CREATE OR REPLACE TRIGGER SCOTT.params_adu
  -- ����� ����������
  after update on params
begin
  -- ������������� �������� � Java
  p_java.reloadParams;

end params_adu;
/

