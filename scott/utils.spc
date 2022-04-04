create or replace package scott.utils is
 --глобальная переменная для триггера, для добавления нового spk_id
 spk_id_ spk.id%type;
 --sprorg_kod_ sprorg.kod%type;
 spr_tarif_id_ spr_tarif.id%type;
 spr_tarif_root_id_ spr_tarif.id%type;
 oper_ oper.oper%type;

 function MONTH_NAME1(month_ NUMBER) RETURN varchar2;
 function MONTH_NAME(month_ NUMBER) RETURN VARCHAR2;
 function add_months_pr(mg_ in varchar2, cnt_ in number) return varchar2;
 FUNCTION get_org_lsk(p_lsk IN kart.lsk%TYPE)
           RETURN NUMBER;
 FUNCTION get_nkom_pay_lsk(p_lsk IN kart.lsk%TYPE)
    RETURN c_comps.nkom%type;
 function GET_LSK_BY_ADR(kul_ kart.kul%TYPE, nd_ kart.nd%TYPE, kw_ kart.kw%TYPE)
           RETURN VARCHAR2;
 function GET_C_LSK_ID_BY_ADR(kul_ kart.kul%TYPE, nd_ kart.nd%TYPE, kw_ kart.kw%TYPE)
           RETURN VARCHAR2;
function GET_LSK_BY_ADR2(house_id_ kart.house_id%TYPE, kw_ kart.kw%TYPE)
           RETURN VARCHAR2;
 function GET_LSK_BY_ADR3(house_id_ kart.house_id%TYPE, kw_ kart.kw%TYPE)
           RETURN kart.k_lsk_id%type;
 function GET_LSK_BY_ADR4(house_id_ kart.house_id%TYPE, kw_ kart.kw%TYPE)
           RETURN kart.c_lsk_id%type;
 function GET_K_LSK_ID_BY_LSK(lsk_ kart.lsk%TYPE)
           RETURN kart.k_lsk_id%type;
 function GET_C_LSK_ID_BY_LSK(lsk_ kart.lsk%TYPE)
           RETURN kart.c_lsk_id%type;
 function GET_ADR_BY_LSK(lsk_ kart.lsk%TYPE)
           RETURN varchar2;
 function ALLOW_FUNCT(fk_type_ in number)
           RETURN NUMBER;
  function ALLOW_EDIT_LSK(lsk_ kart.lsk%TYPE, cd_ in varchar2)
           RETURN NUMBER;
  function ALLOW_EDIT_LSK_BY_REU(p_reu in varchar2, p_pasp_org in number, p_cd in varchar2)
           RETURN NUMBER;
 function ALLOW_CR_NEW_LSK(lsk_ kart.lsk%TYPE)
           RETURN NUMBER;
 function ALLOW_CHANGES_LSK(lsk_ kart.lsk%TYPE)
           RETURN NUMBER;
 function GET_NEW_LSK (lsk_ in kart.lsk%TYPE, p_lsk in kart.lsk%TYPE)
           RETURN kart.lsk%type;
 FUNCTION GET_NEW_LSK_BY_REU(p_reu kart.reu%TYPE) RETURN kart.lsk%TYPE;
 procedure ins_lg_doc (kart_pr_id_ in c_kart_pr.id%type);
 procedure del_lg_doc (c_lg_docs_id_ in c_lg_docs.id%type);
 procedure count_krt_kpr (lsk_ in kart.lsk%type);
 function count_krt_kpr (user_id_ in number) return number;
 function get_report_name (id_ in number)
   return varchar2;
 function get_sum_str_2(source in number) return varchar2;
 function f_order(str_ varchar2, len_ number) return varchar2;
 function f_order2(str_ varchar2) return varchar2;
 function f_ord2(str_ varchar2) return varchar2;
 function f_ord3(p_str varchar2) return varchar2;
 function f_ord_digit(p_str varchar2) return number;
 function add_months2(mg_ in varchar2, months_ in number) return varchar2;
 procedure prep_users_tree;
 procedure prep_users_par;
 function concatenate(v_rownum    number,
                     v_string    varchar2,
                     v_delimiter varchar2 default null,
                     v_call_id number default 1) return varchar2;
 function tst_krt(lsk_ in kart.lsk%type, var_ in number) return varchar2;
 procedure set_kpr(lsk_ in kart.lsk%type);
 procedure set_krt_adm (lsk_ in c_kart_pr.lsk%type);
-- procedure set_krt_adm2 (fk_kart_pr_ in c_kart_pr.id%type);
 procedure upd_c_kart_pr_state(fk_kart_pr_ in c_kart_pr.id%type);
 function add_list(cdtp_ in u_listtp.cd%type, cd_ in u_list.cd%type,
   name_ in u_list.name%type) return number;
 procedure add_usl(uslm_ in usl.uslm%type, prefix_ in varchar2,
   name_ in varchar2, name2_ in usl.nm2%type, cd_ in usl.cd%type,
   price_ in prices.summa%type, org_ in nabor.org%type,
   koeff_ in nabor.koeff%type, norm_ in nabor.norm%type,
   usl_koeff_ in usl.usl%type, usl_norm_ in usl.usl%type,
   usl_org_ in usl.usl%type);
 procedure usl_add_flds;
 function del_lsk(lsk_ in kart.lsk%type) return varchar2;
 -- удалить лиц.счет без проверок
function del_lsk_wo_check(lsk_ in kart.lsk%type) return varchar2;
procedure del_usl(usl_ in usl.usl%type);
 procedure del_uslm(uslm_ in usl.uslm%type);
 procedure cp_price(err_ out number, err_str_ out varchar2,
   usl_ in prices.usl%type, fk_org_src_ in prices.fk_org%type,
   fk_org_dst_ in prices.fk_org%type);
 procedure del_price(usl_ in prices.usl%type, fk_org_ in prices.fk_org%type);
 function set_int_param(l_cd spr_params.cd%type,
     l_val spr_params.parn1%type) return spr_params.id%type;
 function get_int_param(cd_ varchar2) return spr_params.parn1%type ;
 function getS_int_param(cd_ varchar2) return spr_params.parn1%type;
 function get_bool_param(cd_ varchar2) return spr_params.parn1%type;
 function getS_bool_param(cd_ varchar2) return spr_params.parn1%type;
 function get_str_param(cd_ varchar2) return spr_params.parvc1%type;
 function getS_str_param(cd_ varchar2) return spr_params.parvc1%type;
 function get_date_param(cd_ varchar2) return spr_params.pardt1%type;
 function getS_date_param(cd_ varchar2) return spr_params.pardt1%type;
 function getS_list_param(cd_ varchar2) return list_c.sel_id%type;
 function getScd_list_param(cd_ varchar2) return list_c.sel_cd%type;
 procedure fill_list_c (fk_par_ in spr_params.id%type);
 procedure set_list_c (fk_par_ in spr_params.id%type, id_ in list_c.id%type);
 procedure rep_add_param (fk_rep_ in reports.id%type, fk_par_ in spr_params.id%type);
 procedure rep_del_param (fk_rep_ in reports.id%type, fk_par_ in spr_params.id%type);
 function have_sch(p_lsk in kart.lsk%type, p_counter in usl.counter%type) return number;
 procedure upd_krt_sch_state(lsk_ in kart.lsk%type);
 function set_krt_psch (dat_ in c_states_sch.dt1%type,
   fk_status_ in c_states_sch.fk_status%type, lsk_ in kart.lsk%type) return integer;
 function set_base_state_gen(l_set in number) return number;

 --проверка справочника redir_pay
 function check_redir_pay return number;
end utils;
/

