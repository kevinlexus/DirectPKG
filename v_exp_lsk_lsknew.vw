create or replace force view scott.v_exp_lsk_lsknew as
select k.lsk, k1.lsk as lsknew,
k.reu, k.kul, s.name, ltrim(k.nd,'0') as nd, ltrim(k.kw,'0') as kw, k.fio
 from kart k, kart k1, spul s
where k.k_lsk_id=k1.k_lsk_id and k.psch=8
and k.lsk <> k1.lsk and k.kul=s.id;

