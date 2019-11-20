create or replace package scott.scripts3 is
  TYPE type_saldo_usl IS table of saldo_usl%rowtype;
  t_tab_corr type_saldo_usl;
  procedure dist_saldo_polis;
  procedure set_elsd;
  procedure swap_chrg_pay_by_one_org;
end scripts3;
/

