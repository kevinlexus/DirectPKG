create or replace package body scott.C_DIST_PAY is

procedure gen_deb_usl_all is
begin
--������������ ����������� �������� ������
--�� ����� �����
for c in (select * from kart k)
loop

 gen_deb_usl(c.lsk,0 );
 commit;

end loop;

end;

procedure gen_deb_usl(l_lsk in kart.lsk%type, l_commit in number) is
l_dt_start date;
l_dt_end date;
l_mg1 params.period%type;
l_mg params.period%type;
l_overpay number;
begin
--����� ����������� c_deb_usl, ...���������� ������ ��� ��������� ����������� (������ �� ��� �������������� ������...������ �� xitog3_lsk)
--������������ ����������� �������� ������
--������ ���� ������
select to_date(p.period||'01','YYYYMMDD'),
   p.period
   into l_dt_start, l_mg
   from params p;
--��������� ���� ������
l_dt_end:=last_day(l_dt_start);
-- -1 ����� �����
l_mg1:= to_char(add_months(to_date(l_mg || '01', 'YYYYMMDD'), -1),
               'YYYYMM');

delete from c_deb_usl t where t.period=l_mg and t.lsk=l_lsk;
insert into c_deb_usl
 (lsk, usl, org, summa, mg, period)
 select a.lsk, a.usl, a.org, sum(a.summa) as summa,
  a.mg, a.period from (
 select t.lsk, t.usl, t.org, t.summa, t.mg as mg, l_mg as period
   from c_deb_usl t --����������� �� �������� �������
  where t.period=l_mg1 and t.lsk=l_lsk
 union all
 select t.lsk, t.usl, n.org, t.summa, l_mg as mg, l_mg as period
   from c_charge t, nabor n --����������
  where t.lsk = n.lsk
    and t.usl=n.usl
    and t.type = 1 and t.lsk=l_lsk
 union all
 --����������� - ������
 select /*+ INDEX (k A_NABOR2_I)*/ p.lsk, p.usl, t.fk_org2 as org, p.summa, p.mgchange, l_mg
   from a_nabor2 k, c_change p, t_org t, params m
  where k.lsk = p.lsk
    and p.mgchange between k.mgFrom and k.mgTo
    and k.usl = p.usl
    and k.org = t.id and k.lsk=l_lsk
    and p.org is null -- ��� �� ������ ��� ��� � ������ �������
    and exists --� ��� ������� ������ � �������� �����������
  (select /*+ INDEX (n A_NABOR2_I)*/*
           from a_nabor2 n
          where n.lsk = k.lsk
            and p.mgchange between n.mgFrom and n.mgTo
            and n.usl = k.usl)
    and p.mgchange < m.period
    and p.dtek between l_dt_start and l_dt_end
 union all
 select p.lsk, p.usl, t.fk_org2, p.summa, p.mgchange, l_mg
   from nabor k, c_change p, t_org t, params m
  where k.lsk = p.lsk
    and k.usl = p.usl --�� ������ ���� ������, ��� ��� �� ������� ��� ����� ���
    and p.org is null -- ��� �� ������ ��� ��� � ������ �������
    and k.org = t.id and k.lsk=l_lsk
    and not exists --� ��� �� ������� ������ � �������� �����������
  (select /*+ INDEX (n A_NABOR2_I)*/*
           from a_nabor2 n
          where n.lsk = k.lsk
            and p.mgchange between n.mgFrom and n.mgTo
            and n.usl = k.usl
            and n.lsk=l_lsk)
    and p.mgchange < m.period
    and p.dtek between l_dt_start and l_dt_end
 union all
 select p.lsk, p.usl, t.fk_org2, p.summa, p.mgchange, l_mg
   from nabor k, c_change p, t_org t, params m
  where k.lsk = p.lsk
    and k.usl = p.usl
    and k.org = t.id
    and p.org is null -- ��� �� ������ ��� ��� � ����� �������
    and p.mgchange >= m.period
    and p.dtek between l_dt_start and l_dt_end
    and k.lsk=l_lsk
 union all
 select p.lsk, p.usl, nvl(t.fk_org2, 0) as org, p.summa, p.mgchange, l_mg
   from kart r, c_change p, t_org t, params m
  where r.lsk = p.lsk
    and p.org = t.id
    and p.org is not null -- ��� ������ ��� ��� � �� ����� ����� ������
    and p.dtek between l_dt_start and l_dt_end
    and r.lsk=l_lsk
 --����������� - ���������
/* union all
 select t.lsk, t.usl, t.org, -1 * t.summa, t.dopl as mg, l_mg --������������� ������
   from t_corrects_payments t, params p --������ ����� - ��� � KWTP_DAY �����!!!
  where t.mg = l_mg
    and t.lsk=l_lsk*/
 union all
 select t.lsk, t.usl, t.org, -1 * t.summa, t.dopl as mg, l_mg
   from kwtp_day t where t.priznak = 1 --���� ������
                         and t.lsk=l_lsk
                         and nvl(t.fk_distr,0) <> 12 --����� �� ����� ������������� �� ���������������
                                              --��� c_deb_usl
                         and t.dtek between init.g_dt_start and init.g_dt_end

 ) a
 group by a.lsk, a.usl, a.org, a.mg, a.period
 having sum(a.summa)<>0;

 -- ������� ��������� �� ��������� ������� ���.20.02.2018 �� ������� �����
 transfer_overpay(l_lsk);

 if l_commit =1 then
   commit;
 end if;
end;

-- ������� ��������� �� ��������� ������� ���.20.02.2018 �� ������� �����
procedure transfer_overpay(p_lsk in kart.lsk%type) is 
  l_dt_start date;
  l_dt_end date;
  l_mg1 params.period%type;
  l_mg params.period%type;
  l_overpay number;
