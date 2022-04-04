CREATE OR REPLACE TRIGGER SCOTT.spr_params_adu_l2c
  -- ����� ��������, ���������� (�� �� ����������, ��� ���������� ��� �������� � L2C)
  after delete or update on spr_params
begin
  -- �������� ��� Hibernate L2C
  p_java.evictL2Cache;

end spr_params_adu_l2c;
/

