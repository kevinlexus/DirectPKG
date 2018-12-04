CREATE OR REPLACE TRIGGER SCOTT.t_role_bi
  before insert on t_role
  for each row
declare
begin
  if :new.id is null then
    select scott.t_role_id.nextval into :new.id from dual;
  end if;
end t_role_bi;
/

