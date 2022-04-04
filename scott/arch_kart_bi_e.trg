CREATE OR REPLACE TRIGGER SCOTT.ARCH_KART_bi_e
  before insert on ARCH_KART
  for each row
declare
  l_id number;
begin
  if :new.id is null then
    select ARCH_KART_id.nextval into :new.id from dual;
  end if;
end;
/

