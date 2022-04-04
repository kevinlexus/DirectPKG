CREATE OR REPLACE TRIGGER SCOTT.lock_kart_buid
  before insert or update or delete on kart
--  for each row
declare
  cnt_ number;
begin
  select nvl(max(t.parn1),0) into cnt_ from spr_params t where
   t.cd='kart_update';
  if cnt_=1 and init.g_admin_acc = 0 then
    Raise_application_error(-20000,
      'БАЗА ДАННЫХ ЗАКРЫТА! В доступе к объектам карточек отказано!');
  end if;
end lock_kart_buid;
/

