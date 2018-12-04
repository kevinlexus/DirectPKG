create or replace package body scott.rep_bills_ext is

  -- детализация счета, перегруженный метод, для старых вызовов
procedure detail(p_lsk  IN KART.lsk%TYPE, -- лиц.счет
                 p_mg   IN PARAMS.period%type, -- период запроса
                 p_rfcur out ccur
  ) is
begin
  detail(p_lsk   => p_lsk,
         p_mg    => p_mg,
         p_includeSaldo => 1,
         p_rfcur => p_rfcur);
end;
-- детализация счета по строкам
procedure detail(p_lsk  IN KART.lsk%TYPE, -- лиц.счет
                 p_mg   IN PARAMS.period%type, -- период запроса
                 p_includeSaldo in number, -- включать ли сальдо в запрос (1-да, 0 - нет)
                 p_rfcur out ccur
  ) is
  l_bill_var number;
  l_house_id number;
  t_bill_row tab_bill_row;
  l_tp number; -- строить по иерархии по орг (0) или по дому (1)
  i number;
  r_bill_row rec_bill_row;
  l_lsk_tp u_list.cd%type;
  l_cnt number;
  rec rec_bill_detail := rec_bill_detail(0, null, 0, null, 0,0,0,0,0,0,0,0,0,0,0);
begin

  -- если есть запись в иерархии по дому (usl_tree), то строить детализацию по ней
  select o.fk_bill_var, k.house_id, nvl(uh.tp,0), tp.cd into l_bill_var, l_house_id, l_tp, l_lsk_tp
      from arch_kart k
      join v_lsk_tp tp on k.fk_tp=tp.id
      left join (select distinct 1 as tp, u.fk_house from usl_tree u) uh -- признак наличия иерархии по дому
        on k.house_id=uh.fk_house
      join t_org o on k.reu=o.reu
        and k.lsk=p_lsk
        and k.mg=p_mg;

  select rec_bill_row(u.usl, u.parent_usl, nvl(a.vol,0), nvl(a.price,0), nvl(a.summa,0), nvl(sl.deb,0), 
                             nvl(r.change1,0), nvl(r.change_proc1,0), nvl(r.change2,0), nvl(d.kub,0))
       bulk collect
       into t_bill_row
     from
      arch_kart k
      join t_org o on k.reu=o.reu
      join usl_tree u on l_tp=0 and u.fk_bill_var=o.fk_bill_var or l_tp=1 and u.fk_house=k.house_id
      left join
      (select t.usl, t.mgFrom, t.mgTo,
             sum(t.summa) as summa,  -- сумма
             sum(t.test_opl) as vol, -- объем
             max(t.test_cena) as price -- расценка
            from a_charge2 t  -- начисление
             where t.type = 1 and p_mg between t.mgFrom and t.mgTo
              and t.lsk=p_lsk
             group by t.mgFrom, t.mgTo, t.usl) a on
                   u.usl=a.usl and k.mg between a.mgFrom and a.mgTo
      left join
      (select t.usl, sum(t.summa) as deb -- входящее сальдо
            from saldo_usl t
            where t.mg = p_mg and t.lsk=p_lsk and p_includeSaldo=1 -- включать ли сальдо?
           group by t.usl) sl on u.usl=sl.usl
      left join
      (select t.usl, sum(t.kub) as kub -- объем ОДПУ
            from a_vvod t join a_nabor2 a on a.fk_vvod=t.id and p_mg between a.mgFrom and a.mgTo
            and t.mg = p_mg and a.lsk=p_lsk
           group by t.usl) d on u.usl=d.usl
      left join
      (select t.usl as usl, 
              sum(decode(t.type,0,t.summa)) as change1, -- снятия-доборы
              sum(decode(t.type,0,0,t.summa)) as change2, -- прочие перерасчеты
              sum(t.proc) as change_proc1
            from
            a_change t where nvl(t.show_bill,0)<>1 and t.mg = p_mg
            and t.lsk=p_lsk
            group by t.usl) r on u.usl=r.usl
      where k.mg=p_mg and k.lsk=p_lsk;

  tab:= tab_bill_detail();
  -- начать с корневой записи, рекурсивно
  r_bill_row:=procRow(0, '000', t_bill_row, l_bill_var, l_house_id, l_tp);
  --select count(*) into l_cnt from table(t_bill_row) t where t.usl='003';
  --or (l_lsk_tp='LSK_TP_MAIN' and t.usl='003' or l_lsk_tp='LSK_TP_ADDIT' and t.usl='033')

  select count(*) into l_cnt from table(tab) t
       where t.price<>0 or t.charge<>0 
       or t.change1<>0 or t.change2<>0 or t.amnt <>0 or t.deb<>0 or t.kub<>0;
       
  if l_cnt = 0 then 
    tab.extend;
    tab(tab.last):=rec;