begin
 -- ��������� ��� ��, ���, ���
 for c in (select distinct t.lsk, t.usl, t.org from c_deb_usl t, params p where t.period=p.period
            and nvl(p_lsk, t.lsk)=t.lsk) loop
   l_overpay:=0;    
   -- ��������� ��� ������� �� ������� ���, ���     
   for c2 in (select t.summa, t.mg, lead(t.lsk,1) over (order by t.mg) as is_last, t.rowid from c_deb_usl t, params p 
                     where t.period=p.period and t.lsk=c.lsk and t.usl=c.usl and t.org=c.org
                     and nvl(t.summa,0) <> 0
                     order by t.mg
                     ) loop
   if c2.summa+l_overpay <= 0 and c2.is_last is not null then 
     -- ������� ���������, ���������, ���� ������ �� ���������
     l_overpay:=c2.summa+l_overpay;
     -- ������� ���� ����������� �� ������� �������
       delete from c_deb_usl t where t.rowid=c2.rowid;
   else 
     -- �������� ����� �����������
     if c2.summa+l_overpay <> c2.summa then
       update c_deb_usl t set t.summa = c2.summa+l_overpay 
         where t.rowid=c2.rowid;
     end if;  
     l_overpay:=0;
   end if; 
   
   
   end loop;
            
 end loop;

end;

procedure dist_pay_all is
l_rec c_kwtp_mg%rowtype;
begin
  --������������� ���� �� �������������� ��������
for c in (select k.reu, t.*, t.rowid as rw from c_kwtp_mg t, kart k where/*t.lsk='06002298'
  and */ t.lsk=k.lsk
  and not exists (select * from kwtp_day k where k.kwtp_id=t.id
     and k.dtek between init.g_dt_start and init.g_dt_end)
  )
loop

 select t.lsk, t.summa, t.penya, t.oper, t.dopl, t.nink, t.nkom, t.dtek, t.nkvit, t.dat_ink, t.ts, t.c_kwtp_id, t.cnt_sch, t.cnt_sch0, t.id, null
  into l_rec from c_kwtp_mg t where t.id=c.id
  and t.rowid=c.rw
  and t.dtek between init.g_dt_start and init.g_dt_end;
 --������������ ������
 dist_pay_deb_mg_lsk(c.reu, l_rec);
end loop;
commit;

end;

-- �������� ��������� ������������� ������ �� �������
procedure dist_pay_deb_mg_lsk(p_reu in kart.reu%type, p_rec in c_kwtp_mg%rowtype) is
l_mg params.period%type;
l_in_summa number;
l_summa number;
l_summa_p number;
l_cnt number;
l_summa_tmp number;
l_summa_old number;
l_summap_old number;
l_summa_err number;
l_flag number;
l_flagp number;
l_trgt_usl usl.usl%type;
l_trgt_org number;
l_dist number;
i number;
t_redir tab_redir;
t_summ  tab_summ;
l_err number;
l_sign number;
l_cnt2 number;

function dist(p_mg in varchar2, p_summa in number,
  p_tp in number, p_distr in number,
  p_kwtp_mg_id in number --id ������� (��� ������������� ���� �� ��� �������������� �������)
  ) return number is
