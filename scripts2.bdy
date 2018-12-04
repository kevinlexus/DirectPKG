create or replace package body scott.scripts2 is
--����� �������!

--����������� ������ � ����� ������ ��� (����������) �� ������
procedure swap_sal_chpay6 is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
begin
  l_mg:='201610'; --���.������
  l_cd:='swap_sal_chpay5_20161028_1';
  l_mgchange:=l_mg;
  l_dt:=to_date('20161028','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������

  dbms_output.enable;

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;


  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);
  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;


  for c in (select t.lsk, t.org, t.usl, abs(t.summa) as summa from saldo_usl t, usl u where t.mg='201611'
            and t.org in (2) and t.summa<0
            and t.usl=u.usl and u.usl in  ('005', '006')
        )
  loop
      --��������� �� ����� (�� ������� ��� � ���.��.)
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, n.usl , n.org, c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
           from nabor n where n.lsk=c.lsk and n.usl='009'; /* ������������� �����*/
      if sql%notfound then
        dbms_output.put_line('check lsk='||c.lsk||' usl='||c.usl);
      else
        --����� � �������, ���� ������� ���������� �� �����
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
          select c.lsk, c.usl, c.org, -1*c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
             from dual;
      end if;     
           
  end loop;
commit;
end swap_sal_chpay6;


--����������� ������ � ����� ������ ��� (����������) �� ������
procedure swap_sal_chpay7 is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
begin
  l_mg:='201610'; --���.������
  l_cd:='swap_sal_chpay5_20161028_2';
  l_mgchange:=l_mg;
  l_dt:=to_date('20161028','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������

  dbms_output.enable;

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;


  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);
  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;


  for c in (select t.lsk, t.org, t.usl, abs(t.summa) as summa from saldo_usl t, usl u where t.mg='201611'
            and t.org in (76) and t.summa<0
            and t.usl=u.usl and u.usl in  ('031', '046')
        )
  loop

      --��������� �� �����
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, n.usl , n.org, c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
           from nabor n where n.lsk=c.lsk and n.usl=c.usl
           and n.org=650; 
      if sql%notfound then
        dbms_output.put_line('check lsk='||c.lsk||' usl='||c.usl);
      else
        --����� � �������, ���� ������� ���������� �� �����
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
          select c.lsk, c.usl, c.org, -1*c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
             from dual;
      end if;     
           
  end loop;
commit;
end swap_sal_chpay7;

