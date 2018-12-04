CREATE OR REPLACE TRIGGER SCOTT.t_org_tp_bi
  before insert on t_org_tp
  for each row
declare
begin
  if :new.id is null then
    select scott.t_org_tp_id.nextval into :new.id from dual;
  end if;
end t_org_tp_bi;
/

