CREATE OR REPLACE TRIGGER SCOTT.c_kwtp_mg_d_e
  after delete on c_kwtp_mg
  for each row
begin
-- ред.22.04.19 триггер сделан, так как был удалён
-- каскадный foreign key на C_KWTP из KWTP_DAY (ввиду того что Java распределение
-- не видело Entity C_KWTP_MG

   delete from kwtp_day t
   where t.kwtp_id=:old.id;
   
   delete from kwtp_day_log t
   where t.fk_c_kwtp_mg=:old.id;

end c_kwtp_mg_ai_e;
/

