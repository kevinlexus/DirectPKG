CREATE OR REPLACE TRIGGER SCOTT.temp_prep2_bi
  before insert on temp_prep2
  for each row
declare
begin
  if :new.id is null then
    select scott.temp_prep2_id.nextval into :new.id from dual;
  end if;
end temp_prep2_bi;
/

