create or replace package scott.scripts is
  TYPE type_saldo_usl IS table of saldo_usl%rowtype;
  t_tab_corr type_saldo_usl;
  procedure swap_sal_MAIN_BY_LSK;
  procedure swap_sal_TO_NOTHING;
  procedure CREATE_UK_NEW2(p_reu_dst          in kart.reu%type, -- ��� �� ���������� (������ ������� new_reu_), ���� �� ��������, �� ��������� �� ���.����� ���������
                           p_reu_src          in varchar2, -- ��� �� ��������� (���� �� ���������, �� �����) ����������� ���� ����������� �� �� ��� � ������ ���
                           p_lsk_tp_src       in varchar2, -- � ������ ���� ������ �������, ���� �� ������� - ����� ����� �� ������� p_remove_nabor_usl
                           p_house_src        in varchar2, -- House_id ����� �������, �������� '3256,5656,7778,'
                           p_get_all          in number, -- ������� ����� ����� �� (1 - ��� ��, � �.�. ��������, 0-������ ��������)
                           p_close_src        in number, -- ��������� ��. ��������� (mg2='999999') 1-��,0-���,2-��������� ������ ���� �� �������� ����
                           p_close_dst        in number, -- ��������� ��. ���������� (mg2='999999') 1-��,0-���
                           p_move_resident    in number, -- ���������� �����������? 1-��,0-���
                           p_forced_status    in number, -- ���������� ����� ������ ����� (0-��������, NULL - ����� �� ��� ��� � ����� ���������)
                           p_forced_tp        in varchar2, -- ���������� ����� ��� ����� (NULL-����� �� ���������, �������� 'LSK_TP_RSO' - ���)
                           p_tp_sal           in number, --������� ��� ���������� ������ 0-�� ����������, 2 - ���������� � ����� � ������, 1-������ �����, 3 - ������ ������
                           p_special_tp       in varchar2, -- ������� �������������� ���.���� � ������� � ����� ���������� (NULL- �� ���������, 'LSK_TP_ADDIT' - ���������)
                           p_special_reu      in varchar2, -- �� ��������������� ���.�����
                           p_mg_sal           in c_change.mgchange%type, -- ������ ������
                           p_remove_nabor_usl in varchar2 default null, -- ����������� ������ ������ (�������� ��� 033,034,035)
                           p_create_nabor_usl in varchar2 default null, -- ������� ������ ������ (�������� ��� 033,034,035) �� ������������ ��������� � p_remove_nabor_usl!
                           p_forced_usl       in varchar2 default null, -- ���������� ������ ������ � ���������� (���� �� �������, ����� �� ���������)
                           p_forced_org       in number default null, -- ���������� ����������� � ������ ���������� (null - ����� �� ���������)
                           p_mg_pen           in c_change.mgchange%type, -- ������ �� �������� ��������� ����. null - �� ���������� (������ ����� �����)
                           p_move_meter       in number default 0,-- ���������� ��������� ��������� (������ �����) 1-��,0-��� - ��� ����������� �� ��� - �� ���� ��������
                           p_cpn              in number default 0-- ��������� ���� � ����� ��� ������? (0, null, -��, 1 - ���)
                           );
  procedure sub_ZERO_kis;
  procedure swap_sal_PEN(
     p_reu_src          in varchar2, -- ��� �� ���������
     p_usl_src in varchar2, -- ����������� � ������ ������
     p_usl_dst in varchar2, -- ��� ������ ����������
     p_org_src in number, -- ��� ���������
     p_org_dst in number -- ��� ����������
  );  
  procedure swap_sal_PEN2;
  procedure swap_sal_and_pen;
  procedure swap_sal_PEN3;
  procedure swap_sal_from_main_to_rso;
  procedure swap_sal_from_main_to_rso2;
  procedure swap_sal_chpay13;
  procedure move_sal_pen_main_to_rso;
  
  procedure dist_saldo_polis;
  procedure dist_saldo_PEN_polis;
  procedure swap_chrg_pay_by_one_org;
end scripts;
/

