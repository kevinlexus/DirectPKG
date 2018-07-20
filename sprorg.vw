create or replace force view scott.sprorg as
select null as type, id as kod, t.name, t.npp, t.grp
 from t_org t;

