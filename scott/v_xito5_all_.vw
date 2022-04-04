CREATE OR REPLACE FORCE VIEW SCOTT.V_XITO5_ALL_ AS
(SELECT g.ska,g.pn,g.trest,g.reu,g.from_reu,g.other,g.nal,g.ink,g.oper FROM
(

SELECT t.lsk,  summa ska, 0 pn,  s.trest, s.reu, SUBSTR(nkom,1,2) from_reu, SUBSTR(o.oigu,1,1) other ,
          DECODE(o.tpl,'5',1,0) nal, SUBSTR(o.oigu,2,1) ink, t.oper
     FROM kwtp_day t, kart k, s_reu_trest s, oper o
     WHERE t.oper=o.oper AND t.priznak=1
     AND t.lsk =k.lsk and k.reu=s.reu
     and t.dat_ink between init.get_dt_start and init.get_dt_end
UNION ALL
SELECT t.lsk,  summa ska, 0 pn,  s.trest, SUBSTR(nkom,1,2) reu, SUBSTR(nkom,1,2) from_reu, SUBSTR(o.oigu,1,1) other ,
          DECODE(o.tpl,'5',1,0) nal, SUBSTR(o.oigu,2,1) ink, t.oper
     FROM kwtp_day t, s_reu_trest s, oper o
     WHERE t.oper=o.oper AND t.priznak=1
     AND t.lsk LIKE '×%' AND s.reu=SUBSTR(nkom,1,2)
     and t.dat_ink between init.get_dt_start and init.get_dt_end
) g
UNION ALL
SELECT g.ska,g.pn,g.trest,g.reu,g.from_reu,g.other,g.nal,g.ink,g.oper FROM
(

SELECT t.lsk,  0 ska, summa pn,  s.trest, s.reu, SUBSTR(nkom,1,2) from_reu, SUBSTR(o.oigu,1,1) other ,
          DECODE(o.tpl,'5',1,0) nal, SUBSTR(o.oigu,2,1) ink, t.oper
     FROM kwtp_day t, kart k, s_reu_trest s, oper o
     WHERE t.oper=o.oper AND t.priznak=0
     AND t.lsk =k.lsk and k.reu=s.reu
     and t.dat_ink between init.get_dt_start and init.get_dt_end
UNION ALL
SELECT t.lsk,  0 ska, summa pn,  s.trest, SUBSTR(nkom,1,2) reu, SUBSTR(nkom,1,2) from_reu, SUBSTR(o.oigu,1,1) other ,
          DECODE(o.tpl,'5',1,0) nal, SUBSTR(o.oigu,2,1) ink, t.oper
     FROM kwtp_day t, s_reu_trest s, oper o
     WHERE t.oper=o.oper AND t.priznak=0
     AND t.lsk LIKE '×%' AND s.reu=SUBSTR(nkom,1,2)
     and t.dat_ink between init.get_dt_start and init.get_dt_end
) g
);

