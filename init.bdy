CREATE OR REPLACE PACKAGE BODY SCOTT.init IS

l_mg params.period%type;

PROCEDURE set_default_nkom is
cnt_ number;

begin

  select count(*) into cnt_ from c_comps t, t_user u, c_users_perm m,
    u_list l
    where u.id=m.user_id and m.fk_comp = t.nkom and u.cd=user
    and l.cd='доступ к компьютерам'
    and m.fk_perm_tp=l.id;

   if cnt_ = 1 then -- найдено по умолчанию не более 1 компьтера
     select t.nkom into ncomp_ from c_comps t, t_user u, c_users_perm m,
    u_list l
     where u.id=m.user_id and m.fk_comp = t.nkom and u.cd=user
      and l.cd='доступ к компьютерам'
      and m.fk_perm_tp=l.id;
   else
     ncomp_:=null; --необходимо пользователю выбрать какой комп.
   end if;
end;

PROCEDURE set_nkom(nkom_ in c_comps.nkom%type) is
begin
   ncomp_:= nkom_;
end;

FUNCTION get_role
  return t_role.name%type is
  role_name_ t_role.name%type;
begin
/* не нужно, делалось для подомового учета, коммент от 09.12.2010
  begin
   select t.role_name into role_name_ from v_cur_usxrl t;
   exception
     when others then
      Raise_application_error(-20000,
        'Внимание! Подключаемый пользователь не имеет зарегистрированный ролей в справочнике ролей');
   end;*/
   role_name_:=null;
   return role_name_;
end;

FUNCTION get_login_acc
 return number is
cnt_ number;
begin
 --входов в программу максимально допустимое в таблице пользователей
  begin
   select case when nvl(t.cnt_enters,0) = 1 and nvl(v1.cnt,0)=1 then 0
            when nvl(t.cnt_enters,0) > 1 and nvl(v.cnt,0)<=nvl(t.cnt_enters,0) then 0
            else 2 end as cnt into cnt_
    from (select count(*) as cnt from (select distinct (utl_inaddr.get_host_address(terminal))
          from sys.v_$session v
         where v.username = sys_context('USERENV', 'SESSION_USER'))) v,
         (select count(*) as cnt
          from sys.v_$session v
         where v.username = sys_context('USERENV', 'SESSION_USER')) v1,
         (select max(u.cnt_enters) as cnt_enters from t_user u where u.cd=user) t;
/*   select case when nvl(count(*),0) <= max(t.cnt_enters) then 0
          else 2
          end into cnt_
    from (select distinct (utl_inaddr.get_host_address(terminal))
          from sys.v_$session v
         where v.username = sys_context('USERENV', 'SESSION_USER')) v,
         (select u.cnt_enters from t_user u where u.cd=user) t;
*/   exception
   when others then
   logger.log_(null, 'Не удалось определить IP терминала, из-за возникшего exception в sys.utl_inaddr.get_host_address(terminal)');
 end;

  return cnt_;
end;

FUNCTION get_fio
  return t_user.name%type is
fio_ t_user.name%type;
begin
--возвращает ФИО кассира
   begin
   select name into fio_
     from t_user u where u.cd=user;
     exception
   when others then
      Raise_application_error(-20000,
        'Внимание! Подключаемый пользователь не зарегистрирован в справочнике пользователей!');
   end;
   return fio_;
end;

FUNCTION get_def_reu
  return permissions.reu%type is
reu_ permissions.reu%type;
begin
--для заявок... РЭУ по умолчанию, для справочника расценок по работам
   select MIN(trim(p.reu)) into reu_
     from t_user u, permissions p where u.cd=user and p.user_id=u.id and p.type = 0;
   return reu_;
end;

FUNCTION get_nkom
  return c_comps.nkom%type is
begin
  --возвращает текущий № компьютера
   return ncomp_;
end;

--возвращает текущий Id сессии
FUNCTION get_session_id
  return number is
begin
   return g_session_id;
end;

FUNCTION get_org_nkom
  return c_comps.fk_org%type is
fk_org_ number;
begin
  --возвращает организацию к которой принадлежит выбранный компьютер
