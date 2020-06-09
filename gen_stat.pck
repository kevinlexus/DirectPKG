create or replace package scott.gen_stat is

procedure gen_stat_usl(dat_ in date);

end gen_stat;
/

create or replace package body scott.gen_stat is

procedure gen_stat_usl(dat_ in date) is
  --���������� �� �������
  mg_ params.period%type;
  time_ date;
  l_reu statistics.reu%type;
  l_kul statistics.kul%type;
  l_nd statistics.nd%type;
  l_uslm usl.uslm%type;
 -- l_psch number;
 begin
 time_ := sysdate;
 --��������� ��������� ������� ��� ������� ����� �� kart
 select p.period into mg_ from params p;
    if dat_ is not null then
      delete from statistics_lsk a where a.dat is not null;
      delete from statistics a where a.dat is not null;
    else
      gen.trunc_part('statistics_lsk', mg_);
      gen.trunc_part('statistics', mg_);
    end if;
--��������� ���������� � ������������ �� ������� ������
insert into statistics_lsk
    (lsk, reu, for_reu, kul, nd, kw, usl, kpr, is_empt, kpr_ot, kpr_wr, klsk, cnt, status,
     psch, sch, org, val_group, val_group2, cnt_subs, uch, mg, dat, limit, cena, fk_tp, opl, is_vol, chng_vol)
   select k.lsk, k.reu, a.reu as for_reu, k.kul, k.nd, k.kw, n.usl, a.kpr,
     case when k.parent_lsk is not null then 0 -- �������� ����������� � ��������� ���.�����
          when u.is_iter = 1 and nvl(a.kpr,0)= 0 then 1  --��������!
          when u.is_iter = 1 and nvl(a.kpr,0)<> 0 then 0
          when nvl(u.is_iter,0) = 0 and nvl(k.kpr,0)<> 0 then 0
          else 1 end as is_empt,
       case when k.parent_lsk is not null then 0 else a.kpro end as kpr_ot, -- �������� ����������� � ��������� ���.�����
       case when k.parent_lsk is not null then 0 else a.kprz end as kpr_wr, -- �������� ����������� � ��������� ���.�����
       decode(lag(k.lsk || u.uslm, 1) over(order by k.lsk, u.uslm, nvl(a.kpr,0) desc, nvl(a.cnt,0) desc), k.lsk || u.uslm, null, 1) as klsk,
       a.cnt,
       k.status,
       decode(k.psch, 9, 1, 8, 2, 0) as psch,
        case when nvl(a.cnt,0) <> 0 or n.usl not in ('011','012','015','016','013','014') then nvl(a.sch, -1) -- ���� � ���������� ���� �����, ��� ������ �������, ���� ������ �� �.�. �.�.
             when n.usl in ('011','012') and k.fact_meter_tp in (1,2) or -- � ���������� ��� ������, ����� �� Kart.fact_meter_tp (����������� � Java ����������)
                  n.usl in ('015','016') and k.fact_meter_tp in (1,3) or
                  n.usl in ('013','014') and k.fact_meter_tp in (1,2,3) then 1 -- �������������, ���.23.09.2019
             else 0
                end as sch,
       n.org,
       round(n.koeff, 6) as val_group,
       round(n.norm, 6) as val_group2, null as cnt_subs, c.uch,
       decode(dat_, null, mg_, null) as mg, dat_, n.limit,
       a.cena, k.fk_tp, 
       decode(lag(k.lsk || u.uslm, 1) over(order by k.lsk, u.uslm, nvl(a.kpr,0) desc, nvl(a.cnt,0) desc), k.lsk || u.uslm, null, k.opl) as opl,
       case when nvl(a.cnt,0) <> 0 then '����' else '���' end as is_vol, 
         null as vol
        from arch_kart k
             join a_nabor2 n on k.lsk=n.lsk and mg_ between n.mgFrom and n.mgTo and k.psch not in (8,9) -- ������� ����� ������ �� ����������� ��. ���.05.07.2019
             join a_houses c on k.house_id=c.id and c.mg=mg_
             join usl u on n.usl=u.usl
             left join (select k2.k_lsk_id, max(k2.reu) as reu 
                         from arch_kart k2 join v_lsk_tp tp on k2.fk_tp=tp.id
                         and tp.cd='LSK_TP_MAIN' and k2.mg=mg_ and k2.psch not in (8,9)
                         group by k2.k_lsk_id 
                         ) a on k.k_lsk_id=a.k_lsk_id  -- ������������� ���� ��
             left join (select c.lsk, c.usl, nvl(c.sch,0) as sch,
                        sum(c.kpr) as kpr, sum(c.kprz) as kprz, sum(c.kpro) as kpro, sum(c.test_opl) as cnt,
                        max(c.test_cena) as cena
                        from a_charge2 c
                       where c.type = 1 and mg_ between c.mgFrom and c.mgTo
                       group by c.lsk, c.usl, c.sch) a on n.lsk=a.lsk and n.usl=a.usl
             --join usl u on a.usl=u.usl
      where k.mg=mg_; --����� ������ ���� ������ � ���������. �������
      
