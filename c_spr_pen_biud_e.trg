CREATE OR REPLACE TRIGGER SCOTT.c_spr_pen_biud_e
  before insert or update or delete on c_spr_pen
  for each row
begin
  if inserting then
    if :new.id is null then
      select scott.c_spr_pen_id.nextval into :new.id from dual;
    end if;
  end if;

end c_spr_pen_biud_e;
/

