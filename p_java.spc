create or replace package scott.p_java is

function http_req(p_url in varchar2) return varchar2;
procedure gen(p_dt in date, p_tp in number, 
  p_lsk_from in kart.lsk%type,
  p_lsk_to in kart.lsk%type,
  p_dbg_lvl in number  
  );
procedure gen_stop(p_tp in number);
  
end p_java;
/

