create or replace trigger scott.doa_emp_briu
  before insert or update on doa_emp
  for each row
begin
  if :new.hiredate > sysdate then
    raise_application_error(-20000, 'Hiredate cannot be in the future');
  end if;
end doa_emp_briu;
/

