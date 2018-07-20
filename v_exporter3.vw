create or replace force view scott.v_exporter3 as
select t.lsk,
       s.name || ',' || LTRIM(k.nd, '0') || '-' || LTRIM(k.kw, '0') as adr,
       t.reu,
       t.kul,
       t.nd,
       t.kw,
       initcap(rtrim(a.fio)) || ', ' || to_char(a.dat_rog, 'DD/MM/YYYY') || ', ' ||
       trim(d.doc) as fio,
       k.status,
       k.opl,
       lg_id,
       t.usl,
       t.org,
       t.cnt_main,
       t.summa,
       t.mg
  from xito_lg4 t,
       arch_kart k,
       a_kart_pr a,
       (select /* ◊®œŒœ¿ÀŒ Õ¿œ»—¿À, –≈¿À‹ÕŒ */
         c_kart_pr_id, mg, max(doc) as doc
          from a_lg_docs
         group by c_kart_pr_id, mg) d,
       spul s
 where t.lsk = a.lsk
   and a.id = d.c_kart_pr_id
   and a.mg = d.mg
   and t.kul = s.id
   and t.nomer = a.id
   and t.mg = a.mg
   and t.lsk = k.lsk
   and t.mg = k.mg
   and exists (select *
          from scott.list_choices_reu l
         where l.reu = t.reu
           and l.sel = 0);

