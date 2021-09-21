CREATE OR REPLACE TRIGGER SCOTT.SPR_BILL_PRINT_bi_e
  before insert on SPR_BILL_PRINT
  for each row
declare
begin
  if :new.id is null then
    select scott.SPR_BILL_PRINT_id.nextval into :new.id from dual;
  end if;
end SPR_BILL_PRINT_bi_e;
/

