CREATE OR REPLACE TRIGGER SCOTT.u_listtp_bi
  before insert on u_listtp
  for each row
declare
begin
  if :new.id is null then
    select scott.u_list_id.nextval into :new.id from dual;
  end if;
end u_listtp_bi;
/

