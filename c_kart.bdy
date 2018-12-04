create or replace package body scott.C_KART is
procedure set_part_kpr_vvod(p_vvod in c_vvod.id%type) is

begin
--����������� ��� �� �������� �.�. �� �����
for c in (select t.lsk, n.usl, u.cd as tp from kart t, nabor n, u_list u where t.psch not in (8,9)
  and t.lsk=n.lsk and n.fk_vvod=p_vvod and t.fk_tp=u.id
  )
loop
  set_part_kpr(c.lsk, c.usl, 0, c.tp);
--����� ������ - ����������� � ��������
--  commit;
end loop;
end;

--��������� ���������������� ����������� c_charge_prep
procedure set_part_kpr(p_lsk in kart.lsk%type, p_usl in usl.usl%type,
                       p_set_utl_kpr in number,
                       p_tp in u_list.cd%type --��� ��������, ��� ������� ���������� � ���.������ (��� ����������� ����������� �� ���������
                       ) is
  l_dt_start date;
  l_dt_end date;
  l_dt date;
  l_hw_days number; --���-�� ���� �������������� �������� �.�. � ������
  l_gw_days number; --���-�� ���� �������������� �������� �.�. � ������

  l_max_days number; --���� ���-�� ���� � ������
  l_part_days number; --���� ������ ��� � ������
  l_mg params.period%type;
  l_prop c_states_pr.fk_status%type;
  l_prop_reg c_states_pr.fk_status%type;
  --��������! 5000-��������� ��������, ������������ ����� ���� ���-�� ���� * ���� ���-�� �����������
  TYPE l_rec_prop_type IS RECORD (id number, dt date, prop number, prop_reg number, rel_cd relations.cd%type, dat_rog date);
  TYPE l_arr_prop_type IS VARRAY(5000) OF l_rec_prop_type;
  l_arr_prop l_arr_prop_type;
  -- ������ ����������� ������������� ��������
  l_arr_prop4 l_arr_prop_type;

  --��� ���� ������ ID �����������
  TYPE l_rec_prop2_type IS RECORD (id number, status number,
    dat_prop date, dat_ub date, dat_rog date, rel_cd relations.cd%type);
  TYPE l_arr_prop2_type IS VARRAY(500) OF l_rec_prop2_type;
  l_arr_prop2 l_arr_prop2_type;

  --������ ID ����������� ������������� ��������
  l_arr_prop3 l_arr_prop2_type;

  TYPE l_rec_type IS RECORD (usl varchar2(3), sch number, chrg_round number, exist_kpr number);
  TYPE l_arr_type IS VARRAY(500) OF l_rec_type;
  l_arr l_arr_type;
  
  l_kpr_wrz number;     --��� ������������ �� ��.�����, �� ���������
  l_kpr_wro number;     --��� ������������ �� ��.�����., �� ���������
  l_kpr number;
  l_kpr2 number; --��� ������������ ��� ���� �������� ����������� (����� ��� ���)

  --���������� �� � ������
  l_round number;    

  --����� ���������
  l_psch number;
  l_sch_el kart.sch_el%type;
  --�������� �� ������
  l_norm number;

  l_temp_days number;
  --��������� ����������
  l_tmp1 number;
  l_tmp2 number;

  --���������� ��� �������� �������� ����������))
  l_dummy number;
  --������������ ���-�� �����������, � ������� ������ (��� ��������)
  l_max_kpr number;
  --�������� - ������� �������� c_charge_prep-1, ��� ������� ��������-������� �� 15 �����
  l_det params.is_det_chrg%type;
  --�������� �������� ���-�� ������ (0-��� ���, 1-�����., 1 - ��� ��� (����, ����� ���������) ���.22.05.17)
  l_var_cnt_kpr number;
  --�������������� �������� �������� ���-�� ������ (0-��� ���, 1 - ��� ���, �����.)
  l_var_cnt_kpr2 number;
  --���� �������� ������
  l_hf_dt date;
  l_is_1room_sn number;
  --CD ��������� ����� ������.
  l_rel_cd relations.cd%type;
  --���� �������� ������������
  l_dat_rog date;
  l_dat_rog_tmp date;
  --��������, ��� ������������� ������������, ��� ����������
  l_above70_owner number;
  l_above70 number;
  l_under70 number;
  -- �������� ���.���� (��� ������� ���������� � ���.������)
  l_lsk_main kart.lsk%type;
  -- ������������ ���.���� (���� ����������)
  l_lsk_parent kart.lsk%type;
  t_state tab_state;
  
  -- ��� ������ ������������� ���.�����
  t_state2 tab_state;
  
  l_status_cd status.cd%type;
  -- ������������ ������, ��� �.�.
  l_otop number;
  -- ������������ ������ ��� ��������� ����
  l_otop2 number;
  -- �������� ����� ����������� ��� ����������
  l_cap_calc_kpr_tp number;
  -- klsk �������� �����
  l_klsk number;
  
cursor cur1 is
  select u.usl_norm, u.counter, u.usl, u.usl_type2, u.fk_calc_tp,
          case when u.cd in ('�.����', '�.����', '�.�. ��� ���', 'VVD') then n.norm
               else null
               end as norm,
          u.cd,
          case when u.cd in ('�.����') then vl.vol --k.mhw
               when u.cd in ('�.����', '�.�. ��� ���') then vl.vol --k.mgw
               when u.cd in ('��.�����.2','EL_OTHER') then vl.vol --k.mel
               when u.cd = '��.��.���� ��' then vl.vol --k.mel
               when u.cd in ('����.����.','����.�����.') and nvl(k.pot,0) <> 0 then nvl(k.mot,0) --���� �� ��������������� ��������, ������� �� ����! (������ pot ������ mot)
               when u.cd in ('����.����.','����.�����.') and k.opl <> 0 and d.dist_tp in (1) then nvl(n.vol,0) --���� ���� �� ��������� ����, ��������� �� �������������
               when u.cd in ('����.����.','����.�����.') and k.opl <> 0 and d.dist_tp in (4,5) 
                 then case when nvl(d.non_heat_per,0)=0 then l_otop2 * k.opl * nvl(n.norm,0) --���� ���� �� ��������� ����, ��������� �� ��������� � ������ ������������� ������
                      else k.opl * nvl(n.norm,0) end --���� ���� �� ��������� ����, ��������� �� ���������                 
                 
               when u.cd in ('�.����.���', '�.����.���', '�.�. ��� ��� ���', '��.��.���', 
                    'HW_ODN2', 'GW_ODN2', 'EL_ODN2' --����� ������ ���
                 ) then nvl(n.vol_add,0)
                    else null
                    end
                    as sch_vol,
          nvl(n.vol,0) as vol, -- ������������� (� ��� ���, ��� ����, �������� �����.�.���)
          nvl(n.vol_add,0) as vol_add, -- ������������� (� ��� ���, ��� ����, �������� �.�.���)
          d.kub, decode(u.cd, '�.����', k.kran1, '�.����.���', k.kran1, null) as kran1,
          case when u.cd in ('�.����', '�.����', '�.�. ��� ���', 'VVD') then 1
               when u.cd in ('��.�����.2','EL_OTHER') then 2
               when u.cd = '��.��.���� ��' then 2
               when u.cd in ('����.����.','����.�����.') then 0  --�������� � ���������� �����
               when u.cd in ('�.����.���', '�.����.���', '�.�. ��� ��� ���', '��.��.���',
                    'HW_ODN2', 'GW_ODN2', 'EL_ODN2' --����� ������ ���
                    ) then 4  --�������� � ���������� �����
               when u.cd in ('���.') then 5  --���������! (� >=70 ��� ������.!)
                    else 3 --��������� (���.������, ��������� �2)
                    end as norm_tp,
                    k.opl,
                    f.norma_1, f.norma_2, f.norma_3,
                    k.komn
          from kart k join nabor n on n.lsk=k.lsk
           join usl u on n.usl=u.usl
           left join c_vvod d on n.fk_vvod=d.id
           join load_memof f on 1=1
           left join (select m2.fk_usl, sum(t2.n1) as vol -- �������� ����� �� ��������
                        from meter m2
                        join params pm on 1=1
                        join T_OBJXPAR t2 on m2.k_lsk_id = t2.fk_k_lsk and t2.mg = pm.period
                        join u_list s2 on t2.fk_list = s2.id and s2.cd = 'ins_vol_sch'
                       where m2.fk_klsk_obj = l_klsk
                       group by m2.fk_usl
                      ) vl on u.usl_vol=vl.fk_usl -- �� ������, � ������� ����� �����
          where k.lsk=p_lsk
          and u.usl_norm=0
          and k.psch not in (8,9)
          and nvl(p_usl, u.usl)=u.usl
          order by u.usl; --order by ����� ��� ����������� ����������/������ �������

/*           left join (select m2.fk_usl, sum(t2.n1) as vol -- �������� ����� �� ��������
                        from kart k2 
                        join v_lsk_tp tp2 on k2.fk_tp = tp2.id and tp2.cd = 'LSK_TP_MAIN'
                        join meter m2 on m2.fk_klsk_obj = l_klsk and k2.k_lsk_id=m2.fk_klsk_obj
                        join params pm on 1=1
                        join T_OBJXPAR t2 on m2.k_lsk_id = t2.fk_k_lsk and t2.mg = pm.period
                        join u_list s2 on t2.fk_list = s2.id and s2.cd = 'ins_vol_sch'
                       where k2.psch not in (8,9)
                       group by m2.fk_usl
                      ) vl on u.usl_vol=vl.fk_usl -- �� ������, � ������� ����� �����
*/
--��������������� ������ � temp ������ � ��������
procedure load_temp(p_load_lsk in kart.lsk%type, p_state out tab_state) is
begin

  l_is_1room_sn := utils.get_int_param('IS_1ROOM_SN');

  if utils.get_int_param('VER_METER1') = 0 then
    --������ ������
    --��������� ������� �� ����������� � ���� �.�.
    select rec_state(t.fk_kart_pr,
                      t.fk_status,
                      decode(u.cd, 'PROP', 0, 'PROP_REG', 1),
                      nvl(t.dt1, to_date('01011900', 'DDMMYYYY')),
                      nvl(t.dt2, to_date('01012900', 'DDMMYYYY')),
                      p.dat_rog,
                      r.cd) bulk collect
      into p_state
      from c_states_pr t, u_list u, u_listtp tp, c_kart_pr p, relations r
     where t.fk_tp = u.id
       and u.fk_listtp = tp.id
       and tp.cd = '���� �������� �����������' --�����.������������ ���� u_listtp
       and t.fk_kart_pr = p.id
       --and p.lsk = coalesce(l_lsk_main, p_lsk) --�����������!!!
       and p.lsk = p_load_lsk
       and p.relat_id = r.id(+)
    union all
    --��������� ������� ��������� � ���� �.�.
    select rec_state(t.id,
                      t.fk_status,
                      2,
                      nvl(t.dt1, to_date('01011900', 'DDMMYYYY')),
                      nvl(t.dt2, to_date('01012900', 'DDMMYYYY')),
                      null,
                      null)
      from c_states_sch t
     --where t.lsk = p_lsk;
     where t.lsk = p_load_lsk;
  else
    --����� ������
    --��������� ������� �� ����������� � ���� �.�.
    select rec_state(t.fk_kart_pr,
                      t.fk_status,
                      decode(u.cd, 'PROP', 0, 'PROP_REG', 1),
                      nvl(t.dt1, to_date('01011900', 'DDMMYYYY')),
                      nvl(t.dt2, to_date('01012900', 'DDMMYYYY')),
                      p.dat_rog,
                      r.cd) bulk collect
      into p_state
      from c_states_pr t, u_list u, u_listtp tp, c_kart_pr p, relations r
     where t.fk_tp = u.id
       and u.fk_listtp = tp.id
       and tp.cd = '���� �������� �����������' --�����.������������ ���� u_listtp
       and t.fk_kart_pr = p.id
       --and p.lsk = coalesce(l_lsk_main, p_lsk) --�����������!!!
       and p.lsk = p_load_lsk 
       and p.relat_id = r.id(+)
    union all
    --��������� ������� ��������� � ���� �.�.
    select rec_state(null,
                      a.psch,
                      2,
                      nvl(a.dt1, to_date('01011900', 'DDMMYYYY')),
                      nvl(a.dt2, to_date('01012900', 'DDMMYYYY')),
                      null,
                      null)
      from (with t as (select distinct d.dat,
                                       case
                                         when m.fk_usl is not null and
                                              m2.fk_usl is not null then
                                          1 -- �.�. � �.�.
                                         when m.fk_usl is not null and
                                              m2.fk_usl is null then
                                          2 -- �.�.   
                                         when m.fk_usl is null and
                                              m2.fk_usl is not null then
                                          3 -- �.�.
                                         else
                                          0
                                       end as psch
                         from v_cur_days d
                         join kart k
                           on k.lsk = p_load_lsk
                         join usl u
                           on u.cd = '�.����'
                         join usl u2
                           on u2.cd = '�.����'
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
              order by dt1) a;
  
  end if;

  select t.sch_el into l_sch_el from kart t where t.lsk = p_load_lsk;

  --��������� ���-�� ���� ������� ��������� �� ����
  --�� ��.�� - ���-�� ������������� ���-�� ���� � ������
  for c in (select distinct u.fk_calc_tp as fk_calc_tp_hw,
                            u2.fk_calc_tp as fk_calc_tp_gw
              from usl u, usl u2
             where u.cd in ('�.����')
               and u2.cd in ('�.����')) loop
    if utils.get_int_param('VER_METER1') = 0 then
      --������ ������
      select sum(c_kart.get_is_sch(c.fk_calc_tp_hw, t.fk_status, null)) as cnt,
             sum(c_kart.get_is_sch(c.fk_calc_tp_gw, t.fk_status, null)) as cnt2
        into l_hw_days, l_gw_days
        from c_states_sch t, v_cur_days d
       where t.lsk = p_load_lsk
         and d.dat between nvl(t.dt1, to_date('01011900', 'DDMMYYYY')) and
             nvl(t.dt2, to_date('01012900', 'DDMMYYYY'));
    else
      --����� ������
      select sum(c_kart.get_is_sch(c.fk_calc_tp_hw, a.psch, null)) as cnt,
             sum(c_kart.get_is_sch(c.fk_calc_tp_gw, a.psch, null)) as cnt2
        into l_hw_days, l_gw_days
        from (select distinct d.dat,
                               case
                                 when m.fk_usl is not null and
                                      m2.fk_usl is not null then
                                  1 -- �.�. � �.�.
                                 when m.fk_usl is not null and
                                      m2.fk_usl is null then
                                  2 -- �.�.   
                                 when m.fk_usl is null and
                                      m2.fk_usl is not null then
                                  3 -- �.�.
                                 else
                                  0
                               end as psch
                 from v_cur_days d
                 join kart k
                   on k.lsk = p_load_lsk
                 join usl u
                   on u.cd = '�.����'
                 join usl u2
                   on u2.cd = '�.����'
                 left join meter m
                   on k.k_lsk_id = m.fk_klsk_obj
                  and d.dat between m.dt1 and m.dt2
                  and m.fk_usl = u.usl
                 left join meter m2
                   on k.k_lsk_id = m2.fk_klsk_obj
                  and d.dat between m2.dt1 and m2.dt2
                  and m2.fk_usl = u2.usl) a;
    end if;
  end loop;
end;

--�������� ������� ������������ �� �������
procedure get_prop(p_arr in l_arr_prop_type, p_fk_kart_pr in number, p_dt in date,
                   p_prop out number, p_prop_reg out number, 
                   p_rel_cd out relations.cd%type,
                   p_dat_rog out date) is
begin
  for element in 1..p_arr.count --������ ����������... ��� ��� ����� ����������� ��������� ����������
  loop
     if p_arr(element).id=p_fk_kart_pr and  --����� ��� p_arr(element).prop;
        p_arr(element).dt=p_dt then
       p_prop:=p_arr(element).prop;
       p_prop_reg:=p_arr(element).prop_reg;
       p_rel_cd:=p_arr(element).rel_cd;
       p_dat_rog:=p_arr(element).dat_rog;
       --�����, ��� �����
       exit;
     end if;
  end loop;
end;

procedure init_arr_usl is
  l_nrm_kpr number;     --���-�� �����������, ��� ������������ ���.�����
  l_rel_cd relations.cd%type; --��������� ����� ������. (� ���� ����. - �� �����)
begin
  --���������� ���-�� �����, ��� ����������� ���������� �� ��������� �������
  --���������� ������
  --������������� ������� ������� �������
  l_nrm_kpr:=0;
    --���������� ��� ������
    l_dt:=l_dt_start;
    l_nrm_kpr:=0;
    --���� - ����� ���������� ���-�� ����������� � ���� ������ (�� ������)
    --��� ����������� ���������
    while l_dt <= l_dt_end
    loop
      l_kpr:=0;
      if l_arr_prop2.count > 0 then
      for i in l_arr_prop2.FIRST..l_arr_prop2.LAST
      loop
        --�������� ������� ������������ �� �������
        get_prop(l_arr_prop, l_arr_prop2(i).id, l_dt, l_prop, l_prop_reg, l_rel_cd, l_dat_rog);
        --������� ���-�� ����������� �� ������ � ������� ���������
        --(��������� � ������ ������� ������� ���, ����� �� - ���-�� ����
        --������������� ��� - 2 (��� �������� ���-�� ����. ��� ������������ ��������)
        get_days(2, l_kpr, l_dummy, l_dummy, l_dummy, l_prop, l_prop_reg, l_var_cnt_kpr2);
      end loop;
      end if;
      if l_kpr > l_nrm_kpr then
        l_nrm_kpr:=l_kpr;
      end if;
      l_dt:=l_dt+1;
    end loop;

--    l_arr_usl.extend;
      l_max_kpr:=ceil(l_nrm_kpr); --��������� � ������� �������
    if l_var_cnt_kpr = 0 and l_max_kpr = 0 and l_status_cd not in ('MUN') then
      --������� ���
      l_max_kpr:=1;
    end if;

    if l_var_cnt_kpr = 1 and l_max_kpr = 0  then
      --������� �����, � �.�. � �� �������.�����
      l_max_kpr:=1;
    end if;

  --��������� ���� � �������, ����� ������������ � ���������� (����� c_charge)
  for c2 in cur1
  loop
    insert into c_charge_prep
     (lsk, usl, kpr, tp)
     values
     (p_lsk, c2.usl, l_max_kpr, 2);
  end loop;


  --���������������� ������ ��� ������ �� ���������
  select usl, 0 as sch, nvl(u.chrg_round,3),--���������� �� ��������� �� 3 ������
    0 as exist_kpr
    bulk collect into l_arr
    from usl u where (p_usl is null or u.usl=p_usl); --��������! ����������� ���! (�������� ������ ������������ ����� �������) ���.17.02.2015
end;

--�������� ������ �� array
function get_status(p_state in tab_state, p_dt in date, p_tp in number, p_prop in number) return number is
begin
  if p_state.count > 0 then       
    if p_tp=2 then
      --����� �� ���������
        --���� ������� ���������� ����
        for j in p_state.first..p_state.last loop
          if p_state(j).tp=p_tp 
            and p_dt between p_state(j).dt1 and p_state(j).dt2 then
            return p_state(j).fk_status;
          end if;
        end loop;    
    else
      --����� �� �����������
      for j in p_state.first..p_state.last loop
        if p_state(j).tp=p_tp and p_state(j).fk_kart_pr=p_prop
          and p_dt between p_state(j).dt1 and p_state(j).dt2 then
          return p_state(j).fk_status;
        end if;
      end loop;    
    end if;
  end if;    
  return null;
end;

--������������� ������� �� ��������� �����������
procedure init_array is
j number;
--��������� ����������, ����� �������� �� ����������
l_prop2 number;
l_prop_reg2 number;
l_dt_tmp date;
begin
  
  --������������� ������� ������� �������
  l_arr_prop:=l_arr_prop_type();
  l_arr_prop4:=l_arr_prop_type();

  --���������������� ������-2 ��� ������ � ������������
  select t.id, t.status, t.dat_prop, t.dat_ub, t.dat_rog, r.cd as relat_cd
    bulk collect into l_arr_prop2
  from c_kart_pr t, relations r where t.lsk=coalesce(l_lsk_main, p_lsk)  --�����������!!!
   and t.relat_id=r.id(+);

  --���������������� ������-3, ����������� �� ������������� ���.�����
--  if l_lsk_parent is not null then
    select t.id, t.status, t.dat_prop, t.dat_ub, t.dat_rog, r.cd as relat_cd
      bulk collect into l_arr_prop3
    from c_kart_pr t, relations r where t.lsk=l_lsk_parent
     and t.relat_id=r.id(+);
--  end if;

  --���������� �����������
  j:=1;
  if l_arr_prop2.count > 0 then
  for i in l_arr_prop2.FIRST..l_arr_prop2.LAST
  loop
    l_dt_tmp:=l_dt_start;
    --���������� ��� ������
    while l_dt_tmp <= l_dt_end
    loop
      --������� � ������� �������
      --������ ���������� �����������
      --begin
      if l_det <> 0 then
        --������� �������� �����
        l_prop2:=get_status(p_state => t_state, p_dt => l_dt_tmp, p_tp => 0, p_prop => l_arr_prop2(i).id);
      else
        --����� ���� �������� ��������-������� �� 15 �����
        l_prop2:=get_status(p_state => t_state, p_dt => l_hf_dt, p_tp => 0, p_prop => l_arr_prop2(i).id);
      end if;
        if l_prop2 is null then
          l_prop2:=4; --���� ��� �������, ������ ��� �������
        end if;
      if l_det <> 0 then
        --������� �������� �����
        l_prop_reg2:=get_status(p_state => t_state, p_dt => l_dt_tmp, p_tp => 1, p_prop => l_arr_prop2(i).id);
      else
        --����� ���� �������� ��������-������� �� 15 �����
        l_prop_reg2:=get_status(p_state => t_state, p_dt => l_hf_dt, p_tp => 1, p_prop => l_arr_prop2(i).id);
      end if;
      --��������� ������ ����������
      l_arr_prop.extend;
      -- ID ������������
      l_arr_prop(j).id:=l_arr_prop2(i).id;
      -- ����, �� ������� ������� ������
      l_arr_prop(j).dt:=l_dt_tmp;
      -- ������ ������� ����������� ���������� 
      l_arr_prop(j).prop:=l_prop2;
      -- ������ ������� ��������� ����������� ��� ����������
      l_arr_prop(j).prop_reg:=l_prop_reg2;
      -- ���� ��������
      l_arr_prop(j).dat_rog:=l_arr_prop2(i).dat_rog;
      -- ���������
      l_arr_prop(j).rel_cd:=l_arr_prop2(i).rel_cd;
      
      j:=j+1;
      l_dt_tmp:=l_dt_tmp+1;
    end loop;
  end loop;
  end if;
  
  --���������� ����������� �� ������������� ���.�����
  j:=1;
  if l_arr_prop3.count > 0 then
  for i in l_arr_prop3.FIRST..l_arr_prop3.LAST
  loop
    l_dt_tmp:=l_dt_start;
    --���������� ��� ������
    while l_dt_tmp <= l_dt_end
    loop
      --������� � ������� �������
      --������ ���������� �����������
      --begin
      if l_det <> 0 then
        --������� �������� �����
        l_prop2:=get_status(p_state => t_state2, p_dt => l_dt_tmp, p_tp => 0, p_prop => l_arr_prop3(i).id);
      else
        --����� ���� �������� ��������-������� �� 15 �����
        l_prop2:=get_status(p_state => t_state2, p_dt => l_hf_dt, p_tp => 0, p_prop => l_arr_prop3(i).id);
      end if;
        if l_prop2 is null then
          l_prop2:=4; --���� ��� �������, ������ ��� �������
        end if;
      if l_det <> 0 then
        --������� �������� �����
        l_prop_reg2:=get_status(p_state => t_state2, p_dt => l_dt_tmp, p_tp => 1, p_prop => l_arr_prop3(i).id);
      else
        --����� ���� �������� ��������-������� �� 15 �����
        l_prop_reg2:=get_status(p_state => t_state2, p_dt => l_hf_dt, p_tp => 1, p_prop => l_arr_prop3(i).id);
      end if;
      --��������� ������ ����������
      l_arr_prop4.extend;
      l_arr_prop4(j).id:=l_arr_prop3(i).id;
      l_arr_prop4(j).dt:=l_dt_tmp;
      l_arr_prop4(j).prop:=l_prop2;
      l_arr_prop4(j).prop_reg:=l_prop_reg2;
      l_arr_prop4(j).dat_rog:=l_arr_prop3(i).dat_rog;
      l_arr_prop4(j).rel_cd:=l_arr_prop3(i).rel_cd;
      
      j:=j+1;
      l_dt_tmp:=l_dt_tmp+1;
    end loop;
  end loop;
  end if;
  
end;


begin
--if admin.get_state_base = 0 or init.g_admin_acc <> 0 then
--���� ���� ������� � ������� ������������ ��� ��������� ������
--�� ��������� ��������...
--������� ��� ��������� ������ ����������

--������� ���������� ������
delete from c_charge_prep t where t.lsk=p_lsk
 and t.tp in (0,1,2,3,5,6,7,8,9)
 and (p_usl is null or t.usl=p_usl);

--��������� ��������� �������
delete from temp_c_charge_prep t;

--������ ���� ������
select to_date(p.period||'01','YYYYMMDD'),
  p.period, nvl(p.is_det_chrg,0), to_date(p.period||'15','YYYYMMDD')
   into l_dt_start, l_mg, l_det, l_hf_dt
   from params p; --�������� �������� ������������ ���������

if l_dt_start between utils.get_date_param('MONTH_HEAT1') --�����.������.������
                  and utils.get_date_param('MONTH_HEAT2') then
   l_otop:=1;               
else
   l_otop:=0;
end if;
                           
if l_dt_start between utils.get_date_param('MONTH_HEAT3') --�����.������.������ � ����� ��� c_vvod.dist_tp=4
                  and utils.get_date_param('MONTH_HEAT4') then
   l_otop2:=1;               
else
   l_otop2:=0;
end if;

--����������� ����������� ��������� ���.����� ������ ��������������� ���.����� 
--����� ������������ c_kart_pr � c_states_pr �� ��������� �����
l_lsk_main:=null;
l_lsk_parent:=null;

if p_tp in ('LSK_TP_ADDIT','LSK_TP_RSO') then
  -- ��������.����� �� ������., �� ���
  begin
    select t.lsk, s.cd, k.k_lsk_id into l_lsk_main, l_status_cd, l_klsk
                          from kart k, kart t, u_list u, status s
                          where k.lsk=p_lsk and k.k_lsk_id=t.k_lsk_id
                          and t.psch not in (8,9) and t.fk_tp=u.id
                          and u.cd='LSK_TP_MAIN'
                          and t.status=s.id(+);
                          --and k.reu=t.reu; ���.08.08.2018,- ����� ������� �� reu, ��� ��� � ��� ��������� �������� �� � ������ ��
    exception when no_data_found then
      --��� ��������� �����, ����������� ��������� �� ��������
      l_lsk_main:=p_lsk;
    when others then
      Raise_application_error(-20000, '���������� ����� ���.����� lsk='||p_lsk);
      raise;                      
  end;
elsif p_tp='LSK_TP_MAIN' then
    for c in (select s.cd as status_cd, k.parent_lsk, k.k_lsk_id from kart k, status s
                          where k.lsk=p_lsk and k.status=s.id) loop
       l_status_cd:=c.status_cd;
       l_klsk:=c.k_lsk_id;
       --���� �������� ������������ ���.����, - ���������� ���
       if c.parent_lsk is not null then
         l_lsk_parent:=c.parent_lsk;
       end if;  
    end loop;                          
                                                
end if;


--�������� �������� ���-�� ������ (�������� ����, � �����������)
l_var_cnt_kpr:=nvl(utils.get_int_param('VAR_CNT_KPR'),0);
--�������������� �������� �������� ���-�� ������ (�������� ����, � �����������)
l_var_cnt_kpr2:=nvl(utils.get_int_param('VAR_CNT_KPR2'),0);

-- �������� ����� ����������� ��� ����������
l_cap_calc_kpr_tp:=nvl(utils.get_int_param('CAP_CALC_KPR_TP'),0);
--��������� ���� ������
l_dt_end:=last_day(l_dt_start);
--���-�� ���� � ������
l_max_days:=to_number(to_char(l_dt_end,'DD'));
--���� ������ ��� � ������
l_part_days:=1/l_max_days;

-- ��������� ������ ������������� ���.�����
if l_lsk_parent is not null then 
  load_temp(l_lsk_parent, t_state2);
end if;

--��������������� ������ � temp ������ � �������� �����������
load_temp(coalesce(l_lsk_main, p_lsk), t_state);

--������������� ������� �� ��������� �����������
init_array;
--������������� ������� � ���-�� ������ �� ������
init_arr_usl;

  --���������� ��� ������
  l_dt:=l_dt_start;
  while l_dt <= l_dt_end
  loop
--    j:=1;
    --���������� ������
    for c2 in cur1
    loop

      --������ ��� �������
      --begin
      --���� ���� ������� �����, ���� ��� ������ 4 - (���)
        if c2.counter is not null or c2.norm_tp=4 then
          if l_det <> 0 then
            --������� �������� �����
            l_psch:=get_status(p_state => t_state, p_dt => l_dt, p_tp => 2, p_prop => null);
            /*select nvl(max(t.fk_status),0) into l_psch
              from tmp_state t
               where t.tp=2 and l_dt between t.dt1 and t.dt2;*/
          else
            --�����, ��������� �������� �� ����� ������
            l_psch:=get_status(p_state => t_state, p_dt => l_dt_end, p_tp => 2, p_prop => null);
            /*select nvl(max(t.fk_status),0) into l_psch
              from tmp_state t
               where t.tp=2 and l_dt_end between t.dt1 and t.dt2;*/
--               Raise_application_error(-20000, to_char(l_dt_end,'YYYYMMDD')||'-'||l_psch);
          end if;
        else
         --������ ��� ���������
         l_psch:=0;
        end if;
        --�� ������ �������, ����������� ����� �� ��������� ����, ��� ��������� 0 (��...)
        if l_psch is null then
            l_psch:=nvl(get_status(p_state => t_state, p_dt => l_dt_end, p_tp => 2, p_prop => null),0);
        end if;
      --exception when NO_DATA_FOUND then
        /*select nvl(max(t.fk_status),0) into l_psch
          from tmp_state t
           where t.tp=2;*/
      --end;

      --������� ���-�� �����������, ������ ��� �������� �������, �� ������
      l_kpr:=0;
      l_kpr_wrz:=0;
      l_kpr_wro:=0;
      --l_kpr2 - ������� ����, �.�.�.�.�.�.�.�. ����� �.�. - ��� ������� � ��������� (�� ������ � l_max_kpr!)
      l_kpr2:=0;
      l_dummy:=0;

      l_dat_rog:=null;
      l_above70_owner:=0;
      l_above70:=0;
      l_under70:=0;
      
      if l_arr_prop2.count > 0 then
        for i in l_arr_prop2.FIRST..l_arr_prop2.LAST
        loop
          --�������� ������� ������������ �� �������
          get_prop(l_arr_prop, l_arr_prop2(i).id, l_dt, l_prop, l_prop_reg, l_rel_cd, l_dat_rog_tmp);
          if l_prop =1 --������ ��
             and months_between(l_dt, coalesce(l_dat_rog_tmp, sysdate))/12 >= 70 and l_rel_cd in ('���������������', '�����������') then
            --��������� ����������� >=70 ���, �� ��� � ��������������� (�����������)
            l_above70_owner:=1;
          elsif l_prop =1 --������ ��
             and months_between(l_dt, coalesce(l_dat_rog_tmp, sysdate))/12 >= 70 and (l_rel_cd is null or l_rel_cd not in ('���������������', '�����������')) then
            --��������� ����������� >=70 ���, �� �� ��������������� (�� �����������)
            l_above70:=1;
          elsif l_cap_calc_kpr_tp=1 and l_prop in (1) -- ������ ��
                and months_between(l_dt, coalesce(l_dat_rog_tmp, sysdate))/12 < 70 then
            --���������, �������� ����� <70 ���
            -- ������� �����
            l_under70:=1;
          elsif l_cap_calc_kpr_tp=0 and (l_prop in (1) or l_prop_reg in (3)) --��� �� ��� ��
                and months_between(l_dt, coalesce(l_dat_rog_tmp, sysdate))/12 < 70 then
            -- ������� ������
            --���������, �������� ����� <70 ���
            l_under70:=1;
          end if;
            
--          end if;
          --������� ���-�� ����������� �� ������ � ������� ���������
            --(��������� � ������ ������� ������� ���, ����� �� - ���-�� ����
          get_days(p_usl_type2 =>c2.usl_type2 ,
                   p_days => l_kpr, --���-�� ����. ��� ����������� ��������
                   p_days_wrz => l_kpr_wrz,
                   p_days_wro => l_kpr_wro,
                   p_days_kpr2 => l_kpr2, --���-�� ����. ��� ����������� ������ �� ���������, � ��� �� ����� ��������
                   p_prop => l_prop,
                   p_prop_reg => l_prop_reg,
                   p_var_cnt_kpr => l_var_cnt_kpr2);
        end loop;
      end if;

      -- �������� �� ������������� ���.����� �����������, ���������� ������������ ��������
      if l_lsk_parent is not null then

        if l_arr_prop3.count > 0 then
          for i in l_arr_prop3.FIRST..l_arr_prop3.LAST
          loop
            --�������� ������� ������������ �� �������
            get_prop(l_arr_prop4, l_arr_prop3(i).id, l_dt, l_prop, l_prop_reg, l_rel_cd, l_dat_rog_tmp);
            --������� ���-�� ����������� �� ������ � ������� ���������
              --(��������� � ������ ������� ������� ���, ����� �� - ���-�� ����
            get_days(p_usl_type2 =>c2.usl_type2,
                     p_days => l_kpr, --���-�� ����. ��� ����������� ��������
                     p_days_wrz => l_dummy, -- �� �����
                     p_days_wro => l_dummy, -- �� �����
                     p_days_kpr2 => l_dummy, -- �� �����
                     p_prop => l_prop,
                     p_prop_reg => l_prop_reg,
                     p_var_cnt_kpr => l_var_cnt_kpr2);
          end loop;
        end if;

        if l_var_cnt_kpr = 0 then
          --������� ���.
          if p_tp in ('LSK_TP_RSO') and nvl(l_kpr_wro,0) = 0 --���� ��� �������� ��������.
            -- ���� ���
            and l_kpr2 = 0 and l_status_cd not in ('MUN') then
            -- ��������� ���� ������ ������������ ��� ����������� ������
            l_kpr2:=1;
          end if;  
        end if;  
      else  
        -- ������ � ������������ �������!
        if l_var_cnt_kpr = 0 then
          --������� ���.
          if c2.fk_calc_tp=49 then
            -- ������ �� ��������� � ��� (���.)
            if l_kpr2 = 0 and l_status_cd not in ('MUN') then
              -- ��� ����������� � �� �������. ��������
              l_kpr:=1;
              l_kpr2:=1;
            end if;
          else
            -- ������ ������
            if nvl(l_kpr_wro,0) = 0 --���� ��� �������� ��������.
              and l_kpr2 = 0 and l_status_cd not in ('MUN') then
              -- ��������� ���� ������ ������������ ��� ����������� ������
              l_kpr2:=1;
            end if;  
          end if;       
        end if;
          
        if l_var_cnt_kpr = 1 and nvl(l_kpr_wro,0) = 0 --���� ��� �������� ��������.
          and l_kpr2 = 0 then
          --������� �����, � �.�. �� ������� �����.
          -- ��������� ���� ������ ������������ ��� ����������� ������
          l_kpr2:=1;
        end if;  

      end if;
      
      --���������� ��� ����� �� ���-�� �����������
      --(������ ��� ����������� ���� �� ����� � ����� ��������)
      l_norm:=null;
      if c2.norm_tp=1 then
        --������, �� ������� ����� �������� � �������
        l_norm:=c2.norm;
      elsif c2.norm_tp=2 then --��� ��.��.
        --������� l_kpr �� l_kpr2 (���� ���� ������� �� �� ���-�� ��� ����������� ���������??) ���. 01.12.2016
        if l_kpr2 = 1 THEN
          l_norm := 130;
        ELSIF l_kpr2 IN (2, 3) THEN
          l_norm := 100;
        ELSIF l_kpr2 = 4 THEN
          l_norm := 87.5;
        ELSIF l_kpr2 = 5 THEN
          l_norm := 80;
        ELSIF l_kpr2 >= 6 THEN
          l_norm := 75;
        END IF;
      elsif c2.norm_tp=3 then --��� ���.������., ��������� �2
        IF l_kpr2 = 1 THEN
          l_norm := c2.norma_1;
        ELSIF l_kpr2 IN (2) THEN
          l_norm := c2.norma_2;
        ELSIF l_kpr2 >= 3 THEN
          l_norm := c2.norma_3;
        ELSE
          --���-�� ������ = 0 (������ ��� �������� �����)
          l_norm := c2.norma_1;
        END IF;
      end if;

      --�������� ���-�� ���� ������� ��������
      l_temp_days:= null;
      if c2.cd in ('�.����') then
        l_temp_days:=l_hw_days;
      elsif c2.cd in ('�.����', '�.�. ��� ���') then
        l_temp_days:=l_gw_days;
      elsif c2.cd in ('����.����.','����.�����.') then
        l_temp_days:=l_max_days;
      else
        --��� ������ �����, ���� ���� ���-�� ����
        l_temp_days:=l_max_days;
      end if;

      --�������� ���� ������ ���
      if get_is_sch(c2.fk_calc_tp, l_psch, l_sch_el) = 1 then
        --�������, ���������� ��� � ������� ������� ��������� �� �������
        --(� ��� ����� ������� �� ���)
        for i in l_arr.FIRST..l_arr.LAST
        loop
          if l_arr(i).usl=c2.usl then
            l_arr(i).sch:=1;
          end if;
        end loop;

        --������� ��� ����� - ��������
--        l_tmp1:=l_norm * l_max_kpr * l_part_days;
       if c2.cd <> '�.����.���' or c2.cd='�.����.���' and
         (nvl(c2.kran1, 0) = 0 or
          nvl(c2.kran1, 0) = 1
          and l_dt between utils.get_date_param('MONTH_HEAT1') --�����.������.������
                       and utils.get_date_param('MONTH_HEAT2'))
          then

          l_tmp1:=l_norm * l_kpr2 * l_part_days;
          l_tmp2:=c2.sch_vol * 1/l_temp_days;

          insert into temp_c_charge_prep
           (usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, dt1, tp, opl)
          values
           (c2.usl,
           c2.sch_vol * 1/l_temp_days, --���� ������ ���
           case when l_tmp1 > l_tmp2 then
              l_tmp2
              else
               l_tmp1 end, --�� ���.�����
           case when l_tmp1 > l_tmp2 then
              null
              else
               l_tmp2 - l_tmp1 end, --����� ���.�����
           l_kpr * l_part_days,
           l_kpr_wrz * l_part_days,
           l_kpr_wro * l_part_days,
           l_kpr2 * l_part_days,
           1, l_dt, 0,
             case when nvl(c2.sch_vol * 1/l_temp_days,0)<>0 then c2.opl * 1/l_max_days
               else null end --������� � ���� ������ ���
           );
       end if;
      elsif get_is_sch(c2.fk_calc_tp, l_psch, l_sch_el) is null and c2.sch_vol <> 0 then
        --��� ��������, ������ �������������� �� ������ � nabor.vol (����.����) ��� 
        insert into temp_c_charge_prep
         (usl, vol, kpr, kprz, kpro, kpr2, sch, dt1, tp, opl)
        values
         (c2.usl,
         c2.sch_vol * 1/l_temp_days, --���� ������ ���
         l_kpr * l_part_days,
         l_kpr_wrz * l_part_days,
         l_kpr_wro * l_part_days,
         l_kpr2 * l_part_days,
         0, l_dt, 0,
           case when nvl(c2.sch_vol * 1/l_temp_days,0)<>0 then c2.opl * 1/l_max_days
             else null end --������� � ���� ������ ���
         );
      else
        --��������
        if c2.norm_tp=3 then
          --������ ���������/����� (��� ������ �������� ���������, ���.������. �2)
-- ������� ��� �����. 19.05.14
--          l_tmp1:=l_norm * l_max_kpr * l_part_days;
          if l_is_1room_sn=1 and c2.komn =1 and l_kpr2 > 0 then 
            --� 1-���� �������� ��� ������� �����������, �� ��� � �������� (���� ��������� ���������� l_is_1room_sn=1)
            l_tmp1:=c2.opl * 1/l_temp_days;
            l_tmp2:=c2.opl * 1/l_temp_days;
          else
            l_tmp1:=l_norm * l_kpr2 * l_part_days;
            l_tmp2:=c2.opl * 1/l_temp_days;
          end if;

          insert into temp_c_charge_prep
           (usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, dt1, tp, opl)
          values
           (c2.usl,
           l_tmp2, --���� ������ ���
           case when l_tmp1 > l_tmp2 then
              l_tmp2
              else
               l_tmp1 end, --�� ���.�����
           case when l_tmp1 > l_tmp2 then
              null
              else
               l_tmp2 - l_tmp1 end, --����� ���.�����
           l_kpr * l_part_days,
           l_kpr_wrz * l_part_days,
           l_kpr_wro * l_part_days,
           l_kpr2 * l_part_days,
           0, l_dt, 0,
           case when nvl(l_tmp2,0)<>0 then c2.opl * 1/l_max_days
             else null end --������� � ���� ������ ���
           );
        elsif c2.norm_tp=4 then
          --������ ����������� ���� �� ���
           if c2.cd <> '�.����.���' or c2.cd='�.����.���' and
             (nvl(c2.kran1, 0) = 0 or
              nvl(c2.kran1, 0) = 1
              and l_dt between utils.get_date_param('MONTH_HEAT1') --�����.������.������
                           and utils.get_date_param('MONTH_HEAT2'))
               then
                l_tmp1:=c2.sch_vol * l_part_days;
                insert into temp_c_charge_prep
                 (usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, dt1, tp, opl)
                values
                 (c2.usl,
                 l_tmp1, --���� ������ ���
                 l_tmp1, --������ �� ��������
                 null,
                 l_kpr * l_part_days,
                 l_kpr_wrz * l_part_days,
                 l_kpr_wro * l_part_days,
                 l_kpr2 * l_part_days,
                 0, l_dt, 0,
                 case when nvl(l_tmp1,0)<>0 then c2.opl * 1/l_max_days
                   else null end --������� � ���� ������ ���
                 );
            end if;
        elsif c2.norm_tp=5 then --���������
          
          insert into temp_c_charge_prep
           (usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, dt1, tp, opl)
          values
           (c2.usl,
           case when l_above70_owner=1 and l_above70 = 0 and l_under70=0 then 0 -- ������ �������� ������������� > 70 ��� 
                when l_above70_owner=1 and l_above70 = 1 and l_under70=0 then 0 -- ������ ������������� > 70 ��� � ������ > 70���
                else c2.opl * 1/l_temp_days end, --������� � ���� ������ ���
           null, null,
           l_kpr * l_part_days,
           l_kpr_wrz * l_part_days,
           l_kpr_wro * l_part_days,
           l_kpr2 * l_part_days,
           0, l_dt, 0,
           null);

          --�������� ���� �� ������
          insert into temp_c_charge_prep
           (usl, vol, dt1, tp, fk_spk)
          select 
           c2.usl,
           case when l_above70_owner=1 and l_under70=0 then c2.opl * 1/l_temp_days
                else null end as vol, --������� � ���� ������ ���
               l_dt as dt1, 8 as tp, t.id as fk_spk
           from spk t where 
           case when l_above70_owner=1 and l_above70 = 0 and l_under70=0 then 'PENS_SINGLE_70'
                when l_above70_owner=1 and l_above70 = 1 and l_under70=0 then 'PENS_70_WITH_70'
                else null end =t.cd;
        elsif c2.norm_tp in (1,2) then
          --�������� ������ (�� ��������) � �� ���� ������� ����� ��� �����
          if c2.kub <> 0.001  or c2.kub is null then
           --���� ��� ������ ����� �� �����, �� ������ �������� (������ ���� ����� ��� - 0.001)
           if c2.cd <> '�.����' or c2.cd='�.����' and
             (nvl(c2.kran1, 0) = 0 or
              nvl(c2.kran1, 0) = 1
              and l_dt between utils.get_date_param('MONTH_HEAT1') --�����.������.������
                           and utils.get_date_param('MONTH_HEAT2'))
               then
           --���� ������ - ������������ (������ ��� ������� ����)
             if nvl(l_kpr2,0) <> 0 then
             --���� ���� ����������� � ���� ����
               insert into temp_c_charge_prep
                 (usl, vol, vol_nrm, kpr, kprz, kpro, kpr2, sch, dt1, tp, opl)
                values
                 (c2.usl,
                 l_norm * l_kpr2 * l_part_days,
                 l_norm * l_kpr2 * l_part_days,
                 l_kpr * l_part_days,
                 l_kpr_wrz * l_part_days,
                 l_kpr_wro * l_part_days,
                 l_kpr2 * l_part_days,
                 0, l_dt, 0,
                 case when nvl(l_norm * l_kpr2 * l_part_days,0)<>0 then c2.opl * 1/l_max_days
                  else null end --������� � ���� ������ ���
                 );
              end if;
           end if;
          end if;
        end if;
      end if;
    end loop;
    l_dt:=l_dt+1;
  end loop;

   --�������� ������� � ������� �������� �� ������ � ������ �������
  for i in l_arr.FIRST..l_arr.LAST
  loop
    if l_arr(i).sch=1 then
      insert into c_charge_prep
       (lsk, usl, sch, tp)
      values
       (p_lsk, l_arr(i).usl, 1, 7);
    end if;
  end loop;

--������������ �� �������� �������
--��� ����� ������������� ���
--� TEMP
--��� ���� �����������
for i in l_arr.FIRST..l_arr.LAST
loop
  l_round:=l_arr(i).chrg_round;

  insert into temp_c_charge_prep
   (usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, tp)
  select usl, round(sum(vol), l_round),
   nvl(round(sum(vol_nrm), l_round),0)
   + --����������
   (nvl(round(sum(vol), l_round),0)-nvl(round(sum(vol_nrm), l_round),0)-nvl(round(sum(vol_sv_nrm), l_round),0))
   ,
   round(sum(vol_sv_nrm) ,l_round),
   round(sum(kpr),4),
   round(sum(kprz),4),
   round(sum(kpro),4),
   round(sum(kpr2),4),
   sch, 5 as tp
   from temp_c_charge_prep t
   where t.tp in (0) --�� ������� ������������� ��� (4)
   and nvl(t.kpr,0)<>0
   and t.usl = l_arr(i).usl
   group by t.usl, t.sch;

  --��� ��� ����������� � ���� �����
  insert into temp_c_charge_prep
   (usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, tp)
  select usl, round(sum(vol),l_round),
   nvl(round(sum(vol_nrm),l_round),0)
   + --����������
   (nvl(round(sum(vol),l_round),0)-nvl(round(sum(vol_nrm),l_round),0)-nvl(round(sum(vol_sv_nrm),l_round),0))
   ,
   round(sum(vol_sv_nrm) ,l_round),
   round(sum(kpr),4),
   round(sum(kprz),4),
   round(sum(kpro),4),
   round(sum(kpr2),4),
   sch, 5 as tp
   from temp_c_charge_prep t
   where t.tp in (0) --�� ������� ������������� ��� (4)
   and nvl(t.kpr,0)=0 and nvl(t.vol,0)<>0
   and t.usl = l_arr(i).usl
   group by t.usl, t.sch;

end loop;

--���������� � ����� �������
insert into c_charge_prep
 (lsk, usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, tp)
select p_lsk, usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, tp
 from temp_c_charge_prep t
 where t.tp = 5;


--� ������ ������������� ���
--������ � TEMP

--��� ���� �����������
for i in l_arr.FIRST..l_arr.LAST
loop
  l_round:=l_arr(i).chrg_round;
  
  insert into temp_c_charge_prep
   (usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, tp)
  select usl, round(sum(vol), l_round),
   nvl(round(sum(vol_nrm), l_round),0)
   + --����������
   (nvl(round(sum(vol), l_round),0)-nvl(round(sum(vol_nrm), l_round),0)-nvl(round(sum(vol_sv_nrm), l_round),0))
   ,
   round(sum(vol_sv_nrm) ,l_round),
   round(sum(kpr),4),
   round(sum(kprz),4),
   round(sum(kpro),4),
   round(sum(kpr2),4),
   sch, 1 as tp
   from (select p_lsk as lsk, usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, tp from
      temp_c_charge_prep r where r.tp=0
      union all
      select r.lsk, r.usl, r.vol, r.vol_nrm, r.vol_sv_nrm, r.kpr, r.kprz, r.kpro, r.kpr2, r.sch, r.tp from
      c_charge_prep r, nabor n, usl u where r.tp=4 and r.lsk=p_lsk
      and r.lsk=n.lsk and r.usl=u.usl 
      and u.fk_usl_chld=n.usl and nvl(n.koeff,0)<>0 and nvl(n.norm,0)<>0 -- ������� ������ ������, ������� �����������
      ) t
   where t.lsk=p_lsk and t.tp in (0,4) --������� ������������� ��� (4)
   and (nvl(t.kpr,0)<>0 or t.tp=4) --���� ���-�� ���������, ���� �������������
   and t.usl = l_arr(i).usl
   group by t.lsk, t.usl, t.sch;

  --���� ������� ����������� (����� �������� ������������� ��� ���� ���� ���� ����)
  if SQL%NOTFOUND then
    l_arr(i).exist_kpr:=0;
  else
    l_arr(i).exist_kpr:=1;
  end if;
end loop;


--��� ��� ����������� � ���� �����
for i in l_arr.FIRST..l_arr.LAST
loop
  l_round:=l_arr(i).chrg_round;
  insert into temp_c_charge_prep
   (usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, tp)
  select usl, round(sum(vol), l_round) as vol,
   nvl(round(sum(vol_nrm), l_round),0)
   + --����������
   (nvl(round(sum(vol), l_round),0)-nvl(round(sum(vol_nrm), l_round),0)-nvl(round(sum(vol_sv_nrm), l_round),0)) as vol_nrm,
   round(sum(vol_sv_nrm) , l_round) as vol_sv_nrm,
   round(sum(kpr),4) as kpr,
   round(sum(kprz),4) as kprz,
   round(sum(kpro),4) as kpro,
   round(sum(kpr2),4) as kpr2,
   sch, 1 as tp
   from (select p_lsk as lsk, usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, tp from
      temp_c_charge_prep r where r.tp=0
      union all
      select r.lsk, r.usl, r.vol, r.vol_nrm, r.vol_sv_nrm, r.kpr, r.kprz, r.kpro, r.kpr2, r.sch, r.tp from
      c_charge_prep r, nabor n, usl u where r.tp=4 and r.lsk=p_lsk
      and r.lsk=n.lsk and r.usl=u.usl 
      and u.fk_usl_chld=n.usl and nvl(n.koeff,0)<>0 and nvl(n.norm,0)<>0 -- ������� ������ ������, ������� �����������
      ) t
   where (t.tp in (0,4) and l_arr(i).exist_kpr=0 or
        t.tp in (0) and l_arr(i).exist_kpr=1)  --������� ��� �� ������� ������������� ��� (4)
   and nvl(t.kpr,0)=0 and nvl(t.vol,0)<>0
   and t.usl = l_arr(i).usl
   group by t.lsk, t.usl, t.sch;
end loop;

--���������� � ����� �������
insert into c_charge_prep
 (lsk, usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, tp)
select p_lsk, usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, tp
 from temp_c_charge_prep t
 where t.tp = 1;


--���� ������, ���� �����������, �� ��������, ���������
--�������������� �� �������- ���������� ��������
--��� ����� ����.���
insert into c_charge_prep
 (lsk, usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, tp)
 select p_lsk, usl, sum(vol) as vol, sum(vol_nrm) as vol_nrm,
        sum(vol_sv_nrm) as vol_sv_nrm, sum(kpr) as kpr,
        sum(kprz) as kprz, sum(kpro) as kpro, sum(kpr2) as kpr2, sch, 6 as tp
  from temp_c_charge_prep t where t.tp=5
  and (p_usl is null or t.usl = p_usl)
  group by usl, sch;

--� ������ ����.���
insert into c_charge_prep
 (lsk, usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, tp)
 select p_lsk, usl, sum(vol) as vol, sum(vol_nrm) as vol_nrm,
        sum(vol_sv_nrm) as vol_sv_nrm, sum(kpr) as kpr,
        sum(kprz) as kprz, sum(kpro) as kpro, sum(kpr2) as kpr2, sch, 3 as tp
  from temp_c_charge_prep t where t.tp=1
  and (p_usl is null or t.usl = p_usl)
  group by usl, sch;

--������������� ���� �� �������, �� ������� ��������
/*delete kmp1;
insert into kmp1
select * from temp_c_charge_prep t;*/

insert into c_charge_prep
 (lsk, usl, fk_spk, vol, tp, dt1, dt2)

with r as
 (select t.dt1, t.vol, t.usl, t.fk_spk
    from temp_c_charge_prep t
   where t.fk_spk is not null
     and (p_usl is null or t.usl = p_usl)
     and t.tp = 8)
     
select p_lsk as lsk, d.usl, d.fk_spk, round(sum(d.vol),2) as vol, 9 as tp, d.dt1, d.dt2
  from (
  select c.fk_spk, c.usl, c.dt1, c.dt2, r.vol
           from (select b.fk_spk, b.usl, grp1 as dt1,
                         case
                           when grp2 is null then
                            lead(grp2, 1) over (order by usl, dt1)
                           else
                            grp2
                         end as dt2
                    from (select fk_spk, usl, dt1,
                                  case
                                    when fk_spk = lag(fk_spk, 1) over(order by usl, dt1) and usl = lag(usl, 1) over(order by usl, dt1)
                                      then
                                     null
                                    else
                                     dt1
                                  end as grp1,
                                  case
                                    when fk_spk = lead(fk_spk, 1) over(order by usl, dt1) and usl = lead(usl, 1) over(order by usl, dt1) 
                                      then
                                     null
                                    else
                                     dt1
                                  end as grp2
                             from r) b
                   where b.grp1 is not null
                      or b.grp2 is not null) c
           join r
             on r.usl=c.usl and r.dt1 between c.dt1 and c.dt2
          where c.dt1 is not null
            and c.dt2 is not null
            ) d
 group by d.fk_spk, d.usl, d.dt1, d.dt2;

/* if sql%rowcount = 0 then 
   Raise_application_error(-20000, 'TEST1');
 end if;*/

--����� ����� �������� �������� �����������!
/*insert into c_charge_prep
 (lsk, usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch, tp, dt1, dt2, fk_spk)
 select p_lsk, usl, vol, vol_nrm, vol_sv_nrm, kpr, kprz, kpro, kpr2, sch,
   t.tp as tp, t.dt1, t.dt2, t.fk_spk
  from temp_c_charge_prep t where t.tp in (0,8); --�������� ���������� � ������
*/

--������� �������������� ������� ������� ���-�� �����������
if nvl(p_set_utl_kpr,0) = 1 then
  utils.set_kpr(p_lsk);
end if;

end;

procedure get_days(
   p_usl_type2 in usl.usl_type2%type,
   p_days in out number,
   p_days_wrz in out number,
   p_days_wro in out number,
   p_days_kpr2 in out number,
   p_prop in c_states_pr.fk_status%type,
   p_prop_reg in c_states_pr.fk_status%type,
   p_var_cnt_kpr in number) is
begin
--������ ��������� (�.�.,�.�.)
if p_var_cnt_kpr = 0 then
  --������� ���.
  if p_prop in (4) and p_prop_reg is null then
    --������� ��� ���.��������
    null;
  elsif p_prop in (4) and p_prop_reg in (2) then
    --������� � �������� �����. (������, �� ������ ������)
    null;
  elsif (p_prop in (4) or p_prop is null) and p_prop_reg in (3) then
    --������� ��� ������ �������� ������ � �������� �����.
    if p_usl_type2 =1 then
      --������ �������� (���.���.)
      p_days:=p_days+1;
      p_days_wrz:=p_days_wrz+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      p_days:=p_days+1;
      p_days_wrz:=p_days_wrz+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
      --������ ������������ (�.�.)
    --���. 20.08.2014
    null;
--      p_days:=p_days+1;
    end if;
  elsif (p_prop in (4) or p_prop is null) and p_prop_reg in (6) then
    --������� ��� ������ �������� ������ � �������� �����������
    if p_usl_type2 =1 then
      --������ �������� (���.���.)
      p_days_wrz:=p_days_wrz+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      p_days_wrz:=p_days_wrz+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
      --������ ������������ (�.�.)
    --���. 20.08.2014
    null;
--      p_days:=p_days+1;
    end if;
  elsif p_prop in (1,5) and p_prop_reg is null then
    --�������� ��� ������=���_���������� ��� ���.��������
    if p_usl_type2 =1 then
      --������ �������� (���.���.)
      p_days:=p_days+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      p_days:=p_days+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
      p_days:=p_days+1;
    end if;
  elsif p_prop in (1,5) and p_prop_reg in (2) then
    --�������� ��� ������=���_���������� � �������� �����.
    if p_usl_type2 =1 then
      --������ �������� (���.���.)
      p_days:=p_days+1;
      p_days_wro:=p_days_wro+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      --p_days:=p_days+1; - ��� ������ ������ 03.03.2017
      p_days_wro:=p_days_wro+1;
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
      p_days:=p_days+1;
    end if;
  elsif p_prop in (1,5) and p_prop_reg in (3,6) then
    --�������� ��� ������=���_���������� � �������� �����. (������, �� ������ ������)
    if p_usl_type2 =1 then
      --������ �������� (���.���.)
      p_days:=p_days+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      p_days:=p_days+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
    --���. 20.08.2014
    null;
--      p_days:=p_days+1;
    end if;
  end if;
elsif p_var_cnt_kpr = 1 then
--#######################################################################
--������� �����.
  if p_prop in (4) and p_prop_reg is null then
    --������� ��� ���.��������
    null;
  elsif p_prop in (4) and p_prop_reg in (2) then
    --������� � �������� �����. (������, �� ������ ������)
    null;
  elsif (p_prop in (4) or p_prop is null) and p_prop_reg in (3) then
    --������� ��� ������ �������� ������ � �������� �����.
    if p_usl_type2 =1 then
      --������ �������� (���������)
      p_days_wrz:=p_days_wrz+1;
      --��� ������� ������ ��� ������������ ����������
      --p_days_kpr2:=p_days_kpr2+1;
      --p_days:=p_days+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      p_days_wrz:=p_days_wrz+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
      p_days:=p_days+1;
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
      --������ ������������ (�.�.)
      p_days:=p_days+1;
    end if;
  elsif (p_prop in (4) or p_prop is null) and p_prop_reg in (6) then
    --������� ��� ������ �������� ������ � �������� �����.
    if p_usl_type2 =1 then
      --������ �������� (���������)
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
      p_days_kpr2:=p_days_kpr2+1;
    end if;
  elsif p_prop in (1,5) and p_prop_reg is null then
    --�������� ��� ������=���_���������� ��� ���.��������
    if p_usl_type2 =1 then
      --������ �������� (���.���.)
      p_days:=p_days+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      p_days:=p_days+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
      p_days:=p_days+1;
    end if;
  elsif p_prop in (1,5) and p_prop_reg in (2) then
    --�������� ��� ������=���_���������� � �������� �����.
    if p_usl_type2 =1 then
      --������ �������� (���.���.)
      p_days:=p_days+1;
      p_days_wro:=p_days_wro+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      p_days:=p_days+1;
      p_days_wro:=p_days_wro+1;
      --��� ������� ������ ��� ������������ ����������
      --p_days_kpr2:=p_days_kpr2+1; ---�������
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
      p_days:=p_days+1;
    end if;
  elsif p_prop in (1,5) and p_prop_reg in (3,6) then
    --�������� ��� ������=���_���������� � �������� �����. (������, �� ������ ������)
    if p_usl_type2 =1 then
      --������ �������� (���.���.)
      p_days:=p_days+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      p_days:=p_days+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
      p_days:=p_days+1;
    end if;
  end if;
elsif p_var_cnt_kpr = 2 then
--#######################################################################
--������� ���
  if p_prop in (4) and p_prop_reg is null then
    --������� ��� ���.��������
    null;
  elsif p_prop in (4) and p_prop_reg in (2) then
    --������� � �������� �����. (������, �� ������ ������)
    null;
  elsif (p_prop in (4) or p_prop is null) and p_prop_reg in (3,6) then
    --������� ��� ������ �������� ������ � �������� �����.
    if p_usl_type2 =1 then
      --������ �������� (���������)
      p_days_wrz:=p_days_wrz+1;
      --��� ������� ������ ��� ������������ ����������
--      p_days_kpr2:=p_days_kpr2+1;
      p_days:=p_days+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      p_days_wrz:=p_days_wrz+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
      p_days:=p_days+1;
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
      --������ ������������ (�.�.)
      p_days:=p_days+1;
    end if;
  elsif p_prop in (1,5) and p_prop_reg is null then
    --�������� ��� ������=���_���������� ��� ���.��������
    if p_usl_type2 =1 then
      --������ �������� (���.���.)
      p_days:=p_days+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      p_days:=p_days+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
      p_days:=p_days+1;
    end if;
  elsif p_prop in (1,5) and p_prop_reg in (2) then
    --�������� ��� ������=���_���������� � �������� �����.
    if p_usl_type2 =1 then
      --������ �������� (���.���.)
      p_days:=p_days+1;
      p_days_wro:=p_days_wro+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      p_days:=p_days+1;
      p_days_wro:=p_days_wro+1;
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
      p_days:=p_days+1;
    end if;
  elsif p_prop in (1,5) and p_prop_reg in (3,6) then
    --�������� ��� ������=���_���������� � �������� �����. (������, �� ������ ������)
    if p_usl_type2 =1 then
      --������ �������� (���.���.)
      p_days:=p_days+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (0) then
      --������ ������������ (�.�.)
      p_days:=p_days+1;
      --��� ������� ������ ��� ������������ ����������
      p_days_kpr2:=p_days_kpr2+1;
    elsif p_usl_type2 in (2) then
      --��� ������� ���� ���-�� ������
      p_days:=p_days+1;
    end if;
  end if;

end if;
end;

function get_is_sch (p_fk_calc in usl.fk_calc_tp%type,
  p_psch in kart.psch%type, p_sch_el in kart.sch_el%type) return number is
l_ret number;
begin
--������� ������������ ������� �������� �� ������
l_ret:=null;

if p_fk_calc in (3, 17, 20, 38, 41) then --(� �.�.��� ������)
  --�.����
  if p_psch in (1,2) then
    l_ret:=1;
  else
    l_ret:=0;
  end if;
elsif p_fk_calc in (4, 18, 21, 38, 40, 42) then --(� �.�.��� ������)
  --�.����
  if p_psch in (1,3) then
    l_ret:=1;
  else
    l_ret:=0;
  end if;
elsif p_fk_calc in (31, 23) then --����� �������� ������ fk_calc (���������!) --(� �.�.��� ������)
  --��.�����
    l_ret:=p_sch_el;
end if;

return l_ret;
end;

function get_is_chrg(p_sptarn in usl.sptarn%type,
    p_koeff in nabor.koeff%type, p_norm in nabor.norm%type) return number is
begin
  --������� ����������� ������� ������ �� �����
  --������������ nabor � usl
  case
     when p_sptarn = 0 and nvl(p_koeff, 0) <> 0 then
      return 1;
     when p_sptarn = 1 and nvl(p_norm, 0) <> 0 then
      return 1;
     when p_sptarn = 2 and nvl(p_koeff, 0) <> 0 and nvl(p_norm, 0) <> 0 then
      return 1;
     when p_sptarn = 3 and nvl(p_koeff, 0) <> 0 and nvl(p_norm, 0) <> 0 then
      return 1;
     else
      return 0;
   end case;
end;

--���������� ��������� �������� (� �������� ��� ��� ���)
function set_kw_par(p_house_guid in varchar2, p_kw in varchar2, p_entr in number) return number is
begin
  for c in (select k.rowid as rd from 
    kart k join prep_house_fias f on k.house_id=f.fk_house
      and upper(f.houseguid)=upper(p_house_guid)
      and k.kw=lpad(ltrim(p_kw), 7, '0') --���� �� ������� ��� ����� � ���������� � ��������� ��������
      and k.psch not in (8,9)
    )
  loop
    --���������� �������
    update kart k set k.entr=p_entr where k.rowid=c.rd;
  end loop;
  if sql%rowcount = 0 then
    return 1; --�� ������� ��� ��������
  else  
    return 0; --�������
  end if;
end;

--���������� ������ ���.����
function set_elsk (p_lsk in kart.lsk%type, p_elsk in varchar2) return number is
begin
  update kart k set k.elsk=p_elsk where k.lsk=p_lsk;  
  if sql%rowcount = 0 then
    return 1; --�� ������� ��� ��������
  else  
    return 0; --�������
  end if;
end;  

end C_KART;
/

