CREATE OR REPLACE TRIGGER SCOTT.u_list_bi
  before insert on u_list
  for each row
declare
begin
  if :new.id is null then
    select scott.u_list_id.nextval into :new.id from dual;
  end if;
  if :new.cd is null then
     :new.cd:=:new.id;
  end if;
end u_list_bi;
/

