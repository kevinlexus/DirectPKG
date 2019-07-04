CREATE OR REPLACE TRIGGER SCOTT.params_adu
  -- после обновления
  after update on params
begin
  -- перезагрузить сущность в Java
  p_java.reloadParams;

end params_adu;
/

