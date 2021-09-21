create or replace package body scott.rep_bills_compound is

procedure main(p_sel_obj   in number, -- ������� �������: 0 - �� ���.�����, 1 - �� ������, 2 - �� ��
               p_reu       in kart.reu%type, -- ��� ��
               p_kul       in kart.kul%type, -- ��� �����
               p_nd        in kart.nd%type, -- � ����
               p_kw        in kart.kw%type, -- � ��������
               p_lsk       in kart.lsk%type, -- ���.���������
               p_lsk1      in kart.lsk%type, -- ���.��������
               p_klsk_id   in number default null, -- ���.��� ����, ������������ ��� p_sel_obj=1
               p_firstNum  in number, -- ��������� ����� ����� (��� ������ �� ��)
               p_lastNum   in number, -- �������� ����� �����
               p_is_closed in number, -- �������� �� �������� ����, ���� ���� ����? (0-���, 1-��)
               p_mg        in params.period%type, -- ������ �������
               p_sel_uk    in varchar2, -- ������ ��
               p_postcode  in varchar2, -- �������� ������ (��� p_sel_obj=2)
               p_exp_email in number default 0, -- ��������� ��� �������� �� ��.�����, ������������ ��� ������. �� ��, 0 - ���, 1 - ��
               p_rfcur     out ccur -- ���.���������
               ) is
l_exp_email_id number;               
begin
    if p_sel_obj = 2 then
      if p_exp_email = 1 then
        select u.id into l_exp_email_id from u_list u where u.cd='send_bill_via_email';
      end if;
      -- �� ��
      open p_rfcur for
        select k.prn_num, k.for_bill, k.lsk, k.k_lsk_id, k.opl, utils.month_name(SUBSTR(p_mg,
                                        5,
                                        2)) || ' ' ||
                SUBSTR(p_mg,
                       1,
                       4) ||
                ' �.' as mg2, k.kpr, k.kpr_wr, k.kpr_wrp, k.kpr_ot, k.opl, t.name as st_name, -- ������
               decode(t.cd,
                       'MUN',
                       '����������',
                       '�����������') as pers_tp, tp2.name_short||'.'||o2.name||', '||s.name || ', ' ||
                nvl(ltrim(k.nd, '0'), '0') || '-' ||
                nvl(ltrim(k.kw, '0'), '0') as adr, -- �����
               p_mg as mg, scott.utils.month_name(substr(p_mg, 5, 2)) || ' ' ||
                substr(p_mg, 1, 4) || '�.' as mg_str, -- ������
               k.fio
          from scott.arch_kart k
          join u_list tp
            on k.fk_tp = tp.id
          left join scott.spul s
            on k.kul = s.id
          left join scott.t_org o2 on s.fk_settlement=o2.id
          left join scott.t_org_tp tp2 on o2.fk_orgtp=tp2.id
          left join scott.status t
            on k.status = t.id
          join scott.c_houses h on k.house_id=h.id
          join (select *
                  from (select k2.lsk, -- ������ ������������� ��������� � ��������� ��� �����
                                first_value(k2.lsk) over(partition by k2.k_lsk_id order by decode(k2.psch, 8, 1, 9, 1, 0), tp2.npp) as lsk_main
                           from ARCH_KART k2
                           join u_list tp2
                             on k2.fk_tp = tp2.id
                            and k2.mg = p_mg
                            and k2.reu = p_reu) a
                 where a.lsk = a.lsk_main) b
            on b.lsk = k.lsk
         where k.mg = p_mg
           and k.reu = p_reu
           and case
                 when p_is_closed = 1 and nvl(k.for_bill, 0) = 1 then
                  1 -- ���� � �.�.��������, � ������
                 when p_is_closed = 0 and k.psch not in (8, 9) then
                  1 -- ���� ������ ��������
                 else
                  0
               end = 1