begin
  select t.fk_org into fk_org_ from c_comps t where t.nkom=ncomp_;
  return fk_org_;
exception
  when no_data_found then
  Raise_application_error(-20000, 'Не выбран текущий компьютер!');
end;
end;

FUNCTION compare_org(p_fk_org1 IN t_org.id%TYPE, p_fk_org2 IN t_org.id%TYPE)
  return number is
l_cnt NUMBER;
begin
  --сравнить, входит ли fk_org2 в fk_org1
  --по дереву организаций
  
  --не работает, это правоприемничество в REDIR_PAY
  
  
  Raise_application_error(-20000, 'ERROR #2');
  
  SELECT nvl(count(*),0) INTO l_cnt
  FROM
  (
  SELECT t.* FROM t_org t
    CONNECT BY PRIOR t.id=t.parent_id
    START WITH t.id=p_fk_org1
  ) a
   WHERE a.id=p_fk_org2;
  --0 - не входит, 1 - входит
 IF l_cnt = 0 THEN
  RETURN 0;
 ELSE
  RETURN 1;
 END IF;
end;

FUNCTION get_cur_period
  return params.period%type is
mg_ params.period%type;
begin
  select period into mg_ from params p;
  return mg_;
end;

FUNCTION get_is_cnt_sch
  return params.cnt_sch%type is
  cnt_sch_ params.cnt_sch%type;
begin
  select nvl(cnt_sch,0) into cnt_sch_ from params p;
  return cnt_sch_;
end;

FUNCTION get_kart_ed1
  return params.kart_ed1%type is
  kart_ed1_ params.kart_ed1%type;
begin
  select nvl(kart_ed1,0) into kart_ed1_ from params p;
  return kart_ed1_;
end;

FUNCTION get_gen_exp_lst
  return params.gen_exp_lst%type is
  gen_exp_lst_ params.gen_exp_lst%type;
begin
  select nvl(gen_exp_lst,0) into gen_exp_lst_ from params p;
  return gen_exp_lst_;
end;

FUNCTION get_org_var
  return params.org_var%type is
  org_var_ params.org_var%type;
begin
  select nvl(org_var,0) into org_var_ from params p;
  return org_var_;
end;

FUNCTION get_show_exp_pay
  return params.show_exp_pay%type is
  show_exp_pay_ params.show_exp_pay%type;
begin
  --показывать оплату в развернутом виде или нет
  select nvl(show_exp_pay,0) into show_exp_pay_ from params p;
  return show_exp_pay_;
end;

FUNCTION get_have_splash
  return params.splash%type is
  splash_ params.splash%type;
begin
  select nvl(splash,0) into splash_ from params p;
  return splash_;
end;

FUNCTION recharge_bill
  return params.recharge_bill%type is
  recharge_bill_ params.recharge_bill%type;
begin
  --пересчитывать ли счет по умолчанию (галка на форме счета)
  select nvl(recharge_bill,0) into recharge_bill_ from params p;
  return recharge_bill_;
end;

FUNCTION get_errors
  return varchar2 is
  txt_ varchar2(4000);
  cnt_ number;
  i number;
