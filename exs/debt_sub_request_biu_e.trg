create or replace trigger exs.debt_sub_request_BIU_E
  before insert or update on exs.debt_sub_request
  for each row
begin
  if inserting then
    if :new.ID is null then
      :new.ID := EXS.seq_debt_sub_request.nextval;
    end if;
    :new.dt_crt := sysdate;
    :new.dt_upd := sysdate;
  elsif updating then
    :new.dt_upd := sysdate;
  end if;

      if :new.fk_user is null then
      select t.id into :new.fk_user from scott.t_user t where t.cd=user;
    end if;

end;
/

