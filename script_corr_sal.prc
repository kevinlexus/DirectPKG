create or replace procedure scott.script_corr_sal is
id_ number;
mg_ char(6);
begin
--Корректировка сальдо по УК
--Перенос сальдо с одной орг. на другую, по той же услуге
--исправить MG!!!!!!!!!!!!!!!!!!
mg_:='200808';
delete from c_change_docs t where t.user_id=11;
delete from c_change t where t.user_id=11;
commit;

select changes_id.nextval into id_ from dual;


insert into c_change_docs
  (id, mgchange, dtek, ts, user_id, text)
values
  (id_, mg_,trunc(sysdate), sysdate, 11, 'Корректировка сальдо по УК');


insert into c_change
  (lsk, usl, summa, proc, mgchange, nkom, org, type, dtek, ts, user_id, doc_id)
  select t.lsk, t.usl, t.summa as summa, null as proc, mg_ as mgchange,
  '010' as nkom, n.org, 0 as type, trunc(sysdate) as dtek, sysdate, 11, id_ as doc_id
    from saldo_usl t, kart k, nabor n, s_reu_trest s
   where t.mg = mg_
     and t.lsk = k.lsk
     and t.lsk = n.lsk
     and t.usl = n.usl
     and k.reu = s.reu
     and s.trest = '03'
     and t.org in (10);

insert into c_change
  (lsk, usl, summa, proc, mgchange, nkom, org, type, dtek, ts, user_id, doc_id)
  select t.lsk, t.usl, -1 * t.summa as summa, null as proc, mg_ as mgchange,
  '010' as nkom, t.org, 0 as type, trunc(sysdate) as dtek, sysdate, 11, id_ as doc_id
    from saldo_usl t, kart k, nabor n, s_reu_trest s
   where t.mg = mg_
     and t.lsk = k.lsk
     and t.lsk = n.lsk
     and t.usl = n.usl
     and k.reu = s.reu
     and s.trest = '03'
     and t.org in (10);

insert into c_change
  (lsk, usl, summa, proc, mgchange, nkom, org, type, dtek, ts, user_id, doc_id)
  select t.lsk, t.usl, t.summa as summa, null as proc, mg_ as mgchange,
  '010' as nkom, n.org, 0 as type, trunc(sysdate) as dtek, sysdate, 11, id_ as doc_id
    from saldo_usl t, kart k, nabor n, s_reu_trest s
   where t.mg = mg_
     and t.lsk = k.lsk
     and t.lsk = n.lsk
     and t.usl = n.usl
     and k.reu = s.reu
     and s.trest = '03'
     and t.org in (12);

insert into c_change
  (lsk, usl, summa, proc, mgchange, nkom, org, type, dtek, ts, user_id, doc_id)
  select t.lsk, t.usl, -1 * t.summa as summa, null as proc, mg_ as mgchange,
  '010' as nkom, t.org, 0 as type, trunc(sysdate) as dtek, sysdate, 11, id_ as doc_id
    from saldo_usl t, kart k, nabor n, s_reu_trest s
   where t.mg = mg_
     and t.lsk = k.lsk
     and t.lsk = n.lsk
     and t.usl = n.usl
     and k.reu = s.reu
     and s.trest = '03'
     and t.org in (12);
commit;

end script_corr_sal;
/

