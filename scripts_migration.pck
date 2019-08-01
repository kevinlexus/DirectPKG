create or replace package scott.scripts_migration is
  PROCEDURE find_update_reu3;
  PROCEDURE find_update2_reu3;
  PROCEDURE find_update_oper3;
  PROCEDURE find_update2_oper3;
  procedure prep_c_spr_pen_usl;
  procedure prep_stav_r_usl;
  procedure prep_c_pen_usl_corr;
  procedure prep_deb;
  procedure prep_pen;
  procedure test_gen_pen_lsk(p_lsk in varchar2, p_dt in date);
  procedure test_gen_pen_all(p_dt in date);
  procedure test_gen_pen_all_stop;
  
end scripts_migration;
/

create or replace package body scott.scripts_migration is
--скрипты для перемещения в новые структуры данных


-- найти все таблицы с длиной reu = 3 и обновить с лидирующими нулями.
PROCEDURE find_update_reu3 IS
  l_cnt number;
  TYPE CurType IS REF CURSOR;
  v_cur CurType;
  TYPE rec2 IS RECORD(
    mg varchar2(6));
  rec  rec2;
  str  varchar(2024);
  str2 varchar(2024);
begin
  -- найти все таблицы с длиной reu = 3 и обновить с лидирующими нулями.
  -- отключить констрэйнты ДО!
  -- от SYS: grant select on sys.dba_tab_columns to scott;
  -- от SYS: grant select on sys.dba_views to scott;
  -- включить констрэйнты ПОСЛЕ!
  for c in (select t.TABLE_NAME, t.COLUMN_NAME, t.owner
              from sys.dba_tab_columns t
             where t.OWNER = 'SCOTT'
               and t.COLUMN_NAME in ('REU', 'FORREU', 'FK_REU')
               and t.DATA_LENGTH = 2
               and t.TABLE_NAME not like 'BIN%'
               and not exists
             (select *
                      from sys.dba_views d
                     where d.owner = t.owner
                       and d.view_name = t.table_name)
             order by t.TABLE_NAME, t.COLUMN_NAME) loop
    Raise_application_error(-20000,
                            'НАЙДЕНА НЕКОРРЕКТНАЯ длина поля! таблица='||c.owner||'.'||c.table_name);
  end loop;

  for c in (select t.TABLE_NAME, t.COLUMN_NAME, t.owner
              from sys.dba_tab_columns t
             where t.OWNER = 'SCOTT'
               and t.COLUMN_NAME in ('REU', 'FORREU', 'FK_REU')
               and t.DATA_LENGTH = 3
               and t.TABLE_NAME not like 'BIN%'
               --and t.TABLE_NAME in ('STATISTICS_TREST', 'XITO5_', 'XITO5', 'XXITO10', 'XXITO11')
               and not exists
             (select *
                      from sys.dba_views d
                     where d.owner = t.owner
                       and d.view_name = t.table_name)
             order by t.TABLE_NAME, t.COLUMN_NAME) loop
  
    select count(*)
      into l_cnt
      from dba_tab_columns t
     where t.OWNER = c.owner
       and t.table_name = c.table_name
       and t.COLUMN_NAME in ('MG');
    if l_cnt > 0 then
      -- возможно есть партиции, обновить по ним
      str := 'SELECT distinct t.mg FROM ' || c.owner || '.' || c.table_name ||
             ' t order by t.mg';
      OPEN v_cur FOR str;
      LOOP
        FETCH v_cur
          INTO rec;
        if rec.mg is not null then   
          str2 := 'update ' || c.owner || '.' || c.table_name || ' t set t.' ||
                  c.column_name || '= lpad(trim(t.' || c.column_name ||
                  '),3, ''0'') where length(trim(t.' || c.column_name ||
                  '))=2 and t.mg=:mg';
          execute immediate str2 using rec.mg;
        else
          str2 := 'update ' || c.owner || '.' || c.table_name || ' t set t.' ||
                  c.column_name || '= lpad(trim(t.' || c.column_name ||
                  '),3, ''0'') where length(trim(t.' || c.column_name ||
                  '))=2 and t.mg is null';
          execute immediate str2;
        end if;          
        commit;
        logger.log_(null, 'партиция:'||c.owner || '.' || c.table_name ||'.'||rec.mg);
      
        EXIT WHEN v_cur%NOTFOUND;
      END LOOP;
    
      -- Close cursor:
      CLOSE v_cur;
    
    else
      -- без партиций
      str2 := 'update ' || c.owner || '.' || c.table_name || ' t set t.' ||
              c.column_name || '= lpad(trim(t.' || c.column_name ||
              '),3, ''0'') where length(trim(t.' || c.column_name ||
              '))=2 ';
      execute immediate str2;
      commit;
      logger.log_(null, 'без партиций:'||c.owner || '.' || c.table_name);
    
    end if;
  
  end loop;

