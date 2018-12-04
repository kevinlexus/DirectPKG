CREATE OR REPLACE TRIGGER SCOTT.t_bill_det_bi_e
  before insert on c_bill_det
  for each row
declare
begin
  if :new.id is null then
    select scott.c_bill_det_id.nextval into :new.id from dual;
  end if;
end c_bill_det_e;
/

