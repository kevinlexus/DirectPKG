create or replace package body exs.P_GIS is

/** �������� �������� ������� �������� Eolink **/
function get_root_eolink(p_id in number, -- Id ��������
                         p_tp in varchar2 -- ��� �������� ��������
                         ) return number is
begin
  for c in (select e.id as root_id, e.parent_id, tp.cd as addrTp  
             from exs.eolink e join bs.addr_tp tp on e.fk_objtp=tp.id
             and e.id=p_id) loop
             if c.addrtp=p_tp then
               -- ������� ������
                return c.root_id;  
             else
               -- ���������� �����
               return get_root_eolink(c.parent_id, p_tp);
             end if;   
  end loop;   
  -- ������� �� ������        
  return 0;
end;


-- �������� ����������� �� �� ����� ��
function insert_pd_by_uk(p_eol_uk in number -- Id �� � Eolink
                              ) return number is 
  l_cnt number;                            
begin
  -- �� ������� ����
  l_cnt:=0;
  for c in (select t.id from exs.eolink t where t.parent_id=p_eol_uk) loop
    l_cnt:=l_cnt+insert_pd_by_house(c.id, null, p_eol_uk);
  end loop;
  return l_cnt;
end;                              

-- �������� ����������� �� �� ����� �����, ��� ������� ���.����� ���
function insert_pd_by_rso(p_eol_uk in number -- Id ��� � Eolink
                              ) return number is 
  a number;                              
  l_cnt number;                            
begin
  -- �� ������� ����, � ������� ������������ �������� ���.����� ���
  l_cnt:=0;
  for c in (select distinct a.id, a.reu from (
    -- ��������� � ���������
      select distinct t.id, o.reu from exs.eolink t --���
             join BS.ADDR_TP tp4 on t.fk_objtp=tp4.id and tp4.cd='���'
             join exs.eolink p on p.parent_id=t.id -- �������
             join BS.ADDR_TP tp2 on p.fk_objtp=tp2.id and tp2.cd='�������'
             join exs.eolink kw on kw.parent_id=p.id -- ��������� � ���������
             join BS.ADDR_TP tp3 on kw.fk_objtp=tp3.id and tp3.cd='��������'
             join exs.eolink s on s.parent_id=kw.id --and s.status=1 -- �������� ���.��.
             join BS.ADDR_TP tp on s.fk_objtp=tp.id and tp.cd='��'
             join exs.eolink o on s.fk_uk=o.id
             join BS.ADDR_TP tp5 on o.fk_objtp=tp5.id and tp5.cd='�����������'
             where s.fk_uk = p_eol_uk 
             union all
    -- ��������� ��� ��������
      select distinct t.id, o.reu from exs.eolink t --���
             join BS.ADDR_TP tp4 on t.fk_objtp=tp4.id and tp4.cd='���'
             join exs.eolink kw on kw.parent_id=t.id -- ��������� ��� ��������
             join BS.ADDR_TP tp3 on kw.fk_objtp=tp3.id and tp3.cd='��������'
             join exs.eolink s on s.parent_id=kw.id --and s.status=1 -- �������� ���.��.
             join BS.ADDR_TP tp on s.fk_objtp=tp.id and tp.cd='��'
             join exs.eolink o on s.fk_uk=o.id
             join BS.ADDR_TP tp5 on o.fk_objtp=tp5.id and tp5.cd='�����������'
             where s.fk_uk = p_eol_uk 
             union all
    -- ������� ���
      select distinct t.id, o.reu from exs.eolink t --���
             join BS.ADDR_TP tp4 on t.fk_objtp=tp4.id and tp4.cd='���'
             join exs.eolink s on s.parent_id=t.id
             join BS.ADDR_TP tp on s.fk_objtp=tp.id and tp.cd='��'
             join exs.eolink o on s.fk_uk=o.id
             join BS.ADDR_TP tp5 on o.fk_objtp=tp5.id and tp5.cd='�����������'
             where s.fk_uk = p_eol_uk 
             ) a
             order by a.id
    ) loop
    l_cnt:=l_cnt+insert_pd_by_house(c.id, c.reu, p_eol_uk);
  end loop;
  return l_cnt;
