CREATE OR REPLACE PACKAGE EXS.P_GIS IS
type ccur is ref cursor;
  
function get_root_eolink(p_id in number, -- Id родительского элемента
                         p_tp in varchar2 -- тип искомого элемента
                         ) return number;
  

function insert_pd_by_house(p_eol_house in number, -- Id дома в Eolink
                            p_reu in varchar2,      -- код УК (РСО) если не заполнено - то взять основные лиц счета        
                            p_eol_uk in number -- Id УК в Eolink
                              ) return number;
function insert_pd_by_uk(p_eol_uk in number -- Id uk в Eolink
                              ) return number;
function insert_pd_by_rso(p_eol_uk in number -- Id РСО в Eolink
                              ) return number;
function withdraw_pd_by_uk(p_eol_uk in number -- Id uk в Eolink
                              ) return number;
function withdraw_pd_by_house(p_eol_house in number, -- Id дома в Eolink
                              p_eol_uk in number -- Id УК в Eolink
                              ) return number;
procedure annulment_notif(
         p_kwtp_id in number, -- Id платежа
         p_ret out number -- результат
         );
procedure annulment_arch_notif(
         p_kwtp_id in number, -- Id платежа
         p_ret out number -- результат
         );
function activate_task_by_rkc(p_eol_rkc in number, -- ID РКЦ
                         p_act_cd in varchar2
                         ) return number;
function activate_task_by_uk(
                         p_act_cd in varchar2,
                         p_proc_uk in number -- процессинг УК
                         ) return number;
function activate_task_by_house(
                                 p_eol_house in number, -- Id дома в Eolink
                                 p_act_cd in varchar2,
                                 p_proc_uk in number -- процессинг УК
                                 ) return number;
procedure get_errs_menu(p_rfcur out ccur);
procedure show_errs(p_id in number, p_period in varchar2, p_rfcur out ccur);
function change_reu_by_house(p_eol_house in number, -- Id дома в Eolink
                             p_reu in exs.eolink.reu%type               
                             ) return number;

END P_GIS;
/

