create or replace procedure scott.script_corrsal_pay is
 oper_ oper.oper%type;
 dopl_ c_kwtp.dopl%type;
 nkom_ c_kwtp.nkom%type;
begin
--скрипт переброски кредитового сальдо,
--созданного не верной оплатой по капремонту
oper_:='01';
dopl_:='200809';
nkom_:='999';

for c in (select k.lsk, sum(summa) as summa, c.nink, c.nkom
  from saldo_usl s, kart k, c_comps c
 where k.lsk = s.lsk
   and k.reu = '17'
   and k.kul = '0108'
   and k.nd = '0020/2'
   and s.mg = '200901'
   and s.usl in ('033', '034')
   and c.nkom=nkom_
  group by k.lsk, c.nink, c.nkom
  having sum(summa) <> 0)
loop

--проводим в оплате
insert into c_kwtp
  (lsk, summa, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, id, iscorrect)
 values
  (c.lsk, c.summa*-1, oper_, dopl_, c.nink, c.nkom, trunc(sysdate),
    (select nkvit from c_comps c where c.nkom=nkom_), trunc(sysdate), sysdate, c_kwtp_id.nextval, 0);
insert into c_kwtp_mg
  (lsk, summa, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, c_kwtp_id)
 values
  (c.lsk, c.summa*-1, oper_, dopl_, c.nink, c.nkom, trunc(sysdate),
    (select nkvit from c_comps c where c.nkom=nkom_), trunc(sysdate), sysdate, c_kwtp_id.currval);
 update c_comps c set c.nkvit=nvl(c.nkvit,0)+1 where c.nkom=nkom_;
end loop;
 update c_comps c set c.nink=nvl(c.nink,0)+1 where c.nkom=nkom_;

 delete from t_corrects_payments t where t.mg=(select period from params);

--проводим в корректировках
insert into t_corrects_payments
  (lsk, usl, org, summa, user_id, dat, dopl, mg)
  select k.lsk, s.usl, s.org, sum(summa) as summa, 10, trunc(sysdate), dopl_, p.period
  from saldo_usl s, kart k, params p
 where k.lsk = s.lsk
   and k.reu = '17'
   and k.kul = '0108'
   and k.nd = '0020/2'
   and s.mg = '200901'
   and s.usl in ('033', '034')
 group by k.lsk, s.usl, s.org, p.period
having sum(summa) <> 0;
 commit;

end script_corrsal_pay;
/

