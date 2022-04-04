CREATE OR REPLACE TRIGGER SCOTT.a_kart_pr2_bie
  before insert on a_kart_pr2
  for each row
declare
begin
  if :new.rec_id is null then
    select scott.a_kart_pr2_id.nextval into :new.rec_id from dual;
  end if;
end a_kart_pr2_bie;
/

