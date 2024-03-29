create or replace package scott.p_java is

  function http_req(p_url        in varchar2, -- ����� Endpoint
                    p_url2       in varchar2 default null, -- ��������� ������� (����� URLENCODE!)
                    p_server_url in varchar2 default null,
                    tp           in varchar2 default 'GET', -- ��� �������
                    p_server_tp  in varchar2 default '' -- ��� ������� ''- ����, '2'-����
                    ) return varchar2;
  function gen(p_tp        in number,
               p_house_id  in number default null,
               p_vvod_id   in number default null,
               p_usl_id    in usl.usl%type default null,
               p_klsk_id   in number default null,
               p_debug_lvl in number,
               p_gen_dt    in date,
               p_stop      in number,
               p_server_tp in varchar2 default '' -- ��� ������� ''- ����, '2'-����
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
                    p_server_tp in varchar2 default '' -- ��� ������� ''- ����, '2'-����
                    );

  procedure evictL2Cache;
  procedure reloadParams(p_server_tp in varchar2 default '');
  procedure reloadSprPen(p_server_tp in varchar2 default '');

end p_java;
/

