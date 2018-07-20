CREATE OR REPLACE TRIGGER SCOTT.t_reports_bi
  before insert on reports
  for each row
declare
begin
  if :new.id is null then
    select scott.reports_id.nextval into :new.id from dual;
  end if;
end t_reports_bi;
/

