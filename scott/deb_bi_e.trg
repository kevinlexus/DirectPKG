CREATE OR REPLACE TRIGGER SCOTT.deb_bi_e
  before insert on deb
  for each row
declare
begin
  if :new.id is null then
    select scott.deb_id.nextval into :new.id from dual;
  end if;
end deb_bi_e;
/

