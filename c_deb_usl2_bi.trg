CREATE OR REPLACE TRIGGER SCOTT.c_deb_usl2_bi
  before insert on c_deb_usl2
  for each row
declare
begin
  if :new.id is null then
    select scott.c_deb_usl_id.nextval into :new.id from dual;
  end if;
end c_deb_usl2_bi;
/

