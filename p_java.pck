create or replace package scott.p_java is

function http_req(p_url in varchar2) return varchar2;
function gen(
  p_tp in number, 
  p_house_id in number,
  p_vvod_id in number,
  p_usl_id in usl.usl%type,
  p_klsk_id in number,
  p_debug_lvl in number,
  p_gen_dt in date, 
  p_stop in number
  ) return number;
  
procedure distKwtpMg(
  p_kwtp_mg_id in number,
  p_lsk in kart.lsk%type,
  p_summa in number,
  p_penya in number,
  p_debt in number,
  p_dopl in varchar2,
  p_nink in number,
  p_nkom in varchar2,
  p_oper in varchar2,
  p_dtek in date,
  p_dat_ink in date,
  p_use_queue in number default 0
  );
procedure correct(
  p_var in number,
  p_dt in date,
  p_uk in varchar2
  );
    
procedure evictL2Cache;
procedure reloadParams;

end p_java;
/

create or replace package body scott.p_java is

--вызов ядра java-функций начисления
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
      Raise_application_error(-20000, l_url || ' ВОЗМОЖНО НЕ ЗАПУЩЕНО ЯДРО НАЧИСЛЕНИЯ! OTHER Error Msg  : ' ||
                           utl_http.get_detailed_sqlcode ||
                           utl_http.get_detailed_sqlerrm);
  end;                           
end;

-- вызов процесса расчета
/*   * @param p_tp       - тип выполнения 0-начисление, 1-задолженность и пеня, 2 - распределение объемов по вводу
     * @param p_house_Id   - houseId объекта (дом)
     * @param p_vvod_Id   - vvodId объекта (ввод)
     * @param p_klsk_Id   - klskId объекта (помещение)
     * @param p_debug_Lvl - уровень отладки 0, null - не записивать в лог отладочную информацию, 1 - записывать
     * @param genDt   - дата на которую сформировать
     * @param stop     - 1 - остановить выполнение текущей операции с типом tp*/
function gen(
  p_tp in number, 
  p_house_id in number,
  p_vvod_id in number,
  p_usl_id in usl.usl%type,
  p_klsk_id in number,
  p_debug_lvl in number,
  p_gen_dt in date, 
  p_stop in number
  ) return number is
  l_ret varchar2(1000);
  l_req varchar2(1000); 
begin
  utl_http.set_transfer_timeout(50000);
  l_req:='gen?tp='||p_tp;
  if p_house_id is not null then
    l_req:=l_req||'&houseId='||p_house_id;
  end if;
  if p_vvod_id is not null then
    l_req:=l_req||'&vvodId='||p_vvod_id;
  end if;
  if p_klsk_id is not null then
    l_req:=l_req||'&klskId='||p_klsk_id;
  end if;
  if p_usl_id is not null then
    l_req:=l_req||'&uslId='||p_usl_id;
  end if;
  
  l_ret:=p_java.http_req(
    l_req||'&debugLvl='||p_debug_lvl
    ||'&genDt='||to_char(p_gen_dt,'DD.MM.YYYY')
    ||'&stop='||p_stop
    );
  if substr(l_ret,1,2) = 'OK' then
     -- вернуть ОК + объем, который может быть начислен при выполнении операции с типом tp=4
     return substr(l_ret,4,24);
    else
      Raise_application_error(-20000, 'Ошибка при вызове Java функции: '||l_ret );
  end if;
end;

/**

 Распределить платеж C_KWTP_MG в Java 
**/
procedure distKwtpMg(
  p_kwtp_mg_id in number,
  p_lsk in kart.lsk%type,
  p_summa in number,
  p_penya in number,
  p_debt in number,
  p_dopl in varchar2,
  p_nink in number,
  p_nkom in varchar2,
  p_oper in varchar2,
  p_dtek in date,
  p_dat_ink in date,
  p_use_queue in number default 0
  ) is
  l_ret varchar2(1000);
  l_req varchar2(1000); 
begin
  utl_http.set_transfer_timeout(50000);
                    
  l_req:='distKwtpMg?kwtpMgId='||p_kwtp_mg_id||'&lsk='||p_lsk||'&strSumma='||p_summa
    ||'&strPenya='||p_penya||'&strDebt='||p_debt||'&dopl='||p_dopl||'&nink='||p_nink||'&nkom='||p_nkom
    ||'&oper='||p_oper||'&strDtek='||to_char(p_dtek,'DD.MM.YYYY')
    ||'&strDtInk='||to_char(p_dat_ink,'DD.MM.YYYY')||'&useQueue='||p_use_queue;
  l_ret:=p_java.http_req(l_req);
  if substr(l_ret,1,2) != 'OK' then
      Raise_application_error(-20000, 'Ошибка при вызове Java функции: '||l_ret );
  end if;
end;

/**

 Выполнить корректировку сальдо в T_CORRECTS_PAYMENTS
**/
procedure correct(
  p_var in number,
  p_dt in date,
  p_uk in varchar2
  ) is
  l_ret varchar2(1000);
  l_req varchar2(1000); 
begin
  utl_http.set_transfer_timeout(50000);
                    
  l_req:='correct?var='||p_var||'&strDt='||to_char(p_dt,'DD.MM.YYYY')||'&uk='||p_uk;
  l_ret:=p_java.http_req(l_req);
  if substr(l_ret,1,2) != 'OK' then
      Raise_application_error(-20000, 'Ошибка при вызове Java функции: '||l_ret );
  end if;
end;

/** Очистить HibernateL2 кэш
  **/
procedure evictL2Cache is
  l_ret varchar2(1000);
begin
  utl_http.set_transfer_timeout(50000);
  l_ret:=p_java.http_req('evictL2C');
  if substr(l_ret,1,2) <> 'OK' then
    Raise_application_error(-20000, 'Ошибка при вызове Java функции: '||l_ret );
  end if;
end;

-- Перезагрузить сущность Params
procedure reloadParams is
  l_ret varchar2(1000);
begin
  utl_http.set_transfer_timeout(50000);
  l_ret:=p_java.http_req('reloadParams');
  if substr(l_ret,1,2) <> 'OK' then
    Raise_application_error(-20000, 'Ошибка при вызове Java функции: '||l_ret );
  end if;
end;

end p_java;
/

