CREATE OR REPLACE TRIGGER SCOTT.MESSAGES_BIS
  before insert on messages
declare
begin
    admin.TRG_DEL_VAR;
end UPD;
/

