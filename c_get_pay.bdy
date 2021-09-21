create or replace package body scott.C_GET_PAY is

  function get_payment_bank_date return date is
    dtek_ date;
  begin
    --���������� ���� ������, ��������� �� �����
    select max(dtek)
      into dtek_
      from load_bank t
     where t.nkom = init.get_nkom;
    return dtek_;
  end;

  function check_payment_bank_date return number is
    cnt_ number;
  begin
    --���������, ���������� �� ��� ����� ����� �� ������ ����
    --���������� ���-�� �������
    select count(*)
      into cnt_
      from c_kwtp c
     where exists (select *
              from load_bank t
             where t.nkom = c.nkom
               and c.dat_ink = init.get_date
               and t.nkom = init.get_nkom);
    return cnt_;
  end;

  function check_payment_bank_nink(nink_ in c_kwtp.nink%type) return number is
    cnt_ number;
  begin
    --���������, ���������� �� ��� ����� ����� c ������ �������
    --���������� ���-�� �������
    select count(*)
      into cnt_
      from c_kwtp c
     where c.nkom = init.get_nkom
       and c.nink = nink_;
    return cnt_;
  end;

  function get_payment_bank_summa return number is
    summa_ number;
  begin
    --���������� ����� �������� ������, ��������� �� �����
    select sum(summa)
      into summa_
      from load_bank t
     where t.nkom = init.get_nkom
       and t.code = '01';
    return summa_;
  end;

  function get_payment_bank_summp return number is
    summap_ number;
  begin
    --���������� ����� ���� ������, ��������� �� �����
    select sum(summa)
      into summap_
      from load_bank t
     where t.nkom = init.get_nkom
       and t.code = '02';
    return summap_;
  end;

  procedure cur_payment_bank(id_            in number,
                             prep_refcursor in out rep_refcursor) is
  begin
    --������� ������ �� ��������� �������� �������� �����
    if id_ = 1 then
      open prep_refcursor for
        select t.*
          from c_comps t
         where t.nkom = init.get_nkom
           and t.fk_oper is null;
    elsif id_ = 2 then
      open prep_refcursor for
        select t.*
          from load_bank t
         where t.nkom = init.get_nkom
           and not exists (select * from kart k where k.lsk = t.lsk);
    
    elsif id_ = 3 then
      open prep_refcursor for
        select t.*
          from load_bank t
         where t.nkom = init.get_nkom
           and t.code not in ('01', '02');
    
      /* --���.05.03.12
      elsif id_=4 then
         open prep_refcursor for select t.* from load_bank t, params p
          where t.nkom=init.get_nkom and to_char(t.dtek,'YYYYMM')<>p.period;
        */
    elsif id_ = 5 then
      -- �������� �������� � ������� ��������
      open prep_refcursor for
        select t.*
          from load_bank t
           where t.dopl not in (select p.mg from period_reports p where p.id=21);
--         where t.nkom = init.get_nkom and not t.dopl between l_dopl_min and p.period;

--           and not exists --����� ���� -- ����� ���.26.10.2020
--         (select *
--                  from c_chargepay2 c, params p
--                 where p.period between c.mgFrom and c.mgTo
--                   and c.mg = t.dopl);
    end if;
  
  end;

  function recv_payment_bank(nink_ in c_kwtp.nink%type) return number is
    oper_        oper.oper%type;
    cnt_         number;
    distrib_pay_ number;
    l_nink       number;
  begin
    l_nink := nink_;
    --������ �� ������� ���������� (����, �����)
    select fk_oper into oper_ from c_comps c where c.nkom = init.get_nkom;
    if oper_ is null then
      --�� ������ ����������� ��� �������� ���������� ������ � ����������� c_comps
      return 1;
    end if;
  
    --������������ �� ������ �� �������� (������: 6-�����, 4-�����)
    select nvl(p.distrib_pay, 0) into distrib_pay_ from params p;
  
    select nvl(count(*), 0)
      into cnt_
      from load_bank t
     where t.nkom = init.get_nkom
       and not exists (select * from kart k where k.lsk = t.lsk);
    if cnt_ <> 0 then
      --���� �������� �������� ������� ����� �� ��������������� ������� ������ ����!
      return 2;
    end if;
  
    select nvl(count(*), 0)
      into cnt_
      from load_bank t
     where t.nkom = init.get_nkom
       and t.code not in ('01', '02');
    if cnt_ <> 0 then
      return 3;
      -- '���� �������� �������� ������������ ��� ��������!');
    end if;
  
    select nvl(count(*), 0)
      into cnt_
      from load_bank t
     where t.nkom = init.get_nkom
     and t.dopl not in (select p.mg from period_reports p where p.id=21);