end;                              

-- �������� ����������� �� �� ����� ����
function insert_pd_by_house(p_eol_house in number, -- Id ���� � Eolink
                            p_reu in varchar2,      -- ��� �� (���) ���� �� ��������� - �� ����� �������� ��� �����        
                            p_eol_uk in number -- Id �� � Eolink
                              ) return number is 
  l_dt date;  
  l_cnt number;                            
  l_cnt2 number;                            
begin
  -- �������� �������� - ���� ������� - ��������� ���� �������� ������� 
  select last_day(scott.getdt(1, substr(p.s1,5,2), substr(p.s1,1,4))) into l_dt
  from exs.eolink t join exs.eolxpar p on t.id=p.fk_eolink
   join oralv.u_hfpar u on p.fk_par=u.id
   where t.fk_objtp=1 and t.parent_id is null
   and u.cd='��� ���.PERIOD_IMP_PD';
 
/*  l_dt:=scott.getdt(p_day => 1,
                     p_month => 0,
                     p_year => 0)-1; -- ��������� ���� �������� ������� 
*/
  -- ������ ������ ��������, �� ���������� - � ����������                 
  update exs.pdoc t set t.err=0 
    where exists (
        select * from exs.eolink s 
             join exs.eolink kw on s.parent_id=kw.id -- ��������� �������� � �������
             join exs.eolink p on kw.parent_id=p.id and p.parent_id=p_eol_house -- �������
             join BS.ADDR_TP tp on s.fk_objtp=tp.id and tp.cd='��'
             where s.id=t.fk_eolink
    ) and t.dt=l_dt;
  -- ������ ������ ��������, �� ���������� - ��� ���������
  update exs.pdoc t set t.err=0 
    where exists (
        select * from exs.eolink d 
             join exs.eolink kw on d.parent_id=kw.id and kw.parent_id=p_eol_house -- ��������� �� �������� � �������
             join BS.ADDR_TP tp on d.fk_objtp=tp.id and tp.cd='��'
             where d.id=t.fk_eolink
    ) and t.dt=l_dt;
  l_cnt2:=sql%ROWCOUNT;                     

  -- �������� ����� ���������  
  insert into exs.pdoc
  (fk_eolink, status, v, dt)
  select s.id, 0, 1, l_dt from exs.eolink s -- �� Eolink
       join scott.kart k on s.lsk=k.lsk and k.psch not in (8,9) -- �� �������
       join scott.v_lsk_tp tp2 on k.fk_tp=tp2.id 
        and nvl(p_reu,k.reu)=k.reu and decode(p_reu,null,'LSK_TP_MAIN',tp2.cd)=tp2.cd -- ���� �������� ��� �� (���) ���� ������ �������� ���.�����
       join exs.eolink kw on s.parent_id=kw.id  -- ���������, �������� � �������
       join exs.eolink p on kw.parent_id=p.id and p.parent_id=p_eol_house -- �������
       join BS.ADDR_TP tp on s.fk_objtp=tp.id and tp.cd='��' and s.status=1 and s.uniqnum is not null-- �� ��������, � ����������� ������� ��� ���. 03.10.2019
       and not exists (select * from exs.pdoc d 
           where d.fk_eolink=s.id and d.status in (0,1) -- ����� ���������� �� �������� � ����������� �� �� ������ ������ � ������ ��
           and d.v = 1 -- ��������
           and d.dt=l_dt
           )
       /*and not exists (
        select * from exs.task d join bs.list i 
             on d.fk_act=i.id and i.cd='GIS_IMP_PAY_DOCS'
          where d.fk_eolink=p_eol_house and d.fk_proc_uk=p_eol_uk
            and d.state in ('INS','ACK') -- ���� ��� ������� �� ���� � ��������� �������� � ��� 
                       )*/;

  l_cnt:=sql%ROWCOUNT;                     

  -- �������� ����� ��������� �� ���.������ ��� ���������
  insert into exs.pdoc
  (fk_eolink, status, v, dt)
  select s.id, 0, 1, l_dt from exs.eolink s -- �� Eolink
       join scott.kart k on s.lsk=k.lsk and k.psch not in (8,9) -- �� �������
       join scott.v_lsk_tp tp2 on k.fk_tp=tp2.id 
        and nvl(p_reu,k.reu)=k.reu and decode(p_reu,null,'LSK_TP_MAIN',tp2.cd)=tp2.cd -- ���� �������� ��� �� (���) ���� ������ �������� ���.�����
       join exs.eolink kw on s.parent_id=kw.id and kw.parent_id=p_eol_house -- ���������, �� �������� � �������
       join BS.ADDR_TP tp on s.fk_objtp=tp.id and tp.cd='��' and s.status=1 -- �� ��������
       and not exists (select * from exs.pdoc d 
           where d.fk_eolink=s.id and d.status in (0,1) -- ����� ���������� �� �������� � ����������� �� �� ������ ������ � ������ ��
           and d.v = 1 -- ��������
           and d.dt=l_dt
           )
       /*and not exists (
        select * from exs.task d join bs.list i 
             on d.fk_act=i.id and i.cd='GIS_IMP_PAY_DOCS'
          where d.fk_eolink=p_eol_house and d.fk_proc_uk=p_eol_uk
            and d.state in ('INS','ACK') -- ���� ��� ������� �� ���� � ��������� �������� � ��� 
                       )*/;

  l_cnt:=l_cnt+sql%ROWCOUNT;                     
  -- �������� ����� ��������� �� ���.������ �������� �������
  insert into exs.pdoc
  (fk_eolink, status, v, dt)
  select s.id, 0, 1, l_dt from exs.eolink s -- �� Eolink
       join scott.kart k on s.lsk=k.lsk and k.psch not in (8,9) -- �� �������
       join scott.v_lsk_tp tp2 on k.fk_tp=tp2.id 
        and nvl(p_reu,k.reu)=k.reu and decode(p_reu,null,'LSK_TP_MAIN',tp2.cd)=tp2.cd -- ���� �������� ��� �� (���) ���� ������ �������� ���.�����
       join exs.eolink kw on s.parent_id=kw.id and kw.id=p_eol_house -- ������� ���
       join BS.ADDR_TP tp on s.fk_objtp=tp.id and tp.cd='��' and s.status=1 -- �� ��������
       and not exists (select * from exs.pdoc d 
           where d.fk_eolink=s.id and d.status in (0,1) -- ����� ���������� �� �������� � ����������� �� �� ������ ������ � ������ ��
           and d.v = 1 -- ��������
           and d.dt=l_dt
           )
       /*and not exists (
        select * from exs.task d join bs.list i 
             on d.fk_act=i.id and i.cd='GIS_IMP_PAY_DOCS'
          where d.fk_eolink=p_eol_house and d.fk_proc_uk=p_eol_uk
            and d.state in ('INS','ACK') -- ���� ��� ������� �� ���� � ��������� �������� � ��� 
                       )*/;

  l_cnt:=l_cnt+sql%ROWCOUNT;                     
  -- ������������ �������� �������                     
  if l_cnt > 0 or l_cnt2 > 0 then                   
    if activate_task_by_house(p_eol_house, 'GIS_IMP_PAY_DOCS', p_eol_uk) = 0 then
      rollback;
      Raise_application_error(-20000, '������! ��� ����������� ��� �� ���������� ������� �� �������� ��');
    end if;
  end if;  
  return l_cnt;                   
