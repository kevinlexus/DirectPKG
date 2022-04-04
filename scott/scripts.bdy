create or replace package body scott.scripts is

--�� ���.������ � KMP_LSK
--�������� ������ ��������� ����� ������ � ������� �����������
--� ��� �� ������� ������, ����������� � ���� �������!!! ��� 03.02.2016
--�� ��������� ��� ��������������� ������ �� �������� �.�. � ������� ��!
procedure swap_sal_MAIN_BY_LSK is
  l_reu_dst t_org.reu%type;
  dopl_ c_kwtp_mg.dopl%type;
  mg_ params.period%type;
  l_mg_back params.period%type;
  user_id_ number;
  dat_ date;
  fk_doc_ number;
  l_lsk_tp_cd v_lsk_tp.cd%type;
  l_cd c_change_docs.cd_tp%type;
  l_mg_frwrd params.period%type;
a number;
begin
--������, ������� �������� ���������
dopl_:='201802';
--������, ������ �� �������� �������
mg_:='201803';
--������ ��� ������ �� ����
l_mg_back:='201801';
--������ �� ����� ������
l_mg_frwrd:=utils.add_months_pr(mg_,1);
--���� ����������
dat_:=to_date('28022018','DDMMYYYY');
--��� ������
l_lsk_tp_cd:='LSK_TP_ADDIT'; --LSK_TP_ADDIT
--CD ����������
l_cd:=l_lsk_tp_cd||'20180228_1';
--������� ��
l_reu_dst:='96';

a:=init.set_date(dat_);

select t.id into user_id_ from t_user t where t.cd='SCOTT';

delete from t_corrects_payments t where t.mg=dopl_
 and exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd);
delete from c_change t where
  exists (select * from c_change_docs d where d.id=t.doc_id and
  d.cd_tp=l_cd);
delete from c_pen_corr t where
  exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd);

delete from c_change_docs t where t.cd_tp=l_cd;

--return ;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, cd_tp)
values
  (dopl_, dat_, sysdate, user_id_, l_cd)
  returning id into fk_doc_;


for c in (select k.lsk, s2.org, s2.usl,
   k1.lsk as newlsk, s2.summa as summa
     from (select usl, org, lsk, sum(summa) as summa from saldo_usl where
      mg=mg_
      group by usl, org, lsk) s2, kart k, kart k1, v_lsk_tp tp--, kmp_houses x
    where
    k.lsk=s2.lsk
    and k1.reu=l_reu_dst
    and k.k_lsk_id=k1.k_lsk_id
    and k.house_id in (12160,12127,12134,12164,12143,12162,12163,12161,10935,10841)
    --and k.house_id=x.old_id
    --and k1.house_id=x.id
    and tp.cd=l_lsk_tp_cd
    --and exists (select * from kmp_lsk m where k.lsk=m.lsk)
    and k.fk_tp=tp.id
    and k1.fk_tp=tp.id
    )
loop
if c.lsk='80001506' then
  null;
end if;
--�� ������ �.�.
  insert into c_change
    (lsk, usl, org, summa, user_id, dtek, mg2, mgchange, doc_id, ts)
    values
    (c.lsk, c.usl, c.org, -1*c.summa, user_id_, dat_, dopl_, dopl_, fk_doc_, sysdate);

--�� ����� �.�.
  insert into c_change
    (lsk, usl, org, summa, user_id, dtek, mg2, mgchange, doc_id, ts)
    values
    (c.newlsk, c.usl, c.org, c.summa, user_id_, dat_, dopl_, dopl_, fk_doc_, sysdate);

end loop;

-- ������
/*for c in (select k.lsk, s2.org as org, s2.usl as usl, s2.dopl,
   k1.lsk as newlsk, s2.summa as summa
     from (select t.usl, t.org, t.lsk, m.dopl, sum(t.summa) as summa from c_kwtp_mg m, kwtp_day t
      where to_char(t.dat_ink,'YYYYMM')=dopl_ and m.id=t.kwtp_id
      group by t.usl, t.org, m.dopl, t.lsk) s2, kart k, kart k1, v_lsk_tp tp--, kmp_houses x
    where
    k.lsk=s2.lsk
    and k1.reu=l_reu_dst
    and k.k_lsk_id=k1.k_lsk_id
    and exists (select * from kmp_lsk m where k.lsk=m.lsk)
    --and k.house_id=x.old_id
    --and k1.house_id=x.id
    and tp.cd=l_lsk_tp_cd
    and k.fk_tp=tp.id
    and k1.fk_tp=tp.id
    )
loop

--�� ������ �.�.
 insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc)
    values
    (c.lsk, c.usl, c.org, -1*c.summa, user_id_, dat_, dopl_, c.dopl, fk_doc_);--����� ������� � ����������� �������

--�� ����� �.�.
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc)
    values
    (c.newlsk, c.usl, c.org, c.summa, user_id_, dat_, dopl_, dopl_, fk_doc_); --����� ������ �� ������� ������

null;
end loop;*/

--������ �� ���� � ������� ����
for c in (select k.lsk,
   k1.lsk as newlsk
     from (select t.lsk, sum(t.penya) as penya from a_penya t
      where t.mg=l_mg_back
      group by t.lsk
      having sum(t.penya)<>0) s2, kart k, kart k1, v_lsk_tp tp--, kmp_houses x
    where
    k.lsk=s2.lsk
    and k1.reu=l_reu_dst
    and k.k_lsk_id=k1.k_lsk_id
    and k.house_id in (12160,12127,12134,12164,12143,12162,12163,12161,10935,10841)
    --and exists (select * from kmp_lsk m where k.lsk=m.lsk)
    --and k.house_id=x.old_id
    --and k1.house_id=x.id
    and tp.cd=l_lsk_tp_cd
    and k.fk_tp=tp.id
    and k1.fk_tp=tp.id
    )
loop
  --�������� ���� �� ������ �� �� ���� ����������
  c_cpenya.gen_penya(c.lsk, dat_, 0, 0);

--�� ������ �.�. -�����
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select t.lsk, -1*t.penya, t.mg1 as dopl, dat_ as dtek,
   sysdate as ts, u.id as fk_user, fk_doc_ from
   a_penya t, t_user u where t.mg=l_mg_back --��.������ �� ����
   and t.lsk=c.lsk and u.cd=user
  union all
  select t.lsk, -1*sum(t.penya), t.mg1 as dopl, dat_ as dtek,
   sysdate as ts, u.id as fk_user, fk_doc_ from
   c_pen_cur t, t_user u where
   t.lsk=c.lsk and u.cd=user
   group by t.lsk, u.id, t.mg1
   having sum(t.penya)<>0;

--�� ����� �.�. - ���������
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select c.newlsk, sum(t.penya) as penya, dopl_ as dopl,
   dat_ as dtek, sysdate as ts, u.id as fk_user, fk_doc_ from
   a_penya t, t_user u where t.mg=l_mg_back --��.������ �� ����
   and t.lsk=c.lsk and u.cd=user
   group by c.newlsk, u.id
   having sum(t.penya)<>0
  union all
  select c.newlsk, sum(t.penya), t.mg1 as dopl, dat_ as dtek,
   sysdate as ts, u.id as fk_user, fk_doc_ from
   c_pen_cur t, t_user u where
   t.lsk=c.lsk and u.cd=user
   group by c.newlsk, u.id, t.mg1
   having sum(t.penya)<>0;

end loop;



commit;

end swap_sal_MAIN_BY_LSK;


--������ ������ "� ������", �������������� ������������ ������!
procedure swap_sal_TO_NOTHING is
  mgchange_ c_change.mgchange%type;
  comment_ c_change_docs.text%type;
  l_mg params.period%type;
  l_mg_sal params.period%type;
  l_mg_back params.period%type;
  user_id_ number;
  cd_ c_change_docs.text%type;
  l_id number;
  l_dt date;
begin
--������, ������� �������� ���������
mgchange_:='202203';
--������, �� �������� ������� ������
l_mg_sal:='202203';
--������� �����
l_mg:='202203';
--����� �����
l_mg_back:='202202';
--����, ������� ��������
l_dt:=to_date('20220301','YYYYMMDD');
--�����������
comment_:='������ ������ � ���� �� ���������� ��� ������';
--���������� id ����������
cd_:='swp_sal_nothing_202203_1';

select t.id into user_id_ from t_user t where t.cd='SCOTT';
select changes_id.nextval into l_id from dual;

delete from c_change t where t.user_id=user_id_
 and exists (select * from
 c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.doc_id);

delete from t_corrects_payments t where t.user_id=user_id_
 and exists (select * from
 c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.fk_doc);

delete from c_pen_corr t where
 exists (select * from
   c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.fk_doc);

delete from c_change_docs t where t.user_id=user_id_ and t.text=cd_;


insert into c_change_docs (id, mgchange, dtek, ts, user_id, text)
select l_id as id, mgchange_, trunc(sysdate), sysdate, user_id_, cd_
 from dual;

