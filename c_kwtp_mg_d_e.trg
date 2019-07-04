CREATE OR REPLACE TRIGGER SCOTT.c_kwtp_mg_d_e
  after delete on c_kwtp_mg
  for each row
begin
-- ���.22.04.19 ������� ������, ��� ��� ��� �����
-- ��������� foreign key �� C_KWTP �� KWTP_DAY (����� ���� ��� Java �������������
-- �� ������ Entity C_KWTP_MG

   delete from kwtp_day t
   where t.kwtp_id=:old.id;
   
   delete from kwtp_day_log t
   where t.fk_c_kwtp_mg=:old.id;

end c_kwtp_mg_ai_e;
/

