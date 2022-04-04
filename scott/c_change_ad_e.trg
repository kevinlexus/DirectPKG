CREATE OR REPLACE TRIGGER SCOTT.c_change_ad_e
  after delete on c_change
  for each row
declare
begin
 if nvl(c_charges.trg_proc_next_month,0)=0 then
   --если не переход мес€ца
    logger.log_act(:old.lsk, '”даление перерасчета по л/c: '||:old.lsk||' сумма:'||:old.summa||' дата:'||to_char(:old.dtek,'DD.MM.YYYY'), 2);
 end if;
end c_change_ad_e;
/