--����������� ������ � ����� ������ ��� (����������) �� ������
procedure swap_sal_chpay8 is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
begin
  l_mg:='201610'; --���.������
  l_cd:='swap_sal_chpay5_20161028_3';
  l_mgchange:=l_mg;
  l_dt:=to_date('20161028','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������

  dbms_output.enable(1000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;


  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);
  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;


  for c in (select k.k_lsk_id, t.lsk, t.org, t.usl, abs(t.summa) as summa from kart k, saldo_usl t, usl u, v_lsk_tp tp where t.mg='201610'
            and t.summa<0 and k.lsk=t.lsk and k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
            and t.usl=u.usl and u.usl in  ('033', '034')
        )
  loop

      --��������� �� ����� (�� ������� ��� � ���.��.)
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select k.lsk, n.usl , n.org, c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
           from kart k, nabor n, v_lsk_tp tp where k.k_lsk_id=c.k_lsk_id and n.usl='033'
           and k.lsk<>c.lsk and k.psch not in (8,9)
           and k.lsk=n.lsk and k.fk_tp=tp.id and tp.cd='LSK_TP_ADDIT';
      if sql%notfound then
        dbms_output.put_line('check lsk='||c.lsk||' usl='||c.usl);
      else
        --����� � �������, ���� ������� ���������� �� �����
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
          select c.lsk, c.usl, c.org, -1*c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
             from dual;
      end if;     
           
  end loop;
commit;
end swap_sal_chpay8;


--������������ ���������� ������ � ����� ������ ���(���) �� ������ ������
procedure swap_sal_chpay9 is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
begin
  l_mg:='201704'; --���.������
  l_cd:='swap_sal_chpay1_20170417';
  l_mgchange:=l_mg;
  l_dt:=to_date('20170414','YYYYMMDD');
--  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������
  l_mg3:=l_mg; --����� ������

  dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  for c in (select s.lsk, s.usl, s.org, s.summa, s.mg, u2.uslm
         from saldo_usl s join usl u2
        on s.summa < 0 and s.mg=l_mg3 and s.usl=u2.usl
        and s.usl in ('015', '016', '058', '007', '008', '056') --�� ���� �������
        and s.org=2
        join kart k on s.lsk=k.lsk
             --and k.house_id=39766 --�� ����� ���� 
        and exists
        (select t.* 
         from saldo_usl t-- ��� ���� �����.������ �� ������ �������
         where t.mg=s.mg and t.lsk=s.lsk
          --and s.org<>t.org and t.usl=u.usl and u.uslm=u2.uslm
          --and t.usl in ('054','026','055','007','008','056','011','012','031','046') --�� ������ ������
          and t.org=677 
          and t.summa > 0
        )
        )
  loop

  --���.�������� ������ ������
  l_kr:=abs(c.summa);

  --������������ ������
  gen.gen_saldo(c.lsk);

  --����� ��� ��� ������
  select abs(nvl(sum(t.summa),0)) into l_deb
         from saldo_usl t--, usl u
         where t.mg=c.mg and t.lsk=c.lsk
          --and t.org <> c.org and t.usl=u.usl 
          --and u.uslm=c.uslm
          --and t.usl in ('054','026','055','007','008','056','011','012','031','046') --�� ������ ������
          and t.org=677
          and t.summa > 0;
  --���������� ����� �� �����.������
  if l_kr >= l_deb then
    l_kr:=l_deb;
  end if;
          
  --��������� ������� ������. ������, 
  --�� ������, ��������� ������
  select rec_summ(t.usl, t.org, t.summa, 0)
         bulk collect into t_summ
         from saldo_usl t--, usl u
         where t.mg=c.mg and t.lsk=c.lsk
          --and t.org <> c.org and t.usl=u.usl
          --and u.uslm=c.uslm
          --and t.usl in ('054','026','055','007','008','056','011','012','031','046') --�� ������ ������
          and t.org=677
          and t.summa > 0;

  if t_summ.count > 0 then
    l_ret:=c_prep.dist_summa_full(p_sum => l_kr, t_summ => t_summ);
    for c2 in (select * from table(t_summ) t where t.tp=1)
    loop
      --����� � �������
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, c.usl, c.org, -1*c2.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
           from dual;

      --��������� �� �����
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, c2.fk_cd, c2.fk_id, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
           from dual;
    end loop;
  else
    dbms_output.put_line('�� ������ ����� �� �.�.'||c.lsk);
  end if;                                                                                                              
  end loop;
commit;
end swap_sal_chpay9;

--������������ ���������� ������ � ����� ������ ���(���) �� ������ ������
--����������� ������ � ����� ������ ��� (����������) �� ������
procedure swap_sal_with_pen10 is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
 l_lsk_tp number;
begin
  l_mg:='201612'; --���.������
  l_cd:='swap_sal_with_pen10_20161212';
  l_mgchange:=l_mg;
  l_dt:=to_date('20161212','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,-1); --����� �����
  
  select t.id into l_lsk_tp from v_lsk_tp t where t.cd='LSK_TP_MAIN';
  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;
  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;
   
  delete from c_change t where t.doc_id=l_id;
  delete from c_pen_corr t where t.fk_doc=l_id;
  
  --������
  --����� � ��
  insert into c_change
    (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id,
     doc_id)
    select k.lsk, t.usl, t.org, -1*t.summa, l_mg as mgchange, '999' as nkom, 0 as type,
     l_dt, sysdate, l_user, l_id
     from saldo_usl t, kart k where t.lsk=k.lsk and k.reu in ('88') and
       t.mg=l_mg and k.fk_tp=l_lsk_tp;
  --��������� �� ��
  insert into c_change
    (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id,
     doc_id)
    select k2.lsk, t.usl, t.org, t.summa, l_mg as mgchange, '999' as nkom, 0 as type,
     l_dt, sysdate, l_user, l_id
     from saldo_usl t, kart k, kart k2 where t.lsk=k.lsk and k.reu in ('88')
       and k.k_lsk_id=k2.k_lsk_id and k2.reu in ('41') and
       t.mg=l_mg and k.fk_tp=l_lsk_tp and k2.fk_tp=l_lsk_tp;
       
  --����
  --����� � ��
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
    select k.lsk, -1*t.penya, t.mg1, l_dt, sysdate, l_user, l_id
     from a_penya t, kart k where t.lsk=k.lsk and k.reu in ('88') and
       t.mg=l_mg3 and k.fk_tp=l_lsk_tp;
  --��������� �� ��
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
    select k2.lsk, t.penya, t.mg1, l_dt, sysdate, l_user, l_id
     from a_penya t, kart k, kart k2 where t.lsk=k.lsk and k.reu in ('88') and
       k.k_lsk_id=k2.k_lsk_id and k2.reu in ('41') and
       t.mg=l_mg3 and k.fk_tp=l_lsk_tp and k2.fk_tp=l_lsk_tp;
  
commit;
end swap_sal_with_pen10;

--������������ ���������� ������ �� ���������� - ��� ���.
procedure sub_ZERO_kis is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 l_kr2 number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
 l_coeff number;
 l_coeff2 number;
 l_itg_kr number;
 l_itg_db number;
 l_old_usl_kr usl.usl%type;
 l_old_org_kr number;
 l_old_usl_db usl.usl%type;
 l_old_org_db number;
begin
  l_mg:='201803'; --���.������
  l_cd:='swap_ZERO_kis_20170319';
  l_mgchange:=l_mg;
  l_dt:=to_date('20180319','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������, ���� ���� ��� �� ��� ������

  --l_mg3 := l_mg; -- ������ - ��.�� ������� �����

  dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;


  for c in (select distinct s.lsk, s.mg
         from saldo_usl s join usl u2
        on s.mg=l_mg3 and s.usl=u2.usl
        join kart k on s.lsk=k.lsk
        --and s.org = 676 -- ������������ ��������
        and k.reu in (
        '89','91','93','66','59','68','74','17','21','14','18','63','15','16','67','19','44','69','01','02','03','04','05',
        '06','07','08','09','10','36','78','29','54','27','57','25','12','38','52','70','81','95','35','94','41','26','96') --�� ���� ��
        --and k.reu not in ('87','82','73','80','76','85','86','84')
        --and k.house_id =39666 --�� ����� ����
        and s.summa < 0
        --and s.usl in ('007','008','056') --�� ���� �������
             --and k.lsk='14040757'
        --and exists (select * from a_kwtp_day d where d.mg between '201701' and '201702'
        --                     and d.lsk=k.lsk and d.fk_distr=15)
        and exists
        (select t.*
         from saldo_usl t-- ��� ���� �����.������ �� ������ ������� 14040763
         where t.mg=s.mg and t.lsk=s.lsk
          and t.summa > 0
          --and t.org<>677
        )
        )
  loop

  --����� ��� ���� � ��� ������
  select abs(nvl(sum(case when t.summa < 0 then t.summa else 0 end),0)),
         nvl(sum(case when t.summa > 0 then t.summa else 0 end),0)
          into l_kr2, l_deb
         from saldo_usl t
         where t.mg=c.mg
         and t.lsk=c.lsk
         --and (t.summa < 0 and t.usl in ('007','008','056') or t.summa > 0 and t.org <> 677)-- ������������ �������� ������ ������, ���� ��������� ��� ������ ������!
         ;

  --���������� ������ ����� �� �����.������
  if l_kr2 > l_deb then
    l_kr:=l_deb;
  else
    l_kr:=l_kr2;
  end if;

  -- ����� ����� ����������� ������ � �������
  l_coeff2:=l_kr/l_kr2;

  -- ����� ����� ��������� �� �����
  l_coeff:=l_kr/l_deb;

  --����� � �������
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff2,2) as summa from saldo_usl t
                 where t.mg=c.mg
                 and t.summa < 0
                 and t.lsk=c.lsk
                 --and t.org = 676 -- ������������ �������� ������ ������, ���� ��������� ��� ������ ������!
                 --and (t.summa < 0 and t.usl in ('007','008','056') or t.summa > 0 and t.org <> 677)-- ������������ �������� ������ ������, ���� ��������� ��� ������ ������!
                 and round(t.summa*l_coeff2,2) <> 0
                 ) loop

      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 1 as var
           from dual;
        l_old_usl_kr:=c2.usl;
        l_old_org_kr:=c2.org;

  end loop;

  --��������� �� �����
  l_old_usl_db:=null;
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff,2) as summa from saldo_usl t
                 where t.mg=c.mg
                 and t.summa > 0
                 and t.lsk=c.lsk
                 and round(t.summa*l_coeff,2) <> 0
                 ) loop
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 2 as var
           from dual;
        l_old_usl_db:=c2.usl;
        l_old_org_db:=c2.org;

  end loop;

  -- �� ���� ������� ��������� � ��������� �� ����� (������ ���� ������ =0.01 ���)
  if l_old_usl_db is null then
    for c3 in (select t.usl, t.org from saldo_usl t
           where t.lsk=c.lsk and t.mg=c.mg
           and t.summa > 0
           --and t.org <> 677
            order by t.summa desc) loop
      l_old_usl_db:=c3.usl;
      l_old_org_db:=c3.org;
      exit;
    end loop;
  end if;

  select sum(decode(t.var,1,t.summa,0)), sum(decode(t.var,2,t.summa,0))
      into l_itg_kr, l_itg_db
      from t_corrects_payments t where t.fk_doc=l_id
      and t.lsk=c.lsk;
  -- ���������
  if l_kr=l_kr2 then
    -- ���� ������ ������ ��� ����� ����������
    -- ���� ����� � ����!
    for c2 in (
          select a.usl, a.org, sum(a.summa) as summa from (
          select t.usl, t.org, t.summa from saldo_usl t where
                       t.mg=c.mg
                       and t.summa < 0 -- ������.������
                       --and t.usl in ('007','008','056')
                       and t.lsk=c.lsk
                       --and t.org = 676-- ������������ �������� ������ ������, ���� ��������� ��� ������ ������!

          union all
          select t.usl, t.org, -1*t.summa from t_corrects_payments t where
                       t.mg=l_mg
                       and t.lsk=c.lsk -- ������������� ��� ������
                       and t.fk_doc=l_id
                       and t.var=1) a
          group by a.usl, a.org
          having sum(a.summa) <> 0 )
           loop
          -- ������ ��������� �� ���������, ����� ���
          if abs(c2.summa) <> 0.01 then
            Raise_application_error(-20000, '������������ ���������� #1! ��='||c.lsk||' summa='||to_char(c2.summa));
          end if;
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
            select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, -1 as var
               from dual;
    end loop;
  else
    -- ������ ���������� �� ����������
    if (-1*l_kr <> l_itg_kr) then
    --��������� ��� ����� ��������� ����� �����������
          if abs(-1*l_kr - l_itg_kr) > 0.05 then
            Raise_application_error(-20000, '������������ ���������� #2! ��='||c.lsk||' summa='||to_char(-1*l_kr - l_itg_kr));
          end if;
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
            select c.lsk, l_old_usl_kr, l_old_org_kr, (-1*l_kr - l_itg_kr), uid, l_dt, l_mg, l_mg, l_id, -1 as var
               from dual;
    end if;
  end if;

  -- ��������� ��������� ���������� ������
    if (l_kr <> l_itg_db) then
    --��������� ��� ����� ��������� ����� �����������
          if abs(l_kr - l_itg_db) > 0.05 then
            Raise_application_error(-20000, '������������ ���������� #3! ��='||c.lsk||' summa='||to_char(l_kr - l_itg_db));
          end if;
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
            select c.lsk, l_old_usl_db, l_old_org_db, (l_kr - l_itg_db), uid, l_dt, l_mg, l_mg, l_id, -2 as var
               from dual;
    end if;

  commit;

  -- ��� ��� ���������
  select sum(decode(t.var,1,t.summa,-1,t.summa,0)), sum(decode(t.var,2,t.summa,-2,t.summa,0))
      into l_itg_kr, l_itg_db
      from t_corrects_payments t where t.mg=l_mg and t.fk_doc=l_id
      and t.lsk=c.lsk;

    if (abs(l_itg_kr) <> abs(l_itg_db)) then
      Raise_application_error(-20000, '������������ ���������� #4! ��='||c.lsk||' summa='||to_char(abs(l_itg_kr) -  abs(l_itg_db)));
    end if;


  end loop;

  -- ������� ������� var
  update t_corrects_payments t set t.var=0
    where t.mg=l_mg and t.fk_doc=l_id;

  -- �������� � kwtp_day
  c_gen_pay.dist_pay_del_corr;
  c_gen_pay.dist_pay_add_corr(var_ => 0);