/*       and not exists --����� ����
     (select *
              from c_chargepay2 c, params p
             where p.period between c.mgFrom and c.mgTo
               and c.mg = t.dopl);*/ --����� ���.26.10.20
    if cnt_ <> 0 then
      return 5;
      -- '���� �������� �������� ������������ ������ ������ !');
    end if;
  
    --��� 05.03.12 ���� �������� �� ���� �������, - ������� ���� ����������
  
    if nvl(l_nink, 0) <> 0 then
      --������ �������, ���� ������ ����� ����������
      delete from c_kwtp_mg c
       where c.nkom = init.get_nkom
         and c.nink = l_nink;
      delete from c_kwtp c
       where c.nkom = init.get_nkom
         and c.nink = l_nink;
      --�ommit - ����� deadlock � c_valid! ��� 02.12.12
      commit;
    end if;
  
    if l_nink = 0 then
      -- ���� �� ����� � ����������, �������� ���
      select nvl(nink, 0)
        into l_nink
        from c_comps t
       where t.nkom = init.get_nkom();
    end if;
  
    for c in (select * from load_bank t where t.nkom = init.get_nkom) loop
    
      --�� ��������� �������� �������� �� ������ ������ ��� ������� ���� ���������� ����������� ������� ���.02.09.14
      if c.dtek > init.get_date then
        -- '���� �������� �������� ������������ ���� ������!');
        return 4;
      end if;
      if c.code = '01' then
        if distrib_pay_ in (1,4,6) then
          get_payment(c.dtek,
                      c.lsk,
                      c.summa,
                      null,
                      oper_,
                      c.dopl,
                      distrib_pay_,
                      null,
                      0,
                      null,
                      null,
                      l_nink,
                      init.get_date());
        else
          -- ���� �� ���������� - ������ ������. ������ ������� - �� ���� ���������� ����� 23.10.2020
          Raise_application_error(-20000, '������ ��� ������������� �������� #1');       
        end if;
        
      elsif c.code = '02' then
        --���� �� ������������ �� ��������
        if distrib_pay_ = 1 then
          get_payment(c.dtek,
                      c.lsk,
                      null,
                      c.summa,
                      oper_,
                      c.dopl,
                      distrib_pay_,
                      null,
                      0,
                      null,
                      null,
                      l_nink,
                      init.get_date());
        else
          -- ���� �� ���������� - ������ ������. ������ ������� - �� ���� ���������� ����� 23.10.2020
          Raise_application_error(-20000, '������ ��� ������������� �������� #2');       
        end if;
      end if;
    end loop;
    --������ ���� � �������� �������
    delete from load_bank t where t.nkom = init.get_nkom;
    --���������� ����������, ������� �����������, ������� ����� ���.20.05.2019 - �� ��������� ����������, ��� ������������� � get_payment(l_nink)
    --make_inkass;
    update c_comps c
       set c.nink = l_nink + 1
     where c.nkom = init.get_nkom();
    commit;
    --�� ��������� �������
    return 0;
  end;

  procedure get_payment(dtek_      in c_kwtp.dtek%type,
                        lsk_       in c_kwtp.lsk%type,
                        summa_     in c_kwtp.summa%type,
                        penya_     in c_kwtp.penya%type,
                        oper_      in c_kwtp.oper%type,
                        dopl_      in c_kwtp.dopl%type,
                        p_pay_tp   in number,
                        nkvit1_    in c_kwtp.nkvit%type,
                        iscommit_  in number,
                        num_doc_   in c_kwtp.num_doc%type,
                        dat_doc_   in c_kwtp.dat_doc%type,
                        nink_      in number default 0,
                        dat_ink_   in date default null) is
    nkvit_  number;
    id_     number;
    dtplat_ c_kwtp.dtek%type;
    l_Java_deb_pen number;
  begin
    --����� ������
    l_Java_deb_pen := utils.get_int_param('JAVA_DEB_PEN');

    if lsk_ is null then
      Raise_application_error(-20000,
                              '������� ������ ������� ����!');
    end if;
  
    if dtek_ is null then
      --���� ������ � ������ ����� - ���������� �������
      --�� ������ ����� ��������� ������� � ������� <> ��������
      dtplat_ := init.get_date();
    else
      dtplat_ := dtek_;
    end if;
  
    if nvl(p_pay_tp, 0) = 3 then
      --�������
      nkvit_ := nkvit1_;
    else
      select nkvit
        into nkvit_
        from c_comps t
       where t.nkom = init.get_nkom();
    end if;
  
    if nvl(p_pay_tp, 0) in (0, 1, 2, 3, 4, 6, 7) then
      select c_kwtp_id.nextval into id_ from dual;
    end if;
  
    if nvl(p_pay_tp, 0) = 1 then
      --������������� ������
      insert into c_kwtp
        (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, id, iscorrect, num_doc, dat_doc)
      values
        (lpad(lsk_, 8, '0'), summa_, penya_, oper_, dopl_, nink_, dat_ink_, init.get_nkom(), dtplat_, nkvit_, sysdate, id_, p_pay_tp, num_doc_, dat_doc_);
    elsif nvl(p_pay_tp, 0) = 2 then
      --������������� ������
      insert into c_kwtp
        (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, id, iscorrect, num_doc, dat_doc)
      values
        (lpad(lsk_, 8, '0'), summa_, penya_, oper_, dopl_, nink_, dat_ink_, init.get_nkom(), dtplat_, nkvit_, sysdate, id_, p_pay_tp, num_doc_, dat_doc_);
    elsif nvl(p_pay_tp, 0) = 3 then
      --�������
      insert into c_kwtp
        (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, id, iscorrect, num_doc, dat_doc)
      values
        (lpad(lsk_, 8, '0'), summa_, penya_, oper_, dopl_, nink_, dat_ink_, init.get_nkom(), dtplat_, nkvit_, sysdate, id_, p_pay_tp, num_doc_, dat_doc_);
    elsif nvl(p_pay_tp, 0) in (5) then
      --����������� ����� - �� �������� ����� �������!
      null;
    elsif nvl(p_pay_tp, 0) in (4, 6, 7) then
      --������ ������, ������ ������ �����. ��������
      --����� ���� �� ���������� (������ � c_kwtp_mg)
      insert into c_kwtp
        (lsk, summa, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, id, iscorrect, num_doc, dat_doc)
      values
        (lpad(lsk_, 8, '0'), summa_, oper_, dopl_, nink_, dat_ink_, init.get_nkom(), dtplat_, nkvit_, sysdate, id_, p_pay_tp, num_doc_, dat_doc_);
    else
      -- ������� ������ (0)
      insert into c_kwtp
        (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, id, iscorrect, num_doc, dat_doc)
      values
        (lpad(lsk_, 8, '0'), summa_, penya_, oper_, (select period
             from params), nink_, dat_ink_, init.get_nkom(), dtplat_, nkvit_, sysdate, id_, p_pay_tp, num_doc_, dat_doc_);
    end if;
    --������������ ������ �� ��������
    get_payment_mg(id_,
                   nkvit_,
                   lsk_,
                   summa_,
                   penya_,
                   oper_,
                   dopl_,
                   nvl(p_pay_tp, 0),
                   init.get_nkom(),
                   dtplat_,
                   nink_,
                   dat_ink_,
                   l_Java_deb_pen);
  
    update c_comps c
       set c.nkvit = nkvit_ + 1
     where c.nkom = init.get_nkom();
    if nvl(iscommit_, 0) = 1 then
      commit;
    end if;
  end;

  procedure get_payment_mg(id_      in c_kwtp.id%type,
                           nkvit_   in c_kwtp.nkvit%type,
                           lsk_     in c_kwtp.lsk%type,
                           summa_   in c_kwtp.summa%type,
                           penya_   in c_kwtp.penya%type,
                           oper_    in c_kwtp.oper%type,
                           dopl_    in c_kwtp.dopl%type,
                           p_pay_tp in number,
                           nkom_    in c_kwtp.nkom%type,
                           dtek_    in c_kwtp.dtek%type,
                           nink_    in c_kwtp.nink%type,
                           dat_ink_ in date,
                           is_Java_deb_pen in number) is
  
    t_lsk      tab_lsk;
    summa_pay_ number;
    summa_pn_  number;
  
    --����������� �� ��������� �����
    saldo_ number;
    --����������� �� ����
    saldo_pen_ number;
    --��������� �� ��������� �����
    saldo_cr_ number;
    --��������� �� ����
    saldo_pen_cr_ number;
  
    l_proc_summa number;
    l_summa      number;
    l_penya      number;
    saldo_amnt_  number;
  
    l_kwtp_id number;
    l_klsk number;
    l_pay_tp  number;
    l_lsk_old kart.lsk%type;
    l_dummy number;
    --������ ������������� �� c_penya (����� �������)
    cursor c is
      select t.lsk, t.mg1 as mg, nvl(t.summa, 0) as summa, nvl(t.penya, 0) as penya
        from c_penya t
       where t.lsk = lpad(lsk_, 8, '0')
       order by t.mg1;
    rec_ c%rowtype;
  
    --������ ������������� �� c_penya, �� ��������� � ��������������� ��� ������ 
    cursor c2 is
      select t.lsk, t.mg1 as mg, nvl(t.summa, 0) as summa, nvl(t.penya, 0) as penya
        from c_penya t, temp_lsk s
       where t.lsk = s.lsk
       order by t.mg1, t.lsk;
  
    --������ ������������� �� c_chargepay (������ �������������)
    cursor r is
      select *
        from (select c.lsk, c.mg, sum(decode(type, 1, -1 * summa, summa)) as summa
                 from c_chargepay2 c, params p
                where p.period between c.mgFrom and c.mgTo
                  and c.lsk = lpad(lsk_, 8, '0')
                  and c.type in (0, 1)
                  and c.mg <= dopl_
                group by c.lsk, c.mg --������� ������ ������� ������ (������� � ����� ����� � ������)
                order by c.mg desc, c.lsk);
    rec_r_ r%rowtype;
  
    --������ ��� ������������� ������ ������, ����� ���� (��� 6 ���� ��������)
    cursor c3(p_tp in number) is
      select t.lsk, t.mg1 as mg,case
               when p_tp = 0 then
                nvl(t.summa, 0)
               else
                0
             end as summa,case
               when p_tp = 1 then
                nvl(t.penya, 0)
               else
                0
             end as penya
        from c_penya t, params p
       where t.lsk = lpad(lsk_, 8, '0')
         and t.mg1 < p.period --����� ��������
       order by t.mg1;
  
    --������ ��� ������������� ������ ���. ����������, ����� ������, ����� ���� (��� 7 ���� ��������)
    cursor c4(p_tp in number) is
      select t.lsk, t.mg1 as mg,case
               when p_tp = 0 then
                nvl(t.summa, 0)
               else
                0
             end as summa,case
               when p_tp = 1 then
                nvl(t.penya, 0)
               else
                0
             end as penya
        from c_penya t, params p
       where t.lsk = lpad(lsk_, 8, '0')
         and t.mg1 < p.period --����� ��������
       order by t.mg1 desc;
  
  begin
    --��� ������
    l_pay_tp := p_pay_tp;
    --���� ������, ����
    summa_pay_ := nvl(summa_, 0);
    summa_pn_  := nvl(penya_, 0);
    --�����, ���� ������� �����
    if summa_pay_ = 0 and summa_pn_ = 0 then
      return;
    end if;
  
    if nvl(l_pay_tp, 0) in (0, 2, 4, 6, 7) then
      --����������� ������ � ������ �������, ������������ ��� ������������� �������� �� ��������
      --���������� ��� ������� - ����� �����, ���� ��� ���������...��� 16.04.12
      --cnt_:=c_charges.gen_charges(lsk_, lsk_, null, 0, 0);
      --�������� ��� ������� � ���� �� ������� ����, ����� ��������� ��������� ������� �������
      --��� 16.04.12
      --c_cpenya.gen_charge_pay(lsk_, 0); --�����, ��������� � gen_penya 28.12.2015
    
      -- ��������! ����� �����! ����� �������� ������ ������������� �������������! 
      --���������� ��� ������, ���� ������, �� ���� �������� ������������!
      for c in (select nvl(h.fk_typespay, l_pay_tp) as pay_tp
        from kart k
        join c_houses h
          on k.house_id = h.id
         and k.lsk = lpad(lsk_, 8, '0')) loop
         if c.pay_tp=5 and nvl(l_pay_tp, 0) <>5 then
           --  ����� �� 5 ��� �������������, ������� ��������� �� C_KWTP (����� ������ �����)
           delete from c_kwtp t where t.id=id_;
         end if;
         l_pay_tp:=c.pay_tp;
      end loop;
    
      c_cpenya.gen_penya(lsk_         => lpad(lsk_, 8, '0'),
                         dat_         => dtek_,
                         islastmonth_ => 0,
                         p_commit     => 0);
    
      --  c_cpenya.gen_penya(lpad(lsk_,8,'0'), 0, 0);
    elsif nvl(l_pay_tp, 0) = 5 then
      --����������� ����� (�������� � �������������� (������) ����� 
      --���������� ���� � ���� �� ������� �.�.
      --t_lsk-���������, - �������� �������� � ��������� table(t_lsk), �������� ���������� 
      delete from temp_lsk;
      t_lsk := p_houses.get_other_lsk(lpad(lsk_, 8, '0'));
          l_klsk := utils.GET_K_LSK_ID_BY_LSK(lsk_);
          if is_Java_deb_pen=1 then  
            -- ��������, ���������� ���� �� ������, �� ���� �� �����
               l_dummy:=p_java.gen(p_tp        => 1,
                 p_house_id  => null,
                 p_vvod_id   => null,
                 p_usl_id    => null,
                 p_klsk_id   => l_klsk,
                 p_debug_lvl => 0,
                 p_gen_dt    => dtek_,
                 p_stop      => 0);
          end if;                     

      if t_lsk.count > 0 then
        for i in t_lsk.first .. t_lsk.last loop
          insert into temp_lsk
            (lsk) --t_lsk-���������, - �������� �������� � ��������� table(t_lsk), �������� ������ temp_lsk (���� �������)
          values
            (t_lsk(i).lsk);
          if is_Java_deb_pen=0 then  
            -- ��������, ���������� ���� �� �������  
            c_cpenya.gen_penya(lsk_         => t_lsk(i).lsk,
                               dat_         => dtek_,
                               islastmonth_ => 0,
                               p_commit     => 0);
          end if;                     
        end loop;
      end if;
    
    end if;
  
    saldo_        := 0;
    saldo_pen_    := 0;
    saldo_cr_     := 0;
    saldo_pen_cr_ := 0;
    saldo_amnt_   := 0;
  
    if nvl(l_pay_tp, 0) = 0 then
      --������� �����  --������������� �� ������ �������� (������ �.�.) � �����
      open c;
      loop
        fetch c
          into rec_;
        exit when c%notfound or summa_pay_ = 0;
        if rec_.summa + saldo_ <= 0 then
          --���� ���������, ��������� �� ����. ������.
          saldo_ := rec_.summa + saldo_;
        elsif summa_pay_ <= rec_.summa + saldo_ then
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          values
            (rec_.lsk, summa_pay_, summa_pn_, oper_, rec_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, rec_.summa);
          summa_pay_ := 0;
          summa_pn_  := 0; --���� ����������� ������ ��������
        else
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          values
            (rec_.lsk, rec_.summa + saldo_, summa_pn_, oper_, rec_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, rec_.summa);
          summa_pay_ := summa_pay_ - (rec_.summa + saldo_);
          saldo_     := 0;
          summa_pn_  := 0; --���� ����������� ������ ��������
        end if;
      
      end loop;
      close c;
    
      --���� ������ �� ������������, ������ � �� ������� ������ (������ �������� �����!!!)
      if summa_pay_ <> 0 or summa_pn_ <> 0 then
        insert into c_kwtp_mg
          (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          select k.lsk, summa_pay_, summa_pn_, oper_, p.period, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, 0
            from kart k, params p
           where k.c_lsk_id =
                 (select max(c_lsk_id)
                    from kart t
                   where t.lsk = lpad(lsk_, 8, '0'))
             and rownum = 1;
      end if;
      
    elsif nvl(l_pay_tp, 0) = 2 then
      --������������� �� ������ �������� � �����
      --�����? ��� � �� �����... ������������ � ��� � ������� ����� (��� 16.04.12) - ������ ������ �����!!!
      open r;
      loop
        fetch r
          into rec_r_;
        exit when r%notfound or summa_pay_ = 0;
        if rec_r_.summa + saldo_ <= 0 then
          --���� ���������, ��������� �� ����. ������.
          saldo_ := rec_r_.summa + saldo_;
        elsif summa_pay_ <= rec_r_.summa + saldo_ then
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          values
            (rec_r_.lsk, summa_pay_, summa_pn_, oper_, rec_r_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, rec_.summa);
          summa_pay_ := 0;
          summa_pn_  := 0; --���� ����������� ������ ��������
        else
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          values
            (rec_r_.lsk, rec_r_.summa + saldo_, summa_pn_, oper_, rec_r_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, rec_.summa);
          summa_pay_ := summa_pay_ - (rec_r_.summa + saldo_);
          saldo_     := 0;
          summa_pn_  := 0; --���� ����������� ������ ��������
        end if;
      
      end loop;
      close r;
    
      --���� ������ �� ������������, ������ � �� ������� ������ (������ �������� �����!!!)
      if summa_pay_ <> 0 or summa_pn_ <> 0 then
        insert into c_kwtp_mg
          (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          select k.lsk, summa_pay_, summa_pn_, oper_, p.period, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, 0
            from kart k, params p
           where k.c_lsk_id =
                 (select max(c_lsk_id)
                    from kart t
                   where t.lsk = lpad(lsk_, 8, '0'))
             and rownum = 1;
      end if;
      
    elsif nvl(l_pay_tp, 0) = 4 then
      --������ �����  --������������� �� ������ �������� (������ �.�.) � ����� (�����)
      --� ������������� �� ������ � ����
      --��� 29.08.13
      open c;
      loop
        fetch c
          into rec_;
        exit when c%notfound or summa_pay_ = 0;
        l_summa := 0;
        l_penya := 0;
      
        -- ������������� � ������ ��������� ��������. �������
        saldo_     := rec_.summa + saldo_cr_;
        saldo_pen_ := rec_.penya + saldo_pen_cr_;
      
        --���� ���������, ��������� �� ����. ������.
        if saldo_ < 0 then
          saldo_cr_ := saldo_;
        else
          saldo_cr_ := 0;
        end if;
        if saldo_pen_ < 0 then
          saldo_pen_cr_ := saldo_pen_;
        else
          saldo_pen_cr_ := 0;
        end if;
        saldo_amnt_ := saldo_ + saldo_pen_;
      
        if saldo_ > 0 or saldo_pen_ > 0 then
          -- ���� �������������, ������������
          if saldo_ > 0 and saldo_pen_ > 0 then
            -- ���� �������� ���� � ���� ����
            l_proc_summa := saldo_ / saldo_amnt_;
            if summa_pay_ <= saldo_amnt_ then
              -- ����� ������ ������ ����������� �����
              l_summa := round(l_proc_summa * summa_pay_, 2);
              l_penya := summa_pay_ - l_summa;
            else
              -- ����� ������ ������ ����������� �����
              l_summa := round(l_proc_summa * saldo_amnt_, 2);
              l_penya := saldo_amnt_ - l_summa;
            end if;
          elsif saldo_ > 0 and saldo_pen_ <= 0 then
            -- ���� ������ �������� ���� � ��������� ����
            if summa_pay_ <= saldo_ then
              -- ����� ������ ������ �����
              l_summa := summa_pay_;
              l_penya := 0;
            else
              -- ����� ������ ������ ����������� �����
              l_summa := saldo_;
              l_penya := 0;
            end if;
          elsif saldo_ <= 0 and saldo_pen_ > 0 then
            -- ���� ��������� �� ����� � ���� ����
            if summa_pay_ <= saldo_pen_ then
              -- ����� ������ ������ �����
              l_summa := 0;
              l_penya := summa_pay_;
            else
              -- ����� ������ ������ ����������� �����
              l_summa := 0;
              l_penya := saldo_pen_;
            end if;
          end if;
        end if;
      
        if l_summa != 0 or l_penya != 0 then
          -- �������
          summa_pay_ := summa_pay_ - (l_summa + l_penya);
          -- ������������ ��������, ���������
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          values
            (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, 0);
        end if;
      end loop;
      close c;
    
      --���� ������ �� ������������, ������ � �� ������� ������, �� �������� ����
      if summa_pay_ <> 0 then
        insert into c_kwtp_mg
          (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          select k.lsk, summa_pay_, 0, oper_, p.period, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, 0
            from kart k, params p
           where k.lsk = lpad(lsk_, 8, '0')
             and rownum = 1;
      end if;
    elsif nvl(l_pay_tp, 0) = 5 then
      --����������� �����  --������������� �� ������ �������� � ����� �� ��������� � ��������������� ��
      --� ������������� �� ������ � ���� (�����.)
      --��� 01.01.2016
    
      l_lsk_old := 'xxx';
      delete from temp_kwtp_mg;
      open c2;
      loop
        fetch c2
          into rec_;
        exit when c2%notfound or summa_pay_ = 0;
        if l_lsk_old <> rec_.lsk then
          --���� ������ ���.����, �� ������ ��������� � ��������
          saldo_ := 0;
        end if;
        if rec_.summa + rec_.penya + saldo_ <= 0 then
          --���� ���������, ��������� �� ����. ������.
          saldo_ := rec_.summa + rec_.penya + saldo_;
        elsif summa_pay_ <= rec_.summa + rec_.penya + saldo_ then
          l_proc_summa := rec_.summa / (rec_.summa + rec_.penya);
          l_summa      := round(l_proc_summa * summa_pay_, 2);
          l_penya      := summa_pay_ - l_summa;
        
          insert into temp_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts)
          values
            (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate );
          summa_pay_ := 0;
        else
          l_proc_summa := rec_.summa / (rec_.summa + rec_.penya);
          --����� ������� � ������� �������� ������������ ��������������� ����� � ����
          l_summa := rec_.summa + round(saldo_ * l_proc_summa, 2);
          l_penya := rec_.penya +
                     (saldo_ - round(saldo_ * l_proc_summa, 2));
          insert into temp_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts)
          values
            (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate);
          summa_pay_ := summa_pay_ - (l_summa + l_penya);
          saldo_     := 0;
        end if;
      
      end loop;
      close c2;
    
      --���� ������ �� ������������, ������ � �� ������� ������ � ��������� �� ����������
      if summa_pay_ <> 0 then
        for c in (select t.lsk, t.summa / (sum(t.summa) over(partition by 0)) as proc
                    from (select a.lsk, sum(a.summa) as summa
                             from c_charge a, temp_lsk s
                            where a.lsk = s.lsk
                              and a.type = 1
                            group by a.lsk
                           having nvl(sum(a.summa), 0) <> 0) t) loop
        
          insert into temp_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts)
            select k.lsk, round(summa_pay_ * c.proc, 2), null, oper_, p.period, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate
              from kart k, params p
             where k.lsk = c.lsk;
        
          summa_pay_ := summa_pay_ - round(summa_pay_ * c.proc, 2);
        end loop;
      end if;
    
      --���� ������� �������, �� ������ �� ����� �.�.
      if nvl(summa_pay_, 0) <> 0 then
        update temp_kwtp_mg t
           set t.summa = nvl(t.summa, 0) + summa_pay_
         where rowid = (select max(rowid)
                          from temp_kwtp_mg k
                         where k.summa >= summa_pay_);
         if sql%rowcount = 0 then
           -- �� ���� ��������� �������, ������ �� lsk_ ���.24.03.20
          insert into temp_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts)
            select k.lsk, summa_pay_, null, oper_, p.period, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate
              from kart k, params p
             where k.lsk = lsk_;
         end if;                
                         
      end if;
    
      --� ������ ��������� ��������� �������, � ������
      for c in (select distinct t.lsk from temp_kwtp_mg t) loop
        select c_kwtp_id.nextval into l_kwtp_id from dual;
        insert into c_kwtp
          (id, lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, iscorrect)
          select l_kwtp_id, lsk, sum(summa) as summa, sum(penya) as penya, oper_, dopl_, 0, dat_ink_, init.get_nkom(), dtek_, nkvit_, sysdate, l_pay_tp
            from temp_kwtp_mg t
           where t.lsk = c.lsk
           group by t.lsk;
      
        if sql%rowcount = 0 then
          Raise_application_error(-20000,
                                  '����������� ����� �� ������, ��������� ������� ����������� �� ���.�����!');
        end if;
      
        insert into c_kwtp_mg
          (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id)
          select t.lsk, t.summa, t.penya, t.oper, t.dopl, t.nink, dat_ink_, t.nkom, t.dtek, t.nkvit, t.ts, l_kwtp_id
            from temp_kwtp_mg t
           where t.lsk = c.lsk;
      
      end loop;
          
    elsif nvl(l_pay_tp, 0) = 6 then
      --������ �����  --�������������: ������� �����, ����� ���� (���.)
      --��� 21.01.2016
      --������������� ������
      open c3(0);
      loop
        fetch c3
          into rec_;
        exit when c3%notfound or summa_pay_ = 0;
        if rec_.summa + rec_.penya + saldo_ <= 0 then
          --���� ���������, ��������� �� ����. ������.
          saldo_ := rec_.summa + rec_.penya + saldo_;
        elsif summa_pay_ <= rec_.summa + rec_.penya + saldo_ then
          l_proc_summa := rec_.summa / (rec_.summa + rec_.penya);
          l_summa      := round(l_proc_summa * summa_pay_, 2);
          l_penya      := summa_pay_ - l_summa;
        
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          values
            (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, rec_.summa);
          summa_pay_ := 0;
        else
          l_proc_summa := rec_.summa / (rec_.summa + rec_.penya);
          --����� ������� � ������� �������� ������������ ��������������� ����� � ����
          l_summa := rec_.summa + round(saldo_ * l_proc_summa, 2);
          l_penya := rec_.penya +
                     (saldo_ - round(saldo_ * l_proc_summa, 2));
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          values
            (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, rec_.summa);
          summa_pay_ := summa_pay_ - (l_summa + l_penya);
          saldo_     := 0;
        end if;
      
      end loop;
      close c3;
    
      --������������� ����
      open c3(1);
      loop
        fetch c3
          into rec_;
        exit when c3%notfound or summa_pay_ = 0;
        if rec_.summa + rec_.penya + saldo_ <= 0 then
          --���� ���������, ��������� �� ����. ������.
          saldo_ := rec_.summa + rec_.penya + saldo_;
        elsif summa_pay_ <= rec_.summa + rec_.penya + saldo_ then
          l_proc_summa := rec_.summa / (rec_.summa + rec_.penya);
          l_summa      := round(l_proc_summa * summa_pay_, 2);
          l_penya      := summa_pay_ - l_summa;
        
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          values
            (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, rec_.summa);
          summa_pay_ := 0;
        else
          l_proc_summa := rec_.summa / (rec_.summa + rec_.penya);
          --����� ������� � ������� �������� ������������ ��������������� ����� � ����
          l_summa := rec_.summa + round(saldo_ * l_proc_summa, 2);
          l_penya := rec_.penya +
                     (saldo_ - round(saldo_ * l_proc_summa, 2));
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          values
            (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, rec_.summa);
          summa_pay_ := summa_pay_ - (l_summa + l_penya);
          saldo_     := 0;
        end if;
      
      end loop;
      close c3;
    
      --���� ������ �� ������������, ������ � �� ������� ������
      if summa_pay_ <> 0 then
        insert into c_kwtp_mg
          (lsk, summa, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          select k.lsk, summa_pay_, oper_, p.period, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, 0
            from kart k, params p
           where k.lsk = lpad(lsk_, 8, '0')
             and rownum = 1;
      
      end if;
    
    elsif nvl(l_pay_tp, 0) = 7 then
      --������ �����  --�������������: ������� ������� ����������, ����� �����, ����� ����,- � �������� �������
      --��� 16.01.2017
      open c4(0);
      loop
        fetch c4
          into rec_;
        exit when c4%notfound or summa_pay_ = 0;
        if rec_.summa + rec_.penya + saldo_ <= 0 then
          --���� ���������, ��������� �� ����. ������.
          saldo_ := rec_.summa + rec_.penya + saldo_;
        elsif summa_pay_ <= rec_.summa + rec_.penya + saldo_ then
          l_proc_summa := rec_.summa / (rec_.summa + rec_.penya);
          l_summa      := round(l_proc_summa * summa_pay_, 2);
          l_penya      := summa_pay_ - l_summa;
        
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          values
            (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, rec_.summa);
          summa_pay_ := 0;
        else
          l_proc_summa := rec_.summa / (rec_.summa + rec_.penya);
          --����� ������� � ������� �������� ������������ ��������������� ����� � ����
          l_summa := rec_.summa + round(saldo_ * l_proc_summa, 2);
          l_penya := rec_.penya +
                     (saldo_ - round(saldo_ * l_proc_summa, 2));
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          values
            (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, rec_.summa);
          summa_pay_ := summa_pay_ - (l_summa + l_penya);
          saldo_     := 0;
        end if;
      
      end loop;
      close c4;
    
      --������������� ����
      open c3(1);
      loop
        fetch c3
          into rec_;
        exit when c3%notfound or summa_pay_ = 0;
        if rec_.summa + rec_.penya + saldo_ <= 0 then
          --���� ���������, ��������� �� ����. ������.
          saldo_ := rec_.summa + rec_.penya + saldo_;
        elsif summa_pay_ <= rec_.summa + rec_.penya + saldo_ then
          l_proc_summa := rec_.summa / (rec_.summa + rec_.penya);
          l_summa      := round(l_proc_summa * summa_pay_, 2);
          l_penya      := summa_pay_ - l_summa;
        
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          values
            (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, rec_.summa);
          summa_pay_ := 0;
        else
          l_proc_summa := rec_.summa / (rec_.summa + rec_.penya);
          --����� ������� � ������� �������� ������������ ��������������� ����� � ����
          l_summa := rec_.summa + round(saldo_ * l_proc_summa, 2);
          l_penya := rec_.penya +
                     (saldo_ - round(saldo_ * l_proc_summa, 2));
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          values
            (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, rec_.summa);
          summa_pay_ := summa_pay_ - (l_summa + l_penya);
          saldo_     := 0;
        end if;
      
      end loop;
      close c3;
    
      --���� ������ �� ������������, ������ � �� ������� ������
      if summa_pay_ <> 0 then
        insert into c_kwtp_mg
          (lsk, summa, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
          select k.lsk, summa_pay_, oper_, p.period, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, 0
            from kart k, params p
           where k.lsk = lpad(lsk_, 8, '0')
             and rownum = 1;
      
      end if;
    else
      --������������� ������
      insert into c_kwtp_mg
        (lsk, summa, penya, oper, dopl, nink, dat_ink, nkom, dtek, nkvit, ts, c_kwtp_id, debt)
      values
        (lpad(lsk_, 8, '0'), summa_pay_, summa_pn_, oper_, dopl_, nink_, dat_ink_, nkom_, dtek_, nkvit_, sysdate, id_, 0);
    
    end if;
  
  end;

  function get_tails return number is
    summa_ number;
  begin
    -- ������� � ����� �� �������� ����������
    select nvl(sum(nvl(summa, 0) + nvl(penya, 0)), 0)
      into summa_
      from c_kwtp t
     where t.nkom = init.get_nkom()
       and nvl(nink, 0) = 0
    /*and t.dtek between init.g_dt_cur_start and init.g_dt_cur_end*/
    ; --���� ����� ���� ����� ��� ������
    return summa_;
  end;

  function dst_money_cur_month(summa_ number)
     return number
   is
  maxmg_ c_kwtp_temp_dolg.mg%type;
  begin
      if sysdate > gdt(15,10,2019) then
    Raise_application_error(-20000, '�� ������������! �������� ������������!');
  end if;
  --������������� ������� ���������� ����� (����� �� ������ �����)
  select trim(max(t.mg)) into maxmg_ from c_kwtp_temp_dolg t;
  if maxmg_ is not null then
    --������������ �� ��������� ����� ������
    update c_kwtp_temp_dolg t set t.summa=nvl(t.summa,0)+summa_, t.itog=nvl(t.itog,0)+summa_
      where t.mg=maxmg_;

    update c_kwtp_temp t set t.summa=nvl(t.summa,0)+summa_, t.itog=nvl(t.itog,0)+summa_
      where exists (select * from oper o where o.oper=t.oper and nvl(o.iscounter,0) =0);
    return 0;
  else
    return 1;
  end if;

  end;
   
  function dst_money_cur_month2(summa_ number) return number is
    maxmg_     c_kwtp_temp_dolg.mg%type;
    l_summa    number;
    l_pay      number;
    l_last_lsk kart.lsk%type;
  begin
      if sysdate > gdt(15,10,2019) then
    Raise_application_error(-20000, '�� ������������! �������� ������������!');
  end if;
    --������������� ������� ���������� ����� (����� �� ������ �����)
    select trim(max(t.mg)) into maxmg_ from c_kwtp_temp_dolg t;
    l_summa := summa_;
    if maxmg_ is not null then
      --������������ �� ��������� ����� ������
      for c in (select t.lsk, t.summa, sum(t.summa) over(partition by mg) as itg_summa
                  from c_kwtp_temp_dolg t
                 where t.mg = maxmg_) loop
        l_last_lsk := c.lsk;
        if l_summa > 0 and c.itg_summa > 0 then
          l_pay := round(c.summa / c.itg_summa * summa_, 2);
          if l_pay > l_summa then
            -- ����������
            l_pay := l_summa;
          end if;
          l_summa := l_summa - l_pay;
          for c2 in (select rowid as rd from c_kwtp_temp_dolg t where t.lsk = c.lsk
             and t.mg = maxmg_) loop
            update c_kwtp_temp_dolg t
               set t.summa = nvl(t.summa, 0) + l_pay, t.itog = nvl(t.itog, 0) +
                             l_pay
             where t.rowid=c2.rd;
          exit;   
          end loop; 
        end if;
      end loop;
      -- �������
      if l_summa > 0 then
        for c2 in (select rowid as rd from c_kwtp_temp_dolg t where t.lsk = l_last_lsk
           and t.mg = maxmg_) loop
          update c_kwtp_temp_dolg t
             set t.summa = nvl(t.summa, 0) + l_summa, t.itog = nvl(t.itog, 0) +
                           l_summa
           where t.rowid=c2.rd;
        exit;   
        end loop; 
      end if;
      return 0;
    else
      return 1;
    end if;
  end;

  function get_money_nal(lsk_ in kart.lsk%type) return c_kwtp.id%type is
    nkvit_           number;
    cnt_             number;
    id_              c_kwtp.id%type;
    c_kwtp_summa_    number;
    c_kwtp_mg_summa_ number;
    summa_mg_        number;
  begin
    --���� ������, ��������
    select nvl(count(*), 0)
      into cnt_
      from (select count(*) as cnt, t.oper
               from c_kwtp_temp t
              group by t.oper)
     where cnt > 1;
    if cnt_ > 1 then
      Raise_application_error(-20001,
                              '��������! ����������� ��� ��������, ������!');
    end if;
  
    --����� ���������
    select nkvit into nkvit_ from c_comps t where t.nkom = init.get_nkom();
    update c_comps c
       set c.nkvit = nkvit_ + 1
     where c.nkom = init.get_nkom();
    select c_kwtp_id.nextval into id_ from dual;
  
    insert into c_kwtp
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, id, iscorrect)
      select lpad(lsk_, 8, '0'), sum(t.summa), sum(t.penya), null, null, 0, init.get_nkom(), init.get_date(), nkvit_, null, sysdate, id_, 3
        from c_kwtp_temp t
       where nvl(t.summa, 0) <> 0
          or nvl(t.penya, 0) <> 0;
  
    select nvl(sum(t.summa), 0) + nvl(sum(t.penya), 0)
      into c_kwtp_summa_
      from c_kwtp_temp t
     where nvl(t.summa, 0) <> 0
        or nvl(t.penya, 0) <> 0;
  
    summa_mg_        := 0;
    c_kwtp_mg_summa_ := 0;
    for c in (select t.*, nvl(o.iscounter, 0) as iscounter, trim(u.counter) as counter
                from c_kwtp_temp t, oper o, usl u
               where t.oper = o.oper
                 and o.fk_usl_chk = u.usl(+)) loop
      --�������� 01 - ����, ����������
      insert into c_kwtp_mg
        (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, c_kwtp_id)
        select lpad(lsk_, 8, '0'), t.summa, t.penya, c.oper, t.mg, 0, init.get_nkom(), init.get_date(), nkvit_, null, sysdate, id_
          from c_kwtp_temp_dolg t
         where (nvl(t.summa, 0) <> 0 or nvl(t.penya, 0) <> 0);
    
      if SQL%ROWCOUNT = 0 then
        rollback;
        logger.log_(null,
                    'C_GET_PAY.GET_MONEY_NAL, ������ ��� ����� ������! ��������� ����!');
        Raise_application_error(-20000,
                                '������ ��� ����� ������! ��������� ����!' ||
                                c_kwtp_summa_ || ' ' || c_kwtp_mg_summa_);
      end if;
      select nvl(sum(t.summa), 0) + nvl(sum(t.penya), 0)
        into summa_mg_
        from c_kwtp_temp_dolg t
       where nvl(t.summa, 0) <> 0
          or nvl(t.penya, 0) <> 0;
      c_kwtp_mg_summa_ := c_kwtp_mg_summa_ + summa_mg_;
      exit;
    end loop;
    if nvl(c_kwtp_summa_, 0) <> nvl(c_kwtp_mg_summa_, 0) then
      rollback;
      logger.log_(null,
                  'C_GET_PAY.GET_MONEY_NAL, ������ ��� ����� ������! ��������� ����!');
      Raise_application_error(-20000,
                              '������ ��� ����� ������! ��������� ����!' ||
                              c_kwtp_summa_ || ' ' || c_kwtp_mg_summa_);
    end if;
    return id_;
  end;

  -- ����� ������ ������� - �� ���� ���.������ �������� � ��� 
  -- ���.26.06.2019
  procedure get_money_nal2(prep_refcursor in out rep_refcursor) is
    l_nkvit          number;
    l_cnt            number;
    --l_oper            oper.oper%type;
    l_c_kwtp_id      c_kwtp.id%type;
    --c_kwtp_summa_    number;
    --c_kwtp_mg_summa_ number;
    --summa_mg_        number;
    tab              tab_id;
  begin
    tab:=tab_id();
    select nvl(count(*), 0)
      into l_cnt
      from (select count(*) as cnt, t.oper
               from c_kwtp_temp t
              group by t.oper)
     where cnt > 1;
    if l_cnt > 1 then
      Raise_application_error(-20001,
                              '��������! ����������� ��� ��������, ������!');
    end if;
  
   /* select sum(nvl(t.summa, 0) + nvl(t.penya, 0)), max(t.oper) 
      into c_kwtp_summa_, l_oper
      from c_kwtp_temp t
     where nvl(t.summa, 0) <> 0
        or nvl(t.penya, 0) <> 0;*/
  
    for r in (select sum(nvl(t.summa, 0) + nvl(t.penya, 0)) as summa, max(t.oper) as oper from c_kwtp_temp t) loop
      for c in (select t.lsk, nvl(sum(t.summa), 0) as summa, nvl(sum(t.penya),
                            0) as penya
                  from c_kwtp_temp_dolg t
                 where nvl(t.summa, 0) <> 0
                    or nvl(t.penya, 0) <> 0
                 group by t.lsk) loop
        select c_kwtp_id.nextval into l_c_kwtp_id from dual;
        --����� ���������
        --LOCK TABLE c_comps IN EXCLUSIVE MODE;  ������ �� ������ ���� ����������, �� �� ���� - ����� ���� ���������� ������ �������������
        select nkvit
          into l_nkvit
          from c_comps t
         where t.nkom = init.get_nkom();
        update c_comps c
           set c.nkvit = l_nkvit + 1
         where c.nkom = init.get_nkom();
      
        insert into c_kwtp
          (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, id, iscorrect)
        values
          (c.lsk, c.summa, c.penya, null, null, 0, init.get_nkom(), init.get_date(), l_nkvit, null, sysdate, l_c_kwtp_id, 3);
        tab.extend;
        tab(tab.last) := l_c_kwtp_id;
        for c2 in (select t.lsk, t.summa, t.penya, t.mg
                     from c_kwtp_temp_dolg t 
                    where t.lsk=c.lsk and (nvl(t.summa, 0) <> 0
                       or nvl(t.penya, 0) <> 0)) loop
          insert into c_kwtp_mg
            (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, c_kwtp_id)
            select c2.lsk, c2.summa, c2.penya, r.oper, c2.mg, 0, init.get_nkom(), init.get_date(), l_nkvit, null, sysdate, l_c_kwtp_id
              from dual t;
        end loop;
      end loop;
    end loop;
    
    open prep_refcursor for
      select t.c_kwtp_id, t.lsk, substr(tp.name, 1, 3) as lsk_tp, nvl(t.summa,
                  0) +
              nvl(t.penya,
                  0) as summ_itg, substr(t.dopl,5,2)||'.'||substr(t.dopl,1,4) as dopl, o.naim
        from c_kwtp_mg t
        join kart k
          on t.lsk = k.lsk
        join v_lsk_tp tp
          on k.fk_tp = tp.id
        join oper o
          on t.oper = o.oper
       where t.c_kwtp_id in (select * from table(tab))
       order by tp.npp, t.lsk, t.dopl, o.naim;
  end;
  
  
  --����������
  procedure make_inkass is
    nink_ number;
  begin
  
    -- ���.17.06.2019 - ������� �������, ������� ������� ��� ����������. ������, ���� ��������� Rollback 
    -- ����� ������� c_kwtp_mg, �� � Java ������ ��� �������������. ���� ������ ���, ��������� ��� ���� �������!
    delete from kwtp_day t
     where t.nkom = init.get_nkom()
       and not exists
     (select * from c_kwtp_mg m where m.id = t.kwtp_id);
    /*  for c in (
      select *
        from (select * from C_KWTP_MG t where t.nkom = scott.init.get_nkom) a
        full join (select t.kwtp_id, sum(summa) as summa
                     from kwtp_day t
                    where t.nkom = scott.init.get_nkom
                    group by t.kwtp_id) b
          on a.id = b.kwtp_id
         and a.nkom = scott.init.get_nkom
       where nvl(a.summa, 0) + nvl(a.penya, 0) <> nvl(b.summa, 0))
       loop
         Raise_application_error(-20000, '��������� ������������� ������ ����� �����������!');
       end loop;
    */
  
    select nvl(nink, 0)
      into nink_
      from c_comps t
     where t.nkom = init.get_nkom();
  
    update kwtp_day t
       set t.nink = nink_, t.dat_ink = init.get_date()
     where exists (select *
              from c_kwtp_mg c
             where c.nkom = init.get_nkom()
               and nvl(c.nink, 0) = 0
               and t.kwtp_id = c.id
            /*and c.dtek between init.g_dt_cur_start and init.g_dt_cur_end*/
            );
  
    update c_kwtp c
       set c.nink = nink_, c.dat_ink = init.get_date()
     where c.nkom = init.get_nkom()
       and nvl(c.nink, 0) = 0
    /*and c.dtek between init.g_dt_cur_start and init.g_dt_cur_end*/
    ;
  
    update c_kwtp_mg c
       set c.nink = nink_, c.dat_ink = init.get_date()
     where c.nkom = init.get_nkom()
       and nvl(c.nink, 0) = 0
    /*and c.dtek between init.g_dt_cur_start and init.g_dt_cur_end*/
    ;
  
    update c_comps c set c.nink = nink_ + 1 where c.nkom = init.get_nkom();
    --��� ������� (�� - �� ������� �������)
    -- commit;
  end;

  procedure init_c_kwtp_temp_dolg(p_lsk in kart.lsk%type) is
    l_lsk  c_kwtp.lsk%type;
    a      number;
    l_klsk number;
    l_dummy number;
    l_Java_deb_pen number;
  begin
    l_lsk  := lpad(p_lsk, 8, '0');
    l_klsk := utils.GET_K_LSK_ID_BY_LSK(l_lsk);
    l_Java_deb_pen := utils.get_int_param('JAVA_DEB_PEN');
    if l_Java_deb_pen=1 then 
    -- ����� Java ����������
    l_dummy:=p_java.gen(p_tp        => 0,
             p_house_id  => null,
             p_vvod_id   => null,
             p_usl_id    => null,
             p_klsk_id   => l_klsk,
             p_debug_lvl => 0,
             p_gen_dt    => init.get_date,
             p_stop      => 0);
    -- ����� Java ������ ������������� + ���������� ����
    l_dummy:=p_java.gen(p_tp        => 1,
             p_house_id  => null,
             p_vvod_id   => null,
             p_usl_id    => null,
             p_klsk_id   => l_klsk,
             p_debug_lvl => 0,
             p_gen_dt    => init.get_date,
             p_stop      => 0);
   end if;                         
    delete from c_kwtp_temp_dolg;
    -- ��������� ��� ���.����� ��������������� � ������ klsk
    for c in (select k.lsk, substr(u.name, 1, 3) as lsk_tp, 
                     p_java.http_req(p_url => '/getKartShortNames',
                               p_url2 => k.lsk||'/'||p.period,
                               p_server_url => init.g_java_server_url,
                               tp => 'GET') as usl_name_short,      
                     --k.usl_name_short, 
                     k.psch, u.name
                from kart k, u_list u, params p
               where k.k_lsk_id = l_klsk
                 and k.fk_tp = u.id) loop
      if l_Java_deb_pen=0 then 
        if c.psch not in (8, 9) then 
          -- ���������� �� �������� ���.������ 
          a := c_charges.gen_charges(lsk_      => c.lsk,
                                     lsk_end_  => c.lsk,
                                     house_id_ => null,
                                     p_vvod    => null,
                                     iscommit_ => 0,
                                     sendmsg_  => null);
        end if;
      end if;
      if l_Java_deb_pen=0 then 
        -- ������� �������� �� �.�.
        c_cpenya.gen_charge_pay(c.lsk, 0);
        -- ���� �����������!
        c_cpenya.gen_penya(c.lsk, 0, 0);
      end if;  

    
      insert into c_kwtp_temp_dolg
        (lsk, lsk_tp, usl_name_short, mg, charge, payment, summa, penya, summa2, penya2, sal, itog)
        select c.lsk, c.lsk_tp, c.usl_name_short, a.mg, nvl(b.summa, 0) as charge, nvl(f.summa,
                    0) as payment, case when nvl(e.summa, --���� ����������� ����� ���, ������ ����� � ����������� ���.04.07.2019
                    0) > 0 then d.summa else 0 end as summa
                    , nvl(d.penya, 0) as penya, case when nvl(e.summa, --���� ����������� ����� ���, ������ ����� � ����������� ���.04.07.2019
                    0) > 0 then d.summa else 0 end as summa2
                    , nvl(d.penya, 0) as penya2, nvl(e.summa,
                    0) as sal, d.summa + nvl(d.penya, 0) as itog
          from long_table a
               join params p on 1=1
               left join (select mg, sum(summa) as summa
                   from scott.c_chargepay2 t, params p
                  where p.period between t.mgFrom and t.mgTo
                    and lsk = c.lsk
                    and type = 0
                  group by mg) b on a.mg = b.mg
               left join (select mg, sum(summa) as summa
                   from scott.c_chargepay2 t, params p
                  where p.period between t.mgFrom and t.mgTo
                    and lsk = c.lsk
                    and type = 1
                  group by mg) f on a.mg = f.mg
               left join (select t.mg1,case
                          when t.penya >= 0 then
                           t.penya
                          else
                           0
                        end as penya,case
                          when t.summa >= 0 then
                           t.summa
                          else
                           0
                        end as summa
                   from c_penya t
                  where lsk = c.lsk) d on a.mg = d.mg1
               join (select sum(summa) as summa
                   from c_penya
                  where lsk = c.lsk) e on 1=1--���������� ����
         where ((nvl(b.summa, 0) = 0 and p.period = a.mg) or
               nvl(b.summa, 0) <> 0 or nvl(d.summa, 0) <> 0 or
               nvl(f.summa, 0) <> 0);
    end loop;
  end;

  procedure remove_pay(id_ in c_kwtp.id%type) is
  begin
    --�������� ������������ ����� �� ����� �������
    delete from c_kwtp_mg t where t.c_kwtp_id = id_;
    delete from c_kwtp t where t.id = id_;
    --  ��� �������
    --  commit;
  end;

  procedure remove_inkass(nkom_ in c_kwtp.nkom%type,
                          nink_ in c_kwtp.nink%type) is
  begin
    --�������� ������������ ����������...
    --�������� ������� - � ������?))
    delete from c_kwtp_mg t
     where t.nkom = nkom_
       and nvl(t.nink, 0) = nvl(nink_, 0);
    delete from c_kwtp t
     where t.nkom = nkom_
       and nvl(t.nink, 0) = nvl(nink_, 0);
    delete from kwtp_day t
     where t.nkom = nkom_
       and nvl(t.nink, 0) = nvl(nink_, 0);
    commit;
  end;

  function reverse_pay(p_kwtp_id in c_kwtp.id%type) return number is
    l_id  number;
    l_id2 number;
    l_dt  date;
    --������� � ����.
    l_nkom  c_kwtp.nkom%type;
    l_nkvit c_kwtp.nkvit%type;
    l_flag number;
    l_kwtp_id number;
  begin
    --�������� ����� (�������� ��������� �����, � ���.�������,
    --� �������� ��� ����, ������ � �������� ������)
    l_dt   := init.get_date;
    l_nkom := init.get_nkom;
    select scott.c_kwtp_id.nextval into l_id from dual;
    select nkvit into l_nkvit from c_comps t where t.nkom = l_nkom;
    update c_comps c
       set c.nkvit = l_nkvit + 1
     where c.nkom = init.get_nkom();
  
    l_flag:=0;
    begin
      select t.id into l_kwtp_id from c_kwtp t where t.id=p_kwtp_id;
    exception when no_data_found then
      -- ������ �� � ������� �������
      l_flag:=1;
    end;
    
    if l_flag = 1 then 
      insert into c_kwtp
        (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, id, iscorrect, num_doc, dat_doc)
        select t.lsk, -1 * nvl(t.summa, 0) as summa, -1 * nvl(t.penya, 0) as penya, t.oper, t.dopl, 0 as nink, l_nkom as nkom, l_dt as dtek, l_nkvit, l_id, t.iscorrect, t.num_doc, t.dat_doc
          from a_kwtp t
         where t.id = p_kwtp_id;
    else
      insert into c_kwtp
        (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, id, iscorrect, num_doc, dat_doc)
        select t.lsk, -1 * nvl(t.summa, 0) as summa, -1 * nvl(t.penya, 0) as penya, t.oper, t.dopl, 0 as nink, l_nkom as nkom, l_dt as dtek, l_nkvit, l_id, t.iscorrect, t.num_doc, t.dat_doc
          from c_kwtp t
         where t.id = p_kwtp_id;
    end if;   
    if SQL%ROWCOUNT = 0 then
      --�� �������
      return 1;
    end if;
  
    if l_flag = 1 then 
      for c in (select t.lsk, -1 * nvl(summa, 0) as summa, -1 * nvl(penya, 0) as penya, t.oper, t.dopl, null as nink, l_nkom as nkom, l_dt as dtek, l_nkvit as nkvit, t.cnt_sch, t.cnt_sch0, t.id
                  from a_kwtp_mg t
                 where t.c_kwtp_id = p_kwtp_id) loop
        insert into c_kwtp_mg
          (lsk, summa, penya, oper, dopl, nkom, dtek, nkvit, c_kwtp_id, cnt_sch, cnt_sch0, is_dist, nink)
        values
          (c.lsk, c.summa, c.penya, c.oper, c.dopl, c.nkom, c.dtek, c.nkvit, l_id, c.cnt_sch, c.cnt_sch0, 1, --is_dist=1 - ������ ��� ������������ (���� �������� �� �������������� � ��������)
           0)
        returning id into l_id2;
        if SQL%ROWCOUNT = 0 then
          --�� �������
          return 2;
        end if;
      
        insert into kwtp_day
          (summa, lsk, oper, dopl, nkom, nink, dat_ink, priznak, usl, org, fk_distr, sum_distr, kwtp_id, dtek)
          select -1 * nvl(t.summa, 0) as summa, t.lsk, t.oper, t.dopl, l_nkom as nkom, 0 as nink, null as dat_ink, t.priznak, t.usl, t.org, 13 as fk_distr, --12 ��� (�������� �����)
                 t.sum_distr, l_id2 as kwtp_id, init.get_date
            from a_kwtp_day t
           where t.kwtp_id = c.id;
        if SQL%ROWCOUNT = 0 then
          --�� �������
          return 3;
        end if;
      end loop;
    else
      for c in (select t.lsk, -1 * nvl(summa, 0) as summa, -1 * nvl(penya, 0) as penya, t.oper, t.dopl, null as nink, l_nkom as nkom, l_dt as dtek, l_nkvit as nkvit, t.cnt_sch, t.cnt_sch0, t.id
                  from c_kwtp_mg t
                 where t.c_kwtp_id = p_kwtp_id) loop
        insert into c_kwtp_mg
          (lsk, summa, penya, oper, dopl, nkom, dtek, nkvit, c_kwtp_id, cnt_sch, cnt_sch0, is_dist, nink)
        values
          (c.lsk, c.summa, c.penya, c.oper, c.dopl, c.nkom, c.dtek, c.nkvit, l_id, c.cnt_sch, c.cnt_sch0, 1, --is_dist=1 - ������ ��� ������������ (���� �������� �� �������������� � ��������)
           0)
        returning id into l_id2;
        if SQL%ROWCOUNT = 0 then
          --�� �������
          return 2;
        end if;
      
        insert into kwtp_day
          (summa, lsk, oper, dopl, nkom, nink, dat_ink, priznak, usl, org, fk_distr, sum_distr, kwtp_id, dtek)
          select -1 * nvl(t.summa, 0) as summa, t.lsk, t.oper, t.dopl, l_nkom as nkom, 0 as nink, null as dat_ink, t.priznak, t.usl, t.org, 13 as fk_distr, --12 ��� (�������� �����)
                 t.sum_distr, l_id2 as kwtp_id, init.get_date
            from kwtp_day t
           where t.kwtp_id = c.id;
        if SQL%ROWCOUNT = 0 then
          --�� �������
          return 3;
        end if;
      end loop;
    end if;  
  
    --�������
    return 0;
  
  end;

  /** ������� ��������� �� ������ � ���.
     �������������� �� �������� �� insert C_KWTP_MG
  **/
  /*procedure create_notification_gis(rec c_kwtp_mg%rowtype) is 
  begin
    -- ������ + ����? (� ���� ���������� �� � ����� �� � ����������� ������ ���������������)
    insert into exs.notif(fk_pdoc, summa, dt, fk_kwtp_mg)
    select p.id, nvl(rec.summa,0)+nvl(rec.penya,0) as summa, 
           rec.dtek, rec.id from exs.pdoc p join exs.eolink e on
           p.fk_eolink=e.id and e.lsk=rec.lsk and to_char(p.dt,'YYYYMM')=rec.dopl -- �� �������
           and nvl(rec.summa,0)+nvl(rec.penya,0)<>0
           and p.status=1 and p.v=1;
  
  end;  
  
  \** ������� ��������� �� ������ � ��� �� ���� �������������� �������� �������� �������
   **\
  procedure create_notification_gis_all is 
  begin
    for c in (select * from scott.c_kwtp_mg t 
        where not exists (select * from exs.notif n where n.fk_kwtp_mg=t.id)) loop
      create_notification_gis(c);
    end loop;    
  
  end;  
  */

  -- �������� ����������� �� ����������� ����
  procedure get_receipt_detail(p_kwtp_id in number, -- id ������� ���. �� �������
                               p_rfcur   out ccur -- ���.���������
                               ) is
  begin
    open p_rfcur for
      select m.dopl,rpad(decode(t.priznak,
                         0,
                         '����', -- ������������ �������
                         case
                           when m.dopl = pm.period or u.usl in ('033', '034') then
                            p.name
                           else
                            '����� �� ���'
                         end),
                  18,
                  ' ') || ' ' ||
             decode(t.priznak,
                    0,
                    null,
                    substr(t.dopl, 5, 2) || '/' || substr(t.dopl, 1, 4)) as name, sum(t.summa) as summa, -- �����
             1 as dep -- �����
        from scott.kwtp_day t
        join scott.c_kwtp_mg m
          on m.id = t.kwtp_id
         and m.c_kwtp_id = p_kwtp_id
        join scott.usl_receipt u
          on t.usl = u.usl -- ������ � ������
        join scott.usl_receipt p
          on u.parent_id = p.id -- ��������� ������ �����
        join params pm
          on 1 = 1
       group by m.dopl, rpad(decode(t.priznak,
                             0,
                             '����', -- ������������ �������
                             case
                               when m.dopl = pm.period or u.usl in ('033', '034') then
                                p.name
                               else
                                '����� �� ���'
                             end),
                      18,
                      ' ') || ' ' ||
                 decode(t.priznak,
                        0,
                        null,
                        substr(t.dopl, 5, 2) || '/' ||
                        substr(t.dopl, 1, 4)) --, decode(t.priznak, 0, 1000, p.npp)
       order by 1, 2;
  end;
end C_GET_PAY;
/

