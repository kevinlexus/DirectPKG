create or replace package body scott.gen_stat2 is
-- ����� ��� ����������� ����� �� � 2018-07 �������, ����� �������!
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
 select '201807' into mg_ from params p;
    if dat_ is not null then
      --delete from statistics_lsk a where a.dat is not null;
      delete from statistics a where a.dat is not null;
    else
--      gen.trunc_part('statistics_lsk', mg_);
      gen.trunc_part('statistics', mg_);
    end if;
    if dat_ is not null then
    --�������� ���-�� �������, �����������, ��� ����� �����
      insert into statistics
        (reu, kul, nd, usl, kpr, is_empt, kpr_ot, kpr_wr, klsk, cnt, cena, status, psch,
         sch, org, val_group, val_group2, cnt_lg, cnt_subs, uch, mg, dat, fk_tp, opl, is_vol, chng_vol)
        select reu, kul, nd, usl, sum(kpr), s.is_empt, sum(kpr_ot), sum(kpr_wr),
               sum(klsk), sum(cnt), cena, status, psch, sch, org, val_group, val_group2,
               sum(cnt_lg), sum(cnt_subs), uch, mg, dat, s.fk_tp, sum(s.opl) as opl, s.is_vol, sum(s.chng_vol)
          from statistics_lsk s
         where dat = dat_ and /*s.uslm is null and ���.26.06.13*/ s.usl is not null
         group by reu, kul, nd, usl, status, psch, sch, cena, org, val_group, val_group2, uch,
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
      insert into statistics
        (reu, kul, nd, usl, kpr, is_empt, kpr_ot, kpr_wr, klsk, cnt, cena, status, psch,
         sch, org, val_group, val_group2, cnt_lg, cnt_subs, uch, mg, dat, fk_tp, opl, is_vol, chng_vol)
        select reu, kul, nd, usl, sum(kpr), s.is_empt, sum(kpr_ot), sum(kpr_wr),
               sum(klsk), sum(cnt), cena, status, psch, sch, org, val_group, val_group2,
               sum(cnt_lg), sum(cnt_subs), uch, mg, dat, s.fk_tp, sum(s.opl) as opl, s.is_vol, sum(chng_vol)
          from statistics_lsk s
         where s.mg = ''||mg_||'' and /*s.uslm is null and ���.26.06.13*/ s.usl is not null
         group by reu, kul, nd, usl, status, psch, sch, org, cena, val_group, val_group2, uch,
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
          order by t.reu,t.kul,t.nd,u.uslm, case when nvl(t.cnt,0)> 0 then 0 else 1 end, u.usl_norm
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
  else
    logger.ins_period_rep('13', null, dat_, 0);
    logger.ins_period_rep('18', null, dat_, 0);
    logger.ins_period_rep('57', null, dat_, 0);
    logger.ins_period_rep('83', null, dat_, 0);
  end if;
  commit;
  logger.log_(time_, 'gen_stat_usl ' || to_char(dat_, 'DDMMYYYY'));
end gen_stat_usl;

end gen_stat2;
/

