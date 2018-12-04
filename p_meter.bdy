create or replace package body scott.p_meter is

  --�������� �������
  function ins_meter(p_npp        number, --� �.�.
                    p_usl         in usl.usl%type, -- ������
                    p_dt1         in date,         -- ������ ������ �..
                    p_dt2         in date,         -- ������ ������ ��..
                    p_n1          in number, --��������� ���������
                    p_fk_klsk_obj in number, --������ � �������� ���������
                    p_tp          in u_list.cd%type --��� (�������� ���)
                    ) return number is
    l_num_id number;
    l_vol_id number;
    l_user number;
    l_counter usl.counter%type;
    l_lsk kart.lsk%type;
    l_mg params.period%type;
  begin

    for c in (select k_lsk_id.nextval as klsk, u.id as fk_tp
                from u_list u, u_listtp tp
               where u.cd = p_tp
                 and tp.cd = 'object_type') loop

      insert into k_lsk (id, fk_addrtp) values (c.klsk, c.fk_tp);

        for c2 in (select 1 as exs, t.id as fk_tp
                     from u_list t
                    where t.cd = p_tp) loop
          insert into meter
            (npp, k_lsk_id, fk_usl, dt1, dt2, fk_klsk_obj)
          values
            (p_npp, c.klsk, p_usl, p_dt1, p_dt2, p_fk_klsk_obj);

        select max(decode(u.cd,'ins_sch',u.id,0)), max(decode(u.cd,'ins_vol_sch',u.id,0)), max(s.id), trim(max(u2.counter)), trim(max(k.lsk)), max(p.period)
          into l_num_id, l_vol_id, l_user, l_counter, l_lsk, l_mg  from u_list u, t_user s, meter m, usl u2, kart k, params p
         where u.cd in ('ins_sch', 'ins_vol_sch')
         and s.cd = user and m.k_lsk_id=c.klsk and m.fk_klsk_obj=k.k_lsk_id
         and m.fk_usl=u2.usl;

         --�������� ��������� ��������� (��� ������!!!)
         if nvl(p_n1,0)<>0 then
           insert into t_objxpar (fk_k_lsk, fk_list, n1, fk_user, mg)
             values(c.klsk, l_num_id, p_n1, l_user, l_mg);
           --��������� ��������� ��������� � ��������
           update meter m set m.n1=p_n1 where m.k_lsk_id=c.klsk;
           --�������� ��������� � kart
           execute immediate 'update kart k set k.'||l_counter||'=nvl('||p_n1||',0) where k.lsk='||l_lsk;
         end if;
          --������� klsk ������ ��������
          return c.klsk;
        end loop;

      exit;
    end loop;
  end;

  --������ ������ ��� ����� ��������� �� ��������
  function ins_vol_meter(p_met_klsk in number, -- klsk �������� --���� klsk ��������
                         p_lsk in kart.lsk%type, --���.����     --���� ���.���� + ������!
                         p_usl in usl.usl%type,  --������
                         p_vol in number, -- �����
                         p_n1 in number, -- �� ������������!
                         p_tp in number default 0 -- ��� (0-������ ����, 1-��������������, 2-������ ����������
                         ) return number is
  l_num_id number;
  l_vol_id number;
  l_user number;
  l_counter usl.counter%type;
  l_lsk kart.lsk%type;
  l_dt2 date; --���� �������� ��������
  l_dt date; --���� ������ ������
  l_period params.period%type; --������� ������
  l_met_klsk number;
  l_cnt number;
  l_flag number;
  begin
    -- ����, ��� �� ���� ��������� ���������� � ��������
    g_flag:=1;
    if p_met_klsk is null and (p_lsk is null or p_usl is null) then
      Raise_application_error(-20000, '������������ ������������� ������� p_meter.ins_vol_meter, p_lsk � p_usl ��� k_lsk ������������ ������!');
    end if;
    if p_vol is null then
       -- ���.25.01.18 ��� ������ � �����. ��� ���� ������ ������ ��������� �������� (���?)
       return 3; -- ������! �� ��� ������� �����
    end if;

    if p_met_klsk is not null then
      -- �� klsk ��������
      l_met_klsk:=p_met_klsk;
    else
       -- �� lsk ���.�����, ������� ������ �������� �� ������� id �������, �������� �� ���� �����
       for c in (
          select m.k_lsk_id into l_met_klsk
                       from kart k join params p on 1=1
                       join v_lsk_tp tp on k.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')
                      join meter m on k.k_lsk_id=m.fk_klsk_obj and m.fk_usl=p_usl
                      and k.lsk=p_lsk and
                      case when m.dt1 <=last_day(to_date(p.period||'01', 'YYYYMMDD'))
                            and m.dt2 > last_day(to_date(p.period||'01', 'YYYYMMDD'))
                            then 1 else 0 end =1
                              order by m.id) loop

          l_met_klsk:=c.k_lsk_id;
          exit;
      end loop;

      if l_met_klsk is null then
        g_flag:=0;
        return 2; -- ������, ��� �������� ���������, �������� ����� �� ��������!
      end if;
    end if;

    -- ���� ������� ��� ���.����� � ����� k_lsk �� ����� ����� ����� ������������ �� ��� � �� ��� ��������� kart.mgw ��� kart.mhw � �����...
    select max(decode(u.cd,'ins_sch',u.id,0)), max(decode(u.cd,'ins_vol_sch',u.id,0)), max(s.id),
      trim(max(u2.counter)), trim(max(k.lsk)), max(m.dt2),
      max(to_date(p.period||'01', 'YYYYMMDD')), max(p.period)
      into l_num_id, l_vol_id, l_user, l_counter, l_lsk, l_dt2, l_dt, l_period
      from u_list u, t_user s, meter m, usl u2, kart k, params p, v_lsk_tp tp
     where u.cd in ('ins_sch', 'ins_vol_sch')
     and s.cd = user and m.k_lsk_id=l_met_klsk and m.fk_klsk_obj=k.k_lsk_id
     and k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
     and m.fk_usl=u2.usl and k.psch not in (8,9);

     if p_lsk is not null then
       --���� ������ ���.����, �� ������������ ���
       l_lsk:=p_lsk;
     end if;


     l_flag:=0;
     if l_dt2 > l_dt then
       if (nvl(p_vol,0)) <> 0 then
         -- ������ ����� ������ ������
         --�������� �����
         insert into t_objxpar (fk_k_lsk, fk_list, n1, fk_user, mg, tp)
           values(l_met_klsk, l_vol_id, p_vol, l_user, l_period, p_tp);

         select nvl(m.n1,0) + nvl(p_vol,0) into l_cnt
           from meter m where m.k_lsk_id=l_met_klsk;
         
         --�������� ��������� ��������� � �������� + ������
         update meter m set m.n1=l_cnt where m.k_lsk_id=l_met_klsk;

         --�������� ���������
         insert into t_objxpar (fk_k_lsk, fk_list, n1, fk_user, mg, tp)
           values(l_met_klsk, l_num_id, l_cnt, l_user, l_period, p_tp);

         --�������� ��������� � ����� ������ �� ����� � kart
         execute immediate 'update kart k set k.'||l_counter||'=nvl(k.'||l_counter||',0)+nvl('||p_vol||',0) where k.lsk='||l_lsk;
         --������ ������ ����� �� "m" - �������� ���� ��� ������� (������)
         execute immediate 'update kart k set k.'||'m'||substr(l_counter,2,3)||'=nvl(k.'||'m'||substr(l_counter,2,3)||',0) + nvl('||p_vol||+',0) where k.lsk='||l_lsk;

         l_flag:=1;

         g_flag:=0; -- ����� ���� �� ���������� � ��������

       end if;

       if l_flag=1 then
         return 0;
       else
         return 3; -- ������! �� ��� ������� �����
       end if;
     else
       -- ������! ������� �������� ����� �� ��������� ��������!
       return 1;
     end if;
  end;

  -- �������������� �� ���������
function gen_auto_chrg_all(p_set in number, p_usl in usl.usl%type)
    return number is
    l_counter usl.counter%type;
    l_mg1     params.period%type;
    l_mg2     params.period%type;
    l_cnt     t_objxpar.n1%type;
    l_tp      t_objxpar.tp%type;
    l_ret     number;
    l_ret2     number;
    l_months  spr_params.parn1%type;
    l_usl_nm  varchar2(100);
    l_otop    number; --������.������
  begin
    logger.log_(null, 'p_meter.gen_auto_chrg_all ������ �� ������ usl='||p_usl);
    --�������������� �� ���������, �� ������
    l_ret := 1;

    --������ ������������ �� �����?
    --(�� ��������� ���� ������) - ���� ���... ������ ����� �� ��������
    select case
             when last_day(to_date(p.period || '01', 'YYYYMMDD')) between
                  utils.get_date_param('MONTH_HEAT1') --�����.������.������
                  and utils.get_date_param('MONTH_HEAT2') then
              1
             else
              0
           end
      into l_otop
      from params p;

    --�� ��������, �� ��������� N �������, �� �� ����� ��� �� ��������� 3 ���.
    select trim(t.counter), trim(t.nm)
      into l_counter, l_usl_nm
      from usl t
     where t.usl = p_usl;
    l_months := utils.get_int_param('AUTOCHRGM');

    if p_set = 1 then
      --��������������
      --������, �� ���� ����� �� �������� ������
      select to_char(add_months(to_date(p.period || '01', 'YYYYMMDD'),
                                -1 * l_months),
                     'YYYYMM'),
             to_char(add_months(to_date(p.period || '01', 'YYYYMMDD'), -1),
                     'YYYYMM')
        into l_mg1, l_mg2
        from params p;

      --����� ����������� �������� (���������� � ���������)
      if utils.get_int_param('DEL_BRK_SCH')=1 then
        del_broken_meter(p_usl);
      end if;

      for c in (select k.lsk,
                       nvl(sum(case
                                 when a.psch in (1, 2) then
                                  1
                                 else
                                  0
                               end),
                           0) as m_hw, --�������, ����� ������� ��� ����������
                       nvl(sum(case
                                 when a.psch in (1, 2) then
                                  a.mhw
                                 else
                                  0
                               end),
                           0) as cnt_hw, --�����, ����� ������� ��� ����������
                       nvl(sum(case
                                 when a.psch in (1, 3) then
                                  1
                                 else
                                  0
                               end),
                           0) as m_gw, --� ��� �����...
                       nvl(sum(case
                                 when a.psch in (1, 3) then
                                  a.mgw
                                 else
                                  0
                               end),
                           0) as cnt_gw,
                       nvl(sum(case
                                 when a.sch_el in (1) then
                                  1
                                 else
                                  0
                               end),
                           0) as m_el,
                       nvl(sum(case
                                 when a.sch_el in (1) then
                                  a.mel
                                 else
                                  0
                               end),
                           0) as cnt_el
                  from arch_kart a join v_lsk_tp tp on a.fk_tp=tp.id and tp.cd='LSK_TP_MAIN' and a.psch not in (8, 9)
                       and a.mg between l_mg1 and l_mg2
                   join kart k on a.k_lsk_id=k.k_lsk_id and k.fk_tp=a.fk_tp and k.psch not in (8,9)
                     and (l_otop = 0 and l_counter = 'pgw' and nvl(k.kran1,0) <> 1 or  --������������ ����� �� ����.��������� (������ ��� �.�.!!!)
                          l_otop = 1 and l_counter = 'pgw' or
                          l_counter <> 'pgw')
                     and ((k.psch in (1, 2) and l_counter = 'phw' and
                               nvl(k.mhw, 0) = 0) or
                               (k.psch in (1, 3) and l_counter = 'pgw' and
                               nvl(k.mgw, 0) = 0) or
                               (k.sch_el = 1 and l_counter = 'pel') and
                               nvl(k.mel, 0) = 0)
                 group by k.lsk) loop
        --��������!, ���������� ��� ���, ���� ����� ������������ ������������� �� �������!
        if l_counter = 'phw' then
          --������������� �� �.�.
          if c.m_hw >= 3 and c.cnt_hw > 0 then
            --�� ����� 3 ������� �������
            l_ret2:=ins_vol_meter(p_met_klsk => null, p_lsk => c.lsk, p_usl => p_usl, p_vol => round(c.cnt_hw / c.m_hw, 3), p_n1 => null, p_tp => 1);
            if l_ret2 = 0 then
              l_ret := 0;
            end if;
--            update kart k
--               set k.phw = nvl(k.phw, 0) + round(c.cnt_hw / c.m_hw, 3)
--             where k.lsk = c.lsk;
          end if;
        elsif l_counter = 'pgw' then
          --������������� �� �.�.
          if c.m_gw >= 3 and c.cnt_gw > 0 then
            --�� ����� 3 ������� �������
            l_ret2:=ins_vol_meter(p_met_klsk => null, p_lsk => c.lsk, p_usl => p_usl, p_vol => round(c.cnt_gw / c.m_gw, 3), p_n1 => null, p_tp => 1);
            if l_ret2 = 0 then
              l_ret := 0;
            end if;
--            update kart k
--               set k.pgw = nvl(k.pgw, 0) + round(c.cnt_gw / c.m_gw, 3)
--             where k.lsk = c.lsk;
          end if;
        elsif l_counter = 'pel' then
          --������������� �� ��.��.
          if c.m_el >= 3 and c.cnt_el > 0 then
            --�� ����� 3 ������� �������
            l_ret2:=ins_vol_meter(p_met_klsk => null, p_lsk => c.lsk, p_usl => p_usl, p_vol => round(c.cnt_el / c.m_el, 3), p_n1 => null, p_tp => 1);
            if l_ret2 = 0 then
              l_ret := 0;
            end if;
--            update kart k
--               set k.pel = nvl(k.pel, 0) + round(c.cnt_el / c.m_el, 3)
--             where k.lsk = c.lsk;
          end if;
        end if;
      end loop;
    elsif p_set = 0 then
      --������ �������������� (������)
      for c in (select m.k_lsk_id, t.n1
                  from meter m, t_objxpar t, params p, u_list s
                 where t.fk_k_lsk=m.k_lsk_id and t.mg = p.period
                   and s.cd = 'ins_vol_sch'
                   and m.fk_usl=p_usl
                   and t.fk_list = s.id
                   and t.tp in (1) --��� - �������������
                   and t.id= --��������� ��������
                   (
                   select max(t.id)
                  from meter m2, t_objxpar t, params p, u_list s
                 where t.fk_k_lsk=m2.k_lsk_id and t.mg = p.period
                   and s.cd = 'ins_vol_sch'
                   and m2.fk_usl=p_usl
                   and t.fk_list = s.id
                   and t.tp in (1) --��� - �������������
                   and m2.id=m.id
                   )
                 ) loop

            l_ret2:=ins_vol_meter(p_met_klsk => c.k_lsk_id, p_lsk => null, p_usl => null, p_vol => -1*c.n1, p_n1 => null, p_tp => 2);
            if l_ret2 = 0 then
              l_ret := 0;
            end if;
      end loop;

    end if;
    commit;
    if p_set = 1 then
      logger.log_(null,
                  'p_meter.gen_auto_chrg_all ���������-������������� �� �������� �� ������ usl='||p_usl);
    elsif p_set = 0 then
      logger.log_(null,
                  'p_meter.gen_auto_chrg_all ���������-������:�������������� �� �������� �� ������ usl='||p_usl);
    end if;

    return l_ret;
  end;

--�������� ��� ������� �������� ��� �� ��������� ���� ������ ��� kart.psch
function getpsch(p_lsk in kart.lsk%type) return number is
begin

for c in (
  with t as
   (select distinct d.dat,
                    case
                      when m.fk_usl is not null and m2.fk_usl is not null then
                       1 -- �.�. � �.�.
                      when m.fk_usl is not null and m2.fk_usl is null then
                       2 -- �.�.
                      when m.fk_usl is null and m2.fk_usl is not null then
                       3 -- �.�.
                      else
                       0
                    end as psch
      from v_cur_days d
      join kart k
        on k.lsk = p_lsk
      join usl u on u.cd='�.����'
      join usl u2 on u2.cd='�.����'
      left join meter m
        on k.k_lsk_id = m.fk_klsk_obj
       and d.dat between m.dt1 and m.dt2
       and m.fk_usl = u.usl
      left join meter m2
        on k.k_lsk_id = m2.fk_klsk_obj
       and d.dat between m2.dt1 and m2.dt2
       and m2.fk_usl = u2.usl)
  select psch, min(dat) as dt1, max(dat) as dt2
    from (select t.*,
                  row_number() over(order by dat) - row_number() over(partition by psch order by dat) as grp
             from t)
   group by grp, psch
   order by dt1 desc) loop

   return c.psch;

  end loop;

  -- ��� ����������� ����������, ������� ��������
  return 0;


end;

--�������� ��� ������� ��������������� ��� �� ��������� ���� ������ ��� kart.psch
function getElpsch(p_lsk in kart.lsk%type) return number is
begin

for c in (
  with t as
   (select distinct d.dat,
                    case
                      when m.fk_usl is not null then
                       1 -- ���� �������
                      else
                       0 -- ��� ��������
                    end as psch
      from v_cur_days d
      join kart k
        on k.lsk = p_lsk
      join usl u on u.cd='��.�����.2'
      left join meter m
        on k.k_lsk_id = m.fk_klsk_obj
       and d.dat between m.dt1 and m.dt2
       and m.fk_usl = u.usl)
  select psch, min(dat) as dt1, max(dat) as dt2
    from (select t.*,
                  row_number() over(order by dat) - row_number() over(partition by psch order by dat) as grp
             from t)
   group by grp, psch
   order by dt1 desc) loop

   return c.psch;

  end loop;

  -- ��� ����������� ����������, ������� ��������
  return 0;


end;

  -- ���������� ����������� ��������
  procedure del_broken_meter(p_usl in varchar2) is
    l_dt1 date;
    l_dt2 date;
    l_mg params.period%type;
    l_back_6_month params.period%type;
    l_ret number;
  begin
  -- ������ ���� ������
  l_dt1:=gdt(1,0,0);
  -- ��������� ���� ������
  l_dt2:=gdt(32,0,0);
  select p.period into l_mg
    from params p;
  -- ������ ����� �� 6 ���
  l_back_6_month:=utils.add_months_pr(mg_ => l_mg,cnt_ => -6); 

  logger.log_(time_ => null, comments_ => 'p_meter.del_broken_meters: ������ ��������� ����������� ���������');
  -- ����� ����������� ��������
  for c in (select m.id, us.nm, m.fk_usl, k.lsk, m.k_lsk_id, t.fk_meter, months_between(l_dt1, t.dt1) as cnt_months, --���-�� ���. �� ������
                 case when not t.dt1 < l_dt1  --���� �������� ��������
                   then l_dt1 else t.dt1 end dt1
                 from c_reg_sch t
                 join u_list u on t.fk_tp=u.id and u.cd='������� ��'
                 join u_list u2 on t.fk_state=u2.id and u2.cd='���������� ��'
                 and t.dt1 < l_dt2 -- ���������� ���.��������
                 join meter m on m.id=t.fk_meter and m.dt2 > l_dt2 -- �������� �������
                   and m.fk_usl=p_usl
                 left join (select k_lsk_id, trim(max(t.lsk)) as lsk from kart t
                      where t.psch not in (8,9) group by k_lsk_id) k on m.fk_klsk_obj=k.k_lsk_id
                 join usl us on m.fk_usl=us.usl
              where
              months_between(l_dt1, t.dt1) > 0 and
              not exists (select * from c_reg_sch t2 -- ��� ��� ������ �������� �������
                 join u_list u3 on t2.fk_tp=u3.id and u3.cd='������� ��'
                 join u_list u4 on t2.fk_state=u4.id and u4.cd in ('���������� ��','�������� ��')
                 where t2.dt1 > t.dt1 -- �������!
                  and t2.fk_meter=t.fk_meter))
  loop

    if c.cnt_months > 2 then

      -- ����� ������� ������ �� ��������
      for c2 in (select t.n1*-1 as vol from t_objxpar t
          join u_list u on t.fk_list=u.id and u.cd='ins_vol_sch'
          join t_user s on s.cd=user
          where t.fk_k_lsk=c.k_lsk_id and t.mg=l_mg
          and not exists (select * from t_objxpar x where x.fk_k_lsk=t.fk_k_lsk and x.mg=l_mg and x.tp=4) --��� �� ���� ������ �� ��������
          ) loop

        l_ret:=ins_vol_meter(p_met_klsk => c.k_lsk_id, p_lsk => null, p_usl => null, p_vol => c2.vol, p_n1 => null, p_tp => 4);
        if l_ret <> 0 then
          Raise_application_error(-20000, '������ ������ ������� �������� � id='||c.id);
        end if;
      end loop;

      -- ������� �������, ������� �� ��������� ������ 2 ���.
      update meter t set t.dt2=c.dt1 where t.id=c.fk_meter;

      logger.log_act(c.lsk,
                     '### ����������� ������� id='||c.id||' �� ������: ' || trim(c.nm) ||
                     ', >= 3 ������, ���������� ��������',
                     2);
    else
      -- ����� ������� ������ �� ��������, ������� �� ��������� ����� 2 ���.(� �������������� ���������� ������� �� 6 ���)
      for c2 in (select t.n1*-1 as vol from t_objxpar t
          join u_list u on t.fk_list=u.id and u.cd='ins_vol_sch'
          join t_user s on s.cd=user
          where t.fk_k_lsk=c.k_lsk_id and t.mg=l_mg
          and not exists (select * from t_objxpar x where x.fk_k_lsk=t.fk_k_lsk and x.mg=l_mg and x.tp=4) --��� �� ���� ������ �� ��������
          ) loop

        l_ret:=ins_vol_meter(p_met_klsk => c.k_lsk_id, p_lsk => null, p_usl => null, p_vol => c2.vol, p_n1 => null, p_tp => 4);
        if l_ret <> 0 then
          Raise_application_error(-20000, '������ ������ ������� �������� � id='||c.id);
        end if;
      end loop;
      logger.log_act(c.lsk,
                     '### ����������� ������� id='||c.id||' �� ������: ' || trim(c.nm) ||
                     ', < 3 ������, ���� ������� ������',
                     2);
    end if;

  end loop;

  logger.log_(time_ => null, comments_ => 'p_meter.del_broken_meters: ��������� ��������� ����������� ���������');

  logger.log_(time_ => null, comments_ => 'p_meter.del_broken_meters: ������ ��������� ��������� �� ������� �� �������� ���������');



  for c in (select m.id, k.lsk, us.nm, case when not m.dt1 < l_dt1  --���� �������� ��������
                   then l_dt1 else m.dt1 end dt1
                 from meter m 
                 join (select k_lsk_id, trim(max(t.lsk)) as lsk from kart t, v_lsk_tp tp  
                      where t.psch not in (8,9) and t.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
                       group by k_lsk_id) k on m.fk_klsk_obj=k.k_lsk_id
                     and m.dt2 > l_dt2 -- �������� �������
                     and m.dt1 <= to_date(l_back_6_month||'01', 'YYYYMMDD') -- ���� ������ ������������� �������� ����� 6 ��� �����
                 join usl us on m.fk_usl=us.usl
              where
              not exists (select * from c_reg_sch t2 -- ��� ��� �������� �������������, ������� ��������� ���� ��������
                 join u_list u3 on t2.fk_tp=u3.id and u3.cd='������� ��'
                 join u_list u4 on t2.fk_state=u4.id and u4.cd in ('���������� ��')
                 -- � ������� ��������� ���� �� �������������� ��������� (���� ����������� ��������� ���� ���������)
                 where t2.dt1 >= m.dt1 and t2.dt1 > to_date(l_back_6_month||'01', 'YYYYMMDD') 
                  and t2.fk_meter=m.id)
              and not exists -- ��� �� ������������ ������ �� ���������, ������� � ������� 6 ��� �����
               (select t2.* from T_OBJXPAR t2, u_list s
                      where t2.fk_list=s.id
                      and s.cd in ('ins_vol_sch', 'ins_sch') -- ����� ��� ���������
                      and t2.fk_k_lsk = m.k_lsk_id
                      and t2.mg > l_back_6_month
                      and t2.tp not in (1,2) -- ����� ��������������
                      and nvl(n1,0)<>0 -- ��������� �����
                      )) loop
                      
                      
      -- ������� �������, �� �������� �� �������� ��������� ������ 6 ���. (������� ��������)
      update meter t set t.dt2=c.dt1 where t.id=c.id;

      logger.log_act(c.lsk,
                     '### ������ ������� �� �������� �� �������� ��������� id='||c.id||' �� ������: ' || trim(c.nm) ||
                     ', > 6 �������, ���������� ��������',
                     2);

  end loop;                      



  commit;
  end;

  -- ������ ���� ���������
  procedure imp_all_meter is
    l_usl_hw varchar2(3);
    l_usl_gw varchar2(3);
    l_usl_el varchar2(3);
    l_usl_ot varchar2(3);
  begin

  l_usl_hw:='011';
  l_usl_gw:='015';
  l_usl_el:='038';
  l_usl_ot:='007';

  -- ��������� k_lsk �� ���������� id ���������
   delete from k_lsk t where
    not exists (select * from meter m where m.k_lsk_id=t.id)
    and exists (select * from u_list u where u.id=t.fk_addrtp and u.cd='���');


   --  ������ ������� ���������
   delete from meter;

   --  ������
   for c in (select * from kart k where k.psch not in (8,9)) loop
       imp_lsk_meter(c.lsk, l_usl_hw, l_usl_gw, l_usl_el, l_usl_ot);
   end loop;


     -- �� ���� �������, ��� ��� ���� ��������� ������ ����� ���!
     -- ������� ������ ������� ������� ���������
/*     delete from c_reg_sch r where exists
     (select * from c_reg_sch s join u_list u on s.fk_tp=u.id
              and u.cd='������� ��'
              join usl us on us.usl=s.fk_usl and us.usl in (l_usl_hw, l_usl_gw, l_usl_el)
              where r.rowid=s.rowid
              );  */
    -- ��������� ����� kart - � �����, ��� ��� �������� ���������� ����������� �� ����� ��������
  /*  delete from kart2 t;
    insert into kart2
      (lsk, kul, nd, kw, fio, kpr, kpr_wr, kpr_ot, kpr_cem, kpr_s, opl, ppl, pldop, ki, psch, psch_dt, status, kwt, lodpl, bekpl, balpl, komn, et, kfg, kfot, phw, mhw, pgw, mgw, pel, mel, sub_nach, subsidii, sub_data, polis, sch_el, reu, text, schel_dt, eksub1, eksub2, kran, kran1, el, el1, sgku, doppl, subs_cor, house_id, c_lsk_id, mg1, mg2, kan_sch, subs_inf, k_lsk_id, dog_num, schel_end, fk_deb_org, subs_cur, k_fam, k_im, k_ot, memo, fk_distr, law_doc, fk_pasp_org, flag, flag1, fk_err, law_doc_dt, prvt_doc, prvt_doc_dt, cpn, kpr_wrp, pn_dt, lsk_ext, fk_tp, sel1, vvod_ot, entr, pot, mot, elsk)
    select lsk, kul, nd, kw, fio, kpr, kpr_wr, kpr_ot, kpr_cem, kpr_s, opl, ppl, pldop, ki, psch, psch_dt, status, kwt, lodpl, bekpl, balpl, komn, et, kfg, kfot, phw, mhw, pgw, mgw, pel, mel, sub_nach, subsidii, sub_data, polis, sch_el, reu, text, schel_dt, eksub1, eksub2, kran, kran1, el, el1, sgku, doppl, subs_cor, house_id, c_lsk_id, mg1, mg2, kan_sch, subs_inf, k_lsk_id, dog_num, schel_end, fk_deb_org, subs_cur, k_fam, k_im, k_ot, memo, fk_distr, law_doc, fk_pasp_org, flag, flag1, fk_err, law_doc_dt, prvt_doc, prvt_doc_dt, cpn, kpr_wrp, pn_dt, lsk_ext, fk_tp, sel1, vvod_ot, entr, pot, mot, elsk from kart;
*/
     commit;
  end;

  -- ������������� ������� �������
  procedure imp_states_meter(p_lsk in varchar2, p_klsk_met in number, p_usl in varchar2) is
  begin
        insert into c_reg_sch
          (dt1, fk_tp, fk_state, text, fk_usl, lsk, fk_meter)
        select s.dt1, s.fk_tp, s.fk_state, s.text, null as fk_usl, s.lsk, m.id as fk_meter
            from c_reg_sch s join u_list u on s.fk_tp=u.id
                      and u.cd='������� ��' and s.fk_usl=p_usl
                      and s.lsk=p_lsk
                      join meter m on m.k_lsk_id=p_klsk_met;

  end;

  -- ������ ��������� �� kart, c_states_sch
  procedure imp_lsk_meter(p_lsk in kart.lsk%type, p_usl_hw in varchar2, p_usl_gw in varchar2, p_usl_el in varchar2, p_usl_ot in varchar2) is
  l_mfd date; --����� ������ ���� � �������
  l_mld date; --����� ��������� ���� � �������
  l_usl_hw varchar2(3);
  l_usl_gw varchar2(3);
  l_usl_el varchar2(3);
  l_usl_ot varchar2(3);
  l_met_klsk number;
  l_cur_dt1 date;
  l_cur_dt2 date;
  l_old number;
  l_sch_el number;
  l_pel number;
  l_klsk_obj number;
  l_arch_mg params.period%type; -- �����, � �������� ������������� �������� ��������
  begin

  l_mfd:=gdt(1,1,1990);
  l_mld:=gdt(1,1,2050);
  l_arch_mg:='201701'; -- �� ��� ������

  --  ������� ����
  select to_date(p.period||'01','YYYYMMDD'),
         last_day(to_date(p.period||'01','YYYYMMDD')) into l_cur_dt1, l_cur_dt2
   from params p;

  l_usl_hw:=p_usl_hw;
  l_usl_gw:=p_usl_gw;
  l_usl_el:=p_usl_el;
  l_usl_ot:=p_usl_ot;

  l_old:=-1;
  for c in (select s.id, s.lsk, s.fk_status, nvl(s.dt1, l_mfd) as dt1, nvl(s.dt2, l_mld) as dt2, k.k_lsk_id,
    k.phw, k.pgw, k.pel,
    case when l_cur_dt2 between nvl(s.dt1, l_mfd) and nvl(s.dt2, l_mld) then 1 else 0 end as active, k.sch_el
   from c_states_sch s join kart k on s.lsk=k.lsk
   where k.lsk=p_lsk
   order by nvl(s.dt1, l_mfd), nvl(s.dt1, l_mld)) loop

    if c.fk_status=1  then
      --��.�.�. � �.�

      l_met_klsk:=ins_meter(p_npp => 1, p_usl => l_usl_hw, p_dt1 => c.dt1, p_dt2 => c.dt2,
                       p_n1 => case when c.active=1 then c.phw else null end, p_fk_klsk_obj => c.k_lsk_id, p_tp => '���');

      if c.active=1 then
        imp_arch_meter(p_lsk => p_lsk, p_met_klsk => l_met_klsk, p_mg => l_arch_mg, p_counter => 'mhw');
        imp_states_meter(p_lsk => p_lsk, p_klsk_met => l_met_klsk, p_usl => l_usl_hw);
      end if;

      l_met_klsk:=ins_meter(p_npp => 1, p_usl => l_usl_gw, p_dt1 => c.dt1, p_dt2 => c.dt2,
                       p_n1 => case when c.active=1 then c.pgw else null end, p_fk_klsk_obj => c.k_lsk_id, p_tp => '���');
      if c.active=1 then
        imp_arch_meter(p_lsk => p_lsk, p_met_klsk => l_met_klsk, p_mg => l_arch_mg, p_counter => 'mgw');
        imp_states_meter(p_lsk => p_lsk, p_klsk_met => l_met_klsk, p_usl => l_usl_gw);
      end if;

    elsif c.fk_status=2  then
      --��.�.�.

      l_met_klsk:=ins_meter(p_npp => 1, p_usl => l_usl_hw, p_dt1 => c.dt1, p_dt2 => c.dt2,
                       p_n1 => case when c.active=1 then c.phw else null end, p_fk_klsk_obj => c.k_lsk_id, p_tp => '���');
      if c.active=1 then
        imp_arch_meter(p_lsk => p_lsk, p_met_klsk => l_met_klsk, p_mg => l_arch_mg, p_counter => 'mhw');
        imp_states_meter(p_lsk => p_lsk, p_klsk_met => l_met_klsk, p_usl => l_usl_hw);
      end if;

    elsif c.fk_status=3  then
      --��.�.�.

      l_met_klsk:=ins_meter(p_npp => 1, p_usl => l_usl_gw, p_dt1 => c.dt1, p_dt2 => c.dt2,
                       p_n1 => case when c.active=1 then c.pgw else null end, p_fk_klsk_obj => c.k_lsk_id, p_tp => '���');
      if c.active=1 then
        imp_arch_meter(p_lsk => p_lsk, p_met_klsk => l_met_klsk, p_mg => l_arch_mg, p_counter => 'mgw');
        imp_states_meter(p_lsk => p_lsk, p_klsk_met => l_met_klsk, p_usl => l_usl_gw);
      end if;

    end if;

    l_old:=c.fk_status;
    l_sch_el:=c.sch_el;
    l_pel:=c.pel;
    l_klsk_obj:=c.k_lsk_id;
  end loop;

  -- �������� ���������
  for c in (select * from kart k where k.psch not in (8,9) and k.pot <> 0 and k.lsk=p_lsk) loop
    l_met_klsk:=ins_meter(p_npp => 1, p_usl => l_usl_ot, p_dt1 => l_mfd, p_dt2 => l_mld,
                     p_n1 => c.pot, p_fk_klsk_obj => l_klsk_obj, p_tp => '���');
    imp_arch_meter(p_lsk => p_lsk, p_met_klsk => l_met_klsk, p_mg => l_arch_mg, p_counter => 'mot');
    imp_states_meter(p_lsk => p_lsk, p_klsk_met => l_met_klsk, p_usl => l_usl_ot);
  end loop;

  -- �������� ��.��
  for c in (select * from kart k where k.psch not in (8,9) and k.pel <> 0 and k.sch_el <> 0 and k.lsk=p_lsk) loop

    l_met_klsk:=ins_meter(p_npp => 1, p_usl => l_usl_el, p_dt1 => l_mfd, p_dt2 => l_mld,
                     p_n1 => c.pel, p_fk_klsk_obj => c.k_lsk_id, p_tp => '���');
    imp_arch_meter(p_lsk => p_lsk, p_met_klsk => l_met_klsk, p_mg => l_arch_mg, p_counter => 'mel');
    imp_states_meter(p_lsk => p_lsk, p_klsk_met => l_met_klsk, p_usl => l_usl_el);
  end loop;
  
  end;

  -- ������������� �������� ������ ���������
  procedure imp_arch_meter(p_lsk in kart.lsk%type, -- ��
                           p_met_klsk in number,   -- klsk ��������
                           p_mg in params.period%type, -- ������ � �������
                           p_counter in varchar2 -- ��� ��������
                           ) is
    l_vol_id number;
    l_user number;
  begin

    select max(decode(u.cd,'ins_vol_sch',u.id,0)), max(s.id)
      into l_vol_id, l_user
      from u_list u, t_user s
     where u.cd in ('ins_sch', 'ins_vol_sch')
     and s.cd=user;


     for c in (select t.sch_el, t.mg, t.psch,
        decode(p_counter, 'mhw', t.mhw, 'mgw', t.mgw, 'mel', t.mel, 'mot', t.mot) as vol
         from arch_kart t, params p where t.lsk=p_lsk and t.mg >= p_mg -- �����
                                          and t.mg <>p.period
         union all
         select t.sch_el, p.period, t.psch,
        decode(p_counter, 'mhw', t.mhw, 'mgw', t.mgw, 'mel', t.mel, 'mot', t.mot) as vol
         from kart t, params p where t.lsk=p_lsk -- ������������ ������� ������
         ) loop

     if nvl(c.vol,0) <> 0 then
     if p_counter = 'mhw' and (c.psch=1 or c.psch=2) then
      --��.�.�.
       --�������� ����� �� ��������
       insert into t_objxpar (fk_k_lsk, fk_list, n1, mg, fk_user)
         values(p_met_klsk, l_vol_id, c.vol, c.mg, l_user);

     elsif p_counter = 'mgw' and (c.psch=1 or c.psch=3) then
      --��.�.�.
       --�������� ����� �� ��������
       insert into t_objxpar (fk_k_lsk, fk_list, n1, mg, fk_user)
         values(p_met_klsk, l_vol_id, c.vol, c.mg, l_user);

     elsif p_counter = 'mel' and c.sch_el=1 then
      --��.��.��.
       --�������� ����� �� ��������
       insert into t_objxpar (fk_k_lsk, fk_list, n1, mg, fk_user)
         values(p_met_klsk, l_vol_id, c.vol, c.mg, l_user);

     elsif p_counter = 'mot' and nvl(c.vol,0) <> 0 then
      --��.����.
       --�������� ����� �� ��������
       insert into t_objxpar (fk_k_lsk, fk_list, n1, mg, fk_user)
         values(p_met_klsk, l_vol_id, c.vol, c.mg, l_user);

     end if;
     end if;

     end loop;
  end;



  procedure test1 is
    l_klsk   number;
    met_klsk number;
    dt1      date;
    dt2      date;
  begin

    dt1 := gdt(1, 1, 0);
    dt2 := gdt(31, 12,14 );

    l_klsk := 104880;
    delete from meter t where t.fk_klsk_obj = l_klsk;

    met_klsk := ins_meter(p_npp => 1,
                         p_usl         => '011',
                         p_dt1         => dt1,
                         p_dt2         => dt2,
                         p_n1            => 0,
                         p_fk_klsk_obj => l_klsk,
                         p_tp          => '���');

--   insert into t_objxpar (fk_k_lsk, fk_list, n1)
--     values(met_klsk, 2694, 5.56);
   insert into t_objxpar (fk_k_lsk, fk_list, n1)
     values(met_klsk, 2693, 555);
   update meter t set t.n1=555 where t.k_lsk_id=met_klsk;
   update kart k set k.phw=555, k.mhw=null where k.k_lsk_id=l_klsk;

    met_klsk := ins_meter(p_npp => 1,
                         p_usl         => '015',
                         p_dt1         => dt1,
                         p_dt2         => dt2,
                         p_n1            => 0,
                         p_fk_klsk_obj => l_klsk,
                         p_tp          => '���');

--   insert into t_objxpar (fk_k_lsk, fk_list, n1)
--     values(met_klsk, 2694, 12);
   insert into t_objxpar (fk_k_lsk, fk_list, n1)
     values(met_klsk, 2693, 777);
   update meter t set t.n1=777 where t.k_lsk_id=met_klsk;
   update kart k set k.pgw=777, k.mgw=null where k.k_lsk_id=l_klsk;

   commit;
  end;



/*
  �������! ������� ����������� �� ������
procedure gen_auto_chrg_all(p_set in number, p_usl in usl.usl%type) is
    l_otop number;
    l_months number;
    l_dt1 date;
    l_dt2 date;
  begin


  if p_set = 1 then
  --��������������
  --������ ������������ �� �����?(�� ��������� ���� ������)
    select case
             when last_day(to_date(p.period || '01', 'YYYYMMDD')) between
                  utils.get_date_param('MONTH_HEAT1') --�����.������.������
                  and utils.get_date_param('MONTH_HEAT2') then
              1
             else
              0
           end
      into l_otop
      from params p;
    -- ���-�� �������, ��� ���������� ��-��������
    l_months := utils.get_int_param('AUTOCHRGM');

    --������, �� ���� ����� �� �������� ������
      select to_date(utils.add_months_pr(p.period, -1 * l_months)||'01'), --������ ���� ���������� ������
             last_day(to_date(utils.add_months_pr(p.period, -1)||'01'))  --��������� ���� ��������� ������
        into l_dt1, l_dt2
        from params p;

-- insert into t_objxpar (fk_k_lsk, fk_list, n1, fk_user, mg, tp)
--           values(p_met_klsk, l_vol_id, p_vol, l_user, l_period, p_tp)


      select m.fk_klsk_obj, sum(x.n1) from meter m join t_objxpar x on m.k_lsk_id=x.fk_k_lsk
        join u_list u on x.fk_list=u.id and u.cd='ins_vol_sch'
        where m.fk_usl=p_usl and (m.dt1 between l_dt1 and l_dt2 or m.dt2 between l_dt1 and l_dt2)
        and m.fk_usl=p_usl


  else
    --����� ��������������
    null;
  end if;

  end;*/
end p_meter;
/

