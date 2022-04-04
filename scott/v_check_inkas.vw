create or replace force view scott.v_check_inkas as
select r.dat_ink, r.nkom, r.nink, sum(v.summa) summa_g, sum(d.summa) summa from
(select distinct dat_ink, nkom, nink from kwtp_day k) r,
(select nkom,dat_ink,nink,sum(summa) as summa from kwtp_day k,oper
 where k.oper=oper.oper
 and k.lsk not like '00009999' and substr(oper.oigu,1,1)='1'
 group by nkom,dat_ink,nink) v,
(select nkom,dat_ink,nink,sum(summa) as summa from kwtp_day k,oper
 where k.oper=oper.oper
 and k.lsk not like '00009999' and substr(oper.oigu,2,1)='1'
 group by nkom,dat_ink,nink) d
where r.dat_ink=v.dat_ink(+) and r.dat_ink=d.dat_ink(+)
and r.nkom=v.nkom(+) and r.nkom=d.nkom(+) and r.nink=v.nink(+) and r.nink=d.nink(+)
group by r.dat_ink, r.nkom, r.nink
order by r.dat_ink;

