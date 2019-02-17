create or replace package body scott.p_java is

--����� ���� java-������� ����������
function http_req(p_url in varchar2) return varchar2 is
   l_req utl_http.req;
   l_resp utl_http.resp; 
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

-- ����� �������� �������
/*   * @param p_tp       - ��� ���������� 0-����������, 1-������������� � ����, 2 - ������������� ������� �� �����
     * @param p_house_Id   - houseId ������� (���)
     * @param p_vvod_Id   - vvodId ������� (����)
     * @param p_klsk_Id   - klskId ������� (���������)
     * @param p_debug_Lvl - ������� ������� 0, null - �� ���������� � ��� ���������� ����������, 1 - ����������
     * @param genDt   - ���� �� ������� ������������
     * @param stop     - 1 - ���������� ���������� ������� �������� � ����� tp*/
procedure gen(
  p_tp in number, 
  p_house_id in number,
  p_vvod_id in number,
  p_klsk_id in number,
  p_debug_lvl in number,
  p_gen_dt in date, 
  p_stop in number
  ) is
  l_ret varchar2(1000);
begin
  utl_http.set_transfer_timeout(50000);
  l_ret:=p_java.http_req(
      'gen?tp='||p_tp
    ||'&houseId='||p_house_id
    ||'&vvodId='||p_vvod_id
    ||'&klskId='||p_klsk_id
    ||'&debugLvl='||p_debug_lvl
    ||'&genDt='||to_char(p_gen_dt,'DD.MM.YYYY')
    ||'&stop='||p_stop
    );
  if substr(l_ret,1,2) <> 'OK' then
    Raise_application_error(-20000, '������ ��� ������ Java �������: '||l_ret );
  end if;
end;

/** �������� ���
  str - ����������� ������������ ����
  **/
procedure evictCache(p_str in varchar2) is
  l_ret varchar2(1000);
begin
  utl_http.set_transfer_timeout(50000);
  l_ret:=p_java.http_req(p_str);
  if substr(l_ret,1,2) <> 'OK' then
    Raise_application_error(-20000, '������ ��� ������ Java �������: '||l_ret );
  end if;
end;

end p_java;
/

