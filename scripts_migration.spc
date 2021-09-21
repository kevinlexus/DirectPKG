create or replace package scott.scripts_migration is
  PROCEDURE find_update_reu3;
  PROCEDURE find_update2_reu3;
  PROCEDURE find_update_oper3;
  PROCEDURE find_update2_oper3;
  procedure prep_c_spr_pen_usl;
  procedure prep_stav_r_usl;
  procedure prep_c_pen_usl_corr;
  --procedure prep_deb;
  procedure prep_pen;
  procedure test_gen_pen_lsk(p_lsk in varchar2, p_dt in date);
  procedure test_gen_pen_all(p_dt in date);
  procedure test_gen_pen_all_stop;
  
end scripts_migration;
/

