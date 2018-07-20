CREATE OR REPLACE FORCE VIEW SCOTT.V_CHECK_INKAS1
(dat_ink, nkom, nink, summa_g, summa)
AS
SELECT r.dat, r.nkom, r.nink, SUM(v.summa) summa_g, SUM(d.summa) summa FROM
(SELECT DISTINCT dat, nkom, nink FROM scott.XITO5 k) r,
(SELECT nkom,dat,nink,SUM(ska) AS summa FROM scott.XITO5 k,OPER
 WHERE k.OPER=OPER.OPER
  AND SUBSTR(OPER.oigu,1,1)='1'
 GROUP BY nkom,dat,nink) v,
(SELECT nkom,dat,nink,SUM(ska) AS summa FROM scott.XITO5 k,scott.OPER
 WHERE k.OPER=OPER.OPER
  AND SUBSTR(OPER.oigu,2,1)='1'
 GROUP BY nkom,dat,nink) d
WHERE r.dat=v.dat(+) AND r.dat=d.dat(+)
AND r.nkom=v.nkom(+) AND r.nkom=d.nkom(+) AND r.nink=v.nink(+) AND r.nink=d.nink(+)
GROUP BY r.dat, r.nkom, r.nink
ORDER BY r.dat;

