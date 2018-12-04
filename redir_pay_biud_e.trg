CREATE OR REPLACE TRIGGER SCOTT.REDIR_PAY_biud_e
  before insert or update or delete on REDIR_PAY
  for each row
begin
  if inserting then
    if :new.id is null then
      select scott.REDIR_PAY_id.nextval into :new.id from dual;
    end if;
  end if;

end REDIR_PAY_biud_e;
/

