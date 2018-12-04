CREATE OR REPLACE TRIGGER SCOTT.pen_bi_e
  before insert on pen
  for each row
declare
begin
  if :new.id is null then
    select scott.pen_id.nextval into :new.id from dual;
  end if;
end pen_bi_e;
/

