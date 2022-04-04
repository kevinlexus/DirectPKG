CREATE OR REPLACE TRIGGER SCOTT.LOAD_KART_EXT_bi_e
  before insert or update on LOAD_KART_EXT
  for each row
begin
  if inserting then
    if :new.id is null then
      select scott.LOAD_KART_EXT_id.nextval into :new.id from dual;
    end if;
  end if;
  if :new.lsk is not null and :new.fk_klsk_premise is not null then
    Raise_application_error(-20000, 'Ошибка! Не должно быть заполнено одновременно Лиц.сч. и KLSK Помещения!');
  end if;
end LOAD_KART_EXT_bi_e;
/

