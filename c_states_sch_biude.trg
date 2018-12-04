CREATE OR REPLACE TRIGGER SCOTT.c_states_sch_biude
  before insert or update or delete on c_states_sch
  for each row
declare
begin
    --��������, ������� ���� ��������� � �������� after
    if inserting then
      if nvl(:new.dt1, to_date('01011900','DDMMYYYY'))
           > nvl(:new.dt2, to_date('01012900','DDMMYYYY')) then
        Raise_application_error(-20000, '��������! �������� ���� ��������� ������� �������� ������� ��������� ������ ���������!!');
      end if;
      if :new.id is null then
        select scott.c_states_sch_id.nextval into :new.id from dual;
      end if;
      c_charges.tb_rec_states.extend;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).id := :new.id;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).lsk := :new.lsk;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).dt1 := :new.dt1;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).dt2 := :new.dt2;

      logger.log_act(:new.lsk, '�������� ����� ������ �������� ������� ��������: '||
        case when :new.fk_status =0 then '��������'
             when :new.fk_status =1 then '��.�.�. � �.�.'
             when :new.fk_status =2 then '��.�.�.'
             when :new.fk_status =3 then '��.�.�.'
             when :new.fk_status =8 then '�����.'
             when :new.fk_status =9 then '������'
             else '' end||
         case when :new.dt1 is not null then ' c '||to_char(:new.dt1,'DD.MM.YYYY') else ' � �������������� ���� ������ ' end||
        case when :new.dt2 is not null then ' �� '||to_char(:new.dt2,'DD.MM.YYYY') else ' �� �������������� ���� ��������� ' end, 2);
    elsif updating then
      if nvl(:new.dt1, to_date('01011900','DDMMYYYY'))
           > nvl(:new.dt2, to_date('01012900','DDMMYYYY')) then
        Raise_application_error(-20000, '��������! �������� ���� ��������� ������� ������� ��������� ������ ���������!!');
      end if;
      c_charges.tb_rec_states.extend;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).id := :old.id;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).lsk := :old.lsk;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).dt1 := :new.dt1;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).dt2 := :new.dt2;
      logger.log_act(:old.lsk,
        logger.log_text('�������� ������ �������� ������� ��������: ',
        case when :old.fk_status =0 then '��������'
             when :old.fk_status =1 then '��.�.�. � �.�.'
             when :old.fk_status =2 then '��.�.�.'
             when :old.fk_status =3 then '��.�.�.'
             when :old.fk_status =8 then '�����.'
             when :old.fk_status =9 then '������'
             else '' end||
         case when :old.dt1 is not null then ' c '||to_char(:old.dt1,'DD.MM.YYYY') else ' � �������������� ���� ������ ' end||
        case when :old.dt2 is not null then ' �� '||to_char(:old.dt2,'DD.MM.YYYY') else ' �� �������������� ���� ��������� ' end,
        case when :new.fk_status =0 then '��������'
             when :new.fk_status =1 then '��.�.�. � �.�.'
             when :new.fk_status =2 then '��.�.�.'
             when :new.fk_status =3 then '��.�.�.'
             when :new.fk_status =8 then '�����.'
             when :new.fk_status =9 then '������'
             else '' end||
         case when :new.dt1 is not null then ' c '||to_char(:new.dt1,'DD.MM.YYYY') else ' � �������������� ���� ������ ' end||
        case when :new.dt2 is not null then ' �� '||to_char(:new.dt2,'DD.MM.YYYY') else ' �� �������������� ���� ��������� ' end), 2);
    elsif deleting then
      c_charges.tb_rec_states.extend;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).id := :old.id;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).lsk := :old.lsk;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).dt1 := :old.dt1;
      c_charges.tb_rec_states(c_charges.tb_rec_states.last).dt2 := :old.dt2;
      logger.log_act(:old.lsk, '����� ������ �������� ������� ��������: '||
        case when :old.fk_status =0 then '��������'
             when :old.fk_status =1 then '��.�.�. � �.�.'
             when :old.fk_status =2 then '��.�.�.'
             when :old.fk_status =3 then '��.�.�.'
             when :old.fk_status =8 then '�����.'
             when :old.fk_status =9 then '������'
             else '' end||
         case when :old.dt1 is not null then ' c '||to_char(:old.dt1,'DD.MM.YYYY') else ' � �������������� ���� ������ ' end||
        case when :old.dt2 is not null then ' �� '||to_char(:old.dt2,'DD.MM.YYYY') else ' �� �������������� ���� ��������� ' end, 2);
    end if;
end c_states_sch_biude;
/