END find_update_reu3;

-- найти все таблицы с reu или forreu, но с некорректным содержимым,
-- без обновления
PROCEDURE find_update2_reu3 IS
  l_cnt number;
  TYPE CurType IS REF CURSOR;
  v_cur CurType;
  TYPE rec2 IS RECORD(
    cnt number);
  rec  rec2;
  str  varchar(2024);
  str2 varchar(2024);
begin
  -- ПРОСТО МОНИТОРИТ ДАННЫЕ
  -- найти все таблицы с reu или forreu, но с некорректным содержимым
  -- от SYS: grant select on sys.dba_tab_columns to scott;
  -- от SYS: grant select on sys.dba_views to scott;
  for c in (select t.TABLE_NAME, t.COLUMN_NAME, t.owner
              from sys.dba_tab_columns t
             where t.OWNER = 'SCOTT'
               and t.COLUMN_NAME in ('REU', 'FORREU', 'FK_REU')
               and t.DATA_LENGTH = 2
               and t.TABLE_NAME not like 'BIN%'
               and not exists
             (select *
                      from sys.dba_views d
                     where d.owner = t.owner
                       and d.view_name = t.table_name)
             order by t.TABLE_NAME, t.COLUMN_NAME) loop
    Raise_application_error(-20000,
                            'НАЙДЕНА НЕКОРРЕКТНАЯ длина поля! таблица='||c.owner||'.'||c.table_name);
  end loop;

  for c in (select t.TABLE_NAME, t.COLUMN_NAME, t.owner
              from sys.dba_tab_columns t
             where t.OWNER = 'SCOTT'
               and t.COLUMN_NAME in ('REU', 'FORREU', 'FK_REU')
               and t.TABLE_NAME not like 'BIN%'
               and not exists
             (select *
                      from sys.dba_views d
                     where d.owner = t.owner
                       and d.view_name = t.table_name)
             order by t.TABLE_NAME, t.COLUMN_NAME) loop

      str := 'select count(*) from ' || c.owner || '.' || c.table_name || ' t where length(trim(t.' || c.column_name ||
              '))=2 ';
      OPEN v_cur FOR str;
      LOOP
        FETCH v_cur
          INTO rec;
          if rec.cnt > 0 then 
          Raise_application_error(-20000, 'Таблица ' || c.owner || '.' || c.table_name ||
           'имеет '||rec.cnt||' необновленных строк!');
          end if; 
        EXIT WHEN v_cur%NOTFOUND;
      END LOOP;

  end loop;

END find_update2_reu3;


-- найти все таблицы с длиной oper = 3 и обновить с лидирующими нулями.
-- предварительно отключить foreign keys!
PROCEDURE find_update_oper3 IS
  l_cnt number;
  TYPE CurType IS REF CURSOR;
  v_cur CurType;
  TYPE rec2 IS RECORD(
    mg varchar2(6));
  rec  rec2;
  str  varchar(2024);
  str2 varchar(2024);
