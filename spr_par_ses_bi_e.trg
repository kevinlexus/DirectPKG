CREATE OR REPLACE TRIGGER SCOTT.spr_par_ses_bi_e
  before insert on spr_par_ses
  for each row
declare
begin
  if :new.fk_ses is null then
    select USERENV('sessionid') into :new.fk_ses from dual;
  end if;
end spr_par_ses_bi_e;
/

