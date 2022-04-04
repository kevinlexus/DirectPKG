create or replace force view scott.v_params as
select p.id, p.param, p.message, p.ver, p.mess_hint,
p.period, (select count(*) as cnt from scott.v_messages v
where v.is_read_lamp= 0 and v.can_set_is_read = 1
and v.user_id=uid) as cntmess,
TO_CHAR(ADD_MONTHS( to_date( p.period,'YYYYMM'),1),'YYYYMM') as period1,
TO_CHAR(to_date( p.period,'YYYYMM'),'MM/YYYY') as period2,
TO_CHAR(ADD_MONTHS( to_date( p.period,'YYYYMM'),-1),'YYYYMM') as period3,
CASE WHEN ROUND(sysdate-p.agent_uptime,2) > 0.02 THEN 1 ELSE 0 END
    as agent_uptime, p.agent_uptime as agent_time
from scott.params p;

