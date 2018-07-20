create or replace force view scott.v_house_pars as
select u."ID",u."CD",u."NAME",u."NM",u."FK_LISTTP",u."NPP",u."VAL_TP",u."FK_UNIT" from u_list u, u_listtp tp
where tp.cd='house_params'
and u.fk_listtp=tp.id;

