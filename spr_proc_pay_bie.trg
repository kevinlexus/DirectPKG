CREATE OR REPLACE TRIGGER SCOTT.SPR_PROC_PAY_bie
  before insert on SPR_PROC_PAY
  for each row
declare
begin
  if :new.id is null then
    select scott.SPR_PROC_PAY_id.nextval into :new.id from dual;
  end if;
end SPR_PROC_PAY_bie;
/

