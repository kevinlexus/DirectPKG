create or replace package body scott.P_THREAD is

--создание списков объектов для формирования в потоках
procedure prep_obj(p_var in number) is
begin
 delete from temp_obj;
 if p_var=1 then
   --выбрать все не закрытые дома 
   insert into temp_obj(id)
   select h.id from c_houses h
     where nvl(h.psch, 0) = 0; --не закрытые дома
 elsif p_var=2 then  
   --распределить ОДН во вводах, где нет ОДПУ
   insert into temp_obj(id)
   select d.id
    from c_vvod d, c_houses h
   where d.house_id = h.id
     and d.dist_tp in (4,5) --дома без ОДПУ
     and nvl(h.psch, 0) = 0; --не закрытые дома
 elsif p_var=3 then  
   --дома с ОДПУ
   insert into temp_obj(id)
    select distinct d.id
        from c_vvod d, c_houses h
       where d.house_id = h.id
         and nvl(h.psch, 0) = 0 --не закрытые дома
         and d.dist_tp not in (4,5,2); --дома с ОДПУ и с услугой для распределения, например ОДН (dist_tp<>2)
 elsif p_var=4 then
   --выбрать все дома, и закрытые и не закрытые 
   insert into temp_obj(id)
   select h.id from c_houses h;
 end if;
end;

-- обертка для Java функции smpl_chk
procedure smpl_chk (p_var in number, p_ret out number) is
begin
  p_ret:= smpl_chk(p_var);          
end;
  
--аналог процедуры gen.smpl_chk
--проверка перед формированием, с выводом л.с.
--содержащих ошибки в таблицу prep_err
function smpl_chk (p_var in number) return number is
  begin
  delete from prep_err;
  if p_var=1 then
    --список лс. по которым не корректно распр.пеня
      insert into prep_err (lsk, text)
        select k.lsk, 'Некорректные лицевые, содержащие услугу х.в.ОДН, но у прочих л.с. дома услуги ОДН нет' as text
         from kart k, nabor n, usl u where
        k.lsk=n.lsk and k.psch not in (8,9)
        and n.usl=u.usl
        and u.cd='х.вода'
        and exists
        (select * from nabor r, usl u2 where r.lsk=k.lsk
          and r.usl=u2.usl --есть услуга ОДН
          and u2.cd='х.вода.ОДН')
        and not exists --а у других л.с. нет этой услуги
        (select * from kart t, nabor r, usl u2 where r.lsk<>k.lsk
          and r.usl=u2.usl
          and u2.cd='х.вода.ОДН'
          and t.lsk=r.lsk
          and t.house_id=k.house_id)
        and exists
        (select a.house_id from kart a where a.house_id=k.house_id
         having count(*)>1
         group by a.house_id);
  elsif p_var=2 then
    --список лс. по которым не корректно распр.пеня
      insert into prep_err (lsk, text)
        select k.lsk, 'Некорректные лицевые, НЕ содержащие х.в.услугу ОДН, но у прочих л.с. дома услуга ОДН есть' as text
         from kart k, nabor n, usl u where
        k.lsk=n.lsk and k.psch not in (8,9)
        and n.usl=u.usl
        and u.cd='х.вода'
        and exists
        (select * from nabor r, usl u2 where r.lsk=k.lsk
          and r.usl=u2.usl --есть услуга ОДН
          and u2.cd='х.вода.ОДН')
        and not exists --а у других л.с. нет этой услуги
        (select * from kart t, nabor r, usl u2 where r.lsk<>k.lsk
          and r.usl=u2.usl
          and u2.cd='х.вода.ОДН'
          and t.lsk=r.lsk
          and t.house_id=k.house_id)
        and exists
        (select a.house_id from kart a where a.house_id=k.house_id
         having count(*)>1
         group by a.house_id);
  elsif p_var=3 then
    --список лс. по которым не корректно распр.пеня
      insert into prep_err (lsk, text)
        select k.lsk, 'Некорректные лицевые, содержащие услугу г.в.ОДН, но у прочих л.с. дома услуги ОДН нет' as text
        from kart k, nabor n, usl u where
        k.lsk=n.lsk and k.psch not in (8,9)
        and n.usl=u.usl
        and u.cd='г.вода'
        and exists
        (select * from nabor r, usl u2 where r.lsk=k.lsk
          and r.usl=u2.usl --есть услуга ОДН
          and u2.cd='г.вода.ОДН')
        and not exists --а у других л.с. нет этой услуги
        (select * from kart t, nabor r, usl u2 where r.lsk<>k.lsk
          and r.usl=u2.usl
          and u2.cd='г.вода.ОДН'
          and t.lsk=r.lsk
          and t.house_id=k.house_id)
        and exists
        (select a.house_id from kart a where a.house_id=k.house_id
         having count(*)>1
         group by a.house_id);
  elsif p_var=4 then
    --список лс. по которым не корректно распр.пеня
      insert into prep_err (lsk, text)
        select k.lsk, 'Некорректные лицевые, НЕ содержащие г.в.услугу ОДН, но у прочих л.с. дома услуга ОДН есть' as text
         from kart k, nabor n, usl u where
        k.lsk=n.lsk and k.psch not in (8,9)
        and n.usl=u.usl
        and u.cd='г.вода'
        and exists
        (select * from nabor r, usl u2 where r.lsk=k.lsk
          and r.usl=u2.usl --есть услуга ОДН
          and u2.cd='г.вода.ОДН')
        and not exists --а у других л.с. нет этой услуги
        (select * from kart t, nabor r, usl u2 where r.lsk<>k.lsk
          and r.usl=u2.usl
          and u2.cd='г.вода.ОДН'
          and t.lsk=r.lsk
          and t.house_id=k.house_id)
        and exists
        (select a.house_id from kart a where a.house_id=k.house_id
         having count(*)>1
         group by a.house_id);
  elsif p_var=5 then
    --список домов в разных УК, по которым обнаружены открытые лицевые счета - ред.19.02.2019 - отменил проверку, дом может быть в разных УК      
     /* insert into prep_err (lsk, text)           
      select null as lsk, 'kul='||t.kul||' nd='||t.nd||' cnt='||count(*)
      ||' Дом в разных УК, по которому обнаружены открытые лицевые счета' from (
      select k.reu, k.kul, k.nd from kart k, v_lsk_tp tp
       where k.psch not in (8,9) and k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
      group by k.reu, k.kul, k.nd
      ) t 
      group by t.kul,t.nd
      having count(*)>1
      union all
      select null as lsk, 'kul='||t.kul||' nd='||t.nd||' cnt='||count(*)
      ||' Дом в разных УК, по которому обнаружены открытые лицевые счета' from (
      select k.reu, k.kul, k.nd, tp.cd from kart k, v_lsk_tp tp
       where k.psch not in (8,9) and k.fk_tp=tp.id and tp.cd in ('LSK_TP_ADDIT','LSK_TP_RSO')
      group by k.reu, k.kul, k.nd, tp.cd
      ) t 
      group by t.kul,t.nd
      having count(*)>1
      ;*/
      null;
  end if;
  if sql%rowcount > 0 then
    return 1; --есть ошибки
  else
    return 0; --нет ошибок
  end if;
  end;


