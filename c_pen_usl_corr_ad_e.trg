CREATE OR REPLACE TRIGGER SCOTT.c_pen_usl_corr_ad_e
  after delete on c_pen_usl_corr
  for each row
declare
begin
  if nvl(c_charges.trg_proc_next_month,0) = 0  then
    --если разрешено логгировать - записать в лог
    logger.log_act(:old.lsk, 'Удаление корректировки пени по л/c: '||:old.lsk||' сумма:'||:old.penya||' дата корректировки:'||to_char(:old.dtek,'DD.MM.YYYY'), 2);
  end if;
end c_pen_usl_corr_ad_e;
/

