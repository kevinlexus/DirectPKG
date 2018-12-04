CREATE OR REPLACE TRIGGER SCOTT.pp_proj_bi_e
  before insert on pp_proj
  for each row
declare
begin
  if :new.id is null then
    select scott.changes_id.nextval into :new.id from dual;
  end if;

end pp_proj_bi_e;
/

