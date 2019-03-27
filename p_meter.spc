create or replace package scott.p_meter is
  g_flag number;
  -- ��� ������ - klsk ������� �� ������� �������� �������
  type trg_obj is record(
    klsk     number, -- klsk ��������
    klsk_obj number, -- klsk �������
    fk_usl   varchar2(3), -- ������ ��������
    n1       number, -- ����� ���������
    isChng   number -- �������� ��������� (1-��, 0-���)
    );

  -- ������ �������
  trg_rec_obj trg_obj;
  -- ��� ������� �������
  type tab_rec_obj is table of trg_rec_obj%type;
  -- �������
  tb_rec_obj tab_rec_obj := tab_rec_obj(null);

  function ins_meter(p_npp         in number,
                     p_usl         in usl.usl%type,
                     p_dt1         in date,
                     p_dt2         in date,
                     p_n1          in number,
                     p_fk_klsk_obj in number,
                     p_tp          in u_list.cd%type) return number;
  function ins_vol_meter(p_met_klsk in number, -- klsk �������� --���� klsk ��������
                         p_lsk      in kart.lsk%type, --���.����     --���� ���.���� + ������!
                         p_usl      in usl.usl%type, --������
                         p_vol      in number, -- �����
                         p_n1       in number, -- �� ������������!
                         p_tp       in number default 0 -- ��� (0-������ ����, 1-��������������, 2-������ ���������� (����� �� ������ �������)
                         ) return number;
  procedure ins_data_meter(p_met_klsk in number, -- klsk �������� --���� klsk ��������
                           p_n1       in number, -- ����� ���������
                           p_ts       in date, -- timestamp
                           p_period   in varchar2,
                           p_ret      out number);
  function getpsch(p_lsk in kart.lsk%type) return number;
  function getElpsch(p_lsk in kart.lsk%type) return number;
  function gen_auto_chrg_all(p_set in number, p_usl in usl.usl%type)
    return number;
  procedure del_broken_meter(p_usl in varchar2);
  procedure imp_all_meter;
  procedure imp_states_meter(p_lsk      in varchar2,
                             p_klsk_met in number,
                             p_usl      in varchar2);
  procedure imp_lsk_meter(p_lsk    in kart.lsk%type,
                          p_usl_hw in varchar2,
                          p_usl_gw in varchar2,
                          p_usl_el in varchar2,
                          p_usl_ot in varchar2);
  procedure imp_arch_meter(p_lsk      in kart.lsk%type, -- ��
                           p_met_klsk in number, -- klsk ��������
                           p_mg       in params.period%type, -- ������ � �������
                           p_counter  in varchar2 -- ��� ��������
                           );
  procedure test1;

end p_meter;
/