end;


-- ��������� ��� ������������� GisExchanger - �� �� ����������������� ����������
-- �������� �� �� ����� �� (���)
function withdraw_pd_by_uk(p_eol_uk in number -- Id uk � Eolink
                              ) return number is 
  l_cnt number;                            
begin
  -- �� ������� ����
  l_cnt:=0;
  for c in (select distinct parent_id from (
            select p.parent_id from exs.eolink s 
                         join exs.eolink kw on s.parent_id=kw.id -- ���������, �������� � �������
                         join exs.eolink p on kw.parent_id=p.id -- �������
                         where s.fk_uk=p_eol_uk
            union all
            select kw.parent_id from exs.eolink s 
                         join exs.eolink kw on s.parent_id=kw.id -- ���������, �� �������� � �������
                         where s.fk_uk=p_eol_uk                         
            )) loop
    l_cnt:=l_cnt+withdraw_pd_by_house(c.parent_id, p_eol_uk);
  end loop;
  return l_cnt;
end;                              


-- ��������� ��� ������������� GisExchanger - �� �� ����������������� ����������
-- �������� �� �� ����� ����
function withdraw_pd_by_house(p_eol_house in number, -- Id ���� � Eolink
                              p_eol_uk in number -- Id �� � Eolink
                              ) return number is 
  l_cnt number;                            
  l_dt date;
