create or replace package scott.C_CHARGES is
 --глобальные переменные для триггера
 nabor_lsk_ nabor.lsk%type;
 nabor_lsk2_ nabor.lsk%type;

 chng_relat_id number;
 trg_c_lg_docs_bd number;
 trg_c_lg_docs_bd_fio c_kart_pr.fio%type;
 trg_c_lg_docs_bd_lsk c_kart_pr.lsk%type;

 type t_lsk is table of kart.lsk%type;
 tab_lsk t_lsk := t_lsk(null);

-- type t_vvod_id is table of c_vvod.id%type;
-- tab_vvod_id t_vvod_id := t_vvod_id(null);

 type t_c_kart_pr_id is table of c_kart_pr.id%type;
 tab_c_kart_pr_id t_c_kart_pr_id := t_c_kart_pr_id(null);

 trg_kart_flag number;
 trg_t_org_flag number;
 --флаг для использования в скриптах
 scr_flag_ number;
 --флаг снятия логгинга при удалении строк в переходе месяца
 trg_proc_next_month number;
 --флаг-признак работы в скрипте (первонач. загрузка данных)
 debug_flag_ number;

 --Таблица лиц. по которым обновились определенные поля в триггере
 type t_klsk is table of number;
 trg_tab_klsk t_klsk := t_klsk(null);
 --флаг, для триггера
 trg_klsk_flag number;
  
 --структуры для использования в триггерах по c_states_sch
 type trg_states is record
 (
  id c_states_sch.id%type,
  lsk c_states_sch.lsk%type,
  dt1 c_states_sch.dt1%type,
  dt2 c_states_sch.dt2%type
 );
 trg_rec_states trg_states;
 type tab_rec_states is table of trg_rec_states%type;
 tb_rec_states tab_rec_states := tab_rec_states(null);

 --структуры для использования в триггерах по c_states_pr
 type trg_pr_states is record
 (
  id c_states_pr.id%type,
  fk_kart_pr c_states_pr.id%type,
  fk_tp c_states_pr.id%type,
  dt1 c_states_pr.dt1%type,
  dt2 c_states_pr.dt2%type
 );
 trg_rec_pr_states trg_pr_states;
 type tab_rec_pr_states is table of trg_rec_pr_states%type;
 tb_rec_pr_states tab_rec_pr_states := tab_rec_pr_states(null);

 trg_c_kart_pr_flag number;
 trg_c_kart_pr_bd number;
 trg_c_kart_pr_bd_fio c_kart_pr.fio%type;
 trg_c_kart_pr_bd_lsk c_kart_pr.lsk%type;
 trg_c_vvod number; --флаг, чтобы правильно писать в лог описание процесса

 function get_upd_tab return tab_rec_states
  parallel_enable pipelined;
 FUNCTION gen_charges_sch(lsk_ VARCHAR2, usl_ in usl.usl%type, var_ in number, cnt_ in number)
   return number;
 PROCEDURE gen_chrg_all(p_lvl     IN NUMBER,
                         house_id_ IN c_houses.id%TYPE,
                         p_reu     IN kart.reu%TYPE,
                         p_trest   IN kart.reu%TYPE);
 procedure gen_charges(house_id_ c_houses.id%TYPE);
 FUNCTION gen_charges(lsk_ VARCHAR2, lsk_end_ VARCHAR2, house_id_ c_houses.id%TYPE,
    p_vvod c_vvod.id%type, iscommit_ number, sendmsg_ number)
    return number;

end C_CHARGES;
/

