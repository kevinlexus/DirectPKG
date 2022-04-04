CREATE OR REPLACE TRIGGER SCOTT.tree_adr_BIU_E
  BEFORE INSERT or update on scott.tree_adr
  FOR EACH ROW
begin
  if inserting then
    IF :NEW.ID is null THEN
       :NEW.ID:= tree_adr_ID.nextval;
    END IF;
  end if;
END tree_adr_BIU_E;
/

