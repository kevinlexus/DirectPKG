CREATE OR REPLACE TRIGGER SCOTT."C_PEN_CORR_BIU_E"
  before insert or update on c_pen_corr
  for each row
declare
 l_cnt number;
begin
  select nvl(count(*),0) into l_cnt from period_reports r
    where r.mg=:new.dopl;
  if l_cnt = 0 then
    Raise_application_error(-20000, '�� ���������� ������!');
  end if;

  if :new.usl is not null and :new.org is null then
    -- ��������! ����� ����������� ������������� ������ �� ���� ���.04.07.2019
    Raise_application_error(-20000, '��� ���������� ������, ���������� ���������� �����������!');
  end if;

  if :new.id is null then
    select scott.c_pen_corr_id.nextval, u.id, sysdate into :new.id, :new.fk_user, :new.ts from t_user u
       where u.cd=user;
  end if;
  if not :new.dtek between init.get_dt_start and init.get_dt_end then
    Raise_application_error(-20000, '�� ���������� ���� ��������!');
  end if;
end c_pen_corr_biu_e;
/

