CREATE OR REPLACE TRIGGER SCOTT.spk_aie
  after insert on spk
  for each row
begin
  --�������� � ����� ��������� ������ ����� � ���-����.
  insert into c_spk_usl c (spk_id, usl_id, koef)
    select utils.spk_id_, usl, 0 from usl u;
end;
/

