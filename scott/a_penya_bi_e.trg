CREATE OR REPLACE TRIGGER SCOTT.a_penya_bi_e
  before insert on a_penya
  for each row
begin
  if :new.id is null then
    select a_penya_id.nextval into :new.id from dual;
  end if;

end a_penya_bi_e;
/

