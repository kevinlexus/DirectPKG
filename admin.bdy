CREATE OR REPLACE PACKAGE BODY SCOTT.ADMIN IS
  g_trg_id_ NUMBER;

procedure fix_base(fix_ in number) is
begin
--фиксация изменений в базе...
  if fix_ = 1 then --изменения не разрешены
    execute immediate 'alter trigger fix_c_change enable';
    execute immediate 'alter trigger fix_c_change_docs enable';
    execute immediate 'alter trigger fix_c_houses enable';
    execute immediate 'alter trigger fix_c_kart_pr enable';
    execute immediate 'alter trigger fix_c_kwtp enable';
    execute immediate 'alter trigger fix_c_kwtp_mg enable';
    execute immediate 'alter trigger fix_c_lg_docs enable';
    execute immediate 'alter trigger fix_c_lg_pr enable';
    execute immediate 'alter trigger fix_c_vvod enable';
    execute immediate 'alter trigger fix_kart enable';
    execute immediate 'alter trigger fix_kart_pr enable';
    execute immediate 'alter trigger fix_nabor enable';
  else --изменения разрешены
  null;
  end if;
end;


  PROCEDURE sign_reports is
  begin
   update period_reports p set p.signed=1;
  end;

  PROCEDURE disable_logons(param_ IN PARAMS.param%TYPE,
                           mess_  IN PARAMS.message%TYPE) IS
    --Запрет / разрешение на работу пользователям
  BEGIN
    UPDATE PARAMS SET param = param_, message = mess_;
    COMMIT;
  END disable_logons;

  PROCEDURE send_message(msg_ IN MESSAGES.text%TYPE) IS
  BEGIN
    --отправка сообщений пользователям
   SYS.Dbms_Alert.signal('FINDAY', msg_ );
   COMMIT;
  END;

  procedure analyze_all_tables is
    cursor c is
      select table_name from all_tables where owner = 'SCOTT';
    rec_ c%rowtype;
  begin
  time_ := sysdate;
    open c;
    loop
      fetch c
        into rec_;
      exit when c%notfound;
      begin
        execute immediate 'BEGIN DBMS_STATS.GATHER_TABLE_STATS ( ''SCOTT'' , :table_ ,'''' ,''33'' ,FALSE ,''FOR ALL INDEXES''  ,NULL  ,''DEFAULT''  ,FALSE ,''''  ,''''  ,'''' ); END;'
          using rec_.table_name;
      end;
    end loop;
  logger.log_(time_, 'Admin.analyze_all_tables (Собрана аналитика)');
  end;

  PROCEDURE ANALYZE(table_ IN sys.all_tables.table_name%TYPE) IS
    CURSOR c IS
      SELECT index_name AS index_name
        FROM all_indexes
       WHERE owner = 'SCOTT'
         AND table_name = UPPER(table_);
    rec_ c%ROWTYPE;
  BEGIN
    --  return;
    --analyze таблиц и индексов, после загрузки в схеме 'SCOTT'
    EXECUTE IMMEDIATE 'BEGIN DBMS_STATS.GATHER_TABLE_STATS ( ''SCOTT'' , :table_ ,'''' ,''33'' ,FALSE ,''FOR ALL INDEXES''  ,NULL  ,''DEFAULT''  ,FALSE ,''''  ,''''  ,'''' ); END;'
      USING UPPER(table_);
    OPEN c;
    LOOP
      FETCH c
        INTO rec_;
      EXIT WHEN c%NOTFOUND;
      BEGIN
        EXECUTE IMMEDIATE 'BEGIN DBMS_STATS.GATHER_INDEX_STATS (''SCOTT''  ,:index_  ,''''  ,''33''  ,''''  ,''''  ,'''' ); END;'
          USING rec_.index_name;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END LOOP;
  END;

  PROCEDURE analyze_db IS
  BEGIN
    sys.dbms_stats.gather_database_stats(30,
                                         NULL,
                                         'FOR ALL COLUMNS',
                                         NULL,
                                         'DEFAULT',
                                         TRUE,
                                         NULL,
                                         NULL,
                                         'GATHER',
                                         NULL,
                                         FALSE,
                                         FALSE,
                                         FALSE);
  END;

  PROCEDURE make_readed_message(id_ IN MESSAGES.id%TYPE) IS
  BEGIN
    --отметка о прочтении сообщения пользователем
    UPDATE MESSAGES m SET m.is_read_lamp = 1 WHERE m.id = id_;
    COMMIT;
  END;

  PROCEDURE trg_del_var IS
    --Группа процедур по удалению старых сообщений пользователей
  BEGIN
    g_trg_id_ := 0;
  END;

  PROCEDURE trg_set_var(id_ IN NUMBER) IS
  BEGIN
    g_trg_id_ := id_;
  END;

  PROCEDURE trg_del_rec IS
  BEGIN
    IF g_trg_id_ <> 0 THEN
      --У не SYS-а оставляем последние 30 сообщений
      DELETE FROM MESSAGES d
       WHERE d.id IN (SELECT t.id
                        FROM MESSAGES t,
                             (SELECT m.*, ROWNUM AS rn
                                FROM (SELECT *
                                        FROM MESSAGES
                                       WHERE from_id = g_trg_id_
                                       ORDER BY dat DESC) m) a
                       WHERE t.id = a.id
                         AND a.rn > 30);
    ELSE
      --У SYS-а удаляем старые сообщения
      DELETE FROM MESSAGES m
       WHERE m.from_id = g_trg_id_
         AND m.dat < SYSDATE - 1;
    END IF;
  END;


  function test_fields(tname_ in varchar2, field_ varchar2) return varchar2
  is
  TYPE empcurtyp IS REF CURSOR;
  c     empcurtyp;
  rec_ usl%rowtype;
  txt_ varchar2(1000);
  fld_ varchar2(100);
  begin
  txt_:='';
    open c for 'select trim('||field_||') as fld from usl u ';
    loop
      fetch c into fld_;
      exit when c%notfound;
      begin
        execute immediate 'insert into '||tname_||' (' || fld_ || ')
           values  (null)';
        exception
        when others then
        txt_:=txt_||' '||fld_;
      end;
    rollback;
    end loop;
  return txt_;
  end;

  procedure test_tables is
  txt_ varchar2(1000);
  begin
    txt_:=test_fields('expprivs', 'lpw');
    if length(txt_) > 0 then
      raise_application_error(-20001,
                           'Для таблицы expprivs не достаточно следующих полей '||txt_);
    end if;
    txt_:=test_fields('expkartw', 'kartw');
    if length(txt_) > 0 then
      raise_application_error(-20001,
                           'Для таблицы expkartw не достаточно следующих полей '||txt_);
    end if;
    txt_:=test_fields('expkwni', 'kwni');
    if length(txt_) > 0 then
      raise_application_error(-20001,
                           'Для таблицы expkwni не достаточно следующих полей '||txt_);
    end if;

  end;

  procedure user_add_perm(fk_pasp_org_ in c_users_perm.fk_pasp_org%type,
    fk_reu_ in c_users_perm.fk_reu%type,
    user_id_ in t_user.id%type, fk_perm_tp_ in c_users_perm.fk_perm_tp%type,
    fk_comp_ in c_users_perm.fk_comp%type) is
  cd_ u_list.cd%type;
  begin
  --Добавляет привилегии на правку
  select t.cd into cd_ from u_list t where t.id=fk_perm_tp_;
  if cd_ in  ('доступ к карт.рэу',
    'доступ к карт.площадь',
    'доступ к карт.статус') then
  --для РЭУ
  insert into c_users_perm
    (user_id, fk_reu, fk_pasp_org, fk_perm_tp)
    select user_id_, fk_reu_, null, fk_perm_tp_ from dual
     where not exists (select * from c_users_perm c
     where c.user_id=user_id_ and c.fk_reu=fk_reu_ and
     c.fk_perm_tp=fk_perm_tp_);
  elsif cd_ = 'доступ к отчётам' then
  --для доступа к отчётам
  insert into c_users_perm
    (user_id, fk_reu, fk_pasp_org, fk_perm_tp)
    select user_id_, fk_reu_, null, fk_perm_tp_ from dual
     where not exists (select * from c_users_perm c
     where c.user_id=user_id_ and c.fk_reu=fk_reu_ and
     c.fk_perm_tp=fk_perm_tp_);
  elsif cd_='доступ к пасп.столу' then
  --для Паспортного
  insert into c_users_perm
    (user_id, fk_reu, fk_pasp_org, fk_perm_tp)
    select user_id_, null, fk_pasp_org_, fk_perm_tp_ from dual
     where not exists (select * from c_users_perm c
     where c.user_id=user_id_ and c.fk_pasp_org=fk_pasp_org_ and
     c.fk_perm_tp=fk_perm_tp_);
  elsif cd_='доступ к льготам' then
  --для редактирования льгот
  insert into c_users_perm
    (user_id, fk_reu, fk_pasp_org, fk_perm_tp)
    select user_id_, fk_reu_, null, fk_perm_tp_ from dual
     where not exists (select * from c_users_perm c
     where c.user_id=user_id_ and c.fk_reu=fk_reu_ and
     c.fk_perm_tp=fk_perm_tp_);
  elsif cd_='доступ к компьютерам' then
  --доступ к компьютерам
  insert into c_users_perm
    (user_id, fk_reu, fk_comp, fk_perm_tp)
    select user_id_, null, fk_comp_, fk_perm_tp_ from dual
     where not exists (select * from c_users_perm c
     where c.user_id=user_id_ and c.fk_comp=fk_comp_ and
     c.fk_perm_tp=fk_perm_tp_);
  end if;
  commit;
  end;

  procedure user_del_perm(fk_pasp_org_ in c_users_perm.fk_pasp_org%type,
    fk_reu_ in c_users_perm.fk_reu%type,
    user_id_ in t_user.id%type, fk_perm_tp_ in c_users_perm.fk_perm_tp%type,
    fk_comp_ in c_users_perm.fk_comp%type) is
  cd_ u_list.cd%type;
  begin
  --Удаляет привилегии на правку
  select t.cd into cd_ from u_list t where t.id=fk_perm_tp_;
  if cd_ in ('доступ к карт.рэу',
    'доступ к карт.площадь',
    'доступ к карт.статус') then
  --для РЭУ
    delete from c_users_perm c where
    c.fk_reu=fk_reu_ and c.user_id=user_id_ and
    c.fk_perm_tp=fk_perm_tp_;
  elsif cd_ = 'доступ к отчётам' then
  --для доступа к отчётам
    delete from c_users_perm c where
    c.fk_reu=fk_reu_ and c.user_id=user_id_ and
    c.fk_perm_tp=fk_perm_tp_;
  elsif cd_='доступ к пасп.столу' then
  --для Паспортного
    delete from c_users_perm c where
    c.fk_pasp_org=fk_pasp_org_ and c.user_id=user_id_ and
    c.fk_perm_tp=fk_perm_tp_;
  elsif cd_='доступ к льготам' then
  --для редактирования льгот
    delete from c_users_perm c where
    c.fk_reu=fk_reu_ and c.user_id=user_id_ and
    c.fk_perm_tp=fk_perm_tp_;
  elsif cd_='доступ к компьютерам' then
  --доступ к компьютерам
    delete from c_users_perm c where
    c.fk_comp=fk_comp_ and c.user_id=user_id_ and
    c.fk_perm_tp=fk_perm_tp_;
  end if;
  commit;
  end;

