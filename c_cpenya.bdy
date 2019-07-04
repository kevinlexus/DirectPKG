create or replace package body scott.C_CPENYA is

--�������
procedure gen_charge_pay_pen is
begin
  gen_charge_pay_pen(p_dt => null);
end;

--��� ���� �������, ��� ������ �������
procedure gen_charge_pay_pen(p_dt in date) is
begin
  gen_charge_pay_pen(null, p_dt, 1);
end;

--������������ �� �����, � �������
procedure gen_charge_pay_pen_house(p_dt in date, --���� ������.
                             p_house in number) is
 l_dt date;
 l_is_lstdt number;
begin
/*  if p_dt is null then
    --�� ����� ������
    l_is_lstdt:=1;
    l_dt:=init.get_dt_end;
  else
    --�� �������� ����
    l_is_lstdt:=0;
    l_dt:=p_dt;
  end if; */
  -- ����� ������ �� ����� ������
  l_is_lstdt:=1;
  l_dt:=null;

  logger.log_(time_, 'gen_charge_pay_pen_house ������: p_house='||p_house);

  for c in (select lsk from kart k where k.house_id=p_house) loop
    --����, �� ����, � ��������
    --�������� �������� ������
    --logger.log_(time_, 'gen_charge_pay_pen_house ������: p_lsk='||c.lsk);
    gen_penya(lsk_ => c.lsk, dat_ => l_dt, islastmonth_ => l_is_lstdt, p_commit => 1);
    --logger.log_(time_, 'gen_charge_pay_pen_house ���������: p_lsk='||c.lsk);
  end loop;
  logger.log_(time_, 'gen_charge_pay_pen_house ���������: p_house='||p_house);
  
end;

