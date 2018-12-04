CREATE OR REPLACE TRIGGER SCOTT.a_charge2_bie
  before insert on a_charge2
  for each row
declare
begin
  if :new.id is null then
    select scott.a_charge_id.nextval into :new.id from dual;
  end if;
end a_charge2_bie;
/

