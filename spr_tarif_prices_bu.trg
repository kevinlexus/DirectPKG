CREATE OR REPLACE TRIGGER SCOTT.spr_tarif_prices_bu
  before update on spr_tarif_prices
begin
  init.spr_tarif_upd_:=1;
end;
/