insert into c_pen_corr
  (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
select s.lsk, s.penya*-1, s.mg1, l_dt, sysdate, user_id_, l_id
 from a_penya s, kart k, v_lsk_tp tp where
   s.lsk=k.lsk --and k.lsk in (select lsk from kmp_lsk)
    and k.reu in ('092','041')
    and s.mg=l_mg_back
    and k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN';

insert into c_change (lsk, usl, org, summa, mgchange, type, dtek, ts,
user_id, doc_id)
select s.lsk, s.usl, s.org, -1*s.summa as summa,
 mgchange_, 1, l_dt, sysdate, user_id_, l_id
 from saldo_usl s, kart k, v_lsk_tp tp where
   s.lsk=k.lsk --and k.lsk in (select lsk from kmp_lsk)
   and k.reu in ('092','041')
   and s.mg=l_mg_sal
   and k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN';

/*insert into t_corrects_payments
  (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc)
select s.lsk, s.usl, s.org, s.summa as summa, user_id_, l_dt,
 mgchange_, mgchange_, l_id
 from saldo_usl_script s, kart k where
   s.lsk=k.lsk --and k.lsk in (select lsk from kmp_lsk)
   and k.reu in ('092','041')
   and s.mg=l_mg_sal;*/
commit;

end swap_sal_TO_NOTHING;

-- ������� ���.������ � ������
-- �������� ����� https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
procedure CREATE_UK_NEW2(p_reu_dst          in kart.reu%type, -- ��� �� ���������� (������ ������� new_reu_), ���� �� ��������, �� ��������� �� ���.����� ���������
                         p_reu_src          in varchar2, -- ��� �� ��������� (���� �� ���������, �� �����) ����������� ���� ����������� �� �� ��� � ������ ���
                         p_lsk_tp_src       in varchar2, -- � ������ ���� ������ �������, ���� �� ������� - ����� ����� �� ������� p_remove_nabor_usl
                         p_house_src        in varchar2, -- House_id ����� �������, �������� '3256,5656,7778,'
                         p_get_all          in number, -- ������� ����� ����� �� (1 - ��� ��, � �.�. ��������, 0-������ ��������)
                         p_close_src        in number, -- ��������� ��. ��������� (mg2='999999') 1-��,0-���,2-��������� ������ ���� �� �������� ����
                         p_close_dst        in number, -- ��������� ��. ���������� (mg2='999999') 1-��,0-���
                         p_move_resident    in number, -- ���������� �����������? 1-��,0-���
                         p_forced_status    in number, -- ���������� ����� ������ ����� (0-��������, NULL - ����� �� ��� ��� � ����� ���������)
                         p_forced_tp        in varchar2, -- ���������� ����� ��� ����� (NULL-����� �� ���������, �������� 'LSK_TP_RSO' - ���)
                         p_tp_sal           in number, --������� ��� ���������� ������ 0-�� ����������, 2 - ���������� � ����� � ������, 1-������ �����, 3 - ������ ������
                         p_special_tp       in varchar2, -- ������� �������������� ���.���� � ������� � ����� ���������� (NULL- �� ���������, 'LSK_TP_ADDIT' - ���������)
                         p_special_reu      in varchar2, -- �� ��������������� ���.�����
                         p_mg_sal           in c_change.mgchange%type, -- ������ ������
                         p_remove_nabor_usl in varchar2 default null, -- ����������� ������ ������ (�������� ��� 033,034,035)
                         p_create_nabor_usl in varchar2 default null, -- ������� ������ ������ (�������� ��� 033,034,035) �� ������������ ��������� � p_remove_nabor_usl!
                         p_forced_usl       in varchar2 default null, -- ���������� ������ ������ � ���������� (���� �� �������, ����� �� ���������)
                         p_forced_org       in number default null, -- ���������� ����������� � ������ ���������� (null - ����� �� ���������)
                         p_mg_pen           in c_change.mgchange%type, -- ������ �� �������� ��������� ����. null - �� ���������� (������ ����� �����)
                         p_move_meter       in number default 0,-- ���������� ��������� ��������� (������ �����) 1-��,0-��� - ��� ����������� �� ��� - �� ���� ��������
                         p_cpn              in number default 0-- ��������� ���� � ����� ��� ������? (0, null, -��, 1 - ���)
                         ) is
  maxlsk_     number;
  comment_    c_change_docs.text%type;
  mg_         params.period%type;
  mg_close_   params.period%type;
  period_     params.period%type;
  user_id_    number;
  changes_id_ c_change_docs.id%type;
  cnt_        number;
  l_tp_sal    number;
  l_par       number;
  l_id        number;
  l_cd_tp     varchar2(256);
  -- ���� ���������� ������, ��� �������������
  l_dt        date;
  l_lsk_new   kart.lsk%type;
  l_ret       number;
  l_forced_tp number;
  l_flag      number;
  i           number;
begin
  -- ��������
  if p_remove_nabor_usl is not null and p_create_nabor_usl is not null then
    Raise_application_error(-20000, '����������� ������������ ������������ p_remove_nabor_usl � p_create_nabor_usl!');
  end if;

  --������� ��� ���������� ������
  --0-�� ����������, 2 - ���������� � ����� � ������,
  --1-������ �����
  l_tp_sal := nvl(p_tp_sal, 0);
  -- ���� ���������� ������, ��� �������������
  l_dt := gdt(30, 0, 0);
  select period into period_ from params p;
  select period3 into mg_close_ from v_params;
  --��������� ����� ��������, �.�. ������ ���������� ����� ������ �������� �����
  c_charges.scr_flag_ := 1;

  if l_tp_sal in (1, 2, 3) then
    --���� ��������� ��������� 1- ��������� (��� 2-��) ������

    --������, ������ �� �������� ������� ���������
    select p.period into mg_ from params p;
    --�����������
    comment_ := '���������� C����� �� ��=' || nvl(p_reu_dst,' ����� �� ���������');
    l_cd_tp  := 'TRANSF_28112018_1';
    --���������� ����� ����������
    select changes_id.nextval into changes_id_ from dual;

    select t.id into user_id_ from t_user t where t.cd = 'SCOTT';
    delete from t_corrects_payments t
     where exists (select *
              from c_change_docs t
             where t.cd_tp = l_cd_tp
               and t.id = t.fk_doc);
    delete from c_change_docs t where t.cd_tp = l_cd_tp;

    insert into c_change_docs
      (id, mgchange, dtek, ts, user_id, text, cd_tp)
      select changes_id_, mg_, trunc(l_dt), sysdate, user_id_, comment_, l_cd_tp
        from dual;
  end if;
  -- ������ ��� ����� ��� ����� ��
  l_forced_tp := null;
  if p_forced_tp is not null then
    select tp.id
      into l_forced_tp
      from v_lsk_tp tp
     where tp.cd = p_forced_tp;
  end if;

  l_flag := 0;
  i      := 0;
  for c in (select t.lsk as old_lsk, t.k_lsk_id, t.c_lsk_id, t.flag, t.flag1, t.kul, t.nd, t.kw, fio,
    k_fam, k_im, k_ot, kpr, kpr_wr, kpr_ot, kpr_cem, kpr_s, t.opl, ppl, pldop, ki, t.psch, psch_dt,
    status, kwt, lodpl, bekpl, balpl, komn, et, kfg, kfot,
    decode(p_move_meter, 1, phw, null) as phw, decode(p_move_meter, 1, mhw, null) as mhw,
    decode(p_move_meter, 1, pgw, null) as pgw, decode(p_move_meter, 1, mgw, null) as mgw,
    decode(p_move_meter, 1, pel, null) as pel, decode(p_move_meter, 1, mel, null) as mel,
    sub_nach, subsidii, sub_data, polis, sch_el,
    nvl(p_reu_dst, t.reu) as reu, -- ����� �� ���������, ���� �� ���������
    text, schel_dt, eksub1, eksub2, kran, t.kran1, el, el1, sgku, doppl, subs_cor, subs_cur, t.house_id, t.kan_sch, period_ as mg1,case
                     when nvl(p_close_dst, 0) = 1 then
                      period_
                     else
                      '999999'
                   end as mg2, t.fk_tp, t.entr, t.fk_pasp_org, tp.cd as tp_cd, t.fk_klsk_premise
              from kart t, v_lsk_tp tp
             where
             case
               when nvl(p_get_all, 0) = 1 then
                0 -- ��� ����� ���
               else
                t.psch
             end not in (8, 9)
         and -- ��� ����� ������ ��������
             (p_house_src is null or regexp_instr(p_house_src,
                          '(^|,|;)' || t.house_id || '($|,|;)') > 0)
            --and t.reu in ('084')
            --exists (select * from work_houses h where h.id=t.house_id)
            --exists (select * from kmp_lsk h where h.lsk=t.lsk)
         and t.fk_tp = tp.id and
         -- ���� �������� ��� �� ��������� ���.������ (������ ��� �������� �� ��� � ���)
         (p_reu_src is null or t.reu = p_reu_src) and
         -- ���� ��������� ������ ��� �������� (������ ��� �������� ���.������ ���), �� ������ ��, ���������� ������ ������
         (p_remove_nabor_usl is null or exists (select * from nabor n where n.lsk=t.lsk
         and regexp_instr(p_remove_nabor_usl,
             '(^|,|;)' || n.usl || '($|,|;)') > 0))

         and (p_lsk_tp_src is null or tp.cd in (p_lsk_tp_src)) -- ��� ���.����� - ���������
             order by t.kul, t.nd, t.kw) loop
    i := i + 1;
    --�������� �����, ���������� ��
    maxlsk_   := p_houses.find_unq_lsk(p_reu_dst, null);
    l_lsk_new := lpad(to_char(maxlsk_), 8, '0');
    insert into c_lsk (id) values (c_lsk_id.nextval);

    insert into kart
      (k_lsk_id, c_lsk_id, lsk, flag, flag1, kul, nd, kw, fio, k_fam, k_im, k_ot, kpr, kpr_wr,
      kpr_ot, kpr_cem, kpr_s, opl, ppl, pldop, ki, psch, psch_dt, status, kwt, lodpl, bekpl, balpl,
      komn, et, kfg, kfot, phw, mhw, pgw, mgw, pel, mel, sub_nach, subsidii, sub_data, polis, reu,
      text, schel_dt, eksub1, eksub2, kran, kran1, el, el1, sgku, doppl, subs_cor, subs_cur, house_id,
      kan_sch, mg1, mg2, fk_tp, entr, fk_pasp_org, fk_klsk_premise, cpn)
    values
      (c.k_lsk_id, c_lsk_id.currval, l_lsk_new, c.flag, c.flag1, c.kul, c.nd, c.kw, c.fio, c.k_fam,
      c.k_im, c.k_ot, c.kpr, c.kpr_wr, c.kpr_ot, c.kpr_cem, c.kpr_s, c.opl, c.ppl, c.pldop, c.ki,
      c.psch, c.psch_dt, c.status, c.kwt, c.lodpl, c.bekpl, c.balpl, c.komn, c.et, c.kfg, c.kfot,
      c.phw, c.mhw, c.pgw, c.mgw, c.pel, c.mel, c.sub_nach, c.subsidii, c.sub_data, c.polis, c.reu,
       c.text, c.schel_dt, c.eksub1, c.eksub2, c.kran, c.kran1, c.el, c.el1, c.sgku, c.doppl, c.subs_cor,
        c.subs_cur, c.house_id, c.kan_sch, c.mg1, c.mg2, nvl(l_forced_tp,
            c.fk_tp), c.entr, c.fk_pasp_org, c.fk_klsk_premise, p_cpn);
    insert into kart_detail(lsk)
    values (l_lsk_new);
    --���������� ������ �����
    insert into c_states_sch
      (lsk, fk_status, dt1, dt2)
      select l_lsk_new, nvl(p_forced_status, c.psch) as fk_status, -- ���� ������ �� ���������� �������������
             init.get_dt_start, null
        from dual;

    -- ������� ������� ���� ������������� � ������ (�������� ����������� ��� ���. 07.08.2018)
/*    if p_special_tp is not null then
      l_ret := p_houses.kart_lsk_special_add(l_lsk_new,
                                             p_special_tp,
                                             l_lsk_new
                                             null,
                                             0,
                                             0,
                                             p_special_reu);
      if l_ret != 0 then
        Raise_application_error(-20000,
                                '������ �������� ��������������� ���.����� � �����:' ||
                                p_special_tp);
      end if;
    end if; */

    --����������� ���������, (������ ���� �� ���������� �������� ���.������)
    if nvl(p_move_resident, 0) = 1 then
      for t in (select id, lsk, fio, status, dat_rog, pol, dok, dok_c, dok_n, dok_d, dok_v, dat_prop, dat_ub, relat_id, old_id, status_dat, status_chng, k_fam, k_im, k_ot, fk_doc_tp, fk_nac, b_place, fk_frm_cntr, fk_frm_regn, fk_frm_distr, frm_town, frm_dat, fk_frm_kul, frm_nd, frm_kw, w_place, fk_ub, fk_to_cntr, fk_to_regn, fk_to_distr, to_town, fk_to_kul, to_nd, to_kw, fk_citiz, fk_milit, fk_milit_regn
                  from c_kart_pr p
                 where p.lsk = c.old_lsk) loop
        insert into c_kart_pr
          (id, lsk, fio, status, dat_rog, pol, dok, dok_c, dok_n, dok_d, dok_v, dat_prop, dat_ub, relat_id, old_id, status_dat, status_chng, k_fam, k_im, k_ot, fk_doc_tp, fk_nac, b_place, fk_frm_cntr, fk_frm_regn, fk_frm_distr, frm_town, frm_dat, fk_frm_kul, frm_nd, frm_kw, w_place, fk_ub, fk_to_cntr, fk_to_regn, fk_to_distr, to_town, fk_to_kul, to_nd, to_kw, fk_citiz, fk_milit, fk_milit_regn)
        values
          (kart_pr_id.nextval, l_lsk_new, t.fio, t.status, t.dat_rog, t.pol, t.dok, t.dok_c, t.dok_n, t.dok_d, t.dok_v, t.dat_prop, t.dat_ub, t.relat_id, t.old_id, t.status_dat, t.status_chng, t.k_fam, t.k_im, t.k_ot, t.fk_doc_tp, t.fk_nac, t.b_place, t.fk_frm_cntr, t.fk_frm_regn, t.fk_frm_distr, t.frm_town, t.frm_dat, t.fk_frm_kul, t.frm_nd, t.frm_kw, t.w_place, t.fk_ub, t.fk_to_cntr, t.fk_to_regn, t.fk_to_distr, t.to_town, t.fk_to_kul, t.to_nd, t.to_kw, t.fk_citiz, t.fk_milit, t.fk_milit_regn);

        --��������� ��� ������� ������������ � ����� �����...
        insert into c_states_pr
          (fk_status, fk_kart_pr, dt1, dt2) -- �������� ��� ������, ���� � ������ ����������� � ����� fk_tp!
          select p.fk_status, kart_pr_id.currval, p.dt1, p.dt2
            from c_states_pr p
           where p.fk_kart_pr = t.id;

        for d in (select c.id, c.doc, c.dat_begin, c.main, c.dat_end
                    from c_lg_docs c
                   where c.c_kart_pr_id = t.id) loop
          insert into c_lg_docs
            (id, c_kart_pr_id, doc, dat_begin, main, dat_end)
          values
            (c_lg_docs_id.nextval, kart_pr_id.currval, d.doc, d.dat_begin, d.main, d.dat_end);

          insert into c_lg_pr
            (c_lg_docs_id, spk_id, type)
            select c_lg_docs_id.currval, r.spk_id, r.type
              from c_lg_pr r
             where r.c_lg_docs_id = d.id;
        end loop;
      end loop;
    end if;

    -- ������ �����
    if p_remove_nabor_usl is not null then
      insert into nabor
        (lsk, usl, org, koeff, norm, fk_vvod)
        select l_lsk_new, nvl(p_forced_usl, n.usl) as usl, nvl(p_forced_org, n.org), n.koeff, n.norm, n.fk_vvod -- n.fk_vvod ���. 03.07.2018 �������, ������ ���� n.fk_vvod
          from nabor n
         where n.lsk = c.old_lsk
           and regexp_instr(p_remove_nabor_usl,
                            '(^|,|;)' || n.usl || '($|,|;)') > 0;
      -- ������� �������� ������ � �� - ���������
      delete from nabor n
       where regexp_instr(p_remove_nabor_usl,
                          '(^|,|;)' || n.usl || '($|,|;)') > 0
         and n.lsk = c.old_lsk;
    elsif p_create_nabor_usl is not null then
      insert into nabor
        (lsk, usl, org)
      select l_lsk_new as lsk, u.usl as usl, nvl(p_forced_org, o.id) as org from usl u join t_org o on o.reu=p_reu_dst
              where regexp_instr(p_create_nabor_usl,
                          '(^|,|;)' || u.usl || '($|,|;)') > 0;
    else
      insert into nabor
        (lsk, usl, org, koeff, norm, fk_vvod)
        select l_lsk_new, n.usl, nvl(p_forced_org, n.org), n.koeff, n.norm, n.fk_vvod -- n.fk_vvod ���. 03.07.2018 �������, ������ ���� n.fk_vvod
          from nabor n
         where n.lsk = c.old_lsk;
    end if;

    if nvl(p_close_src, 0) = 1 or nvl(p_close_src, 0) = 2 and c.tp_cd <> 'LSK_TP_MAIN' then
      --�������� ������� �����
      --��������� ������ �������� ���������

      --������������� ������ ��������
      update kart k
         set k.mg2 = mg_close_
       where k.mg1 < mg_
         and k.lsk = c.old_lsk
         and k.mg2 = '999999';

      -- ������� �� ��� ��� �������� ��������� �� �� ������� ��������� 80000452 ���. 01.03.2018
      --if sql%rowcount = 0 or mg_close_='999999' then
      --  Raise_application_error(-20000, '��������� �������� ������ � ��� �����:'||c.old_lsk||' mg_close='||mg_close_);
      --end if;

      --��� ��� �.�. ������� ������ ������ ��������� � ��� ������ (������ �����)
      update kart k
         set k.mg2 = period_
       where k.mg1 = period_ /* and k.psch in (8,9)*/
         and k.lsk = c.old_lsk
         and k.mg2 = '999999';

      --psch � kart ����������� �����, � ���������
      --������� �������� � �������� ������� �����
      delete from c_states_sch k where k.lsk = c.old_lsk;

      --������������� ����� "��������" ������ ������� �����
      insert into c_states_sch
        (lsk, fk_status, dt1, dt2, fk_close_reason)
        select k.lsk, 8 as fk_status, to_date(period_ || '01', 'YYYYMMDD') as dt1, null as dt2, a.id as fk_close_reson
          from kart k
          join (select u.id, s.name
                  from exs.u_list u
                  join exs.u_list s
                    on u.id = s.parent_id
                  join exs.u_listtp t
                    on s.fk_listtp = t.id
                 where t.cd = 'GIS_NSI_22'
                   and s.s1 = '����� ����������� �������-������������ �����') a
            on 1 = 1
         where k.lsk = c.old_lsk;
    end if;

    -- ������ ��������� � �����!
    if l_tp_sal in (1, 2, 3) then
      -- ������ ���������� � ������ �� ������� ��
--      cnt_ := c_charges.gen_charges(c.old_lsk, c.old_lsk, null, null, 1, 0);
--      gen.gen_saldo(c.old_lsk);

      --���� ��������� ��������� ������
      --�� ������ �.�.
      --������� ������
      insert into t_corrects_payments
        (lsk, usl, summa, org, user_id, dat, mg, dopl, fk_doc)
        select s.lsk, s.usl, s.summa, s.org, d.user_id, d.dtek, mg_, mg_, d.id
          from c_change_docs d, saldo_usl s, (select m.lsk, sum(summa) as summa
                   from saldo_usl m
                  where m.mg = p_mg_sal
                    and m.lsk = c.old_lsk
                       --###2 ������ ��� ���������������� https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
                    and regexp_instr(p_remove_nabor_usl,
                                     '(^|,|;)' ||
                                     m.usl ||
                                     '($|,|;)') > 0
                  group by m.lsk) a
         where s.mg = p_mg_sal
           and s.lsk = a.lsk
           and case
                 when l_tp_sal = 1 and nvl(a.summa, 0) > 0 then
                  1 -- ������ �����
                 when l_tp_sal = 3 and nvl(a.summa, 0) < 0 then
                  1 -- ������ ������
                 when l_tp_sal = 2 then
                  1 -- �� ������
                 else
                  0
               end = 1
              --###2 ������ ��� ���������������� https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
           and regexp_instr(p_remove_nabor_usl,
                            '(^|,|;)' || s.usl || '($|,|;)') > 0
           and d.id = changes_id_
           and s.lsk = c.old_lsk;

      --������������� ������
      insert into t_corrects_payments
        (lsk, usl, summa, org, user_id, dat, mg, dopl, fk_doc)
        select l_lsk_new as lsk, s.usl, -1 * s.summa, s.org, d.user_id, d.dtek, mg_, mg_, d.id
          from c_change_docs d, saldo_usl s, (select m.lsk, sum(summa) as summa
                   from saldo_usl m
                  where m.mg = p_mg_sal
                    and m.lsk = c.old_lsk
                       --###2 ������ ��� ���������������� https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
                    and regexp_instr(p_remove_nabor_usl,
                                     '(^|,|;)' ||
                                     m.usl ||
                                     '($|,|;)') > 0
                  group by m.lsk) a
         where s.mg = p_mg_sal
           and s.lsk = a.lsk
           and case
                 when l_tp_sal = 1 and nvl(a.summa, 0) > 0 then
                  1
                 when l_tp_sal = 3 and nvl(a.summa, 0) < 0 then
                  1
                 when l_tp_sal = 2 then
                  1
                 else
                  0
               end = 1
              --###2 ������ ��� ���������������� https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
           and regexp_instr(p_remove_nabor_usl,
                            '(^|,|;)' || s.usl || '($|,|;)') > 0
           and d.id = changes_id_
           and s.lsk = c.old_lsk;

    end if;

    -- ������� ����
    if p_mg_pen is not null then
      -- ��������� �� ������
      --�����
      insert into c_pen_corr
        (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
        select t.lsk, -1 * t.poutsal as penya, mg_close_ as dopl, l_dt as dtek, sysdate, d.user_id, d.id as fk_doc, t.usl, t.org
          from xitog3_lsk t
          join c_change_docs d
            on d.id = changes_id_
         where t.lsk = c.old_lsk
           and t.mg = p_mg_pen
              --###2 ������ ��� ���������������� https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
           and nvl(t.poutsal, 0) <> 0
           and regexp_instr(p_remove_nabor_usl,
                            '(^|,|;)' || t.usl || '($|,|;)') > 0;
      --���������
      insert into c_pen_corr
        (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
        select l_lsk_new as lsk, t.poutsal as penya, mg_close_ as dopl, l_dt as dtek, sysdate, d.user_id, d.id as fk_doc, t.usl, t.org
          from xitog3_lsk t
          join c_change_docs d
            on d.id = changes_id_
         where t.lsk = c.old_lsk
           and t.mg = p_mg_pen
              --###2 ������ ��� ���������������� https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
           and nvl(t.poutsal, 0) <> 0
           and regexp_instr(p_remove_nabor_usl,
                            '(^|,|;)' || t.usl || '($|,|;)') > 0;
    end if;
    l_flag := 1;
  end loop;

  if l_flag = 0 then
    Raise_application_error(-20000,
                            '������! �� ���������� �� ����� ������!');
  end if;
  --�������� �����. ������ � �������� ���������� �� ������ � ����� �.�.
  /*for c in (select r.lsk from kart r,
                work_houses t where t.kul=r.kul and t.nd=r.nd and t.newreu = newreu_
                )
  loop
    cnt_:=c_charges.gen_charges(c.lsk, c.lsk, null, null, 1, 0);
  end loop;*/

  commit;

  --������ ����� ��������
  c_charges.scr_flag_ := 0;

  Raise_application_error(-20000,
                          '���������� ' || i || ' ������� ������');

end create_uk_new2;

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
  l_mg:='201902'; --���.������
  l_cd:='swap_ZERO_kis_20190226';
  l_mgchange:=l_mg;
  l_dt:=to_date('20190226','YYYYMMDD');
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
         from saldo_usl_script s join usl u2
        on s.mg=l_mg3 and s.usl=u2.usl
        join kart k on s.lsk=k.lsk
        --and s.org = 676 -- ������������ ��������
--        and k.reu in (
--        '094','109','103','059','017','041','104','102','014','105','106','073','012','063',
--        '015','096','080','095','107','108','077','019','070','084','006','007','036','035','078','052','081','100','101'
--        ) --�� ���� ��
        --and k.reu not in ('87','82','73','80','76','85','86','84')
        --and k.house_id =39666 --�� ����� ����
        and s.summa < 0
        --and s.usl in ('007','008','056') --�� ���� �������
             --and k.lsk='14040757'
        --and exists (select * from a_kwtp_day d where d.mg between '201701' and '201702'
        --                     and d.lsk=k.lsk and d.fk_distr=15)
        and exists
        (select t.*
         from saldo_usl_script t-- ��� ���� �����.������ �� ������ ������� 14040763
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
         from saldo_usl_script t
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
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff2,2) as summa from saldo_usl_script t
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
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff,2) as summa from saldo_usl_script t
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
    for c3 in (select t.usl, t.org from saldo_usl_script t
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
          select t.usl, t.org, t.summa from saldo_usl_script t where
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

-- ��������� ������ �� ���� � �� �� ��
procedure swap_sal_PEN(
     p_reu_src          in varchar2, -- ��� �� ���������
     p_usl_src in varchar2, -- ����������� � ������ ������
     p_usl_dst in varchar2, -- ��� ������ ����������
     p_org_src in number, -- ��� ���������
     p_org_dst in number -- ��� ����������
)
 is
  mg_ params.period%type;
  user_id_ number;
  dat_ date;
  fk_doc_ number;
  l_cd c_change_docs.cd_tp%type;
begin
--������, ������ �� �������� �������
mg_:='202010';
--���� ����������
dat_:=to_date('01112020','DDMMYYYY');
--CD ����������
l_cd:='swap_sal_PEN_'||to_char(dat_,'DDMMYYYY')||'_1';

select t.id into user_id_ from t_user t where t.cd='SCOTT';

/* ������� � ������!
delete from c_pen_corr t where
  exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd);

delete from c_change_docs t where t.cd_tp=l_cd;
insert into c_change_docs
  (mgchange, dtek, ts, user_id, cd_tp)
values
  (mg_, dat_, sysdate, user_id_, l_cd)
  returning id into fk_doc_;
*/

fk_doc_:=9710460;
for c in (select k.lsk, s.org, s.usl,
     s.summa as summa
     from (select usl, org, lsk, sum(t.poutsal) as summa from xitog3_lsk t where
      t.mg=mg_ --����� ���.������
      and t.usl=p_usl_src and t.org=p_org_src
      group by usl, org, lsk) s, kart k
    where
    k.lsk=s.lsk
    and k.reu=p_reu_src
    and nvl(s.summa,0) <> 0
    )
loop

-- �����
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.lsk, -1*c.summa, mg_ as dopl, dat_ as dtek,
   sysdate as ts, u.id as fk_user, fk_doc_, c.usl, c.org from
   dual t, t_user u where u.cd=user;

-- ���������
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.lsk, c.summa, mg_ as dopl, dat_ as dtek,
   sysdate as ts, u.id as fk_user, fk_doc_, p_usl_dst, p_org_dst from
   dual t, t_user u where u.cd=user;

end loop;



--commit;

end swap_sal_pen;


-- ����� ���� ��� ��������� �� ������ ��
procedure swap_sal_PEN2 is
  mg_ params.period%type;
  user_id_ number;
  dat_ date;
  fk_doc_ number;
  l_cd c_change_docs.cd_tp%type;
begin
--������, ������ �� �������� �������
mg_:='201906';
--���� ����������
dat_:=to_date('01072019','DDMMYYYY');
--CD ����������
l_cd:='swap_sal_PEN_'||to_char(dat_,'DDMMYYYY')||'_1';

select t.id into user_id_ from t_user t where t.cd='SCOTT';

delete from c_pen_corr t where
  exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd);

delete from c_change_docs t where t.cd_tp=l_cd;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, cd_tp)
values
  (mg_, dat_, sysdate, user_id_, l_cd)
  returning id into fk_doc_;

for c in (select k.lsk, s2.org, s2.usl,
   k1.lsk as newlsk, s2.summa as summa
     from (select usl, org, lsk, sum(t.poutsal) as summa from xitog3_lsk t where
      t.mg=mg_ --����� ������
      --and t.usl='026'
      group by usl, org, lsk) s2 join kart k on k.lsk=s2.lsk
      left join kart k1 on k.k_lsk_id=k1.k_lsk_id and k1.reu='XXX' and k1.psch not in (8,9) -- �� ����������, ���� ����� k1.reu='XXX', �� ����� � ������
    where
    --exists (select * from kmp_lsk t where t.lsk=k.lsk) -- �� ���������
    k.reu in ('013', '087') -- �� ���������
    and nvl(s2.summa,0) <> 0
    )
loop

--�� ������ �.�. -�����
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.lsk, -1*c.summa, mg_ as dopl, dat_ as dtek,
   sysdate as ts, u.id as fk_user, fk_doc_, c.usl, c.org from
   dual t, t_user u where u.cd=user;

if c.newLsk is not null then
--�� ����� �.�. - ���������
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.newlsk, c.summa, mg_ as dopl, dat_ as dtek,
   sysdate as ts, u.id as fk_user, fk_doc_, c.usl, c.org from
   dual t, t_user u where u.cd=user;
end if;

end loop;



commit;

end swap_sal_pen2;


-- ����� ���� � ������ � ��������� �� ������ ������
procedure swap_sal_and_pen is
  mg_ params.period%type;
  user_id_ number;
  dat_ date;
  fk_doc_ number;
  l_cd c_change_docs.cd_tp%type;
begin
--������, ������ �� �������� �������
mg_:='202102';
--���� ����������
dat_:=to_date('01'||mg_,'DDYYYYMM');
--CD ����������
l_cd:='swap_sal_with_pen_'||to_char(dat_,'DDMMYYYY')||'_1';

select t.id into user_id_ from t_user t where t.cd='SCOTT';

delete from c_pen_corr t where
  exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd);
