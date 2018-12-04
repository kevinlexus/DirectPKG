CREATE OR REPLACE TRIGGER SCOTT.c_kwtp_mg_bi_e
  before insert on c_kwtp_mg
  for each row
declare
begin
  if :new.id is null then
    select scott.c_kwtp_mg_id.nextval into :new.id from dual;
  end if;
end c_kwtp_mg_bi_e;
/

