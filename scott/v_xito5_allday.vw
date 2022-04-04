CREATE OR REPLACE FORCE VIEW SCOTT.V_XITO5_ALLDAY AS
(



SELECT g.ska,g.pn,g.trest,g.reu,g.other,g.nal,g.ink,g.oper,g.md,g.nkom,g.nink FROM
(
SELECT t.lsk,  summa ska, 0 pn,  s.trest, SUBSTR(t.nkom,1,3) reu, SUBSTR(o.oigu,1,1) other ,
          DECODE(o.tpl,'5',1,0) nal, SUBSTR(o.oigu,2,1) ink, t.oper, t.dat_ink as md, t.nkom, t.nink
     FROM kwtp_day t, t_org s, oper o, c_comps c
     WHERE t.oper=o.oper AND t.priznak=1
     and t.nkom=c.nkom and c.fk_org=s.id
     and t.dat_ink between init.get_dt_start and init.get_dt_end
) g
UNION ALL
SELECT g.ska,g.pn,g.trest,g.reu,g.other,g.nal,g.ink,g.oper,g.md,g.nkom,g.nink FROM
(
SELECT t.lsk,  0 ska, summa pn,  s.trest, SUBSTR(t.nkom,1,3) reu, SUBSTR(o.oigu,1,1) other ,
          DECODE(o.tpl,'5',1,0) nal, SUBSTR(o.oigu,2,1) ink, t.oper, t.dat_ink as md, t.nkom, t.nink
     FROM kwtp_day t, t_org s, oper o, c_comps c
     WHERE t.oper=o.oper AND t.priznak=0
     and t.nkom=c.nkom and c.fk_org=s.id
     and t.dat_ink between init.get_dt_start and init.get_dt_end
) g


);

