CREATE OR REPLACE TRIGGER SCOTT.du_obj_comp_bi_e
  before insert on du_obj_comp
  for each row
declare
begin
  if :new.id is null then
    select scott.du_obj_id.nextval into :new.id from dual;
  end if;
end du_obj_comp_bi_e;
/

