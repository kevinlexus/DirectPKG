CREATE OR REPLACE PROCEDURE SCOTT.testX(mg_ IN XITO_LG2.mg%TYPE) IS
    type_otchet  CONSTANT NUMBER := 8; --тип возмещение по льготникам (Ф.8.1.)
    type_otchet2 CONSTANT NUMBER := 11; --тип льготники для статистики (Ф.9.1.)
    type_otchet3  CONSTANT NUMBER := 20; --тип возмещение по льготникам (Ф.7.5.)
  BEGIN

    DELETE FROM XITO_LG3 x WHERE x.mg = mg_;
--    /*+ INDEX (t PRIVS_I) */
    INSERT INTO XITO_LG3
      (reu,
       trest,
       kul,
       nd,
       usl_id,
       lg_id,
       org_id,
       summa,
       cnt_main,
       cnt,
       mg)
      SELECT a.reu,
             a.trest,
             a.kul,
             a.nd,
             a.USL,
             a.lg_id,
             a.ORG,
             SUM(summa),
             SUM(cnt_main),
             SUM(cnt),
             mg_
        FROM (SELECT lsk,
                     reu,
                     trest,
                     kul,
                     nd,
                     USL,
                     lg_id,
                     ORG,
                     nomer,
                     cnt_main,
                     cnt,
                     SUM(summa) AS summa
                FROM (SELECT /*+ RULE */
                       t.lsk,
                       e.reu,
                       s.trest,
                       e.kul,
                       e.nd,
                       t.usl_id AS USL,
                       t.lg_id,
                       CASE
                         WHEN p.period >=
                              SUBSTR(d.dat3, 3, 4) || SUBSTR(d.dat3, 1, 2) THEN
                          d.kod3
                         WHEN p.period >=
                              SUBSTR(d.dat2, 3, 4) || SUBSTR(d.dat2, 1, 2) THEN
                          d.kod2
                         WHEN p.period >=
                              SUBSTR(d.dat, 3, 4) || SUBSTR(d.dat, 1, 2) THEN
                          d.kod1
                         ELSE
                          d.kod
                       END ORG,
                       t.nomer,
                       t.main AS cnt_main,
                       t.summa,
                       1 AS cnt
                        FROM PRIVS       t,
                             KART        e,
                             NABOR       k,
                             S_REU_TREST s,
                             PARAMS      p,
                             SPRORG      d
                       WHERE t.lsk = e.lsk
                         AND e.reu = s.reu
                         AND e.nabor_id = k.id
                         AND t.usl_id = k.USL
                         AND k.ORG = d.kod
                      UNION ALL
                      SELECT t.lsk,
                             s.reu,
                             s.trest,
                             e.kul,
                             e.nd,
                             t.USL,
                             t.lg_id,
                             t.ORG,
                             0 AS nomer,
                             t.main,
                             t.summa,
                             1 AS cnt
                        FROM T_CORRECTS_LG t,
                             KART          e,
                             S_REU_TREST   s,
                             PARAMS        p
                       WHERE e.lsk = t.lsk
                         AND e.reu = s.reu
                         AND t.mg = p.period)
               GROUP BY lsk,
                        reu,
                        trest,
                        kul,
                        nd,
                        USL,
                        lg_id,
                        ORG,
                        nomer,
                        cnt_main,
                        cnt) a
       GROUP BY a.reu, a.trest, a.kul, a.nd, a.USL, a.lg_id, a.ORG;

    DELETE FROM XITO_LG2 x WHERE x.mg = mg_;
    /*+ INDEX (t PRIVS_I) */
    INSERT INTO XITO_LG2
      (reu,
       trest,
       kul,
       nd,
       uslm_id,
       lg_id,
       org_id,
       summa,
       cnt_main,
       cnt,
       mg)
      SELECT a.reu,
             a.trest,
             a.kul,
             a.nd,
             a.USLM,
             a.lg_id,
             a.ORG,
             SUM(summa),
             SUM(cnt_main),
             SUM(cnt),
             mg_
        FROM (SELECT lsk,
                     reu,
                     trest,
                     kul,
                     nd,
                     USLM,
                     lg_id,
                     ORG,
                     nomer,
                     cnt_main,
                     cnt,
                     SUM(summa) AS summa
                FROM (SELECT /*+ RULE */
                       t.lsk,
                       e.reu,
                       s.trest,
                       e.kul,
                       e.nd,
                       u.USLM,
                       t.lg_id,
                       CASE
                         WHEN p.period >=
                              SUBSTR(d.dat3, 3, 4) || SUBSTR(d.dat3, 1, 2) THEN
                          d.kod3
                         WHEN p.period >=
                              SUBSTR(d.dat2, 3, 4) || SUBSTR(d.dat2, 1, 2) THEN
                          d.kod2
                         WHEN p.period >=
                              SUBSTR(d.dat, 3, 4) || SUBSTR(d.dat, 1, 2) THEN
                          d.kod1
                         ELSE
                          d.kod
                       END ORG,
                       t.nomer,
                       t.main AS cnt_main,
                       t.summa,
                       1 AS cnt
                        FROM PRIVS       t,
                             KART        e,
                             NABOR       k,
                             USL         u,
                             S_REU_TREST s,
                             PARAMS      p,
                             SPRORG      d
                       WHERE u.USL = t.usl_id
                         AND t.lsk = e.lsk
                         AND e.reu = s.reu
                         AND e.nabor_id = k.id
                         AND t.usl_id = k.USL
                         AND k.ORG = d.kod
                      UNION ALL
                      SELECT t.lsk,
                             s.reu,
                             s.trest,
                             e.kul,
                             e.nd,
                             u.USLM,
                             t.lg_id,
                             t.ORG,
                             0 AS nomer,
                             t.main,
                             t.summa,
                             1 AS cnt
                        FROM T_CORRECTS_LG t,
                             KART          e,
                             USL           u,
                             S_REU_TREST   s,
                             PARAMS        p
                       WHERE e.lsk = t.lsk
                         AND t.USL = u.USL
                         AND e.reu = s.reu
                         AND t.mg = p.period)
               GROUP BY lsk,
                        reu,
                        trest,
                        kul,
                        nd,
                        USLM,
                        lg_id,
                        ORG,
                        nomer,
                        cnt_main,
                        cnt) a
       GROUP BY a.reu, a.trest, a.kul, a.nd, a.USLM, a.lg_id, a.ORG;

    DELETE FROM XITO_LG1 x WHERE x.mg = mg_;
    INSERT INTO XITO_LG1
      (reu, trest, kul, nd, lg_id, summa, cnt_main, cnt, mg)
      SELECT s.reu,
             s.trest,
             k.kul,
             k.nd,
             x.lg_id,
             SUM(x.summa) AS summa,
             SUM(x.cnt_main) AS cnt_main,
             COUNT(*) AS cnt,
             p.period
        FROM (SELECT lsk,
                     lg_id,
                     nomer,
                     cnt_main AS cnt_main,
                     SUM(summa) AS summa
                FROM (SELECT t.lsk,
                             t.lg_id,
                             t.nomer,
                             t.main AS cnt_main,
                             t.summa
                        FROM PRIVS t
                      UNION ALL
                      SELECT t.lsk, t.lg_id, 0 AS nomer, t.main, t.summa
                        FROM T_CORRECTS_LG t,
                             KART          e,
                             USL           u,
                             S_REU_TREST   s,
                             PARAMS        p
                       WHERE e.lsk = t.lsk
                         AND t.USL = u.USL
                         AND e.reu = s.reu
                         AND t.mg = p.period)
               GROUP BY lsk, lg_id, nomer, cnt_main) x,
             KART k,
             S_REU_TREST s,
             PARAMS p
       WHERE x.lsk = k.lsk
         AND k.reu = s.reu
       GROUP BY s.reu, s.trest, k.kul, k.nd, x.lg_id, p.period;

    DELETE FROM PERIOD_REPORTS p
     WHERE p.id = type_otchet
       AND p.mg = mg_; --обновляем период для отчета
    INSERT INTO PERIOD_REPORTS (id, mg) VALUES (type_otchet, mg_);

    DELETE FROM PERIOD_REPORTS p
     WHERE p.id = type_otchet2
       AND p.mg = mg_; --обновляем период для отчета
    INSERT INTO PERIOD_REPORTS (id, mg) VALUES (type_otchet2, mg_);

    DELETE FROM PERIOD_REPORTS p
     WHERE p.id = type_otchet3
       AND p.mg = mg_; --обновляем период для отчета
    INSERT INTO PERIOD_REPORTS (id, mg) VALUES (type_otchet3, mg_);
    COMMIT;
END testX;
/

