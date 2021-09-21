CREATE OR REPLACE PACKAGE BODY SCOTT.C_EXP_LIST IS

PROCEDURE privs_export is
 type_otchet CONSTANT NUMBER := 54; --тип отчета (архивы)
 cursor c_usl is
  select t.usl, t.lpw from usl t
   where t.lpw is not null;
  rec_usl_ c_usl%rowtype;
  period_ params.period%type;
  sqlstr_ varchar2(32000);
begin

-- нет льготников - не используется! ред. 31.07.2017
return;
--Выполнять строго после формирования архивов
--обратный парсер для списка льготников
time_ := SYSDATE;

/*begin
 execute immediate 'drop table expprivs';
 exception when others then
 null;
end;
sqlstr_:=' create table expprivs (lsk char(8), id number, adr char(50), fio char(50), doc char(55),
 main number, spk_id number, ';
open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;
  sqlstr_:=sqlstr_||rec_usl_.lpw||' number (8,2),';
end loop;
close c_usl;
sqlstr_:=sqlstr_||' itog number, var number, mg char(6)) tablespace data';
execute immediate sqlstr_;
*/
--delete from expprivs e where e.mg = (select period from params);

select period into period_ from params;
gen.trunc_part('expprivs', period_);

open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;

  begin
    execute immediate 'alter table expprivs add '||rec_usl_.lpw||' number(8,2)';
  exception when others then
    null; --да да null
  end;

  execute immediate 'insert into expprivs (lsk, id, reu, kul, nd, kw, opl, status, adr, fio, main, spk_id, doc, '||rec_usl_.lpw||', mg)
   select /*+RULE */ a.lsk, c.id, k.reu, k.kul, k.nd, k.kw, k.opl, k.status, s.name||'',''||LTRIM(k.nd,''0'')||''-''||LTRIM(k.kw,''0''), c.fio, a.main, a.spk_id, d.doc, a.summa,
   p.period from
  kart k, nabor b, spul s,
  (select t.lsk, t.usl, t.kart_pr_id, t.spk_id, t.main, t.lg_doc_id, sum(summa) as summa
   from c_charge t where t.type=4 and t.usl=:usl
  group by t.lsk, t.usl, t.kart_pr_id, t.spk_id, t.main, t.lg_doc_id ) a,
  c_kart_pr c, c_lg_docs d, params p
  where k.lsk = b.lsk and b.lsk=a.lsk and k.kul=s.id and b.usl=a.usl
  and a.lg_doc_id=d.id
  and a.kart_pr_id=c.id and a.summa <>0'
  using rec_usl_.usl;
end loop;
close c_usl;

sqlstr_:=' insert into expprivs (lsk, id, reu, kul, nd, kw, opl, status, adr, fio, main, spk_id, doc, ';

open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;
  sqlstr_:=sqlstr_||trim(rec_usl_.lpw)||', ';
end loop;
close c_usl;
sqlstr_:=sqlstr_||' itog, var, mg)';

sqlstr_:=sqlstr_||' select t.lsk, t.id, t.reu, t.kul, t.nd, t.kw, t.opl, t.status, t.adr, t.fio, t.main, t.spk_id, t.doc,  ';
open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;
  sqlstr_:=sqlstr_||'sum(t.'||trim(rec_usl_.lpw)||')'||', ';
end loop;
close c_usl;
sqlstr_:=sqlstr_||' sum(';
open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;
  sqlstr_:=sqlstr_||'nvl(t.'||trim(rec_usl_.lpw)||',0)'||'+ ';
end loop;
close c_usl;
sqlstr_:=sqlstr_||'0) as itog, 1 as var, t.mg  from expprivs t, params p
 where t.mg=p.period
 group by t.lsk, t.id, t.reu, t.kul, t.nd, t.kw, t.opl, t.status, t.adr, t.fio, t.main, t.spk_id, t.doc, t.mg ';
execute immediate sqlstr_;

delete from expprivs t where t.var is null;

--обновляем период для отчета
delete from period_reports p
 where p.id in (type_otchet)
    and p.mg in (select s.period from params s);
insert into period_reports
 (id, mg, signed)
 select type_otchet, p.period, 1 from params p;
 logger.log_(time_, 'c_exp_list.privs_export');
commit;
end;

