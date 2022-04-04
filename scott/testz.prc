CREATE OR REPLACE PROCEDURE SCOTT.testZ IS
cnt_ number;
BEGIN
for d in (select k.lsk, k.c_lsk_id from kart k where
    exists (select * from kart t where t.c_lsk_id=k.c_lsk_id
      and t.lsk=lpad('00010001',8,'0')))
loop
null;
  --начисление без коммита
  cnt_:=c_charges.gen_charges(d.lsk, d.lsk, null, 0, 0);
  --движение
  c_cpenya.gen_charge_pay(d.c_lsk_id, 0);
end loop;

END testZ;
/