commit;
end sub_ZERO_kis;

--������������ ���������� ������ �� ���������� - ��� �����.
procedure sub_ZERO_polis is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 l_kr2 number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
 l_coeff number;
 l_coeff2 number;
 l_itg_kr number;
 l_itg_db number;
 l_old_usl_kr usl.usl%type;
 l_old_org_kr number; 
 l_old_usl_db usl.usl%type;
 l_old_org_db number; 
begin
  l_mg:='201711'; --���.������
  l_cd:='swap_ZERO_polis_20171130';
  l_mgchange:=l_mg;
  l_dt:=to_date('20171130','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������, ���� ���� ��� �� ��� ������
  
  --l_mg3 := l_mg; -- ������ - ��.�� ������� ����� 
  
  dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;


  for c in (select distinct s.lsk, s.mg
         from saldo_usl s join usl u2
        on s.mg=l_mg3 and s.usl=u2.usl
        join kart k on s.lsk=k.lsk
        and k.reu in ('35') --�� ���� ��
        and s.summa < 0
        and s.usl in ('007','056') --�� ���� �������
        and exists
        (select t.* 
         from saldo_usl t-- ��� ���� �����.������ �� ������ �������
         where t.mg=s.mg and t.lsk=s.lsk
          and t.summa > 0
          and t.usl in ('007','056') --�� ���� �������
        )
        )
  loop

  --����� ��� ���� � ��� ������
  select abs(nvl(sum(case when t.summa < 0 then t.summa else 0 end),0)),
         nvl(sum(case when t.summa > 0 then t.summa else 0 end),0)
          into l_kr2, l_deb
         from saldo_usl t
         where t.mg=c.mg 
         and t.lsk=c.lsk
          and t.usl in ('007','056') --�� ���� �������
         ;
         
  --���������� ������ ����� �� �����.������
  if l_kr2 > l_deb then
    l_kr:=l_deb;
  else
    l_kr:=l_kr2;  
  end if;

  -- ����� ����� ����������� ������ � �������
  l_coeff2:=l_kr/l_kr2;

  -- ����� ����� ��������� �� �����
  l_coeff:=l_kr/l_deb;
  
  --����� � �������
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff2,2) as summa from saldo_usl t 
                 where t.mg=c.mg
                 and t.summa < 0 
                 and t.lsk=c.lsk
                 and t.usl in ('007','056') --�� ���� �������
                 and round(t.summa*l_coeff2,2) <> 0
                 ) loop
                 
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 1 as var
           from dual;
        l_old_usl_kr:=c2.usl;   
        l_old_org_kr:=c2.org;   
                 
  end loop;

  --��������� �� �����
  l_old_usl_db:=null;
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff,2) as summa from saldo_usl t 
                 where t.mg=c.mg
                 and t.summa > 0 
                 and t.lsk=c.lsk
                 and t.usl in ('007','056') --�� ���� �������
                 and round(t.summa*l_coeff,2) <> 0
                 ) loop
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 2 as var
           from dual;
        l_old_usl_db:=c2.usl;   
        l_old_org_db:=c2.org;   
                 
  end loop;
  
  -- �� ���� ������� ��������� � ��������� �� ����� (������ ���� ������ =0.01 ���)
  if l_old_usl_db is null then
    for c3 in (select t.usl, t.org from saldo_usl t 
           where t.lsk=c.lsk and t.mg=c.mg
           and t.summa > 0
           --and t.org <> 677
            order by t.summa desc) loop
      l_old_usl_db:=c3.usl;   
      l_old_org_db:=c3.org;   
      exit;
    end loop;
  end if;
  
  select sum(decode(t.var,1,t.summa,0)), sum(decode(t.var,2,t.summa,0))
      into l_itg_kr, l_itg_db 
      from t_corrects_payments t where t.fk_doc=l_id
      and t.lsk=c.lsk;
  -- ���������
  if l_kr=l_kr2 then
    -- ���� ������ ������ ��� ����� ����������
    -- ���� ����� � ����!  
    for c2 in (
          select a.usl, a.org, sum(a.summa) as summa from (
          select t.usl, t.org, t.summa from saldo_usl t where 
                       t.mg=c.mg
                       and t.summa < 0 -- ������.������
                       and t.usl in ('007','056') --�� ���� �������
                       and t.lsk=c.lsk
          union all
          select t.usl, t.org, -1*t.summa from t_corrects_payments t where 
                       t.mg=l_mg
                       and t.lsk=c.lsk -- ������������� ��� ������
                       and t.fk_doc=l_id
                       and t.var=1) a
          group by a.usl, a.org
          having sum(a.summa) <> 0 )
           loop
          -- ������ ��������� �� ���������, ����� ��� 
          if abs(c2.summa) <> 0.01 then
            Raise_application_error(-20000, '������������ ���������� #1! ��='||c.lsk||' summa='||to_char(c2.summa));
          end if;    
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
            select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, -1 as var
               from dual;
    end loop;
  else
    -- ������ ���������� �� ���������� 
    if (-1*l_kr <> l_itg_kr) then
    --��������� ��� ����� ��������� ����� �����������
          if abs(-1*l_kr - l_itg_kr) > 0.05 then
            Raise_application_error(-20000, '������������ ���������� #2! ��='||c.lsk||' summa='||to_char(-1*l_kr - l_itg_kr));
          end if;    
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
            select c.lsk, l_old_usl_kr, l_old_org_kr, (-1*l_kr - l_itg_kr), uid, l_dt, l_mg, l_mg, l_id, -1 as var
               from dual;
    end if;
  end if;
  
  -- ��������� ��������� ���������� ������
    if (l_kr <> l_itg_db) then
    --��������� ��� ����� ��������� ����� �����������
          if abs(l_kr - l_itg_db) > 0.05 then
            Raise_application_error(-20000, '������������ ���������� #3! ��='||c.lsk||' summa='||to_char(l_kr - l_itg_db));
          end if;    
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
            select c.lsk, l_old_usl_db, l_old_org_db, (l_kr - l_itg_db), uid, l_dt, l_mg, l_mg, l_id, -2 as var
               from dual;
    end if;
  
  commit;
  
  -- ��� ��� ���������         
  select sum(decode(t.var,1,t.summa,-1,t.summa,0)), sum(decode(t.var,2,t.summa,-2,t.summa,0))
      into l_itg_kr, l_itg_db 
      from t_corrects_payments t where t.mg=l_mg and t.fk_doc=l_id
      and t.lsk=c.lsk;

    if (abs(l_itg_kr) <> abs(l_itg_db)) then
      Raise_application_error(-20000, '������������ ���������� #4! ��='||c.lsk||' summa='||to_char(abs(l_itg_kr) -  abs(l_itg_db)));
    end if;    


  end loop;

  -- ������� ������� var
  update t_corrects_payments t set t.var=0
    where t.mg=l_mg and t.fk_doc=l_id;

  -- �������� � kwtp_day
  c_gen_pay.dist_pay_del_corr;
  c_gen_pay.dist_pay_add_corr(var_ => 0);    