begin
  i:=1;
  --Отчет показывающий ошибки в базе
  txt_:='';
  select nvl(count(*),0) into cnt_ from t_org t, t_org_tp tp where
   t.fk_orgtp=tp.id and tp.cd='РКЦ';
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'Отсутствует запись с cd="РКЦ" в справочнике t_org или t_org_tp!'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from t_org t, t_org_tp tp where
   t.fk_orgtp=tp.id and tp.cd='РКЦ';
  if cnt_ > 1 then
   txt_:=txt_||to_char(i)||'Кол-во записей с cd="РКЦ" в справочнике t_org или t_org_tp больше одной!'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from t_org t, t_org_tp tp where
   t.fk_orgtp=tp.id and tp.cd='Город';
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'Отсутствует запись с cd="Город" в справочнике t_org или t_org_tp!'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from t_org t, t_org_tp tp where
   t.fk_orgtp=tp.id and tp.cd='Паспортный стол';
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'Отсутствует запись с cd="Паспортный стол" в справочнике t_org или t_org_tp!'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from my_messages;
  if cnt_ <> 58 then
   txt_:=txt_||to_char(i)||'.Некорректное кол-во записей в my_messages... или поправить пакет init'||chr(12);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from load_memof;
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'.Некорректное кол-во записей в load_memof (будут не корректно выводиться счета)'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from spr_services;
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'.Некорректное кол-во записей в spr_services (будут не корректно выводиться счета)'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from c_status_pr;
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'.Некорректное кол-во записей в c_status_pr'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from t_org_tp t
         where t.cd='Паспортный стол';
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'.Нет записи паспортного стола в t_org_tp'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from usl_bills t
         where t.mg1 is null or t.mg2 is null;
  if cnt_ <> 0 then
   txt_:=txt_||to_char(i)||'.Не заполнен период mg1 или mg2 в usl_bills'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from t_org_tp t
         where t.cd='Город';
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'.Нет записи Города в t_org_tp'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from t_org o, t_org_tp t
         where t.cd='Город' and o.fk_orgtp=t.id;
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'.Нет записи Города в t_org_tp'||chr(13)||chr(10);
   i:=i+1;
  end if;

  return txt_;
end;

FUNCTION get_dbid
  return varchar2 is
  txt_ varchar2(50);
begin
  txt_:='';
  select dbid into txt_ from sys.v_$database;
  return txt_;
end;

--установить дату для итогового формирования (в потоках, p_thread)
procedure set_date_for_gen is
 a number;      
 l_dt date;
 last_dt date;
 first_dt date;
begin
  -- перечитать из params
  select to_date(p.period||'01','YYYYMMDD'), last_day(to_date(p.period||'01','YYYYMMDD')) 
    into first_dt, last_dt from params p;
  if sysdate > last_dt then
    -- текущая дата не находится в текущем периоде
    l_dt:=last_dt;
  elsif sysdate < first_dt then
    -- текущая дата не находится в текущем периоде
    l_dt:=first_dt;
  else
    -- текущая дата в диапазоне тек.периода
    l_dt:=trunc(sysdate);  
  end if;

  a:=set_date(l_dt);
  if a <> 1 then
    Raise_application_error(-20000, 'Ошибка установки даты формирования!');
  end if;

end;

Function set_date(dat_ in c_kwtp.dtek%type)
  return number is
  l_val number;
  l_mg v_params.period%type;
  l_cur_mg params.period%type;
  l_dt date;
begin
   select p.period into l_cur_mg from params p;
    --проверить период, если не в допустимом диапазоне, запретить вход
   l_dt:=get_period_date(get_nkom);   

   if dat_ between to_date(to_char(l_dt,'YYYYMM')||'01', 'YYYYMMDD') and 
        last_day(l_dt) then
      --дата корректна
      --установить id пользователя в глобальную переменную
      l_mg:=to_char(l_dt, 'YYYYMM');
      set_user;
      dtek_:= dat_;
      --установить даты периода для ТЕКУЩИХ ОПЕРАЦИЙ, ВЫБРАННАЯ ПОЛЬЗОВАТЕЛЕМ ДАТА!!!
      g_dt_cur_start:=to_date(to_char(dat_,'YYYYMM')||'01', 'YYYYMMDD');
      g_dt_cur_end:=last_day(g_dt_cur_start);
            
      --честно говоря, не понял, зачем здесь устанавливается дата как для текущих операций - ред. 09.02.15
      --странно. (поправил)
      --установить даты периода для процедур ФОРМИРОВАНИЯ, УСТАНОВЛЕННЫЙ ТЕКУЩИЙ ПЕРИОД!!!
--      g_dt_start:=to_date(l_mg||'01', 'YYYYMMDD');
--      g_dt_end:=last_day(g_dt_start);
      g_dt_start:=to_date(l_cur_mg||'01', 'YYYYMMDD');
      g_dt_end:=last_day(g_dt_start);

      --проверить админский доступ
      g_admin_acc:=is_allow('drx5_Админ_доступ_к_базе');
      l_val:=1;
   else
      dtek_:= null;
      --закрыть админский доступ, ждать повторного входа в программу
      g_admin_acc:=0;
      l_val:=3;
   end if;
   return l_val;
end;

