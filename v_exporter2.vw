create or replace force view scott.v_exporter2 as
select k.reu, k.lsk, s.name as street, ltrim(k.nd, '0') as nd, ltrim(k.kw, '0') as kw, k.fio,
k.opl, k.status
from kart k, spul s where k.kul=s.id;

