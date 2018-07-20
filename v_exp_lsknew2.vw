create or replace force view scott.v_exp_lsknew2 as
select k.lsk,
k.reu, k.kul, s.name, ltrim(k.nd,'0') as nd, ltrim(k.kw,'0') as kw, k.fio
 from kart k, spul s
where k.kul=s.id and k.psch not in (8,9);

