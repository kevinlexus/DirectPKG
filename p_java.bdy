create or replace package body scott.p_java is

--вызов ядра java-функций начисления
function http_req(p_url in varchar2) return varchar2 is
   l_req utl_http.req;
   l_resp utl_http.resp; 
   is_link_valid Boolean := False;  
   l_proxy VARCHAR2(250) := '';
   l_str VARCHAR2(250);
   l_url varchar2(1024);
begin
  l_str:='BAD_REQUEST';
  l_url:=utils.get_str_param('JAVA_SERVER_URL');
  utl_http.set_response_error_check(enable => true);
  utl_http.set_detailed_excp_support(enable => true);
  utl_http.set_proxy(l_proxy);
  l_url:=l_url||p_url;
  begin
    l_req  := utl_http.begin_request(l_url);
    l_resp := utl_http.get_response(l_req);
    if l_resp.status_code = utl_http.http_ok then
      utl_http.read_text(l_resp, l_str, 250);
      utl_http.end_response(l_resp);
    end if;
    return l_str;
  exception
    when others then
      Raise_application_error(-20000, l_url || ' OTHER Error Msg  : ' ||
                           utl_http.get_detailed_sqlcode ||
                           utl_http.get_detailed_sqlerrm);
  end;                           
end;

-- вызов процесса расчета
-- p_tp - тип (0-задолженность и пеня)
-- p_dt - дата на которую расчитать
-- p_lsk_from - начальный лицевой
-- p_lsk_to - конечный лицевой
procedure gen(p_dt in date, p_tp in number, 
  p_lsk_from in kart.lsk%type,
  p_lsk_to in kart.lsk%type,
  p_dbg_lvl in number
  ) is
  l_ret varchar2(1000);
begin
  utl_http.set_transfer_timeout(50000);
  l_ret:=p_java.http_req(
      'gen?tp='||p_tp
    ||'&debugLvl='||p_dbg_lvl
    ||'&genDt='||to_char(p_dt,'DD.MM.YYYY')
    ||'&lskFrom='||p_lsk_from    
    ||'&lskTo='||p_lsk_to    
    ||'&key=lasso_the_moose_'||to_char(sysdate,'YYYYMMDD'));
  if substr(l_ret,1,2) <> 'OK' then
    Raise_application_error(-20000, 'Ошибка при вызове Java функции: '||l_ret );
  end if;
end;

-- остановка процесса расчета
-- p_tp - тип (0-задолженность и пеня)
procedure gen_stop(p_tp in number) is
  l_ret varchar2(1000);
begin
  utl_http.set_transfer_timeout(300);
  l_ret:=p_java.http_req('gen?tp='||p_tp||'&stop=1'
    ||'&key=lasso_the_moose_'||to_char(sysdate,'YYYYMMDD'));
  if substr(l_ret,1,2) <> 'OK' then
    Raise_application_error(-20000, 'Ошибка при вызове Java функции: '||l_ret );
  end if;
end;

end p_java;
/

