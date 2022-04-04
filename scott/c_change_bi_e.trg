CREATE OR REPLACE TRIGGER SCOTT.c_change_bi_e
  before insert on c_change
  for each row
declare
begin
  if :new.id is null then
    select scott.changes_id.nextval into :new.id from dual;
  end if;
end c_change_bi_e;
/

