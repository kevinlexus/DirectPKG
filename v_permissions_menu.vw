create or replace force view scott.v_permissions_menu as
select t."USERNAME", t."REU", t."TREST", t."TYPE", t."MENU_ID", t."USER_ID",
       t."ROLE_ID", t."R_DOC_FUNCT_ID", m.name, m.name1
  from permissions t, t_user u, menu m
 where t.type in (2)
   and t.user_id=u.id and u.cd='BUGH1'
   and t.menu_id = m.id
   order by m.id;

