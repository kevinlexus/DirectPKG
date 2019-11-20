create or replace package scott.gen is
  TYPE rep_refcursor IS REF CURSOR;
  procedure gen_check (err_ out number, err_str_ out varchar2,
    var_ in number);
  procedure gen_check_lst (var_ in number,
                           prep_refcursor IN OUT rep_refcursor);
  procedure smpl_chk (p_var in number,
                           prep_refcursor IN OUT rep_refcursor);
  procedure prep_kart_pr;
  procedure gen_opl_xito3;--
  procedure gen_opl_xito5_;--
  procedure gen_opl_xito5;--
  procedure gen_opl_xito5day(dat1_ in xito5.dat%type,
                             dat2_ in xito5.dat%type);
  procedure gen_opl_xito5day_(dat1_ in xito5_.dat%type,
                              dat2_ in xito5_.dat%type);
  procedure gen_opl_xito10day(dat1_ in xxito10.dat%type,
                              dat2_ in xxito10.dat%type);
  procedure gen_opl_xito10;--
  procedure gen_c_charges(lsk_ in kart.lsk%type);
  procedure gen_lg;--
  procedure gen_saldo(lsk_ in kart.lsk%type);
  procedure gen_saldo_houses;--
  procedure gen_debits_lsk_month(dat_ in date);
  procedure gen_xito13;
  procedure load_saldo(mg_ in varchar2); --???чё эт такое?
--  procedure distrib_vols;
  procedure prepare_arch_lsk(lsk_     in kart.lsk%type,
                             var_     in number);
  procedure prepare_arch_k_lsk(k_lsk_id_     in kart.k_lsk_id%type,
                             pen_last_month_ in number,
                             var_     in number);
  procedure prepare_arch_adr(kul_ in kart.kul%type,
                             nd_  in kart.nd%type,
                             kw_  in kart.kw%type,
                             var_ in number);
  procedure prepare_arch_all;
  procedure prepare_arch(lsk_ in kart.lsk%type);
  procedure upd_acrh_kart(p_lsk in kart.lsk%type,
     p_mg in params.period%type,
     p_mg1 in params.period%type,
     p_old_mg in params.period%type
     );
  procedure upd_arch_kart2(p_klsk in number, p_mg in params.period%type);
  procedure gen_stat_debits;
  procedure go_next_month_year;
  procedure go_nye_phase1;
  procedure go_nye_phase2;
  procedure go_nye_phase3;
  procedure gen_clear_tables;
  procedure gen_del_add_partitions;
  procedure make_part(tablename_ in varchar2,
                      tabspc_    in varchar2,
                      partname_  in varchar2,
                      mg_        in varchar2);
  procedure make_part2(tablename_ in varchar2,
                      tabspc_    in varchar2,
                      mg_        in varchar2,
                      p_drop in number);
  procedure drop_part(tablename_ in varchar2, mg_ in varchar2);
  procedure trunc_part(tablename_ in varchar2, mg_ in varchar2);
  procedure auto_charge;
  procedure prep_template_tree_objects;
end gen;
/