procedure set_state_base(var_ in number)
is
begin
--Открытие/Закрытие базы для доступа пользователей (автоматически после перехода)
-- var_ = 0 - открыть, 1 - закрыть
update spr_params t set t.parn1=var_
  where t.fk_parcdtp ='BASE_STATE';
commit;
end;

function get_state_base
   return number
is
  state_ number;
  cnt_ number;
begin
--вернуть состояние базы
-- 0 -открыта
-- 1 -закрыта
-- 2 -неопределено (часть параметров - открыты, часть - закрыты)
begin
  select count(*) into cnt_ from spr_params t where
    t.fk_parcdtp ='BASE_STATE';
  select case when sum(t.parn1) = 0 then 0
     when sum(t.parn1) / cnt_ = 1 then 1
       else 2
         end as state into state_
        from spr_params t where
    t.fk_parcdtp ='BASE_STATE';
exception
  when others then
   Raise_application_error(-20000, 'Внимание! Некорректно кол-во параметров в справочнике параметров');
end;

return state_;

end;

procedure set_ver(ver_ in number, type_ in number)
is
begin
if nvl(type_,0) = 1 then
  --Обновление номера версии для ожидания программным обеспечением
  update params t set t.wait_ver=ver_;
else
  --Обновление номера версии программных пакетов Updater-ом
  update params t set t.ver=ver_;
