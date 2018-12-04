CREATE OR REPLACE TRIGGER SCOTT.pen_ref_bi_e
  before insert on pen_ref
  for each row
declare
begin
  if :new.id is null then
    select scott.pen_ref_id.nextval into :new.id from dual;
  end if;
end pen_ref_bi_e;
/

