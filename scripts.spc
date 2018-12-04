create or replace package scott.scripts is
  procedure swap_payment;
  procedure swap_payment9;
  procedure swap_payment7;
  procedure swap_payment2;
  procedure swap_payment3;
  procedure gen_del_add_partitions;
  procedure new_usl(usl_ in varchar2);
  procedure script_renumber(oldreu_ in kart.reu%type,
                            reu_    in kart.reu%type);
  procedure create_uk(newreu_ in kart.reu%type,
                      nreu_   in varchar2,
                      mg1_    in params.period%type,
                      mg2_    in params.period%type);
  procedure close_uk(newreu_ in kart.reu%type, mg2_ in params.period%type);
  procedure clear_tables;
  procedure saldo_uk_div;
  procedure swap_payment4(reu_ in varchar2, newreu_ in varchar2);
  procedure swap_payment5;
  procedure swap_changes;
  procedure upd_nabor(oldorg_ in number, org_ in number, newreu_ in kart.reu%type);
  procedure go_back_month;
  procedure create_killme;
  procedure swap_oborot;
  procedure ins_vvod;
  procedure create_kart;
  procedure find_table;
  procedure swap_payment8;
  procedure set_sal_mg;
  procedure swap_oborot2;
  procedure swap_oborot3;
  procedure close_sal;
  procedure close_sal2;
  procedure close_sal3;
  procedure swap_sal1;
  procedure swap_sal_MAIN;
  procedure swap_sal_MAIN_BY_LSK;
  procedure create_uk_new_SPECIAL(newreu_ in kart.reu%type);
  procedure swap_sal2;
  procedure swap_sal3;
  procedure swap_sal4;
  --������ ������ "� ������"
  procedure swap_sal_TO_NOTHING;
  procedure swap_sal_chpay;
  procedure swap_sal_chpay2;
  procedure swap_sal_chpay3;
  procedure create_uk_new(newreu_ in kart.reu%type,
    lsk_ in kart.lsk%type, -- ���.����, ���� �� �������� - �� ������������� � ������������� ��
    p_lsk_tp_src in varchar2, -- ����������� �������, � ������ ���� ������ �������!
    p_get_all in number, -- ������� ����� ����� �� (1 - ��� ��, � �.�. ��������, 0-������ ��������)
    p_close_src in number, -- ��������� ������ � ��. ��������� (mg2='999999') 1-��,0-���
    p_close_dst in number, -- ��������� ������ � ��. ���������� (mg2='999999') 1-��,0-���
    p_move_resident in number, -- ���������� �����������? 1-��,0-���
    p_forced_status in number, -- ���������� ����� ������ ����� (0-��������, NULL - ����� �� ��� ��� � ����� ���������)
    p_forced_tp in varchar2, -- ���������� ����� ��� ����� (NULL-����� �� ���������, �������� 'LSK_TP_RSO' - ���)
    p_tp_sal in number, --������� ��� ���������� ������ 0-�� ����������, 2 - ���������� � ����� � ������, 1-������ �����, 3 - ������ ������
    p_special_tp in varchar2, -- ������� �������������� ���.���� � ������� � ����� ���������� (NULL- �� ���������, 'LSK_TP_ADDIT' - ���������)
    p_special_reu in varchar2, -- �� ��������������� ���.�����
    p_mg_sal in c_change.mgchange%type, -- ������ ������
    p_remove_nabor_usl in varchar2 default null, -- ������� ������ ������ (�������� ��� '033;034;035;' ������!), �� ����������� ������� �� ��������� (null - �� �������) � ��������� � ���������� 
    p_mg_pen in c_change.mgchange%type -- ������ �� �������� ��������� ����. null - �� ���������� (������ ����� �����)
  );
  --������� ���������� �� �������� ���.������
  procedure transfer_closed_all(p_reu in kart.reu%type,  -- ��� ����������
                              p_lsk_recommend in kart.lsk%type); -- �������������� ���.����, ��� ������ ��� Null);
  --������� ���������� �� ��������� ���.�����
  procedure transfer_closed_lsk(p_lsk in kart.lsk%type, --��� ����
                       p_reu in kart.reu%type, --��� ����������
                       p_cd in varchar2, --CD
                       p_lsk_recommend in kart.lsk%type -- �������������� ���.����, ��� ������ ��� Null
                       );
  procedure swap_sal_chpay4;
  --����������� ������ � ����� ������ ��� (����������) �� ������
  procedure swap_sal_chpay5;
end scripts;
/

