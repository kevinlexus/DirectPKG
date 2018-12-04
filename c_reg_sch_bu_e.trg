CREATE OR REPLACE TRIGGER SCOTT.c_reg_sch_bu_e
  before update on c_reg_sch
  for each row
declare
begin
  select t.id as fk_user, 
    sysdate as dtf into :new.fk_user, :new.dtf from scott.t_user t where t.cd=user;
end c_reg_sch_bu_e;
/

