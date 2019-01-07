CREATE OR REPLACE PACKAGE SCOTT.UTILS2 IS
TYPE type_saldo_usl IS table of saldo_usl%rowtype;
  t_tab_corr type_saldo_usl;
  
procedure distSalDebByCrd(p_lsk in kart.lsk%type, 
   p_mg in saldo_usl.mg%type, p_ret in out type_saldo_usl);
   
END UTILS2;
/

