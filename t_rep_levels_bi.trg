CREATE OR REPLACE TRIGGER SCOTT.t_rep_levels_bi
  before insert on rep_levels
  for each row
declare
begin
  if :new.id is null then
    select scott.rep_levels_id.nextval into :new.id from dual;
  end if;
end t_rep_levels_bi;
/

