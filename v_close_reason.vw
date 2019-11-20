create or replace force view scott.v_close_reason as
select t.id, t2.s1 as name
  from EXS.U_LIST t
  join EXS.U_LIST t2
    on t2.parent_id = t.id
 where t2.name = 'Причина закрытия лицевого счета';

