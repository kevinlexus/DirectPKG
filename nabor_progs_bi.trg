CREATE OR REPLACE TRIGGER SCOTT.nabor_progs_bi
  before insert on nabor_progs
  for each row
declare
begin
  if :new.id is null then
    select scott.nabor_progs_id.nextval into :new.id from dual;
  end if;
end nabor_progs_bi;
/

