CREATE OR REPLACE TRIGGER EXS."U_LIST_BIE"
  before insert on exs.u_list
  for each row
declare
begin
  if :new.id is null then
    select exs.SEQ_BASE.nextval into :new.id from dual;
  end if;
end u_list_bie;
/