commit;
end sub_ZERO_polis;


-- ������������ ���������� ������ �� ���������� - ��� �����. 
-- �� ������������ ������� � ��� - ������� ���������
-- �������������� ��������� saldo_usl_script
-- ��������� ������!!!
-- �������� ��� ����� ��������:
/*delete from SALDO_USL_SCRIPT t;
insert into SALDO_USL_SCRIPT
  (lsk, usl, org, summa, mg, uslm)
select lsk, usl, org, summa, mg, uslm
from saldo_usl t where t.mg='201806'*/
procedure sub_ZERO_polis_main is 
  -- ��������� ���������, ��� ������ ����     
  t_tmp_reu scott.tab_tmp;
  t_tmp_usl scott.tab_tmp;
  t_tmp_org scott.tab_tmp;
begin
  dbms_output.enable(2000000);

  
  for c in (select distinct org from (
            select a.lsk, a.org, a.uslm, count(*) as cnt from 
            (
              select t.lsk, t.org, u.uslm, u.usl, sum(t.summa) as summa
                from saldo_usl_script t, usl u where
                t.usl=u.usl
              group by t.lsk, t.org, u.uslm, u.usl
              having sum(t.summa)<>0
              ) a
              group by a.lsk, a.org, a.uslm
              having count(*)>1
            )) loop
    sub_ZERO_polis_usl(t_tmp_usl, t_tmp_org, t_tmp_reu, 
      c.org, c.org, '201803', gdt(29,0,0));
  end loop;

end;

-- ������������ ���������� ������ �� ���������� - ��� �����. �� ������������ ������� � ���
procedure sub_ZERO_polis_usl(p_tmp_usl in scott.tab_tmp, -- ������ ����� (���� �� ������������)
                             p_tmp_org in scott.tab_tmp,  -- ������ ����������� (���� �� ������������)
                             p_tmp_reu in scott.tab_tmp,  -- ������ ��  (���� �� ������������)
                             p_org in number,  -- �����������
                             p_mark in varchar2, -- ������
                             p_mg in varchar2, -- ������� ������,
                             p_dat in date -- ���� ��������
                             ) is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 l_kr2 number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
 l_coeff number;
 l_coeff2 number;
 l_itg_kr number;
 l_itg_db number;
 l_old_usl_kr usl.usl%type;
 l_old_org_kr number; 
 l_old_usl_db usl.usl%type;
 l_old_org_db number; 
 l_iter number;
