CREATE OR REPLACE TRIGGER SCOTT.period_reports_bde
  before delete on period_reports
  for each row
begin
  --if :old.dat < to_date('20160101','YYYYMMDD') then
    --������ ��� ������� ������
  --  Raise_application_error(-20000, '�������� ������������ ��� ������ #235');
 -- end if;
 null;

end;
/

