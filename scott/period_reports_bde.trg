CREATE OR REPLACE TRIGGER SCOTT.period_reports_bde
  before delete on period_reports
  for each row
begin
  --if :old.dat < to_date('20160101','YYYYMMDD') then
    --узнать кто удаляет записи
  --  Raise_application_error(-20000, 'Сообщить разработчику код ошибки #235');
 -- end if;
 null;

end;
/

