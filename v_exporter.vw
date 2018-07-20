create or replace force view scott.v_exporter as
select lsk,usl,sum(summa) summa
    from c_charge where type=1
    group by lsk,usl
union all
select lsk,usl,sum(summa)*-1 summa
    from c_charge where type=2
    group by lsk,usl
union all
select lsk,usl,sum(summa)*-1 summa
    from c_charge where type=4
    group by lsk,usl
union all
select lsk,usl,sum(summa) summa
    from c_change
    group by lsk,usl;

