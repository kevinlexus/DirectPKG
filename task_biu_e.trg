CREATE OR REPLACE TRIGGER EXS."TASK_BIU_E"
  BEFORE INSERT or update on EXS.TASK
  FOR EACH ROW
begin
  if inserting then
    IF :NEW.ID is null THEN
       :NEW.ID:= exs.seq_TASK.nextval;
    END IF;
    :new.dt_crt:= sysdate;
    :new.dt_upd := sysdate;
    if :new.fk_user is null then
      select t.id into :new.fk_user from sec.t_user t where t.cd=user;
    end if;
  elsif updating then
    :new.dt_upd := sysdate;
    if :new.state in ('INS','ACK') then
       :new.dt_nextstart:=null;  
       :new.lag_nextstart:=null;
       :new.fk_eolink_last:=null;
    end if;
  end if;
END;
/

