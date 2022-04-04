CREATE OR REPLACE TRIGGER SCOTT.prices_bi_e
  before insert on prices
  for each row
begin
  if inserting then
    if :new.id is null then
      select scott.prices_id.nextval into :new.id from dual;
    end if;
  end if;
end prices_bi_e;
/

