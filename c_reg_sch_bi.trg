CREATE OR REPLACE TRIGGER SCOTT.c_reg_sch_bi
  before insert on c_reg_sch
  for each row
declare
begin
  if :new.id is null then
    select scott.c_reg_sch_id.nextval as id, t.id as fk_user, 
      sysdate as dtf into :new.id, :new.fk_user, :new.dtf from scott.t_user t where t.cd=user;
  end if;
end c_reg_sch_bi;
/

