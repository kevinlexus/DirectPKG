CREATE OR REPLACE FORCE VIEW SCOTT.V_XITO5 AS
SELECT SUM(summa) summa,  s.trest, s.reu, SUBSTR(o.oigu,1,1) other ,
          DECODE(o.tpl,'5',1,0) nal, SUBSTR(o.oigu,2,1) ink, t.oper
     FROM kwtp_day t, oper o, kart k,s_reu_trest s
     WHERE t.oper=o.oper AND t.priznak=1
     AND t.lsk =k.lsk and k.reu=s.reu
     and t.dat_ink between init.get_dt_start and init.get_dt_end
     GROUP BY s.trest, s.reu, SUBSTR(o.oigu,1,1), DECODE(o.tpl,'5',1,0),
          SUBSTR(o.oigu,2,1), t.oper;