begin

  -- �������� �������� - ���� ������� - ��������� ���� �������� ������� 
  select last_day(scott.getdt(1, substr(p.s1,5,2), substr(p.s1,1,4))) into l_dt
  from exs.eolink t join exs.eolxpar p on t.id=p.fk_eolink
   join oralv.u_hfpar u on p.fk_par=u.id
   where t.fk_objtp=1 and t.parent_id is null
   and u.cd='��� ���.PERIOD_IMP_PD';

  -- ���������, �������� � �������                     
  update exs.pdoc t set t.v=0
     where t.status in (0, 1) -- ����������� �� �������� ��� �����������
     and t.v<>0 -- ����� ����������
     and exists (select * from exs.eolink s 
                         join exs.eolink kw on s.parent_id=kw.id -- ���������, �������� � �������
                         join exs.eolink p on kw.parent_id=p.id and p.parent_id=p_eol_house -- �������
                         where s.id=t.fk_eolink and s.fk_uk=p_eol_uk
                         )
     and t.dt=l_dt -- �� ���������� ������                    
     and not exists (
      select * from exs.task s join bs.list i 
           on s.fk_act=i.id and i.cd='GIS_IMP_PAY_DOCS'
        where s.fk_eolink=p_eol_house
          and s.state in ('INS','ACK') -- ���� ��� ������� �� ���� � ��������� �������� � ��� 
                     );
  -- ���������, �� �������� � �������                     
  update exs.pdoc t set t.v=0
     where t.status in (0, 1) -- ����������� �� �������� ��� �����������
     and t.v<>0 -- ����� ����������
     and exists (select * from exs.eolink s 
                         join exs.eolink kw on s.parent_id=kw.id and s.parent_id=p_eol_house-- ���������, �� �������� � �������
                         where s.id=t.fk_eolink and s.fk_uk=p_eol_uk
                         )
     and t.dt=l_dt -- �� ���������� ������                    
     and not exists (
      select * from exs.task s join bs.list i 
           on s.fk_act=i.id and i.cd='GIS_IMP_PAY_DOCS'
        where s.fk_eolink=p_eol_house
          and s.state in ('INS','ACK') -- ���� ��� ������� �� ���� � ��������� �������� � ��� 
                     );


  l_cnt:=sql%ROWCOUNT;                     
  -- ������������ �������� �������  
  if l_cnt > 0 then                   
    if activate_task_by_house(p_eol_house, 'GIS_IMP_PAY_DOCS', p_eol_uk) = 0 then
      rollback;
      Raise_application_error(-20000, '������! ��� ����������� ��� �� ���������� ������� �� �������� ��');
    end if;
  end if;  
  return l_cnt;                   
end;

-- ������������� ��������� �� ������ �� �������� ������� - ��� ������ �� Java
-- �������� ��������� �����, � ���.�������,
-- � �������� ��� ����, ������ � �������� ������
procedure annulment_notif(
         p_kwtp_id in number, -- Id �������
         p_ret out number -- ���������
         ) is
