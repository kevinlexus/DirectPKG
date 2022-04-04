create or replace package scott.init is
ncomp_ c_kwtp.nkom%type;
dtek_ c_kwtp.dtek%type;
spr_tarif_upd_ number;
g_admin_acc number;
g_user number;
g_java_server_url varchar2(1024);

-- Id сессии, устанавливается в UTILS.prep_users_tree
g_session_id number;
--начальная дата месяца
g_dt_start date;
--конечная дата месяца
g_dt_end date;
--текущий период
g_period params.period%type;

--начальная дата месяца, для текущих операций
g_dt_cur_start date;
--конечная дата месяца, для текущих операций
g_dt_cur_end date;

PROCEDURE set_nkom(nkom_ in c_comps.nkom%type);
FUNCTION get_nkom return c_comps.nkom%type;
FUNCTION get_session_id return number;
FUNCTION get_org_nkom
  return c_comps.fk_org%type;
FUNCTION compare_org(p_fk_org1 IN t_org.id%TYPE, p_fk_org2 IN t_org.id%TYPE)
  return number;
FUNCTION get_role return t_role.name%type;

FUNCTION get_login_acc
 return number;

FUNCTION get_fio
  return t_user.name%type;

FUNCTION get_def_reu
  return permissions.reu%type;

FUNCTION get_cur_period
  return params.period%type;

FUNCTION get_kart_ed1
  return params.kart_ed1%type;

FUNCTION get_is_cnt_sch
  return params.cnt_sch%type;

FUNCTION get_gen_exp_lst
  return params.gen_exp_lst%type;

FUNCTION get_org_var
  return params.org_var%type;

FUNCTION get_show_exp_pay
  return params.show_exp_pay%type;

FUNCTION get_have_splash
  return params.splash%type;

FUNCTION recharge_bill
  return params.recharge_bill%type;

FUNCTION get_errors
  return varchar2;
FUNCTION get_dbid
  return varchar2;
--установить дату для итогового формирования (в потоках, p_thread)
procedure set_date_for_gen;
Function set_date(dat_ in c_kwtp.dtek%type)
  return number;
function is_allow (name_ in varchar2) return number;
function is_allow_acc(l_obj_name in varchar2) return number;

procedure set_user;

Function check_date(dat_ in c_kwtp.dtek%type)
  return number;
FUNCTION get_date return c_kwtp.dtek%type;

function get_dt_start
  return c_kwtp.dtek%type;
function get_dt_end
  return c_kwtp.dtek%type;
function get_cur_dt_start
  return c_kwtp.dtek%type;
function get_cur_dt_end
  return c_kwtp.dtek%type;

FUNCTION get_period_date(p_nkom in c_comps.nkom%type) return c_kwtp.dtek%type;
FUNCTION get_period
  return params.period%type;
procedure set_state(state_ in params.state_base_%type);
Function get_state
  return number;
Function get_user
  return number;
Function get_load_dir
  return varchar2;
function get_unq_comp return number;

end init;
/

