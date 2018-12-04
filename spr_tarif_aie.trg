CREATE OR REPLACE TRIGGER SCOTT.spr_tarif_aie
  after insert on spr_tarif
  for each row
begin
  insert into spr_tarifxprogs
    (fk_tarif, fk_prog)
   values
     (utils.spr_tarif_root_id_, :new.id);
end;
/

