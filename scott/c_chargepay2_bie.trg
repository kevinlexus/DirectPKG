CREATE OR REPLACE TRIGGER SCOTT.c_chargepay2_bie
  before insert on c_chargepay2
  for each row
declare
begin
  if :new.id is null then
    select scott.c_chargepay2_id.nextval into :new.id from dual;
  end if;
end c_chargepay2_bie;
/

