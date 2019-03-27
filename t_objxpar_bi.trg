CREATE OR REPLACE TRIGGER SCOTT.t_objxpar_bi
  before insert on T_OBJXPAR
  for each row
declare
begin
  if :new.id is null then
    select scott.T_OBJXPAR_id.nextval into :new.id from dual;
  end if;

end t_objxpar_bi;
/

