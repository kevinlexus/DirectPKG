CREATE OR REPLACE TRIGGER SCOTT.log_penya_bi_e
  before insert on log_penya
  for each row
declare
begin
  if :new.id is null then
    select scott.log_penya_id.nextval into :new.id from dual;
  end if;
end log_penya_bi_e;
/

