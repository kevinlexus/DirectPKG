CREATE OR REPLACE TRIGGER SCOTT.t_user_bie
  before insert on t_user
  for each row
declare
begin
  if :new.id is null then
    select scott.t_user_id.nextval into :new.id from dual;
  end if;
end t_user_bie;
/

