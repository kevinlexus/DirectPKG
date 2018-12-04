CREATE OR REPLACE TRIGGER SCOTT.period_reports_aiu
  before insert or update on period_reports
  for each row
declare
  set_ number;
begin
  --автоматически подписать отчёты
  select nvl(p.auto_sign,0) into set_ from params p;
  if set_=1 then
   :new.signed:=1;
  end if;

end;
/

