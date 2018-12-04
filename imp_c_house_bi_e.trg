CREATE OR REPLACE TRIGGER SCOTT.imp_c_house_bi_e
  before insert on imp_c_houses
  for each row

begin
  --���������� ��� �� sequence ��� � �� c_houses,
  --����� ��������� ����� ������ � c_houses
  if :new.id is null then
    select c_house_id.nextval into :new.id from dual;
  end if;
end;
/

