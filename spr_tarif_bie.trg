CREATE OR REPLACE TRIGGER SCOTT.spr_tarif_bie
  before insert on spr_tarif
  for each row
begin
  :new.mask:=lpad('0',992,'0');
  :new.id:=utils.spr_tarif_id_;
  :new.cd:=utils.spr_tarif_id_;
end;
/

