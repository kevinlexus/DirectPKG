CREATE OR REPLACE TRIGGER SCOTT.list_c_bi_e
  before insert on list_c
  for each row
declare
begin
  if :new.id is null then
    select scott.list_c_id.nextval into :new.id from dual;
  end if;
  if :new.fk_ses is null then
    select USERENV('sessionid') into :new.fk_ses from dual;
  end if;
end list_c_bi_e;
/

