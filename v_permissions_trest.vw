create or replace force view scott.v_permissions_trest as
select distinct p."USERNAME", p."REU", p."TREST", p."TYPE", p."MENU_ID",
                p."USER_ID", p."ROLE_ID", p."R_DOC_FUNCT_ID",
                s.name as name_tr
  from permissions p, t_org s, t_user c
 where c.cd = 'BUGH1'
   and c.id = p.user_id
   and p.trest = s.trest
   and p.type = 1
 order by p.trest;

