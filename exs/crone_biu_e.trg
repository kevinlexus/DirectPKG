CREATE OR REPLACE TRIGGER EXS."CRONE_BIU_E"
  BEFORE INSERT or update on EXS.CRONE
  FOR EACH ROW
begin
  IF :NEW.ID is null THEN
     :NEW.ID:= exs.seq_CRONE.nextval;
  END IF;
END;
/

