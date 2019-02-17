create or replace package scott.p_java is

function http_req(p_url in varchar2) return varchar2;
procedure gen(
  p_tp in number, 
  p_house_id in number,
  p_vvod_id in number,
  p_klsk_id in number,
  p_debug_lvl in number,
  p_gen_dt in date, 
  p_stop in number
  );
procedure evictCache(p_str in varchar2);
  
end p_java;
/