begin
  l_mg:=p_mg; --���.������
  l_cd:='SWP_ZR_p_usl_'||to_char(p_dat,'YYYYMMDD')||'_'||p_mark;
  l_mgchange:=l_mg;
  l_dt:=p_dat;
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������, ���� ���� �� ��� ������
  
  --l_mg3 := l_mg; -- ������ - ��.�� ������� ����� 
  
  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  dbms_output.put_line('p_org='||p_org);
  l_iter:=0;
  for c in (select distinct s.lsk, s.mg, u2.uslm
         from saldo_usl_script s join usl u2
        on s.mg=l_mg3 and s.usl=u2.usl
        join kart k on s.lsk=k.lsk
        --and k.reu in ('35') --�� ���� ��
        and s.summa < 0
        and s.org=p_org
        and exists
        (select t.* 
         from saldo_usl_script t, usl m-- ��� ���� �����.������ �� ������ �������, �������� � ������� ������
         where t.mg=s.mg and t.lsk=s.lsk
          and t.summa > 0
          
          and t.usl=m.usl
          and t.org=p_org
          and m.uslm=u2.uslm and m.usl<>u2.usl
        )
        )
  loop
  l_iter:=l_iter+1;

  dbms_output.put_line('lsk='||c.lsk||' iter='||l_iter);
  --����� ��� ���� � ��� ������
  select abs(nvl(sum(case when t.summa < 0 then t.summa else 0 end),0)),
         nvl(sum(case when t.summa > 0 then t.summa else 0 end),0)
          into l_kr2, l_deb
         from saldo_usl_script t, usl m
         where t.mg=c.mg 
         and t.lsk=c.lsk
         
          and t.org=p_org
          and t.usl=m.usl
          and m.uslm=c.uslm;
         
  --���������� ������ ����� �� �����.������
  if l_kr2 > l_deb then
    l_kr:=l_deb;
  else
    l_kr:=l_kr2;  
  end if;

  -- ����� ����� ����������� ������ � �������
  l_coeff2:=l_kr/l_kr2;

  -- ����� ����� ��������� �� �����
  l_coeff:=l_kr/l_deb;
  
  --����� � �������
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff2,2) as summa 
                 from saldo_usl_script t, usl m
                 where t.mg=c.mg
                 and t.summa < 0 
                 and t.lsk=c.lsk

                  and t.org=p_org
                  and t.usl=m.usl
                  and m.uslm=c.uslm

                 and round(t.summa*l_coeff2,2) <> 0
                 ) loop
                 
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
        select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 1 as var, l_iter
           from dual;
        l_old_usl_kr:=c2.usl;   
        l_old_org_kr:=c2.org;   
                 
  end loop;

  --��������� �� �����
  l_old_usl_db:=null;
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff,2) as summa 
                 from saldo_usl_script t, usl m
                 where t.mg=c.mg
                 and t.summa > 0 
                 and t.lsk=c.lsk

                  and t.org=p_org
                  and t.usl=m.usl
                  and m.uslm=c.uslm

                 and round(t.summa*l_coeff,2) <> 0
                 ) loop
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
        select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 2 as var, l_iter
           from dual;
        l_old_usl_db:=c2.usl;   
        l_old_org_db:=c2.org;   
                 
  end loop;
  
  -- �� ���� ������� ��������� � ��������� �� ����� (������ ���� ������ =0.01 ���)
  if l_old_usl_db is null then
    for c3 in (select t.usl, t.org from saldo_usl_script t, usl m
           where t.lsk=c.lsk and t.mg=c.mg

            and t.org=p_org
            and t.usl=m.usl
            and m.uslm=c.uslm

           and t.summa > 0
            order by t.summa desc) loop
      l_old_usl_db:=c3.usl;   
      l_old_org_db:=c3.org;   
      exit;
    end loop;
  end if;
  
  select sum(decode(t.var,1,t.summa,0)), sum(decode(t.var,2,t.summa,0))
      into l_itg_kr, l_itg_db 
      from t_corrects_payments t where t.fk_doc=l_id
      and t.lsk=c.lsk and t.iter=l_iter;
  -- ���������
  if l_kr=l_kr2 then
    -- ���� ������ ������ ��� ����� ����������
    -- ���� ����� � ����!  
    for c2 in (
          select a.usl, a.org, sum(a.summa) as summa from (
          select t.usl, t.org, t.summa from saldo_usl_script t, usl m where 
                       t.mg=c.mg
                       and t.summa < 0 -- ������.������

                        and t.org=p_org
                        and t.usl=m.usl
                        and m.uslm=c.uslm

                       and t.lsk=c.lsk
          union all
          select t.usl, t.org, -1*t.summa from t_corrects_payments t where 
                       t.mg=l_mg
                       and t.lsk=c.lsk -- ������������� ��� ������
                       and t.fk_doc=l_id
                       and t.var=1 
                       and t.iter=l_iter
                       ) a
          group by a.usl, a.org
          having sum(a.summa) <> 0 )
           loop
          -- ������ ��������� �� ���������, ����� ��� 
          if abs(c2.summa) <> 0.01 then
            Raise_application_error(-20000, '������������ ���������� #1! ��='||c.lsk||' summa='||to_char(c2.summa));
          end if;    
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
            select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, -1 as var, l_iter
               from dual;
    end loop;
  else
    -- ������ ���������� �� ���������� 
    if (-1*l_kr <> l_itg_kr) then
    --��������� ��� ����� ��������� ����� �����������
          if abs(-1*l_kr - l_itg_kr) > 0.05 then
            Raise_application_error(-20000, '������������ ���������� #2! ��='||c.lsk||' summa='||to_char(-1*l_kr - l_itg_kr));
          end if;    
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
            select c.lsk, l_old_usl_kr, l_old_org_kr, (-1*l_kr - l_itg_kr), uid, l_dt, l_mg, l_mg, l_id, -1 as var, l_iter
               from dual;
    end if;
  end if;
  
  -- ��������� ��������� ���������� ������
    if (l_kr <> l_itg_db) then
    --��������� ��� ����� ��������� ����� �����������
          if abs(l_kr - l_itg_db) > 0.05 then
            Raise_application_error(-20000, '������������ ���������� #3! ��='||c.lsk||' summa='||to_char(l_kr - l_itg_db));
          end if;    
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
            select c.lsk, l_old_usl_db, l_old_org_db, (l_kr - l_itg_db), uid, l_dt, l_mg, l_mg, l_id, -2 as var, l_iter
               from dual;
    end if;
  
  commit;
  
  -- ��� ��� ���������         
  select sum(decode(t.var,1,t.summa,-1,t.summa,0)), sum(decode(t.var,2,t.summa,-2,t.summa,0))
      into l_itg_kr, l_itg_db 
      from t_corrects_payments t where t.mg=l_mg and t.fk_doc=l_id
      and t.lsk=c.lsk and t.iter=l_iter;

    if (abs(l_itg_kr) <> abs(l_itg_db)) then
      Raise_application_error(-20000, '������������ ���������� #4! ��='||c.lsk||' summa='||to_char(abs(l_itg_kr) -  abs(l_itg_db)));
    end if;    


  end loop;

  -- ������� ������� var
  update t_corrects_payments t set t.var=0
    where t.mg=l_mg and t.fk_doc=l_id;

  -- �������� � kwtp_day
  c_gen_pay.dist_pay_del_corr;
  c_gen_pay.dist_pay_add_corr(var_ => 0);    

