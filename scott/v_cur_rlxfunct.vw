create or replace force view scott.v_cur_rlxfunct as
select t."ID",t."CD",t."FK_ROLE",t."FK_ROLE2",t."FK_FUNCT",t."V",t."GRANTABLE",t."FK_TYPE",t."FK_TYPE2", v.fk_org from t_rlxfunct t, v_cur_usxrl v
where t.fk_role2=v.fk_role;

