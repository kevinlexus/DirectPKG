CREATE OR REPLACE TRIGGER SCOTT.usl_bi
  before insert on usl
  for each row
declare
begin
  if :new.cd is null then
    :new.cd:=:new.usl;
  end if;
end usl_bi;
/

