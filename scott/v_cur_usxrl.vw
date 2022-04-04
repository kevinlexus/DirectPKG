create or replace force view scott.v_cur_usxrl as
select r."ID",r."CD",r."FK_ORG",r."FK_USER",r."FK_ROLE",r."V",r."GRANTABLE",r."FK_ORGT",r."TYPE",r."MENU_ID", o.name as role_name from t_user u, t_usxrl r, t_role o where u.cd=user
and u.id=r.fk_user and r.fk_role=o.id;

