create or replace procedure scott.script_make_sal is
cursor d  is
select s.c_lsk_id, s.lsk, s.uslm, r.usl as usl_no, s.org, b.usl, s.summa as sal,
 round(s.summa*decode(a.summa, 0, 1, null, 1, round(b.summa/a.summa,2)),2) as salgood,
 decode(a.summa, 0, 1, null, 1, round(b.summa/a.summa,2)) as proc
 from
  saldo s, (select uslm, usl from usl m where m.usl_norm=0) r,
(select t.lsk, u.uslm, sum(summa) as summa from c_charge t, usl u
 where t.type=0 and t.usl=u.usl
group by t.lsk, u.uslm) a,
(select t.lsk, t.usl, u.uslm, sum(summa) as summa from c_charge t, usl u
 where t.type=0 and t.usl=u.usl
group by t.lsk, t.usl, u.uslm) b
  where s.mg='200806' and s.lsk=a.lsk(+) and s.uslm=a.uslm(+) and
  s.lsk=b.lsk(+) and s.uslm=b.uslm(+) and s.uslm=r.uslm
  order by s.lsk, s.uslm, s.org;
  rec_ d%rowtype;
  lsk_old_ kart.lsk%type;
  usl_old_ usl.usl%type;
  uslm_old_ usl.usl%type;
  sal_ number;
  summa_ost_ number;
  org_old_ number;
  c_lsk_id_old_ number;
  mg_ char(6);
begin
 execute immediate 'truncate table saldo_usl';
  --скрипт для распределение сальдо по подуслугам
 lsk_old_:='';
 usl_old_:='';
 uslm_old_:='';
 org_old_:=0;
 c_lsk_id_old_:=0;
 sal_:=0;
 mg_:='000000';
open d;
loop
  fetch d into rec_;
  exit when d%notfound;
  if rec_.lsk <> lsk_old_ then
   sal_:=rec_.sal;
  end if;

  if rec_.lsk = lsk_old_ and rec_.uslm = uslm_old_ and rec_.org <> org_old_ then
   sal_:=rec_.sal;
  end if;
  if rec_.lsk = lsk_old_ and rec_.uslm <> uslm_old_ then
   sal_:=rec_.sal;
  end if;

  if rec_.lsk <> lsk_old_ and summa_ost_ <> 0 then
  --остаток со старого л.с.
   insert into saldo_usl (c_lsk_id, lsk, usl, org, summa, mg)
    values (c_lsk_id_old_, lsk_old_, usl_old_, org_old_, summa_ost_, mg_);
    summa_ost_:=0;
  end if;

  if rec_.lsk = lsk_old_ and rec_.uslm = uslm_old_
     and rec_.org <> org_old_ and summa_ost_ <> 0 then
   --остаток со старой орг.
   insert into saldo_usl (c_lsk_id, lsk, usl, org, summa, mg)
    values (c_lsk_id_old_, lsk_old_, usl_old_, org_old_, summa_ost_, mg_);
    summa_ost_:=0;
  end if;

  if rec_.lsk = lsk_old_ and rec_.uslm <> uslm_old_
     and summa_ost_ <> 0 then
   --остаток со старой орг.
   insert into saldo_usl (c_lsk_id, lsk, usl, org, summa, mg)
    values (c_lsk_id_old_, lsk_old_, usl_old_, org_old_, summa_ost_, mg_);
    summa_ost_:=0;
  end if;

  if rec_.usl is not null then
   insert into saldo_usl (c_lsk_id, lsk, usl, org, summa, mg)
    values (rec_.c_lsk_id, rec_.lsk, rec_.usl, rec_.org, rec_.salgood, mg_);
   sal_:=sal_-rec_.salgood;
   usl_old_:=rec_.usl;
  else
   --не найдено тек начисление для распределения сальдо (кинем на усл. по соцнорме)
   insert into saldo_usl (c_lsk_id, lsk, usl, org, summa, mg)
    values (rec_.c_lsk_id, rec_.lsk, rec_.usl_no, rec_.org, rec_.salgood, mg_);
   sal_:=sal_-rec_.salgood;
   usl_old_:=rec_.usl_no;
  end if;

 summa_ost_:=sal_;
 uslm_old_:=rec_.uslm;
 lsk_old_:=rec_.lsk;
 org_old_:=rec_.org;
 c_lsk_id_old_:=rec_.c_lsk_id;
end loop;
close d;
commit;
mg_:='200806';
insert into saldo_usl (c_lsk_id, lsk, usl, org, summa, mg)
  select c_lsk_id, lsk, usl, org, sum(summa), mg_ from saldo_usl s
   where mg='000000'
   group by c_lsk_id, lsk, usl, org
   having sum(summa) <> 0;
delete from saldo_usl where mg='000000';
commit;
end script_make_sal;
/

