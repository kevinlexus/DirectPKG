CREATE OR REPLACE TRIGGER SCOTT.meter_biude
  before insert or update or delete on meter
  for each row
declare
begin
  if inserting and :new.id is null then
    select scott.meter_id.nextval into :new.id from dual;
  end if;

  p_meter.tb_rec_obj.extend;
  if deleting then 
    p_meter.tb_rec_obj(p_meter.tb_rec_obj.last).klsk_obj := :old.FK_KLSK_OBJ;
  else
    p_meter.tb_rec_obj(p_meter.tb_rec_obj.last).klsk := :new.K_LSK_ID;
    p_meter.tb_rec_obj(p_meter.tb_rec_obj.last).klsk_obj := :new.FK_KLSK_OBJ;
    p_meter.tb_rec_obj(p_meter.tb_rec_obj.last).fk_usl := :new.FK_USL;

    -- запретить обновление показаний неактивного счетчика!
    if nvl(:new.N1,0) <> nvl(:old.N1,0) then
      p_meter.tb_rec_obj(p_meter.tb_rec_obj.last).n1 := :new.N1;
      p_meter.tb_rec_obj(p_meter.tb_rec_obj.last).isChng := 1; -- изменено показание
      for c in (select case when :new.DT1 <=last_day(to_date(p.period||'01', 'YYYYMMDD')) 
      and :new.DT2 > last_day(to_date(p.period||'01', 'YYYYMMDD')) 
      then 1 else 0 end as act
      from params p) loop
           if c.act <> 1 then
             Raise_application_error(-20000, 'Запрещено передавать показания по неактивному счетчику!');
           end if;
      end loop;
    end if;  

  end if;

end meter_biude;
/

