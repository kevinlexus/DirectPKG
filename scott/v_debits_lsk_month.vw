create or replace force view scott.v_debits_lsk_month as
select lsk, reu, kul, name, nd, kw, fio, status, opl, cnt_month, dolg, nachisl, penya, v.mg,
 v.payment
from debits_lsk_month v
 where exists
(select * from scott.list_choices_reu l where l.reu=v.reu and l.sel=0);