--    if l_lsk_tp='LSK_TP_MAIN' then
--  Raise_application_error(-20000, l_cnt);
--    end if;
      tab(tab.last).usl:=null;
    open p_rfcur for select t.*
   from table(tab) t where t.usl is null and p_includeSaldo=1;
  else
      open p_rfcur for select t.* from table(tab) t
       where t.price<>0 or t.charge<>0 
       or t.change1<>0 or t.change2<>0 or t.amnt <>0 or t.deb<>0 or t.kub<>0
        order by t.npp;
  end if;        


end;


-- обработать запись для счета
function procRow(
                 p_lvl in number, -- текущий уровень
                 p_parent_usl in usl.usl%type, -- код родительской услуги.
                 t_bill_row IN tab_bill_row, -- строки с начислением, сальдо и т.п.
                 p_bill_var IN number,
                 p_house_id IN number,
                 p_tp IN number
                 ) return rec_bill_row is
  rec rec_bill_detail := rec_bill_detail(0, null, 0, null, 0,0,0,0,0,0,0,0,0,0,0);
  r_bill_row rec_bill_row;
  -- итоговая запись по дочерним
  r_bill_row_amnt rec_bill_row;
  r_bill_row_main rec_bill_row;
  l_last number;
begin
  r_bill_row_amnt := rec_bill_row(null, null, 0,0,0,0,0,0,0,0);

  for c in (select t.usl, t.parent_usl, t.tp, t.npp, trim(u.nm)||','||trim(u.ed_izm) as nm, 
           nvl(t.hide_price,0) as hide_price, nvl(t.hide_vol,0) as hide_vol,
           nvl(t.hide_row,0) as hide_row, nvl(u.bill_col,0) as bill_col, 
           nvl(u.bill_col2,0) as bill_col2 from USL_TREE t
                   left join usl u on t.usl=u.usl
                   where t.parent_usl=p_parent_usl 
                   and (p_tp=0 and t.fk_bill_var=p_bill_var
                       or t.fk_house=p_house_id) -- либо по организации, либо по дому
                   order by t.npp
                   ) loop
    -- получить строку
    r_bill_row_main:=getRow(c.usl, t_bill_row);
    if c.tp in (0) then
      -- простая запись, нет вложенных
      r_bill_row := rec_bill_row(null, null, 0,0,0,0,0,0,0,0);
    elsif c.tp in (1,2) then
      -- 1-содержит вложенные
      -- обработать строки вложенных записей
      r_bill_row := procRow(p_lvl+1, c.usl, t_bill_row, p_bill_var, p_house_id, p_tp);
    end if;  

    if c.hide_row != 1 then
      tab.extend;
      l_last:=tab.last;
      tab(l_last):=rec;
      if c.parent_usl != '000' then
        -- подсчитывать в итоге 
        tab(l_last).is_amnt_sum:=0;
      else
        -- не подсчитывать в итоге 
        tab(l_last).is_amnt_sum:=1;
      end if;
      tab(l_last).usl:=c.usl;
      tab(l_last).npp:=c.npp;
      tab(l_last).bill_col:=c.bill_col;
      tab(l_last).bill_col2:=c.bill_col2;
      -- наименование
      if c.tp=1 then
        tab(l_last).name:=lpad(' ',p_lvl)||c.nm||' в т.ч.:';
      elsif c.tp in (0,2) then
        tab(l_last).name:=lpad(' ',p_lvl)||c.nm;
      end if;
      -- добавить суммы из вложенных, если имеются
      tab(l_last).charge:=r_bill_row_main.charge+r_bill_row.charge;
      tab(l_last).change1:=r_bill_row_main.change1+r_bill_row.change1;
      tab(l_last).change2:=r_bill_row_main.change2+r_bill_row.change2;
      tab(l_last).deb:=r_bill_row_main.deb+r_bill_row.deb;
      tab(l_last).amnt:=tab(l_last).charge+tab(l_last).change1
            +tab(l_last).change2;
      -- с % снятия всё сложно - оставил пока так
      tab(l_last).change_proc1:=r_bill_row_main.change_proc1;
      if c.hide_price = 0 then
        tab(l_last).price:=r_bill_row_main.price+r_bill_row.price;
      else
        tab(l_last).price:=null;  
      end if;  
      -- взять максимальный объем
      if c.hide_vol = 0 then
        if abs(r_bill_row.vol) > abs(r_bill_row_main.vol) then
          tab(l_last).vol:=r_bill_row.vol;
        else 
          tab(l_last).vol:=r_bill_row_main.vol;
        end if;  
      else
        tab(l_last).vol:=null;
      end if; 
      if abs(r_bill_row.kub) > abs(r_bill_row_main.kub) then
        tab(l_last).kub:=r_bill_row.kub;
      else 
        tab(l_last).kub:=r_bill_row_main.kub;
      end if;  
    end if;  
      
    
    r_bill_row_main.charge:=r_bill_row_main.charge+r_bill_row.charge;
    r_bill_row_main.change1:=r_bill_row_main.change1+r_bill_row.change1;
    r_bill_row_main.change2:=r_bill_row_main.change2+r_bill_row.change2;
    r_bill_row_main.deb:=r_bill_row_main.deb+r_bill_row.deb;

    -- добавить к итогу по дочерним записям
    r_bill_row_amnt.charge:=r_bill_row_amnt.charge+r_bill_row_main.charge;
    r_bill_row_amnt.change1:=r_bill_row_amnt.change1+r_bill_row_main.change1;
    r_bill_row_amnt.change2:=r_bill_row_amnt.change2+r_bill_row_main.change2;
    r_bill_row_amnt.deb:=r_bill_row_amnt.deb+r_bill_row_main.deb;
    r_bill_row_amnt.price:=r_bill_row_amnt.price+r_bill_row_main.price;
    
    -- максимальный объем по дочерним записям
    if abs(r_bill_row_main.vol) > abs(r_bill_row_amnt.vol) then
      r_bill_row_amnt.vol:=r_bill_row_main.vol;
    end if;
    if abs(r_bill_row_main.kub) > abs(r_bill_row_amnt.kub) then
      r_bill_row_amnt.kub:=r_bill_row_main.kub;
    end if;
    

   end loop;

   return r_bill_row_amnt;
