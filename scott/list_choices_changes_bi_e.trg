CREATE OR REPLACE TRIGGER SCOTT.LIST_CHOICES_CHANGES_bi_e
  before insert on LIST_CHOICES_CHANGES
  for each row
declare
  l_id number;
begin
  if :new.id is null then
    select LIST_CHOICES_CHANGES_id.nextval into :new.id from dual;
  end if;
end;
/