begin
  -- найти все таблицы с длиной oper = 3 и обновить с лидирующими нулями.
  -- отключить констрэйнты ДО!
  -- от SYS: grant select on sys.dba_tab_columns to scott;
  -- от SYS: grant select on sys.dba_views to scott;
  -- включить констрэйнты ПОСЛЕ!
  for c in (select t.TABLE_NAME, t.COLUMN_NAME, t.owner
              from sys.dba_tab_columns t
             where t.OWNER = 'SCOTT'
               and t.COLUMN_NAME in ('OPER', 'FK_OPER')
               and t.DATA_LENGTH = 2
               and t.TABLE_NAME not like 'BIN%'
               and t.TABLE_NAME not in ('PROC_PLAN_LOAD','PROC_PLAN_LOADED')
               and not exists
             (select *
                      from sys.dba_views d
                     where d.owner = t.owner
                       and d.view_name = t.table_name)
             order by t.TABLE_NAME, t.COLUMN_NAME) loop
    Raise_application_error(-20000,
                            'НАЙДЕНА НЕКОРРЕКТНАЯ длина поля! таблица='||c.owner||'.'||c.table_name);
  end loop;

  for c in (select t.TABLE_NAME, t.COLUMN_NAME, t.owner
              from sys.dba_tab_columns t
             where t.OWNER = 'SCOTT'
               and t.COLUMN_NAME in ('OPER', 'FK_OPER')
               and t.TABLE_NAME not like 'BIN%'
               and t.TABLE_NAME not in ('PROC_PLAN_LOAD','PROC_PLAN_LOADED')
               and not exists
             (select *
                      from sys.dba_views d
                     where d.owner = t.owner
                       and d.view_name = t.table_name)
             order by t.TABLE_NAME, t.COLUMN_NAME) loop
  
    select count(*)
      into l_cnt
      from dba_tab_columns t
     where t.OWNER = c.owner
       and t.table_name = c.table_name
       and t.COLUMN_NAME in ('MG');
    if l_cnt > 0 then
      -- возможно есть партиции, обновить по ним
      str := 'SELECT distinct t.mg FROM ' || c.owner || '.' || c.table_name ||
             ' t order by t.mg';
      OPEN v_cur FOR str;
      LOOP
        FETCH v_cur
          INTO rec;
        if rec.mg is not null then   
          str2 := 'update ' || c.owner || '.' || c.table_name || ' t set t.' ||
                  c.column_name || '= lpad(trim(t.' || c.column_name ||
                  '),3, ''0'') where length(trim(t.' || c.column_name ||
                  '))=2 and t.mg=:mg';
          execute immediate str2 using rec.mg;
        else
          str2 := 'update ' || c.owner || '.' || c.table_name || ' t set t.' ||
                  c.column_name || '= lpad(trim(t.' || c.column_name ||
                  '),3, ''0'') where length(trim(t.' || c.column_name ||
                  '))=2 and t.mg is null';
          execute immediate str2;
        end if;          
        commit;
        logger.log_(null, 'партиция:'||c.owner || '.' || c.table_name ||'.'||rec.mg);
      
        EXIT WHEN v_cur%NOTFOUND;
      END LOOP;
    
      -- Close cursor:
      CLOSE v_cur;
    
    else
      -- без партиций
      str2 := 'update ' || c.owner || '.' || c.table_name || ' t set t.' ||
              c.column_name || '= lpad(trim(t.' || c.column_name ||
              '),3, ''0'') where length(trim(t.' || c.column_name ||
              '))=2 ';
      execute immediate str2;
      commit;
      logger.log_(null, 'без партиций:'||c.owner || '.' || c.table_name);
    
    end if;
  
  end loop;

END find_update_oper3;

-- найти все таблицы с oper или fk_oper (и т.п.), но с некорректным содержимым,
-- без обновления
PROCEDURE find_update2_oper3 IS
  l_cnt number;
  TYPE CurType IS REF CURSOR;
  v_cur CurType;
  TYPE rec2 IS RECORD(
    cnt number);
  rec  rec2;
  str  varchar(2024);
  str2 varchar(2024);
