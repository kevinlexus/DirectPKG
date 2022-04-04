CREATE OR REPLACE TRIGGER SCOTT.log_bi_e
  before insert on log
  for each row
declare
begin
  if :new.id_rec is null then
    select scott.log_id.nextval into :new.id_rec from dual;
  end if;
end log_bi_e;
/

