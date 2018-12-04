CREATE OR REPLACE TRIGGER SCOTT.lock_c_houses_buid
  before insert or update or delete on c_houses
--  for each row
declare
  cnt_ number;
begin
  select nvl(max(t.parn1),0) into cnt_ from spr_params t where
   t.cd='c_houses_update';
  if cnt_=1 and init.g_admin_acc = 0 then
    Raise_application_error(-20000, 'БАЗА ДАННЫХ ЗАКРЫТА! В доступе к списку домов отказано!');
  end if;
end lock_c_houses_buid;
/

