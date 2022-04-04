create or replace force view scott.v_cu_rlxac as
select x."ID",x."CD",x."FK_ROLE",x."FK_OBJ",x."FK_ACT",x."V",x."GRANTABLE",x."FK_OBJT",x."FK_DOCTP" from v_cu_usxrl t, t_rlxac x
where t.fk_role=x.fk_role;

