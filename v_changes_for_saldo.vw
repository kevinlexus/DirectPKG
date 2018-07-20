create or replace force view scott.v_changes_for_saldo as
select lsk, sum(summa) as summa, org, usl, type
        from (
          select
          p.lsk, p.summa, p.usl, t.fk_org2 as org, decode(p.type,1,1,2,1,3,3,0) as type
           from a_nabor2 k, c_change p, t_org t, params m
          where k.lsk = p.lsk
            and p.mg2 between k.mgFrom and k.mgTo
            and k.usl = p.usl
            and k.org=t.id
            and p.org is null  -- где не указан код орг и старые периоды
            and exists             --и где найдена услуга в архивном справочнике
            (select * from a_nabor2 n where n.lsk=k.lsk and p.mg2 between n.mgFrom and n.mgTo and n.usl=k.usl)
            and p.mg2 < m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
          select
          p.lsk, p.summa, p.usl, t.fk_org2, decode(p.type,1,1,2,1,3,3,0) as type
           from nabor k, c_change p, t_org t, params m
          where k.lsk = p.lsk
            and k.usl = p.usl  --не должно быть такого, так как не понятно где брать орг
            and p.org is null  -- где не указан код орг и старые периоды
            and k.org=t.id
            and not exists             --и где НЕ найдена услуга в архивном справочнике
            (select * from a_nabor2 n where n.lsk=k.lsk and p.mg2 between n.mgFrom and n.mgTo and n.usl=k.usl)
            and p.mg2 < m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
         select
          p.lsk, p.summa, p.usl, t.fk_org2, decode(p.type,1,1,2,1,3,3,0) as type
           from nabor k, c_change p, t_org t, params m
          where k.lsk = p.lsk
            and k.usl = p.usl
            and k.org=t.id
            and p.org is null  -- где не указан код орг и новые периоды
            and p.mg2 >= m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
          select
          p.lsk, p.summa, p.usl, nvl(t.fk_org2, 0) as org, decode(p.type,1,1,2,1,3,3,0) as type
           from kart r, c_change p, t_org t, params m
          where r.lsk = p.lsk
            and p.org=t.id
            and p.org is not null  -- где указан код орг и не важно какой период
            and to_char(p.dtek, 'YYYYMM') = m.period)
             group by lsk, org, usl, type
;

