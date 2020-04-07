CREATE OR REPLACE TRIGGER SCOTT.LOAD_KART_EXT_bi_e
  before insert on LOAD_KART_EXT
  for each row
begin
  if inserting then
    if :new.id is null then
      select scott.LOAD_KART_EXT_id.nextval into :new.id from dual;
    end if;
  end if;

end LOAD_KART_EXT_bi_e;
/

