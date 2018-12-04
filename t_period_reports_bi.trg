CREATE OR REPLACE TRIGGER SCOTT.t_period_reports_bi
  before insert on period_reports
  for each row
declare
begin
  if :new.id is null then
    select scott.period_rep_id.nextval into :new.id from dual;
  end if;
end t_period_reports_bi;
/

