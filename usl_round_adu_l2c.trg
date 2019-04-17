CREATE OR REPLACE TRIGGER SCOTT.usl_round_adu_l2c
  -- ����� ��������, ���������� (�� �� ����������, ��� ���������� ��� �������� � L2C)
  after delete or update on usl_round
begin
  -- �������� ��� Hibernate L2C
  p_java.evictL2Cache;

end usl_round_adu_l2c;
/

