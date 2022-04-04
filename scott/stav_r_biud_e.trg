CREATE OR REPLACE TRIGGER SCOTT.stav_r_biud_e
  before insert or update or delete on stav_r
  for each row
begin
  if inserting then
    if :new.id is null then
      select scott.stav_r_id.nextval into :new.id from dual;
    end if;
  end if;

end stav_r_biud_e;
/