l_id number;
l_id2 number;
begin
    -- �������, ��� ������ �� �����������
    update scott.c_kwtp t set t.annul=1 where t.id=p_kwtp_id and nvl(t.annul,0) != 1;
    if SQL%ROWCOUNT = 0 then
      -- ���� ������ �� ������, ���� ��� �����������
      rollback;
      p_ret:=4;
      return;
    end if;  
    
    select scott.c_kwtp_id.nextval into l_id from dual;
    insert into scott.c_kwtp
      (lsk, summa, penya, oper, dopl, nink,
       nkom, dtek, nkvit, id,
       iscorrect, num_doc, dat_doc, dat_ink)
    select t.lsk, -1*nvl(t.summa,0) as summa, -1*nvl(t.penya,0) as penya,
       t.oper, t.dopl, 0 as nink,
       t.nkom, t.dtek as dtek, t.nkvit, l_id,
       t.iscorrect, t.num_doc, t.dat_doc, t.dat_ink as dat_ink
    from scott.c_kwtp t
    where t.id=p_kwtp_id;
    if SQL%ROWCOUNT = 0 then
      --�� �������
      rollback;
      p_ret:=1;
      return;
    end if;  
    for c in (select t.lsk, -1*nvl(summa,0) as summa, -1*nvl(penya,0) as penya,
        t.oper, t.dopl, null as nink,
        t.nkom as nkom, t.dtek as dtek, t.nkvit as nkvit,
        t.cnt_sch, t.cnt_sch0, t.id, t.dat_ink
      from scott.c_kwtp_mg t
      where t.c_kwtp_id=p_kwtp_id)
    loop
      insert into scott.c_kwtp_mg
        (lsk, summa, penya, oper, dopl,
        nkom, dtek, nkvit, c_kwtp_id,
        cnt_sch, cnt_sch0, is_dist, nink, dat_ink)
      values
        (c.lsk, c.summa, c.penya, c.oper, c.dopl,
        c.nkom, c.dtek, c.nkvit, l_id,
        c.cnt_sch, c.cnt_sch0, 1, --is_dist=1 - ������ ��� ������������ (���� �������� �� �������������� � ��������)
        0, c.dat_ink
        )
       returning id into l_id2;
      if SQL%ROWCOUNT = 0 then
        --�� �������
        rollback;
        p_ret:=2;
        return;
      end if;

      insert into scott.kwtp_day
        (summa, lsk, oper, dopl, nkom, nink,
        dtek, priznak, usl, org, fk_distr, sum_distr, kwtp_id, dat_ink)
      select -1*nvl(t.summa,0) as summa,
        t.lsk, t.oper, t.dopl, t.nkom, 0 as nink,
        t.dtek, t.priznak, t.usl, t.org, 13 as fk_distr, --13 ��� (�������� �����)
        t.sum_distr,
        l_id2 as kwtp_id,
        t.dat_ink
        from scott.kwtp_day t
        where t.kwtp_id=c.id;
      if SQL%ROWCOUNT = 0 then
        --�� �������
        rollback;
        p_ret:=3;
        return;
      end if;
    end loop;
--�������
p_ret:=0;
return;

end;


-- ������������� ��������� �� ������ �� ������ - ��� ������ �� Java
-- �������� ��������� �����, � ���.�������,
-- � �������� ��� ����, ������ � �������� ������
procedure annulment_arch_notif(
         p_kwtp_id in number, -- Id �������
         p_ret out number -- ���������
         ) is
