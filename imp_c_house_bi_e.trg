CREATE OR REPLACE TRIGGER SCOTT.imp_c_house_bi_e
  before insert on imp_c_houses
  for each row

begin
  --используем тот же sequence что и на c_houses,
  --чтобы поместить потом записи в c_houses
  if :new.id is null then
    select c_house_id.nextval into :new.id from dual;
  end if;
end;
/

