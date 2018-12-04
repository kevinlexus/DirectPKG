create or replace package scott.C_CHANGES is
  PROCEDURE clear_changes_proc;
  PROCEDURE gen_changes_proclsk(lsk_   in c_change.lsk%type,
                                summa_ in c_change.summa%type,
                                usl_   in c_change.usl%type,
                                mg_    in c_change.mgchange%type,
                                text_ in varchar2);
  FUNCTION test_abs_or_proc return number;
  PROCEDURE gen_changes_proc(lsk_start_ in c_change.lsk%type,
                            lsk_end_   in c_change.lsk%type,
                            mg_        in c_change.mgchange%type,
                            p_mg2        in c_change.mg2%type,
                            usl_add_ in number,
                            is_sch_ in number,
                            l_psch in number,
                            tst_ in number,
                            text_ in varchar2,
                            result_ out number,
                            doc_id_ out number,
                            p_kran1 in number,
                            p_status in number,
                            p_chrg in number,
                            p_kan in number,
                            p_wo_kpr in number, --отсутствие проживающих(1-да, 0, null - нет) (нулевые квартиры) по жел. Кис, 02.12.14!
                            p_lsk_tp_var in number, --вариант перерасчета (0-только по основным лс., 1 - только по дополнит лс., 2 - по тем и другим)
                            p_tp in number -- тип, 0 - все остальные, 1 - корректировка сальдо
                            );
  procedure gen_pay_corrects(src_usl_ in usl.usl%type,
      src_org_ in t_org.id%type,
      dst_usl_ in usl.usl%type,
      dst_org_ in t_org.id%type,
      reu_ in t_org.reu%type,
      p_tp in number);
  procedure gen_corrects(src_usl_ in usl.usl%type,
    src_org_ in t_org.id%type,
    dst_usl_ in usl.usl%type,
    dst_org_ in t_org.id%type,
    reu_ in t_org.reu%type,
    text_ in c_change_docs.text%type);
  procedure del_chng_doc(id_ in c_change_docs.id%type);
  procedure del_chng(id_ in c_change.id%type);
  procedure del_corr(fk_doc_ in c_change_docs.id%type);
end C_CHANGES;
/

