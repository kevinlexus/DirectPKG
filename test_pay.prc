CREATE OR REPLACE PROCEDURE SCOTT."TEST_PAY" IS
  id_ number;
begin
init.set_nkom('020');
id_:=init.set_date(trunc(sysdate));
--select c_kwtp_id.nextval into id_ from dual;
for c in (select * from a_kwtp t where t.nkom='020' and t.nink=842
 and mg='200909')
loop
insert into c_kwtp
  (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, id, iscorrect)
select lsk, -1*summa, -1*penya, oper, dopl, nink, nkom, trunc(sysdate),
 nkvit, trunc(sysdate), sysdate, c_kwtp_id.nextval, 1
 from a_kwtp t where t.nkom='020' and t.nink=842
and mg='200909' and t.id=c.id;
insert into c_kwtp_mg
  (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit,
   dat_ink, ts, c_kwtp_id, rasp_id, cnt_sch, cnt_sch0)
select lsk, -1*summa, -1*penya, oper, dopl, nink, nkom, trunc(sysdate), nkvit,
  trunc(sysdate), sysdate, c_kwtp_id.currval, rasp_id, cnt_sch, cnt_sch0
 from a_kwtp_mg t where t.nkom='020' and t.nink=842
and mg='200909' and t.c_kwtp_id=c.id;

c_get_pay.get_payment(c.lsk, c.summa, c.penya, c.oper, c.dopl, 1, null ,
 1);

end loop;

commit;
end test_pay;
/

