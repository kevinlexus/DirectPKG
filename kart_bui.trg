CREATE OR REPLACE TRIGGER SCOTT.kart_bui
  before update or insert on kart
declare
begin
--   c_charges.trg_klsk_flag:=0;
  if nvl(c_charges.trg_klsk_flag,0)=0 then
    c_charges.trg_tab_klsk.delete;
  end if;
end;
/

