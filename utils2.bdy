CREATE OR REPLACE PACKAGE BODY SCOTT.UTILS2 IS

procedure distKey(p_tab in out type_saldo_usl,
                     p_key_usl in out varchar2, p_key_org in out number,
                     p_rec in out saldo_usl%rowtype,
                     p_lst_corr in out type_saldo_usl,
                     p_isDist out boolean
                     );

-- распределить сальдо дебет по кредиту (или наоборот)
-- ред. 24.12.18
-- ВНИМАНИЕ! по таблице saldo_usl_script!!!
-- РАБОТАЕТ ОЧЕНЬ МЕДЛЕННО - НЕ НАШЕЛ ПРИМЕНЕНИЕ
-- p_lsk - лиц.счет
-- p_mg - период
-- p_ret - результат корректировки, которую нужно провести в t_corrects_payment
procedure distSalDebByCrd(p_lsk in kart.lsk%type, 
   p_mg in saldo_usl.mg%type, p_ret in out type_saldo_usl) is
  l_key_usl saldo_usl.usl%type;
  l_key_org number;   
  l_lst_corr type_saldo_usl;
  -- флаг, что идет распределение
  isDist boolean;
  l_isDist boolean;
  -- текущий знак распределения
  l_sign number;
  ii number;
  l_deb number;
  l_cr number;
begin
  --dbms_output.enable(100000);
  l_lst_corr:=type_saldo_usl();
  -- получить сальдо
  select t.* bulk collect into t_tab_corr from saldo_usl_script t 
  where t.lsk=p_lsk and t.mg=p_mg and nvl(t.summa,0)<>0
  order by t.usl, t.org;
  
  ii:=0;
  -- распределить
  while true-- ii<100000
  loop
  ii:=ii+1;
  isDist:=false;
    for i in t_tab_corr.first .. t_tab_corr.last loop
      if l_sign is null then
        -- первоначальный выбор знака распределения
        l_sign:=sign(t_tab_corr(i).summa);
        -- переписать коллекцию, содержащую значения одного знака
        
      end if;
      if sign(t_tab_corr(i).summa)=l_sign then
        -- распределять значения определенного знака, который выбран в начале
        distKey(t_tab_corr, l_key_usl, l_key_org, t_tab_corr(i), l_lst_corr, l_isDist);
        if l_isDist then
          isDist:=true;
        end if;  
        --dbms_output.put_line(l_key_usl||'-'||l_key_org);
      end if;  
    end loop;
    if not isDist then
      exit;
    end if;
  end loop;  
   
  -- выполнить проверку
  l_deb:=0;
  l_cr:=0;
  if l_lst_corr.count > 0 then
    for i in l_lst_corr.first .. l_lst_corr.last loop
--          dbms_output.put_line(l_lst_corr(i).usl||','||l_lst_corr(i).org||' summa='||l_lst_corr(i).summa);
          if l_lst_corr(i).summa > 0 then
            l_deb:=l_deb+l_lst_corr(i).summa;
          else
            l_cr:=l_cr+l_lst_corr(i).summa;
          end if;  
    end loop;
    if abs(l_deb) != abs(l_cr) or (l_deb+l_cr) != 0 then
      Raise_application_error(-20000, 'Ошибка #№1.Некорректное распределение суммы в лиц.сч.:'||p_lsk);
    end if; 
  else
      Raise_application_error(-20000, 'Ошибка #№2.Некорректное распределение суммы в лиц.сч.:'||p_lsk);
  end if;
  p_ret:=l_lst_corr;
end;


-- получить следующую пару ключей из коллекции
-- p_tab - коллекция, в которой искать
-- p_key_usl и p_key_org - пара текущих ключей
-- p_rec - распределяемая запись
-- p_lst_corr - исходящие корректировки
procedure distKey(p_tab in out type_saldo_usl,
                     p_key_usl in out varchar2, p_key_org in out number,
                     p_rec in out saldo_usl%rowtype,
                     p_lst_corr in out type_saldo_usl,
                     p_isDist out boolean
                     ) is
 isNext boolean;                     
 -- первый найденый ключ
