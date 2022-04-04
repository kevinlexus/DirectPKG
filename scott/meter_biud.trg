CREATE OR REPLACE TRIGGER SCOTT.meter_biud
  before insert or update on meter
declare
begin
   p_meter.tb_rec_obj.delete;
end meter_biud;
/