begin
  -- ПРОСТО МОНИТОРИТ ДАННЫЕ
  -- найти все таблицы с oper или fk_oper, но с некорректным содержимым
  -- от SYS: grant select on sys.dba_tab_columns to scott;
  -- от SYS: grant select on sys.dba_views to scott;
  for c in (select t.TABLE_NAME, t.COLUMN_NAME, t.owner
              from sys.dba_tab_columns t
             where t.OWNER = 'SCOTT'
               and t.COLUMN_NAME in ('OPER', 'FK_OPER')
               and t.DATA_LENGTH = 2
               and t.TABLE_NAME not like 'BIN%'
               and t.TABLE_NAME not in ('PROC_PLAN_LOAD','PROC_PLAN_LOADED')
               and not exists
             (select *
                      from sys.dba_views d
                     where d.owner = t.owner
                       and d.view_name = t.table_name)
             order by t.TABLE_NAME, t.COLUMN_NAME) loop
    Raise_application_error(-20000,
                            'НАЙДЕНА НЕКОРРЕКТНАЯ длина поля! таблица='||c.owner||'.'||c.table_name);
  end loop;

  for c in (select t.TABLE_NAME, t.COLUMN_NAME, t.owner
              from sys.dba_tab_columns t
             where t.OWNER = 'SCOTT'
               and t.COLUMN_NAME in ('OPER', 'FK_OPER')
               and t.TABLE_NAME not like 'BIN%'
               and t.TABLE_NAME not in ('PROC_PLAN_LOAD','PROC_PLAN_LOADED')
               and not exists
             (select *
                      from sys.dba_views d
                     where d.owner = t.owner
                       and d.view_name = t.table_name)
             order by t.TABLE_NAME, t.COLUMN_NAME) loop

      str := 'select count(*) from ' || c.owner || '.' || c.table_name || ' t where length(trim(t.' || c.column_name ||
              '))=2 ';
      OPEN v_cur FOR str;
      LOOP
        FETCH v_cur
          INTO rec;
          if rec.cnt > 0 then 
          Raise_application_error(-20000, 'Таблица ' || c.owner || '.' || c.table_name ||
           'имеет '||rec.cnt||' необновленных строк!');
          end if; 
        EXIT WHEN v_cur%NOTFOUND;
      END LOOP;

  end loop;

END find_update2_oper3;

-- подготовка справочника периодов пени по услугам для ИМПОРТА
procedure prep_c_spr_pen_usl is
begin
  delete from pen_dt t;
  -- непересекающимся группами
  for c in (select distinct t.mg, t.fk_lsk_tp from c_spr_pen t) loop
    insert into pen_dt
      (mg, dt, usl_tp_pen, reufrom, reuto)
      SELECT a.mg, a.dat, decode(tp.cd,'LSK_TP_MAIN', 0, 1) as usl_tp_pen,
             MIN(a.reu) AS reuFrom,
             MAX(a.reu) AS reuTo
      FROM   (
        SELECT t.*,
               ROW_NUMBER() OVER ( ORDER BY t.reu ) as rn1,
               ROW_NUMBER() OVER ( PARTITION BY t.dat ORDER BY t.reu ) as rn2,
               ROW_NUMBER() OVER ( ORDER BY t.reu )
                 - ROW_NUMBER() OVER ( PARTITION BY t.dat ORDER BY t.reu )
                 AS grp
        FROM  
        c_spr_pen t where t.mg=c.mg and t.fk_lsk_tp=c.fk_lsk_tp
      ) a, v_lsk_tp tp
      where a.fk_lsk_tp=tp.id
      GROUP BY a.mg, decode(tp.cd,'LSK_TP_MAIN', 0, 1), a.dat, a.grp;
  end loop;    
  commit;
end;

-- подготовка ставок рефинансирования по услугам для ИМПОРТА
procedure prep_stav_r_usl is
begin
  delete from pen_ref t;
  insert into pen_ref
    (proc, partrate, rate, days1, days2, usl_tp_ref, dt1, dt2)
  select t.proc, t.partrate, t.rate, t.days1, t.days2, 
   decode(tp.cd,'LSK_TP_MAIN', 0, 1) as usl_tp_ref, t.dat1, t.dat2
   from stav_r t, v_lsk_tp tp
  where t.fk_lsk_tp=tp.id and t.dat2>=gdt(0,0,0); -- начиная с текущего периода
  commit;
end;