begin
  l_in_summa:=abs(p_summa);
  l_sign:=sign(p_summa);
  --������������ ������(����) �� �������+��� � �������
  delete from temp_prep t;
  if p_kwtp_mg_id is null then --���� ��� �������������� ������� (���� ����� ������, ���� ����, � 0 ������ ������)
    if p_distr = 6 then
    --�� ���������� �������
      select nvl(count(*),0) into l_cnt
                from xitog3_lsk t
                where
                t.lsk=p_rec.lsk
                and t.mg=p_mg
                and t.charges > 0;
    elsif p_distr = 7 then
    --�� �������� ����������
      select nvl(count(*),0) into l_cnt
      from (select n.usl, n.org
          from c_charge t, nabor n
          where t.lsk=p_rec.lsk
          and t.lsk=n.lsk
          and t.usl=n.usl
          and t.type=1
        group by n.usl, n.org
        having sum(t.summa) > 0); --������ �� ���������� > 0
    elsif p_distr in (14,15,18) then
    --�� ��� ������ - �� ���������!
      l_cnt:=1;
    end if;
    --��������� ������� ����� ��� �������������
    if l_cnt = 0 then
      return 0;
    end if;

  if p_distr = 6 then
  --�� ���������� �������
    if utils.get_int_param('RESTRICT_WITH_CHNG') = 0 then
      select rec_summ(b.usl, b.org, b.summa, 0) bulk collect --����� �������� - �������� � �����
          into t_summ
          from (
          select a.usl, a.org, sum(a.summa) as summa from   
            (select t.usl, t.org, t.charges as summa from  
                xitog3_lsk t
              where t.mg = p_mg
              and t.lsk=p_rec.lsk
              and t.charges > 0--������ �� ���������� > 0
            ) a
            group by a.usl, a.org) b;
    elsif utils.get_int_param('RESTRICT_WITH_CHNG') = 1 then --������� ��� ����� � � ���! ��� 02.10.2016
      select rec_summ(b.usl, b.org, b.summa, 0) bulk collect --����� �������� - �������� � �����
          into t_summ
          from (
          select a.usl, a.org, sum(a.summa) as summa from   
            (select t.usl, t.org, t.charges as summa from  
                xitog3_lsk t
              where t.mg = p_mg
              and t.lsk=p_rec.lsk
            union all
            select t.usl, t.org, t.summa from  
                (
         select /*+ INDEX (k A_NABOR2_I)*/
          p.lsk, p.summa, p.usl, t.fk_org2 as org, p.mgchange
           from a_nabor2 k, c_change p, t_org t, params m
          where k.lsk = p.lsk
            and p.mg2 between k.mgFrom and k.mgTo
            and k.usl = p.usl
            and k.org=t.id
            and k.lsk=p_rec.lsk
            and p.org is null  -- ��� �� ������ ��� ��� � ������ �������
            and exists             --� ��� ������� ������ � �������� �����������
            (select /*+ INDEX (n A_NABOR2_I)*/* from a_nabor2 n where n.lsk=k.lsk and p.mg2 between n.mgFrom and n.mgTo and n.usl=k.usl)
            and p.mg2 < m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
          select
          p.lsk, p.summa, p.usl, t.fk_org2, p.mgchange
           from nabor k, c_change p, t_org t, params m
          where k.lsk = p.lsk
            and k.lsk=p_rec.lsk
            and k.usl = p.usl  --�� ������ ���� ������, ��� ��� �� ������� ��� ����� ���
            and p.org is null  -- ��� �� ������ ��� ��� � ������ �������
            and k.org=t.id
            and not exists             --� ��� �� ������� ������ � �������� �����������
            (select /*+ INDEX (n A_NABOR2_I)*/* from a_nabor2 n where n.lsk=k.lsk and p.mg2 between n.mgFrom and n.mgTo and n.usl=k.usl)
            and p.mg2 < m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
         select
          p.lsk, p.summa, p.usl, t.fk_org2, p.mgchange
           from nabor k, c_change p, t_org t, params m
          where k.lsk = p.lsk
            and k.lsk=p_rec.lsk
            and k.usl = p.usl
            and k.org=t.id
            and p.org is null  -- ��� �� ������ ��� ��� � ����� �������
            and p.mg2 >= m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
          select
          p.lsk, p.summa, p.usl, nvl(t.fk_org2, 0) as org, p.mgchange
           from kart r, c_change p, t_org t, params m
          where r.lsk = p.lsk
            and r.lsk=p_rec.lsk
            and p.org=t.id
            and p.org is not null  -- ��� ������ ��� ��� � �� ����� ����� ������
            and to_char(p.dtek, 'YYYYMM') = m.period

) t -- �������� ����������� ��� �����, ����� ������ �����. � ������ ����� ��������!
              where t.mgchange = p_mg
              and t.lsk=p_rec.lsk
            ) a
            group by a.usl, a.org
            having sum(summa) > 0--������ �� ����������+����������� > 0
            ) b;
    end if;
    if sql%rowcount =0 then
      --��� �������, ���������
      return 0;
    end if;
  elsif p_distr in (7, 16) then
  --�� �������� ���������� (�� ��� ������, ��� ������� ��������)
    select rec_summ(n.usl, o.fk_org2, sum(t.summa), 0) bulk collect --����� �������� - �������� � �����
          into t_summ
        from c_charge t, nabor n, t_org o
        where t.lsk=p_rec.lsk and n.org=o.id
        and t.lsk=n.lsk
        and t.usl=n.usl
        and t.type=1
      group by n.usl, o.fk_org2
      having sum(t.summa) > 0; --������ �� ���������� > 0
    if sql%rowcount =0 then
      --��� �������, ���������
      return 0;
    end if;
  elsif p_distr in (14) then
    --�� ��� ������, � ������ �������� ������, � ��������������, ������������ �� ����� ����� ���������� ������
    select rec_summ(d.usl, d.org, sum(d.summa), 0) bulk collect
          into t_summ from
            (select t.usl, t.org, nvl(t.indebet,0)+nvl(t.inkredit,0) as summa
              from xitog3_lsk t, params p --����� �������� ������
              where t.lsk=p_rec.lsk
              and t.mg=p.period
            union all
            select n.usl, o.fk_org2 as org, t.summa --����� �������� - �������� � �����
              from c_charge t, nabor n, t_org o  --��������� ������� ����������
              where t.lsk=p_rec.lsk and n.org=o.id
              and t.lsk=n.lsk
              and t.usl=n.usl
              and t.type=1
            union all
            select t.usl, t.org, -1*t.summa
              from kwtp_day t  --������ ��� �������� ������
              where t.lsk=p_rec.lsk
              and t.priznak=1
             ) d
             group by d.usl, d.org
             having  sum(summa ) > 0;
    if sql%rowcount =0 then
      --��� �������, ���������
      return 0;
    end if;
  elsif p_distr in (15) then
    --�� ��� ������, � ������ �������� ������, �� ��� ���������������� ��������
    select rec_summ(d.usl, d.org, sum(d.summa), 0) bulk collect
          into t_summ from
            (select t.usl, t.org, nvl(t.indebet,0)+nvl(t.inkredit,0) as summa
              from xitog3_lsk t, params p --����� �������� ������
              where t.lsk=p_rec.lsk
              and t.mg=p.period
            union all
            select n.usl, o.fk_org2 as org, t.summa --����� �������� - �������� � �����
              from c_charge t, nabor n, t_org o  --��������� ������� ����������
              where t.lsk=p_rec.lsk and n.org=o.id
              and t.lsk=n.lsk
              and t.usl=n.usl
              and t.type=1
            union all
            select t.usl, t.org, -1*t.summa
              from kwtp_day t  --������ ��� �������� ������
              where t.lsk=p_rec.lsk
              and t.priznak=1
             ) d
             group by d.usl, d.org
             having  sum(summa ) > 0;
    if sql%rowcount =0 then
      --��� �������, ���������
      return 0;
    end if;
  elsif p_distr in (17) then
    --�� ��� ������, ��� ����� �������� ������, � ��� ���������������� ��������
    select rec_summ(d.usl, d.org, sum(d.summa), 0) bulk collect
          into t_summ from
            (select t.usl, t.org, nvl(t.indebet,0)+nvl(t.inkredit,0) as summa
              from xitog3_lsk t, params p --����� �������� ������
              where t.lsk=p_rec.lsk
              and t.mg=p.period
            union all
            select n.usl, o.fk_org2 as org, t.summa --����� �������� - �������� � �����
              from c_charge t, nabor n, t_org o  --��������� ������� ����������
              where t.lsk=p_rec.lsk and n.org=o.id
              and t.lsk=n.lsk
              and t.usl=n.usl
              and t.type=1
             ) d
             group by d.usl, d.org
             having  sum(summa ) > 0;
    if sql%rowcount =0 then
      --��� �������, ���������
      return 0;
    end if;
  elsif p_distr in (18) then
    --�� ��� ������, �� ������ �������� ����� � ��� (����� ����������� ������)
    select rec_summ(d.usl, d.org, sum(d.summa), 0) bulk collect
          into t_summ from
            (select t.usl, t.org, nvl(t.indebet,0) as summa
              from xitog3_lsk t, kart k, params p --����� �������� ��� ������
              where t.lsk=p_rec.lsk and t.lsk=k.lsk
              and t.mg=p.period
              and exists 
              (select * from spr_proc_pay r where 
                 decode(r.reu, '**', k.reu, r.reu)=k.reu -- ���� ��� **, ���� ��������� ��
                 and r.usl=t.usl and r.org=t.org
                 and p_mg between r.mg1 and r.mg2)
             ) d
             group by d.usl, d.org
             having  sum(summa ) > 0;
    if sql%rowcount =0 then
      --��� �������, ���������
      return 0;
    end if;
  end if;
  
  else
    --����������� ��� ������������� ���� �� ��� ������������ �������
    select rec_summ(t.usl, t.org, sum(t.summa), 0) bulk collect
      into t_summ from
       kwtp_day t  --��� �������������� ������
      where t.priznak=1
      and t.kwtp_id=p_kwtp_mg_id
      group by t.usl, t.org
      having nvl(sum(t.summa),0)<>0;
    if sql%rowcount =0 then
      --��� �������, ���������
      return 0;
    end if;
  end if;

