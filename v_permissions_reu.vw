create or replace force view scott.v_permissions_reu as
select p.fk_reu as reu, s.name_reu
 from t_user u, c_users_perm p, u_list i, s_reu_trest s
      where u.id=p.user_id and u.cd=user and p.fk_reu=s.reu
      and i.id=p.fk_perm_tp and i.cd='доступ к отчётам'

/*select p."USERNAME", p."REU", p."TREST", p."TYPE", p."MENU_ID", p."USER_ID",
       p."ROLE_ID", p."R_DOC_FUNCT_ID", s.name_reu
  from permissions p, s_reu_trest s, t_user c
 where c.cd = 'BUGH1'
   and c.id = p.user_id
   and p.type = 0
   and p.reu = s.reu
 order by p.reu;*/;

