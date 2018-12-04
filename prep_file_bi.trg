CREATE OR REPLACE TRIGGER SCOTT.prep_file_bi
  before insert on prep_file
  for each row
declare
begin
  if :new.id is null then
    select scott.prep_file_id.nextval into :new.id from dual;
  end if;

end prep_file_bi;
/

