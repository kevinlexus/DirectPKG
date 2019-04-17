CREATE OR REPLACE TRIGGER SCOTT.t_org_adu_l2c
  -- ����� ��������, ���������� (�� �� ����������, ��� ���������� ��� �������� � L2C)
  after delete or update on t_org
begin
  -- �������� ��� Hibernate L2C
  p_java.evictL2Cache;

end t_org_adu_l2c;
/

