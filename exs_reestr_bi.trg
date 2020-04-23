CREATE OR REPLACE TRIGGER EXS."EXS_REESTR_BI"
  before insert
  on EXS.REESTR
  for each row
declare
  -- local variables here
begin
  IF :NEW.ID is null THEN
     :NEW.ID:= exs.seq_reestr.nextval;
  END IF;
end exs_reestr_bi;
/