/*           and decode(p_sel_obj, 0, p_lsk, k.lsk) >= k.lsk
           and -- �� ���.�����
               decode(p_sel_obj, 0, p_lsk1, k.lsk) <= k.lsk
           and -- �� ���.�����
               decode(p_sel_obj, 1, nvl(p_kul, k.kul), k.kul) = k.kul
           and -- �� ������
               decode(p_sel_obj, 1, nvl(p_nd, k.nd), k.nd) = k.nd
           and decode(p_sel_obj, 1, nvl(p_kw, k.kw), k.kw) = k.kw*/
               -- �� ��������� �������
           and coalesce(p_postcode, h.postcode, 'x') = coalesce(h.postcode,'x')
           and k.prn_num between p_firstNum and p_lastNum -- �� ������� ��, �� ��������� pr_num

           and (p_exp_email = 0 or exists -- ���.19.07.21 �������� OR - ����� ���������!!!
             (select * from t_objxpar x where x.fk_list=l_exp_email_id
               and x.fk_k_lsk=k.k_lsk_id
               and x.n1=1))
               
           and exists
         (select *
                  from arch_kart k2
                 where k2.mg = p_mg
                   and k2.k_lsk_id = k.k_lsk_id
                   and decode(p_sel_uk,
                              '0',
                              1,
                              instr(p_sel_uk, '''' || k2.reu || ''';', 1)) > 0)
         order by k.prn_num;
    else
      -- �� ���.����� � ������
      open p_rfcur for
        select k.prn_num, k.for_bill, k.lsk, k.k_lsk_id, k.opl, utils.month_name(SUBSTR(p_mg,
                                        5,
                                        2)) || ' ' ||
                SUBSTR(p_mg,
                       1,
                       4) ||
                ' �.' as mg2, k.kpr, k.kpr_wr, k.kpr_wrp, k.kpr_ot, k.opl, t.name as st_name, -- ������
               decode(t.cd,
                       'MUN',
                       '����������',
                       '�����������') as pers_tp, tp2.name_short||'.'||o2.name||', '||s.name || ', ' ||
                nvl(ltrim(k.nd, '0'), '0') || '-' ||
                nvl(ltrim(k.kw, '0'), '0') as adr, -- �����
               p_mg as mg, scott.utils.month_name(substr(p_mg, 5, 2)) || ' ' ||
                substr(p_mg, 1, 4) || '�.' as mg_str, -- ������
               k.fio
          from scott.arch_kart k
          join u_list tp
            on k.fk_tp = tp.id
          left join scott.spul s
            on k.kul = s.id
          left join scott.t_org o2 on s.fk_settlement=o2.id
          left join scott.t_org_tp tp2 on o2.fk_orgtp=tp2.id
          left join scott.status t
            on k.status = t.id
         where k.mg = p_mg
           and nvl(p_reu, k.reu) = k.reu
           and -- ��� 05.08.2019
               case
                 when p_is_closed = 1 and nvl(k.for_bill, 0) = 1 then
                  1 -- ���� � �.�.��������, � ������
                 when p_is_closed = 0 and k.psch not in (8, 9) then
                  1 -- ���� ������ ��������
                 else
                  0
               end = 1
           and decode(p_sel_obj, 0, p_lsk, k.lsk) >= k.lsk
           and -- �� ���.�����
               decode(p_sel_obj, 0, p_lsk1, k.lsk) <= k.lsk
           and -- �� �����
            decode(p_sel_obj, 1, nvl(p_kul, k.kul), k.kul) = k.kul
           and -- �� ������
           decode(p_sel_obj, 1, nvl(p_nd, k.nd), k.nd) = k.nd
           and decode(p_sel_obj, 1, nvl(p_kw, k.kw), k.kw) = k.kw
           and decode(p_sel_obj, 1, nvl(p_klsk_id, k.k_lsk_id), k.k_lsk_id) = k.k_lsk_id
           and exists
         (select *
                  from arch_kart k2
                 where k2.mg = p_mg
                   and k2.k_lsk_id = k.k_lsk_id
                   and decode(p_sel_uk,
                              '0',
                              1,
                              instr(p_sel_uk, '''' || k2.reu || ''';', 1)) > 0)
         order by k.prn_num;
    end if;
end;

-- ��� ���.�������
procedure main_arch(p_sel_obj   in number, -- ������� �������: 0 - �� ���.�����, 1 - �� ������, 2 - �� ��
               p_kul       in kart.kul%type, -- ��� �����
               p_nd        in kart.nd%type, -- � ����
               p_kw        in kart.kw%type, -- � ��������
               p_lsk       in kart.lsk%type, -- ���.���������
               p_lsk1      in kart.lsk%type, -- ���.��������
               p_is_closed in number, -- �������� �� �������� ����, ���� ���� ����? (0-���, 1-��)
               p_firstNum  in number default null, -- ��������� ����� ����� (��� ������ �� ��) -- ������ ����� ������������! ���.28.05.2020
               p_lastNum   in number default null, -- �������� ����� ����� -- ������ ����� ������������! ���.28.05.2020
               p_mg        in params.period%type default null, -- ������ ������� (��� ���.�������-������ ������� ������) -- ������ ����� ������������! ���.28.05.2020
               p_sel_uk    in varchar2, -- ������ ��
               p_rfcur     out ccur -- ���.���������
               ) is
begin
    -- �� ���.�����, � ������ ��������
    open p_rfcur for
      select k.k_lsk_id, tp2.name_short||'.'||o2.name||', '||s.name || ', ' ||
                nvl(ltrim(k.nd, '0'), '0') || '-' ||
                nvl(ltrim(k.kw, '0'), '0') as adr, k.lsk, k.kpr, k.opl, decode(st.cd,
                       'MUN',
                       '����������',
                       '�����������') as pers_tp, k.fio, o.name as name_uk
        from scott.kart k
          left join scott.kart_detail d on k.lsk=d.lsk
          left join scott.spul s
            on k.kul = s.id
          left join scott.t_org o2 on s.fk_settlement=o2.id
          left join scott.t_org_tp tp2 on o2.fk_orgtp=tp2.id
          left join scott.status st
            on k.status = st.id
          join t_org o on k.reu=o.reu
          join (select *
                  from (select k2.lsk, -- ������ ������������� ��������� � ��������� ��� �����
                                first_value(k2.lsk) over(partition by k2.k_lsk_id order by decode(k2.psch, 8, 1, 9, 1, 0), tp2.npp) as lsk_main
                           from KART k2
                           join u_list tp2
                             on k2.fk_tp = tp2.id
                           where decode(p_sel_obj, 0, p_lsk, k2.lsk) = k2.lsk
                              --and k2.mg = p_mg
                            ) a
                 where a.lsk = a.lsk_main) b
            on b.lsk = k.lsk
       where decode(p_sel_obj, 0, p_lsk, k.lsk) >= k.lsk
         and -- �� ���.�����
             decode(p_sel_obj, 0, p_lsk1, k.lsk) <= k.lsk
         and -- �� ���.�����
             decode(p_sel_obj, 1, nvl(p_kul, k.kul), k.kul) = k.kul
         and -- �� ������
             decode(p_sel_obj, 1, nvl(p_nd, k.nd), k.nd) = k.nd
         and decode(p_sel_obj, 1, nvl(p_kw, k.kw), k.kw) = k.kw
         and case when p_sel_obj=2 and d.prn_num between p_firstNum and p_lastNum then 1
                  when p_sel_obj!=2 then 1
             else 0 end =1
         group by k.k_lsk_id, tp2.name_short||'.'||o2.name||', '||s.name || ', ' ||
                nvl(ltrim(k.nd, '0'), '0') || '-' ||
                nvl(ltrim(k.kw, '0'), '0'), k.lsk, k.kpr, k.opl, decode(st.cd,
                       'MUN',
                       '����������',
                       '�����������'), k.fio, o.name
         order by k_lsk_id;
end;

-- ����������� �� ��
procedure contractors(p_klsk in number, -- klsk ���������
                 p_is_closed in number, -- �������� �� �������� ����, ���� ���� ����? (0-���, 1-��)
                 p_mg in params.period%type, -- ������ �������
                 p_sel_flt_tp in number, -- �������������� ������
                 p_sel_uk in varchar2, -- ������ ��
                 p_rfcur out ccur
  ) is
begin

open p_rfcur for
  select a.*
  from (
  select k.lsk, k.k_lsk_id, k.opl,
         utils.month_name(SUBSTR(p_mg, 5, 2)) || ' ' || SUBSTR(p_mg, 1, 4) || ' �.' as period,
         last_day(to_date(p_mg||'01','YYYYMMDD')) as dt,
         t.name as st_name,
         decode(t.cd, 'MUN','����������','�����������') as pers_tp,
         s.name || ', ' || nvl(ltrim(k.nd, '0'), '0') || '-' ||
         nvl(ltrim(k.kw, '0'), '0') as adr,
         h.postcode||','||o2.name||', ��.'||s.name || ', �. ' || nvl(ltrim(k.nd, '0'), '0') || ', ��.' ||
         nvl(ltrim(k.kw, '0'), '0') as adr2,
        case when stp.cd in ('LSK_TP_ADDIT') then o.r_sch_addit
                    else o3.raschet_schet end as raschet_schet,
        k.k_fam, k.k_im, k.k_ot, k.fio,
        o3.inn, o3.k_schet, o3.kpp, o3.bik, o3.bank, o.full_name, o3.phone, o3.adr as adr_org, o3.name as uk_name,
        o3.adr_www,
        k.psch, stp.cd as lsk_tp, stp.npp as lsk_tp_npp, k.prn_num, k.prn_new
    from scott.arch_kart k
      join scott.u_list stp on k.fk_tp=stp.id
      join scott.spul s on k.kul = s.id
      join scott.status t on k.status=t.id
      join scott.t_org_tp tp on tp.cd='���'
      join scott.t_org o on tp.id=o.fk_orgtp
      join scott.t_org o2 on s.fk_settlement=o2.id
      join scott.t_org_tp tp2 on o2.fk_orgtp=tp2.id
      --join scott.t_org o2 on tp2.id=o2.fk_orgtp
      --join scott.t_org_tp tp2 on tp2.cd='�����'
      join scott.t_org o3 on k.reu=o3.reu
      join scott.c_houses h on k.house_id=h.id
   where k.mg = p_mg and k.k_lsk_id =p_klsk
     and case when p_is_closed = 1 and nvl(k.for_bill,0)=1 then 1 -- ���� � �.�.��������, � ������
              when p_is_closed = 0 and k.psch not in (8,9) then 1 -- ���� ������ ��������
              else 0 end = 1
     and case when p_sel_flt_tp=0 then 1 -- ���
          when p_sel_flt_tp=1 and stp.cd in ('LSK_TP_MAIN','LSK_TP_ADDIT') then 1 -- ��������+������.
          when p_sel_flt_tp=2 and stp.cd in ('LSK_TP_RSO') then 1 -- ������ ���
          else 0 end = 1
     and decode(p_sel_uk, '0', 1, instr(p_sel_uk, ''''||k.reu||''';', 1)) > 0 -- ������ �� ��
   order by k.prn_num
  ) a;

end;

-- �������� QR ��� �����
procedure getQr(p_klsk in number, -- klsk ���������
                 p_is_closed in number, -- �������� �� �������� ����, ���� ���� ����? (0-���, 1-��)
                 p_mg in params.period%type, -- ������ �������
                 p_sel_tp in number, -- 0 - ��� ���.������: �������� � ���, 1 - ���.���, 3 - ��������, 4 - ���
                 p_sel_flt_tp in number, -- �������������� ������: 0 - ��� ���.������: �������� � ���, 1 - ���.���, 3 - ��������, 4 - ���
                 p_sel_uk in varchar2, -- ������ ��
                 p_rfcur out ccur
  ) is
begin

open p_rfcur for
  select
   case when a.ext_lsk is null then 'ST00012'||'|Name='||a.full_name||'|PersonalAcc='||a.raschet_schet||
   '|BankName='||a.bank||'|BIC='||a.bik||'|CorrespAcc='||a.k_schet
   ||'|PayeeINN='||a.inn||'|persAcc='||a.lsk||'|'
   || a.service_name
   else 
     'ST00012'||'|Name=�� "���� ������������ ������� ��������������� ����� ��������"|PersonalAcc='||a.raschet_schet||
   '|BankName='||a.bank||'|BIC='||a.bik||'|CorrespAcc='||a.k_schet
   ||'|PayeeINN='||a.inn||'|persAcc='||a.ext_lsk||'|'
   || a.service_name
   end
    as QR,
   case when lsk_tp='LSK_TP_ADDIT' then '���� ����������' else a.uk_name end as uk_name
  from (
  select k.lsk, e.ext_lsk, k.k_lsk_id, k.opl,
         utils.month_name(SUBSTR(p_mg, 5, 2)) || ' ' || SUBSTR(p_mg, 1, 4) || ' �.' as period,
         last_day(to_date(p_mg||'01','YYYYMMDD')) as dt,
         t.name as st_name,
         decode(t.cd, 'MUN','����������','�����������') as pers_tp,
         s.name || ', ' || nvl(ltrim(k.nd, '0'), '0') || '-' ||
         nvl(ltrim(k.kw, '0'), '0') as adr,
         tp2.name_short||'.'||o2.name||', ��.'||s.name || ', �. ' || nvl(ltrim(k.nd, '0'), '0') || ', ��.' ||
         nvl(ltrim(k.kw, '0'), '0') as adr2,
        case when e.ext_lsk is not null then e.raschet_schet
             when stp.cd in ('LSK_TP_ADDIT') then o.r_sch_addit
                    else o3.raschet_schet end as raschet_schet,
        k.k_fam, k.k_im, k.k_ot, k.fio,
        o3.inn, o3.k_schet, o3.kpp, o3.bik, o3.bank, o.full_name, o3.phone, o3.adr as adr_org, o3.name as uk_name,
        o3.adr_www,
        k.psch, stp.cd as lsk_tp, stp.npp as lsk_tp_npp, k.prn_num, k.prn_new,
        case when o3.service_name_gis is not null then 'SERVICENAME='||o3.service_name_gis||'|' else '' end as service_name
    from arch_kart k
      left join kart_ext e on k.lsk=e.lsk
      join spul s on k.kul = s.id
      join status t on k.status=t.id
      join t_org_tp tp on tp.cd='���'
      join t_org o on tp.id=o.fk_orgtp
      join t_org o2 on s.fk_settlement=o2.id --tp2.id=o2.fk_orgtp
      join t_org_tp tp2 on o2.fk_orgtp=tp2.id--tp2.cd='�����'
      join t_org o3 on k.reu=o3.reu
      join u_list stp on k.fk_tp=stp.id and -- ������ �� ���� ���.������
           case when p_sel_tp=0 and stp.cd not in 'LSK_TP_ADDIT' then 1 -- ���, ����� ����������
                when p_sel_tp=1 and stp.cd in 'LSK_TP_ADDIT' then 1 -- ������.
                when p_sel_tp=3 and stp.cd in 'LSK_TP_MAIN' then 1 -- ��������
                when p_sel_tp=4 then 1 -- ������ ���
                else 0 end = 1
           and case when p_sel_flt_tp=0 then 1 -- ���
                when p_sel_flt_tp=1 and stp.cd in ('LSK_TP_MAIN','LSK_TP_ADDIT') then 1 -- ��������+������.
                when p_sel_flt_tp=2 and stp.cd in ('LSK_TP_RSO') then 1 -- ������ ���
                else 0 end = 1
   where k.mg = p_mg and k.k_lsk_id =p_klsk
     and case when p_is_closed = 1 and nvl(k.for_bill,0)=1 then 1 -- ���� � �.�.��������, � ������
              when p_is_closed = 0 and nvl(k.for_bill,0)=1 and k.psch not in (8,9) then 1 -- ���� ������ ��������
              else 0 end = 1
     and decode(p_sel_uk, '0', 1, instr(p_sel_uk, ''''||k.reu||''';', 1)) > 0 -- ������ �� ��
   order by k.prn_num
  ) a;

end;

procedure detail(p_klsk in number, -- klsk ���������
                 p_is_closed in number, -- �������� �� �������� ����, ���� ���� ����? (0-���, 1-��)
                 p_mg in params.period%type, -- ������ �������
                 p_sel_tp in number, -- 0 - ��� ���.������: �������� � ���, 1 - ���.���, 3 - ��������, 4 - ���
                 p_sel_flt_tp in number, -- �������������� ������: 0 - ��� ���.������: �������� � ���, 1 - ���.���, 3 - ��������, 4 - ���
                 p_sel_uk in varchar2, -- ������ ��
                 p_rfcur out ccur
  ) is
begin

open p_rfcur for
  select a.*
  from (
  select k.lsk, 
         coalesce(e.ext_lsk, k.lsk) as lsk_display, -- ���.���� ��� ����������� � �����
         k.k_lsk_id, k.opl,
         utils.month_name(SUBSTR(p_mg, 5, 2)) || ' ' || SUBSTR(p_mg, 1, 4) || ' �.' as period,
         last_day(to_date(p_mg||'01','YYYYMMDD')) as dt,
         t.name as st_name,
         decode(t.cd, 'MUN','����������','�����������') as pers_tp,
         s.name || ', ' || nvl(ltrim(k.nd, '0'), '0') || '-' ||
         nvl(ltrim(k.kw, '0'), '0') as adr,
         tp2.name_short||'.'||o2.name||', ��.'||s.name || ', �. ' || nvl(ltrim(k.nd, '0'), '0') || ', ��.' ||
         nvl(ltrim(k.kw, '0'), '0') as adr2,
        case when stp.cd in ('LSK_TP_ADDIT') then o.r_sch_addit
                    else o3.raschet_schet end as raschet_schet,
        s1.sal_in,
        s2.sal_out,
        k.k_fam, k.k_im, k.k_ot, k.fio,
        o3.inn, o3.k_schet, o3.kpp, o3.bik, o3.bank, o.full_name, o3.phone, o3.adr as adr_org, o3.name as uk_name,
        o3.adr_www,
        k.psch, stp.cd as lsk_tp, stp.npp as lsk_tp_npp, k.prn_num, k.prn_new,
        p1.penya_in, p2.penya_charge, p3.penya_corr,
        p4.penya_pay, p5.penya_out, p4.pay,
        p4.last_dtek, nvl(p6.charge,0) +
         case when p_is_closed = 0 and k.psch not in (8,9) or p_is_closed = 1 then nvl(p8.change,0)
            else 0 end as charge, null as qr -- ��� ������ �������
    from scott.arch_kart k
      left join kart_ext e on k.lsk=e.lsk
      join scott.spul s on k.kul = s.id
      join scott.status t on k.status=t.id
      join scott.t_org_tp tp on tp.cd='���'
      join scott.t_org o on tp.id=o.fk_orgtp
      join scott.t_org o2 on s.fk_settlement=o2.id --tp2.id=o2.fk_orgtp
      join scott.t_org_tp tp2 on o2.fk_orgtp=tp2.id--tp2.cd='�����'
      join scott.t_org o3 on k.reu=o3.reu
      join scott.u_list stp on k.fk_tp=stp.id and -- ������ �� ���� ���.������
           case when p_sel_tp=0 and stp.cd not in 'LSK_TP_ADDIT' then 1 -- ���, ����� ����������
                when p_sel_tp=1 and stp.cd in 'LSK_TP_ADDIT' then 1 -- ������.
                when p_sel_tp=3 and stp.cd in 'LSK_TP_MAIN' and k.psch not in (8,9) then 1 -- �������� ����� �������� ������ � ���� p_sel_tp=3!!! (���� ���.29.12.18)
                when p_sel_tp=4 then 1 -- ������ ���
                else 0 end = 1 and
           case when p_sel_flt_tp=0 then 1 -- ���
                when p_sel_flt_tp=1 and stp.cd in ('LSK_TP_MAIN','LSK_TP_ADDIT') then 1 -- ��������+������.
                when p_sel_flt_tp=2 and stp.cd in ('LSK_TP_RSO') then 1 -- ������ ���
                else 0 end = 1
      left join (select l.lsk, sum(l.summa) as sal_in -- ������ ��������
            from scott.saldo_usl l
           where l.mg=p_mg
           group by l.lsk) s1 on k.lsk=s1.lsk
      left join (select l.lsk, sum(l.summa) as sal_out -- ������ ���������
            from scott.saldo_usl l
           where l.mg=scott.utils.add_months_pr(p_mg, 1)
           group by l.lsk) s2 on k.lsk=s2.lsk
      left join (select l.lsk, sum(l.penya) as penya_in -- ������ �� ���� ��������
            from scott.a_penya l
           where l.mg=scott.utils.add_months_pr(p_mg, -1)
           group by l.lsk) p1 on k.lsk=p1.lsk
      left join (select l.lsk, sum(l.penya) as penya_out -- ������ �� ���� ���������
            from scott.a_penya l
           where l.mg=p_mg
           group by l.lsk) p5 on k.lsk=p5.lsk
      left join (select l.lsk, sum(l.summa) as charge -- ���������� �������
            --from scott.tmp_a_charge l join kart t on l.lsk=t.lsk and t.k_lsk_id=p_klsk
            from scott.a_charge2 l  -- ��������� �������
           where
              p_mg between l.mgFrom and l.mgTo and
              l.type=1
              --and l.mgfrom in (select b.mg from long_table b where b.mg>=p_mg) -- ��������� 04.08.2019 -- ������������ ������� ���.11.02.2020
              --and p_mg <=l.mgto -- ���. 11.02.2020 - ������ ������������ �������
           group by l.lsk) p6 on k.lsk=p6.lsk
      left join (select l.lsk, sum(l.summa) as change -- �����������
            from scott.a_change l
           where l.mg=p_mg
           group by l.lsk) p8 on k.lsk=p8.lsk
      left join (
           select l.lsk, sum(penya_charge) as penya_charge from (
             select t.lsk, t.mg1, round(sum(t.penya),2) as penya_charge -- ���������� �� ���� �������
              from scott.a_pen_cur t
             where t.mg=p_mg
             group by t.lsk, t.mg1) l
           group by l.lsk
           ) p2 on k.lsk=p2.lsk
      left join (select l.lsk, sum(l.penya) as penya_corr -- ������������� �� ���� �������
            from scott.a_pen_corr l
           where l.mg=p_mg
           group by l.lsk) p3 on k.lsk=p3.lsk
      left join (select l.lsk, max(l.dtek) as last_dtek, -- ���� �������, ���������
           sum(l.summa) as pay, -- ������ �������
           sum(l.penya) as penya_pay -- ������ �� ���� �������
            from scott.a_kwtp_mg l
           where l.mg=p_mg
           group by l.lsk) p4 on k.lsk=p4.lsk
   where k.mg = p_mg and k.k_lsk_id =p_klsk
     and case when p_is_closed = 1 and nvl(k.for_bill,0)=1 then 1 -- ���� � �.�.��������, � ������
              when p_is_closed = 0 and k.psch not in (8,9) then 1 -- ���� ������ ��������
              else 0 end = 1
     and (nvl(p1.penya_in,0)<>0 or nvl(p2.penya_charge,0)<>0 or nvl(p3.penya_corr,0)<>0 or
        nvl(p4.penya_pay,0)<>0 or nvl(p5.penya_out,0)<>0 or nvl(p4.pay,0)<>0
        or (nvl(p6.charge,0) +
         case when p_is_closed = 0 and k.psch not in (8,9) or p_is_closed = 1 then nvl(p8.change,0)
            else 0 end) <> 0
        or p_is_closed = 1 and nvl(s2.sal_out,0)<>0
        or p_is_closed = 1 and nvl(p5.penya_out,0)<>0
        or e.ext_lsk is not null and nvl(s2.sal_out,0)<>0 -- ���� ��.���.����, � ������
      )
     and decode(p_sel_uk, '0', 1, instr(p_sel_uk, ''''||k.reu||''';', 1)) > 0 -- ������ �� ��
   order by stp.npp, decode(k.psch,8,999,9,999,0)
  ) a;

end;

-- �������� ������� �� klsk
procedure funds_flow_by_klsk(
                 p_klsk in number, -- klsk ���������
                 p_sel_tp in number, -- 0 - ��� ���.������: �������� � ���, 1 - ���.���, 3 - ��������, 4 - ���
                 p_sel_flt_tp in number, -- �������������� ������: 0 - ��� ���.������: �������� � ���, 1 - ���.���, 3 - ��������, 4 - ���
                 p_is_closed in number, -- �������� �� �������� ����, ���� ���� ����? (0-���, 1-��)
                 p_mg in params.period%type, -- ������ �������
                 p_sel_uk in varchar2, -- ������ ��
                 p_rfcur out ccur
                 ) is
  cur1 SYS_REFCURSOR;
  type rec is record(
    is_amnt_sum      number,  -- ����������� � ���� � fastreport
    usl         CHAR(3), -- ��� ������
    npp           NUMBER, -- � �.�.
    name         VARCHAR2(100), -- ������������
    price        NUMBER, -- ����
    vol          NUMBER, -- �����
    charge       NUMBER, -- ����������
    change1      NUMBER, -- ����������
    change_proc1 NUMBER, -- % �� �����������
    change2      NUMBER, -- ����������
    amnt         NUMBER, -- �����
    deb          NUMBER,  -- ������(�������������)
    bill_col     number, -- � ����� ������� �������� ����� (�������� usl.bill.col)
    bill_col2     number, -- � ����� ������� �������� ����� (�������� usl.bill.col)
    kub          number,  -- ����� ����
    pay          number, -- ������� ������
    chargeOwn    number -- ���������� �� �������������� ����������� (��� �������� usl.bill_col=1), � �.�. �����������
    );
  r rec;
  l_last number;
begin

  tab:= tab_bill_detail();
  for c in (select k.lsk, k.psch from kart k join scott.u_list stp on k.fk_tp=stp.id and -- ������ �� ���� ���.������ ���.05.03.20 - ����� ����� arch_kart
                     case when p_sel_tp=0 and stp.cd not in 'LSK_TP_ADDIT' then 1 -- ���, ����� ����������
                          when p_sel_tp=1 and stp.cd in 'LSK_TP_ADDIT' then 1 -- ������.
                          when p_sel_tp=3 and stp.cd in 'LSK_TP_MAIN' then 1 -- ��������
                          when p_sel_tp=4 then 1 -- ������ ���
                          else 0 end = 1
                     and case when p_sel_flt_tp=0 then 1 -- ���
                          when p_sel_flt_tp=1 and stp.cd in ('LSK_TP_MAIN','LSK_TP_ADDIT') then 1 -- ��������+������.
                          when p_sel_flt_tp=2 and stp.cd in ('LSK_TP_RSO') then 1 -- ������ ���
                          else 0 end = 1
                     where k.k_lsk_id=p_klsk-- and k.mg=p_mg ���.05.03.20 - ����� arch_kart, ����� �������
                          and decode(p_sel_uk, '0', 1, instr(p_sel_uk, ''''||k.reu||''';', 1)) > 0 -- ������ �� ��
                   ) loop

       rep_bills_ext.detail(p_lsk => c.lsk,
                     p_mg    => p_mg,
                     p_includeSaldo => 0,
                     p_rfcur => cur1);
       loop
         fetch cur1 into r;
         exit when cur1%notfound;
         tab.extend;
         l_last:=tab.last;
         tab(l_last):=rec_bill_detail(r.is_amnt_sum, r.usl,
           r.npp, r.name, r.price, r.vol,
           r.charge,
           case when p_is_closed = 0 and c.psch not in (8,9) or p_is_closed = 1 then r.change1 else 0 end,
           case when p_is_closed = 0 and c.psch not in (8,9) or p_is_closed = 1 then r.change_proc1 else 0 end,
           case when p_is_closed = 0 and c.psch not in (8,9) or p_is_closed = 1 then r.change2 else 0 end,
           r.amnt, r.deb, r.bill_col, r.bill_col2, r.kub, r.pay, r.chargeOwn);
       end loop;
  end loop;

  open p_rfcur for select * from table(tab) t
    where nvl(t.price,0)<>0 or nvl(t.charge,0)<>0
       or nvl(t.change1,0)<>0
       or nvl(t.change2,0)<>0
       --or t.amnt <>0
       or t.deb<>0 --or t.kub<>0
       ;
end;

procedure get_chargepay(p_lsk in varchar2, -- ���.��.
                 p_mg in params.period%type default '000000', -- �������� ������ -- ���.17.06.21
                 p_mg_from in params.period%type default '000000', -- ������ �������
                 p_mg_to in params.period%type default '999999', -- ������ �������
                 p_rfcur out ccur
  ) is
begin
  open p_rfcur for 
   select b.summa as charge, c.summa as payment,
       nvl(b.summa, 0) - nvl(c.summa, 0) as dolg, 
       d.penya as penya,
       d2.penya as penya_in,
       d3.penya as penya_curr,
       d5.penya_corr as penya_corr,
       d4.penya as penya_pay,
       d3.days as penya_curr_days,
       nvl(d.dolg_pen, 0) + nvl(d.penya, 0) as itog,
       substr(a.mg, 5, 2) || '.' || substr(a.mg, 1, 4) as mg, 
       a.mg as mg2, 
       d.days,
       d.dolg_pen,
       sum(nvl(b.summa, 0) - nvl(c.summa, 0)) over(order by a.mg) as prev_sum,
       e.summa as sal
  from scott.long_table a
  left join (select mg, sum(summa) as summa from scott.c_chargepay2 where /*(select period from scott.params)*/ p_mg between mgFrom and mgTo
                and lsk = p_lsk
                and type = 0
              group by mg) b
    on a.mg = b.mg
  left join (select mg, sum(summa) as summa from scott.c_chargepay2 where /*(select period from scott.params)*/ p_mg between mgFrom and mgTo
                and lsk = p_lsk
                and type = 1
              group by mg) c
    on a.mg = c.mg
  left join (select t.mg, sum(t.summa) as summa
               from scott.saldo_usl t
              where --�������� ������
              lsk = p_lsk
              group by mg) e
    on a.mg = e.mg
  left join (select summa as dolg_pen, penya, days, mg1 from scott.a_penya/*scott.c_penya*/  --���.������ �� ����
              where lsk = p_lsk and mg = p_mg) d
    on a.mg = d.mg1
  left join (select penya, mg1
               --from scott.a_penya c where lsk = p_lsk and c.mg=(select scott.utils.add_months_pr(m.period,-1) from scott.v_params m)  --��.������ �� ����
               from scott.a_penya c where lsk = p_lsk and c.mg=scott.utils.add_months_pr(p_mg,-1)  --��.������ �� ����
              ) d2
    on a.mg = d2.mg1
  left join (select round(sum(penya),2) as penya,sum(c.curdays) as days, mg1 from scott.a_pen_cur c  --������� ����
              where lsk = p_lsk and mg=p_mg
              and c.penya > 0
              group by mg1
              ) d3
    on a.mg = d3.mg1
  left join (select round(sum(c.penya),2) as penya, c.dopl from scott.a_kwtp_mg c  --������ ����
              where lsk = p_lsk and c.dtek <= scott.init.get_date --����� ��� ���� �����!
              and mg=p_mg
              group by c.dopl
              ) d4
    on a.mg = d4.dopl
  left join (select sum(c.penya) as penya_corr, c.dopl from scott.a_pen_corr c  --������������� ����
              where c.lsk = p_lsk
              and c.penya <> 0 --������ �� ���� >0 - �������� ���.30.05.2017
              and mg=p_mg              
              group by c.dopl
              ) d5
    on a.mg = d5.dopl
 where --a.mg between coalesce(p_mg_from,'0000000') and coalesce(p_mg_to,'999999') and
 (nvl(b.summa, 0) <> 0 or 
       nvl(c.summa, 0) <> 0 or
       nvl(e.summa, 0) <> 0 or
       nvl(d.penya, 0) <> 0 or
       nvl(d.dolg_pen, 0) <> 0 or
       nvl(d2.penya, 0) <> 0 or
       nvl(d3.penya, 0) <> 0
       )
 order by a.mg;

  
end;  

end rep_bills_compound;
/

