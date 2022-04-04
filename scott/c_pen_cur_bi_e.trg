CREATE OR REPLACE TRIGGER SCOTT.c_pen_cur_bi_e
  before insert on c_pen_cur
  for each row
begin
  if inserting then
    if :new.id is null then
      select scott.c_pen_cur_id.nextval into :new.id from dual;
    end if;
  end if;

end c_pen_cur_bi_e;
/

