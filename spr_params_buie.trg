CREATE OR REPLACE TRIGGER SCOTT.spr_params_buie
  before insert or update on spr_params
  for each row
begin
  if inserting then
    if :new.id is null then
      select scott.spr_params_id.nextval into :new.id from dual;
    end if;
  end if;
  if nvl(:new.cdtp,0) = 0 and (:new.parvc1 is not null or :new.pardt1 is not null) then
    RAISE_APPLICATION_ERROR(-20001, 'Не допустим ввод символьного значения и даты  по данному параметру!');
  elsif nvl(:new.cdtp,0) = 1 and (:new.parn1 is not null or :new.pardt1 is not null) then
    RAISE_APPLICATION_ERROR(-20001, 'Не допустим ввод числового значения и даты по данному параметру!');
  elsif nvl(:new.cdtp,0) = 2 and (:new.parvc1 is not null or :new.parn1 is not null) then
    RAISE_APPLICATION_ERROR(-20001, 'Не допустим ввод числового и символьного значения по данному параметру!');
  end if;
end;
/