-- загрузка корректировок пени по услугам для ТЕСТОВ
procedure prep_c_pen_usl_corr is
begin
  delete from c_pen_usl_corr;
  insert into c_pen_usl_corr
    (lsk, penya, mgchange, dtek, ts, fk_user, fk_doc, usl, org)
  select t.lsk, t.penya, t.dopl, t.dtek, t.ts, 
  t.fk_user, t.fk_doc, decode(tp.cd, 'LSK_TP_MAIN', '003', '033') as usl, 677 as org
  from c_pen_corr t, kart k, v_lsk_tp tp
  where t.lsk=k.lsk and k.fk_tp=tp.id;
  commit;
end;

-- ОПАСНО! ИДЕТ УДАЛЕНИЕ ДАННЫХ!
-- подготовка ТЕСТОВОЙ таблицы задолженности (наполнить только 003 услугу)
procedure prep_deb is
begin
  delete from deb;
  insert into deb(lsk,
                  usl,
                  org,
                  debout,
                  mg,
                  mgfrom,
                  mgto)
  select t.lsk, decode(tp.cd, 'LSK_TP_MAIN', '003', '033') as usl, 677 as org, 
  sum(decode(t.type,0,summa,-1*summa)) as debout,
  t.mg, t.period as mgFrom, t.period as mgTo
  from C_CHARGEPAY t, kart k, v_lsk_tp tp, v_params p
  where t.period=p.period3 and t.lsk=k.lsk and k.fk_tp=tp.id
  group by t.lsk, decode(tp.cd, 'LSK_TP_MAIN', '003', '033'), t.mg, t.period
  having nvl(sum(decode(t.type,0,summa,-1*summa)),0)<>0;
  commit;               

end;

-- ОПАСНО! ИДЕТ УДАЛЕНИЕ ДАННЫХ!
-- подготовка ТЕСТОВОЙ таблицы пени (наполнить только 003 услугу)
procedure prep_pen is
begin
  delete from pen;
  insert into pen(lsk,
                  usl,
                  org,
                  penout,
                  mg,
                  mgfrom,
                  mgto)
  select t.lsk, decode(tp.cd, 'LSK_TP_MAIN', '003', '033') as usl, 677 as org,
    t.penya, t.mg1, t.mg as mgFrom, t.mg as mgTo
    from a_penya t, kart k, v_lsk_tp tp, v_params p 
         where t.mg=p.period3 and t.lsk=k.lsk and k.fk_tp=tp.id
         and nvl(t.penya,0)<>0;
  
  commit;               

end;

-- тестирование процедуры вызова расчета задолженности и пени по 1 лс
procedure test_gen_pen_lsk(p_lsk in varchar2, p_dt in date) is
  l_ret varchar2(1000);
begin
  utl_http.set_transfer_timeout(5000);
  l_ret:=p_java.http_req('gen?lsk='||p_lsk||'&tp=0&genDt='||to_char(p_dt,'DD.MM.YYYY')
    ||'&key=lasso_the_moose_'||to_char(sysdate,'YYYYMMDD'));
  
  if substr(l_ret,1,2) <> 'OK' then
    Raise_application_error(-20000, 'Ошибка при вызове Java функции: '||l_ret );
  end if;
end;

-- тестирование процедуры вызова расчета задолженности и пени по всем лс
procedure test_gen_pen_all(p_dt in date) is
  l_ret varchar2(1000);
begin
  utl_http.set_transfer_timeout(5000);
  l_ret:=p_java.http_req('gen?tp=0&genDt='||to_char(p_dt,'DD.MM.YYYY')
    ||'&key=lasso_the_moose_'||to_char(sysdate,'YYYYMMDD'));
  if substr(l_ret,1,2) <> 'OK' then
    Raise_application_error(-20000, 'Ошибка при вызове Java функции: '||l_ret );
  end if;
end;

-- тестирование процедуры вызова расчета задолженности и пени по всем лс
procedure test_gen_pen_all_stop is
  l_ret varchar2(1000);
begin
  utl_http.set_transfer_timeout(5000);
  l_ret:=p_java.http_req('gen?tp=0&stop=1'
    ||'&key=lasso_the_moose_'||to_char(sysdate,'YYYYMMDD'));
  if substr(l_ret,1,2) <> 'OK' then
    Raise_application_error(-20000, 'Ошибка при вызове Java функции: '||l_ret );
  end if;
end;


end scripts_migration;
/

