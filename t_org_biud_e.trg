CREATE OR REPLACE TRIGGER SCOTT.t_org_biud_e
  before insert or update or delete on t_org
  for each row
declare
cnt_ number;
begin
  if inserting then
    if :new.id is null then
      select scott.t_org_id.nextval into :new.id from dual;
      :new.cd := :new.id;
    end if;
  end if;
end t_org_bi;
/

