CREATE OR REPLACE TRIGGER SCOTT.MESSAGES_BIR
  before insert on messages
  for each row
declare
id_ NUMBER;
begin
   select messages_id.nextval into id_ from dual;
   :New.id := id_;
   admin.TRG_SET_VAR(:New.from_id);
end UPD;
/

