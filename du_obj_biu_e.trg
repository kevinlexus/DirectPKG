CREATE OR REPLACE TRIGGER SCOTT.du_obj_biu_e
  before insert or update on du_obj
  for each row
declare
begin
  if :new.id is null then
    select scott.du_obj_id.nextval into :new.id from dual;
  end if;
  if updating then
    delete from du_obj_comp t
     where t.fk_du_obj=:old.id;
  end if;
end du_obj_biu_e;
/

