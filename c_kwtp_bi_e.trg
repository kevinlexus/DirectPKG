CREATE OR REPLACE TRIGGER SCOTT.c_kwtp_bi_e
  before insert on c_kwtp
  for each row
declare
begin
  if :new.id is null then
    select scott.c_kwtp_id.nextval into :new.id from dual;
  end if;
end c_kwtp_bi_e;
/

