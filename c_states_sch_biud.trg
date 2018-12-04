CREATE OR REPLACE TRIGGER SCOTT.c_states_sch_biud
  before insert or update on c_states_sch
declare
begin
   c_charges.tb_rec_states.delete;
end c_states_sch_biud;
/

