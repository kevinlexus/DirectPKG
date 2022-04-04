CREATE OR REPLACE TRIGGER SCOTT.spr_koeff_bi
  before insert on spr_koeff
  for each row
declare
begin
  if :new.id is null then
    select scott.spr_koeff_id.nextval into :new.id from dual;
  end if;
end spr_koeff_bi;
/