--�����������
insert into statistics_lsk
    (lsk, reu, for_reu, kul, nd, kw, usl, kpr, is_empt, kpr_ot, kpr_wr, klsk, cnt, status,
     psch, sch, org, val_group, val_group2, cnt_subs, uch, mg, dat, limit, cena, fk_tp, opl, is_vol, chng_vol)
   select k.lsk, k.reu, a.reu as for_reu, k.kul, k.nd, k.kw, n.usl, null as kpr,
       0 as is_empt,
       null as kpr_ot,
       null as kpr_wr,
       null as klsk,
       null as cnt,
       k.status,
       decode(k.psch, 9, 1, 8, 2, 0) as psch,
       nvl(d.sch, -1) as sch, --������ -1, ��� ��� ������ ���������� � ��������� NULL, ��� "��������" � ���� "���", ���. 07.12.2105
       nvl(d.org, n.org) as org,
       null as val_group,
       round(n.norm, 6) as val_group2, null as cnt_subs, c.uch,
       decode(dat_, null, mg_, null) as mg, dat_, n.limit,
       null as cena, k.fk_tp, 
       null as opl,
       case when nvl(d.vol,0) <> 0 then '����' else '���' end as is_vol, d.vol
        from (select c.lsk, c.usl, c.org, c.mgchange, sum(c.vol) as vol, nvl(c.sch,0) as sch
                        from a_change c
                       where c.mg=mg_
                       group by c.lsk, c.usl, c.org, c.mgchange, nvl(c.sch,0)) d
             left join arch_kart k on d.lsk=k.lsk and k.mg=d.mgchange                                
             left join (select k2.k_lsk_id, max(k2.reu) as reu 
                         from arch_kart k2 join v_lsk_tp tp on k2.fk_tp=tp.id
                         and tp.cd='LSK_TP_MAIN' and k2.mg=mg_ and k2.psch not in (8,9)
                         group by k2.k_lsk_id 
                         ) a on k.k_lsk_id=a.k_lsk_id  -- ������������� ���� ��
             left join a_houses c on c.id=k.house_id and c.mg=d.mgchange
             join usl u on d.usl=u.usl
             left join a_nabor2 n on n.lsk=d.lsk and d.mgchange between n.mgFrom and n.mgTo and n.usl=d.usl;

    if dat_ is not null then
    --�������� ���-�� �������, �����������, ��� ����� �����
    insert into statistics_lsk
      (reu, kul, nd, kw, fio, kpr, is_empt, kpr_ot, kpr_wr, klsk, cnt, status, psch,
       sch, org, val_group, cnt_lg, cnt_subs, uch, mg, dat, cnt_room, fk_tp, opl, is_vol)
      select k.reu, k.kul, k.nd, k.kw, k.fio, k.kpr, null as is_empt, k.kpr_ot, k.kpr_wr,
             1 as klsk, k.opl as cnt, k.status, decode(k.psch,9,1,8,2,0) as psch,
              null as sch, null as org, null as val_group,
             ki as cnt_lg, null as cnt_subs, null as uch, null as mg, dat_ as dat,
             k.komn, k.fk_tp, k.opl, '����' as is_vol
        from arch_kart k where k.mg=mg_;

      insert into statistics
        (reu, for_reu, kul, nd, usl, kpr, is_empt, kpr_ot, kpr_wr, klsk, cnt, cena, status, psch,
         sch, org, val_group, val_group2, cnt_lg, cnt_subs, uch, mg, dat, fk_tp, opl, is_vol, chng_vol)
        select reu, for_reu, kul, nd, usl, sum(kpr), s.is_empt, sum(kpr_ot), sum(kpr_wr),
               sum(klsk), sum(cnt), cena, status, psch, sch, org, val_group, val_group2,
               sum(cnt_lg), sum(cnt_subs), uch, mg, dat, s.fk_tp, sum(s.opl) as opl, s.is_vol, sum(s.chng_vol)
          from statistics_lsk s
         where dat = dat_ and /*s.uslm is null and ���.26.06.13*/ s.usl is not null
         group by reu, for_reu, kul, nd, usl, status, psch, sch, cena, org, val_group, val_group2, uch,
                  mg, dat, s.is_empt, s.fk_tp, s.is_vol;

      --�������� ���-�� �������, �����������
      insert into statistics
        (reu, kul, nd, kpr, is_empt, kpr_ot, kpr_wr, klsk, cnt, status, psch,
         sch, org, val_group, cnt_lg, cnt_subs, uch, mg, dat, cnt_room, fk_tp, opl, is_vol)
        select k.reu, k.kul, k.nd, sum(k.kpr), null as is_empt, sum(k.kpr_ot), sum(k.kpr_wr),
               count(*) as klsk, sum(k.opl) as cnt, k.status, decode(k.psch,9,1,8,2,0) as psch,
                null as sch, null as org, null as val_group,
               sum(ki) as cnt_lg, null as cnt_subs, null as uch, null as mg, dat_ as dat,
               sum(k.komn), k.fk_tp, sum(k.opl) as opl, '����' as is_vol
          from arch_kart k where k.mg=mg_
         group by k.reu, k.kul, k.nd, k.status, decode(k.psch,9,1,8,2,0), dat_, k.fk_tp;

    else
    --�� �����
        insert into statistics_lsk
      (reu, kul, nd, kw, fio, kpr, is_empt, kpr_ot, kpr_wr, klsk, cnt, status, psch,
       sch, org, val_group, cnt_lg, cnt_subs, uch, mg, dat, cnt_room, fk_tp, opl, is_vol)
      select k.reu, k.kul, k.nd, k.kw, k.fio, k.kpr, null as is_empt, k.kpr_ot, k.kpr_wr,
             1 as klsk, k.opl as cnt, k.status, decode(k.psch,9,1,8,2,0) as psch,
              null as sch, null as org, null as val_group,
             ki as cnt_lg, null as cnt_subs, null as uch, mg_ as mg, null as dat,
             k.komn, k.fk_tp, k.opl, '����' as is_vol
        from arch_kart k where k.mg=mg_;

      insert into statistics
        (reu, for_reu, kul, nd, usl, kpr, is_empt, kpr_ot, kpr_wr, klsk, cnt, cena, status, psch,
         sch, org, val_group, val_group2, cnt_lg, cnt_subs, uch, mg, dat, fk_tp, opl, is_vol, chng_vol)
        select reu, for_reu, kul, nd, usl, sum(kpr), s.is_empt, sum(kpr_ot), sum(kpr_wr),
               sum(klsk), sum(cnt), cena, status, psch, sch, org, val_group, val_group2,
               sum(cnt_lg), sum(cnt_subs), uch, mg, dat, s.fk_tp, sum(s.opl) as opl, s.is_vol, sum(chng_vol)
          from statistics_lsk s
         where s.mg = ''||mg_||'' and /*s.uslm is null and ���.26.06.13*/ s.usl is not null
         group by reu, for_reu, kul, nd, usl, status, psch, sch, org, cena, val_group, val_group2, uch,
                  mg, dat, s.is_empt, s.fk_tp, s.is_vol;
      --�������� ���-�� �������, �����������
      insert into statistics
        (reu, kul, nd, kpr, is_empt, kpr_ot, kpr_wr, klsk, cnt, status, psch,
         sch, org, val_group, cnt_lg, cnt_subs, uch, mg, dat, cnt_room, fk_tp, opl, is_vol)
        select k.reu, k.kul, k.nd, sum(k.kpr), null as is_empt, sum(k.kpr_ot), sum(k.kpr_wr),
               count(*) as klsk, sum(k.opl) as cnt, k.status, decode(k.psch,9,1,8,2,0) as psch,
                null as sch, null as org, null as val_group,
               sum(ki) as cnt_lg, null as cnt_subs, null as uch, mg_ as mg, null as dat,
               sum(k.komn), k.fk_tp, sum(k.opl) as opl, '����' as is_vol
          from arch_kart k where k.mg=mg_
         group by k.reu, k.kul, k.nd, k.status, decode(k.psch,9,1,8,2,0), mg_, k.fk_tp;
    end if;

    --��������� �������� ������� ���������� ��� �����������
 if dat_ is not null then
  delete from statistics_trest b where b.dat is not null;
  insert into statistics_trest
    (usl, reu, cnt, cena, klsk, kpr, is_empt, kpr_ot, kpr_wr, org, val_group, val_group2, status, psch,
     sch, cnt_lg, cnt_subs, uch, mg, dat, fk_tp, opl, is_vol, chng_vol)
    select s.usl, s.reu, sum(s.cnt), s.cena, sum(s.klsk), sum(s.kpr), s.is_empt, sum(s.kpr_ot),
           sum(s.kpr_wr), s.org, val_group, val_group2, s.status, s.psch, s.sch,
           sum(s.cnt_lg), sum(s.cnt_subs), s.uch, s.mg, s.dat, s.fk_tp, sum(s.opl) as opl, s.is_vol, sum(s.chng_vol)
      from statistics s
     where s.dat = dat_ /*and s.uslm is null*/ and s.usl is not null
     group by s.reu, s.usl, s.org, s.cena, val_group, val_group2, s.status, s.psch, s.sch, s.uch,
              s.mg, s.dat, s.is_empt, s.fk_tp, s.is_vol;
   --�������� ���-�� �������, �����������
   insert into statistics_trest
        (reu, kpr, is_empt, kpr_ot, kpr_wr, klsk, cnt, status, psch,
         sch, org, val_group, cnt_lg, cnt_subs, uch, mg, dat, cnt_room, fk_tp, opl, is_vol)
        select k.reu, sum(k.kpr), null as is_empt, sum(k.kpr_ot), sum(k.kpr_wr),
               count(*) as klsk, sum(k.opl) as cnt, k.status, decode(k.psch,9,1,8,2,0) as psch,
                null as sch, null as org, null as val_group,
               sum(ki) as cnt_lg, null as cnt_subs, null as uch, null as mg, dat_ as dat,
               sum(k.komn), k.fk_tp, sum(k.opl) as opl, '����' as is_vol
          from arch_kart k where k.mg=mg_
         group by k.reu, k.status, decode(k.psch,9,1,8,2,0), dat_, k.fk_tp;
 else
  delete from statistics_trest b
   where b.mg = mg_;
  insert into statistics_trest
    (usl, reu, cnt, cena, klsk, kpr, is_empt, kpr_ot, kpr_wr, org, val_group, val_group2, status, psch,
     sch, cnt_lg, cnt_subs, uch, mg, dat, fk_tp, opl, is_vol, chng_vol)
    select s.usl, s.reu, sum(s.cnt), s.cena, sum(s.klsk), sum(s.kpr), s.is_empt, sum(s.kpr_ot),
           sum(s.kpr_wr), s.org, val_group, val_group2, s.status, s.psch, s.sch,
           sum(s.cnt_lg), sum(s.cnt_subs), s.uch, s.mg, s.dat, s.fk_tp, sum(s.opl) as opl, s.is_vol, sum(s.chng_vol)
      from statistics s
     where s.mg = ''||mg_||'' and /*s.uslm is null and */s.usl is not null
     group by s.reu, s.usl, s.cena, val_group, val_group2, s.org, s.status, s.psch, s.sch, s.uch,
              s.mg, s.dat, s.is_empt, s.fk_tp, s.is_vol;
   --�������� ���-�� �������, �����������
   insert into statistics_trest
        (reu, kpr, is_empt, kpr_ot, kpr_wr, klsk, cnt, status, psch,
         sch, org, val_group, cnt_lg, cnt_subs, uch, mg, dat, cnt_room, fk_tp, opl, is_vol)
        select k.reu, sum(k.kpr), null as is_empt, sum(k.kpr_ot), sum(k.kpr_wr),
               count(*) as klsk, sum(k.opl) as cnt, k.status, decode(k.psch,9,1,8,2,0) as psch,
                null as sch, null as org, null as val_group,
               sum(ki) as cnt_lg, null as cnt_subs, null as uch, mg_ as mg, null as dat,
               sum(k.komn), k.fk_tp, sum(k.opl) as opl, '����' as is_vol
          from arch_kart k where k.mg=mg_
         group by k.reu, k.status, decode(k.psch,9,1,8,2,0), k.fk_tp;
 end if;


 l_reu:= 'xx';
 l_kul:='xx';
 l_nd:='xx';
 l_uslm:='xx';
 --l_psch:=-1;
 -- ���������� ������������� ������ ������ �� ���� � ������ (����� ��������� �������� � ������)
 for c in (select t.reu,t.kul,t.nd, u.uslm,t.psch,t.rowid as rd from statistics t join usl u
    on t.usl=u.usl 
    where (mg_ is not null and t.mg=mg_ or t.dat=dat_)
                  and t.usl is not null
          order by t.reu,t.kul,t.nd,u.uslm, u.usl_norm, -- ���. 06.03.20 ���������� � �����, ����� ��� ��������� � �������� ������
          case when nvl(t.cnt,0)> 0 then 0 else 1 end, 
          t.status -- ������� ���������� �� �������, ���� �� ����������� (9) � ��������� ������� �������� �������������
          
   ) loop
   
   if not (l_reu = c.reu and l_kul=c.kul and l_nd=c.nd and l_uslm=c.uslm-- and l_psch=c.psch
        ) then
     update statistics t set t.fr=1
              where t.rowid=c.rd;
     l_reu:= c.reu;
     l_kul:=c.kul;
     l_nd:=c.nd;
     l_uslm:=c.uslm;
   --  l_psch:=c.psch;
   end if;
   
 end loop;
 
  if dat_ is null then
    logger.ins_period_rep('13', mg_, null, 0);
    logger.ins_period_rep('18', mg_, null, 0);
    logger.ins_period_rep('57', mg_, null, 0);
    logger.ins_period_rep('83', mg_, null, 0);
    logger.ins_period_rep('97', mg_, null, 0);
  else
    logger.ins_period_rep('13', null, dat_, 0);
    logger.ins_period_rep('18', null, dat_, 0);
    logger.ins_period_rep('57', null, dat_, 0);
    logger.ins_period_rep('83', null, dat_, 0);
  end if;
  commit;
  logger.log_(time_, 'gen_stat_usl ' || to_char(dat_, 'DDMMYYYY'));
end gen_stat_usl;

end gen_stat;
/

