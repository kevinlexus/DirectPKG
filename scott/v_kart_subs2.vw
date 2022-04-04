create or replace force view scott.v_kart_subs2 as
select t.reu, t.lsk, p.name, ltrim(t.nd,'0') as nd, ltrim(t.kw,'0') as kw, s.summa as subs, e.summa as subs_el, t.mg
 from arch_kart t, a_houses h, spul p, list_choices_reu l,
 (select lsk, mg, sum(summa) as summa from arch_subsidii
  where usl_id<>'024' group by lsk, mg) s,
 (select lsk, mg, sum(summa) as summa from arch_subsidii
  where usl_id='024' group by lsk, mg) e,
 (select lsk, mg, sum(summa) as summa from arch_charges
  where usl_id = '023' group by lsk, mg
  having sum(summa) <>0
  ) c
 where t.lsk=s.lsk(+) and t.mg=s.mg(+)
  and h.mg=t.mg and t.house_id=h.id and nvl(h.house_type ,0) = 1 /* общаги */
  and t.lsk=e.lsk(+) and t.mg=e.mg(+)
  and t.lsk=c.lsk(+) and t.mg=c.mg(+)
  and t.kul=p.id and e.summa <> 0
  and t.reu=l.reu and l.sel=0;

