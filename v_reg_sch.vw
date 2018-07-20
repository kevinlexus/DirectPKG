create or replace force view scott.v_reg_sch as
select t.dt1, case
when lead(t.dt1, 1) over (order by t.lsk, t.fk_meter, t.dt1) is null
  then to_date('01.01.2900','DD.MM.YYYY')
when nvl(lead(t.lsk, 1) over (order by t.lsk, t.fk_meter, t.dt1), 'xxxxxxxx') <> t.lsk or
     nvl(lead(t.fk_meter, 1) over (order by t.lsk, t.fk_meter, t.dt1), -1) <> t.fk_meter then to_date('01.01.2900','DD.MM.YYYY')
  else lead(t.dt1, 1) over (order by t.lsk, t.fk_meter, t.dt1)-1 end as dt2,
t.fk_state, t.fk_tp, t.lsk, t.fk_meter, t.dtf, t.fk_user from SCOTT.C_reg_SCH t
where t.fk_meter is not null;