end if;
commit;
end;

procedure dsb_constr
is
begin
--отключить все констрэйнты в схеме
BEGIN
  FOR c IN
  (SELECT c.owner, c.table_name, c.constraint_name
   FROM user_constraints c, user_tables t
   WHERE c.table_name = t.table_name
   AND c.status = 'ENABLED'
   ORDER BY c.constraint_type DESC)
  LOOP
    dbms_utility.exec_ddl_statement('alter table "' || c.owner || '"."' || c.table_name || '" disable constraint ' || c.constraint_name);
  END LOOP;
END;
end;
procedure enb_constr
is
begin
--включить все констрэйнты в схеме

BEGIN
  FOR c IN
  (SELECT c.owner, c.table_name, c.constraint_name
   FROM user_constraints c, user_tables t
   WHERE c.table_name = t.table_name
   AND c.status = 'DISABLED'
   ORDER BY c.constraint_type)
  LOOP
    dbms_utility.exec_ddl_statement('alter table "' || c.owner || '"."' || c.table_name || '" enable constraint ' || c.constraint_name);
  END LOOP;
END;
end;

--найти все таблицы, содержащие поле kul, выполнить с ними действие
procedure replace_kul is
begin
--поиск таблиц
dbms_output.enable;
for c in (select t.table_name, t.column_name from all_tab_cols t where t.owner='SCOTT' and upper(t.COLUMN_NAME)
    like upper('KUL') and t.TABLE_NAME not like 'V_%'
    and t.TABLE_NAME not like 'RMT_%'
    and t.TABLE_NAME not like 'KILL%'
    )
