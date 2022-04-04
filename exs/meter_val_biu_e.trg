CREATE OR REPLACE TRIGGER EXS."METER_VAL_BIU_E"
  BEFORE INSERT or update on EXS.METER_VAL
  FOR EACH ROW
begin
  if inserting then
    IF :NEW.ID is null THEN
       :NEW.ID:= exs.seq_METER_VAL.nextval;
    END IF;
    :new.dt_crt:= sysdate;
    :new.dt_upd := sysdate;
  elsif updating then
    :new.dt_upd := sysdate;
  end if;
END;
/