commit;
end sub_ZERO_polis_usl;

procedure swap_oborot3 is
  mgchange_ c_change.mgchange%type;
  comment_ c_change_docs.text%type;
  mg_ params.period%type;
  user_id_ number;
  cd_ c_change_docs.text%type;
  dat_ c_change.dtek%type;
  changes_id_ number;
begin
--���������� ������ �� �� (�����)
--c ����� ���. �� ������
--������, ������� �������� ���������
mgchange_:='201710';
--�����������
comment_:='��������� ������ �� ��';
--���������� ����� ����������
cd_:='01';
--���� ����������
dat_:=to_date('11102017','DDMMYYYY');
select t.id into user_id_ from t_user t where t.cd='SCOTT';

delete from c_change t where t.user_id=user_id_
 and exists (select * from
 c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.doc_id);
delete from c_change_docs t where t.user_id=user_id_ and t.text=cd_;

select changes_id.nextval into changes_id_ from dual;

insert into c_change_docs (id, mgchange, dtek, ts, user_id, text)
select changes_id_, mgchange_, dat_, sysdate, user_id_, cd_
 from dual;

  insert into c_change (lsk, org, usl, summa, mgchange, type, dtek, ts,
  user_id, doc_id)
  select s.lsk, s.org, s.usl, -1 * s.summa as summa,
   mgchange_, null, dat_, sysdate, user_id_, changes_id_
   from saldo_usl s, kart k, t_org o, work_houses h
    where s.lsk=k.lsk and k.reu=o.reu
    and s.mg=mgchange_ and h.id=k.house_id
    union all
  select s.lsk, s.org, s.usl, s.summa as summa,
   mgchange_, null, dat_, sysdate, user_id_, changes_id_
   from saldo_usl s, kart k, kart k2, t_org o, work_houses h
    where s.lsk=k.lsk and k.reu=o.reu
    and s.mg=mgchange_ and h.id=k.house_id
    and k.k_lsk_id = k2.k_lsk_id
    and k2.psch <>8;


commit;
end swap_oborot3;

-- ������� ������
function chooseUsl(p_usl in varchar2, p_usl1 in varchar2, p_usl2 in varchar2) return varchar2 is
 l_usl varchar2(3);
begin
  if p_usl =p_usl1 then
    l_usl:=p_usl2;
  else
    l_usl:=p_usl1;
  end if;  
 return l_usl;
end;
  
-- ��������� ���������� ������ � ����� ��� �� ������ (�����)
-- ����� �������� �� ���������� ������, ��� ����� ����� ������� ��� �������������,
-- ������������ ����� "������" � �������� ������������, �������� ��� ��������, � ����� ������� ������������ ������
procedure swap_sal_chpay10 is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
begin
  l_mg:='201802'; --���.������
  l_cd:='swap_sal_chpay10_20180227';
  l_mgchange:=l_mg;
  l_dt:=to_date('20180227','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������
  --l_mg3:=l_mg;
  --dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

    
-- ������� �����.
  -- �����
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('056', '007')
    where s.mg=l_mg3
    and s.usl in ('056', '007')
    and s.summa < 0
    and s.org = 677;
    
 -- ���������   
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '056', '007', '007', '056') ,s.org, 
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('056', '007')
    where s.mg=l_mg3
    and s.usl in ('056', '007')
    and s.summa < 0
    and s.org = 677;

  -- �����
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('058', '015')
    where s.mg=l_mg3
    and s.usl in ('058', '015')
    and s.summa < 0
    and s.org = 677;
    
 -- ���������   
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '058', '015', '015', '058') ,s.org, 
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('058', '015')
    where s.mg=l_mg3
    and s.usl in ('058', '015')
    and s.summa < 0
    and s.org = 677;


-- �� ��. � �������.
  -- �����
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('057', '011')
    where s.mg=l_mg3
    and s.usl in ('057', '011')
    and s.summa < 0
    and s.org in (2,3,78,29);
    
 -- ���������   
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '057', '011', '011', '057') ,s.org, 
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('057', '011')
    where s.mg=l_mg3
    and s.usl in ('057', '011')
    and s.summa < 0
    and s.org in (2,3,78,29);

  -- �����
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('013', '059')
    where s.mg=l_mg3
    and s.usl in ('013', '059')
    and s.summa < 0
    and s.org in (2,3,78,29);
    
 -- ���������   
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '013', '059', '059', '013') ,s.org, 
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('013', '059')
    where s.mg=l_mg3
    and s.usl in ('013', '059')
    and s.summa < 0
    and s.org in (2,3,78,29);



-- ��� �����.�������� (��������� ��������������!!!)

  -- �.����
  -- �����
/*  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('057', '011')
    where s.mg=l_mg3
    and s.usl in ('057', '011')
    and s.summa < 0
    and s.org in (7);
    
 -- ���������   
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '057', '011', '011', '057'), 29 as org, 
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('057', '011')
    where s.mg=l_mg3
    and s.usl in ('057', '011')
    and s.summa < 0
    and s.org in (7);

  -- �������
  -- �����
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('059', '013')
    where s.mg=l_mg3
    and s.usl in ('059', '013')
    and s.summa < 0
    and s.org in (7);
    
 -- ���������   
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '059', '013', '013', '059'), 29 as org, 
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s       
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('059', '013')
    where s.mg=l_mg3
    and s.usl in ('059', '013')
    and s.summa < 0
    and s.org in (7);
*/
-- ��.�� � ��� 

  -- �����
/*  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('103', '053')
    where s.mg=l_mg3
    and s.summa < 0
    and s.usl in ('103', '053');
    
 -- ���������   
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '103', '053', '053', '103') ,s.org, 
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('103', '053')
    where s.mg=l_mg3
    and s.summa < 0
    and s.usl in ('103', '053');
*/
--������ ����
delete from t_corrects_payments t where t.summa = 0 and t.fk_doc=l_id;
commit;
end swap_sal_chpay10;


-- ��������� ������ � ����� ��� �� ������ (�����)
procedure swap_sal_chpay11 is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
begin
  l_mg:='201803'; --���.������
  l_cd:='swap_sal_chpay11_20180328';
  l_mgchange:=l_mg;
  l_dt:=to_date('20180328','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������
  --l_mg3:=l_mg;
  --dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  -- �����
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select k.lsk, s.usl ,s.org, 
    s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl_script s, kart k, kart k2
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    and k.k_lsk_id=k2.k_lsk_id
    and k.house_id=39766 
    and k.reu in ('01')
    and k2.reu in ('13')
    and s.usl in ('013', '014')
    and s.summa < 0
    and s.org = 7;

 -- ���������   
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select k2.lsk, s.usl ,s.org, 
    -1*s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl_script s, kart k, kart k2
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    and k.k_lsk_id=k2.k_lsk_id
    and k.house_id=39766 
    and k.reu in ('01')
    and k2.reu in ('13')
    and s.usl in ('013', '014')
    and s.summa < 0
    and s.org = 7;

commit;
end swap_sal_chpay11;


procedure swap_sal_chpay11_2 is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
begin
  l_mg:='201803'; --���.������
  l_cd:='swap_sal_chpay11_2_20180328';
  l_mgchange:=l_mg;
  l_dt:=to_date('20180328','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������
  --l_mg3:=l_mg;
  --dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  -- �����
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl_script s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    --and k.reu in ('01','13')
    and k.house_id in (37865,37849,37879,37888,37896)
    and s.usl in ('095')
    and s.summa < 0
    and s.org = 78;

 -- ���������   
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, '003' as usl , s.org, 
    -1*s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl_script s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    --and k.reu in ('01','13')
    and k.house_id in (37865,37849,37879,37888,37896)
    and s.usl in ('095')
    and s.summa < 0
    and s.org = 78;

commit;
end swap_sal_chpay11_2;

procedure swap_sal_chpay11_3 is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
begin
  l_mg:='201802'; --���.������
  l_cd:='swap_sal_chpay11_20180228';
  l_mgchange:=l_mg;
  l_dt:=to_date('20180228','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������
  --l_mg3:=l_mg;
  --dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  -- �����
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    --and k.reu in ('01','13')
    and s.usl in ('056', '058')
    and s.summa < 0
    and s.org = 677;

 -- ���������   
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '056','007','058','015') as usl , s.org, 
    -1*s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    --and k.reu in ('01','13')
    and s.usl in ('056', '058')
    and s.summa < 0
    and s.org = 677;

  -- �����
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    --and k.reu in ('01','13')
    and s.usl in ('057', '059')
    and s.summa < 0
    and s.org in (78,2,3,29);

 -- ���������   
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '057','011','059','013') as usl , s.org, 
    -1*s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    --and k.reu in ('01','13')
    and s.usl in ('057', '059')
    and s.summa < 0
    and s.org in (78,2,3,29);

commit;
end swap_sal_chpay11_3;

-- ��������� ����� ������ � ����� ��� �� ������ (�����)
procedure swap_sal_chpay12 is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
begin
  l_mg:='201711'; --���.������
  l_cd:='swap_sal_chpay11_20171029';
  l_mgchange:=l_mg;
  l_dt:=to_date('20171129','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������
  --l_mg3:=l_mg;
  --dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

    
  -- �����
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch not in (8,9)
    and s.usl in ('031')
    and s.summa < 0
    and s.org = 650;
    
 -- ���������   
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, '031' as usl , 690 as org, 
    -1*s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch not in (8,9)
    and s.usl in ('031')
    and s.summa < 0
    and s.org = 650;

  -- �����
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch not in (8,9)
    and s.usl in ('054')
    and s.summa < 0
    and s.org = 674;
    
 -- ���������   
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, '054' as usl , 690 as org, 
    -1*s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch not in (8,9)
    and s.usl in ('054')
    and s.summa < 0
    and s.org = 674;

--������ ����
delete from t_corrects_payments t where t.summa = 0 and t.fk_doc=l_id;
commit;
end swap_sal_chpay12;

-- ��������� ������ ������ � ������ (�����)
procedure swap_sal_chpay13 is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
begin
  l_mg:='201712'; --���.������
  l_cd:='swap_sal_chpay13_20171227';
  l_mgchange:=l_mg;
  l_dt:=to_date('20171227','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������
  l_mg3:=l_mg;
  --dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

    
  -- �����
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch in (9)
    and s.usl in ('003','013','052')
    and s.summa < 0
    and s.org = 3;
    
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch in (9)
    and s.usl in ('003','052')
    and s.summa < 0
    and s.org = 2;

  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch in (9)
    and s.usl in ('003','052')
    and s.summa < 0
    and s.org = 78;

  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch in (9)
    and s.usl in ('031')
    and s.summa < 0
    and s.org = 650;

  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org, 
    s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch in (9)
    and s.usl in ('054')
    and s.summa < 0
    and s.org = 674;
    
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,  
    s.summa, 
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch in (9)
    and s.usl in ('011','013')
    and s.summa < 0
    and s.org = 7;
    
    
commit;
end swap_sal_chpay13;

--������� ����� ������ � fk_lsk_tp
procedure cr_new_xitog3(p_mg in params.period%type) is
begin
    delete from xitog3 where mg = p_mg;
    insert into xitog3 t
      (reu,
       trest,
       kul,
       nd,
       org,
       usl,
       uslm,
       status,
       indebet,
       inkredit,
       charges,
       poutsal,
       changes,
       ch_full,
       changes2,
       subsid,
       privs,
       payment,
       pn,
       outdebet,
       outkredit,
       fk_lsk_tp,
       mg)
      select s.reu,
             s.trest,
             k.kul,
             k.nd,
             x.org,
             x.usl,
             x.uslm,
             k.status,
             sum(x.indebet),
             sum(x.inkredit),
             sum(x.charges),
             sum(x.poutsal),
             sum(x.changes),
             sum(x.ch_full),
             sum(x.changes2),
             sum(x.subsid),
             sum(x.privs),
             sum(x.payment),
             sum(x.pn),
             sum(x.outdebet),
             sum(x.outkredit),
             k.fk_tp,
             x.mg
        from xitog3_lsk x, kart k, s_reu_trest s
       where x.mg = p_mg
         and x.lsk = k.lsk
         and k.reu = s.reu
       group by s.reu,
                s.trest,
                k.kul,
                k.nd,
                x.org,
                x.usl,
                x.uslm,
                k.status,
                x.mg,
                k.fk_tp;

    delete from t_saldo_reu_kul_nd_st;
    insert into t_saldo_reu_kul_nd_st
      (reu, kul, nd, status, org, usl, fk_lsk_tp)
      select distinct t.reu, t.kul, t.nd, t.status, t.org, t.usl, nvl(t.fk_lsk_tp,0) as fk_lsk_tp
        from xitog3 t;
    commit;                    
end;


--������� ����� �������, ��������� �� ��� ���� � ���� (�� ��������, ����������� ������ ������)
/*procedure cr_new_lsk_with_deb is
  l_mg params.period%type;
  l_mg_sal params.period%type;
  l_user number;  
  l_id number;  
  l_dt date;
  l_cd c_change_docs.cd_tp%type;
  l_dst_uk t_org.reu%type; -- �� ����������
  l_dst_lsk kart.lsk%type; --�� ����������
begin
  dbms_output.enable(1000000);
  
  l_mg:='201705'; --���.������
  l_dt:=gdt(30,5,2017);
  l_cd:='swap_sal_chpay5_'||to_char(l_dt,'YYYYMMDD')||'_1';
  l_mg_sal:='201705'; --������ �� �������� �������� ������

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;


  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change a where exists 
    (select * from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd and t.id=a.doc_id
                );
  delete from c_pen_corr a where exists 
    (select * from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd and t.id=a.fk_doc
                );
  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mg, l_dt, sysdate, l_user, l_cd
   from dual;


  for c in (select t.* from saldo_usl t where t.mg=l_mg_sal and exists
                    (select * from kmp_lsk m where m.lsk=t.lsk)) loop
                    
  
  --������
  --����� � ��
  insert into c_change
    (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id,
     doc_id)
    select t.lsk, t.usl, t.org, -1*t.summa, l_mg as mgchange, '999' as nkom, 0 as type,
     l_dt, sysdate, l_user, l_id
     from saldo_usl t where t.lsk=c.lsk;
     
  l_dst_lsk:=p_houses.find_unq_lsk(p_reu => l_dst_uk, p_lsk => null);
  
  --��������� �� ����� �� � ��
  insert into c_change
    (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id,
     doc_id)
    select l_dst_lsk, t.usl, t.org, t.summa, l_mg as mgchange, '999' as nkom, 0 as type,
     l_dt, sysdate, l_user, l_id
     from saldo_usl t where t.lsk=c.lsk;
                  
                    
                    
  null;                  

  end loop;

end;*/

/*procedure move_kart_pr(p_lsk in kart.lsk%type) is 
begin
  
 for c in (select * from kart k, v_lsk_tp tp where 
     k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
     ) loop
     move_kart_pr_lsk(c.lsk);
     
 end loop;


end;  */

-- ��������� ����������� �� ��������� ��. �� ��������������
/*procedure move_kart_pr_lsk(p_lsk in kart.lsk%type) is 
begin
  
  delete from c_states_pr_kmp s;


  insert into c_states_pr_kmp
    (id, fk_status, fk_kart_pr, dt1, dt2, fk_tp)
  select id, fk_status, fk_kart_pr, dt1, dt2, fk_tp
  from c_states_pr s where exists
  (select t.* from c_KART_pr t where t.lsk=p_lsk
   and t.id=s.id
  );

  delete from c_kart_pr_kmp t where t.lsk=p_lsk;
  insert into c_kart_pr_kmp
  select id, lsk, fio, status, dat_rog, pol, dok, dok_c, dok_n, dok_d, dok_v, dat_prop, dat_ub, relat_id, old_id, status_dat, status_chng, k_fam, k_im, k_ot, fk_doc_tp, fk_nac, b_place, fk_frm_cntr, fk_frm_regn, fk_frm_distr, frm_town, frm_dat, fk_frm_kul, frm_nd, frm_kw, w_place, fk_ub, fk_to_cntr, fk_to_regn, fk_to_distr, to_town, fk_to_kul, to_nd, to_kw, fk_citiz, fk_milit, fk_milit_regn, status_datb, fk_deb_org, priv_proc
  from c_kart_pr t where t.lsk=p_lsk;

  delete from c_states_sch s;
  delete from KART t where t.lsk=p_lsk;
  delete from arch_KART t where t.lsk=p_lsk and t.mg='201710';

  insert into C_KART_PR
  select 
  t.id, k2.lsk, t.fio, t.status, t.dat_rog, t.pol, t.dok, t.dok_c, t.dok_n, t.dok_d, t.dok_v, t.dat_prop, t.dat_ub, 
  t.relat_id, t.old_id, t.status_dat, t.status_chng, t.k_fam, t.k_im, t.k_ot, t.fk_doc_tp, t.fk_nac, t.b_place, 
  t.fk_frm_cntr, t.fk_frm_regn, t.fk_frm_distr, t.frm_town, t.frm_dat, t.fk_frm_kul, t.frm_nd, t.frm_kw, t.w_place, 
  t.fk_ub, t.fk_to_cntr, t.fk_to_regn, t.fk_to_distr, t.to_town, t.fk_to_kul, t.to_nd, t.to_kw, t.fk_citiz, 
  t.fk_milit, t.fk_milit_regn, t.status_datb, t.fk_deb_org, t.priv_proc
  from C_KART_PR_kmp t, kart_kmp k, kart k2, v_lsk_tp tp
  where t.lsk=k.lsk and k.k_lsk_id=k2.k_lsk_id
  and k2.psch not in (8,9) and k2.fk_tp=tp.id
  and tp.cd='LSK_TP_ADDIT'
  and t.lsk=p_lsk;

  insert into c_states_pr
    (id, fk_status, fk_kart_pr, dt1, dt2, fk_tp)
  select id, fk_status, fk_kart_pr, dt1, dt2, fk_tp
  from c_states_pr_kmp s;


end;
*/
end scripts2;
/
