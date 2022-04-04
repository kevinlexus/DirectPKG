CREATE OR REPLACE TRIGGER SCOTT.MESSAGES_AIS
  after insert on messages
declare
begin
    admin.TRG_DEL_REC;
end UPD;
/

