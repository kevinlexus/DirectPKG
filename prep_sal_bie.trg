CREATE OR REPLACE TRIGGER SCOTT.prep_sal_bie
  before insert on prep_sal
  for each row
declare
begin
  if :new.id is null then
    select scott.prep_sal_id.nextval into :new.id from dual;
  end if;
end prep_sal_bie;
/

