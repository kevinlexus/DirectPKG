CREATE OR REPLACE TRIGGER SCOTT.usl_adu_l2c
  -- ����� ��������, ���������� (�� �� ����������, ��� ���������� ��� �������� � L2C)
  after delete or update on usl
begin
  -- �������� ��� Hibernate L2C
  p_java.evictL2Cache;

end usl_adu_l2c;
/