delete from c_change t where
  exists (select * from c_change_docs d where d.id=t.doc_id and
  d.cd_tp=l_cd);

delete from c_change_docs t where t.cd_tp=l_cd;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, cd_tp)
values
  (mg_, dat_, sysdate, user_id_, l_cd)
  returning id into fk_doc_;

for c in (select k.lsk, s.org, s.usl,
     s.outpen, s.outkredit+s.outdebet as outsal
     from (select usl, org, lsk, nvl(sum(t.outkredit),0) as outkredit, nvl(sum(t.outdebet),0) as outdebet,
      nvl(sum(t.poutsal),0) as outpen from xitog3_lsk t where
      t.mg=mg_ --����� ������
      and t.usl in ('003','004')
      group by usl, org, lsk) s join kart k on s.lsk=k.lsk
    where
    k.reu in ('082') -- �� ���������
    and (s.outkredit+s.outdebet <> 0 or outpen <> 0)
    )
loop

--�� ������� -�����
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.lsk, -1*c.outpen, mg_ as dopl, dat_ as dtek,
   sysdate as ts, u.id as fk_user, fk_doc_, c.usl, c.org from
   dual t, t_user u where u.cd=user;
  insert into c_change
    (lsk, usl, org, summa, user_id, dtek, mg2, mgchange, doc_id, ts)
    values
    (c.lsk, c.usl, c.org, -1*c.outsal, user_id_, dat_, mg_, mg_, fk_doc_, sysdate);

