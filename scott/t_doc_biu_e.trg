CREATE OR REPLACE TRIGGER SCOTT."t_doc_BIU_E"
  BEFORE INSERT or update on scott.t_doc
  FOR EACH ROW
begin
  if inserting then
    IF :NEW.ID is null THEN
       :NEW.ID:= t_doc_ID.nextval;
    END IF;
    :new.dt_crt:= sysdate;
    :new.dt_upd := sysdate;
    if :new.fk_user is null then
      select t.id into :new.fk_user from t_user t where t.cd=user;
    end if;
  elsif updating then
    :new.dt_upd := sysdate;
  end if;
END "t_doc_BIU_E";
/