--��������� ������������� ����������� ���� �� ���.������ - �������
procedure gen_charge_pay_pen(
                             p_dt in date, --���� ������.
                             p_var in number --����������� ����? (0-���, 1-�� (������ �����)
          ) is
begin
  gen_charge_pay_pen(null, p_dt, p_var);
end;          

--��������� ������������� ����������� ���� �� ���.������
--������� ���, ������ ��� �� ������ ���������� ���� �� ������� (���� ����� - �� ���� ��������� ���������� � �.�.)
procedure gen_charge_pay_pen(p_lsk in kart.lsk%type, -- ��� ���� (���� null - �� ��� ���.�����)
                             p_dt in date, --���� ������.
                             p_var in number --����������� ����? (0-���, 1-�� (������ �����)
          ) is
  l_usl_dst usl.usl%type;
  l_org_dst number;
  l_mg params.period%type;
  l_mg2 params.period%type;
  l_mg_back params.period%type;
  t_summ  tab_summ;
  l_err number;
  l_dt date;
begin
  time_ := sysdate;
  select p.period, p.period1, p.period3 into l_mg, l_mg2, l_mg_back
    from v_params p;
  if p_dt is null then
    l_dt:=init.get_dt_end;
  else
    l_dt:=p_dt;
  end if; 
  if p_var=1 then 
    for c in (select lsk from kart t where nvl(p_lsk, t.lsk) = t.lsk) loop
      --����, �� ����, � ��������
      --�������� �������� ������
      gen_penya(lsk_ => c.lsk, dat_ => l_dt, islastmonth_ => 0, p_commit => 1);
    end loop;
  end if;
  
  -- ����� ������������ ���������� ����, ������������ � �� �������
  -- ���� ������������� ������ �� ������ ��������� ���������� c_gen_pay.redirect
  if p_lsk is null then
    delete from t_chpenya_for_saldo t; -- �������, ����������� ���� � ������ ������������� �� ����!
    delete from temp_chpenya;
  else
    delete from t_chpenya_for_saldo t where t.lsk=p_lsk; -- �������, ����������� ���� � ������ ������������� �� ����!
    delete from temp_chpenya t where t.lsk=p_lsk;
  end if;
  
  for c in (select t.reu, t.lsk, t.tp, t.penya, coalesce(b.deb_summa,0) as deb_summa, coalesce(b.kr_summa,0) as kr_summa, t.pen_sign
   from (select k.reu, tp.cd as tp, d.lsk, sum(d.penya) as penya, sign(sum(d.penya)) as pen_sign
    from kart k, v_lsk_tp tp, (select r.lsk, sum(r.penya) as penya from (
      select c.lsk, c.mg1, round(sum(penya),2) as penya from c_pen_cur c where nvl(p_lsk,c.lsk)=c.lsk
        group by c.lsk, c.mg1       -- ������� ���������� ����   
      union all
     select c.lsk, c.dopl, c.penya  -- ��������� ������������� ���� �� ����� (�� �������� �� �������)
          from c_pen_corr c where nvl(p_lsk,c.lsk)=c.lsk and c.usl is null
        ) r group by r.lsk
      ) d 
    where nvl(p_lsk,k.lsk)=k.lsk and k.lsk=d.lsk and k.fk_tp=tp.id
    group by k.reu, d.lsk, tp.cd
    having sum(d.penya)<>0) t left join 
   (select d.lsk, sum(case when d.poutsal > 0 then d.poutsal else 0 end) as deb_summa, 
                  sum(case when d.poutsal < 0 then d.poutsal else 0 end) as kr_summa
    from (select a.lsk, a.usl, a.org, sum(a.poutsal) as poutsal from (
           select s.lsk, s.usl, s.org, s.poutsal from xitog3_lsk s where s.mg=l_mg_back -- �������� ������ �� ����
           and nvl(p_lsk,s.lsk)=s.lsk
           union all 
           select s.lsk, s.usl, s.org, s.penya from c_pen_corr s where s.usl is not null
           and nvl(p_lsk,s.lsk)=s.lsk -- �������������, �������� �� ������� (��� ���������� ������������� �� ����������� �������) (���� �����������)
           ) a group by a.lsk, a.usl, a.org) d 
     group by d.lsk) b on t.lsk=b.lsk and t.penya <> 0
       order by t.lsk)
  loop
    --������������� �� ������
    if c.pen_sign > 0 and c.deb_summa <> 0 then 
        --������������ �� ����� ������ ���� - ������������� �������� ����
        select rec_summ(t.usl, t.org, t.poutsal, 0) bulk collect
          into t_summ from
          (select a.usl, a.org, sum(a.poutsal) as poutsal from (
           select s.usl, s.org, s.poutsal from xitog3_lsk s where s.lsk=c.lsk and s.mg=l_mg_back -- ������ �� ����
           union all 
           select s.usl, s.org, s.penya from c_pen_corr s where s.lsk=c.lsk and s.usl is not null
           ) a group by a.usl, a.org -- �������������, �������� �� ������� (��� ���������� ������������� �� ����������� �������) (���� �����������)
           ) t
          where t.poutsal > 0;
    elsif c.pen_sign > 0 and c.kr_summa <> 0 then       
        --������������ �� ������ ������ ���� - ������������� �������� ����
        select rec_summ(t.usl, t.org, t.poutsal*-1, 0) bulk collect
          into t_summ from
           (select a.usl, a.org, sum(a.poutsal) as poutsal from (
           select s.usl, s.org, s.poutsal from xitog3_lsk s where s.lsk=c.lsk and s.mg=l_mg_back -- ������ �� ����
           union all 
           select s.usl, s.org, s.penya from c_pen_corr s where s.lsk=c.lsk and s.usl is not null
           ) a group by a.usl, a.org -- �������������, �������� �� ������� (��� ���������� ������������� �� ����������� �������) (���� �����������)
           ) t
          where t.poutsal < 0;
    elsif c.pen_sign > 0 and c.deb_summa = 0 and c.kr_summa = 0 then       
        --������������ �� ���������� ������������� �������� ����, ���� ������=0
        select rec_summ(n.usl, n.org, t.summa, 0) bulk collect
          into t_summ from
           c_charge t, nabor n
          where t.lsk=c.lsk and t.summa > 0 and t.type=1
          and t.lsk=n.lsk and t.usl=n.usl;
        if sql%rowcount = 0 then --�� ������� ����������, ������������ �� ������� (���� �� 100 ���)
            if c.tp='LSK_TP_MAIN' then
              -- �������� ��
            select rec_summ(t.usl, t.org, 100, 0) bulk collect
              into t_summ from nabor t where t.lsk=c.lsk and t.usl='003'; 
            else 
              -- ������
            select rec_summ(t.usl, t.org, 100, 0) bulk collect
              into t_summ from nabor t where t.lsk=c.lsk and t.usl='033'; 
            end if;
            if sql%rowcount = 0 then
              -- ���� �� � � ������� ��� ������ ��...
              select rec_summ('003', t.id, 100, 0) bulk collect
                into t_summ from t_org t where t.reu=c.reu; 
            end if;    
        end if;   
    elsif c.pen_sign < 0 and c.kr_summa <> 0 then       
        --������������ �� ������ ������ ���� - ������������� �������� ����
        select rec_summ(t.usl, t.org, t.poutsal*-1, 0) bulk collect
          into t_summ from
           (select a.usl, a.org, sum(a.poutsal) as poutsal from (
           select s.usl, s.org, s.poutsal from xitog3_lsk s where s.lsk=c.lsk and s.mg=l_mg_back -- ������ �� ����
           union all 
           select s.usl, s.org, s.penya from c_pen_corr s where s.lsk=c.lsk and s.usl is not null
           ) a group by a.usl, a.org -- �������������, �������� �� ������� (��� ���������� ������������� �� ����������� �������) (���� �����������)
           ) t
          where t.poutsal < 0;
    elsif c.pen_sign < 0 and c.deb_summa <> 0 then       
        --������������ �� ����� ������ ���� - ������������� �������� ����
        select rec_summ(t.usl, t.org, t.poutsal, 0) bulk collect
          into t_summ from
           (select a.usl, a.org, sum(a.poutsal) as poutsal from (
           select s.usl, s.org, s.poutsal from xitog3_lsk s where s.lsk=c.lsk and s.mg=l_mg_back -- ������ �� ����
           union all 
           select s.usl, s.org, s.penya from c_pen_corr s where s.lsk=c.lsk and s.usl is not null
           ) a group by a.usl, a.org -- �������������, �������� �� ������� (��� ���������� ������������� �� ����������� �������) (���� �����������)
           ) t
          where t.poutsal > 0;
    elsif c.pen_sign < 0 and c.deb_summa = 0 and c.kr_summa = 0 then       
        --������������ �� ���������� ������������� �������� ����, ���� ������=0
        select rec_summ(n.usl, n.org, t.summa, 0) bulk collect
          into t_summ from
           c_charge t, nabor n
          where t.lsk=c.lsk and t.summa > 0 and t.type=1
          and t.lsk=n.lsk and t.usl=n.usl;
          if sql%rowcount = 0 then --�� ������� ����������, ������������ �� ������� (���� �� 100 ���)
            if c.tp='LSK_TP_MAIN' then
              -- �������� ��
              select rec_summ(t.usl, t.org, 100, 0) bulk collect
                into t_summ from nabor t where t.lsk=c.lsk and t.usl='003'; 
              else 
                -- ������
              select rec_summ(t.usl, t.org, 100, 0) bulk collect
                into t_summ from nabor t where t.lsk=c.lsk and t.usl='033'; 
            end if;
            if sql%rowcount = 0 then
              -- ���� �� � � ������� ��� ������ ��...
              select rec_summ('003', t.id, 100, 0) bulk collect
                into t_summ from t_org t where t.reu=c.reu; 
            end if;
          end if;
    end if;
          
      
    l_err := c_prep.dist_summa_full(p_sum  => c.penya,
                         t_summ => t_summ);
    if l_err <> 0 then
      Raise_application_error(-20000, '������ ��� ������������� ���� � ���.�����:'||c.lsk);
    end if;                     
    
    delete from temp_prep;
    
    -- ��������������� ����, �� ������ ������ � �����������
    for c2 in (select t.summa as summa, t.fk_cd as usl, t.fk_id as org
       from table(t_summ) t
             where t.tp = 1
             )                     
    loop             
      c_gen_pay.redirect(p_tp => 0, p_reu => c.reu, 
        p_usl_src => c2.usl, p_usl_dst => l_usl_dst, p_org_src => c2.org, p_org_dst => l_org_dst);

      insert into temp_prep(usl, org, summa)
        values (l_usl_dst, l_org_dst, c2.summa);
        
    end loop;

    -- ��������� �� ��������� �������
      begin  
    insert into temp_chpenya (lsk, usl, org, summa)
      select c.lsk, t.usl, t.org, summa as summa
      from temp_prep t;
        exception when others then
          for c3 in (select * from temp_prep t) loop
          Raise_application_error(-20000, 'lsk='||c.lsk||' c2.usl='||c3.usl||' c2.org='||c3.org);
          end loop;
      end;  
  end loop;

    -- �������� �������������, �������� �� �������    
  if p_lsk is null then
    insert into t_chpenya_for_saldo (lsk, usl, org, summa)
    select lsk, usl, org, sum(penya) from (
    select t.lsk, t.usl, t.org, t.penya from c_pen_corr t
     where t.usl is not null -- ������������� �������� �� �������!
    union all 
    select t.lsk, t.usl, t.org, t.summa from temp_chpenya t -- ����������� � �������������� ����
    ) group by lsk, usl, org;
  else
    insert into t_chpenya_for_saldo (lsk, usl, org, summa)
    select lsk, usl, org, sum(penya) from (
    select t.lsk, t.usl, t.org, t.penya from c_pen_corr t
     where t.lsk=p_lsk and t.usl is not null -- ������������� �������� �� �������!
    union all 
    select t.lsk, t.usl, t.org, t.summa from temp_chpenya t -- ����������� � �������������� ����
     where t.lsk=p_lsk
    ) group by lsk, usl, org;
  end if;  

  commit;
 logger.log_(time_, 'c_penya.gen_charge_pay_pen');
end;

PROCEDURE gen_charge_pay_full is
--���������� c_chargepay
--������, �� ������� ����
begin
  for c in (select k.lsk from kart k)
  loop
    gen_charge_pay(c.lsk, 1);
  end loop;
end;

--������� ��� ������ �����
PROCEDURE gen_charge_pay(lsk_ in kart.lsk%type, iscommit_ in number) is
begin
  gen_charge_pay(lsk_ => lsk_, iscommit_ => iscommit_, p_dt => null);
end;

--���������� c_chargepay
--������, �� ������� ����
PROCEDURE gen_charge_pay(lsk_ in kart.lsk%type, --��� ����
                         iscommit_ in number,   --������� �� ������
                         p_dt in date           --���� �� ������� ��������� ����������
                        ) is
  period_ PARAMS.period%TYPE;
  newperiod_ PARAMS.period%TYPE;
  oldperiod_ PARAMS.period%TYPE;
begin

if lsk_ is null then
  --�� ������� ����� �������������� lsk_ is null, ������� ����� �� ��������� ��� ��������?
  Raise_application_error(-20000, '�������� ������������ ��� ������ #1');
end if;


SELECT v.period1 INTO newperiod_ FROM v_params v;
SELECT period INTO period_ FROM PARAMS;
SELECT TO_CHAR(ADD_MONTHS(TO_DATE(period || '01', 'YYYYMMDD'), -1), 'YYYYMM')
 INTO oldperiod_ FROM PARAMS;
--��� ������� ����

delete from c_chargepay c where c.period=period_ and c.lsk=lsk_;

--����������
insert into c_chargepay (summa, type, mg, period, lsk)
select sum(summa) as summa, 0, mg, period_, lsk_
           from (select c.lsk, c.summa, period_ as mg
                    from c_charge c where c.lsk = lsk_
                    and c.type=1 --����������
                    and c.usl not in (select usl_id from usl_excl)
                  union all
                  select c.lsk, c.summa, c.mgchange as mg
                    from c_change c where c.lsk = lsk_
                    and c.usl not in (select usl_id from usl_excl)
                    and c.dtek <= nvl(p_dt, c.dtek) --����������, ���� ����
                    and c.dtek between init.g_dt_start and init.g_dt_end
                    and c.show_bill is null --���.01.03.13 - show_bill ������������ ��������, ����� ����� ����� ���������� �� ��� ��� = 0 (������, �� �������)
                  union all
                  select c.lsk, c.summa, c.mg --�� ������� ������� ����� ����������
                    from c_chargepay c where c.lsk = lsk_
                    and c.period=oldperiod_
                    and c.type=0
                    ) a
                  group by a.lsk, a.mg
                  having sum(summa) <>0;

--������
if init.g_dt_start is null or init.g_dt_end is null then
  Raise_application_error(-20000, '�������� ������������ ��� ������ #5');
end if;

if to_char(init.g_dt_start,'YYYYMM')<>period_ or to_char(init.g_dt_end,'YYYYMM')<>period_ then
  Raise_application_error(-20000, '�������� ������������ ��� ������ #6');
end if;

insert into c_chargepay (summa, summap, type, mg, period, lsk)
select sum(summa) as summa, sum(summap), 1, mg, period_, lsk_
           from (select c.lsk, c.summa, c.penya as summap,
                c.dopl as mg
                    from c_kwtp_mg c where c.lsk = lsk_
                    and c.dtek <= nvl(p_dt, c.dtek) --����������, ���� ����
                    and (c.dat_ink is null and c.dtek <= init.g_dt_end or --�� �� ������ ���� ��� ������� (��������� ��� ������� ������ ��� = ������� �������) ���.02.09.14
                        c.dat_ink between init.g_dt_start and init.g_dt_end)
                  union all
                select c.lsk, c.summa, null as summap,
               /* var=2 ����� dopl �� ���������� � c_deb_usl! ���.08.04.14*/
                  c.dopl
                 --������������� ������
                    from t_corrects_payments c, params p
                     where c.lsk = lsk_ and
                     c.mg=p.period
                  union all
                  select c.lsk, c.summa, c.summap, c.mg --�� ������� ������� ����� ������
                    from c_chargepay c where c.lsk=lsk_
                    and c.period=oldperiod_
                    and c.type=1
                    ) a
                  group by a.lsk, a.mg
                  having sum(summa) <>0 or sum(summap) <>0;
  if iscommit_ = 1 then
   commit;
  end if;
end;

PROCEDURE gen_penya(lsk_ in kart.lsk%type, islastmonth_ in number, p_commit in number) is
begin
  --������������� ������� ������������ ����
  gen_penya(lsk_, null, islastmonth_, p_commit);
end;


PROCEDURE gen_penya(lsk_ in kart.lsk%type, dat_ in date, islastmonth_ in number, p_commit in number) is
 l_pn_dt kart.pn_dt%type; --����������� ���� �����
 l_datpen date;
 l_mg params.period%type;
 l_mg_back params.period%type;
 --��� ������� ����
 l_summa number; --����� �����
 l_ovrpay number; --�������� (��������� �� ������� ������)
 --��� ������� ����� (������, ��� ��� ��� ������� ����� ����, ���� ����������� ����������� ������ �� ������� ����, � ��� ������� ���� - ���
 l_summa_deb number; --����� �����
 l_ovrpay_deb number; --�������� (��������� �� ������� ������)

 l_lsk_tp number; --��� �������� ����� (��������/��������������)
 l_day_iter date; --���� �������� �������
 l_reu kart.reu%type;
begin
  --��������� ������ ����� gen_charge_pay
  --��������� ������ ����� gen.gen_saldo (��� ������������ �� �����)
  --������� ��������.������
  delete from c_penya t where t.lsk = lsk_;
  --������� ��������.������ ���.����
  delete from temp_pen_chrg t;

  --������, ��������� �� ������ ���� �� ������� ��?
  select k.pn_dt, k.fk_tp, k.reu into l_pn_dt, l_lsk_tp, l_reu from kart k
    where k.lsk=lsk_;

  --������� ������
  l_mg:=init.get_period;
  --������ �� ����� �����
  l_mg_back:=utils.add_months2(mg_ => l_mg, months_ => -1);

  --������� ����
  if dat_ is null then
    if islastmonth_ = 0 then --������� ����
      l_datpen:=init.get_date();
    else --���� �� ����� ������
      l_datpen:=init.get_cur_dt_end;
    end if;
  else --���� �� ���������� ����
    if dat_ < init.get_cur_dt_start then
      l_datpen:=init.get_cur_dt_start;
    else
      l_datpen:=dat_;
    end if;  
  end if;

  l_ovrpay:=0;
  l_summa:=0;
  --
  l_ovrpay_deb:=0;
  l_summa_deb:=0;

--  l_tp:=utils.get_int_param('GEN_SAL_PEN'); --�������� �� ������������ ����� (��������� ����� ����� � ������ �����)

  --������ � ������ �� ����
  --��������� ��� ���� ������
--    l_iter:=0;
    delete from temp_for_pen;
    insert into temp_for_pen
     (summa, summa_deb, mg, dtek, tp)
      select 0 as summa, 0 as summa_deb, l_mg as mg, null as dtek, 0 as tp from dual --�������� �� ������ ������ ���.������
      union all
      select decode(t.type,0,t.summa,-1*t.summa) as summa, decode(t.type,0,t.summa,-1*t.summa) as summa2,
        t.mg, null as dtek, 1 as tp from c_chargepay t where t.lsk=lsk_ and t.period=l_mg_back --����� ������� ��������
      union all
      select t.summa, t.summa as summa_deb, l_mg, null as dtek, 2 as tp 
        from c_charge t where t.lsk=lsk_ and t.type=1--����������
      union all
      select -1*t.summa, 0 as summa_deb, t.dopl, t.dtek as dtek, 3 as tp 
        from c_kwtp_mg t where t.lsk=lsk_ 
      union all
      select 0 as summa, -1*t.summa as summa_deb, t.dopl, t.dtek as dtek, 4 as tp 
        from c_kwtp_mg t where t.lsk=lsk_
      union all
      select t.summa, t.summa as summa_deb, t.mgchange, t.dtek as dtek, 5 as tp 
        from c_change t where t.lsk=lsk_
      union all
      select t.summa, -1*t.summa as summa_deb, t.dopl, null as dtek, 6 as tp 
        from t_corrects_payments t--������������� ������
                   where t.lsk=lsk_ and t.mg=l_mg; --����� �� ������� dtek (����� � ������ ������ �������)
                   
  -- ���. 22.03.2017
  -- ������� ��� �����, ����������� > �������� ������� - ������������ � ������� 
  -- ����� �� ������ ����, ��� ��� ������� "if l_summa_deb > 0 or l_summa*c.proc > 0 or c.mg=l_mg then"
  -- ����������� ��� ���� ������ ������������� �����
  update temp_for_pen t set t.mg=l_mg where t.mg > l_mg;

  for c2 in (select t.dat from v_cur_days t where t.dat <= l_datpen) loop
    l_day_iter:=c2.dat;
   
    --�� ������ ���� ����������
    --gen_charge_pay(lsk_ => lsk_, iscommit_ => 0, p_dt => c2.dt2); --����������� ��������, � ������������ ��������, ��� �������

    l_ovrpay:=0;
    l_ovrpay_deb:=0;
    
    for c in (
      with a as (  
      select sum(r.summa) as summa, sum(r.summa_deb) as summa_deb,
      r.mg from (
           select t.summa, t.summa_deb, t.mg from temp_for_pen t where t.tp=0
             union all
           select t.summa, t.summa_deb, t.mg from temp_for_pen t where t.tp=1
             union all
           select t.summa, t.summa_deb, t.mg from temp_for_pen t where t.tp=2
             union all
           select t.summa, t.summa_deb, t.mg from temp_for_pen t where t.tp=3 
                  and case when t.dtek < init.get_cur_dt_start 
                    then init.get_cur_dt_start else t.dtek end < c2.dat --����� ������ ��� ������� ���� (�� ���. ����������� ��� ���)
             union all
           select t.summa, t.summa_deb, t.mg from temp_for_pen t where t.tp=4 and t.dtek<=c2.dat --����� ������ ��� ������� ����� (���. ����������� ��� ���)
             union all
           select t.summa, t.summa_deb, t.mg from temp_for_pen t where t.tp=5 and t.dtek<=c2.dat --����������
             union all
           select t.summa, t.summa_deb, t.mg from temp_for_pen t where t.tp=6
        ) r
        group by r.mg
        having (sum(r.summa) <> 0 or sum(r.summa_deb) <> 0 or r.mg=l_mg) --��� ���� ����-��������� ��� ������� ������
      ) 
      select a.summa, a.summa_deb, 
                sum(a.summa) over (partition by 0) as sal, --�����, ��� ���������� ��������� ������ �� ������� ���
                a.mg, case when l_pn_dt is not null and c2.dat >= l_pn_dt then 0
                      else s.proc/100
                      end as proc, 
                c2.dat-e.dat+1 as days, s.id from a 
                left join c_spr_pen e on a.mg=e.mg and e.fk_lsk_tp=l_lsk_tp and e.reu=l_reu
                left join stav_r s on c2.dat-e.dat+1 between s.days1 and s.days2
                  and l_day_iter between s.dat1 and s.dat2
                  and s.fk_lsk_tp=l_lsk_tp
                order by a.mg
        ) loop
         --��� ������� ����
         if c.summa < 0 then
           l_ovrpay:=c.summa+l_ovrpay; --��������� ���������
           if c.mg=l_mg then
             l_summa:=l_ovrpay;
           else
             l_summa:=0;
           end if;
         else
           l_summa:=c.summa+l_ovrpay; --������ ��������
           if l_summa < 0 then
             l_ovrpay:=l_summa;
           else
             l_ovrpay:=0;
           end if;
         end if;

         --��� ������� �����
         if c.summa_deb < 0 then
           l_ovrpay_deb:=c.summa_deb+l_ovrpay_deb; --��������� ���������
           if c.mg=l_mg then
             l_summa_deb:=l_ovrpay_deb;
           else
             l_summa_deb:=0;
           end if;
         else
           l_summa_deb:=c.summa_deb+l_ovrpay_deb; --������ ��������
           if l_summa_deb < 0 then
             l_ovrpay_deb:=l_summa_deb;
           else
             l_ovrpay_deb:=0;
           end if;
         end if;
         
         if l_summa_deb > 0 or l_summa*c.proc > 0 or c.mg=l_mg then
           --���� ����������� (��� �� ������ ��� ���� ����) ��� ������� ������
           --�������� ������ ���� (���������� �������� �������) (� ����������� �� ������� ��� ������, �� ������, - �������������)
           insert into temp_pen_chrg
             (summa, summa2, penya, days, mg1, day_iter, fk_stav)
           values (
                   l_summa_deb, --������������ ���� �� ����� ��� 
                   l_summa, --���� �� ������� ��������� ����
                   case when c.sal > 0 then l_summa*c.proc--�����! ���� ����� ���, ��� ���������, �������� ����
                   else 0 end, --����������� ���� (��� �� ���� �� ��������� ����������� ������ �� ������� ����) 
                   case when c.days > 0 then c.days else null end, c.mg, l_day_iter, c.id);
         end if;
    end loop;
  end loop;

  --�������� ��������� ������ (���� ����� �� ��������� �������� temp_pen_chrg)
    insert into c_penya (lsk, summa, penya, days, mg1)
    select lsk_ as lsk, r.summa, b.penya, case when nvl(r.summa,0) > 0 then r.days else null end as days, b.mg1 from (
    select a.lsk, nvl(sum(a.penya),0) as penya, a.mg1 from (
    select t.lsk, t.penya, t.mg1
      from a_penya t where t.mg=l_mg_back --��.������ �����.���.
      and t.lsk=lsk_
    union all
    select lsk_ as lsk, round(sum(t.penya),2) as penya, t.mg1 --��������� ���������� ���� �� ����� --���.21.11.2016 ���������� ������ ����
          from temp_pen_chrg t
          group by t.mg1
    union all
    select c.lsk, c.penya,  c.dopl --��������� ������������� ���� �� �����
          from c_pen_corr c where c.lsk = lsk_
          --and c.dtek<=l_datpen --������ ����������� �� ���� - �� ����� ����� �����������
          and c.dtek between init.g_dt_start and init.g_dt_end
    union all
    select c.lsk, -1*c.penya, c.dopl as mg1 --������ ����������� ����
          from c_kwtp_mg c where c.lsk = lsk_
          and c.dtek <= l_datpen --������ ����������� �� ����
          /*between init.g_dt_start and */  --���������� ����� between ��� ��� ������ ���� < ������ ���� ������
               ) a
    group by a.lsk, a.mg1
    ) b full join (select * from temp_pen_chrg t where t.day_iter=l_day_iter) r on b.mg1=r.mg1
    where (nvl(r.summa,0) <> 0 or nvl(b.penya,0)<>0);

  delete from c_pen_cur t where t.lsk=lsk_;  
  insert into c_pen_cur
    (lsk, mg1, fk_stav, penya, summa2, curdays, dt1, dt2)
    with r as
     (select * from temp_pen_chrg t)
    select lsk_ as lsk, a.mg1, a.fk_stav, sum(a.penya) as penya, max(a.summa2) as summa, --�� ��, ����� max (������ ����� ����. ����� �����������)
           count(*) as curdays, min(a.day_iter) as dt1, max(a.day_iter) as dt2
      from (select t.*,
                    row_number() over(order by mg1, day_iter) - row_number()
                     over(partition by mg1, fk_stav order by mg1, day_iter) as grp
               from r t) a
     group by a.grp, a.mg1, a.fk_stav
     having coalesce(sum(a.penya),0) <> 0;

 IF p_commit=1 THEN
   COMMIT;
 END IF;
end;


--������������� �� ���� ��������� ������ �� ���� �� ���� �������� �� �/�
function corr_sal_pen(p_lsk in kart.lsk%type, p_mg in c_pen_corr.dopl%type)
    return number is
  l_id number;
  l_user number;
  l_comm c_change_docs.text%type;
begin
  select u.id into l_user from t_user u where u.cd=user; 
  l_comm:='������������� ��.������ �� ����';
  insert into c_change_docs
    (mgchange, dtek, ts, user_id, text)
  values 
    (p_mg, init.get_date, sysdate, l_user, l_comm)
  returning id into l_id;
  
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select a.lsk, -1*sum(penya) as penya, a.dopl, init.get_date as dtek, sysdate as ts, 
     l_user as fk_user, l_id as fk_doc
  from (
  select t.lsk, t.penya as penya, p_mg as dopl
    from a_penya t where t.lsk=p_lsk and t.mg1=p_mg
    and t.mg=utils.add_months_pr(init.get_period,-1)
  union all
  select t.lsk, t.penya, t.dopl from c_pen_corr t where t.lsk=p_lsk and t.dopl=p_mg  
  ) a
  group by a.lsk, a.dopl
  having sum(penya) > 0;
  
  if sql%rowcount = 0 then
    return 1;
  else
    return 0;
  end if;  
end;

--������������� �� ���� ����� ��������� ������ �� ���� �� ���� �������� �� �/�
function corr_all_sal_pen(p_lsk in kart.lsk%type)
    return number is
  l_id number;
  l_user number;
  l_comm c_change_docs.text%type;
  l_mg params.period%type;
begin
  select u.id, p.period into l_user, l_mg from t_user u, params p where u.cd=user; 
  l_comm:='������������� ��.������ �� ����';
  insert into c_change_docs
    (mgchange, dtek, ts, user_id, text)
  values 
    (l_mg, init.get_date, sysdate, l_user, l_comm)
  returning id into l_id;
  
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select a.lsk, -1*sum(penya) as penya, a.dopl, init.get_date as dtek, sysdate as ts, 
     l_user as fk_user, l_id as fk_doc
  from (
  select t.lsk, t.penya as penya, t.mg1 as dopl
    from a_penya t where t.lsk=p_lsk 
    and t.mg=utils.add_months_pr(init.get_period,-1)
  union all
  select t.lsk, t.penya, t.dopl from c_pen_corr t where t.lsk=p_lsk
  ) a
  group by a.lsk, a.dopl
  having sum(penya) > 0;
  
  if sql%rowcount = 0 then
    return 1;
  else
    return 0;
  end if;  
end;

--������� ����� ��������� ������ �� ���� �� ���� �������� �� �/� �� ������ �/c
function corr_sal_pen2(p_lsk in kart.lsk%type, p_lsk2 in kart.lsk%type)
    return number is
  l_id number;
  l_user number;
  l_comm c_change_docs.text%type;
  l_ret number;
  l_mg params.period%type;
begin
  select u.id, p.period into l_user, l_mg from t_user u, params p where u.cd=user; 
  l_comm:='������������� ��.������ �� ����';
  insert into c_change_docs
    (mgchange, dtek, ts, user_id, text)
  values 
    (l_mg, init.get_date, sysdate, l_user, l_comm)
  returning id into l_id;
  
  --��������� �� ������ �/c
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select p_lsk2 as lsk, sum(penya) as penya, a.dopl, init.get_date as dtek, sysdate as ts, 
     l_user as fk_user, l_id as fk_doc
  from (
  select t.lsk, t.penya as penya, t.mg1 as dopl
    from a_penya t where t.lsk=p_lsk
    and t.mg=utils.add_months_pr(init.get_period,-1)
  union all
  select t.lsk, t.penya, t.dopl from c_pen_corr t where t.lsk=p_lsk
  ) a
  group by a.dopl
  having sum(penya) > 0;

  l_ret:= sql%rowcount;

  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select a.lsk, -1*sum(penya) as penya, a.dopl, init.get_date as dtek, sysdate as ts, 
     l_user as fk_user, l_id as fk_doc
  from (
  select t.lsk, t.penya as penya, t.mg1 as dopl
    from a_penya t where t.lsk=p_lsk 
    and t.mg=utils.add_months_pr(init.get_period,-1)
  union all
  select t.lsk, t.penya, t.dopl from c_pen_corr t where t.lsk=p_lsk
  ) a
  group by a.lsk, a.dopl
  having sum(penya) > 0;

  if l_ret =0 or sql%rowcount = 0 then
    Raise_application_error(-20000, '1='||l_ret||', '||sql%rowcount);
    return 1;
  else
    return 0;
  end if;  
end;

end C_CPENYA;
/