--  insert into temp_prep
--    (usl, org, summa, tp_cd)
--  values
--    ('xxx', 0, -1*p_summa, 0); --����� ��� �������������, � �������� ������
  --����������
  --c_prep.dist_summa;

    l_err := c_prep.dist_summa_full(p_sum  => l_in_summa,
                             t_summ => t_summ);

   insert into temp_prep
    (usl, org, summa, tp_cd)
   select t.fk_cd, t.fk_id, t.summa, 3 as tp_cd
   from table(t_summ) t
         where t.tp = 1;
  --�������� �������������, ���� ������ ����������� �� ������ (��������! � ��� ������� �������� ������ �������� ���� �� 01.01.2016!!!)
  if p_kwtp_mg_id is null then
  if utils.get_int_param('RESTRICT_BY_SAL') = 1 and -- ����� 1 � ���
     utils.get_int_param('RESTRICT_WITH_CHNG') = 0 and -- ����� 0 � ���
     p_distr not in (15,16,17) then
      --��� ������������
      insert into temp_prep  --�������� 20.04.15 � 15:08
        (usl, org, summa, tp_cd)
       with a as (select t.usl, t.org, sum(t.summa) as summa from temp_prep t
                   where t.summa<>0 and t.tp_cd in (3)
                   group by t.usl, t.org),
            b as (select d.usl, d.org, sum(d.summa) as summa from
            (select t.usl, t.org, nvl(t.indebet,0)+nvl(t.inkredit,0) as summa
              from xitog3_lsk t, params p --����� �������� ������
              where t.lsk=p_rec.lsk
              and t.mg=p.period
            union all
            select n.usl, o.fk_org2 as org, t.summa
              from c_charge t, nabor n, t_org o  --��������� ������� ����������
              where t.lsk=p_rec.lsk and n.org=o.id
              and t.lsk=n.lsk
              and t.usl=n.usl
              and t.type=1
            union all
            select t.usl, t.org, -1*t.summa
              from kwtp_day t  --������ ��� �������� ������
              where t.lsk=p_rec.lsk
              and t.priznak=1
             ) d
             group by d.usl, d.org
             having  sum(summa) > 0) --����� ������ ���.��������� ������
        select a.usl, a.org, nvl(b.summa,0)-nvl(a.summa,0) as diff, 4 as tp_cd from a
              left join b on a.usl=b.usl and a.org=b.org
              where nvl(b.summa,0)-nvl(a.summa,0) <0; --��� ������������� ������� ���������� ������
   elsif utils.get_int_param('RESTRICT_BY_SAL') = 1 and utils.get_int_param('RESTRICT_WITH_CHNG') = 1 and p_distr not in (15,16,17,18) then 
      -- �� �������� � ���!
      --� �������������
      insert into temp_prep  --�������� 20.04.15 � 15:08
        (usl, org, summa, tp_cd)
       with a as (select t.usl, t.org, sum(t.summa) as summa from temp_prep t
                   where t.summa<>0 and t.tp_cd in (3)
                   group by t.usl, t.org),
            b as (select d.usl, d.org, sum(d.summa) as summa from
            (select t.usl, t.org, nvl(t.indebet,0)+nvl(t.inkredit,0) as summa
              from xitog3_lsk t, params p --����� �������� ������
              where t.lsk=p_rec.lsk
              and t.mg=p.period
            union all
        select t.usl, t.org, t.summa
        from (
        
        select lsk, sum(summa) as summa, org, usl, type
        from (
          select /*+ INDEX (k A_NABOR2_I)*/
          p.lsk, p.summa, p.usl, t.fk_org2 as org, decode(p.type,1,1,2,1,3,3,0) as type
           from a_nabor2 k, c_change p, t_org t, params m
          where k.lsk = p.lsk
            and k.lsk=p_rec.lsk
            and p.mg2 between k.mgFrom and k.mgTo
            and k.usl = p.usl
            and k.org=t.id
            and p.org is null  -- ��� �� ������ ��� ��� � ������ �������
            and exists             --� ��� ������� ������ � �������� �����������
            (select /*+ INDEX (n A_NABOR2_I)*/* from a_nabor2 n where n.lsk=k.lsk and p.mg2 between n.mgFrom and n.mgTo and n.usl=k.usl)
            and p.mg2 < m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
          select
          p.lsk, p.summa, p.usl, t.fk_org2, decode(p.type,1,1,2,1,3,3,0) as type
           from nabor k, c_change p, t_org t, params m
          where k.lsk = p.lsk
            and k.lsk=p_rec.lsk
            and k.usl = p.usl  --�� ������ ���� ������, ��� ��� �� ������� ��� ����� ���
            and p.org is null  -- ��� �� ������ ��� ��� � ������ �������
            and k.org=t.id
            and not exists             --� ��� �� ������� ������ � �������� �����������
            (select /*+ INDEX (n A_NABOR2_I)*/ * from a_nabor2 n 
               where n.lsk=k.lsk and n.lsk = p_rec.lsk and p.mg2 between n.mgFrom and n.mgTo and n.usl=k.usl)
            and p.mg2 < m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
         select
          p.lsk, p.summa, p.usl, t.fk_org2, decode(p.type,1,1,2,1,3,3,0) as type
           from nabor k, c_change p, t_org t, params m
          where k.lsk = p.lsk
            and k.lsk=p_rec.lsk
            and k.usl = p.usl
            and k.org=t.id
            and p.org is null  -- ��� �� ������ ��� ��� � ����� �������
            and p.mg2 >= m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
          select
          p.lsk, p.summa, p.usl, nvl(t.fk_org2, 0) as org, decode(p.type,1,1,2,1,3,3,0) as type
           from kart r, c_change p, t_org t, params m
          where r.lsk = p.lsk
            and r.lsk=p_rec.lsk
            and p.org=t.id
            and p.org is not null  -- ��� ������ ��� ��� � �� ����� ����� ������
            and to_char(p.dtek, 'YYYYMM') = m.period)
             group by lsk, org, usl, type
        
        
        ) t where t.lsk=p_rec.lsk and t.org is not null --�������� �����������
            union all
            select n.usl, o.fk_org2 as org, t.summa
              from c_charge t, nabor n, t_org o  --��������� ������� ����������
              where t.lsk=p_rec.lsk and n.org=o.id
              and t.lsk=n.lsk
              and t.usl=n.usl
              and t.type=1
            union all
            select t.usl, t.org, -1*t.summa
              from kwtp_day t  --������ ��� �������� ������
              where t.lsk=p_rec.lsk
              and t.priznak=1
             ) d
             group by d.usl, d.org
             having  sum(summa) > 0) --����� ������ ���.��������� ������
        select a.usl, a.org, nvl(b.summa,0)-nvl(a.summa,0) as diff, 4 as tp_cd from a
              left join b on a.usl=b.usl and a.org=b.org
              where nvl(b.summa,0)-nvl(a.summa,0) <0; --��� ������������� ������� ���������� ������
   end if;
   end if;

