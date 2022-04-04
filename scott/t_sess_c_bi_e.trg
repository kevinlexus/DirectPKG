CREATE OR REPLACE TRIGGER SCOTT.t_sess_c_bi_e
  before insert on t_sess
  for each row
declare
begin
  if :new.id is null then
    select scott.t_sess_id.nextval into :new.id from dual;
  end if;
end t_sess_bi_e;
/

