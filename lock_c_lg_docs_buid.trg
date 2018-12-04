CREATE OR REPLACE TRIGGER SCOTT.lock_c_lg_docs_buid
  before insert or update or delete on c_lg_docs
--  for each row
declare
  cnt_ number;
begin
  select nvl(max(t.parn1),0) into cnt_ from spr_params t where
   t.cd='c_lg_docs_update';

  if cnt_=1 and init.g_admin_acc = 0 then
    Raise_application_error(-20000, '���� ������ �������! � ������� � ������ ���������� ����� ����������� ��������!');
  end if;
end lock_c_lg_docs_buid;
/