--��������������� ������ � ����
  for c in (
    select
    t.usl, t.org, sum(l_sign * t.summa) as summa --��� ������ ��� ������������� ������ ���� (�.�. �������)
    from temp_prep t
      where t.tp_cd in (3,4) --������ ������������������!!!30.01.2015
      and t.summa <> 0 and t.usl<>'xxx'
    group by t.usl, t.org
    having sum(l_sign * t.summa) <>0
    ) loop
      --���������������
      redirect(p_tp => p_tp, p_reu => p_reu, p_usl_src => c.usl,
        p_usl_dst => l_trgt_usl, p_org_src => c.org, p_org_dst => l_trgt_org, t_redir => t_redir);

      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      values
        (p_distr, p_rec.id, p_rec.lsk, l_trgt_usl, l_trgt_org, c.summa,
         p_rec.oper, p_mg,
         p_rec.nkom, p_rec.nink, p_rec.dat_ink, p_tp, p_rec.dtek);
  end loop;
--�������� �� �������.��������
  if p_summa > 0 and l_sign = 1 then

      select nvl(count(*),0) into l_summa_tmp
      from (
      select t.usl, t.org
        from temp_prep t where t.tp_cd in (3,4)
        and t.usl<>'xxx'
        group by t.usl, t.org
        having sum(t.summa) < -0.05);  --������ -5 ������
     if l_summa_tmp > 0 then
        Raise_application_error(-20000, '��� ������ #7');
      end if;

    end if;

  select
    sum(l_sign*t.summa) into l_summa_tmp
    from temp_prep t where t.tp_cd in (3,4)
    and t.summa <> 0 and t.usl<>'xxx';

  return nvl(l_summa_tmp,0);
end;

begin
--������������� ������ �� ����������� �� �������� + ��� + �������
--�������� FK_DISTR
--������������� ������:
--0 - ������ C_GEN_PAY
--1 - ������ C_GEN_PAY
--2 - ������ C_GEN_PAY
--3 - ������ C_GEN_PAY
--4 - ������ C_GEN_PAY (�������������)
--5 - ������ C_GEN_PAY
--11 - ������ C_GEN_PAY


--6 - ������������ �� ������ �����������
--7 - ������������ �� �������� ����������
--8 - �� �����.�� ���.����������, �����.�� ��� ������ ��� ����� �� ��.������
--9 - �� �����.� �� ��.������, ������ �� ��� "���" - ����� ������ �������������!!!

--10 - ������������ � ������ �� ����� ������������� ������
--12 - (������������� �� ��� c_deb_usl)
--13 - (�������� �����!)
--14 - ������������ �� ���������� ������
--15 - ������������ �� ���������� ������, ��� ������� ��������
--16 - ������������ �� �������� ����������, ��� ������� ��������
--17 - ������������ �� ���������� ������, ��� ������� �������� � ��� ����� ������
--18 - ��������� ������ ������������ ������ �� ������ �������� ����� � ��� (����� ����������� ������)

