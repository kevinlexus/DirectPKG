CREATE OR REPLACE TRIGGER SCOTT.kwtp_day_bu_e
  before update of summa, usl, org on kwtp_day
  for each row
declare
begin
  if nvl(c_get_pay.g_flag_upd,0)=0 then 
    logger.log_act(:old.lsk, 'Ручное распределение оплаты c_kwtp_mg.id='||:old.kwtp_id, 2);
  end if;

end kwtp_day_bu_e;
/

