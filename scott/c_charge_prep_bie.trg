CREATE OR REPLACE TRIGGER SCOTT.c_charge_prep_bie
  before insert on c_charge_prep
  for each row
declare
begin
  if :new.id is null then
    select scott.c_charge_prep_id.nextval into :new.id from dual;
  end if;
end c_charge_prep_bie;
/