--�� ������ ������� - ���������
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.lsk, c.outpen, mg_ as dopl, dat_ as dtek,
   sysdate as ts, u.id as fk_user, fk_doc_, '122' as usl, c.org from
   dual t, t_user u where u.cd=user;
  insert into c_change
    (lsk, usl, org, summa, user_id, dtek, mg2, mgchange, doc_id, ts)
    values
    (c.lsk, '122', c.org, c.outsal, user_id_, dat_, mg_, mg_, fk_doc_, sysdate);

end loop;

end swap_sal_and_pen;

-- ����� ���� � ������ � ��������� �� ������ ������ (�����������)
procedure swap_sal_PEN3 is
  mg_ params.period%type;
  user_id_ number;
  dat_ date;
  fk_doc_ number;
  l_cd c_change_docs.cd_tp%type;
begin
--������, ������ �� �������� �������
mg_:='202112';
--���� ����������
dat_:=to_date('13122021','DDMMYYYY');
--CD ����������
l_cd:='swap_sal_PEN3_'||to_char(dat_,'DDMMYYYY')||'_1';

select t.id into user_id_ from t_user t where t.cd='SCOTT';

delete from c_pen_corr t where
  exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd);

delete from c_change_docs t where t.cd_tp=l_cd;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, cd_tp)
values
  (mg_, dat_, sysdate, user_id_, l_cd)
  returning id into fk_doc_;