-- l_first_key_usl saldo_usl.usl%type;
-- l_first_key_org number;
 l_first_rec saldo_usl%rowtype;
 l_last_rec saldo_usl%rowtype;

 -- последний найденый ключ
 l_last_key_usl saldo_usl.usl%type;
 l_last_key_org number;

 -- пара ключей текущей записи
 l_usl saldo_usl.usl%type;
 l_org number;
 -- сумма текущей записи
 l_summa number;
 -- флаг первой записи
 isFirstRec boolean;

 isFound boolean;

  procedure make_corr(p_usl in saldo_usl.usl%type, p_org number) is
  begin
    p_isDist:=false;
    -- поставить копейку на корректировочную запись
    if p_lst_corr.count = 0 then
      -- снять 
      p_lst_corr.extend;
      p_lst_corr(p_lst_corr.last).usl:=p_rec.usl;
      p_lst_corr(p_lst_corr.last).org:=p_rec.org;
      p_lst_corr(p_lst_corr.last).summa:=-1*sign(p_rec.summa)*0.01;
      -- поставить
      p_lst_corr.extend;
      p_lst_corr(p_lst_corr.last).usl:=p_usl;
      p_lst_corr(p_lst_corr.last).org:=p_org;
      p_lst_corr(p_lst_corr.last).summa:=sign(p_rec.summa)*0.01;
    else
      -- снять
      isFound:=false;
      for d in p_lst_corr.first .. p_lst_corr.last loop
        if p_lst_corr(d).usl=p_rec.usl 
           and p_lst_corr(d).org=p_rec.org then
           -- найдена уже добавленная корректировочная строка
            p_lst_corr(d).summa:=p_lst_corr(d).summa-1*sign(p_rec.summa)*0.01;
            isFound:=true;
            exit;
        end if;
      end loop;
      if not isFound then
          -- не найдена запись с таким ключом    
          p_lst_corr.extend;
          p_lst_corr(p_lst_corr.last).usl:=p_rec.usl;
          p_lst_corr(p_lst_corr.last).org:=p_rec.org;
          p_lst_corr(p_lst_corr.last).summa:=-1*sign(p_rec.summa)*0.01;
      end if;    

      -- поставить
      isFound:=false;
      for d in p_lst_corr.first .. p_lst_corr.last loop
        if p_lst_corr(d).usl=p_usl 
           and p_lst_corr(d).org=p_org then
           -- найдена уже добавленная корректировочная строка
            p_lst_corr(d).summa:=p_lst_corr(d).summa+sign(p_rec.summa)*0.01;
            isFound:=true;
            exit;
        end if;
      end loop;
      if not isFound then
          -- не найдена запись с таким ключом    
          p_lst_corr.extend;
          p_lst_corr(p_lst_corr.last).usl:=p_usl;
          p_lst_corr(p_lst_corr.last).org:=p_org;
          p_lst_corr(p_lst_corr.last).summa:=sign(p_rec.summa)*0.01;
      end if;              
    end if;
    
    -- корректировка сальдо
    -- снять копейку с текущей записи
    for s in p_tab.first .. p_tab.last loop
      if p_tab(s).usl=p_usl and p_tab(s).org=p_org then
        -- поставить копейку на целевую запись
      --if p_usl='015' and p_org=677-- and l_summa>0
      --   then
       -- dbms_output.put_line('015='||p_tab(s).summa);
      --end if;

        p_isDist:=true;
        p_tab(s).summa:=p_tab(s).summa+sign(p_rec.summa)*0.01;
        exit;
      end if;
    end loop;
    p_rec.summa:=p_rec.summa-sign(p_rec.summa)*0.01;
    
  end;
 

begin
  isNext:=false;
  l_usl:=p_rec.usl;
  l_org:=p_rec.org;
  l_summa:=p_rec.summa;
  
  isFirstRec:=true;
  for i in p_tab.first .. p_tab.last loop
    if sign(p_tab(i).summa) != sign(l_summa) and p_tab(i).summa !=0 then
      -- если сумма с противоположным знаком с вход.значением и не равна нулю
      if isFirstRec then
        -- сохранить первую запись, погасить флаг первой записи
        isFirstRec:=false;
        l_first_rec:=p_tab(i);
        --l_first_key_usl:=p_tab(i).usl;
        --l_first_key_org:=p_tab(i).org;
      end if;
      
      if p_key_usl is null or isNext then
        -- выполнить корректировку
        
        if p_tab(i).usl is null then 
          null;
        end if; 
        make_corr(p_tab(i).usl, p_tab(i).org);

        p_key_usl:=p_tab(i).usl;
        p_key_org:=p_tab(i).org;
        return;
      end if;
        
      if p_tab(i).usl = p_key_usl and p_tab(i).org = p_key_org then
        -- по следующей записи сделать корректировку
        isNext:=true;
      end if;
      
      l_last_rec:=p_tab(i);
      
    end if;
  end loop;
  -- ничего не найдено - выполнить корректировку по текущей записи
  if l_last_rec.usl is not null then 
    make_corr(l_last_rec.usl, l_last_rec.org);
    p_key_usl:=l_last_rec.usl;
    p_key_org:=l_last_rec.org;
  else
    p_key_usl:=null;  
  end if; 
                         
end;


END UTILS2;
/

