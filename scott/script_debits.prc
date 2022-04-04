create or replace procedure scott.script_debits is
  mg_ params.period%TYPE;
begin
  --задолжники по лицевым
  --выполнять ДО перехода, выгружать, - когда угодно
  select '200803' into mg_ from params;
  delete from debits_lsk_month d where d.mg = mg_;
  insert into debits_lsk_month (lsk, reu, kul, name, nd, kw, fio, status, opl, cnt_month, dolg, nachisl,
   penya, payment, mg)
  select a.lsk, a.reu, a.kul, s.name, a.nd, a.kw, a.fio, a.status, a.opl,
       round(decode(b.summa,0, 0, a.dolg/b.summa),0) as cnt_month,
       a.dolg, b.summa as nachisl, a.penya, c.summa, mg_
   from
  (select t.c_lsk_id,t.reu,t.kul,t.nd,t.kw,t.fio,t.status,t.opl,t.lsk,
     nvl(t.dolg,0)+nvl(t.old_dolg,0) as dolg, nvl(t.penya,0)+nvl(t.old_pen,0) as penya
     from arch_kart t where t.mg=mg_ and t.psch <> 8) a,
  (select d.lsk,sum(d.summa_it) as summa
        from arch_charges d where d.mg=mg_
        and d.usl_id not in (select u.usl_id from usl_excl u)
        group by d.lsk) b,
  (select k.c_lsk_id, sum(d.summa) as summa
        from arch_kart k, arch_kwtp d where d.mg=mg_ and k.mg=mg_ and k.lsk=d.lsk
        and d.usl_id not in (select u.usl_id from usl_excl u)
        group by k.c_lsk_id) c,
        spul s
  where a.lsk=b.lsk(+) and a.kul=s.id and a.c_lsk_id=c.c_lsk_id(+) and round(decode(b.summa,0, 0, a.dolg/b.summa),0)>0;
  commit;
end script_debits;
/

