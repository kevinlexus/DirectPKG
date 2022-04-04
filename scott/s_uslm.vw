create or replace force view scott.s_uslm as
select distinct uslm as usl, nm1
    from usl
    order by nm1;