--��������!!! ������ ������ ������ � �������� �� + ������ (���������� �������� ��������)
select rec_redir(t.reu, t.fk_usl_src, t.fk_usl_dst, t.fk_org_src, t.fk_org_dst, t.tp)
  bulk collect into t_redir from redir_pay t;

select p.period into l_mg from params p;

l_summa:=p_rec.summa;
l_summa_p:=p_rec.penya;

-- ���: ��������� ������ ������������ ������ �� ������ �������� ����� � ��� (����� ����������� ������)
-- � �������������� �������, ���� �� ��������� ��� ������!
if p_rec.dopl <= l_mg and l_summa > 0 then

  l_summa_tmp:=dist(p_rec.dopl, l_summa, 1, 18, null);
  l_summa:=l_summa-l_summa_tmp;

end if;

l_summa_old:=l_summa;
l_summap_old:=l_summa_p;
l_flag:=0;
l_flagp:=0;
i:=0;
-- ���������� ������������� 500 ���!!!
loop
  if l_flag = 0 then
    if l_summa > 0 then
      --������������ ������
      if p_rec.dopl>=l_mg then
        --������� ������
        if l_flag=1 then
          l_dist:=14; --�� ������
        else
          l_dist:=7;  --�� �������� ����������
        end if;
        l_summa_tmp:=dist(l_mg, l_summa, 1, l_dist, null);
      else
        --�������� ������
        if l_flag=1 then
          l_dist:=14; --�� ������
        else
          l_dist:=6;  --�� ������ �����������
        end if;
        l_summa_tmp:=dist(p_rec.dopl, l_summa, 1, l_dist, null);
      end if;
      l_summa:=l_summa-l_summa_tmp;
    elsif l_summa < 0 then
      --������ �� ������� �.� ������������� ������ ����
      l_dist:=7;  --�� �������� ����������
      l_summa_tmp:=dist(p_rec.dopl, l_summa, 1, l_dist, null); --�������� -1 �� 1 ���. 19.11.15
      l_summa:=l_summa-l_summa_tmp;
    end if;
  end if;

  if abs(l_summa_old-l_summa)=0 then --������������, ������ �� ������!
    --����� ������ �� ��������������, ����������� ������������
    --�� ������
    l_flag:=1;
  else
    --����� ��������������
    l_summa_old:=l_summa;
  end if;

  if l_flagp = 0 then
    if l_summa_p > 0 and l_flag = 0 then
      --������������ ���� - �� ��� ������������� ����� ������
      l_dist:=6;
      l_summa_tmp:=dist(p_rec.dopl, l_summa_p, 0, l_dist, p_rec.id);
      l_summa_p:=l_summa_p-l_summa_tmp;
    elsif l_summa_p < 0 then
      --������ �� ������� �.� ������������� ������ ����
      l_dist:=6;
      l_summa_tmp:=dist(p_rec.dopl, l_summa_p, 0, l_dist, null);
      l_summa_p:=l_summa_p-l_summa_tmp;
    end if;
  end if;
  i:=i+1;

  if abs(l_summap_old-l_summa_p)=0 then --������������, ������ �� ������!
    --���� �� ��������������
    l_flagp:=1;
  else
    --����� ��������������
    l_summap_old:=l_summa_p;
  end if;

  if l_flag =1 and l_flagp =1 then --� ������ � ���� �� ��������������
    exit;
  end if;

  exit when (l_summa =0 and l_summa_p =0) or i >=500 ;
end loop;


-- ������� ������� ��������� ��� ������������� 21.12.2016

if utils.get_int_param('PAY_ORD1') = 1 then
  if l_summa <> 0 then
    --������������ �� �������� ���������� (���� ��� ���� ������), �� ��� ���������������� ��������
    select nvl(count(*),0) into l_cnt2
          from c_charge t, nabor n
          where t.lsk=p_rec.lsk
          and t.lsk=n.lsk
          and t.usl=n.usl
          and t.type=1
          and t.summa > 0;
    if l_cnt<>0 then
      i:=0;
      loop
        l_summa_tmp:=dist(p_rec.dopl, l_summa, 1, 16, null);
        l_summa:=l_summa-l_summa_tmp;
        i:=i+1;
        exit when l_summa =0 or i >=500 ;
      end loop;
    end if;
  end if;

  if l_summa <> 0 then
    --������������ �� ���������� ������, � ������ �������� ������, �� ��� ���������������� ��������
    i:=0;
    loop
      l_summa_tmp:=dist(p_rec.dopl, l_summa, 1, 15, null);
      l_summa:=l_summa-l_summa_tmp;
      i:=i+1;
      exit when l_summa =0 or i >=500 ;
    end loop;
  end if;

else
  -- ������� ��� �� �� '13','14' � 15.12.2017:
  /* ���:
  ������, ��� ���������� �������� � ������, ��� �� ����� � ������ ��� �� ���������� ������� "�����", 
  ������� ���� �� �� 14 � 15 ������ ������ ������ ������� ������ 3 ������ 4.
  ������� ��� �� ���� �� � 19.12.2017:
  �.�. ������� � ����� ����� ���� "�� ��������� ������ ������ � �����������".�������� � ����������. 
  � ����� ����� ����� �������� � ������������� ������ � 3, 4 �� 4, 3 ��� ���� ��������� �� (��� 14 � 15 ��� ��� ������� � ����������� �������)?
  */
  
 -- if p_reu in ('13','14') then
    --����� 4
    if l_summa <> 0 then
      --������������ �� �������� ���������� (���� ��� ���� ������), �� ��� ���������������� ��������
      select nvl(count(*),0) into l_cnt2
            from c_charge t, nabor n
            where t.lsk=p_rec.lsk
            and t.lsk=n.lsk
            and t.usl=n.usl
            and t.type=1
            and t.summa > 0;
      if l_cnt<>0 then
        i:=0;
        loop
          l_summa_tmp:=dist(p_rec.dopl, l_summa, 1, 16, null);
          l_summa:=l_summa-l_summa_tmp;
          i:=i+1;
          exit when l_summa =0 or i >=500 ;
        end loop;
      end if;
    end if;
    --����� 3
    if l_summa <> 0 then
      --������������ �� ���������� ������, � ������ �������� ������, �� ��� ���������������� ��������
      i:=0;
      loop
        l_summa_tmp:=dist(p_rec.dopl, l_summa, 1, 15, null);
        l_summa:=l_summa-l_summa_tmp;
        i:=i+1;
        exit when l_summa =0 or i >=500 ;
      end loop;
    end if;
