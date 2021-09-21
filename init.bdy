CREATE OR REPLACE PACKAGE BODY SCOTT.init IS

l_mg params.period%type;

PROCEDURE set_default_nkom is
cnt_ number;

begin

  select count(*) into cnt_ from c_comps t, t_user u, c_users_perm m,
    u_list l
    where u.id=m.user_id and m.fk_comp = t.nkom and u.cd=user
    and l.cd='������ � �����������'
    and m.fk_perm_tp=l.id;

   if cnt_ = 1 then -- ������� �� ��������� �� ����� 1 ���������
     select t.nkom into ncomp_ from c_comps t, t_user u, c_users_perm m,
    u_list l
     where u.id=m.user_id and m.fk_comp = t.nkom and u.cd=user
      and l.cd='������ � �����������'
      and m.fk_perm_tp=l.id;
   else
     ncomp_:=null; --���������� ������������ ������� ����� ����.
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
/* �� �����, �������� ��� ���������� �����, ������� �� 09.12.2010
  begin
   select t.role_name into role_name_ from v_cur_usxrl t;
   exception
     when others then
      Raise_application_error(-20000,
        '��������! ������������ ������������ �� ����� ������������������ ����� � ����������� �����');
   end;*/
   role_name_:=null;
   return role_name_;
end;

FUNCTION get_login_acc
 return number is
cnt_ number;
begin
 --������ � ��������� ����������� ���������� � ������� �������������
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
   logger.log_(null, '�� ������� ���������� IP ���������, ��-�� ���������� exception � sys.utl_inaddr.get_host_address(terminal)');
 end;

  return cnt_;
end;

FUNCTION get_fio
  return t_user.name%type is
fio_ t_user.name%type;
begin
--���������� ��� �������
   begin
   select name into fio_
     from t_user u where u.cd=user;
     exception
   when others then
      Raise_application_error(-20000,
        '��������! ������������ ������������ �� ��������������� � ����������� �������������!');
   end;
   return fio_;
end;

FUNCTION get_def_reu
  return permissions.reu%type is
reu_ permissions.reu%type;
begin
--��� ������... ��� �� ���������, ��� ����������� �������� �� �������
   select MIN(trim(p.reu)) into reu_
     from t_user u, permissions p where u.cd=user and p.user_id=u.id and p.type = 0;
   return reu_;
end;

FUNCTION get_nkom
  return c_comps.nkom%type is
begin
  --���������� ������� � ����������
   return ncomp_;
end;

--���������� ������� Id ������
FUNCTION get_session_id
  return number is
begin
   return g_session_id;
end;

FUNCTION get_org_nkom
  return c_comps.fk_org%type is
fk_org_ number;
begin
  --���������� ����������� � ������� ����������� ��������� ���������
begin
  select t.fk_org into fk_org_ from c_comps t where t.nkom=ncomp_;
  return fk_org_;
exception
  when no_data_found then
  Raise_application_error(-20000, '�� ������ ������� ���������!');
end;
end;

FUNCTION compare_org(p_fk_org1 IN t_org.id%TYPE, p_fk_org2 IN t_org.id%TYPE)
  return number is
l_cnt NUMBER;
begin
  --��������, ������ �� fk_org2 � fk_org1
  --�� ������ �����������
  
  --�� ��������, ��� ������������������ � REDIR_PAY
  
  
  Raise_application_error(-20000, 'ERROR #2');
  
  SELECT nvl(count(*),0) INTO l_cnt
  FROM
  (
  SELECT t.* FROM t_org t
    CONNECT BY PRIOR t.id=t.parent_id
    START WITH t.id=p_fk_org1
  ) a
   WHERE a.id=p_fk_org2;
  --0 - �� ������, 1 - ������
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
  --���������� ������ � ����������� ���� ��� ���
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
  --������������� �� ���� �� ��������� (����� �� ����� �����)
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
  --����� ������������ ������ � ����
  txt_:='';
  select nvl(count(*),0) into cnt_ from t_org t, t_org_tp tp where
   t.fk_orgtp=tp.id and tp.cd='���';
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'����������� ������ � cd="���" � ����������� t_org ��� t_org_tp!'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from t_org t, t_org_tp tp where
   t.fk_orgtp=tp.id and tp.cd='���';
  if cnt_ > 1 then
   txt_:=txt_||to_char(i)||'���-�� ������� � cd="���" � ����������� t_org ��� t_org_tp ������ �����!'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from t_org t, t_org_tp tp where
   t.fk_orgtp=tp.id and tp.cd='�����';
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'����������� ������ � cd="�����" � ����������� t_org ��� t_org_tp!'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from t_org t, t_org_tp tp where
   t.fk_orgtp=tp.id and tp.cd='���������� ����';
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'����������� ������ � cd="���������� ����" � ����������� t_org ��� t_org_tp!'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from my_messages;
  if cnt_ <> 58 then
   txt_:=txt_||to_char(i)||'.������������ ���-�� ������� � my_messages... ��� ��������� ����� init'||chr(12);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from load_memof;
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'.������������ ���-�� ������� � load_memof (����� �� ��������� ���������� �����)'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from spr_services;
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'.������������ ���-�� ������� � spr_services (����� �� ��������� ���������� �����)'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from c_status_pr;
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'.������������ ���-�� ������� � c_status_pr'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from t_org_tp t
         where t.cd='���������� ����';
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'.��� ������ ����������� ����� � t_org_tp'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from usl_bills t
         where t.mg1 is null or t.mg2 is null;
  if cnt_ <> 0 then
   txt_:=txt_||to_char(i)||'.�� �������� ������ mg1 ��� mg2 � usl_bills'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from t_org_tp t
         where t.cd='�����';
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'.��� ������ ������ � t_org_tp'||chr(13)||chr(10);
   i:=i+1;
  end if;

  select nvl(count(*),0) into cnt_ from t_org o, t_org_tp t
         where t.cd='�����' and o.fk_orgtp=t.id;
  if cnt_ = 0 then
   txt_:=txt_||to_char(i)||'.��� ������ ������ � t_org_tp'||chr(13)||chr(10);
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

