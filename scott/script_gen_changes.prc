create or replace procedure scott.script_gen_changes is
cnt_ number;
begin
   --проводим одним документом
   insert into c_change_docs
    (id, mgchange, dtek, ts, user_id, text)
    values
    (changes_id.nextval, '200802', trunc(sysdate),
      sysdate, 11, 'Переброска начисления для УК');

  for c in (select t.lsk, e.lsk as lsk2, t.usl_id, sum(t.summa) as summa
      from arch_charges t, kart k, kart e,
  (select t.lsk, sum(summa) as summa from saldo t where mg='200803'
              group by t.lsk --только начисление по дебетовому сальдо
              having sum(summa) > 0) a
    where t.mg='200802' and
    exists (select * from work_houses h where h.id=k.house_id and h.newreu in
    ('11','12','13','14','15'))
    and k.lsk=t.lsk and k.lsk=a.lsk and k.c_lsk_id=e.c_lsk_id and k.lsk<>e.lsk
    group by t.lsk, e.lsk, t.usl_id)
  loop
  insert into c_change
    (lsk, usl, summa, proc, mgchange, nkom, org, type, dtek, ts, user_id, doc_id)
  values
    (c.lsk, c.usl_id,
     -1*c.summa, null, '200802', '999', null, null, trunc(sysdate), sysdate,
     11, changes_id.currval);

  insert into c_change
    (lsk, usl, summa, proc, mgchange, nkom, org, type, dtek, ts, user_id, doc_id)
  values
    (c.lsk2, c.usl_id,
     c.summa, null, '200802', '999', null, null, trunc(sysdate), sysdate,
     11, changes_id.currval);
  commit;
  end loop;

end script_gen_changes;
/

