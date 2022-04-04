CREATE OR REPLACE TRIGGER SCOTT.c_states_pr_biude
  before insert or update or delete on c_states_pr
  for each row
declare
  TYPE rec_kart_pr IS RECORD (
     lsk c_kart_pr.lsk%type,
     fio c_kart_pr.fio%type);
  rec_kart_pr_ rec_kart_pr;
  txt_ c_status_pr.name%type;
  txt2_ c_status_pr.name%type;

begin
    --элементы, которые надо проверить в триггере after
    if inserting then
     :new.dt_crt:= sysdate;
     :new.dt_upd := sysdate;
     if :new.fk_user is null then
      select t.id into :new.fk_user from scott.t_user t where t.cd=user;
     end if;

      if nvl(:new.dt1, to_date('01011900','DDMMYYYY'))
           > nvl(:new.dt2, to_date('01012900','DDMMYYYY')) then
        Raise_application_error(-20000, 'Внимание! Указаная дата окончания периода статуса прописки/регистрации прожив.меньше начальной!');
      end if;
      if :new.id is null then
        select scott.c_states_pr_id.nextval into :new.id from dual;
      end if;
      c_charges.tb_rec_pr_states.extend;
      c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).id := :new.id;
      c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).fk_kart_pr := :new.fk_kart_pr;
      --c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).fk_tp := :new.fk_tp;
      c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).dt1 := :new.dt1;
      c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).dt2 := :new.dt2;

      --аудит
      select c.name into txt_ from c_status_pr c where c.id=:new.fk_status;
      select c.lsk, c.fio into rec_kart_pr_ from c_kart_pr c where c.id=:new.fk_kart_pr;

      logger.log_act(rec_kart_pr_.lsk, 'добавлен новый период действия статуса проживающего: '||
         trim(rec_kart_pr_.fio)||' -'||
         txt_||
         case when :new.dt1 is not null then ' c '||to_char(:new.dt1,'DD.MM.YYYY') else ' с неопределенной даты начала ' end||
        case when :new.dt2 is not null then ' по '||to_char(:new.dt2,'DD.MM.YYYY') else ' по неопределенную дату окончания ' end, 2);
    elsif updating then
      :new.dt_upd := sysdate;
      if nvl(:new.dt1, to_date('01011900','DDMMYYYY'))
           > nvl(:new.dt2, to_date('01012900','DDMMYYYY')) then
        Raise_application_error(-20000, 'Внимание! Указаная дата окончания периода статуса прописки/регистрации прожив.меньше начальной!');
      end if;
      c_charges.tb_rec_pr_states.extend;
      c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).id := :old.id;
      c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).fk_kart_pr := :old.fk_kart_pr;
      --c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).fk_tp := :old.fk_tp;
      c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).dt1 := :new.dt1;
      c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).dt2 := :new.dt2;
      --аудит
      select c.name into txt_ from c_status_pr c where c.id=:old.fk_status;
      select c.name into txt2_ from c_status_pr c where c.id=:new.fk_status;
      select c.lsk, c.fio into rec_kart_pr_ from c_kart_pr c where c.id=:old.fk_kart_pr;
      logger.log_act(rec_kart_pr_.lsk,
      logger.log_text('Обновлен период действия статуса проживающего: '||
         trim(rec_kart_pr_.fio),
         txt_||
         case when :old.dt1 is not null then ' c '||to_char(:old.dt1,'DD.MM.YYYY') else ' с неопределенной даты начала ' end||
         case when :old.dt2 is not null then ' по '||to_char(:old.dt2,'DD.MM.YYYY') else ' по неопределенную дату окончания ' end,
         txt2_||
         case when :new.dt1 is not null then ' c '||to_char(:new.dt1,'DD.MM.YYYY') else ' с неопределенной даты начала ' end||
         case when :new.dt2 is not null then ' по '||to_char(:new.dt2,'DD.MM.YYYY') else ' по неопределенную дату окончания ' end)
        , 2);
      --аудит
    elsif deleting then
      c_charges.tb_rec_pr_states.extend;
      c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).id := :old.id;
      c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).fk_kart_pr := :old.fk_kart_pr;
      --c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).fk_tp := :old.fk_tp;
      c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).dt1 := :old.dt1;
      c_charges.tb_rec_pr_states(c_charges.tb_rec_pr_states.last).dt2 := :old.dt2;
      --аудит, вести если не было каскадного удаления из c_kart_pr (иначе mutating в триггере)
      if nvl(c_charges.trg_c_kart_pr_bd,0) = 0 then
        select c.name into txt_ from c_status_pr c where c.id=:old.fk_status;
        select c.lsk, c.fio into rec_kart_pr_ from c_kart_pr c where c.id=:old.fk_kart_pr;
        logger.log_act(rec_kart_pr_.lsk, 'Удален период действия статуса проживающего: '||
           trim(rec_kart_pr_.fio)||' -'||
           txt_||
           case when :old.dt1 is not null then ' c '||to_char(:old.dt1,'DD.MM.YYYY') else ' с неопределенной даты начала ' end||
          case when :old.dt2 is not null then ' по '||to_char(:old.dt2,'DD.MM.YYYY') else ' по неопределенную дату окончания ' end, 2);
      end if;
    end if;
end c_states_pr_biude;
/

