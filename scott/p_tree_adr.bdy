create or replace package body scott.P_TREE_ADR is

-- обновить таблицу поиска и выбора объектов
-- используется в поиске объектов для перерасчетов
procedure tree_adr_load is
begin
  delete from tree_adr;
  insert into tree_adr(
                       kul,
                       nd,
                       kw,
                       adr,
                       k_lsk_id,
                       tp,
                       k_lsk_id_divided)
  select a.kul, a.nd, a.kw, a.adr, a.k_lsk_id, a.tp,
   case when lead(a.adr, 1) over (order by a.street, a.ord1, a.ord2, a.tp, a.ord3, a.ord4)=a.adr
          or lag(a.adr, 1) over (order by a.street, a.ord1, a.ord2, a.tp, a.ord3, a.ord4)=a.adr
     then a.k_lsk_id else null end as k_lsk_id_divided
  from (
  select distinct t.kul, t.nd, null as kw, s.name as street, s.name||', '||ltrim(t.nd,'0') as adr, null as k_lsk_id, 0 as tp,
  scott.utils.f_ord_digit(nd) as ord1, scott.utils.f_ord3(nd) as ord2, null as ord3, null as ord4
   from scott.c_houses t join scott.spul s on t.kul=s.id
  union all
  select distinct t.kul, t.nd, t.kw, s.name as street, '    '||s.name||', '||ltrim(t.nd,'0')||', '||ltrim(t.kw,'0') as adr, t.k_lsk_id, 1 as tp,
  scott.utils.f_ord_digit(nd), scott.utils.f_ord3(nd), scott.utils.f_ord_digit(kw), scott.utils.f_ord3(kw)
  from scott.kart t join scott.spul s on t.kul=s.id
  ) a
  order by street, ord1, ord2, tp, ord3, ord4;
end;

end P_TREE_ADR;
/

