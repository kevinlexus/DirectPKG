create or replace force view scott.v_permissions_nd as
select distinct t.kul, t.nd, t.reu from kart t, v_permissions_reu v where
     t.reu=v.reu order by t.kul,t.nd;

