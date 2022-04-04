create or replace package body scott.p_java is

  --вызов ядра java-функций начисления

  function http_req(p_url        in varchar2, -- адрес Endpoint
                    p_url2       in varchar2 default null, -- параметры запроса (будут URLENCODE!)
                    p_server_url in varchar2 default null, -- заполнять на клиенте, чтоб не искать в БД
                    tp           in varchar2 default 'GET', -- тип запроса
                    p_server_tp  in varchar2 default '', -- тип сервера ''- Прод, '2'-Тест
                    p_body  in varchar2 default '' -- для POST запросов
                    ) return varchar2 is
    l_req       utl_http.req;
    l_resp      utl_http.resp;
    l_proxy     VARCHAR2(250) := '';
    l_str       VARCHAR2(250);
    l_url       varchar2(32767);
    l_base_url  varchar2(32767);
    l_exception number;
  begin
    l_str := 'BAD_REQUEST';
    if p_server_tp = '2' then
      l_base_url := 'http://127.0.0.1:8101/';
    else
      if p_server_url is null then
        l_base_url := init.g_java_server_url;
      else
        l_base_url := p_server_url;
      end if;
    end if;

    utl_http.set_response_error_check(enable => true);
    utl_http.set_detailed_excp_support(enable => true);
    utl_http.set_proxy(l_proxy);
    utl_http.set_transfer_timeout(28800); -- тайм-аут ждать 8 часов ответа
    l_url := l_base_url || p_url;
    if p_url2 is not null then
      -- URLEncode кроме / символа
      l_url := l_url || '/' ||
               replace(utl_url.escape(p_url2, true, 'utf-8'), '%2F', '/');
    end if;
    l_exception := 0;
    --Raise_application_error(-20000, p_body);
    begin
      l_req  := utl_http.begin_request(l_url, tp, ' HTTP/1.1');
      if tp='POST' then
        utl_http.set_header(l_req, 'user-agent', 'mozilla/4.0');
        utl_http.set_header(l_req, 'Content-Length', length(p_body));
        utl_http.set_body_charset(l_req, 'UTF-8');
        utl_http.set_header(l_req, 'Transfer-Encoding', 'chunked');
        utl_http.set_header(l_req, 'Content-Type',  'application/json;charset=utf-8');
        utl_http.write_text(l_req, p_body);
      end if;
      l_resp := utl_http.get_response(l_req);
      if l_resp.status_code = utl_http.http_ok then
        utl_http.read_text(l_resp, l_str, 250);
        utl_http.end_response(l_resp);
      end if;
      return l_str;

    exception
      when others then
        l_exception := 1;

    end;

    if l_exception = 1 then
      begin
        l_req  := utl_http.begin_request(l_base_url || 'getStatus',
                                         'GET',
                                         ' HTTP/1.1');
        l_resp := utl_http.get_response(l_req);
        if l_resp.status_code = utl_http.http_ok then
          l_exception := 2;
        end if;
      exception
        when others then
          Raise_application_error(-20000, 'НЕ ЗАПУЩЕНО ЯДРО НАЧИСЛЕНИЯ!');
      end;
    end if;
    if l_exception = 2 then
      Raise_application_error(-20000, ' Некорректный вызов метода контроллера: '||l_url);
    end if;

  end;

  -- вызов процесса расчета
  /*   * @param p_tp       - тип выполнения 0-начисление, 1-пеня, 2 - распределение объемов по вводу
  * @param p_house_Id   - houseId объекта (дом)
  * @param p_vvod_Id   - vvodId объекта (ввод)
  * @param p_klsk_Id   - klskId объекта (помещение)
  * @param p_debug_Lvl - уровень отладки 0, null - не записивать в лог отладочную информацию, 1 - записывать
  * @param genDt   - дата на которую сформировать
  * @param stop     - 1 - остановить выполнение текущей операции с типом tp*/
  function gen(p_tp        in number,
               p_house_id  in number default null,
               p_vvod_id   in number default null,
               p_usl_id    in usl.usl%type default null,
               p_klsk_id   in number default null,
               p_debug_lvl in number,
               p_gen_dt    in date,
               p_stop      in number,
               p_server_tp in varchar2 default '' -- тип сервера ''- Прод, '2'-Тест
               ) return number is
    l_ret varchar2(1000);
    l_req varchar2(1000);
  begin
    utl_http.set_transfer_timeout(50000);
    l_req := 'gen?tp=' || p_tp;
    if p_house_id is not null then
      l_req := l_req || '&houseId=' || p_house_id;
    end if;
    if p_vvod_id is not null then
      l_req := l_req || '&vvodId=' || p_vvod_id;
    end if;
    if p_klsk_id is not null then
      l_req := l_req || '&klskId=' || p_klsk_id;
    end if;
    if p_usl_id is not null then
      l_req := l_req || '&uslId=' || p_usl_id;
    end if;
    l_ret := p_java.http_req(p_url       => l_req || '&debugLvl=' ||
                                            p_debug_lvl || '&genDt=' ||
                                            to_char(p_gen_dt, 'DD.MM.YYYY') ||
                                            '&stop=' || p_stop,
                             p_server_tp => p_server_tp);
    /*  l_ret:=p_java.http_req(
    l_req||'&debugLvl='||p_debug_lvl
    ||'&genDt='||to_char(p_gen_dt,'DD.MM.YYYY')
    ||'&stop='||p_stop
    );*/
    if substr(l_ret, 1, 2) = 'OK' then
      -- вернуть ОК + объем, который может быть начислен при выполнении операции с типом tp=4
      return substr(l_ret, 4, 24);
    else
      Raise_application_error(-20000,
                              'Ошибка при вызове Java функции: ' || l_ret);
    end if;
  end;

  /**

   Распределить платеж C_KWTP_MG в Java
  **/
  procedure distKwtpMg(p_kwtp_mg_id in number,
                       p_lsk        in kart.lsk%type,
                       p_summa      in number,
                       p_penya      in number,
                       p_debt       in number,
                       p_dopl       in varchar2,
                       p_nink       in number,
                       p_nkom       in varchar2,
                       p_oper       in varchar2,
                       p_dtek       in date,
                       p_dat_ink    in date,
                       p_use_queue  in number default 0) is
    l_ret varchar2(1000);
    l_req varchar2(1000);
  begin
    utl_http.set_transfer_timeout(50000);

    l_req := 'distKwtpMg?kwtpMgId=' || p_kwtp_mg_id || '&lsk=' || p_lsk ||
             '&strSumma=' || p_summa || '&strPenya=' || p_penya ||
             '&strDebt=' || p_debt || '&dopl=' || p_dopl || '&nink=' ||
             p_nink || '&nkom=' || p_nkom || '&oper=' || p_oper ||
             '&strDtek=' || to_char(p_dtek, 'DD.MM.YYYY') || '&strDtInk=' ||
             to_char(p_dat_ink, 'DD.MM.YYYY') || '&useQueue=' ||
             p_use_queue;
    l_ret := p_java.http_req(l_req);
    if substr(l_ret, 1, 2) != 'OK' then
      Raise_application_error(-20000,
                              'Ошибка при вызове Java функции: ' || l_ret);
    end if;
  end;

  /**

   Выполнить корректировку сальдо в T_CORRECTS_PAYMENTS
  **/
  procedure correct(p_var       in number,
                    p_dt        in date,
                    p_uk        in varchar2,
                    p_server_tp in varchar2 default '' -- тип сервера ''- Прод, '2'-Тест
                    ) is
    l_ret varchar2(1000);
    l_req varchar2(1000);
  begin
    utl_http.set_transfer_timeout(50000);

    l_req := 'correct?var=' || p_var || '&strDt=' ||
             to_char(p_dt, 'DD.MM.YYYY') || '&uk=' || p_uk;
    l_ret := p_java.http_req(p_url => l_req, p_server_tp => p_server_tp);
    --.http_req(l_req);
    if substr(l_ret, 1, 2) != 'OK' then
      Raise_application_error(-20000,
                              'Ошибка при вызове Java функции: ' || l_ret);
    end if;
  end;

  /** Очистить HibernateL2 кэш (todo выполняется в целом по некоторым сущностям, надо бы переделать на evictL2CEntity ред.04.03.22)
  **/
  procedure evictL2Cache is
    l_ret varchar2(1000);
  begin
    utl_http.set_transfer_timeout(50000);
    begin
      l_ret := p_java.http_req('evictL2C');
      if substr(l_ret, 1, 2) <> 'OK' then
        Raise_application_error(-20000,
                                'Возможно не доступно ядро начисления. Ошибка при вызове Java функции: evictL2C');
      end if;
    exception when others then
      logger.log_(time_ => sysdate, comments_ => 'Возможно не доступно ядро начисления. Ошибка при вызове Java функции: evictL2C');
    end;                        
  end;

  /** Очистить HibernateL2 кэш по сущности
  **/
  procedure evictL2CEntity(p_entity in varchar2, p_id in varchar2) is
    l_ret varchar2(1000);
    l_req varchar2(1000);
  begin
    utl_http.set_transfer_timeout(50000);
    l_req := 'evictL2CEntity/' || p_entity || '/'||p_id;
    begin
      l_ret := p_java.http_req(l_req);
      if substr(l_ret, 1, 2) <> 'OK' then
        Raise_application_error(-20000,
                                'Возможно не доступно ядро начисления. Ошибка при вызове Java функции: ' || l_req);
      end if;
    exception when others then
      logger.log_(time_ => sysdate, comments_ => 'Возможно не доступно ядро начисления. Ошибка при вызове Java функции: ' || l_req);
    end;                        

  end;

  /** Очистить HibernateL2 кэш по региону
  **/
  procedure evictL2CRegion(p_region in varchar2) is
    l_ret varchar2(1000);
    l_req varchar2(1000);
  begin
    utl_http.set_transfer_timeout(50000);
    l_req := 'evictL2CRegion/' || p_region;
    begin
      l_ret := p_java.http_req(l_req);
      if substr(l_ret, 1, 2) <> 'OK' then
        Raise_application_error(-20000,
                                'Возможно не доступно ядро начисления. Ошибка при вызове Java функции: ' || l_req);
      end if;
    exception when others then
      logger.log_(time_ => sysdate, comments_ => 'Возможно не доступно ядро начисления. Ошибка при вызове Java функции: ' || l_req);
    end;                        
  end;

  -- Перезагрузить сущность Params
  procedure reloadParams(p_server_tp in varchar2 default '') -- тип сервера ''- Прод, '2'-Тест)
   is
    l_ret varchar2(1000);
  begin
    utl_http.set_transfer_timeout(50000);
    l_ret := p_java.http_req(p_url       => 'reloadParams',
                             p_server_tp => p_server_tp);
    --  l_ret:=p_java.http_req('reloadParams');
    if substr(l_ret, 1, 2) <> 'OK' then
      Raise_application_error(-20000,
                              'Ошибка при вызове Java функции: ' || l_ret);
    end if;
  end;

  -- Перезагрузить справочники по пене
  procedure reloadSprPen(p_server_tp in varchar2 default '') is
    l_ret varchar2(1000);
  begin
    utl_http.set_transfer_timeout(50000);
    l_ret := p_java.http_req(p_url       => 'reloadSprPen',
                             p_server_tp => p_server_tp);
    -- l_ret:=p_java.http_req('reloadSprPen');
    if substr(l_ret, 1, 2) <> 'OK' then
      Raise_application_error(-20000,
                              'Ошибка при вызове Java функции: ' || l_ret);
    end if;
  end;

  -- Отправить ответы на запросы УСЗН в ГИС, вернуть кол-во активированных заданий
  procedure putTaskToWork(p_ids in varchar2, p_count out number) is
    l_req varchar2(32767);
  begin
    utl_http.set_transfer_timeout(50000);
    l_req := 'putTaskToWork/' || p_ids;
    p_count := p_java.http_req(l_req);
  end;

  -- Сохранить таблицу в DBF файл
  function saveDBF(p_table_in_name in varchar2, p_table_out_name in varchar2) return varchar2 is
    l_req varchar2(32767);
  begin
    utl_http.set_transfer_timeout(50000);
    l_req := 'saveDBF/' || p_table_in_name||'/'||utl_url.escape(p_table_out_name, true, 'utf-8');
    return p_java.http_req(null, l_req);
  end;

end p_java;
/