end;

function getRow(
                 p_usl in usl.usl%type, -- код услуги.
                 t_bill_row IN tab_bill_row -- строки с начислением, сальдо и т.п.
                 ) return rec_bill_row is
begin
   for c in 1..t_bill_row.count loop
       if t_bill_row(c).usl=p_usl then
         return t_bill_row(c);
       end if;
   end loop;
   -- не найдено ничего
   return null;
end;

-- получить сумму по дочерним записям для счета
/*function getChildRowSum(
                 p_is_sum_vol in number, -- суммировать объем (0-нет,1-да)
                 p_parent_usl in usl.usl%type -- код родительской услуги.
                 ) return rec_bill_row is
  rec rec_bill_row;
begin
   rec := rec_bill_row(null, null, 0,0,0,0,0,0,0,0);
   for c in 1..tab.count loop
       if tab(c).parent_usl=p_parent_usl then
         if (p_is_sum_vol=1) then
           rec.vol:=rec.vol+nvl(tab(c).vol,0);
         else
           if nvl(tab(c).vol,0) > rec.vol then
             rec.vol:=nvl(tab(c).vol,0);
           end if;    
         end if;    
         rec.price:=rec.price+nvl(tab(c).price,0);
         rec.charge:=rec.charge+nvl(tab(c).charge,0);
         rec.sal:=rec.sal+nvl(tab(c).deb,0);
         rec.proc:=rec.proc+nvl(tab(c).change_proc1,0);
         rec.changes0:=rec.changes0+nvl(tab(c).changes0,0);
         rec.changes1:=rec.changes1+nvl(tab(c).changes1,0);
         rec.changes2:=rec.changes2+nvl(tab(c).changes2,0);
       end if;
   end loop;
   return rec;
null;

end;*/

end rep_bills_ext;
/

