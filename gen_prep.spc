create or replace package scott.GEN_PREP is

procedure dist_npg_on_saldo3(p_lsk in scott.kart.lsk%type, p_round in number,
   p_mg in varchar2, p_mg_back in varchar2, p_i out number, p_i1 out number, p_err out number);
end GEN_PREP;
/

