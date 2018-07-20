create or replace force view scott.v_exp_kart as
select k.reu, k.lsk, k.kul, s.name, ltrim(k.nd,'0') as nd, ltrim(k.kw,'0') as kw, k.fio from kart k, spul s
where k.kul=s.id and k.psch <> 8
order by k.kul, s.name, k.nd, k.kw;

