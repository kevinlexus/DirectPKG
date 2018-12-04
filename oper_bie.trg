CREATE OR REPLACE TRIGGER SCOTT.oper_bie
  before insert on oper
  for each row
declare
 oper_ oper.oper%type;
begin
--�������� � ����� ��������� ������ ����� � ���-����.
if :new.oper is null then
  select min(oper) into oper_
  from (select lpad(rownum, 2, '0') as oper from all_objects t
  where rownum <99) a
  where not exists (select * from oper o where o.oper=a.oper);
  :new.oper:=oper_;
end if;
end;
/

