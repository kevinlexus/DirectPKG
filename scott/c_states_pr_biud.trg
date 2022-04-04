CREATE OR REPLACE TRIGGER SCOTT.c_states_pr_biud
  before insert or update or delete on c_states_pr
declare
begin
    c_charges.tb_rec_pr_states.delete;

end c_states_pr_biud;
/

