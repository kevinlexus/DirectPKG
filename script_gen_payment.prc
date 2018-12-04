create or replace procedure scott.script_gen_payment is
cnt_ number;
begin
  cnt_:=c_get_pay.set_date(trunc(sysdate));
  c_get_pay.set_nkom('999');
  for c in (select t.lsk, e.lsk as lsk2, t.oper, sum(t.summa) as summa
      from a_kwtp t, kart k, kart e,
  (select t.lsk, sum(summa) as summa from saldo t where mg='200803'
              group by t.lsk --только платежи по дебетовому сальдо
              having sum(summa) > 0) a
    where t.mg='200802' and
    exists (select * from work_houses h where h.id=k.house_id and h.newreu in
    ('11','12','13','14','15'))
    and k.lsk=t.lsk and k.lsk=a.lsk and k.c_lsk_id=e.c_lsk_id and k.lsk<>e.lsk
    group by t.lsk, e.lsk, t.oper)
  loop
    c_get_pay.get_payment(c.lsk, -1 * c.summa, 0, c.oper, '200802', 1);
    c_get_pay.get_payment(c.lsk2, c.summa, 0, c.oper, '200802', 1);
  commit;
  end loop;

end script_gen_payment;
/

