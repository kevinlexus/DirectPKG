CREATE OR REPLACE TRIGGER EXS.PDOC_BIU_E
  BEFORE INSERT or update on EXS.PDOC
  FOR EACH ROW
begin
  if inserting then
    IF :NEW.ID is null THEN
       :NEW.ID:= exs.seq_PDOC.nextval;
    END IF;
    :new.dt_crt:= sysdate;
    :new.dt_upd := sysdate;
  elsif updating then
    if :new.dt!=scott.getdt(1,0,0)-1 then
      Raise_application_error(-20000, 'ОШИБКА, запрещено обновление ПД прошлого периода загрузки!');
    end if;
    :new.dt_upd := sysdate;
  end if;
END;
/

