CREATE OR REPLACE TRIGGER SCOTT.c_deb_oper_bie
  before insert on c_deb_oper
  for each row
declare
begin
  if :new.id is null then
    select scott.c_deb_oper_id.nextval into :new.id from dual;
  end if;
end c_deb_oper_bie;
/

