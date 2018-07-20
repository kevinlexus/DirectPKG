create or replace force view scott.v_changes_for_saldo_det as
select lsk, sum(summa) as summa, org, usl, dtek, mgchange
        from (
          select
          p.lsk, p.summa, p.usl, t.fk_org2 as org, p.mgchange, p.dtek
           from a_nabor2 k, c_change p, t_org t, params m
          where k.lsk = p.lsk
            and p.mg2 between k.mgFrom and k.mgTo
            and k.usl = p.usl
            and k.org=t.id
            and p.org is null  -- ��� �� ������ ��� ��� � ������ �������
            and exists             --� ��� ������� ������ � �������� �����������
            (select * from a_nabor2 n where n.lsk=k.lsk and p.mg2 between n.mgFrom and n.mgTo and n.usl=k.usl)
            and p.mg2 < m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
          select
          p.lsk, p.summa, p.usl, t.fk_org2, p.mgchange, p.dtek
           from nabor k, c_change p, t_org t, params m
          where k.lsk = p.lsk
            and k.usl = p.usl  --�� ������ ���� ������, ��� ��� �� ������� ��� ����� ���
            and p.org is null  -- ��� �� ������ ��� ��� � ������ �������
            and k.org=t.id
            and not exists             --� ��� �� ������� ������ � �������� �����������
            (select * from a_nabor2 n where n.lsk=k.lsk and p.mg2 between n.mgFrom and n.mgTo and n.usl=k.usl)
            and p.mg2 < m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
         select
          p.lsk, p.summa, p.usl, t.fk_org2, p.mgchange, p.dtek
           from nabor k, c_change p, t_org t, params m
          where k.lsk = p.lsk
            and k.usl = p.usl
            and k.org=t.id
            and p.org is null  -- ��� �� ������ ��� ��� � ����� �������
            and p.mg2 >= m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
          select
          p.lsk, p.summa, p.usl, nvl(t.fk_org2, 0) as org, p.mgchange, p.dtek
           from kart r, c_change p, t_org t, params m
          where r.lsk = p.lsk
            and p.org=t.id
            and p.org is not null  -- ��� ������ ��� ��� � �� ����� ����� ������
            and to_char(p.dtek, 'YYYYMM') = m.period)
             group by lsk, org, usl, dtek, mgchange
;

