CREATE OR REPLACE PROCEDURE SCOTT.test2 IS
--добавление услуг ант.дог по –Ё”-01
begin

--установка новой услуги
update nabor n set n.koeff =(select r.koeff from nabor r where r.lsk=n.lsk
 and r.usl='043'), n.norm =(select r.norm from nabor r where r.lsk=n.lsk
 and r.usl='043'), n.fk_tarif =(select r.fk_tarif from nabor r where r.lsk=n.lsk
 and r.usl='043'), n.org=553
 where n.usl='046'
 and exists
 (select * from kart k where k.lsk=n.lsk and exists
 (select * from killme_l1 m where m.kul=k.kul and m.nd=k.nd
  and m.kw=k.kw));

--удаление старой услуги
update nabor n set n.koeff =0, n.norm =0, n.fk_tarif =null
 where n.usl='043' and nvl(n.koeff,0)<>0 and nvl(n.norm,0) <>0
 and exists
 (select * from kart k where k.lsk=n.lsk and exists
 (select * from killme_l1 m where m.kul=k.kul and m.nd=k.nd
  and m.kw=k.kw));
commit;

END test2;
/