PROCEDURE changes_export is
 type_otchet CONSTANT NUMBER := 53; --тип отчета (архивы)
 cursor c_usl is
  select t.usl, t.kwni as fname from usl t
   where t.kwni is not null;
  rec_usl_ c_usl%rowtype;

  sqlstr_ varchar2(32000);
begin
--ред. 27.03.19: Алёна, здравствуйте! Скажите как часто выполняете пункт Служебные отчеты (списки) -> Списки по начислению  (expkartw.dbf)
--Алена 6:35
--Здравствуйте Л.Н.! даже уже не помню, когда последний раз пользовались. Может год назад.
--6:36
--выключу этот пункт? он съедает много ресурсов. если понадобится- включить без проблем
return;
--Выполнять строго после формирования архивов
time_ := SYSDATE;

--обратный парсер для скидок

--сперва для отчета
delete from expkwniusl e where e.mg = (select period from params);

insert into expkwniusl
  (reu, house_id, kul, adr, summa, usl, opl, mg)
select k.reu, k.house_id, k.kul, s.name||','||LTRIM(k.nd,'0') as adr, sum(t.summa) as summa,
   t.usl, max(c.opl), p.period
   from kart k, c_change t, spul s, params p, c_houses c where
   k.lsk=t.lsk and k.kul=s.id and k.house_id=c.id and t.proc <> 0
   and to_char(t.dtek , 'YYYYMM')=p.period
   group by k.reu, k.house_id, k.kul, s.name||','||LTRIM(k.nd,'0'), t.usl, p.period;

delete from expkwni e where e.mg = (select period from params);

--затем для DBF
open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;

  begin
    execute immediate 'alter table expkwni add '||rec_usl_.fname||' number(8,2)';
  exception when others then
    null; --да да null
  end;

  execute immediate 'insert into expkwni (reu, house_id, kul, name, nd, '||rec_usl_.fname||', var, mg)
  select k.reu, k.house_id, k.kul, s.name, ltrim(k.nd, ''0'') as nd, sum(t.summa) as summa,
   null as var, p.period
   from kart k, c_change t, spul s, params p where
   k.lsk=t.lsk and k.kul=s.id and t.usl=:usl and t.proc <> 0
   and to_char(t.dtek , ''YYYYMM'')=p.period
   group by k.reu, k.house_id, k.kul, s.name, k.nd, t.usl, p.period'
  using rec_usl_.usl;

end loop;
close c_usl;

sqlstr_:=' insert into expkwni (reu, house_id, kul, name, nd, ';

open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;
  sqlstr_:=sqlstr_||trim(rec_usl_.fname)||', ';
end loop;
close c_usl;
sqlstr_:=sqlstr_||' itog, var, mg)';

sqlstr_:=sqlstr_||' select reu, house_id, kul, name, nd, ';
open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;
  sqlstr_:=sqlstr_||'sum(t.'||trim(rec_usl_.fname)||')'||', ';
end loop;
close c_usl;
sqlstr_:=sqlstr_||' sum(';
open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;
  sqlstr_:=sqlstr_||'nvl(t.'||trim(rec_usl_.fname)||',0)'||'+ ';
end loop;
close c_usl;
sqlstr_:=sqlstr_||'0) as itog, 1 as var, mg from expkwni t, params p
 where t.mg=p.period
 group by reu, house_id, kul, name, nd, mg ';
execute immediate sqlstr_;

sqlstr_:=' insert into expkwni (reu, house_id, kul, name, nd, opl, ';

open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;
  sqlstr_:=sqlstr_||trim(rec_usl_.fname)||', ';
end loop;
close c_usl;
sqlstr_:=sqlstr_||' itog, var, mg)';

sqlstr_:=sqlstr_||' select e.reu, e.house_id, e.kul, e.name, e.nd, a.opl, ';
open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;
  sqlstr_:=sqlstr_||'e.'||trim(rec_usl_.fname)||''||', ';
end loop;
close c_usl;
sqlstr_:=sqlstr_||' e.itog, 2 as var, e.mg from expkwni e,
(select k.house_id, sum(k.opl) as opl
 from kart k, spul s where
 k.kul=s.id
 and exists ( select * from c_change t where t.lsk=k.lsk  and t.proc <> 0)
group by k.house_id) a
where e.house_id=a.house_id and e.var = 1';
execute immediate sqlstr_;

