CREATE OR REPLACE TRIGGER SCOTT.spk_bi
  before insert on spk
declare
 spk_id_ number;
begin
--копируем в новую категорию льготы коэфф с раб-служ.
 select nvl(max(s.id),0) into spk_id_ from spk s;
 utils.spk_id_:=spk_id_+1;
end;
/

