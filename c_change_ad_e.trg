CREATE OR REPLACE TRIGGER SCOTT.c_change_ad_e
  after delete on c_change
  for each row
declare
begin
 if nvl(c_charges.trg_proc_next_month,0)=0 then
   --���� �� ������� ������
    logger.log_act(:old.lsk, '�������� ����������� �� �/c: '||:old.lsk||' �����:'||:old.summa||' ����:'||to_char(:old.dtek,'DD.MM.YYYY'), 2);
 end if;
end c_change_ad_e;
/

