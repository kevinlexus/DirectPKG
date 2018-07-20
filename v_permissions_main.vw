create or replace force view scott.v_permissions_main as
select p."USERNAME", p."REU", p."TREST", p."TYPE", p."MENU_ID", p."USER_ID",
       p."ROLE_ID", p."R_DOC_FUNCT_ID"
  from permissions p, t_user u
 where p.user_id=u.id and u.cd='BUGH1'
   and p.type = 4;

