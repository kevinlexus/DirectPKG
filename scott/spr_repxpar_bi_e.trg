CREATE OR REPLACE TRIGGER SCOTT.spr_repxpar_bi_e
  before insert on REPXPAR
  for each row
declare
begin
  if :new.id is null then
    select scott.spr_repxpar_id.nextval into :new.id from dual;
  end if;
end spr_repxpar_bi_e;
/

