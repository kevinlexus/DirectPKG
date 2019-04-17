create or replace package scott.p_java is

function http_req(p_url in varchar2) return varchar2;
function gen(
  p_tp in number, 
  p_house_id in number,
  p_vvod_id in number,
  p_reu_id in varchar2,
  p_usl_id in usl.usl%type,
  p_klsk_id in number,
  p_debug_lvl in number,
  p_gen_dt in date, 
  p_stop in number
  ) return number;
procedure evictL2Cache;
  
end p_java;
/