l_id number;
l_id2 number;
l_dt date;
begin
    l_dt:=scott.init.get_period_date(null); -- ���� 1 �����, ��� ������������� �������� � ������
    -- �������, ��� ������ �� �����������
    update scott.a_kwtp t set t.annul=1 where t.id=p_kwtp_id and nvl(t.annul,0) != 1;
    if SQL%ROWCOUNT = 0 then
      -- ���� ������ �� ������, ���� ��� �����������
      rollback;
      p_ret:=4;
      return;
    end if;  
    
    select scott.c_kwtp_id.nextval into l_id from dual;
    insert into scott.c_kwtp
      (lsk, summa, penya, oper, dopl, nink,
       nkom, dtek, nkvit, id,
       iscorrect, num_doc, dat_doc, dat_ink)
    select t.lsk, -1*nvl(t.summa,0) as summa, -1*nvl(t.penya,0) as penya,
       t.oper, t.dopl, 0 as nink,
       t.nkom, l_dt as dtek, t.nkvit, l_id,
       t.iscorrect, t.num_doc, t.dat_doc, l_dt as dat_ink
    from scott.a_kwtp t
    where t.id=p_kwtp_id;
    if SQL%ROWCOUNT = 0 then
      --�� �������
      rollback;
      p_ret:=1;
      return;
    end if;  
    for c in (select t.lsk, -1*nvl(summa,0) as summa, -1*nvl(penya,0) as penya,
        t.oper, t.dopl, null as nink,
        t.nkom as nkom, l_dt as dtek, t.nkvit as nkvit,
        t.cnt_sch, t.cnt_sch0, t.id
      from scott.a_kwtp_mg t
      where t.c_kwtp_id=p_kwtp_id)
    loop
      insert into scott.c_kwtp_mg
        (lsk, summa, penya, oper, dopl,
        nkom, dtek, nkvit, c_kwtp_id,
        cnt_sch, cnt_sch0, is_dist, nink, dat_ink)
      values
        (c.lsk, c.summa, c.penya, c.oper, c.dopl,
        c.nkom, l_dt, c.nkvit, l_id,
        c.cnt_sch, c.cnt_sch0, 1, --is_dist=1 - ������ ��� ������������ (���� �������� �� �������������� � ��������)
        0, l_dt
        )
       returning id into l_id2;
      if SQL%ROWCOUNT = 0 then
        --�� �������
        rollback;
        p_ret:=2;
        return;
      end if;

      insert into scott.kwtp_day
        (summa, lsk, oper, dopl, nkom, nink,
        dtek, priznak, usl, org, fk_distr, sum_distr, kwtp_id, dat_ink)
      select -1*nvl(t.summa,0) as summa,
        t.lsk, t.oper, t.dopl, t.nkom, 0 as nink,
        l_dt as dtek, t.priznak, t.usl, t.org, 13 as fk_distr, --13 ��� (�������� �����)
        t.sum_distr,
        l_id2 as kwtp_id,
        l_dt as dat_ink
        from scott.a_kwtp_day t
        where t.kwtp_id=c.id;
      if SQL%ROWCOUNT = 0 then
        --�� �������
        rollback;
        p_ret:=3;
        return;
      end if;
    end loop;
--�������
p_ret:=0;
return;

end;

-- ��������� ������� �� ����� ���
function activate_task_by_rkc(p_eol_rkc in number, -- ID ��� (�� ������������)
                         p_act_cd in varchar2
                         ) return number is 
  l_cnt number;                            
begin
  -- �� ������ ��
  l_cnt:=0;
  for c in (select distinct t.fk_uk from exs.eolink t
             join BS.ADDR_TP tp on t.fk_objtp=tp.id and tp.cd='��'
             where t.parent_id=p_eol_rkc
    ) loop
    l_cnt:=l_cnt+activate_task_by_uk(p_act_cd, c.fk_uk);
  end loop;
  return l_cnt;
end;                              

-- ��������� ������� �� ��
function activate_task_by_uk(
                         p_act_cd in varchar2,
                         p_proc_uk in number -- ���������� ��
                         ) return number is 
begin
  -- �� ������� ����
  update exs.task t set t.state='INS'
         where exists (select * from bs.list i where i.cd=p_act_cd and t.fk_act=i.id)
         and t.fk_proc_uk=p_proc_uk
         and t.state not in ('INS', 'ACK');
  return sql%ROWCOUNT;       
end;                              

-- ��������� ������� �� ����
function activate_task_by_house(
                                 p_eol_house in number, -- Id ���� � Eolink
                                 p_act_cd in varchar2,
                                 p_proc_uk in number -- ���������� ��
                                 ) return number is
