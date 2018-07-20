create or replace force view scott.v_cur_rlxorg as
select a.id from t_org a
connect by prior a.id=a.parent_id
start with a.id=(select v.fk_org from v_cur_usxrl v);

