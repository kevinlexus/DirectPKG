create or replace force view scott.v_lsk_tp as
select u.id, u.cd, u.name, u.npp from u_list u, u_listtp d
  where u.fk_listtp=d.id
    and d.cd='“ипы лиц.счета';

