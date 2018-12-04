CREATE OR REPLACE TRIGGER SCOTT.c_penya_biud_e
  before insert or update or delete on c_penya
  for each row
begin
  if inserting then
    if :new.id is null then
      select scott.c_penya_id.nextval into :new.id from dual;
    end if;
  end if;

end c_penya_biud_e;
/