loop
   dbms_output.put_line(c.table_name);
   begin
      execute immediate 'update '||c.table_name||' t set t.kul=''1044'' where t.kul=''1033''';
   exception
   when others then
      dbms_output.put_line('Ошибка выполенния:');
      dbms_output.put_line('ERRcode - '||SQLCODE||' -ERRmsg- '||SQLERRM);
   end;
   dbms_output.put_line('Обработано строк:'||sql%rowcount);
   
end loop;
end replace_kul;

-- процедура по очистке ненужных партиций
procedure truncate_partitions is
l_mg1 varchar2(6); --начиная с партиции
l_mg2 varchar2(6); --до партиции (включительно)
l_mg varchar2(6); --текущая партиция
begin
  dbms_output.enable(1000000);
   for c in (select distinct t.mg from EXPKARTW t where t.mg <= '201706' order by t.mg) loop
     l_mg:=utils.add_months_pr(c.mg, 1);
     dbms_output.put_line('Чистится партиция:'||l_mg);
     execute immediate 'alter table EXPKARTW truncate partition mg'||l_mg;
     
   end loop;

end;

--разовая процедура по переносу пени в новую таблицу, сжатую по дням
/*procedure move_to_new_cur_pen is
i number;
i2 number;
begin
if to_char(sysdate,'YYYYMMDD') >= '20160401' then
  Raise_application_error(-20000, 'Процедура не выполняется, она уже не нужна!');
end if;

execute immediate 'truncate table a_pen_cur';
--если нет поля fk_stav, создать его!!!
i:=0;
i2:=0;
for c in (select distinct t.lsk, t.mg from a_pen_chrg t where t.fk_stav is null) loop
  i:=i+1;
  i2:=i2+1;
  update a_pen_chrg t set t.fk_stav=(select s.id
     from kart k, stav_r s where t.days between s.days1 and s.days2
                                       and k.lsk=t.lsk
                                       and k.fk_tp=s.fk_lsk_tp)
                                       where t.lsk=c.lsk and t.mg=c.mg;
  if i>=1000 then
    commit;
    i:=0;
    logger.log_(null, i2);
  end if;
  
end loop;                                     

commit;

  --Raise_application_error(-20000, 'STOP!');

for c in (select distinct t.lsk, t.mg from a_pen_chrg t where t.mg between '201601' and '201602'-- and t.lsk='01000019'
    )
loop
  
  insert into a_pen_cur
    (lsk, mg1, fk_stav, penya, summa2, curdays, dt1, dt2, mg)
    with r as
     (select t.mg1, t.day_iter, t.fk_stav, t.penya, t.summa 
     from a_pen_chrg t where t.lsk=c.lsk and t.mg=c.mg)
    select c.lsk, a.mg1, a.fk_stav, sum(a.penya) as penya, max(a.summa) as summa2,
           count(*) as curdays, min(a.day_iter) as dt1, max(a.day_iter) as dt2, c.mg
      from (select t.*,
                    row_number() over(order by mg1, day_iter) - row_number()
                     over(partition by mg1, fk_stav order by mg1, day_iter) as grp
               from r t) a
     group by a.grp, a.mg1, a.fk_stav
     having coalesce(sum(a.penya),0) <> 0;


end loop;
commit;

  
end;*/

/**
Установить номер версии обновления базы
**/
procedure set_version(p_n1 in number, p_comm in varchar2 default null) is
begin

  insert into log_version(id,
                          n1,
                          comm)
  select log_version_id.nextval as id, p_n1 as n1, p_comm
    from dual where not exists (select * from log_version t where t.n1=p_n1);                        
  
end;  

END ADMIN;
/

