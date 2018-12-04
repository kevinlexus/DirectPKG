CREATE OR REPLACE TRIGGER SCOTT.t_corrects_payments_bie
  before insert on t_corrects_payments
  for each row
begin
  if :new.id is null then
    select scott.t_corrects_payments_id.nextval into :new.id from dual;
  end if;
end t_corrects_payments_bie;
/

