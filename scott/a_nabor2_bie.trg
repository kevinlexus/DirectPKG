CREATE OR REPLACE TRIGGER SCOTT.a_nabor2_bie
  before insert on a_nabor2
  for each row
declare
begin
  if :new.id is null then
    select scott.a_nabor_id.nextval into :new.id from dual;
  end if;
end a_nabor2_bie;
/

