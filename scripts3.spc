create or replace package scott.scripts3 is
TYPE type_saldo_usl IS table of saldo_usl%rowtype;
  t_tab_corr type_saldo_usl;

  procedure dist_saldo_polis;
  procedure dist_sal_deb_by_cr;

end scripts3;
/

