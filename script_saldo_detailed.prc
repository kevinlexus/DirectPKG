create or replace procedure scott.script_saldo_detailed is
 mg_ char(6);
 mg1_ char(6);
begin
 mg_:='200803';
 mg1_:='200804';

    execute immediate 'truncate table t_lsk_saldo';
    insert into t_lsk_saldo (lsk, org, uslm)
         select distinct lsk, org, uslm from
         (select t.lsk, t.org, t.uslm
               from saldo t where t.mg=mg_
               union all
          select t.lsk, t.org, t.uslm
               from saldo t where t.mg=mg1_
               union all
         select t.lsk, t.org, u.uslm
               from a_nabor t, usl u
                 where t.usl=u.usl and t.mg=mg_
               union all
         select k.lsk,
                    nvl(t.org,0),
                    u.uslm
               from a_change t, kart k, usl u where t.mg=mg_ and
               t.lsk=k.lsk
               union all
         select t.lsk, 0, '002'
               from a_nabor t, usl u
                 where t.usl=u.usl and t.mg=mg_);
   commit;
    delete from xitog2_lsk t where t.mg=mg_;
    insert into xitog2_lsk
      (lsk,
       ORG,
       USLM,
       indebet,
       inkredit,
       CHARGES,
       CHANGES,
       CH_FULL,
       CHANGES2,
       subsid,
       PRIVS,
       payment,
       pn,
       outdebet,
       outkredit,
       mg)
      SELECT t.lsk,
             t.ORG,
             t.USLM,
             SUM(a.summa) indebet,
             SUM(b.summa) inkredit,
             SUM(NVL(e.summa, 0) + NVL(f.summa, 0)+ NVL(w.summa, 0)- NVL(o.summa, 0)- NVL(g.summa, 0)) CHARGES,
             SUM(NVL(f.summa,0)) CHANGES,
             SUM(NVL(e.summa, 0)) CH_FULL,
             SUM(NVL(w.summa,0)) CHANGES2,
             SUM(g.summa) subsid,
             SUM(o.summa) PRIVS,
             SUM(h.summa) payment,
             SUM(j.summa) pn,
             SUM(k.summa) outdebet,
             SUM(l.summa) outkredit,
             mg_ AS mg
        FROM t_lsk_saldo t,
             (select t.lsk, t.org, t.uslm, sum(summa) as summa
               from saldo t
              where summa >= 0
                and mg = mg_
              group by t.lsk, t.org, t.uslm) a,
             (select t.lsk, t.org, t.uslm, sum(summa) as summa
               from saldo t
              where summa < 0
                and mg = mg_
              group by t.lsk, t.org, t.uslm) b,
             (select t.lsk, t.org, t.uslm, sum(summa) as summa
               from saldo t
              where summa >= 0
                and mg = mg1_
              group by t.lsk, t.org, t.uslm) k,
             (select t.lsk, t.org, t.uslm, sum(summa) as summa
               from saldo t
              where summa < 0
                and mg = mg1_
              group by t.lsk, t.org, t.uslm) l,
             (select k.lsk,
                    n.org,
                    u.uslm,
                    sum(summa) as summa
               from a_nabor n, a_charge t, kart k, usl u
              where n.lsk = t.lsk and k.lsk = t.lsk
                and n.usl=t.usl and t.usl=u.usl and t.usl not in ('024')
                and t.type=1 and n.mg=mg_ and t.mg=mg_
              group by k.lsk, n.org, u.uslm) e,
             (select k.lsk,
                    n.org,
                    u.uslm,
                    sum(summa) as summa
               from a_nabor n, a_charge t, kart k, usl u
              where n.lsk = t.lsk and k.lsk = t.lsk
                and n.usl=t.usl and t.usl=u.usl and t.usl not in ('024')
                and t.type=4 and n.mg=mg_ and t.mg=mg_
              group by k.lsk, n.org, u.uslm) o,
             (select k.lsk,
                    t.org,
                    u.uslm,
                    sum(summa) as summa
               from a_change t, kart k, usl u
              where k.lsk = t.lsk and t.usl=u.usl
                and t.type in (0) and t.mg=mg_
              group by k.lsk, t.org, u.uslm) f,
             (select k.lsk,
                    t.org,
                    u.uslm,
                    sum(summa) as summa
               from a_change t, kart k, usl u
              where k.lsk = t.lsk and t.usl=u.usl
                and t.type in (1,2) and t.mg=mg_
              group by k.lsk, t.org, u.uslm) w,
             (select k.lsk,
                    n.org,
                    u.uslm,
                    sum(summa) as summa
               from a_nabor n, a_charge t, kart k, usl u
              where n.lsk = t.lsk and k.lsk = t.lsk
                and n.usl=t.usl and t.usl=u.usl
                and t.type=2 and n.mg=mg_ and t.mg=mg_
              group by k.lsk, n.org, u.uslm) g,
             (select k.lsk,
                    0 as org,
                    '002' as uslm,
                    sum(summa) as summa
               from a_kwtp_mg t, kart k
              where k.lsk = t.lsk and t.mg=mg_
              group by k.lsk) h,
             (select k.lsk,
                    0 as org,
                    '002' as uslm,
                    sum(penya) as summa
               from a_kwtp_mg t, kart k
              where k.lsk = t.lsk and t.mg=mg_
              group by k.lsk) j
       WHERE t.lsk = a.lsk(+)
         AND t.ORG = a.ORG(+)
         AND t.USLM = a.USLM(+)

         and t.lsk = b.lsk(+)
         AND t.ORG = b.ORG(+)
         AND t.USLM = b.USLM(+)

         and t.lsk = k.lsk(+)
         AND t.ORG = k.ORG(+)
         AND t.USLM = k.USLM(+)

         and t.lsk = l.lsk(+)
         AND t.ORG = l.ORG(+)
         AND t.USLM = l.USLM(+)

         and t.lsk = e.lsk(+)
         AND t.ORG = e.ORG(+)
         AND t.USLM = e.USLM(+)

         and t.lsk = o.lsk(+)
         AND t.ORG = o.ORG(+)
         AND t.USLM = o.USLM(+)

         and t.lsk = f.lsk(+)
         AND t.ORG = f.ORG(+)
         AND t.USLM = f.USLM(+)

         and t.lsk = w.lsk(+)
         AND t.ORG = w.ORG(+)
         AND t.USLM = w.USLM(+)

         and t.lsk = g.lsk(+)
         AND t.ORG = g.ORG(+)
         AND t.USLM = g.USLM(+)

         and t.lsk = h.lsk(+)
         AND t.ORG = h.ORG(+)
         AND t.USLM = h.USLM(+)

         and t.lsk = j.lsk(+)
         AND t.ORG = j.ORG(+)
         AND t.USLM = j.USLM(+)
       GROUP BY t.lsk, t.ORG, t.USLM;

  execute immediate 'truncate table t_lsk_saldo2';
  insert into t_lsk_saldo2
      (lsk, org, uslm)
      select distinct lsk, org, uslm from xitog2_lsk t;
  commit;
end script_saldo_detailed;
/

