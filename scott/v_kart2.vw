create or replace force view scott.v_kart2 as
select k.lsk, k.reu, k.kul, k.nd, k.kw, k.fio, k.fk_tp, k.house_id, k.k_lsk_id, k.psch, k.status, k.parent_lsk, k.fk_klsk_obj, k.kpr, k.kpr_wr, k.kpr_ot, k.mg1, k.mg2 from kart k;

