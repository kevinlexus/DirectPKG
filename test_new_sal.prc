CREATE OR REPLACE PROCEDURE SCOTT.test_new_sal IS
mg_ char(6);
mg1_ char(6);
begin
    select period into mg_ from params;
    mg1_ := TO_CHAR(ADD_MONTHS(TO_DATE(mg_ || '01', 'YYYYMMDD'), 1),
                    'YYYYMM');
    --Добавляем во временную таблицу
    EXECUTE IMMEDIATE 'TRUNCATE TABLE t_c_lsk_id_saldo';
    insert into t_c_lsk_id_saldo
      (c_lsk_id, org, uslm)
      select distinct k.c_lsk_id,
                      a.org,
                      a.uslm
        from (select a.lsk, a.org, a.uslm
                from saldo a, v_params v
               where a.mg = v.period1
              union all
              select e.lsk, e.org, e.uslm
                from t_charges_for_saldo e
              union all
              select e.lsk, e.org, e.uslm
                from t_changes_for_saldo e
              union all
              select e.lsk, e.org, e.uslm
                from t_subsidii_for_saldo e
              union all
              select e.lsk, e.org, e.uslm
                from t_payment_for_saldo e
              union all
              select e.lsk, e.org, e.uslm
                from t_privs_for_saldo e
              union all
              select e.lsk, e.org, e.uslm from t_penya_for_saldo e) a,
              kart k
              where k.lsk=a.lsk;
    commit;

    delete from xitog2_lsk t where t.mg=mg_;
    insert into xitog2_lsk
      (c_lsk_id,
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
      SELECT t.c_lsk_id,
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
        FROM t_c_lsk_id_saldo t,
             (select t.c_lsk_id, t.org, t.uslm, sum(summa) as summa
               from saldo t
              where summa >= 0
                and mg = mg_
              group by t.c_lsk_id, t.org, t.uslm) a,
             (select t.c_lsk_id, t.org, t.uslm, sum(summa) as summa
               from saldo t
              where summa < 0
                and mg = mg_
              group by t.c_lsk_id, t.org, t.uslm) b,
             (select t.c_lsk_id, t.org, t.uslm, sum(summa) as summa
               from saldo t
              where summa >= 0
                and mg = mg1_
              group by t.c_lsk_id, t.org, t.uslm) k,
             (select t.c_lsk_id, t.org, t.uslm, sum(summa) as summa
               from saldo t
              where summa < 0
                and mg = mg1_
              group by t.c_lsk_id, t.org, t.uslm) l,
             (select k.c_lsk_id,
                    t.org,
                    t.uslm,
                    sum(summa) as summa
               from t_charges_for_saldo t, kart k
              where k.lsk = t.lsk
              group by k.c_lsk_id, t.org, t.uslm) e,
             (select k.c_lsk_id,
                    t.org,
                    t.uslm,
                    sum(summa) as summa
               from t_privs_for_saldo t, kart k
              where k.lsk = t.lsk
              group by k.c_lsk_id, t.org, t.uslm) o,
             (select k.c_lsk_id,
                    t.org,
                    t.uslm,
                    sum(summa) as summa
               from t_changes_for_saldo t, kart k
              where k.lsk = t.lsk and t.type in (0)
              group by k.c_lsk_id, t.org, t.uslm) f,
             (select k.c_lsk_id,
                    t.org,
                    t.uslm,
                    sum(summa) as summa
               from t_changes_for_saldo t, kart k
              where k.lsk = t.lsk and t.type in (1,2)
              group by k.c_lsk_id, t.org, t.uslm) w,
             (select k.c_lsk_id,
                    t.org,
                    t.uslm,
                    sum(summa) as summa
               from t_subsidii_for_saldo t, kart k
              where k.lsk = t.lsk
              group by k.c_lsk_id, t.org, t.uslm) g,
             (select k.c_lsk_id,
                    t.org,
                    t.uslm,
                    sum(summa) as summa
               from t_payment_for_saldo t, kart k
              where k.lsk = t.lsk
              group by k.c_lsk_id, t.org, t.uslm) h,
             (select k.c_lsk_id,
                    t.org,
                    t.uslm,
                    sum(summa) as summa
               from t_penya_for_saldo t, kart k
              where k.lsk = t.lsk
              group by k.c_lsk_id, t.org, t.uslm) j
       WHERE t.c_lsk_id = a.c_lsk_id(+)
         AND t.ORG = a.ORG(+)
         AND t.USLM = a.USLM(+)

         and t.c_lsk_id = b.c_lsk_id(+)
         AND t.ORG = b.ORG(+)
         AND t.USLM = b.USLM(+)

         and t.c_lsk_id = k.c_lsk_id(+)
         AND t.ORG = k.ORG(+)
         AND t.USLM = k.USLM(+)

         and t.c_lsk_id = l.c_lsk_id(+)
         AND t.ORG = l.ORG(+)
         AND t.USLM = l.USLM(+)

         and t.c_lsk_id = e.c_lsk_id(+)
         AND t.ORG = e.ORG(+)
         AND t.USLM = e.USLM(+)

         and t.c_lsk_id = o.c_lsk_id(+)
         AND t.ORG = o.ORG(+)
         AND t.USLM = o.USLM(+)

         and t.c_lsk_id = f.c_lsk_id(+)
         AND t.ORG = f.ORG(+)
         AND t.USLM = f.USLM(+)

         and t.c_lsk_id = w.c_lsk_id(+)
         AND t.ORG = w.ORG(+)
         AND t.USLM = w.USLM(+)

         and t.c_lsk_id = g.c_lsk_id(+)
         AND t.ORG = g.ORG(+)
         AND t.USLM = g.USLM(+)

         and t.c_lsk_id = h.c_lsk_id(+)
         AND t.ORG = h.ORG(+)
         AND t.USLM = h.USLM(+)

         and t.c_lsk_id = j.c_lsk_id(+)
         AND t.ORG = j.ORG(+)
         AND t.USLM = j.USLM(+)
       GROUP BY t.c_lsk_id, t.ORG, t.USLM;

  -- выбираем уникальные c_lsk_id + орг. + усл. для формирования отчетности по сальдо
  delete from t_c_lsk_id_saldo2;
  insert into t_c_lsk_id_saldo2
      (c_lsk_id, org, uslm)
      select distinct c_lsk_id, org, uslm from xitog2_lsk t;
  commit;
END test_new_sal;
/

