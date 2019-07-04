CREATE OR REPLACE TRIGGER SCOTT.usl_receipt_bie
  before insert on usl_receipt
  for each row
declare
begin
  if :new.id is null then
    select scott.usl_receipt_id.nextval into :new.id from dual;
  end if;
end usl_receipt_bie;
/

