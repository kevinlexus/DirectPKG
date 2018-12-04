CREATE OR REPLACE TRIGGER SCOTT.t_usxrl_bi
  before insert on t_usxrl
  for each row
declare
begin
  if :new.id is null then
    select scott.t_usxrl_id.nextval into :new.id from dual;
  end if;
  select trim(to_char(:new.id)) into :new.cd from dual;
end t_usxrl_bi;
/

