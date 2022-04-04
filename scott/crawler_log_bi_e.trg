CREATE OR REPLACE TRIGGER SCOTT.CRAWLER_LOG_bi_e
  before insert on CRAWLER_LOG
  for each row
begin
  if :new.id is null then
    select scott.CRAWLER_LOG_id.nextval into :new.id from dual;
  end if;
end CRAWLER_LOG_bi_e;
/