/*  else
    --������ �� ���:
    --����� 3
    if l_summa <> 0 then
      --������������ �� ���������� ������, � ������ �������� ������, �� ��� ���������������� ��������
      i:=0;
      loop
        l_summa_tmp:=dist(p_rec.dopl, l_summa, 1, 15, null);
        l_summa:=l_summa-l_summa_tmp;
        i:=i+1;
        exit when l_summa =0 or i >=500 ;
      end loop;
    end if;

    --����� 4
    if l_summa <> 0 then
      --������������ �� �������� ���������� (���� ��� ���� ������), �� ��� ���������������� ��������
      select nvl(count(*),0) into l_cnt2
            from c_charge t, nabor n
            where t.lsk=p_rec.lsk
            and t.lsk=n.lsk
            and t.usl=n.usl
            and t.type=1
            and t.summa > 0;
      if l_cnt<>0 then
        i:=0;
        loop
          l_summa_tmp:=dist(p_rec.dopl, l_summa, 1, 16, null);
          l_summa:=l_summa-l_summa_tmp;
          i:=i+1;
          exit when l_summa =0 or i >=500 ;
        end loop;
      end if;
    end if;
    
  end if;*/

end if;


if l_summa <> 0 then
  --���� ���� ������ ���������� ������� �� ����������� ������� (��������� �� ������) , 
  --�� ������������ �� ���������� ������, ��� ����� �������� ������, � ��� ���������������� ��������
  i:=0;
  loop
    l_summa_tmp:=dist(p_rec.dopl, l_summa, 1, 17, null);
    l_summa:=l_summa-l_summa_tmp;
    i:=i+1;
    exit when l_summa =0 or i >=500 ;
  end loop;
end if;

