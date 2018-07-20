create or replace force view scott.s_reu_trest as
select t.reu, t2.trest, t2.name as name_tr, t.name as name_reu, 0 as var
from t_org t, t_org t2 where (t.reu is not null or t.trest is not null)
and t.parent_id=t2.id;

