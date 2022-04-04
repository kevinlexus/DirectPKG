CREATE OR REPLACE FORCE VIEW SCOTT.V_GEN_LG3_C AS
SELECT a.reu,
             a.trest,
             a.kul,
             a.nd,
             a.USL,
             a.lg_id,
             a.ORG,
             SUM(summa) summa,
             0 cnt_main,
             0 cnt,
             period
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
                     period,
                     SUM(summa) AS summa
                FROM (SELECT /*+ ORDERED */
                       t.lsk,
                       e.reu,
                       s.trest,
                       e.kul,
                       e.nd,
                       t.usl_id AS USL,
                       t.lg_id,
                       d.kod as org,
                       t.nomer,
                       t.main AS cnt_main,
                       t.summa,
                       1 AS cnt,
                       p.period
                        FROM PRIVS       t,
                             KART        e,
                             NABOR       k,
                             S_REU_TREST s,
                             PARAMS      p,
                             SPRORG      d
                       WHERE t.lsk = e.lsk
                         AND e.reu = s.reu
                         AND e.lsk = k.lsk
                         AND t.usl_id = k.USL
                         AND k.ORG = d.kod AND t.main IN (2)
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
                             1 AS cnt,
                             p.period
                        FROM T_CORRECTS_LG t,
                             KART          e,
                             S_REU_TREST   s,
                             PARAMS        p
                       WHERE e.lsk = t.lsk
                         AND e.reu = s.reu
                         AND t.mg = p.period AND t.main IN (2))
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
                        cnt,period) a
       GROUP BY a.reu, a.trest, a.kul, a.nd, a.USL, a.lg_id, a.ORG, a.period;

