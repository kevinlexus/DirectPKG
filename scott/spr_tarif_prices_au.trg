CREATE OR REPLACE TRIGGER SCOTT.spr_tarif_prices_au
  after update on spr_tarif_prices
begin
  init.spr_tarif_upd_:=0;
end;
/

