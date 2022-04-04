CREATE OR REPLACE TRIGGER SCOTT.pen_dt_bi_e
  before insert on pen_dt
  for each row
declare
begin
  if :new.id is null then
    select scott.pen_dt_id.nextval into :new.id from dual;
  end if;
end pen_dt_bi_e;
/