begin
  update exs.task t set t.state='INS'
         where exists (select * from bs.list i where i.cd=p_act_cd and t.fk_act=i.id)
         and t.fk_eolink=p_eol_house
         and t.fk_proc_uk=p_proc_uk
         and t.state not in ('INS', 'ACK');
  return sql%ROWCOUNT;       
end;                                 

procedure get_errs_menu(p_rfcur out ccur) is
begin
    open p_rfcur for 
    select 0 as id, '��� ���.������ ��� �������� � ���' as name from dual
    union all
    select 1 as id, '���� ���������� � ��� ��' as name from dual
    ;
end;

procedure show_errs(p_id in number, p_period in varchar2, p_rfcur out ccur) is
begin
  if p_id = 0 then
    -- ��� ��� ���.������ � eolink
    open p_rfcur for 
    select k.reu, count(*), max(k.lsk) as lsk, k.kul, s.name as street, 
     ltrim(k.nd,'0') as nd
     from scott.kart k join scott.v_lsk_tp tp on k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
     join scott.spul s on k.kul=s.id
     where k.psch not in (8,9) 
     and not exists (select * from exs.eolink e where k.lsk=e.lsk and e.status=1 -- �������� ��
     )
     group by k.reu, k.kul, s.name, 
     ltrim(k.nd,'0')
     order by k.reu, s.name, 
     ltrim(k.nd,'0');
  elsif p_id = 1 then  
    -- ��� ���� ���������� ��� ���������� � ��� ��
    open p_rfcur for 
     select k.reu, count(*) as cnt, max(k.lsk) as lsk, k.reu, k.kul, s.name as street, 
     ltrim(k.nd,'0') as nd from scott.kart k 
     join scott.spul s on k.kul=s.id
     join scott.v_lsk_tp tp on k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
     where k.psch not in (8,9) 
     and exists (
        select a.lsk from scott.a_charge2 a where a.lsk=k.lsk and p_period between a.mgFrom and a.mgTo and a.summa <> 0
        union all
        select a.lsk from scott.a_change a where a.mg=p_period and a.lsk=k.lsk and a.summa<>0 
     )
     and not exists (select * from exs.eolink e join exs.pdoc p on p.fk_eolink=e.id -- ��� ��� �� �� ������
                            where k.lsk=e.lsk and to_char(p.dt,'YYYYMM')=p_period
                             and e.status=1 -- �������� ��
                             and p.v=1 and p.status=1 -- ����������� � �������� ��
                            )
     group by k.reu, k.kul, s.name, 
     ltrim(k.nd,'0')
     order by k.reu, s.name, 
     ltrim(k.nd,'0');
    
  end if; 
end;

-- �������� ��� REU � �������� ���� (���� ��� ������� � ������ ��)
function change_reu_by_house(p_eol_house in number, -- Id ���� � Eolink
                             p_reu in exs.eolink.reu%type               
                             ) return number is
 l_cnt number;                             
begin
  -- ���
  update exs.eolink t set t.reu = p_reu, t.parent_id=(select e.id from exs.eolink e join bs.addr_tp tp on
         e.fk_objtp=tp.id and tp.cd='�����������' and e.reu=p_reu)
         where t.id=p_eol_house
         and exists (select * from bs.addr_tp tp where t.fk_objtp=tp.id and tp.cd='���');    
  l_cnt:=sql%rowcount;               
                                
  for c in (select * from exs.eolink t where t.parent_id=p_eol_house) loop
    -- �������
    update exs.eolink t set t.reu = p_reu where t.id=c.id
         and exists (select * from bs.addr_tp tp where t.fk_objtp=tp.id and tp.cd='�������');                             
    for c2 in (select * from exs.eolink t where t.parent_id=c.id) loop
      -- �������� 
      update exs.eolink t set t.reu = p_reu where t.id=c2.id
           and exists (select * from bs.addr_tp tp where t.fk_objtp=tp.id and tp.cd='��������');                             
    end loop;
  end loop;
  if l_cnt >  0 then
    -- �������
    return 0;                             
  else 
    -- ������, �� ���� ��������� 
    rollback;
    return 1;                             
  end if;

end;

end P_GIS;
/

