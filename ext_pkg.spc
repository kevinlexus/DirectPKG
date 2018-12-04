CREATE OR REPLACE PACKAGE SCOTT.ext_pkg
AUTHID CURRENT_USER IS
procedure exp_base(var_ in number, p_mg1 in params.period%type, p_mg2 in params.period%type);
--procedure exp_base_arch(p_mg1 in params.period%type, p_mg2 in params.period%type);
procedure imp_vol_all;
procedure exp_vol_all;
procedure imp_vol_usl(cd_usl_ in usl.cd%type);
function is_lst(p_cd_org in varchar2) return number;
procedure fill_table;

END ext_pkg;
/

