CREATE OR REPLACE TRIGGER SCOTT."T_DOCXPAR_BIU_E"
  BEFORE INSERT or update on scott.T_DOCXPAR
  FOR EACH ROW
begin
  if inserting then
    IF :NEW.ID is null THEN
       :NEW.ID:= T_DOCXPAR_ID.nextval;
    END IF;
    :new.dt_crt := sysdate;
    :new.dt_upd := sysdate;
    if :new.fk_user is null then
      select t.id into :new.fk_user from t_user t where t.cd=user;
    end if;
  elsif updating then
    :new.dt_upd := sysdate;
  end if;
END;
/

