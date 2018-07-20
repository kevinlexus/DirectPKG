create or replace force view scott.v_month as
select 1 as id, 'Январь' as month from dual
union all
select 2 as id, 'Февраль' as month from dual
union all
select 3 as id, 'Март' as month from dual
union all
select 4 as id, 'Апрель' as month from dual
union all
select 5 as id, 'Май' as month from dual
union all
select 6 as id, 'Июнь' as month from dual
union all
select 7 as id, 'Июль' as month from dual
union all
select 8 as id, 'Август' as month from dual
union all
select 9 as id, 'Сентябрь' as month from dual
union all
select 10 as id, 'Октябрь' as month from dual
union all
select 11 as id, 'Ноябрь' as month from dual
union all
select 12 as id, 'Декабрь' as month from dual;

