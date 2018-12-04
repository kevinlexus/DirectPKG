CREATE OR REPLACE TRIGGER SCOTT.nabor_fk_tarif_bu_e
  before update of  fk_tarif on nabor
  for each row
declare
  cnt_ number;
  cena_ number;
  id_ number;
begin
  if nvl(:old.fk_tarif,0) <> nvl(:new.fk_tarif,0) then
  --обновление тарифа
    select max(nvl(t.cena,0)) into cena_ from spr_tarif_prices t, params p where t.fk_tarif=:new.fk_tarif
      and p.period between t.mg1 and t.mg2;
      :new.koeff:=cena_;
  end if;
end;
/