--���������� ���� ��� ��������� ������������ (� �������, p_thread)
procedure set_date_for_gen is
 a number;      
 l_dt date;
 last_dt date;
 first_dt date;
begin
  -- ���������� �� params
  select to_date(p.period||'01','YYYYMMDD'), last_day(to_date(p.period||'01','YYYYMMDD')) 
    into first_dt, last_dt from params p;
  if sysdate > last_dt then
    -- ������� ���� �� ��������� � ������� �������
    l_dt:=last_dt;
  elsif sysdate < first_dt then
    -- ������� ���� �� ��������� � ������� �������
    l_dt:=first_dt;
  else
    -- ������� ���� � ��������� ���.�������
    l_dt:=trunc(sysdate);  
  end if;

  a:=set_date(l_dt);
  if a <> 1 then
    Raise_application_error(-20000, '������ ��������� ���� ������������!');
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
    --��������� ������, ���� �� � ���������� ���������, ��������� ����
   l_dt:=get_period_date(get_nkom);   

   if dat_ between to_date(to_char(l_dt,'YYYYMM')||'01', 'YYYYMMDD') and 
        last_day(l_dt) then
      --���� ���������
      --���������� id ������������ � ���������� ����������
      l_mg:=to_char(l_dt, 'YYYYMM');
      set_user;
      dtek_:= dat_;
      --���������� ���� ������� ��� ������� ��������, ��������� ������������� ����!!!
      g_dt_cur_start:=to_date(to_char(dat_,'YYYYMM')||'01', 'YYYYMMDD');
      g_dt_cur_end:=last_day(g_dt_cur_start);
            
      --������ ������, �� �����, ����� ����� ��������������� ���� ��� ��� ������� �������� - ���. 09.02.15
      --�������. (��������)
      --���������� ���� ������� ��� �������� ������������, ������������� ������� ������!!!
--      g_dt_start:=to_date(l_mg||'01', 'YYYYMMDD');
--      g_dt_end:=last_day(g_dt_start);
      g_dt_start:=to_date(l_cur_mg||'01', 'YYYYMMDD');
      g_dt_end:=last_day(g_dt_start);

      --��������� ��������� ������
      g_admin_acc:=is_allow('drx5_�����_������_�_����');
      l_val:=1;
   else
      dtek_:= null;
      --������� ��������� ������, ����� ���������� ����� � ���������
      g_admin_acc:=0;
      l_val:=3;
   end if;
   return l_val;
end;

FUNCTION get_date
  return c_kwtp.dtek%type is
begin
 if dtek_ is null or g_admin_acc is null then
    --������� ��������� ������, ����� ���������� ����� � ���������
    g_admin_acc:=0;
    --������ ���� ����� ���� ���������� �������������� ������
    Raise_application_error(-20000, '��������! �������� ����������� ���, ���������� ��������� � ����������!');
 end if;
 return dtek_;
end;

function is_allow (name_ in varchar2) return number
  is
cnt_ number;
begin
  --������� ������� � ��������� (drnx...)
  --����� �� drx5_�����_������_�_���� ���� ������ ���������������
  --������������!!!!!!!!!!
  --0 - ���� �����, 1 - �� ����
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
  --������� ������� � ��������� (drnx...)
  --��������� � ��� ����� ������ ������ � �������, ��� �
  --����� ����
  --1 - ���� �����, 0 - �� ����
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
    --����
    l_cnt:=1;
    else
    --�� ����
    l_cnt:=0;
  end if;
  return l_cnt;
end;

procedure set_user is
begin
   --���������� id ������������ � ���������� ����������
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
--������� ��������� ���� ������������� �������� ������ (������������ ������ � ��������)
  if g_dt_start is null then
    Raise_application_error(-20000, '��������! �� ������ g_dt_start!');
  end if;
 return g_dt_start;   
end;

function get_dt_end
  return c_kwtp.dtek%type is 