if l_summa <> 0 then --���� � �� ����������� ������� (��� ���������.) �� �����., ������ ��� ����� �� 1 �� ������ �� nabor
  insert into kwtp_day
    (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
  select
    9 as fk_distr, p_rec.id, p_rec.lsk, n.usl, n.org, l_summa,
     p_rec.oper, p_rec.dopl,
     p_rec.nkom, p_rec.nink, p_rec.dat_ink, 1 as priznak, p_rec.dtek
     from nabor n where n.lsk=p_rec.lsk and rownum=1;
    if sql%rowcount <> 0 then 
      l_summa:=0;
    end if;
end if;

if l_summa <> 0 then --���� � �� nabor �� �����, ������ �� ���, ��� ������
  insert into kwtp_day
    (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
  select
    9 as fk_distr, p_rec.id, p_rec.lsk, '003' as usl, o.id, l_summa,
     p_rec.oper, p_rec.dopl,
     p_rec.nkom, p_rec.nink, p_rec.dat_ink, 1 as priznak, p_rec.dtek
     from t_org o where o.reu=p_reu;
    l_summa:=0;
end if;

--����
if l_summa_p <> 0 then
  --���� ���� ������ ���������� ������� �� ����������� �������, �� ������������ �� ���������� ������, � ������ �������� ������, �� ��� ���������������� ��������
  i:=0;
  loop
    l_summa_tmp:=dist(p_rec.dopl, l_summa_p, 0, 15, null);
    l_summa_p:=l_summa_p-l_summa_tmp;
    i:=i+1;
    exit when l_summa_p =0 or i >=500 ;
  end loop;
end if;


if l_summa <> 0 then --���� � �� ��� ������ �� �����, ������ ��� ����� �� 1 �� ������ �� nabor
  insert into kwtp_day
    (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
  select
    9 as fk_distr, p_rec.id, p_rec.lsk, n.usl, n.org, l_summa_p,
     p_rec.oper, p_rec.dopl,
     p_rec.nkom, p_rec.nink, p_rec.dat_ink, 0 as priznak, p_rec.dtek
     from nabor n where n.lsk=p_rec.lsk and rownum=1 ;
  l_summa_p:=0;   
end if;

if l_summa_p > 0 then --���� � �� nabor �� �����, ������ �� ���, ��� ������
  insert into kwtp_day
    (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
  select
    9 as fk_distr, p_rec.id, p_rec.lsk, '003' as usl, o.id, l_summa_p,
     p_rec.oper, p_rec.dopl,
     p_rec.nkom, p_rec.nink, p_rec.dat_ink, 0 as priznak, p_rec.dtek
     from t_org o where o.reu=p_reu;
elsif l_summa_p < 0 then
    --������ �� ������� �.� ������������� ������ ����
  l_summa_tmp:=dist(p_rec.dopl, l_summa_p, 0, 16, null);
end if;

--��������... �� �������, ��� ��� �� ��� ���������� ������ ������������� �������������
select case when nvl(sum(decode(t.priznak, 1, t.summa, 0)),0) - nvl(p_rec.summa,0) <>0  then 1
            when nvl(sum(decode(t.priznak, 0, t.summa, 0)),0) - nvl(p_rec.penya,0) <>0 then 2
            else 0 end,
       case when nvl(sum(decode(t.priznak, 1, t.summa, 0)),0) - nvl(p_rec.summa,0) <>0  then
              nvl(sum(decode(t.priznak, 1, t.summa, 0)),0) - nvl(p_rec.summa,0)
            when nvl(sum(decode(t.priznak, 0, t.summa, 0)),0) - nvl(p_rec.penya,0) <>0 then
              nvl(sum(decode(t.priznak, 0, t.summa, 0)),0) - nvl(p_rec.penya,0)
            else 0 end
       into l_cnt, l_summa_err
  from kwtp_day t where t.kwtp_id=p_rec.id;
if l_cnt = 1 then
  Raise_application_error(-20000, '��� ������ #1 � �.�.='||p_rec.lsk||', kwtp_id='||p_rec.id||' �������� ��� ���������� �� ������, �������='||l_summa_err);
elsif l_cnt = 2 then
  Raise_application_error(-20000, '��� ������ #0 � �.�.='||p_rec.lsk||', kwtp_id='||p_rec.id||' �������� ��� ���������� �� ������, �������='||l_summa_err);
end if;

 --��������� �������� ������ ��� ����
 update kwtp_day t set t.org=redirect_org(t.priznak, p_reu, t.usl, t.org, t_redir)
   where t.kwtp_id=p_rec.id;
end;

procedure dist_pay_lsk_force is
begin
--�������������� ������������� ��������
for c in (select t.* from c_kwtp_mg t where
 not exists (select * from kwtp_day k where k.kwtp_id=t.id)
 --and t.summa <> 0 --������ ������������� ��������!
 --and t.lsk='00000191'
-- and t.id=4416660
 order by t.dopl)
loop
  for c2 in (select k.reu from kart k where k.lsk=c.lsk) loop --����
    dist_pay_deb_mg_lsk(c2.reu, c);
  end loop;
commit;

end loop;

end;

--������ ��� ������� �� ���������
--��������!!!!(������ ��� ����������!!!! �� ������������ ��� ��������� ������, ��� ��� �� ��������� �������� ������)
function redirect_org (p_tp in number, --1-������, 0 - ����
                        p_reu in varchar2, --��� ���
                        p_usl_src in varchar2, --�������� ������
                        p_org_src in number,  --�������� ���.
                        t_redir in tab_redir --������� ����������
                        ) return number is
  l_org number;
  l_dummy usl.usl%type;
begin

  redirect(p_tp => p_tp, p_reu => p_reu, p_usl_src => p_usl_src, p_usl_dst => l_dummy,
           p_org_src => p_org_src, p_org_dst => l_org, t_redir => t_redir);
  return l_org;

end;


--�������� ������/����
procedure redirect (p_tp in number, --1-������, 0 - ����
                        p_reu in varchar2, --��� ���
                        p_usl_src in varchar2, --�������� ������
                        p_usl_dst out varchar2,--���������������� ������
                        p_org_src in number,  --�������� ���.
                        p_org_dst out number, --���������������� ���.
                        t_redir in tab_redir --������� ����������
                        ) is
  l_usl_flag number; --���� ������������� �������� �� ������
  l_org_flag number; --���� ������������� �������� �� �����������
  l_exist_flag number; --���� ������� ���� � �������
begin

l_usl_flag:=0;
l_org_flag:=0;
p_usl_dst:=p_usl_src;
p_org_dst:=p_org_src;

l_exist_flag:=0;
if t_redir.count > 0 then
  for a in t_redir.first..t_redir.last loop
    if t_redir(a).tp=p_tp then
      l_exist_flag:=1;
      exit;
    end if;
  end loop;
end if;

if l_exist_flag=0 then
  --�� ������ ����� ��� � ������� ����������, �� � ��� ������ ����� ������ ��� �� ���������
  return;
end if;

for c in (select * from redir_pay t where
                                  nvl(t.reu, p_reu)=p_reu and --���� ����������� ���=����.���, ���� ����� (�������� ��� ���� ���)
                                  nvl(t.fk_usl_src, p_usl_src)=p_usl_src and --���� ����������� ���=����.���, ���� ����� (�������� ��� ���� �����)
                                  nvl(t.fk_org_src, p_org_src)=p_org_src --���� ����������� ���=����.���, ���� ����� (�������� ��� ���� �����������)
                                  and t.tp=p_tp
                                  order by
                                  case when t.reu=p_reu then 0 else 1 end,
                                  case when t.fk_usl_src=p_usl_src then 0 else 1 end,
                                  case when t.fk_org_src=p_org_src then 0 else 1 end
             ) loop

  if c.fk_usl_dst is not null then
    p_usl_dst:=c.fk_usl_dst;
    l_usl_flag:=1;
  end if;
  if c.fk_org_dst is not null then
    if c.fk_org_dst=-1 then --������������� �� �����������, ������������� ����
       select o.id into p_org_dst from t_org o
          where o.reu=p_reu;
    else
       p_org_dst:=c.fk_org_dst;
    end if;
    l_org_flag:=1;
  end if;

  if l_usl_flag=1 and l_org_flag=1 then
    exit; --����� ��� ��������
  end if;

end loop;

end;

procedure dist_pay_lsk_avnc_force is
begin
--�������������� ������������� ��������� ��������
--������� ������������� ���������
logger.log_(null, 'scott.c_dist_pay.dist_pay_lsk_avnc_force : ������ ����������������� ��������� ��������');
delete from kwtp_day t where exists (select * from params p where t.dopl>=p.period)
  and exists (select * from c_kwtp_mg m where m.id=t.kwtp_id and (m.summa > 0 or m.penya >0));

--������������
for c in (select t.* from c_kwtp_mg t where
 not exists (select * from kwtp_day k where k.kwtp_id=t.id)
 and (t.summa > 0 or t.penya >0) --������ ������������� ��������!
 )
loop
    for c2 in (select k.reu from kart k where k.lsk=c.lsk) loop --����
      dist_pay_deb_mg_lsk(c2.reu, c);
    end loop;
  commit;
end loop;
logger.log_(null, 'scott.c_dist_pay.dist_pay_lsk_avnc_force : ��������� ����������������� ��������� ��������');
end;

end C_DIST_PAY;
/

