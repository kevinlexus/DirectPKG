create or replace package scott.p_java is
  eolink_updated_cnt number;
  task_updated_cnt number;
  eolxpar_updated_cnt number;
  taskxpar_updated_cnt number;
  kart_updated_cnt number;
  c_kart_pr_updated_cnt number;
  nabor_updated_cnt number;
  t_objxpar_updated_cnt number;
  meter_updated_cnt number;
  k_lsk_updated_cnt number;
  c_houses_updated_cnt number;
  c_users_perm_updated_cnt number;

  function http_req(p_url        in varchar2, -- адрес Endpoint
                    p_url2       in varchar2 default null, -- параметры запроса (будут URLENCODE!)
                    p_server_url in varchar2 default null,
                    tp           in varchar2 default 'GET', -- тип запроса
                    p_server_tp  in varchar2 default '', -- тип сервера ''- Прод, '2'-Тест
                    p_body  in varchar2 default '' -- для POST запросов
                    ) return varchar2;
  function gen(p_tp        in number,
               p_house_id  in number default null,
               p_vvod_id   in number default null,
               p_usl_id    in usl.usl%type default null,
               p_klsk_id   in number default null,
               p_debug_lvl in number,
               p_gen_dt    in date,
               p_stop      in number,
               p_server_tp in varchar2 default '' -- тип сервера ''- Прод, '2'-Тест
               ) return number;

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
                       p_use_queue  in number default 0);
  procedure correct(p_var       in number,
                    p_dt        in date,
                    p_uk        in varchar2,
                    p_server_tp in varchar2 default '' -- тип сервера ''- Прод, '2'-Тест
                    );

  procedure evictL2Cache;
  procedure evictL2CEntity(p_entity in varchar2, p_id in varchar2);
  procedure evictL2CRegion(p_region in varchar2);
  procedure reloadParams(p_server_tp in varchar2 default '');
  procedure reloadSprPen(p_server_tp in varchar2 default '');
  procedure putTaskToWork(p_ids in varchar2, p_count out number);
  function saveDBF(p_table_in_name in varchar2, p_table_out_name in varchar2) return varchar2;

end p_java;
/

