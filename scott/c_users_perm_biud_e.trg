CREATE OR REPLACE TRIGGER SCOTT.C_USERS_PERM_biud_e
  before insert on C_USERS_PERM
  for each row
begin
  if inserting then
    if :new.id is null then
      select scott.C_USERS_PERM_id.nextval into :new.id from dual;
    end if;
  end if;

end C_USERS_PERM_biud_e;
/