FUNCTION get_date
  return c_kwtp.dtek%type is
begin
 if dtek_ is null or g_admin_acc is null then
    --закрыть админский доступ, ждать повторного входа в программу
    g_admin_acc:=0;
    --пустая дата может быть следствием перекомпиляции пакета
    Raise_application_error(-20000, 'Внимание! Обновлен программный код, необходимо перезайти в приложение!');
 end if;
 return dtek_;
end;

function is_allow (name_ in varchar2) return number
  is
cnt_ number;
begin
  --провека доступа к ПРОЦЕДУРЕ (drnx...)
  --ГРАНТ НА drx5_админ_доступ_к_базе НАДО давать непосредственно
  --ПОЛЬЗОВАТЕЛЮ!!!!!!!!!!
  --0 - даны права, 1 - не даны
  select nvl(count(*),0) into cnt_ from (
  select 1 from sys.table_privileges t
  where exists (select * from sys.dba_role_privs u where u.granted_role=t.grantee
   and t.grantee=user)
  and upper(t.table_name)=upper(name_)
  union all
  select 1 from sys.table_privileges t
  where upper(t.table_name)=upper(name_)
  and t.grantee=user);

  if cnt_ > 0 then
    cnt_:=1;
  end if;
  return cnt_;
end;

function is_allow_acc(l_obj_name in varchar2) return number
  is
l_cnt number;
begin
  --провека доступа к ПРОЦЕДУРЕ (drnx...)
  --проверяет в том числе прямой доступ к объекту, так и
  --через роль
  --1 - даны права, 0 - не даны
  select nvl(count(*),0) into l_cnt from (
    select 1 as cnt from sys.dba_tab_privs t where t.grantee=upper(user)
     and upper(t.table_name)=upper(l_obj_name)
    union all
    select 2 as cnt from sys.table_privileges t
     where exists
     (select granted_role from dba_role_privs d
       where d.GRANTED_ROLE=t.GRANTEE
       start with grantee = upper(user)
       connect by prior granted_role = grantee
     )
     and upper(t.table_name)=upper(l_obj_name)
 );

  if l_cnt > 0 then
    --даны
    l_cnt:=1;
    else
    --не даны
    l_cnt:=0;
  end if;
  return l_cnt;
end;

procedure set_user is
begin
   --установить id пользователя в глобальную переменную
   select u.id into g_user from t_user u where u.cd=user;
end;

Function check_date(dat_ in c_kwtp.dtek%type)
  return number is
  valid_ number;
begin
   select case when p.period=to_char(dat_,'YYYYMM') then 1 else 0 end  into valid_
    from params p;
   return valid_;
end;

function get_dt_start
  return c_kwtp.dtek%type is
begin
--вернуть начальную дату УСТАНОВЛЕННОЙ СИСТЕМОЙ месяца (используется обычно в запросах)
  if g_dt_start is null then
    Raise_application_error(-20000, 'Внимание! Не задано g_dt_start!');
  end if;
 return g_dt_start;   
end;

function get_dt_end
  return c_kwtp.dtek%type is 
begin
--вернуть конечную дату УСТАНОВЛЕННОЙ СИСТЕМОЙ месяца (используется обычно в запросах)
  if g_dt_end is null then
    Raise_application_error(-20000, 'Внимание! Не задано g_dt_end!');
  end if;
 return g_dt_end;   
end; 
  
function get_cur_dt_start
  return c_kwtp.dtek%type is
begin
--вернуть начальную дату ВЫБРАННОГО ПОЛЬЗОВАТЕЛЕМ месяца (используется обычно в запросах)
  if g_dt_cur_start is null then
    Raise_application_error(-20000, 'Внимание! Не задано g_dt_cur_start!');
  end if;
 return g_dt_cur_start;     
end;

function get_cur_dt_end
  return c_kwtp.dtek%type is
begin
--вернуть конечную дату ВЫБРАННОГО ПОЛЬЗОВАТЕЛЕМ месяца (используется обычно в запросах)
  if g_dt_cur_end is null then
    Raise_application_error(-20000, 'Внимание! Не задано g_dt_cur_end!');
  end if;
 return g_dt_cur_end;   
