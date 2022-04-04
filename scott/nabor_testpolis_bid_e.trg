CREATE OR REPLACE TRIGGER SCOTT.nabor_testpolis_bid_e
  before delete or insert on testpolis.nabor
  for each row
begin

if inserting then
  if :new.id is null then
    select nabor_id.nextval into :new.id from dual;
  end if;
end if;
end;
/

