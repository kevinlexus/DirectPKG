CREATE OR REPLACE TRIGGER SCOTT.c_states_sch_aiud
  after insert or update or delete on c_states_sch
declare
cnt_ number;
begin

for element in 1 .. c_charges.tb_rec_states.count loop
  if c_charges.tb_rec_states(element).lsk is not null then
    --обновить признак счетчика в карточке л/c
    utils.upd_krt_sch_state(c_charges.tb_rec_states(element).lsk);
  end if;
end loop;

end c_states_sch_aiud;
/

