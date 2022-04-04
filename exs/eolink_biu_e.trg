CREATE OR REPLACE TRIGGER EXS.EOLINK_BIU_E
  BEFORE INSERT or update on EXS.EOLINK
  FOR EACH ROW
begin
  if inserting then
    IF :NEW.ID is null THEN
       :NEW.ID:= exs.seq_EOLINK.nextval;
    END IF;
    :new.dt_crt:= sysdate;
    :new.dt_upd := sysdate;
  elsif updating then
    :new.dt_upd := sysdate;
  end if;

  select t.id into :new.fk_user from scott.t_user t where t.cd=user;
  
  if :new.fk_objtp in (1) then
    -- организация
    :new.app_tp:=2;
  end if;
  -- список типов объектов, по которым не могут быть заполнены reu,kul,nd, exp_lsk_tp
  if :new.fk_objtp not in (18) and :new.fk_uk is not null then
    -- не лиц.счет
    Raise_application_error(-20000, 'Недопустим FK_UK!');
  end if;
  if :new.fk_objtp not in (17, 67, 72) then
    -- не помещение
   if :new.kw is not null then
    Raise_application_error(-20000, 'Недопустим KW!');
   end if;
  end if;
  if :new.fk_objtp not in (14,17,49,67,72) and
    (:new.kul is not null or :new.nd is not null) then
      -- не объекты типа дом, квартира, подъезд
      Raise_application_error(-20000, 'Недопустимы KUL, ND!');

  end if;
  if :new.fk_objtp not in (1,10,14,17,18,49,67,72) and
    :new.reu is not null then
      -- не объекты типа reu+kul+nd
      Raise_application_error(-20000, 'Недопустим REU!');
  end if;
  if :new.fk_objtp not in (1) and
    :new.app_tp is not null then
      -- не организация
      -- не объекты типа reu+kul+nd
      Raise_application_error(-20000, 'Недопустим APP_TP!');
  end if;


END;
/

