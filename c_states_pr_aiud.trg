CREATE OR REPLACE TRIGGER SCOTT.c_states_pr_aiud
  after insert or update or delete on c_states_pr
declare
cnt_ number;
begin
  --�� ���� ���������� �������� �� c_kart_pr
  if nvl(c_charges.trg_c_kart_pr_bd,0) = 0 then
  for element in 1 .. c_charges.tb_rec_pr_states.count loop
    if nvl(c_charges.debug_flag_,0)=0 then
     --�������� ������� ������� � �������� ������������
     utils.upd_c_kart_pr_state(c_charges.tb_rec_pr_states(element).fk_kart_pr);
--������� � ������ ���������� 11.04.14
--�������� ���� � ������� �����
--     c_kart.set_part_kpr_all(c_charges.tb_rec_pr_states(element).fk_kart_pr);
--     utils.upd_nabor_kf_kpr2(c_charges.tb_rec_pr_states(element).fk_kart_pr);
     --���������� ����������������
     utils.set_krt_adm2(c_charges.tb_rec_pr_states(element).fk_kart_pr);
    end if;
  end loop;
  end if;
end c_states_pr_aiud;
/