end;

FUNCTION get_period_date(p_nkom in c_comps.nkom%type)
  return c_kwtp.dtek%type is
  rec_ v_params%rowtype;
  l_period c_comps.period%type;
begin
 --рекомендовать дату для выбора при старте программы
 select p.* into rec_
    from v_params p;
 select max(t.period) into l_period
   from c_comps t where t.nkom=p_nkom;   

 if l_period is null then
   --не указан рабочий период для компьютера
   if trunc(sysdate) between to_date(rec_.period||'01', 'YYYYMMDD') 
       and last_day(to_date(rec_.period||'01', 'YYYYMMDD'))
       and rec_.period=to_char(sysdate, 'YYYYMM') then
     --если переход выполнен и системная дата в пределах текущего периода
     dtek_:=trunc(sysdate);
   else
     --если переход не выполнен и системная дата не в тек.периоде
     dtek_:=last_day( to_date(rec_.period||'01', 'YYYYMMDD'));
   end if;
 else
   --указан рабочий период для компьютера
   if l_period=rec_.period1 then
    --указан будущий период 
    if trunc(sysdate) between to_date(rec_.period1||'01', 'YYYYMMDD') 
      and last_day(to_date(rec_.period1||'01', 'YYYYMMDD')) then
     --системная дата в текущем периоде
     dtek_:=trunc(sysdate);
    else
     --некорректная сист.дата
     dtek_:=to_date(rec_.period1||'01', 'YYYYMMDD');
    end if;
   else
    --указан почему то другой период (может и текущий), проверить его всё равно
    if trunc(sysdate) between to_date(rec_.period||'01', 'YYYYMMDD') 
      and last_day(to_date(rec_.period||'01', 'YYYYMMDD')) then
     --системная дата в текущем периоде
     dtek_:=trunc(sysdate);
    else
     --некорректная сист.дата
     dtek_:=to_date(rec_.period||'01', 'YYYYMMDD');
    end if;
   end if;
 end if;

   
 return dtek_;
end;

FUNCTION get_period
  return params.period%type is
begin
 --текущий период, установленный пользователем
 if g_period is null then
   g_period:=to_char(get_cur_dt_start,'YYYYMM');
 end if;
 return g_period;
end;

procedure set_state(state_ in params.state_base_%type) is
begin
  --установить состояние базы (выполнено ли итоговое формирование всех
  --отчетов)
  update params p set p.state_base_=state_;
  commit;
end;

Function get_state
  return number is
  state_ number;
begin
  --показать состояние базы (выполнено ли итоговое формирование всех
  --отчетов)
  select nvl(p.state_base_,0) into state_ from params p;
  return state_;
end;

Function get_user
  return number is
begin
  --вернуть ID пользователя из глобальной переменной,
  --установленой на входе в приложение
  if g_user is null then
    Raise_application_error(-20000,
     'Внимание!Не обнаружен ID пользователя, возможно обновлен программный код, необходимо перезайти в приложение!');
  end if;
  return g_user;
end;

Function get_load_dir
  return varchar2 is
 dir_ varchar2(1000);
begin
  --показать состояние базы (выполнено ли итоговое формирование всех
  --отчетов)
  select t.directory_path into dir_
   from sys.dba_directories t where t.directory_name='LOAD_FILE_DIR';
   return dir_;
end;

function get_unq_comp return number is
l_id number;
begin
  --получить уникальный номер компьютера,
  --который записан в licenses.ini  
  --применяется для обновления файлов для программы
  select c_comp_id.nextval into l_id from dual;
  return l_id;
end;

--ИНИЦИАЛИЗАЦИЯ PACKAGE--
begin
   --установить даты периода для процедур ФОРМИРОВАНИЯ, УСТАНОВЛЕННЫЙ ТЕКУЩИЙ ПЕРИОД!!!
    --проверить период, если больше текущего на 2 и более месяцев, запретить
   select p.period
     into l_mg
    from params p;
    g_dt_start:=to_date(l_mg||'01', 'YYYYMMDD');
    g_dt_end:=last_day(g_dt_start);
    g_java_server_url:=utils.get_str_param('JAVA_SERVER_URL');
END init;
/

