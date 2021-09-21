create or replace package scott.rep_bills_compound is
  type ccur is ref cursor;
  tab tab_bill_detail;

procedure main(p_sel_obj in number, -- ������� �������: 0 - �� klsk, 1 - �� ������, 2 - �� ��
               p_reu in kart.reu%type, -- ��� ��
               p_kul in kart.kul%type, -- ��� �����
               p_nd in kart.nd%type,   -- � ����
               p_kw in kart.kw%type,   -- � ��������
               p_lsk in kart.lsk%type, -- ���.���������
               p_lsk1 in kart.lsk%type,-- ���.��������
               p_klsk_id   in number default null, -- ���.��� ����, ������������ ��� p_sel_obj=1
               p_firstNum in number, -- ��������� ����� ����� (��� ������ �� ��)
               p_lastNum in number,  -- �������� ����� �����
               p_is_closed in number, -- �������� �� �������� ����, ���� ���� ����? (0-���, 1-��)
               p_mg in params.period%type, -- ������ �������
               p_sel_uk in varchar2, -- ������ ��
               p_postcode  in varchar2, -- �������� ������ (��� p_sel_obj=2)
               p_exp_email in number default 0, -- ��������� ��� �������� �� ��.�����, 0 - ���, 1 - ��
               p_rfcur out ccur -- ���.���������
  );

procedure main_arch(p_sel_obj   in number, -- ������� �������: 0 - �� ���.�����, 1 - �� ������, 2 - �� ��
               p_kul       in kart.kul%type, -- ��� �����
               p_nd        in kart.nd%type, -- � ����
               p_kw        in kart.kw%type, -- � ��������
               p_lsk       in kart.lsk%type, -- ���.���������
               p_lsk1      in kart.lsk%type, -- ���.��������
               p_is_closed in number, -- �������� �� �������� ����, ���� ���� ����? (0-���, 1-��)
               p_firstNum  in number default null, -- ��������� ����� ����� (��� ������ �� ��) -- ������ ����� ������������! ���.28.05.2020
               p_lastNum   in number default null, -- �������� ����� ����� -- ������ ����� ������������! ���.28.05.2020
               p_mg        in params.period%type default null, -- ������ ������� (��� ���.�������-������ ������� ������) -- ������ ����� ������������! ���.28.05.2020
               p_sel_uk    in varchar2, -- ������ ��
               p_rfcur     out ccur -- ���.���������
               );
procedure contractors(p_klsk in number, -- klsk ���������
                 p_is_closed in number, -- �������� �� �������� ����, ���� ���� ����? (0-���, 1-��)
                 p_mg in params.period%type, -- ������ �������
                 p_sel_flt_tp in number, -- �������������� ������
                 p_sel_uk in varchar2, -- ������ ��
                 p_rfcur out ccur);

procedure getQr(p_klsk in number, -- klsk ���������
                 p_is_closed in number, -- �������� �� �������� ����, ���� ���� ����? (0-���, 1-��)
                 p_mg in params.period%type, -- ������ �������
                 p_sel_tp in number, -- 0 - ��� ���.������: �������� � ���, 1 - ���.���, 3 - ������ ���
                 p_sel_flt_tp in number, -- �������������� ������
                 p_sel_uk in varchar2, -- ������ ��
                 p_rfcur out ccur
  );

procedure detail(p_klsk in number, -- klsk ���������
                 p_is_closed in number, -- �������� �� �������� ����, ���� ���� ����? (0-���, 1-��)
                 p_mg in params.period%type, -- ������ �������
                 p_sel_tp in number, -- 0 - ��� ���.������: �������� � ���, 1 - ���.���
                 p_sel_flt_tp in number, -- �������������� ������
                 p_sel_uk in varchar2, -- ������ ��
                 p_rfcur out ccur
  );
procedure funds_flow_by_klsk(
                 p_klsk in number, -- klsk ���������
                 p_sel_tp in number, -- 0 - ��� ���.������: �������� � ���, 1 - ���.���
                 p_sel_flt_tp in number, -- �������������� ������
                 p_is_closed in number, -- �������� �� �������� ����, ���� ���� ����? (0-���, 1-��)
                 p_mg in params.period%type, -- ������ �������
                 p_sel_uk in varchar2, -- ������ ��
                 p_rfcur out ccur
  );
procedure get_chargepay(p_lsk in varchar2, -- ���.��.
                 p_mg in params.period%type default '000000', -- �������� ������
                 p_mg_from in params.period%type default '000000', -- ������ �������
                 p_mg_to in params.period%type default '999999', -- ������ �������
                 p_rfcur out ccur
  );
  
end rep_bills_compound;
/

