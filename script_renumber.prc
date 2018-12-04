create or replace procedure scott.script_renumber is
  oldreu_ kart.reu%type;
  reu_ kart.reu%type;
  lsk1_ kart.lsk%type;
begin
  --скрипт для присоединения УК к существующим УК
  oldreu_:='34';
  reu_:='15';
update kart t set t.polis = null;
update kart t set t.polis =
  lpad((select max(lsk)
   from kart k where k.reu = oldreu_)+rownum,8,'0')
    where t.reu = reu_;
update kart t set t.lsk=t.polis, t.polis=t.lsk
 where t.reu = reu_;
 update c_kart_pr t set t.lsk= (select k.lsk from kart k where k.polis=t.lsk
   and k.reu = reu_)
   where exists (select * from kart k where k.polis=t.lsk
   and k.reu = reu_);
 update saldo_usl t set t.lsk= (select k.lsk from kart k where k.polis=t.lsk
   and k.reu = reu_)
   where exists (select * from kart k where k.polis=t.lsk
   and k.reu = reu_);
 update nabor t set t.lsk= (select k.lsk from kart k where k.polis=t.lsk
   and k.reu = reu_)
   where exists (select * from kart k where k.polis=t.lsk
   and k.reu = reu_);

 update c_charge t set t.lsk= (select k.lsk from kart k where k.polis=t.lsk
   and k.reu = reu_)
    where exists (select * from kart k where k.polis=t.lsk
   and k.reu = reu_);

 update c_chargepay t set t.lsk= (select k.lsk from kart k where k.polis=t.lsk
   and k.reu = reu_)
    where exists (select * from kart k where k.polis=t.lsk
   and k.reu = reu_);

update c_houses t set t.reu =oldreu_
 where t.reu = reu_;
update kart t set t.reu =oldreu_
 where t.reu = reu_;


 commit;
end script_renumber;
/

