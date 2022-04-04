CREATE OR REPLACE TRIGGER SCOTT.LIST_CHOICES_HS_bi_e
  before insert on LIST_CHOICES_HS
  for each row
declare
  l_id number;
begin
  if :new.id is null then
    select LIST_CHOICES_HS_id.nextval into :new.id from dual;
  end if;
end;
/

