create or replace package scott.rep_bills_ext is
  type ccur is ref cursor;
  tab tab_bill_detail;
  -- ����������� �����, ������������� �����, ��� ������ �������
  procedure detail(p_lsk  IN KART.lsk%TYPE, -- ���.����
                 p_mg   IN PARAMS.period%type, -- ������ �������
                 p_rfcur out ccur);
  -- ����������� �����
  procedure detail(p_lsk  IN KART.lsk%TYPE, -- ���.����
                 p_mg   IN PARAMS.period%type, -- ������ �������
                 p_includeSaldo in number, -- �������� �� ������ � ������ (1-��, 0 - ���)
                 p_rfcur out ccur);

-- ���������� ������ ��� �����
function procRow(p_lvl in number, -- ������� �������
                 p_parent_usl in usl.usl%type, -- ��� ������������ ������.
                 t_bill_row IN tab_bill_row, -- ������ � �����������, ������ � �.�.
                 p_bill_var IN number,
                 p_house_id IN number,
                 p_tp IN number
                 ) return rec_bill_row;
function getRow(
                 p_usl in usl.usl%type, -- ��� ������.
                 t_bill_row IN tab_bill_row -- ������ � �����������, ������ � �.�.
                 ) return rec_bill_row;

-- �������� ����� �� �������� ������� ��� �����
/*function getChildRowSum(
                 p_is_sum_vol in number, -- ����������� ����� (0-���,1-��)
                 p_parent_usl in usl.usl%type, -- ��� ������������ ������.
                 t_bill_row IN tab_bill_row -- ������ � �����������, ������ � �.�.
                 ) return rec_bill_row;
*/
end rep_bills_ext;
/

