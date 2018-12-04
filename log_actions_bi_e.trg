CREATE OR REPLACE TRIGGER SCOTT.log_actions_bi_e
  before insert on log_actions
  for each row
begin
  if :new.id is null then
    select scott.log_actions_id.nextval,
     to_char(sysdate, 'YYYYMM')
     into :new.id, :new.mg from dual;
  end if;
end;
/

