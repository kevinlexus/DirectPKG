CREATE OR REPLACE TRIGGER SCOTT.kart_detail_bi_e
  before insert on kart_detail
  for each row
declare
begin
  if :new.id is null then
    select scott.kart_detail_id.nextval into :new.id from dual;
  end if;
end kart_detail_bi_e;
/

