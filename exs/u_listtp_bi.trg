CREATE OR REPLACE TRIGGER EXS."U_LISTTP_BI"
  before insert on exs.u_listtp
  for each row
declare
begin
  if :new.id is null then
    select exs.SEQ_BASE.nextval into :new.id from dual;
  end if;
end u_listtp_bi;
/

