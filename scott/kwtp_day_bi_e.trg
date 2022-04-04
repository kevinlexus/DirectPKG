CREATE OR REPLACE TRIGGER SCOTT.kwtp_day_bi_e
  before insert on kwtp_day
  for each row
declare
begin
  if :new.id is null then
    select scott.kwtp_day_id.nextval into :new.id from dual;
  end if;
end kwtp_day_bi_e;
/

