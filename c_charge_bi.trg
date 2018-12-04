CREATE OR REPLACE TRIGGER SCOTT.c_charge_bi
  before insert on c_charge
  for each row
declare
begin
  if :new.id is null then
    select scott.c_charge_id.nextval into :new.id from dual;
  end if;
  if :new.usl is null then
    Raise_application_error(-20000, 'Попытка добавить строку с пустым кодом USL по лиц.счету:'||:new.lsk);
  end if;
end c_charge_bi;
/

