CREATE OR REPLACE TRIGGER SCOTT.KART_EXT_biu_e
  before insert or update on KART_EXT
  for each row
begin
  if inserting then
    if :new.id is null then
      select scott.KART_EXT_id.nextval into :new.id from dual;
    end if;
    :new.dt_crt:= sysdate;
    :new.dt_upd := sysdate;
  elsif updating then
    :new.dt_upd := sysdate;
  end if;

end KART_EXT_biu_e;
/