for c in (select k.lsk, s2.org, s2.usl, s2.summa as summa
     from (select usl, org, lsk, sum(t.poutsal) as summa from xitog3_lsk t where
      t.mg=mg_
      and  --����� ������ �� ������
      (t.usl in ('061','015') and t.org=20
       or t.usl in ('007','008','056') and t.org=10
       or t.usl in ('061','015') and t.org=19
       or t.usl in ('007','008') and t.org=9
       )
      group by usl, org, lsk) s2, kart k
    where
    k.lsk=s2.lsk
    --and k.reu in ('014','015') -- ��
    and nvl(s2.summa,0) < 0
    )
loop

--�� ������-��������� -����� (��� ���������)
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.lsk, -1*c.summa, mg_ as dopl, dat_ as dtek,
   sysdate as ts, u.id as fk_user, fk_doc_, c.usl, c.org from
   dual t, t_user u where u.cd=user;

--�� ������-���������� - ���������
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.lsk, c.summa, mg_ as dopl, dat_ as dtek,
   sysdate as ts, u.id as fk_user, fk_doc_, c.usl, 7 as org from
   dual t, t_user u where u.cd=user;

end loop;



commit;

end swap_sal_pen3;


-- ����� ���� � ������ �� ���� ���. 03.02.2022 - ���
procedure remove_sal_PEN1 is
  mg_ params.period%type;
  mg_back params.period%type;
  user_id_ number;
  dat_ date;
  fk_doc_ number;
  l_cd c_change_docs.cd_tp%type;
begin
--������, ������ �� �������� �������
mg_:='202202';
mg_back:='202201';
--���� ����������
dat_:=to_date('01022022','DDMMYYYY');
--CD ����������
l_cd:='remove_sal_PEN1_1';

select t.id into user_id_ from t_user t where t.cd='SCOTT';

delete from c_pen_corr t where
  exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd);

delete from c_change_docs t where t.cd_tp=l_cd;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, cd_tp)
values
  (mg_, dat_, sysdate, user_id_, l_cd)
  returning id into fk_doc_;

-- ����� ��.������ �� ����
for c in (select k.lsk, s2.org, s2.usl, s2.insal as summa, s2.mg1
     from (select '140' as usl, 846 as org, t.mg1, lsk, nvl(sum(t.penya),0) as insal from a_penya t where
      t.mg=mg_back
      group by t.lsk, t.mg1) s2, kart k
    where
    k.lsk=s2.lsk
    and exists (select * from kmp_lsk m where m.lsk=k.lsk)
    )
loop

--�� ������-��������� -����� (��� ���������)
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.lsk, -1*c.summa, c.mg1, dat_ as dtek,
   sysdate as ts, u.id as fk_user, fk_doc_, c.usl, c.org from
   dual t, t_user u where u.cd=user;

end loop;

-- ����� ������� ����, ����� ��� � ����� �������!
for c in (select '140' as usl, 846 as org, mg1, lsk, round(sum(penya),2) as summa from c_pen_cur t
    where exists (select * from kmp_lsk m where m.lsk=t.lsk)
      group by mg1, lsk
    )
loop

--�� ������-��������� -����� (��� ���������)
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.lsk, -1*c.summa, c.mg1 as dopl, dat_ as dtek,
   sysdate as ts, u.id as fk_user, fk_doc_, c.usl, c.org from
     dual t, t_user u where u.cd=user;

end loop;

commit;

end remove_sal_pen1;

-- ��������� ������ � ��������� ���.����� �� ���� ��� (�����)
-- ���. 26.12.18
procedure swap_sal_from_main_to_rso is
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
  l_mg:='201902'; --���.������
  l_cd:='swap_sal_from_main_to_RSO_20190227';
  l_mgchange:=l_mg;
  l_dt:=to_date('20190227','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  for c in (select k.lsk as lskFrom, k2.lsk as lskTo, a.usl as uslFrom, a.org as orgFrom, n.usl as uslTo, n.org as orgTo,
        a.summa
         from kart k join kart k2 on k.k_lsk_id=k2.k_lsk_id and k2.psch not in (8,9) and k2.fk_tp=3861849
         join
         (select s.lsk, s.usl, s.org, sum(s.summa) as summa from (
           select t.lsk, t.usl, t.org, t.summa from saldo_usl_script t where t.mg='201903'
           and t.usl in ('007','056','015','058') and t.org not in (2,7)
           union all
           select t.lsk, t.usl, t.org, -1*t.summa as summa from t_corrects_payments t join
              c_change_docs d on t.fk_doc=d.id and d.cd_tp='dist_saldo_polis_201902'
               where t.mg='201902' and t.usl in ('007','056','015','058') and t.org not in (2,7)
               ) s
          group by s.lsk, s.usl, s.org) a on k.lsk=a.lsk and a.summa<>0
         left join nabor n on k2.lsk=n.lsk and n.usl=a.usl
        where k.psch not in (8,9) and k.fk_tp=673012

        and not exists (select * from c_penya p  -- ��� ��� ������������� ����� 2019.02
        where p.lsk=k.lsk and p.mg1<'201902' and p.summa > 0)) loop

      -- �����
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lskFrom, c.uslFrom, c.orgFrom,
        c.summa,
        uid, l_dt, l_mg, l_mg, l_id, 0 as var from dual;
      -- ���������
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lskTo, c.uslTo, c.orgTo,
        -1*c.summa,
        uid, l_dt, l_mg, l_mg, l_id, 0 as var from dual;
  end loop;
commit;
end swap_sal_from_main_to_rso;


-- ��������� ������ � ��������� ���.����� �� ���� ��� (�����) ��� ��������
-- ���. 29.01.19
procedure swap_sal_from_main_to_rso2 is
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
 l_main number;
 l_rso number;
