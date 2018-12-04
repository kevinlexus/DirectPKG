CREATE OR REPLACE TRIGGER SCOTT.c_change_docs_bi_e
  before insert on c_change_docs
  for each row
declare
begin

  if :new.id is null then
    select scott.changes_id.nextval into :new.id from dual;
  end if;

  if :new.ts is null then
    :new.ts := sysdate;
  end if;
  if :new.user_id is null then
    select u.id into :new.user_id
             from t_user u
            where u.cd = user;
  end if;
end c_change_docs_bi_e;
/

