CREATE OR REPLACE TRIGGER SCOTT.spr_tarif_usl_aue
  after update of usl on spr_tarif
  for each row
declare
 cnt_ number;
begin
null;
 --Странно.... а оно надо?
  --Антенны
  --Проверка на корректность обновления поля usl
/*  select nvl(count(*),0) into cnt_
    from nabor n where n.usl=:old.usl and n.fk_tarif=:old.id;
  if cnt_ > 0 then
    Raise_application_error(-20001,
      'Данный тариф используется другой услугой, изменение запрещено!');
  end if;*/
end;
/