begin
--������� �������� ���� ������������� �������� ������ (������������ ������ � ��������)
  if g_dt_end is null then
    Raise_application_error(-20000, '��������! �� ������ g_dt_end!');
  end if;
 return g_dt_end;   
end; 
  
function get_cur_dt_start
  return c_kwtp.dtek%type is
begin
--������� ��������� ���� ���������� ������������� ������ (������������ ������ � ��������)
  if g_dt_cur_start is null then
    Raise_application_error(-20000, '��������! �� ������ g_dt_cur_start!');
  end if;
 return g_dt_cur_start;     
end;

function get_cur_dt_end
  return c_kwtp.dtek%type is
begin
--������� �������� ���� ���������� ������������� ������ (������������ ������ � ��������)
  if g_dt_cur_end is null then
    Raise_application_error(-20000, '��������! �� ������ g_dt_cur_end!');
  end if;
 return g_dt_cur_end;   
end;

FUNCTION get_period_date(p_nkom in c_comps.nkom%type)
  return c_kwtp.dtek%type is
  rec_ v_params%rowtype;
  l_period c_comps.period%type;
begin
 --������������� ���� ��� ������ ��� ������ ���������
 select p.* into rec_
    from v_params p;
 select max(t.period) into l_period
   from c_comps t where t.nkom=p_nkom;   

 if l_period is null then
   --�� ������ ������� ������ ��� ����������
   if trunc(sysdate) between to_date(rec_.period||'01', 'YYYYMMDD') 
       and last_day(to_date(rec_.period||'01', 'YYYYMMDD'))
       and rec_.period=to_char(sysdate, 'YYYYMM') then
     --���� ������� �������� � ��������� ���� � �������� �������� �������
     dtek_:=trunc(sysdate);
   else
     --���� ������� �� �������� � ��������� ���� �� � ���.�������
     dtek_:=last_day( to_date(rec_.period||'01', 'YYYYMMDD'));
   end if;
 else
   --������ ������� ������ ��� ����������
   if l_period=rec_.period1 then
    --������ ������� ������ 
    if trunc(sysdate) between to_date(rec_.period1||'01', 'YYYYMMDD') 
      and last_day(to_date(rec_.period1||'01', 'YYYYMMDD')) then
     --��������� ���� � ������� �������
     dtek_:=trunc(sysdate);
    else
     --������������ ����.����
     dtek_:=to_date(rec_.period1||'01', 'YYYYMMDD');
    end if;
   else
    --������ ������ �� ������ ������ (����� � �������), ��������� ��� �� �����
    if trunc(sysdate) between to_date(rec_.period||'01', 'YYYYMMDD') 
      and last_day(to_date(rec_.period||'01', 'YYYYMMDD')) then
     --��������� ���� � ������� �������
     dtek_:=trunc(sysdate);
    else
     --������������ ����.����
     dtek_:=to_date(rec_.period||'01', 'YYYYMMDD');
    end if;
   end if;
 end if;

   
 return dtek_;
end;

FUNCTION get_period
  return params.period%type is
begin
 --������� ������, ������������� �������������
 if g_period is null then
   g_period:=to_char(get_cur_dt_start,'YYYYMM');
 end if;
 return g_period;
end;

procedure set_state(state_ in params.state_base_%type) is
begin
  --���������� ��������� ���� (��������� �� �������� ������������ ����
  --�������)
  update params p set p.state_base_=state_;
  commit;
end;

Function get_state
  return number is
  state_ number;
begin
  --�������� ��������� ���� (��������� �� �������� ������������ ����
  --�������)
  select nvl(p.state_base_,0) into state_ from params p;
  return state_;
end;

Function get_user
  return number is
begin
  --������� ID ������������ �� ���������� ����������,
  --������������ �� ����� � ����������
  if g_user is null then
    Raise_application_error(-20000,
     '��������!�� ��������� ID ������������, �������� �������� ����������� ���, ���������� ��������� � ����������!');
  end if;
  return g_user;
end;

Function get_load_dir
  return varchar2 is
 dir_ varchar2(1000);
begin
  --�������� ��������� ���� (��������� �� �������� ������������ ����
  --�������)
  select t.directory_path into dir_
   from sys.dba_directories t where t.directory_name='LOAD_FILE_DIR';
   return dir_;
end;

function get_unq_comp return number is
l_id number;
begin
  --�������� ���������� ����� ����������,
  --������� ������� � licenses.ini  
  --����������� ��� ���������� ������ ��� ���������
  select c_comp_id.nextval into l_id from dual;
  return l_id;
end;

--������������� PACKAGE--
begin
   --���������� ���� ������� ��� �������� ������������, ������������� ������� ������!!!
    --��������� ������, ���� ������ �������� �� 2 � ����� �������, ���������
   select p.period
     into l_mg
    from params p;
    g_dt_start:=to_date(l_mg||'01', 'YYYYMMDD');
    g_dt_end:=last_day(g_dt_start);
    g_java_server_url:=utils.get_str_param('JAVA_SERVER_URL');
END init;
/

