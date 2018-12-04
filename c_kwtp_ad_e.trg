CREATE OR REPLACE TRIGGER SCOTT.c_kwtp_ad_e
  after delete on c_kwtp
  for each row
declare
begin
  if nvl(c_charges.trg_proc_next_month,0) = 0  then
    --���� ��������� ����������� - �������� � ���
    logger.log_act(:old.lsk, '�������� ������ �� �/c: '||:old.lsk||' �����:'||:old.summa||' ����:'||:old.penya||' ���� �������:'||to_char(:old.dtek,'DD.MM.YYYY'), 2);
  end if;
end c_kwtp_bd_e;
/

