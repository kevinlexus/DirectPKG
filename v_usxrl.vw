create or replace force view scott.v_usxrl as
select u.id as user_id, u.cd, u.name, o.cd as role_cd, o.name as role_name
from t_user u, t_usxrl r, t_role o
where u.id=r.fk_user and r.fk_role=o.id;

