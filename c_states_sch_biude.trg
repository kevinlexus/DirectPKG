CREATE OR REPLACE TRIGGER SCOTT.c_states_sch_biude
  before insert or update or delete on c_states_sch
  for each row
declare
begin
    --элементы, которые надо проверить в триггере after
    if inserting then
      if nvl(:new.dt1, to_date('01011900','DDMMYYYY'))
           > nvl(:new.dt2, to_date('01012900','DDMMYYYY')) then
        Raise_application_error(-20000, 'Внимание! Указаная дата окончания периода действия статуса счетчиков меньше начальной!!');
      end if;
      if :new.id is null then
        select scott.c_states_sch_id.nextval into :new.id from dual;
      end if;
      c_charges.tb_rec_states.extend;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).id := :new.id;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).lsk := :new.lsk;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).dt1 := :new.dt1;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).dt2 := :new.dt2;

      logger.log_act(:new.lsk, 'добавлен новый период действия статуса счетчика: '||
        case when :new.fk_status =0 then 'Норматив'
             when :new.fk_status =1 then 'Сч.Х.В. и Г.В.'
             when :new.fk_status =2 then 'Сч.Х.В.'
             when :new.fk_status =3 then 'Сч.Г.В.'
             when :new.fk_status =8 then 'Прошл.'
             when :new.fk_status =9 then 'Закрыт'
             else '' end||
         case when :new.dt1 is not null then ' c '||to_char(:new.dt1,'DD.MM.YYYY') else ' с неопределенной даты начала ' end||
        case when :new.dt2 is not null then ' по '||to_char(:new.dt2,'DD.MM.YYYY') else ' по неопределенную дату окончания ' end, 2);
    elsif updating then
      if nvl(:new.dt1, to_date('01011900','DDMMYYYY'))
           > nvl(:new.dt2, to_date('01012900','DDMMYYYY')) then
        Raise_application_error(-20000, 'Внимание! Указаная дата окончания периода статуса счетчиков меньше начальной!!');
      end if;
      c_charges.tb_rec_states.extend;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).id := :old.id;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).lsk := :old.lsk;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).dt1 := :new.dt1;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).dt2 := :new.dt2;
      logger.log_act(:old.lsk,
        logger.log_text('Обновлен период действия статуса счетчика: ',
        case when :old.fk_status =0 then 'Норматив'
             when :old.fk_status =1 then 'Сч.Х.В. и Г.В.'
             when :old.fk_status =2 then 'Сч.Х.В.'
             when :old.fk_status =3 then 'Сч.Г.В.'
             when :old.fk_status =8 then 'Прошл.'
             when :old.fk_status =9 then 'Закрыт'
             else '' end||
         case when :old.dt1 is not null then ' c '||to_char(:old.dt1,'DD.MM.YYYY') else ' с неопределенной даты начала ' end||
        case when :old.dt2 is not null then ' по '||to_char(:old.dt2,'DD.MM.YYYY') else ' по неопределенную дату окончания ' end,
        case when :new.fk_status =0 then 'Норматив'
             when :new.fk_status =1 then 'Сч.Х.В. и Г.В.'
             when :new.fk_status =2 then 'Сч.Х.В.'
             when :new.fk_status =3 then 'Сч.Г.В.'
             when :new.fk_status =8 then 'Прошл.'
             when :new.fk_status =9 then 'Закрыт'
             else '' end||
         case when :new.dt1 is not null then ' c '||to_char(:new.dt1,'DD.MM.YYYY') else ' с неопределенной даты начала ' end||
        case when :new.dt2 is not null then ' по '||to_char(:new.dt2,'DD.MM.YYYY') else ' по неопределенную дату окончания ' end), 2);
    elsif deleting then
      c_charges.tb_rec_states.extend;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).id := :old.id;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).lsk := :old.lsk;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).dt1 := :old.dt1;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).dt2 := :old.dt2;
      logger.log_act(:old.lsk, 'удалён период действия статуса счетчика: '||
        case when :old.fk_status =0 then 'Норматив'
             when :old.fk_status =1 then 'Сч.Х.В. и Г.В.'
             when :old.fk_status =2 then 'Сч.Х.В.'
             when :old.fk_status =3 then 'Сч.Г.В.'
             when :old.fk_status =8 then 'Прошл.'
             when :old.fk_status =9 then 'Закрыт'
             else '' end||
         case when :old.dt1 is not null then ' c '||to_char(:old.dt1,'DD.MM.YYYY') else ' с неопределенной даты начала ' end||
        case when :old.dt2 is not null then ' по '||to_char(:old.dt2,'DD.MM.YYYY') else ' по неопределенную дату окончания ' end, 2);
    end if;
end c_states_sch_biude;
/

