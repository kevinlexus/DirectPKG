CREATE OR REPLACE TRIGGER SCOTT.t_housexlist_bie
  before insert on t_housexlist
  for each row
declare
begin
  if :new.id is null then
    select scott.t_housexlist_id.nextval into :new.id from dual;
  end if;
end t_housexlist_bie;
/