delete from expkwni t where t.var is null;
delete from expkwni t where t.var = 1;

--обновляем период для отчета
delete from period_reports p
 where p.id in (type_otchet)
    and p.mg in (select s.period from params s);
insert into period_reports
 (id, mg, signed)
 select type_otchet, p.period, 1 from params p;
 logger.log_(time_, 'c_exp_list.changes_export');
commit;
end;

PROCEDURE charges_export is
 cursor c_usl is
  select t.usl, t.kartw as fname from usl t
   where t.kartw is not null and t.usl <>'024';
  rec_usl_ c_usl%rowtype;
  time_ date;
  sqlstr_ varchar2(32000);
  period_ params.period%type;
begin
--ред. 27.03.19: Алёна, здравствуйте! Скажите как часто выполняете пункт Служебные отчеты (списки) -> Списки по начислению  (expkartw.dbf)
--Алена 6:35
--Здравствуйте Л.Н.! даже уже не помню, когда последний раз пользовались. Может год назад.
--6:36
--выключу этот пункт? он съедает много ресурсов. если понадобится- включить без проблем
return;

  time_:=sysdate;
--Выполнять строго после формирования архивов
select period into period_ from params;
gen.trunc_part('expkartw', period_);

open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;

  begin
    execute immediate 'alter table expkartw add '||rec_usl_.fname||' number(8,2)';
  exception when others then
    null; --да да null
  end;


  execute immediate 'insert into expkartw (reu, lsk, kpr, adr, '||rec_usl_.fname||', mg, var)
  select  k.reu, k.lsk, k.kpr, s.name||'',''||LTRIM(k.nd,''0'')||''-''||LTRIM(k.kw,''0''), nvl(a.summa,0)+nvl(d.summa,0) as summa,
     :mg_, null as var from arch_kart k
     left join arch_charges a on k.lsk=a.lsk and k.mg=a.mg and a.usl_id=:usl and a.mg=:mg_
     left join arch_subsidii d on k.lsk=d.lsk and k.mg=d.mg and d.usl_id=:usl and d.mg=:mg_
     join spul s on k.kul=s.id
     where k.mg=:mg_'
  using period_, rec_usl_.usl, period_, rec_usl_.usl, period_, period_;


/*  execute immediate 'insert into expkartw (reu, lsk, kpr, adr, '||rec_usl_.fname||', mg, var)
   select \*+RULE *\ k.reu, k.lsk, k.kpr, s.name||'',''||LTRIM(k.nd,''0'')||''-''||LTRIM(k.kw,''0''), nvl(a.summa,0)+nvl(d.summa,0) as summa,
   :mg_, null as var from arch_kart k, arch_charges a, arch_subsidii d, spul s
   where k.lsk=a.lsk(+) and k.mg=a.mg(+) and a.usl_id(+)=:usl and k.lsk=d.lsk(+) and k.mg=d.mg(+)
   and d.usl_id(+)=:usl and k.kul=s.id and k.mg=:mg_'
  using period_, rec_usl_.usl, rec_usl_.usl, period_;*/

end loop;
close c_usl;

sqlstr_:=' insert into expkartw (reu, lsk, kpr, adr, ';

open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;
  sqlstr_:=sqlstr_||trim(rec_usl_.fname)||', ';
end loop;
close c_usl;
sqlstr_:=sqlstr_||' itog, mg, var)';

sqlstr_:=sqlstr_||' select reu, lsk, kpr, adr, ';
open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;
  sqlstr_:=sqlstr_||'sum(t.'||trim(rec_usl_.fname)||')'||', ';
end loop;
close c_usl;
sqlstr_:=sqlstr_||' sum(';
open c_usl;
loop
  fetch c_usl into rec_usl_;
  exit when c_usl%notfound;
  sqlstr_:=sqlstr_||'nvl(t.'||trim(rec_usl_.fname)||',0)'||'+ ';
end loop;
close c_usl;
sqlstr_:=sqlstr_||'0) as itog, mg, 1 as var from expkartw t, params p
 where t.var is null
 and t.mg=p.period
 group by reu, lsk, kpr, adr, mg
 order by reu, lsk';
execute immediate sqlstr_;
commit;
logger.log_(time_, 'c_exp_list.charges_export');
end;
END C_EXP_LIST;
/

