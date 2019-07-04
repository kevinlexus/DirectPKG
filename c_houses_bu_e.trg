CREATE OR REPLACE TRIGGER SCOTT.c_houses_bu_e
  before update of fk_pasp_org, kran1 on c_houses
  for each row

declare
  cnt_ number;
begin
  --обновление id паспортного стола в карточках
  update kart k set k.fk_pasp_org=:new.fk_pasp_org
   where k.house_id=:old.id;
  --Краны из системы отопления
  update kart k set k.kran1=:new.kran1
   where k.house_id=:old.id;
  --if nvl(:old.kran1,0) <> nvl(:new.kran1,0) then
    --cnt_:=c_charges.gen_charges(null, null, null, :old.id, 0, 0);
  --end if;
end;
/

