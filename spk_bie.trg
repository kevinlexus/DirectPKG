CREATE OR REPLACE TRIGGER SCOTT.spk_bie
  before insert on spk
  for each row
begin
  :new.id:=utils.spk_id_;
end;
/

