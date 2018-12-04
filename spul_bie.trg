CREATE OR REPLACE TRIGGER SCOTT.spul_bie
  before insert on spul
  for each row
declare
 id_ spul.id%type;
begin
--копируем в новую категорию льготы коэфф с раб-служ.
if :new.id is null then
 select lpad(trim(to_char(max(to_number(o.id)+1))), 4, '0') into id_
   from spul o;
 :new.id:=id_;
end if;
end;
/

