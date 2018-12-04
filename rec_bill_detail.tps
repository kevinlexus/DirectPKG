CREATE OR REPLACE TYPE SCOTT."REC_BILL_DETAIL" as object
(
  is_amnt_sum      number,  -- ����������� � ���� � fastreport
  usl         CHAR(3), -- ��� ������
  npp           NUMBER, -- � �.�.
  name         VARCHAR2(100), -- ������������
  price        NUMBER, -- ����
  vol          NUMBER, -- �����
  charge       NUMBER, -- ����������
  change1      NUMBER, -- ����������
  change_proc1 NUMBER, -- % �� �����������
  change2      NUMBER, -- ����������
  amnt         NUMBER, -- �����
  deb          NUMBER, -- ������(�������������)
  bill_col     number, -- � ����� ������� �������� ����� (�������� usl.bill_col)
  bill_col2    number, -- ������� ����� � ���.���. (�������� usl.bill_col2)
  kub          number  -- ����� ����
  )
/