--чистить инф, там где ВООБЩЕ нет счетчиков (нет записи в c_vvod)
procedure gen_clear_vol is
  begin
    for c in (select u.usl, u.fk_usl_chld
                from usl u, usl odn
               where u.cd in ('х.вода',
                              'г.вода',
                              'х.в. для гвс',
                              'эл.энерг.2',
                              'эл.эн.учет УО',
                              'эл.эн.ОДН',
                              'отоп.гкал.')
                 and u.fk_usl_chld = odn.usl) loop
      for c2 in (select h.id
                   from c_houses h
                  where nvl(h.psch, 0) = 0 --не закрытые дома
                    and not exists
                  (select * from c_vvod d where d.usl = c.usl)
                  order by h.id) loop
            --почистить
            p_vvod.gen_clear_odn(p_usl      => c.usl,
                          p_usl_chld => c.fk_usl_chld,
                          p_house    => c2.id,
                          p_vvod     => null);
      end loop;
    end loop;
  
end;

--распределить объемы по домам с ОДПУ
procedure gen_dist_odpu(p_vv in number) is
begin  
    for c in (select t.* from c_vvod t where t.id=p_vv and t.usl is not null) 
     loop
      p_vvod.gen_dist(p_klsk           => c.fk_k_lsk,
                      p_dist_tp        => c.dist_tp,
                      p_usl            => c.usl,
                      p_use_sch        => c.use_sch,
                      p_old_use_sch    => c.use_sch,
                      p_kub_nrm_fact   => c.kub_nrm_fact,
                      p_kub_sch_fact   => c.kub_sch_fact,
                      p_kub_ar_fact    => c.kub_ar_fact,
                      p_kub_ar         => c.kub_ar,
                      p_opl_ar         => c.opl_ar,
                      p_kub_sch        => c.kub_sch,
                      p_sch_cnt        => c.sch_cnt,
                      p_sch_kpr        => c.sch_kpr,
                      p_kpr            => c.kpr,
                      p_cnt_lsk        => c.cnt_lsk,
                      p_kub_norm       => c.kub_norm,
                      p_kub_fact       => c.kub_fact,
                      p_kub_man        => c.kub_man,
                      p_kub            => c.kub,
                      p_edt_norm       => c.edt_norm,
                      p_kub_dist       => c.kub_dist,
                      p_id             => c.id,
                      p_house_id       => c.house_id,
                      p_opl_add        => c.opl_add,
                      p_old_kub        => c.kub,
                      p_limit_proc     => c.limit_proc,
                      p_old_limit_proc => c.limit_proc,
                      p_gen_part_kpr   => 1,
                      p_wo_limit       => c.wo_limit);
    end loop;
  end;
  
--переключить режимы при выборе пунктов меню (в триггере)
procedure check_itms(p_itm in number, p_sel in number) is
 l_var_exp_lst number;
begin
  l_var_exp_lst:=scott.INIT.get_gen_exp_lst;  --кроме списков, которые регулируются параметром
        
  --если выбрано итоговое, включить другие пункты меню, выкл перех.месяца
  update spr_gen_itm t set t.sel=decode(t.cd, 'GEN_MONTH_OVER',0,'GEN_COMPRESS_ARCH',0,p_sel) 
         where t.cd not in ('GEN_ITG', 'GEN_ADVANCE') --кроме итогового и авансовых платежей
    and exists (select * from spr_gen_itm s where s.cd='GEN_ITG' and s.id=p_itm)
    and decode(t.cd, 'GEN_EXP_LISTS', l_var_exp_lst, 1)=1;
      
  --если выбран переход, выключить другие пункты меню, включить сжатие
  update spr_gen_itm t set t.sel=0 where t.cd not in ('GEN_MONTH_OVER')
    and exists (select * from spr_gen_itm s where s.cd='GEN_MONTH_OVER' and s.id=p_itm and p_sel=0);

  update spr_gen_itm t set t.sel=1 where t.cd in ('GEN_COMPRESS_ARCH')
    and exists (select * from spr_gen_itm s where s.cd='GEN_MONTH_OVER' and s.id=p_itm and p_sel=1);
end;

end P_THREAD;
/

