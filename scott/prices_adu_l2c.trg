CREATE OR REPLACE TRIGGER SCOTT.prices_adu_l2c
  -- ����� ��������, ���������� (�� �� ����������, ��� ���������� ��� �������� � L2C)
  after delete or update on prices
begin
  -- �������� ��� Hibernate L2C
  p_java.evictL2Cache;

end prices_adu_l2c;
/