begin
  l_mg:='202112'; --���.������
  l_cd:='swap_sal_from_main_to_RSO2_20211229_1';
  l_mgchange:=l_mg;
  l_dt:=to_date('20211229','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������

  select t.id into l_main from v_lsk_tp t where t.cd='LSK_TP_MAIN';
  select t.id into l_rso from v_lsk_tp t where t.cd='LSK_TP_RSO';

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

for c in (select k.lsk as lskFrom, k2.lsk as lskTo, a.usl, a.org,
        a.summa
         from kart k
         --join v_lsk_tp tp on tp.cd='LSK_TP_MAIN' and k.fk_tp=tp.id
         --join v_lsk_tp tp2 on tp2.cd='LSK_TP_RSO'
         join kart k2 on k.k_lsk_id=k2.k_lsk_id --and k2.psch not in (8,9)
         and k2.reu='023' /*k2.reu='016'*/ --and k2.fk_tp=tp2.id -- ����������
         join
         (select s.lsk, s.usl, s.org, sum(s.summa) as summa from (
           select t.lsk, t.usl, t.org, t.summa from saldo_usl_script t where t.mg='202201'
           and t.usl in ('003','055','103','104','105','106') and t.org in (2,23)
               ) s
          group by s.lsk, s.usl, s.org) a on k.lsk=a.lsk and a.summa < 0
        where k.fk_tp=l_main and k2.fk_tp=l_main
        --k.psch not in (8,9)
        --and
         and k.reu='002' -- ��������
        and k.house_id in (36876,36877,36878,36879,36880,36881,36882,36883,36884,36885,36903,36905,36906,36907,36908,36909,36910,36914,36916,36918,36919,36920,36922,36923,36926,36932,36967,36968,36969,36970,36971,36972,36973,36974,36975,36976,36977,36978,36979,36980,36958,36959,36960,39666,36963,37034,37035,37036,38794,38791,38792,38795,38796,38793,37097,37098,37099,37100,37101,37102,37103,37104,37105,37106,37107,37108,37155,37157,37159,37161,37273,37274,37275,37276,39766) -- ���
) loop

      -- �����
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lskFrom, c.usl, c.org,
        c.summa,
        uid, l_dt, l_mg, l_mg, l_id, 0 as var from dual;
      -- ���������
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lskTo, c.usl, 23 as org,
        -1*c.summa,
        uid, l_dt, l_mg, l_mg, l_id, 0 as var from dual;
  end loop;


commit;
end swap_sal_from_main_to_rso2;

-- ��������� ������ ������ ����-���� (�����) (���������! ����� �������� � �������, ��������� ������!)
-- ���.04.12.2019
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
  l_mg:='201912'; --���.������
  l_cd:='swap_sal_chpay13_20191204';
  l_mgchange:=l_mg;
  l_dt:=to_date('20191204','YYYYMMDD');
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
    from saldo_usl_script s, kart k, kart k3
    where s.mg=l_mg3 and s.lsk=k.lsk
    and s.usl in ('031')
    and k3.lsk = (select max(n.lsk) from nabor n, kart k2 where k2.lsk<>k.lsk and k2.lsk=n.lsk and k2.k_lsk_id=k.k_lsk_id and n.usl='107')
    and s.summa < 0
    and s.org = 690;

  -- ��������� �� ������ ��, ��� ���� ������ ����������
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select k3.lsk, '107' as usl, 14 as org,
    -1*s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl_script s, kart k, kart k3
    where s.mg=l_mg3 and s.lsk=k.lsk
    and s.usl in ('031')
    and k3.lsk = (select max(n.lsk) from nabor n, kart k2 where k2.lsk<>k.lsk and k2.lsk=n.lsk and k2.k_lsk_id=k.k_lsk_id and n.usl='107')
    and s.summa < 0
    and s.org = 690;

commit;
end swap_sal_chpay13;

-- ��������� ������ � ���� � ��������� ���.����� �� �������������� ���� (�����)
-- ���. 06.01.20
procedure move_sal_pen_main_to_rso is
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
 l_day varchar2(2);
begin
  l_mg:='202104'; --���.������
  l_day:='27';
  l_cd:='move_sal_pen_main_to_rso_'||l_mg||l_day;
  l_mgchange:=l_mg;
  l_dt:=to_date(l_mg||l_day,'YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --����� ������

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  for c in (select k.lsk as lskFrom, k2.lsk as lskTo, t.usl as uslFrom, t.org as orgFrom,
         nvl(t.poutsal,0) as poutsal, nvl(t.outdebet,0)+nvl(t.outkredit,0) as sal
         from kart k
         join v_lsk_tp tp on tp.cd='LSK_TP_RSO' and k.fk_tp=tp.id and k.reu='014'
         join v_lsk_tp tp2 on tp2.cd='LSK_TP_RSO'
         join kart k2 on k.k_lsk_id=k2.k_lsk_id and k2.fk_tp=tp2.id and k2.reu='016' --and k2.psch not in (8,9)
         join xitog3_lsk_script t on t.mg=l_mg and k.lsk=t.lsk and (nvl(t.outdebet,0)+nvl(t.outkredit,0)<0)
         and t.usl in ('007','056')
         and t.org=4
         --where k.house_id=38798
        ) loop

      if c.sal<>0 then
      -- ������
        -- �����
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
          select c.lskFrom, c.uslFrom, c.orgFrom,
          c.sal,
          uid, l_dt, l_mg, l_mg, l_id, 0 as var from dual;
        -- ���������
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
          select c.lskTo, c.uslFrom, 11 as org,
          -1*c.sal,
          uid, l_dt, l_mg, l_mg, l_id, 0 as var from dual;
      end if;

/*      if c.poutsal<>0 then
        -- ������ �� ����
        -- �����
        insert into c_pen_corr
          (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
          select c.lskFrom, c.uslFrom, c.orgFrom, -1 * c.poutsal, l_user, l_dt, l_mg, l_id, 2 as var
            from dual;
        -- ���������
        insert into c_pen_corr
          (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
          select c.lskTo, c.uslFrom, c.orgFrom, c.poutsal, l_user, l_dt, l_mg, l_id, 2 as var
            from dual;
      end if;
*/
  end loop;
commit;
end move_sal_pen_main_to_rso;


  -- ������������ ��� �������� ������, ��������� ������!
  /*delete from SALDO_USL_SCRIPT t;
    insert into SALDO_USL_SCRIPT(LSK, USL, ORG, SUMMA, MG, USLM)
    select LSK, USL, ORG, SUMMA, MG, USLM from saldo_usl t where t.mg>='202009';

    delete from xitog3_lsk_script t;
    insert into xitog3_lsk_script(lsk, org, uslm, usl, status, indebet, inkredit, charges, changes, subsid, payment, pn, outdebet, outkredit, mg, privs, privs_city, ch_full, changes2, poutsal, changes3, pinsal, pcur)
    select lsk, org, uslm, usl, status, indebet, inkredit, charges, changes, subsid, payment, pn, outdebet, outkredit, mg, privs, privs_city, ch_full, changes2, poutsal, changes3, pinsal, pcur
     from xitog3_lsk t where t.mg>='202009';
 */
  -- ������� ������ ������������ ������������� ������� �� ������ � ������
  -- ��������� ����������� � ������������� ������
  -- ���.25.12.18
  procedure dist_saldo_polis is
    l_mg           params.period%type;
    l_mg3          params.period%type;
    l_user         number;
    l_id           number;
    l_cd           c_change_docs.text%type;
    l_mgchange     c_change_docs.mgchange%type;
    l_dt           date;
    l_kr           number;
    l_kr2          number;
    l_deb          number;
    l_coeff        number;
    l_coeff2       number;
    l_itg_kr       number;
    l_itg_db       number;
    l_corr_kr      number;
    l_corr_deb     number;
    l_diff         number;
    l_flag_dist    boolean;
    i              number;
    l_last_kr_usl  usl.usl%type;
    l_last_kr_org  number;
    l_last_deb_usl usl.usl%type;
    l_last_deb_org number;

    l_last_kr_usl_zero  usl.usl%type;
    l_last_kr_org_zero  number;
    l_last_deb_usl_zero usl.usl%type;
    l_last_deb_org_zero number;
    l_last_kr_max       number;
    l_last_deb_max      number;
  begin
    l_mg       := '202012'; --���.������
    l_cd       := 'dist_saldo_polis_'||l_mg;
    l_mgchange := l_mg;
    l_dt       := to_date(l_mg||'26', 'YYYYMMDD'); --����� ��������
    l_mg3      := utils.add_months_pr(l_mg, 1); --����� ������, �� ��� ������

    dbms_output.enable(2000000);

    select t.id into l_user from t_user t where t.cd = 'SCOTT';
    select changes_id.nextval into l_id from dual;

    delete from t_corrects_payments t
     where mg = l_mg
       and exists (select *
              from c_change_docs d
             where d.cd_tp = l_cd
               and d.id = t.fk_doc);

    delete from c_change_docs t
     where t.user_id = l_user
       and t.cd_tp = l_cd;

    insert into c_change_docs
      (id, mgchange, dtek, ts, user_id, cd_tp)
      select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd from dual;

    for c in (select distinct s.lsk, s.mg
                from saldo_usl_script s
                join usl u2
                  on s.mg = l_mg3
                 and s.usl = u2.usl
                 and s.summa < 0 --���� ������
                    --and s.lsk='06005556'
                 and exists (select t.*
                        from saldo_usl_script t -- ��� ���� �����.������ �� ������ �������
                       where t.mg = s.mg
                         and t.lsk = s.lsk
                         and t.summa > 0)
              /*and exists ( -- ������� (�����), ������ �� �������� ��, ��� ���� ��� ����
              select k.lsk from kart k where k.lsk=s.lsk and
                  k.psch not in (8,9) and k.fk_tp=673012
                  and exists (select * from kart k2 where k2.k_lsk_id=k.k_lsk_id
                  and k2.fk_tp=3861849)

                  and not exists (select * from c_penya p
                  where p.lsk=k.lsk and p.mg1<'201812' and p.summa > 0)
                  and exists (select * from saldo_usl t where t.mg='201901'
                  and t.lsk=k.lsk and t.usl in ('007','056','015','058'))
                  )*/
              ) loop

      --����� ��� ���� � ��� ������
      select abs(nvl(sum(case
                           when t.summa < 0 then
                            t.summa
                           else
                            0
                         end),
                     0)),nvl(sum(case
                       when t.summa > 0 then
                        t.summa
                       else
                        0
                     end),
                 0)
        into l_kr, l_deb
        from saldo_usl_script t
       where t.mg = c.mg
         and t.lsk = c.lsk;

      --���������� ������ ����� �� �����.������
      if l_kr > l_deb then
        l_kr2 := l_deb;
      else
        l_kr2 := l_kr;
      end if;

      -- ����� ����� ����������� ������ � �������
      l_coeff2 := l_kr2 / l_kr;

      -- ����� ����� ��������� �� �����
      l_coeff := l_kr2 / l_deb;

      l_last_kr_usl  := null;
      l_last_kr_org  := null;
      l_last_deb_usl := null;
      l_last_deb_org := null;

      l_last_kr_usl_zero  := null;
      l_last_kr_org_zero  := null;
      l_last_deb_usl_zero := null;
      l_last_deb_org_zero := null;

      l_last_kr_max  := 0;
      l_last_deb_max := 0;
      --����� � �������
      l_corr_kr := 0;
      for c2 in (select t.lsk, t.usl, t.org, abs(t.summa) as sal, round(abs(t.summa) *
                               l_coeff2,
                               2) as summa
                   from saldo_usl_script t
                  where t.mg = c.mg
                    and t.summa < 0
                    and t.lsk = c.lsk
                    and t.summa * l_coeff2 <> 0) loop

        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
          select c.lsk, c2.usl, c2.org, -1 * c2.summa, uid, l_dt, l_mg, l_mg, l_id, 1 as var
            from dual;
        l_corr_kr := l_corr_kr + c2.summa;
        if c2.sal - 1 * c2.summa > 0 and
           l_last_kr_max < c2.sal - 1 * c2.summa then
          l_last_kr_max := c2.sal - 1 * c2.summa;
          l_last_kr_usl := c2.usl;
          l_last_kr_org := c2.org;
        end if;
        if c2.sal - 1 * c2.summa = 0 then
          l_last_kr_usl_zero := c2.usl;
          l_last_kr_org_zero := c2.org;
        end if;
      end loop;

      --����� � ������
      l_corr_deb := 0;
      for c2 in (select t.lsk, t.usl, t.org, t.summa as sal, round(t.summa *
                               l_coeff,
                               2) as summa
                   from saldo_usl_script t
                  where t.mg = c.mg
                    and t.summa > 0
                    and t.lsk = c.lsk
                    and t.summa * l_coeff <> 0) loop
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
          select c.lsk, c2.usl, c2.org, -1 * c2.summa, uid, l_dt, l_mg, l_mg, l_id, 2 as var
            from dual;
        l_corr_deb := l_corr_deb + c2.summa;
        if c2.sal - 1 * c2.summa > 0 and
           l_last_deb_max < c2.sal - 1 * c2.summa then
          l_last_deb_max := c2.sal - 1 * c2.summa;
          l_last_deb_usl := c2.usl;
          l_last_deb_org := c2.org;
        end if;
        if c2.sal - 1 * c2.summa = 0 then
          l_last_deb_usl_zero := c2.usl;
          l_last_deb_org_zero := c2.org;
        end if;
      end loop;

      if l_kr < l_deb then
        if l_corr_kr <> l_kr then
          -- ����������� ������������� �� �������
          l_diff := l_kr - l_corr_kr;
          if l_last_kr_usl is null then
            --Raise_application_error(-20000, 'usl is null lsk='||c.lsk);
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_kr_usl_zero, l_last_kr_org_zero, -1 *
                      l_diff, uid, l_dt, l_mg, l_mg, l_id, 1 as var, 1 as iter
                from dual;
          else
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_kr_usl, l_last_kr_org, -1 * l_diff, uid, l_dt, l_mg, l_mg, l_id, 1 as var, 1 as iter
                from dual;
          end if;
        end if;

        if l_corr_deb <> l_kr then
          -- ����������� ������������� �� ������
          l_diff := l_kr - l_corr_deb;
          if l_last_deb_usl is null then
            --Raise_application_error(-20000, 'usl is null lsk='||c.lsk);
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_deb_usl_zero, l_last_deb_org_zero, -1 *
                      l_diff, uid, l_dt, l_mg, l_mg, l_id, 2 as var, 1 as iter
                from dual;
          else
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_deb_usl, l_last_deb_org, -1 * l_diff, uid, l_dt, l_mg, l_mg, l_id, 2 as var, 1 as iter
                from dual;
          end if;
        end if;

      else

        if l_corr_kr <> l_deb then
          -- ����������� ������������� �� �������
          l_diff := l_deb - l_corr_kr;
          if l_last_kr_usl is null then
            --Raise_application_error(-20000, 'usl is null lsk='||c.lsk);
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_kr_usl_zero, l_last_kr_org_zero, -1 *
                      l_diff, uid, l_dt, l_mg, l_mg, l_id, 1 as var, 1 as iter
                from dual;
          else
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_kr_usl, l_last_kr_org, -1 * l_diff, uid, l_dt, l_mg, l_mg, l_id, 1 as var, 1 as iter
                from dual;
          end if;
        end if;

        if l_corr_deb <> l_deb then
          -- ����������� ������������� �� ������
          l_diff := l_deb - l_corr_deb;
          if l_last_deb_usl is null then
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_deb_usl_zero, l_last_deb_org_zero, -1 *
                      l_diff, uid, l_dt, l_mg, l_mg, l_id, 2 as var, 1 as iter
                from dual;
          else
            --Raise_application_error(-20000, 'usl is null lsk='||c.lsk);
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_deb_usl, l_last_deb_org, -1 * l_diff, uid, l_dt, l_mg, l_mg, l_id, 2 as var, 1 as iter
                from dual;
          end if;
        end if;

      end if;

    -- ���������, ������� �� ������ � ������
    /*  l_diff:=l_corr_deb - l_corr_kr;
      i:=0;
      l_flag_dist:=true;
      while l_diff<>0 and l_flag_dist=true loop
          l_flag_dist:=false;
          for c2 in (select usl, org, sum(summa) as summa from
            (select t.usl, t.org, abs(t.summa) as summa
                from saldo_usl_script t where t.mg=c.mg and
                 t.lsk=c.lsk and t.summa > 0
            union all
            select t.usl, t.org, t.summa
                from t_corrects_payments t where t.fk_doc=l_id
                and t.lsk=c.lsk and t.var=2)
            group by usl, org
            having sum(summa)<>0) loop
            if c2.summa<>0 then
              null;
            end if;
            l_flag_dist:=true;
            -- �����/��������� �������
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, c2.usl, c2.org, sign(l_diff)*0.01, uid, l_dt, l_mg, l_mg, l_id, 2 as var, 2 as iter
                 from dual;
            l_diff:=l_diff - sign(l_diff)*0.01;
            if l_diff=0 then
              exit;
            end if;
          end loop;
        i:=i+1;
        if i> 1000 then
          Raise_application_error(-20000, '������ #1 ������������� � ��='||c.lsk);
        end if;
      end loop;*/

    -- �� ��������������, ��� ��� ���� ����� = 0, ��������� �� ��������� ������
    end loop;

    update t_corrects_payments t
       set t.summa = -1 * t.summa
     where t.fk_doc = l_id
       and t.var = 2;
    commit;

  end dist_saldo_polis;


  -- ������� ������ ������������ ������������� ������� �� ������ �� ����
  -- ��������� ����������� � ������������� ������
  -- ���.21.11.2019
  procedure dist_saldo_PEN_polis is
    l_mg           params.period%type;
    l_mg3          params.period%type;
    l_user         number;
    l_id           number;
    l_cd           c_change_docs.text%type;
    l_mgchange     c_change_docs.mgchange%type;
    l_dt           date;
    l_kr           number;
    l_kr2          number;
    l_deb          number;
    l_coeff        number;
    l_coeff2       number;
    l_itg_kr       number;
    l_itg_db       number;
    l_corr_kr      number;
    l_corr_deb     number;
    l_diff         number;
    l_flag_dist    boolean;
    i              number;
    l_last_kr_usl  usl.usl%type;
    l_last_kr_org  number;
    l_last_deb_usl usl.usl%type;
    l_last_deb_org number;

    l_last_kr_usl_zero  usl.usl%type;
    l_last_kr_org_zero  number;
    l_last_deb_usl_zero usl.usl%type;
    l_last_deb_org_zero number;
    l_last_kr_max       number;
    l_last_deb_max      number;
  begin
    l_mg       := '202012'; --���.������
    l_cd       := 'dist_pen_polis_'||l_mg;
    l_mgchange := l_mg;
    l_dt       := to_date(l_mg||'26', 'YYYYMMDD');
    l_mg3      := l_mg;

    dbms_output.enable(2000000);

    select t.id into l_user from t_user t where t.cd = 'SCOTT';
    select changes_id.nextval into l_id from dual;

    delete from c_pen_corr t
     where exists (select *
              from c_change_docs d
             where d.cd_tp = l_cd
               and d.id = t.fk_doc);

    delete from c_change_docs t
     where t.user_id = l_user
       and t.cd_tp = l_cd;

    insert into c_change_docs
      (id, mgchange, dtek, ts, user_id, cd_tp)
      select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd from dual;

    for c in (select distinct s.lsk, s.mg
                from xitog3_lsk_script s
                join usl u2
                  on s.mg = l_mg3
                 and s.usl = u2.usl
                 and s.poutsal < 0 --���� ������ �� ����
                 and exists (select t.*
                        from xitog3_lsk_script t -- ��� ���� �����.���� �� ������ �������
                       where t.mg = s.mg
                         and t.lsk = s.lsk
                         and t.poutsal > 0)
              ) loop

      --����� ��� ���� � ��� ������ �� ����
      select abs(nvl(sum(case
                           when t.poutsal < 0 then
                            t.poutsal
                           else
                            0
                         end),
                     0)),nvl(sum(case
                       when t.poutsal > 0 then
                        t.poutsal
                       else
                        0
                     end),
                 0)
        into l_kr, l_deb
        from xitog3_lsk_script t
       where t.mg = c.mg
         and t.lsk = c.lsk;

      --���������� ������ ����� �� �����.������
      if l_kr > l_deb then
        l_kr2 := l_deb;
      else
        l_kr2 := l_kr;
      end if;

      -- ����� ����� ����������� ������ � �������
      l_coeff2 := l_kr2 / l_kr;

      -- ����� ����� ��������� �� �����
      l_coeff := l_kr2 / l_deb;

      l_last_kr_usl  := null;
      l_last_kr_org  := null;
      l_last_deb_usl := null;
      l_last_deb_org := null;

      l_last_kr_usl_zero  := null;
      l_last_kr_org_zero  := null;
      l_last_deb_usl_zero := null;
      l_last_deb_org_zero := null;

      l_last_kr_max  := 0;
      l_last_deb_max := 0;
      --����� � �������
      l_corr_kr := 0;
      for c2 in (select t.lsk, t.usl, t.org, abs(t.poutsal) as sal, round(abs(t.poutsal) *
                               l_coeff2,
                               2) as poutsal
                   from xitog3_lsk_script t
                  where t.mg = c.mg
                    and t.poutsal < 0
                    and t.lsk = c.lsk
                    and t.poutsal * l_coeff2 <> 0) loop

        insert into c_pen_corr
          (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
          select c.lsk, c2.usl, c2.org, -1 * c2.poutsal, l_user, l_dt, l_mg, l_id, 1 as var
            from dual;
        l_corr_kr := l_corr_kr + c2.poutsal;
        if c2.sal - 1 * c2.poutsal > 0 and
           l_last_kr_max < c2.sal - 1 * c2.poutsal then
          l_last_kr_max := c2.sal - 1 * c2.poutsal;
          l_last_kr_usl := c2.usl;
          l_last_kr_org := c2.org;
        end if;
        if c2.sal - 1 * c2.poutsal = 0 then
          l_last_kr_usl_zero := c2.usl;
          l_last_kr_org_zero := c2.org;
        end if;
      end loop;

      --����� � ������
      l_corr_deb := 0;
      for c2 in (select t.lsk, t.usl, t.org, t.poutsal as sal, round(t.poutsal *
                               l_coeff,
                               2) as poutsal
                   from xitog3_lsk_script t
                  where t.mg = c.mg
                    and t.poutsal > 0
                    and t.lsk = c.lsk
                    and t.poutsal * l_coeff <> 0) loop
        insert into c_pen_corr
          (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
          select c.lsk, c2.usl, c2.org, -1 * c2.poutsal, l_user, l_dt, l_mg, l_id, 2 as var
            from dual;
        l_corr_deb := l_corr_deb + c2.poutsal;
        if c2.sal - 1 * c2.poutsal > 0 and
           l_last_deb_max < c2.sal - 1 * c2.poutsal then
          l_last_deb_max := c2.sal - 1 * c2.poutsal;
          l_last_deb_usl := c2.usl;
          l_last_deb_org := c2.org;
        end if;
        if c2.sal - 1 * c2.poutsal = 0 then
          l_last_deb_usl_zero := c2.usl;
          l_last_deb_org_zero := c2.org;
        end if;
      end loop;

      if l_kr < l_deb then
        if l_corr_kr <> l_kr then
          -- ����������� ������������� �� �������
          l_diff := l_kr - l_corr_kr;
          if l_last_kr_usl is null then
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_kr_usl_zero, l_last_kr_org_zero, -1 *
                      l_diff, l_user, l_dt, l_mg, l_id, 1 as var
                from dual;
          else
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_kr_usl, l_last_kr_org, -1 * l_diff, l_user, l_dt, l_mg, l_id, 1 as var
                from dual;
          end if;
        end if;

        if l_corr_deb <> l_kr then
          -- ����������� ������������� �� ������
          l_diff := l_kr - l_corr_deb;
          if l_last_deb_usl is null then
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_deb_usl_zero, l_last_deb_org_zero, -1 *
                      l_diff, l_user, l_dt, l_mg, l_id, 2 as var
                from dual;
          else
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_deb_usl, l_last_deb_org, -1 * l_diff, l_user, l_dt, l_mg, l_id, 2 as var
                from dual;
          end if;
        end if;

      else

        if l_corr_kr <> l_deb then
          -- ����������� ������������� �� �������
          l_diff := l_deb - l_corr_kr;
          if l_last_kr_usl is null then
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_kr_usl_zero, l_last_kr_org_zero, -1 *
                      l_diff, l_user, l_dt, l_mg, l_id, 1 as var
                from dual;
          else
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_kr_usl, l_last_kr_org, -1 * l_diff, l_user, l_dt, l_mg, l_id, 1 as var
                from dual;
          end if;
        end if;

        if l_corr_deb <> l_deb then
          -- ����������� ������������� �� ������
          l_diff := l_deb - l_corr_deb;
          if l_last_deb_usl is null then
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_deb_usl_zero, l_last_deb_org_zero, -1 *
                      l_diff, l_user, l_dt, l_mg, l_id, 2 as var
                from dual;
          else
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_deb_usl, l_last_deb_org, -1 * l_diff, l_user, l_dt, l_mg, l_id, 2 as var
                from dual;
          end if;
        end if;
      end if;
    end loop;

    update c_pen_corr t
       set t.penya = -1 * t.penya
     where t.fk_doc = l_id
       and t.var = 2;

    -- ����������� ���� � �����
    update c_pen_corr t
       set t.penya = -1 * t.penya
     where t.fk_doc = l_id;

    commit;

  end dist_saldo_PEN_polis;

  -- ��������� ���������� � ������ �� ����� ���
  procedure swap_chrg_pay_by_one_org is
    l_cd   varchar2(50);
    l_mg   varchar2(6);
    l_dt   date;
    l_user number;
    l_id   number;
  begin
    l_mg := '201908'; --���.������
    l_cd := 'swap_chrg_pay_by_one_org_20190827';
    l_dt := to_date('20190827', 'YYYYMMDD');

    select t.id into l_user from t_user t where t.cd = 'SCOTT';
    select changes_id.nextval into l_id from dual;

    delete from t_corrects_payments t
     where mg = l_mg
       and exists (select *
              from c_change_docs d
             where d.cd_tp = l_cd
               and d.id = t.fk_doc);

    delete from c_change t
     where exists (select *
              from c_change_docs d
             where d.cd_tp = l_cd
               and d.id = t.doc_id);

    delete from c_change_docs t
     where t.user_id = l_user
       and t.cd_tp = l_cd;

    insert into c_change_docs
      (id, mgchange, dtek, ts, user_id, cd_tp)
      select l_id as id, l_mg, l_dt, sysdate, l_user, l_cd from dual;

    for c in (select t.lsk as lsk_src, t.usl, t.org, k2.lsk as lsk_dst, t.mg, t.charges, t.payment
                from xitog3_lsk t
                join kart k
                  on k.lsk = t.lsk
                 and k.reu = '002'
                join kart k2
                  on k.k_lsk_id = k2.k_lsk_id
                 and k2.reu = '016'
                 and k2.lsk <> k.lsk
               where t.mg between '201905' and '201907'
                 and t.usl = '092'
                 and exists (select *
                        from kart k
                       where k.lsk = t.lsk
                         and k.house_id in( 36950,36949,36934,36935,36943,37134,37136,36951,36945,36987,36988,40106,40126,36952,36940,36946,36941,36948,37505,36947,36942,39305,39325,38798)
                         --and k.k_lsk_id = 395744
                         )
               order by t.mg) loop

      if nvl(c.charges, 0) <> 0 then
        -- ����������
        -- �����
        insert into c_change
          (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id, doc_id)
        values
          (c.lsk_src, c.usl, c.org, -1 * c.charges, c.mg, '999', 0, l_dt, sysdate, l_user, l_id);
        -- ���������
        insert into c_change
          (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id, doc_id)
        values
          (c.lsk_dst, c.usl, 11, c.charges, c.mg, '999', 0, l_dt, sysdate, l_user, l_id);
      end if;

      if nvl(c.payment, 0) <> 0 then
        -- ������
        -- �����
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        values
          (c.lsk_src, c.usl, c.org, -1 * c.payment, l_user, l_dt, l_mg, c.mg, l_id, 0);

        -- ���������
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        values
          (c.lsk_dst, c.usl, 11, c.payment, l_user, l_dt, l_mg, c.mg, l_id, 0);
      end if;
    end loop;

    commit;

  end;

--������ ������ �� ������ ���, �������������� ������������ ������!
procedure swap_sal_to_another_org is
  mgchange_ c_change.mgchange%type;
  comment_ c_change_docs.text%type;
  l_mg params.period%type;
  l_mg_sal params.period%type;
  l_mg_back params.period%type;
  user_id_ number;
  cd_ c_change_docs.text%type;
  l_id number;
  l_dt date;
begin
--������, ������� �������� ���������
mgchange_:='202203';
--������, �� �������� ������� ������
l_mg_sal:='202203';
--������� �����
l_mg:='202203';
--����� �����
l_mg_back:='202202';
--����, ������� ��������
l_dt:=to_date('20220301','YYYYMMDD');
--�����������
comment_:='������ ������ � ���� �� ���������� ��� ������';
--���������� id ����������
cd_:='swp_sal_to_another_org_20220301';

select t.id into user_id_ from t_user t where t.cd='SCOTT';
select changes_id.nextval into l_id from dual;

delete from c_change t where t.user_id=user_id_
 and exists (select * from
 c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.doc_id);

delete from t_corrects_payments t where t.user_id=user_id_
 and exists (select * from
 c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.fk_doc);

delete from c_change_docs t where t.user_id=user_id_ and t.text=cd_;

insert into c_change_docs (id, mgchange, dtek, ts, user_id, text)
select l_id as id, mgchange_, trunc(sysdate), sysdate, user_id_, cd_
 from dual;

-- �������
/*insert into t_corrects_payments
  (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc)
select s.lsk, s.usl, s.org, s.summa as summa, user_id_, l_dt,
 mgchange_, mgchange_, l_id
 from saldo_usl_script s, kart k where
   s.lsk=k.lsk and s.org=708
   and s.usl in ('007','008','015','016','053','054','056','079')
   and s.mg=l_mg_sal
   and s.summa<0;

insert into t_corrects_payments
  (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc)
select s.lsk, '122' as usl, 715 as org, -1*s.summa as summa, user_id_, l_dt,
 mgchange_, mgchange_, l_id
 from saldo_usl_script s, kart k where
   s.lsk=k.lsk and s.org=708
   and s.usl in ('007','008','015','016','053','054','056','079')
   and s.mg=l_mg_sal
   and s.summa<0;*/


-- ������������

-- �����
insert into c_change
  (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id, doc_id)
select s.lsk, s.usl, s.org, -1*s.summa as summa, mgchange_, '999', 0 as type, l_dt, sysdate, user_id_, l_id
 from saldo_usl_script s, kart k where
   s.lsk=k.lsk and s.org=708
   and s.usl in ('007','008','015','016','053','054','056','079')
   and s.mg=l_mg_sal
   and s.summa<0;

-- ���������
insert into c_change
  (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id, doc_id)
select s.lsk, '122' as usl, 715 as org, s.summa as summa, mgchange_, '999', 0 as type, l_dt, sysdate, user_id_, l_id
 from saldo_usl_script s, kart k where
   s.lsk=k.lsk and s.org=708
   and s.usl in ('007','008','015','016','053','054','056','079')
   and s.mg=l_mg_sal
   and s.summa<0;

commit;


end swap_sal_to_another_org;

end scripts;
/

