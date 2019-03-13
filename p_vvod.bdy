create or replace package body scott.p_vvod is

  procedure gen_dist(p_klsk           in c_vvod.fk_k_lsk%type,
                     p_dist_tp        in c_vvod.dist_tp%type,
                     p_usl            in c_vvod.usl%type,
                     p_use_sch        in out c_vvod.use_sch%type,
                     p_old_use_sch    in c_vvod.use_sch%type,
                     p_kub_nrm_fact   in out c_vvod.kub_nrm_fact%type,
                     p_kub_sch_fact   in out c_vvod.kub_sch_fact%type,
                     p_kub_ar_fact    in out c_vvod.kub_ar_fact%type,
                     p_kub_ar         in out c_vvod.kub_ar%type,
                     p_opl_ar         in out c_vvod.opl_ar%type,
                     p_kub_sch        in out c_vvod.kub_sch%type,
                     p_sch_cnt        in out c_vvod.sch_cnt%type,
                     p_sch_kpr        in out c_vvod.sch_kpr%type,
                     p_kpr            in out c_vvod.kpr%type,
                     p_cnt_lsk        in out c_vvod.cnt_lsk%type,
                     p_kub_norm       in out c_vvod.kub_norm%type,
                     p_kub_fact       in out c_vvod.kub_fact%type,
                     p_kub_man        in out c_vvod.kub_man%type,
                     p_kub            in c_vvod.kub%type,
                     p_edt_norm       in c_vvod.edt_norm%type,
                     p_kub_dist       out c_vvod.kub%type,
                     p_id             in c_vvod.id%type,
                     p_opl_add        in out c_vvod.opl_add%type,
                     p_house_id       in c_vvod.house_id%type,
                     p_old_kub        in c_vvod.kub%type,
                     p_limit_proc     in c_vvod.limit_proc%type,
                     p_old_limit_proc in c_vvod.limit_proc%type,
                     p_gen_part_kpr   in number, --������������� �� ���� ����������� (������ �� ��������) (� ����������)
                     p_wo_limit       in c_vvod.wo_limit%type) is
    type rec_sch is record(
      kub_sch number,
      cnt     number,
      kpr     number);
    type rec_norm is record(
      kub_norm number,
      cnt_lsk  number,
      kpr      number
      );

    type rec_sch_tsj is record(
      kub_sch number,
      cnt     number,
      kpr     number,
      opl     number);
      
    type rec_norm_tsj is record(
      kub_norm number,
      cnt_lsk  number,
      kpr      number,
      opl      number
      );

    type rec_ is record(
      kub_sch number,
      cnt     number,
      kpr_sch number);

    type rec_cnt is record(
      vol     number,
      vol_add number);

    type rec_norm2 is record(
      cnt number,
      kpr number);

    type rec_ar_sch is record( --����������
      kub number,
      --cnt number,
      opl number);

    rec_sch_     rec_sch;
    rec_cnt_     rec_cnt;
    rec_norm_    rec_norm;
    rec_norm_tsj_    rec_norm_tsj;
    rec_sch_tsj_     rec_sch_tsj;
    rec_ar_sch_  rec_ar_sch;
    kub_rec_     rec_;
    kpr_rec_     rec_norm2;
    koeff_       number;
    fk_calc_tp_  number;
    sptarn_      number;
    use_sch_     number; --����������, ������� ����� 15.10.12
    otop_        number;
    tp_          number;
    dist_tp_     number;
    all_kub_     number;
    all_opl_     number;
    all_kpr_     number;
    fk_usl_chld_ usl.usl%type;
    l_proc       number;
    l_dist_vl    number;
    l_nbalans    number;
    l_vol        number; --��������� ���������� ��� �����.��������
    l_lsk_round  nabor.lsk%type; --��������� ���������� ��� ���������� ���������
    l_vol_round  number; --��������� ���������� ��� ���������� ���������
    l_flag       number;
    l_limit_vol  number; --���������� ����� ��� �� ���������������� (�����)

    l_area_prop  number; --������� ������ ��������� ����
    l_rate       number; --�������� �� ���
    l_limit_area number; --���������� ����� ��� �� 1 �2

    l_opl_man   number; -- ������� �� ������ ������������ �� 1 ���., ��� ������� �����������
    l_opl_liter number; --���-�� ������ �� ����2 �� �������, ��� ������� �����������
    l_usl_cd    usl.cd%type;
    l_cnt       number;
    --���������� ��� ����������
    l_for_round number;
    l_time date;
    l_odn_nrm number; --����������� �� ��� (��� �������� ����������)
    l_kub_fact_upnorm number; -- ����� ����� ��������� �� ���
    cursor cur1 is --������ ��� ������� ��������
      select k.lsk,
             case
               when nvl(all_kpr_, 0) <> 0 then
                round(nvl((p_kub_dist - all_kub_) / all_kpr_, 0) *
                      (nvl(d.kpr2, 0) +
                       decode(use_sch_, 1, nvl(f.kpr2, 0), 0)),
                      3)
               else
                null
             end as dist_vl,

             f.vol as vol_add, --����� �� ��������
             d.vol as vol, --����� �� ���������
             nvl(f.vol, 0) + nvl(d.vol, 0) as lsk_vl --����� �����
        from kart k, nabor n, c_charge_prep f, c_charge_prep d
       where k.lsk = n.lsk
         and n.lsk = f.lsk(+)
         and n.usl = f.usl(+)
         and f.tp(+) = 6 --���� �� �������� ���� ��� ���
         and f.sch(+) = 1
         and n.lsk = d.lsk(+)
         and n.usl = d.usl(+)
         and d.tp(+) = 6 --���� �� ��������� ���� ��� ���
         and d.sch(+) = 0
         and n.fk_vvod = p_id
         and n.usl = p_usl
         and k.psch not in (8, 9)
         and nvl(f.vol, 0) + nvl(d.vol, 0) > 0; --���, ��� ������ ���� ������ > 0

    cursor cur2 is --������ ��� ������� ��������, ��� ���������
      select k.lsk,
             round(nvl((p_kub_dist - all_kub_) / all_kpr_, 0) *
                   nvl(d.kpr2, 0),
                   3) as dist_vl,
             0 as vol_add, --����� �� �������� (������ NULL - ������ ��������)
             d.vol as vol, --����� �� ���������
             nvl(d.vol, 0) as lsk_vl --����� �����
        from kart k, nabor n, c_charge_prep d
       where k.lsk = n.lsk
         and n.lsk = d.lsk(+)
         and n.usl = d.usl(+)
         and d.tp(+) = 6 --���� �� ��������� ���� ��� ���
         and d.sch(+) = 0
         and n.fk_vvod = p_id
         and n.usl = p_usl
         and k.psch not in (8, 9)
         and nvl(d.vol, 0) > 0 --���, ��� ������ ���� ������ > 0
         and not exists (select *
                from c_charge_prep e
               where n.lsk = e.lsk
                 and n.usl = e.usl
                 and e.tp = 7 --��� ��� ������� �������� � ���.�������
                 and e.sch = 1);

    cursor cur3 is --������ ��� ������� ��������, ���� �� �����������, ���� ����� ��� �� ��������
      select k.lsk,
             round(nvl((p_kub_dist - all_kub_) / all_kpr_, 0) *
                   (nvl(d.kpr2, 0) + decode(use_sch_, 1, nvl(f.kpr2, 0), 0)),
                   3) as dist_vl,

             f.vol as vol_add, --����� �� ��������
             d.vol as vol, --����� �� ���������
             nvl(f.vol, 0) + nvl(d.vol, 0) as lsk_vl --����� �����
        from kart k, nabor n, c_charge_prep f, c_charge_prep d
       where k.lsk = n.lsk
         and n.lsk = f.lsk(+)
         and n.usl = f.usl(+)
         and f.tp(+) = 6 --���� �� �������� ���� ��� ���
         and f.sch(+) = 1
         and n.lsk = d.lsk(+)
         and n.usl = d.usl(+)
         and d.tp(+) = 6 --���� �� ��������� ���� ��� ���
         and d.sch(+) = 0
         and n.fk_vvod = p_id
         and n.usl = p_usl
         and k.psch not in (8, 9)
         and nvl(f.vol, 0) + nvl(d.vol, 0) > 0 --���, ��� ������ ���� ������ > 0
         and (k.status = 9 or exists
              (select *
                 from c_charge_prep e
                where k.lsk = e.lsk
                  and e.usl = p_usl
                  and e.tp = 6 --���� ��� ���
                  and e.kpr2 <> 0));
    rec cur1%rowtype;
    -- ������������� �� Java?
    l_Java_Charge number;
  begin

    --������������� ���� �� ����� � ���������� ��������� �������� 307 ������������� �� 06.05.11
    --(�������� ���������� � 3) ����� �� http://www.consultant.ru/online/base/?req=doc;base=LAW;n=114247;p=7
    --������������ ������� C_VVOD � �������� � ������ �������� - ������, ��� ��� ��� ��������

    --�����������:
    --������ � ������� C_VVOD �������� ����, ����� �������,
    --��������� �������� (�������� ����������) ������ ���� ����������� � ��������� ����� PARENT_ID
    --(���� �� �����������)
    --TO DO: ������ ����������� �� ���������� ��������� ������� ������ ��������� �� ���� (��������� ����������)
    --�������, ������� � 01.07.2013


    l_Java_Charge := utils.get_int_param('JAVA_CHARGE');
    if l_Java_Charge=1 then 
      -- ����� Java �������������
      p_java.gen(p_tp        => 2,
                 p_house_id  => null,
                 p_vvod_id   => p_id,
                 p_reu_id    => null,
                 p_usl_id    => null,
                 p_klsk_id   => null,
                 p_debug_lvl => 0,
                 p_gen_dt    => init.get_date,
                 p_stop      => 0);
      return;
    end if;


    l_time:=sysdate;
    p_kub_dist := p_kub;

    --��� ������������� �� �����
    dist_tp_ := nvl(p_dist_tp, 0);

    --���������� ���� �������, �����������, ��� ������������� � �������������
    --������ � ��� �.�, ������� ����������� �����
    if p_gen_part_kpr = 1 then
      c_kart.set_part_kpr_vvod(p_id);
    end if;

    --��� ������� ������
    begin
      select nvl(u.fk_calc_tp, 0), u.fk_usl_chld, u.cd
        into fk_calc_tp_, fk_usl_chld_, l_usl_cd
        from usl u
       where u.usl = p_usl;
    exception
      when no_data_found then
        Raise_application_error(-20000, '���� id='||p_id||'�� �������� ���������� ��� ������!');
    end;

    select nvl(u.sptarn, 0) into sptarn_ from usl u where u.usl = p_usl;

    --������������ �� �������� ��� ������������� ������ �.�., �.�. (1-��, 0 - ���)
    use_sch_ := nvl(p_use_sch, 0);

    select case
             when substr(p.period, 5, 2) between to_char(p.dt_otop1, 'MM') and
                  to_char(p.dt_otop2, 'MM') then
              1
             else
              0
           end
      into otop_
      from params p;

    if fk_calc_tp_ in (3, 17, 4, 18, 31, 38, 40) then
      if fk_calc_tp_ in (3, 17, 38) then
        tp_ := 0; --�.�.
      elsif fk_calc_tp_ in (4, 18, 40) then
        tp_ := 1; --�.�.
      elsif fk_calc_tp_ in (31) then
        tp_ := 2; --��.��.
      end if;

      --���.��
      --����� ����� �.�./�.�. �� ���������, ���-�� ���������, ���-�� �����, �������
      ---------------------------------------------------
      --------���� ���������� ��� ������� ���------------

      if nvl(p_kub, 0) <> 0.001 then
        --p_kub <> 0.001
        --������� ������
        select nvl(sum(e.vol), 0) as kub_sch,
               nvl(count(k.lsk), 0) as cnt,
               nvl(sum(e.kpr2), 0) as kpr_sch
--               nvl(sum(k.opl), 0) as opl
          into rec_sch_
          from kart k, nabor n, c_charge_prep e
         where k.lsk = n.lsk
           and k.lsk = e.lsk
           and n.fk_vvod = p_id
           and n.usl = e.usl
           and n.usl = p_usl
           and k.psch not in (8, 9)
           and e.sch = 1 --��������
           and e.tp = 6 --���� ��� ���
           and k.status not in (9) /*��� �����������*/
           /*and exists (select *
                  from nabor r
                 where r.lsk = n.lsk --��� ��� ���� ������ ���
                   and r.usl = fk_usl_chld_)*/;

        p_kub_sch := rec_sch_.kub_sch;
        p_sch_cnt := rec_sch_.cnt;
        p_sch_kpr := rec_sch_.kpr;

        --���-�� �����, ����� �� ���������, ���-�� �������, �������
        select nvl(sum(e.vol), 0) as kub_norm,
               nvl(count(k.lsk), 0) as cnt,
               nvl(sum(e.kpr2), 0) as kpr
--               nvl(sum(k.opl), 0) as opl
          into rec_norm_
          from kart k, nabor n, c_charge_prep e
         where k.lsk = n.lsk
           and k.lsk = e.lsk
           and n.fk_vvod = p_id
           and n.usl = e.usl
           and n.usl = p_usl
           and k.psch not in (8, 9)
           and e.sch = 0 --������������
           and e.tp = 6 --���� ��� ���
           and k.status not in (9) /*��� �����������*/
           /*and exists (select *
                  from nabor r
                 where r.lsk = n.lsk --��� ��� ���� ������ ���
                   and r.usl = fk_usl_chld_)*/;

        p_kub_norm := rec_norm_.kub_norm;
        p_cnt_lsk  := rec_norm_.cnt_lsk;
        p_kpr      := rec_norm_.kpr;

        --����� ���-�� ������.
        if use_sch_ = 1 then
          all_kpr_ := rec_norm_.kpr + rec_sch_.kpr;
        else
          all_kpr_ := rec_norm_.kpr;
        end if;
        --���-�� �����, ���-�� �������, ������� �� ����������� (��� ����.354)
        --��.����(����������)

        select nvl(sum(e.vol), 0) as ar_kub_sch,
               --nvl(count(k.lsk), 0) as ar_cnt,
               nvl(sum(k.opl), 0) as ar_opl
          into rec_ar_sch_
          from kart k, nabor n, c_charge_prep e
         where k.lsk = n.lsk
           and k.lsk = e.lsk
           and n.fk_vvod = p_id
           and n.usl = e.usl
           and n.usl = p_usl
           and k.psch not in (8, 9)
           and e.sch = 1 --��������
           and e.tp = 6 --���� ��� ���
           and k.status in (9) /*����������*/
           /*and exists (select *
                  from nabor r
                 where r.lsk = n.lsk --��� ��� ���� ������ ���
                   and r.usl = fk_usl_chld_)*/;

        --����� �����������
        p_kub_ar := rec_ar_sch_.kub;

        --������� �����������
        p_opl_ar := rec_ar_sch_.opl;

        --��������� ������ �� �����
        all_kub_ := rec_sch_.kub_sch + rec_norm_.kub_norm + rec_ar_sch_.kub;

        --��������� ������� �� �����
        if dist_tp_ <> 3 and use_sch_ = 1 then
          --���� � �.�. ��������
          select nvl(sum(k.opl), 0)
            into all_opl_
            from kart k, nabor n
           where k.lsk = n.lsk
             and n.fk_vvod = p_id
             and n.usl = p_usl
             and k.psch not in (8, 9)
             /*and exists (select *
                    from nabor r
                   where r.lsk = n.lsk --��� ��� ���� ������ ���
                     and r.usl = fk_usl_chld_)*/;

        elsif dist_tp_ <> 3 and use_sch_ = 0 then
          --���� ����� �� ���� � ���� ������� ��������
          select nvl(sum(k.opl), 0)
            into all_opl_
            from kart k, nabor n
           where k.lsk = n.lsk
             and n.fk_vvod = p_id
             and n.usl = p_usl
             and k.psch not in (8, 9)
             and not exists (select *
                    from c_charge_prep e
                   where n.lsk = e.lsk
                     and n.usl = e.usl
                     and e.tp = 7 --������� �������� � ���.�������
                     and e.sch = 1)
             /*and exists (select *
                    from nabor r
                   where r.lsk = n.lsk --��� ��� ���� ������ ���
                     and r.usl = fk_usl_chld_)*/;
        elsif dist_tp_ = 3 then
          --���� ��� �����.=3 �� ���� ���������, ���� ������ ���-�� ���� ��������
          select nvl(sum(k.opl), 0)
            into all_opl_
            from kart k, nabor n
           where k.lsk = n.lsk
             and n.fk_vvod = p_id
             and n.usl = p_usl
             and k.psch not in (8, 9)
             and (k.status = 9 or exists
                  (select *
                     from c_charge_prep e
                    where k.lsk = e.lsk
                      and e.usl = p_usl
                      and e.tp = 6 --���� ��� ���
                      and e.kpr2 <> 0))
             /*and exists (select *
                    from nabor r
                   where r.lsk = n.lsk --��� ��� ���� ������ ���
                     and r.usl = fk_usl_chld_)*/;
        end if;

        p_opl_add := all_opl_;

        ---------------------------------------------------
        --------����������� �� ���-------------------------
        if nvl(p_wo_limit, 0) = 0 then
          l_limit_vol := 0; -- �� ������������ � dist_tp_ in (1, 2, 3)
          begin
            if all_opl_ > 0 and all_kpr_ > 0 then
              --������� > 0 � ���-�� ������ > 0

              --����������� ���, ��� ������ �� ������� (������. �� �����)
              if tp_ in (0, 1) then
                --�.�. � �.�.
                l_opl_man   := round(all_opl_ / all_kpr_);
                l_opl_liter := opl_liter(l_opl_man);
                l_limit_vol := l_opl_liter / 1000 * all_opl_;
                --����� �� �������
                l_limit_area := l_opl_liter / 1000;
                if p_dist_tp <> 2 then --����� ������, ��� ��� ������ ��� (���� ������ ����)
                  l_odn_nrm:=l_opl_liter;
                else
                  l_odn_nrm:=null;
                end if;
              elsif tp_ = 2 then
                --��.��.
                --�� ��.��. - �� ����������
                --��� ��� ����� = ������� ������ ��������� * 2.7 ���.
                begin
                  --������� ���.����., ��������, ����� �� �������
                  select x.n1, 2.7, nvl(round(x.n1 * 2.7, 4), 0)
                    into l_area_prop, l_rate, l_limit_vol
                    from t_objxpar x, v_house_pars u, c_houses h
                   where x.fk_list = u.id
                     and x.fk_k_lsk = h.k_lsk_id
                     and h.id = p_house_id
                     and u.cd = 'area_general_property'
                     and not exists
                   (select *
                            from t_objxpar x, v_house_pars u, c_houses h
                           where x.fk_list = u.id
                             and x.fk_k_lsk = h.k_lsk_id
                             and h.id = p_house_id
                             and u.cd = 'exist_lift'
                             and nvl(x.n1, 0) = 1

                          );
                  l_odn_nrm:=2.7;

                  /*            and not exists  --�����, ��� ��� ���� ����� ����, ��� ���� ����� � ������� ����������! (���)
                  (select * from kart k, nabor n, usl u where k.house_id=h.id
                      and k.lsk=n.lsk
                      and n.usl=u.usl
                      and u.cd in ('����')
                      and c_kart.get_is_chrg(u.sptarn, n.koeff, n.norm)=1
                      );*/
                exception
                  when no_data_found then
                    l_limit_vol := 0;
                end;

                if l_limit_vol = 0 then
                  --������ ��� � ������
                  begin
                    --������� ���.����., ��������, ����� �� �������
                    select x.n1, 4.1, nvl(round(x.n1 * 4.1, 4), 0)
                      into l_area_prop, l_rate, l_limit_vol
                      from t_objxpar x, v_house_pars u, c_houses h
                     where x.fk_list = u.id
                       and x.fk_k_lsk = h.k_lsk_id
                       and h.id = p_house_id
                       and u.cd = 'area_general_property'
                       and exists
                     (select *
                              from t_objxpar x, v_house_pars u, c_houses h
                             where x.fk_list = u.id
                               and x.fk_k_lsk = h.k_lsk_id
                               and h.id = p_house_id
                               and u.cd = 'exist_lift'
                               and nvl(x.n1, 0) = 1

                            );
                    /*                and exists
                    (select * from kart k, nabor n, usl u where k.house_id=h.id
                        and k.lsk=n.lsk
                        and n.usl=u.usl
                        and u.cd in ('����')
                        and c_kart.get_is_chrg(u.sptarn, n.koeff, n.norm)=1
                        );*/
                  exception
                    when no_data_found then
                      l_limit_vol := 0;
                  end;
                end if;

              end if;

            else
              l_limit_vol := 0;
            end if;
          exception
            when no_data_found then
              l_limit_vol := 0;
          end;

          l_kub_fact_upnorm := 0;
          -- ��� ����� �� �������� ���� ���� (limit_proc ����� �� ��������):
          if nvl(p_limit_proc, 0) <> 0 then
            --���� ����������� ����������� �� ������������ ��� � %
            --������� 2 ������� ��������� ����������� ������ ���
            if p_kub >
               round(all_kub_ + p_kub / 100 * nvl(p_limit_proc, 0), 3) then
              --���������� ��������� ���������� ����� �� ����
              p_kub_dist := round(all_kub_ +
                                  p_kub / 100 * nvl(p_limit_proc, 0),
                                  3);
              l_kub_fact_upnorm := p_kub-p_kub_dist;
            end if;
          elsif l_limit_vol > 0 and tp_ in (0, 1, 2) then
            --������ ��� ����� �.�. � �.�. � ��.��.
            --������� ����������� ��� �� ���������
            if p_kub > round(all_kub_ + l_limit_vol, 3) then
              --���������� ��������� ���������� ����� �� ����
              p_kub_dist := round(all_kub_ + l_limit_vol, 3);
              l_kub_fact_upnorm := p_kub-p_kub_dist;
            end if;
          end if;
          -- ��� ����� �� �������� ���� ���� (limit_proc ����� �� ��������):

        end if;
      end if;

      ---------------------------------------------------
      --------���� ���������� ��� ������� ���------------

      if nvl(p_kub_dist, 0) = 0.001 then
        p_kub_sch  := null;
        p_sch_cnt  := null;
        p_sch_kpr  := null;
        p_kub_norm := null;
        p_kpr      := null;
        p_cnt_lsk  := null;
        p_kub_ar   := null;
        p_opl_ar   := null;
        p_opl_ar   := null;
      end if;

      ---������� ���������� ���-------------------------
      gen_clear_odn(p_usl      => p_usl,
                    p_usl_chld => fk_usl_chld_,
                    p_house    => null,
                    p_vvod     => p_id);

      if all_kub_ = 0 and p_kub_dist <> 0.001 then
        --p_kub <> 0.001
        --����� ������������� ������ ������� �� ����
        null;
      else
        if dist_tp_ in (1, 2, 3) then
          --������������� ��������������� �������,������ (307, 354 ����.)
          if nvl(p_kub_dist, 0) <> 0 and p_kub_dist - all_kub_ <> 0 then
            ---------------------------------------------------
            --------������������� ���--------------------------

            if dist_tp_ in (1, 3) then
              --������������ ��� �������� �� 344 ����.
              -- ����������
              if p_kub_dist - all_kub_ > 0 then
                --������������ ��������������� ������� (� �.�.����������), ���� �������� > 0
                if dist_tp_ <> 3 and use_sch_ = 1 then
                  --���� � �.�. ��������
                  update nabor k
                     set k.vol_add = round((select t.opl
                                              from kart t
                                             where t.lsk = k.lsk) *
                                           (p_kub_dist - all_kub_) /
                                           (all_opl_),
                                           3),
                         k.limit   = round((select case
                                                    when tp_ in (0, 1) then
                                                     l_limit_area * t.opl --����� ��� �� �/�. �.�.,�.�.
                                                    when tp_ = 2 then
                                                     l_rate * l_area_prop *
                                                     t.opl / all_opl_ --����� ��� �� �/�. ��.��.
                                                    else
                                                     null
                                                  end as limit
                                             from kart t
                                            where t.lsk = k.lsk),
                                           3)
                   where k.usl = fk_usl_chld_
                     and exists (select *
                            from kart t, nabor n
                           where k.lsk = t.lsk
                             and t.lsk = n.lsk
                             and nvl(t.opl, 0) <> 0 --��� ���� �������
                             and t.psch not in (8, 9)
                             and n.usl = p_usl
                             and n.fk_vvod = p_id);
                  -- commit;
                  -- Raise_application_error(-20000, l_limit_area||'-'||l_rate||'-'||l_area_prop||'-'||all_opl_);

                elsif dist_tp_ <> 3 and use_sch_ = 0 then
                  --���� ����� �� ���� � ���� ������� ��������
                  update nabor k
                     set k.vol_add = round((select t.opl
                                              from kart t
                                             where t.lsk = k.lsk) *
                                           (p_kub_dist - all_kub_) /
                                           (all_opl_),
                                           3),
                         k.limit   = round((select case
                                                    when tp_ in (0, 1) then
                                                     l_limit_area * t.opl --����� ��� �� �/�. �.�.,�.�.
                                                    when tp_ = 2 then
                                                     l_rate * l_area_prop *
                                                     t.opl / all_opl_ --����� ��� �� �/�. ��.��.
                                                    else
                                                     null
                                                  end as limit
                                             from kart t
                                            where t.lsk = k.lsk),
                                           3)
                   where k.usl = fk_usl_chld_
                     and exists
                   (select *
                            from kart t, nabor n
                           where k.lsk = t.lsk
                             and t.lsk = n.lsk
                             and nvl(t.opl, 0) <> 0 --��� ���� �������
                             and t.psch not in (8, 9)
                             and n.usl = p_usl
                             and n.fk_vvod = p_id
                             and not exists (select *
                                    from c_charge_prep e
                                   where n.lsk = e.lsk
                                     and n.usl = e.usl
                                     and e.tp = 7 --������� �������� � ���.�������
                                     and e.sch = 1));
                elsif dist_tp_ = 3 then
                  --���� ��� �����.=3 �� ���� ���������, ���� ������ ���-�� ���� ��������
                  update nabor k
                     set k.vol_add = round((select t.opl
                                              from kart t
                                             where t.lsk = k.lsk) *
                                           (p_kub_dist - all_kub_) /
                                           (all_opl_),
                                           3),
                         k.limit   = round((select case
                                                    when tp_ in (0, 1) then
                                                     l_limit_area * t.opl --����� ��� �� �/�. �.�.,�.�.
                                                    when tp_ = 2 then
                                                     l_rate * l_area_prop *
                                                     t.opl / all_opl_ --����� ��� �� �/�. ��.��.
                                                    else
                                                     null
                                                  end as limit
                                             from kart t
                                            where t.lsk = k.lsk),
                                           3)
                   where k.usl = fk_usl_chld_
                     and exists (select *
                            from kart t, nabor n
                           where k.lsk = t.lsk
                             and t.lsk = n.lsk
                             and nvl(t.opl, 0) <> 0 --��� ���� �������
                             and t.psch not in (8, 9)
                             and n.usl = p_usl
                             and n.fk_vvod = p_id
                             and (t.status = 9 or exists
                                  (select *
                                     from c_charge_prep e
                                    where t.lsk = e.lsk
                                      and e.usl = p_usl
                                      and e.tp = 6 --���� ��� ���
                                      and e.kpr2 <> 0)));
                end if;

                --�������� ���� �� ���.
                insert into c_charge
                  (lsk, usl, test_opl, type)
                  select k.lsk,
                         fk_usl_chld_,
                         k.vol_add    as test_opl,
                         5            as type
                    from nabor k
                   where k.usl = fk_usl_chld_
                     and nvl(k.vol_add, 0) <> 0
                     and exists (select *
                            from nabor n
                           where n.lsk = k.lsk
                             and n.usl = p_usl
                             and n.fk_vvod = p_id);
              else
                --�������� ��������������� ���-�� �����������, ���� �������� < 0
                --�� �� ����� ������������� ������
                --            Raise_application_error(-20000, all_kpr_||'-'||p_kub - all_kub_);

                if dist_tp_ <> 3 and use_sch_ = 1 then
                  --���� � �.�. ��������
                  open cur1;
                elsif dist_tp_ <> 3 and use_sch_ = 0 then
                  --���� ����� �� ���� � ���� ������� ��������
                  open cur2;
                elsif dist_tp_ = 3 then
                  --���� ��� �����.=3 �� ���� ���������, ���� ������ ���-�� ���� ��������
                  open cur3;
                end if;
                loop
                  if dist_tp_ <> 3 and use_sch_ = 1 then

                    fetch cur1
                      into rec;
                    exit when cur1%notfound;
                  elsif dist_tp_ <> 3 and use_sch_ = 0 then
                    fetch cur2
                      into rec;
                    exit when cur2%notfound;
                  elsif dist_tp_ = 3 then
                    fetch cur3
                      into rec;
                    exit when cur3%notfound;
                  end if;
                  --� ��� ������� ��� ��� �� �� �������� ������ (���) � �� ��������...
                  --��� 02.10.12
                  l_proc := rec.vol_add / rec.lsk_vl; --���� �������� � ������
                  l_vol  := 0;
                  if l_proc > 0 then
                    if abs(l_proc * rec.dist_vl) > rec.vol_add then
                      l_vol := round(l_proc * rec.vol_add, 3); --���� ABS(�������������� ��������) > ������
                    elsif abs(l_proc * rec.dist_vl) <= rec.vol_add then
                      l_vol := abs(round(l_proc * rec.dist_vl, 3)); --���� ABS(�������������� ��������) < ������
                    end if;
                    --���������� ����� ��� ��� ����������
                    update nabor n
                       set n.limit = round((select case
                                                    when tp_ in (0, 1) then
                                                     l_limit_area * t.opl --����� ��� �� �/�. �.�.,�.�.
                                                    when tp_ = 2 then
                                                     l_rate * l_area_prop *
                                                     t.opl / all_opl_ --����� ��� �� �/�. ��.��.
                                                    else
                                                     null
                                                  end as limit
                                             from kart t
                                            where t.lsk = n.lsk),
                                           3)
                     where n.lsk = rec.lsk
                       and n.usl = fk_usl_chld_;

                    --�������� �������.�� ��������
                    if l_vol > 0 then
                      --�������� ���� �� ���.
                      -- ����� �������� ���, ���� �������� �� �������� �� ����������! ���. 30.01.2017
                      -- ������ �������� ���, ��� ��� ����� ����� ������������ ���������� ���.31.08.2017 ���.
                      insert into c_charge_prep
                        (lsk, usl, vol, sch, tp)
                      values
                        (rec.lsk, p_usl, -1 * l_vol, 1, 4);

                      insert into c_charge
                        (lsk, usl, test_opl, type)
                      values
                        (rec.lsk, fk_usl_chld_, -1 * l_vol, 5);
                    elsif l_vol < 0 then
                      raise_application_error(-20000,
                                              '������������ ����� �����.��������� � �/�:' ||
                                              rec.lsk || ' ' || l_vol);
                    end if;
                  elsif l_proc < 0 then
                    raise_application_error(-20000,
                                            '������������ % ������������� � �/�:' ||
                                            rec.lsk || ' ' || l_proc);
                  end if;
                  --������� �� ������ ��� �������������
                  --�������� �������.�� ��������
                  l_dist_vl := abs(rec.dist_vl) - l_vol;
                  if l_dist_vl > 0 and rec.vol > 0 then
                    --���� �������� �������� � ���� ����� �� ���������

                    -- ����� �������� ���, ���� �������� �� �������� �� ����������! ���. 30.01.2017
                    -- ������ �������� ���, ��� ��� ����� ����� ������������ ���������� ���.31.08.2017 ���.
                    insert into c_charge_prep
                      (lsk, usl, vol, sch, tp)
                    values
                      (rec.lsk,
                       p_usl,
                       -1 * case when l_dist_vl > rec.vol then rec.vol --���� ABS(�������������� ��������) > ������
                       when l_dist_vl <= rec.vol then l_dist_vl --���� ABS(�������������� ��������) < ������
                       end,
                       0,
                       4);

                    --�������� ���� �� ���.
                    --���������� � �������� �����.
                    insert into c_charge
                      (lsk, usl, test_opl, type)
                    values
                      (rec.lsk,
                       fk_usl_chld_,
                       -1 * case when l_dist_vl > rec.vol then rec.vol --���� ABS(�������������� ��������) > ������
                       when l_dist_vl <= rec.vol then l_dist_vl --���� ABS(�������������� ��������) < ������
                       end,
                       5);
                  elsif l_dist_vl < 0 then
                    raise_application_error(-20000,
                                            '������������ ����� �����.������� �� �������� � �/�:' ||
                                            rec.lsk || ' ' || l_dist_vl);
                  end if;
                end loop;
                if dist_tp_ <> 3 and use_sch_ = 1 then
                  --���� � �.�. ��������
                  close cur1;
                elsif dist_tp_ <> 3 and use_sch_ = 0 then
                  --���� ����� �� ���� � ���� ������� ��������
                  close cur2;
                elsif dist_tp_ = 3 then
                  --���� ��� �����.=3 �� ���� ���������, ���� ������ ���-�� ���� ��������
                  close cur3;
                end if;

              end if;

            elsif dist_tp_ = 2 then
              --������������ ��������������� ������. ������
              --��� �� �������������� 22.04.14
              raise_application_error(-20000,
                                      'Error #2-��� �� ��������������');

              /*             update nabor k
                             set k.vol_add = --������������ �� ������������, �������� ��������, (+ ��� -)
                                   round((select nvl(sum(t.vol),0)
                                         from c_charge_prep t where t.lsk = k.lsk --��� ���������� �� ��������� �����.����
                                          and t.usl=p_usl
                                          and t.tp=6 --���� ��� ���
                                          )/(all_kub_) * (p_kub_dist - all_kub_) ,
                                         3)
                           where k.usl = fk_usl_chld_
                                  and k.fk_vvod = p_id
                                      and (use_sch_ = 1 or use_sch_ = 0 and not exists
                                      (select * from nabor n, c_charge_prep e where
                                        k.lsk=e.lsk --���� � �.�. ��������, ���� ����� �� ���� � ���� ������� ��������
                                        and t.lsk=n.lsk
                                        and n.usl=p_usl
                                        and n.fk_vvod = p_id
                                        and e.usl=p_usl
                                        and e.tp=7 --������� ��������
                                         ))
                                      and (dist_tp_ <> 3 or dist_tp_ = 3 and (t.status = 9 or exists
                                      (select * from c_charge_prep e where
                                        t.lsk=e.lsk
                                        and e.usl=p_usl
                                        and e.tp=6 --���� ��� ���
                                        and e.kpr2 <> 0) --���� ��� �����.=3 �� ���� ���������, ���� ������ ���-�� ���� ��������
                                         ))
                                         );
              */
              null;

            end if;
            ---------------------------------------------------
            --------������������� ���--------------------------

            ---------------------------------------------------
            --------���������� ���--------------------------
            --���������� ������������ �� 354 ����.
            if dist_tp_ in (1, 3) then
              --������������ ��������������� �������
              if p_kub_dist - all_kub_ > 0 then
                --���������� ������������ ��������������� ������� (� �.�.����������), ���� �������� > 0
                select sum(n.vol_add)
                  into l_for_round
                  from nabor n
                 where n.usl = fk_usl_chld_
                   and exists (select *
                          from nabor r, kart k
                         where n.lsk = r.lsk
                           and k.lsk = r.lsk
                           and k.psch not in (8, 9)
                           and r.fk_vvod = p_id
                           and r.usl = p_usl);
                logger.log_(null,
                            'p_vvod.gen_dist: ���������� �� ����� ' || p_id || ' =' ||
                            to_char(p_kub_dist - all_kub_ - l_for_round));
                if p_kub_dist - all_kub_ - l_for_round > 0.5 then
                  raise_application_error(-20000,
                                          '����! �������� ���������� ��������� ' ||
                                          to_char(p_kub_dist - all_kub_ -
                                                  l_for_round) ||
                                          ' �� �����: ' || p_id);
                end if;
                update nabor t
                   set t.vol_add = t.vol_add + p_kub_dist - all_kub_ -
                                   l_for_round
                 where t.lsk =
                       (select max(lsk)
                          from nabor n
                         where n.vol_add <> 0
                           and n.usl = fk_usl_chld_
                           and exists
                         (select *
                                  from nabor r, kart k
                                 where n.lsk = r.lsk
                                   and k.lsk = r.lsk
                                   and (dist_tp_ = 3 and
                                       (k.status = 9 or r.nrm_kpr <> 0) or
                                       dist_tp_ <> 3) --���� ��� �����.=3 �� ���� ���������, ���� ������ ���-�� ���� ��������
                                   and k.psch not in (8, 9)
                                   and r.fk_vvod = p_id
                                   and r.usl = p_usl /*� ������������*/
                                ))
                   and t.usl = fk_usl_chld_
                   and t.vol_add <> 0
                returning t.lsk, nvl(t.vol_add, 0) into l_lsk_round, l_vol_round;

                if l_lsk_round is not null and l_vol_round <> 0 then
                  --�������� ���� �� ���.
                  update c_charge t
                     set t.test_opl = l_vol_round
                   where t.lsk = l_lsk_round
                     and t.usl = fk_usl_chld_
                     and t.type = 5;
                end if;
              else
                --���������� �������� ��������������� �����������, ���� �������� < 0
                --� �� ����� ������������ �������!!
                select nvl(sum(n.test_opl), 0)
                  into l_nbalans --����� ��������������� ���������
                  from c_charge n
                 where n.usl = fk_usl_chld_
                   and n.type = 5
                   and exists (select *
                          from nabor r, kart k
                         where n.lsk = r.lsk
                           and k.lsk = r.lsk
                           and k.psch not in (8, 9)
                           and r.fk_vvod = p_id
                           and r.usl = p_usl);
                if abs(p_kub_dist - all_kub_ - l_nbalans) < 0.01 then
                  --���� ����� ��������� - ������������� ��������� ������ 0.01, �� ���������
                  --�� ���������� ��������, ���� ������ - �� ������ �������� ��� ������������, � ��������
                  --�����������
                  --       Raise_application_error(-20000, p_kub - all_kub_ -  l_nbalans);
                  for c in (select t.lsk,
                                   t.usl,
                                   p_kub_dist - all_kub_ - l_nbalans as corr_vol,
                                   1 as sch,
                                   4 as tp
                              from c_charge_prep t, nabor n
                             where t.tp in (0, 4)
                               and t.sch = 1
                               and t.usl = p_usl
                               and t.lsk = n.lsk
                               and n.fk_vvod = p_id
                             group by t.lsk, t.usl
                            having nvl(sum(t.vol), 0) > 0 --��� ��� ��� ������������� ������ ����, ���� ���������
                            ) loop
                    --��������� �������������
                    -- ����� �������� ���, ���� �������� �� �������� �� ����������! ���. 30.01.2017
                    -- ������ �������� ���, ��� ��� ����� ����� ������������ ���������� ���.31.08.2017 ���.
                    insert into c_charge_prep
                      (lsk, usl, vol, sch, tp)
                    values
                      (c.lsk, p_usl, c.corr_vol, c.sch, 4);
                    l_lsk_round := c.lsk;
                    exit;
                  end loop;

                  /*                update nabor t
                    set t.vol_add = t.vol_add + p_kub_dist - all_kub_ -
                                    l_nbalans
                  where t.lsk =
                        (select max(lsk)
                           from nabor n
                          where n.vol_add > 0.01
                            and n.usl =p_usl
                            and exists (select *
                                   from nabor r, kart k
                                  where n.lsk = r.lsk
                                    and k.lsk=r.lsk
                                    and k.psch not in (8, 9)
                                    and r.fk_vvod = p_id
                                    and r.usl = p_usl--��� �����������
                                    ))
                    and t.usl = p_usl
                    and t.vol_add > 0.01 --��� ��� ��� ������������� ������ ����, ���� ���������
                    returning t.lsk, nvl(t.vol_add,0) into l_lsk_round, l_vol_round; */

                  if sql%notfound then
                    --��������� �� ������������, ���� �� ������� ��������
                    for c in (select t.lsk,
                                     t.usl,
                                     p_kub_dist - all_kub_ - l_nbalans as corr_vol,
                                     0 as sch,
                                     4 as tp
                                from c_charge_prep t, nabor n
                               where t.tp in (0, 4)
                                 and t.sch = 0
                                 and t.usl = p_usl
                                 and t.lsk = n.lsk
                                 and n.fk_vvod = p_id
                               group by t.lsk, t.usl
                              having nvl(sum(t.vol), 0) > 0 --��� ��� ��� ������������� ������ ����, ���� ���������
                              ) loop
                      --��������� �������������

                      -- ����� �������� ���, ���� �������� �� �������� �� ����������! ���. 30.01.2017
                      -- ������ �������� ���, ��� ��� ����� ����� ������������ ���������� ���.31.08.2017 ���.
                      insert
                      into c_charge_prep
                        (lsk, usl, vol, sch, tp)
                      values
                        (c.lsk, p_usl, c.corr_vol, c.sch, 4);
                      l_lsk_round := c.lsk;
                      exit;
                    end loop;
                    /*                  update nabor t
                      set t.vol = t.vol + p_kub_dist - all_kub_ -
                                      l_nbalans
                    where t.lsk =
                          (select max(lsk)
                             from nabor n
                            where n.vol >= 0.01
                              and n.usl =p_usl
                              and exists (select *
                                     from nabor r, kart k
                                    where n.lsk = r.lsk
                                      and k.lsk=r.lsk
                                      and k.psch not in (8, 9)
                                      and r.fk_vvod = p_id
                                      and r.usl = p_usl--� ������������))
                      and t.usl = p_usl
                      and t.vol >= 0.01 --��� ��� ��� ������������� ������ ����, ���� ���������
                      returning t.lsk into l_lsk_round;  */
                  end if;
                  if l_lsk_round is not null then
                    --�������� ���� �� ���.
                    update c_charge t
                       set t.test_opl = t.test_opl + p_kub_dist - all_kub_ -
                                        l_nbalans
                     where t.lsk = l_lsk_round
                       and t.usl = fk_usl_chld_
                       and t.type = 5;
                  end if;

                end if;
              end if;
            elsif dist_tp_ = 2 then
              --������������ ��������������� ������. ������

              raise_application_error(-20000,
                                      '��� �� ������������!');
              /*            update nabor t
                set t.vol_add = t.vol_add + p_kub_dist - all_kub_ -
                                 (select round(sum(n.vol_add), 3)
                                    from nabor n
                                   where n.usl = fk_usl_chld_
                                     and exists
                                   (select *
                                            from nabor r, kart k
                                           where n.lsk = r.lsk
                                             and k.lsk = r.lsk
                                             and k.psch not in (8, 9)
                                             and r.fk_vvod = p_id
                                             and r.usl = p_usl))
              where t.lsk =
                    (select max(lsk)
                       from nabor n
                      where n.vol_add <> 0
                        and n.usl =fk_usl_chld_
                        and exists (select *
                               from nabor r, kart k
                              where n.lsk = r.lsk
                                and k.lsk=r.lsk
                                and k.psch not in (8, 9)
                                and r.fk_vvod = p_id
                                and r.usl = p_usl--� ������������))
                and t.usl = fk_usl_chld_
                and t.vol_add <> 0; */
            end if;
            ---------------------------------------------------
            --------���������� ���-----------------------------
          end if;

          ---------------------------------------------------
          --------����� ������������� ���--------------------
          --�������� ����������� ������������
          --�� ����� ����������
          select nvl(sum(case
                           when k.psch in (1, 2) and fk_calc_tp_ in (3, 17, 38) then
                            0
                           when k.psch in (1, 3) and fk_calc_tp_ in (4, 18, 40) then
                            0
                           when k.psch in (0, 3) and fk_calc_tp_ in (3, 17, 38) then
                            n.test_opl
                           when k.psch in (0, 2) and fk_calc_tp_ in (4, 18, 40) then
                            n.test_opl
                           when k.sch_el in (0) and fk_calc_tp_ in (31) then
                            n.test_opl
                         end),
                     0),
                 nvl(sum(case
                           when k.psch in (1, 2) and fk_calc_tp_ in (3, 17, 38) then
                            n.test_opl
                           when k.psch in (1, 3) and fk_calc_tp_ in (4, 18, 40) then
                            n.test_opl
                           when k.psch in (0, 3) and fk_calc_tp_ in (3, 17, 38) then
                            0
                           when k.psch in (0, 2) and fk_calc_tp_ in (4, 18, 40) then
                            0
                           when k.sch_el in (1) and fk_calc_tp_ in (31) then
                            n.test_opl
                         end),
                     0)
            into rec_cnt_
            from kart k, c_charge n
           where k.lsk = n.lsk
             and k.psch not in (8, 9)
             and n.usl = fk_usl_chld_
             and n.type = 5
             and exists (select *
                    from nabor r
                   where n.lsk = r.lsk
                     and r.fk_vvod = p_id
                     and r.usl = p_usl)
             and k.status <> 9;
          --�����
          p_kub_nrm_fact := rec_cnt_.vol;
          p_kub_sch_fact := rec_cnt_.vol_add;
          --�������� ����������� ������������
          --�� ������� ����������
          select nvl(sum(n.test_opl), 0)
            into rec_cnt_.vol_add
            from kart k, c_charge n
           where k.lsk = n.lsk
             and k.psch not in (8, 9)
             and n.usl = fk_usl_chld_
             and exists (select *
                    from nabor r
                   where n.lsk = r.lsk
                     and r.fk_vvod = p_id
                     and r.usl = p_usl)
             and k.status = 9
             and n.type = 5;
          p_kub_ar_fact := rec_cnt_.vol_add;
          p_kub_fact    := p_kub_nrm_fact + p_kub_sch_fact + p_kub_ar_fact;

        elsif dist_tp_ = 0 then
          --������������� ��������������� ������ (���) (����������)
          raise_application_error(-20000,
                                  '��� �� ������������!');
        end if;

        ---------------------------------------------------
        --------�������������------------------------------

      end if;

    elsif fk_calc_tp_ = 1 and dist_tp_ = 0 then
      --����������, ������ ������ 31
      --������������� �������������� ���, ��������������� �������, �� �������� ������ (���)
      select nvl(sum(k.mel), 0) as kub_sch,
             count(*) as cnt,
             nvl(sum(k.kpr - k.kpr_ot), 0) as kpr_sch,
             nvl(sum(k.opl), 0) as opl
        into rec_sch_tsj_
        from kart k, nabor n
       where n.fk_vvod = p_id
         and k.sch_el = 1
         and k.lsk = n.lsk
         and k.psch not in (8, 9)
         and n.usl = p_usl;
      p_kub_sch := rec_sch_tsj_.kub_sch;
      p_sch_cnt := rec_sch_tsj_.cnt;
      p_sch_kpr := rec_sch_tsj_.kpr;

      select 0 as kub_norm,
             count(*) as cnt, --��, �� 0 �� ��������� (����� ������� kpr * ��������) ��������! ��� 21.03.12
             nvl(sum(k.kpr - k.kpr_ot), 0) as kpr_norm,
             nvl(sum(k.opl), 0) as opl
        into rec_norm_tsj_
        from kart k, nabor n
       where n.fk_vvod = p_id
         and k.sch_el <> 1
         and k.lsk = n.lsk
         and k.psch not in (8, 9)
         and n.usl = p_usl;
      p_kub_norm := rec_norm_tsj_.kub_norm;
      p_kpr      := rec_norm_tsj_.kpr;
      p_cnt_lsk  := rec_norm_tsj_.cnt_lsk;

      --��������� ������ �� �����
      all_kub_ := rec_sch_tsj_.kub_sch + rec_norm_tsj_.kub_norm;
      --��������� ������� �� �����
      all_opl_ := rec_sch_tsj_.opl + rec_norm_tsj_.opl;

      update nabor k
         set k.vol_add = --������������ �� ������������, �������� ��������, (+ ��� -)
              round((select t.opl from kart t where t.lsk = k.lsk) /
                    all_opl_ * (p_kub_dist - all_kub_),
                    3)
       where k.usl = fk_usl_chld_
         and exists (select *
                from nabor n, kart t
               where n.lsk = k.lsk
                 and t.psch not in (8, 9)
                 and n.fk_vvod = p_id
                 and n.usl = p_usl);

      --���������� �� ���������� ������������/c�������
      update nabor t
         set t.vol_add = t.vol_add + p_kub_dist - all_kub_ -
                         (select sum(n.vol_add)
                            from nabor n
                           where n.usl = fk_usl_chld_
                             and exists (select *
                                    from nabor r, kart t
                                   where n.lsk = r.lsk
                                     and r.lsk = t.lsk
                                     and t.psch not in (8, 9)
                                     and r.fk_vvod = p_id
                                     and r.usl = p_usl))
       where t.lsk = (select max(lsk)
                        from nabor n
                       where n.vol_add <> 0
                         and n.usl = fk_usl_chld_
                         and exists (select *
                                from nabor r, kart t
                               where n.lsk = r.lsk
                                 and r.lsk = t.lsk
                                 and t.psch not in (8, 9)
                                 and r.fk_vvod = p_id
                                 and r.usl = p_usl))
         and t.vol_add <> 0;
      --�������� ����������� ������������
      select sum(case
                   when k.sch_el <> 1 then
                    n.vol_add
                   else
                    0
                 end),
             sum(case
                   when k.sch_el = 1 then
                    n.vol_add
                   else
                    0
                 end)
        into rec_cnt_
        from kart k, nabor n
       where k.lsk = n.lsk
         and k.psch not in (8, 9)
         and n.usl = fk_usl_chld_
         and exists (select *
                from nabor r, kart t
               where n.lsk = r.lsk
                 and r.lsk = t.lsk
                 and t.psch not in (8, 9)
                 and r.fk_vvod = p_id
                 and r.usl = p_usl);
      --�����
      p_kub_nrm_fact := rec_cnt_.vol;
      p_kub_sch_fact := rec_cnt_.vol_add;
      p_kub_fact     := p_kub_nrm_fact + p_kub_sch_fact;
      ---------
      ---------
    elsif fk_calc_tp_ = 1 and dist_tp_ = 1 then
      --���������� �� ������.����� (���)
      select nvl(sum(mel), 0), count(*), nvl(sum(k.kpr - k.kpr_ot), 0)
        into kub_rec_
        from kart k, nabor n
       where k.sch_el in (1)
         and k.lsk = n.lsk
         and k.psch not in (8, 9)
         and n.usl = p_usl
         and case
               when sptarn_ = 0 and nvl(n.koeff, 0) <> 0 then
                1 --���������� ������� ������ � �.�.
               when sptarn_ = 1 and nvl(n.norm, 0) <> 0 then
                1
               when sptarn_ = 2 and nvl(n.koeff, 0) <> 0 and
                    nvl(n.norm, 0) <> 0 then
                1
               when sptarn_ = 3 and nvl(n.koeff, 0) <> 0 and
                    nvl(n.norm, 0) <> 0 then
                1
               else
                0
             end = 1
         and n.fk_vvod = p_id;

      p_kub_sch := kub_rec_.kub_sch;
      p_sch_cnt := kub_rec_.cnt;
      p_sch_kpr := kub_rec_.kpr_sch;

      --����� ����� �� ���������
      select count(*), nvl(sum(k.kpr - k.kpr_ot), 0)
        into kpr_rec_
        from kart k, nabor n
       where k.sch_el not in (1)
         and k.lsk = n.lsk
         and n.usl = p_usl
         and k.psch not in (8, 9)
         and case
               when sptarn_ = 0 and nvl(n.koeff, 0) <> 0 then
                1 --���������� ������� ������ � �.�.
               when sptarn_ = 1 and nvl(n.norm, 0) <> 0 then
                1
               when sptarn_ = 2 and nvl(n.koeff, 0) <> 0 and
                    nvl(n.norm, 0) <> 0 then
                1
               when sptarn_ = 3 and nvl(n.koeff, 0) <> 0 and
                    nvl(n.norm, 0) <> 0 then
                1
               else
                0
             end = 1
         and n.fk_vvod = p_id;
      p_kpr     := kpr_rec_.kpr;
      p_cnt_lsk := kpr_rec_.cnt;

      --��������� ���-�� ��� �� ���������, �� ���������
      if (p_kub_dist - kub_rec_.kub_sch) < 0 then
        -- �� �������� �������� ( ��� �� �� > ����� �� ����)
        update kart k
           set k.mel = 0
         where k.sch_el not in (1)
           and exists
         (select *
                  from nabor n
                 where n.lsk = k.lsk
                   and n.usl = p_usl
                   and case
                         when sptarn_ = 0 and nvl(n.koeff, 0) <> 0 then
                          1 --���������� ������� ������ � �.�.
                         when sptarn_ = 1 and nvl(n.norm, 0) <> 0 then
                          1
                         when sptarn_ = 2 and nvl(n.koeff, 0) <> 0 and
                              nvl(n.norm, 0) <> 0 then
                          1
                         when sptarn_ = 3 and nvl(n.koeff, 0) <> 0 and
                              nvl(n.norm, 0) <> 0 then
                          1
                         else
                          0
                       end = 1
                   and n.fk_vvod = p_id);

        --������ ��� �� ������� ��������, �� ����� �����
        p_kub_man := 0;
      elsif kpr_rec_.kpr > 0 then
        --���� ���� ����
        update kart k
           set k.mel =
               (p_kub_dist - kub_rec_.kub_sch) / kpr_rec_.kpr
         where k.sch_el not in (1)
           and k.psch not in (8, 9)
           and exists
         (select *
                  from nabor n
                 where n.lsk = k.lsk
                   and n.usl = p_usl
                   and case
                         when sptarn_ = 0 and nvl(n.koeff, 0) <> 0 then
                          1 --���������� ������� ������ � �.�.
                         when sptarn_ = 1 and nvl(n.norm, 0) <> 0 then
                          1
                         when sptarn_ = 2 and nvl(n.koeff, 0) <> 0 and
                              nvl(n.norm, 0) <> 0 then
                          1
                         when sptarn_ = 3 and nvl(n.koeff, 0) <> 0 and
                              nvl(n.norm, 0) <> 0 then
                          1
                         else
                          0
                       end = 1
                   and n.fk_vvod = p_id);
        --������ ��� �� ������� ��������, �� ����� �����
        p_kub_man := (p_kub_dist - kub_rec_.kub_sch) / kpr_rec_.kpr;
      elsif kpr_rec_.kpr = 0 then
        --���� ��� �����
        update kart k
           set k.mel = 0
         where k.sch_el not in (1)
           and exists
         (select *
                  from nabor n
                 where n.lsk = k.lsk
                   and n.usl = p_usl
                   and case
                         when sptarn_ = 0 and nvl(n.koeff, 0) <> 0 then
                          1 --���������� ������� ������ � �.�.
                         when sptarn_ = 1 and nvl(n.norm, 0) <> 0 then
                          1
                         when sptarn_ = 2 and nvl(n.koeff, 0) <> 0 and
                              nvl(n.norm, 0) <> 0 then
                          1
                         when sptarn_ = 3 and nvl(n.koeff, 0) <> 0 and
                              nvl(n.norm, 0) <> 0 then
                          1
                         else
                          0
                       end = 1
                   and n.fk_vvod = p_id);
        --������ ��� �� ������� ��������, �� ����� �����
        p_kub_man := 0;
      end if;

      select sum(decode(k.sch_el, 1, k.mel, k.mel * k.kpr))
        into p_kub_fact
        from kart k, nabor c
       where c.fk_vvod = p_id
         and c.usl = p_usl
         and k.psch not in (8, 9)
         and k.lsk = c.lsk;

      ---------
      ---------
    elsif fk_calc_tp_ = 11 then
      --������������� �� ������ ��� ��� (��������������� �������)
      update nabor n
         set n.koeff = round(p_kub_dist /
                             (select sum(k.opl)
                                from kart k, nabor r
                               where k.lsk = r.lsk
                                 and r.fk_vvod = p_id
                                 and k.psch not in (8, 9)) *
                             (select sum(k.opl)
                                from kart k
                               where k.lsk = n.lsk
                                 and k.psch not in (8, 9)),
                             2)
       where exists (select *
                from kart a, nabor r
               where a.lsk = n.lsk
                 and a.lsk = r.lsk
                 and r.fk_vvod = p_id)
         and n.usl = p_usl;

    elsif fk_calc_tp_ = 23 and p_kub_dist is not null then
      --������������� �� ������ ������, ������������� ��� �������� * vol_add, ��������������� �������
      --��������, ��.����� ��� � ���., � ���, ��.��.��� � �����.
      --����� �� �������������� ������ ���, ������� �� ������������ �����
      --���������� �� �������� ������ � ������� ������
      l_limit_vol := 0;

      if l_usl_cd in ('��.��.���', '��.��.���2', '��.��.���� �� ���') and nvl(p_wo_limit, 0) = 0 then
        begin
          select nvl(round(x.n1 * 2.7, 4), 0)
            into l_limit_vol
            from t_objxpar x, v_house_pars u, c_houses h
           where x.fk_list = u.id
             and x.fk_k_lsk = h.k_lsk_id
             and h.id = p_house_id
             and u.cd = 'area_general_property'
             and not exists
           (select *
                    from t_objxpar x, v_house_pars u, c_houses h
                   where x.fk_list = u.id
                     and x.fk_k_lsk = h.k_lsk_id
                     and h.id = p_house_id
                     and u.cd = 'exist_lift'
                     and nvl(x.n1, 0) = 1

                  );
          l_odn_nrm:=2.7;
        exception
          when no_data_found then
            l_limit_vol := 0;
        end;
        if l_limit_vol = 0 then
          --������ ��� � ������
          begin
            select nvl(round(x.n1 * 4.1, 4), 0)
              into l_limit_vol
              from t_objxpar x, v_house_pars u, c_houses h
             where x.fk_list = u.id
               and x.fk_k_lsk = h.k_lsk_id
               and h.id = p_house_id
               and u.cd = 'area_general_property'
               and exists
             (select *
                      from t_objxpar x, v_house_pars u, c_houses h
                     where x.fk_list = u.id
                       and x.fk_k_lsk = h.k_lsk_id
                       and h.id = p_house_id
                       and u.cd = 'exist_lift'
                       and nvl(x.n1, 0) = 1
                    );
          l_odn_nrm:=4.1;
          exception
            when no_data_found then
              l_limit_vol := 0;
          end;
        end if;

        --��������� ����������� ���
        if p_kub_dist > l_limit_vol then
          p_kub_dist := l_limit_vol;
        end if;
      end if;

      --����� �� �����-������
      update nabor k
         set k.vol = 0, k.vol_add = 0, k.limit = null
       where k.usl = p_usl
         and exists (select *
                from nabor n, kart t
               where n.lsk = k.lsk
                 and n.lsk = t.lsk
                 and n.usl = p_usl
                 and n.fk_vvod = p_id);
      --������������
      update nabor n
         set n.vol_add = round(p_kub_dist /
                               (select sum(k.opl)
                                  from kart k, nabor r
                                 where k.lsk = r.lsk
                                   and r.fk_vvod = p_id
                                   and nvl(r.koeff, 0) <> 0 --������� 01.02.2016
                                   and k.psch not in (8, 9)) *
                               (select sum(k.opl)
                                  from kart k
                                 where k.lsk = n.lsk
                                   and k.psch not in (8, 9)),
                               2)
       where nvl(n.koeff, 0) <> 0
         and n.fk_vvod = p_id
         and n.usl = p_usl
         and exists (select *
                from kart k
               where k.lsk = n.lsk
                 and k.psch not in (8, 9));

      --������������ ����������
      select nvl(sum(c.vol_add), 0)
        into p_kub_fact
        from kart k, nabor c
       where c.fk_vvod = p_id
         and c.usl = p_usl
         and k.psch not in (8, 9)
         and nvl(c.koeff, 0) <> 0
         and k.lsk = c.lsk;
      if abs(p_kub_dist - p_kub_fact) > 2 then
        raise_application_error(-20000,
                                '�������� ������� ����� � �������� �� ��������� �� �����, ������������� �� id=' || p_id||', �������='||(p_kub_dist - p_kub_fact));
      end if;

      --����������
      update nabor t
         set t.vol_add = t.vol_add + p_kub_dist - p_kub_fact
       where t.fk_vvod = p_id
         and t.lsk = (select max(lsk)
                        from nabor n
                       where n.fk_vvod = p_id
                         and n.vol_add <> 0
                         and n.usl = p_usl)
         and t.vol_add <> 0;

      --� �����.. ������������ ����������
      select sum(c.vol_add)
        into p_kub_fact
        from kart k, nabor c
       where c.fk_vvod = p_id
         and c.usl = p_usl
         and k.psch not in (8, 9)
         and nvl(c.koeff, 0) <> 0
         and k.lsk = c.lsk;

    elsif fk_calc_tp_ = 15 then
      --�������������� ����� (��� ���), (�� ������� ������)
      update nabor n
         set n.vol = round(p_kub_dist /
                           (select count(*)
                              from kart k, nabor b, usl u
                             where k.lsk = b.lsk
                               and b.usl = u.usl
                               and b.usl = p_usl
                               and nvl(b.koeff, 0) <> 0
                               and b.fk_vvod = p_id
                               and k.psch not in (8, 9)),
                           5)
       where n.fk_vvod = p_id
         and exists (select *
                from nabor b
               where n.lsk = b.lsk
                 and b.usl = p_usl
                 and b.fk_vvod = p_id
                 and nvl(b.koeff, 0) <> 0)
         and n.usl = p_usl;

      begin
        select nvl(round(p_kub_dist / count(*), 2), 0), count(*), null
          into kub_rec_
          from kart k, nabor b, usl u
         where k.lsk = b.lsk
           and b.usl = u.usl
           and b.usl = p_usl
           and nvl(b.koeff, 0) <> 0
           and b.fk_vvod = p_id
           and k.psch not in (8, 9);
      exception
        when zero_divide then
          raise_application_error(-20000,
                                  '�������� ����������� ������ � ������� ������, ������� �� ���� � ����� ID=' || p_id);

      end;

      select sum(c.vol)
        into p_kub_fact
        from kart k, nabor c
       where c.fk_vvod = p_id
         and c.usl = p_usl
         and k.psch not in (8, 9)
         and nvl(c.koeff, 0) <> 0
         and k.lsk = c.lsk;

      p_kub_sch := kub_rec_.kub_sch;
      p_sch_cnt := kub_rec_.cnt;
      p_sch_kpr := kub_rec_.kpr_sch;

    elsif fk_calc_tp_ = 14 then
      --���������� �� ������ ��������� � �����
      --����������� �����. ��� �������� ���� �� ��� � ���� �� �������
      --�����. ���� ��� ��������� �� ����� � �����

      --����� �� �����
      koeff_ := 1;
      --������������ ������ �� ��� �� �������� ���������, � ������� �������� ������
        --������������ ��� ���������, ���� ��������������� �������
/* ����� ��� �������� ���������� round (5), ��������� � ������������� ������������� (������ � �����) 25.07.2016
           set n.vol = round(round(p_kub_dist /
                                   (select sum(k.opl)
                                      from kart k, nabor b, usl u
                                     where k.lsk = b.lsk
                                       and b.usl = u.usl
                                       and b.usl = p_usl
                                       and b.fk_vvod = p_id
                                       and k.psch not in (8, 9)),
                                   5) * koeff_ *
                             (select k.opl from kart k where k.lsk = n.lsk),
                             5)
*/
        update nabor n
           set n.vol = round(round(p_kub_dist,
                                   5) /
                                   (select sum(k.opl)
                                      from kart k, nabor b, usl u
                                     where k.lsk = b.lsk
                                       and b.usl = u.usl
                                       and b.usl = p_usl
                                       and b.fk_vvod = p_id
                                       and k.psch not in (8, 9)) * koeff_ *
                             (select k.opl from kart k where k.lsk = n.lsk),
                             5)
         where n.fk_vvod = p_id
           and exists (select *
                  from nabor b
                 where n.lsk = b.lsk
                   and b.usl = p_usl)
           and n.usl = p_usl
           and n.fk_vvod = p_id;

      select sum(c.vol)
        into p_kub_fact
        from kart k, nabor c
       where c.fk_vvod = p_id
         and c.usl = p_usl
         and k.psch not in (8, 9)
         and k.lsk = c.lsk;
      /* --����� �������� if... �� �������� ������ ���. 28.04.12
      elsif fk_calc_tp_ = 1 then
        --���������� �� ������.�����
        select nvl(sum(mel), 0), count(*), nvl(sum(k.kpr - k.kpr_ot), 0)
          into kub_rec_
          from kart k, nabor n
         where k.house_id = p_house_id
           and k.sch_el in (1)
           and k.lsk = n.lsk
           and k.psch not in (8, 9)
           and n.usl = p_usl
           and n.fk_vvod = p_id;

        p_kub_sch := kub_rec_.kub_sch;
        p_sch_cnt := kub_rec_.cnt;
        p_sch_kpr := kub_rec_.kpr_sch;

        --����� ����� �� ���������
        select count(*), nvl(sum(k.kpr - k.kpr_ot), 0)
          into kpr_rec_
          from kart k, nabor n
         where k.house_id = p_house_id
           and k.sch_el not in (1)
           and k.lsk = n.lsk
           and n.usl = p_usl
           and k.psch not in (8, 9)
           and n.fk_vvod = p_id;
        p_kpr     := kpr_rec_.kpr;
        p_cnt_lsk := kpr_rec_.cnt;

        --��������� ���-�� ��� �� ���������, �� ���������
        if (p_kub - kub_rec_.kub_sch) < 0 then
          -- �� �������� �������� ( ��� �� �� > ����� �� ����)
          update kart k
             set k.mel = 0
           where k.house_id = p_house_id
             and k.sch_el not in (1)
             and exists (select *
                    from nabor n
                   where n.lsk = k.lsk
                     and n.usl = p_usl
                     and n.fk_vvod = p_id);

          --������ ��� �� ������� ��������, �� ����� �����
          p_kub_man := 0;
        elsif kpr_rec_.kpr > 0 then
          --���� ���� ����
          update kart k
             set k.mel =
                  (p_kub - kub_rec_.kub_sch) / kpr_rec_.kpr
           where k.house_id = p_house_id
             and k.sch_el not in (1)
             and k.psch not in (8, 9)
             and exists (select *
                    from nabor n
                   where n.lsk = k.lsk
                     and n.usl = p_usl
                     and n.fk_vvod = p_id);
          --������ ��� �� ������� ��������, �� ����� �����
          p_kub_man := (p_kub - kub_rec_.kub_sch) / kpr_rec_.kpr;
        elsif kpr_rec_.kpr = 0 then
          --���� ��� �����
          update kart k
             set k.mel = 0
           where k.house_id = p_house_id
             and k.sch_el not in (1)
             and exists (select *
                    from nabor n
                   where n.lsk = k.lsk
                     and n.usl = p_usl
                     and n.fk_vvod = p_id);
          --������ ��� �� ������� ��������, �� ����� �����
          p_kub_man := 0;
        end if;

        select sum(decode(k.sch_el, 1, k.mel, k.mel * k.kpr))
          into p_kub_fact
          from kart k, nabor c
         where c.fk_vvod = p_id
           and c.usl = p_usl
           and k.psch not in (8, 9)
           and k.lsk = c.lsk;
      */
    end if;

    --�������� ����� ��������� �����������
    --�� ��������� �������� ���������� �� �����!

    update c_vvod t
       set t.kub_nrm_fact = p_kub_nrm_fact,
           t.kub_sch_fact = p_kub_sch_fact,
           t.kub_ar_fact  = p_kub_ar_fact,
           t.kub_ar       = p_kub_ar,
           t.opl_ar       = p_opl_ar,
           t.kub_sch      = p_kub_sch,
           t.sch_cnt      = p_sch_cnt,
           t.sch_kpr      = p_sch_kpr,
           t.kpr          = p_kpr,
           t.cnt_lsk      = p_cnt_lsk,
           t.kub_norm     = p_kub_norm,
           t.kub_fact     = p_kub_fact,
           t.kub_man      = p_kub_man,
           t.kub_dist     = p_kub_dist,
           t.opl_add      = p_opl_add,
           t.nrm = l_odn_nrm,
           t.kub_fact_upnorm = l_kub_fact_upnorm
     where t.id = p_id;

    --if p_gen_part_kpr = 1 then
    --  --������ ���������� (���� �� ��������)
    --  l_cnt := c_charges.gen_charges(null, null, null, p_id, 0, 0);
    --end if;
    logger.log_(l_time,
                '���������: p_vvod.gen_dist: vvod_id=' || p_id);

  end;

    --����������������� ������� �� ���� �����
  procedure gen_dist_all_houses is
    l_cnt number;
    time_  date;
    time1_ date;
    i number;
  begin
    time_  := sysdate;
    time1_ := sysdate;
    --������, �� ������ ������ ������ ����, ��� ��� ������ ��� ��������� (��� ������ � c_vvod)
    logger.log_(time1_,
                'p_vvod.gen_dist_all_houses - ������ ������������� ������� �� ����');
    for c in (select u.usl, u.fk_usl_chld
                from usl u, usl odn
               where u.cd in ('�.����',
                              '�.����',
                              '�.�. ��� ���',
                              '��.�����.2',
                              '��.��.���� ��',
                              '��.��.���',
                              '����.����.')
                 and u.fk_usl_chld = odn.usl) loop
      for c2 in (select h.id
                   from c_houses h
                  where nvl(h.psch, 0) = 0 --�� �������� ����
                    and h.id=6962
                    and not exists
                  (select * from c_vvod d where d.usl = c.usl)
                  order by h.id) loop
            logger.log_(time1_,
                'p_vvod.gen_dist_all_houses - I - ����:��� c_house.id='||c2.id);
            --���������
            gen_clear_odn(p_usl      => c.usl,
                          p_usl_chld => c.fk_usl_chld,
                          p_house    => c2.id,
                          p_vvod     => null);
      end loop;
    end loop;

    --commit, ����� �������� �������
    commit;
    logger.log_(time1_,
                'p_vvod.gen_dist_all_houses - ��������� I - ����:������� ��� ��� ������ ��� ������ �� �����');
    time1_ := sysdate;

    --������������ ��� � �����, ��� ��� ����
    i:=0;
    for c in (select d.id
                from c_vvod d, c_houses h
               where d.house_id = h.id
                    and h.id=6962
                 and d.dist_tp in (4,5) --���� ��� ����
                 and nvl(h.psch, 0) = 0 --�� �������� ����
               order by d.id) loop
      --������������ �����
      gen_dist_wo_vvod_usl(c.id);
    end loop;

    logger.log_(time1_,
                'p_vvod.gen_dist_all_houses - ��������� II - ����:����� � �����, ��� ��� ����');
    time1_ := sysdate;

    i:=0;
    --������������ ������ �� ����� � ����
    for c in (select distinct d.*
                from c_vvod d, c_houses h
               where d.house_id = h.id
                    and h.id=6962
                 and nvl(h.psch, 0) = 0 --�� �������� ����
                 and d.dist_tp not in (4,5,2) --���� � ���� � � ������� ��� �������������, �������� ��� (dist_tp<>2)
                 and d.usl is not null
              )
     loop
      p_vvod.gen_dist(p_klsk           => c.fk_k_lsk,
                      p_dist_tp        => c.dist_tp,
                      p_usl            => c.usl,
                      p_use_sch        => c.use_sch,
                      p_old_use_sch    => c.use_sch,
                      p_kub_nrm_fact   => c.kub_nrm_fact,
                      p_kub_sch_fact   => c.kub_sch_fact,
                      p_kub_ar_fact    => c.kub_ar_fact,
                      p_kub_ar         => c.kub_ar,
                      p_opl_ar         => c.opl_ar,
                      p_kub_sch        => c.kub_sch,
                      p_sch_cnt        => c.sch_cnt,
                      p_sch_kpr        => c.sch_kpr,
                      p_kpr            => c.kpr,
                      p_cnt_lsk        => c.cnt_lsk,
                      p_kub_norm       => c.kub_norm,
                      p_kub_fact       => c.kub_fact,
                      p_kub_man        => c.kub_man,
                      p_kub            => c.kub,
                      p_edt_norm       => c.edt_norm,
                      p_kub_dist       => c.kub_dist,
                      p_id             => c.id,
                      p_house_id       => c.house_id,
                      p_opl_add        => c.opl_add,
                      p_old_kub        => c.kub,
                      p_limit_proc     => c.limit_proc,
                      p_old_limit_proc => c.limit_proc,
                      p_gen_part_kpr   => 1,
                      p_wo_limit       => c.wo_limit);
      commit;
    end loop;
    logger.log_(time1_,
                'p_vvod.gen_dist_all_houses - ��������� III - ����:����� � �����, ��� ���� ����');
    logger.log_(time_,
                'p_vvod.gen_dist_all_houses: ��������� �������������');

  end;

  procedure gen_clear_odn(p_usl      in c_vvod.usl%type,
                          p_usl_chld in c_vvod.usl%type,
                          p_house    in c_houses.id%type,
                          p_vvod     in c_vvod.id%type) is
  l_time1 date;
  begin
    --��������� ���������� �� ���
    l_time1 := sysdate;
    if p_vvod is not null then
      --������� ���������� �� �����.���.�� �������������� �������
      delete from c_charge t
       where t.type = 5
         and t.usl = p_usl_chld
         and exists (select *
                from nabor n
               where n.fk_vvod = p_vvod
                 and n.usl = p_usl
                 and n.lsk = t.lsk);
      --������� ���������� �� �������������� ���
      delete from c_charge_prep t
       where t.usl = p_usl
         and t.tp = 4
         and exists (select *
                from nabor n
               where n.fk_vvod = p_vvod
                 and n.usl = p_usl
                 and n.lsk = t.lsk);

      --����� �� �����-������
      update nabor k
         set k.vol = 0, k.vol_add = 0, k.limit = null
       where k.usl = p_usl
         and exists (select *
                from nabor n, kart t
               where n.lsk = k.lsk
                 and n.lsk = t.lsk
                 and n.usl = p_usl
                 and n.fk_vvod = p_vvod);
      --����� �� ��������� �������
      update nabor k
         set k.vol = 0, k.vol_add = 0, k.limit = null
       where k.usl = p_usl_chld
         and exists (select *
                from nabor n, kart t
               where n.lsk = k.lsk
                 and n.lsk = t.lsk
                 and n.usl = p_usl
                 and n.fk_vvod = p_vvod);
      --��������� ��������� (�����������)
      update c_vvod t set t.nrm=null where t.id=p_vvod;
    elsif p_house is not null then
      --������� ���������� �� �����.���.�� �������������� �������
      delete from c_charge t
       where t.type = 5
         and t.usl = p_usl_chld
         and exists (select *
                from nabor n, kart k
               where k.house_id = p_house
                 and k.lsk = n.lsk
                 and n.usl = p_usl
                 and n.lsk = t.lsk);

      --����� �� �����-������
      update nabor k
         set k.vol = 0, k.vol_add = 0
       where k.usl = p_usl
         and exists (select *
                from nabor n, kart t
               where n.lsk = k.lsk
                 and n.lsk = t.lsk
                 and t.psch not in (8, 9)
                 and n.usl = p_usl
                 and t.house_id = p_house);
      --����� �� ��������� �������
      update nabor k
         set k.vol = 0, k.vol_add = 0
       where k.usl = p_usl_chld
         and exists (select *
                from nabor n, kart t
               where n.lsk = k.lsk
                 and n.lsk = t.lsk
                 and t.psch not in (8, 9)
                 and n.usl = p_usl
                 and t.house_id = p_house);
      --��������� ��������� (�����������)
      update c_vvod t set t.nrm=null where t.house_id=p_house and t.usl=p_usl;
    end if;
    logger.log_(l_time1,
                '��������� �������: p_vvod.gen_clear_odn p_house='||p_house||', p_vvod='||p_vvod);

  end;

  --������������ ��� �� ������, ��� ��� ����
  procedure gen_dist_wo_vvod_usl(p_vvod in c_vvod.id%type) is
    fk_usl_chld_ usl.usl%type;
    fk_calc_tp_  number;
    sptarn_      number;
    l_kpr        number;
    l_cnt        number;
    tp_          number;
    l_rate       number; --�������� �� ���
    l_area_prop  number; --������� ������ ��������� ����
    l_limit_vol  number; --���������� ����� ��� �� ���������������� (�����)
    l_usl        c_vvod.usl%type; --������
    l_house      c_vvod.house_id%type; --id ����
    l_nrm_kpr    number; --���-�� ����� �� ���������
    l_sch_kpr    number; --���-�� ����� �� ��������
    --����������� �����
    l_kub_nrm_fact number;
    l_kub_sch_fact number;
    l_kub_fact     number;
    l_opl_add      number;
    l_edt_norm number;
    type rec_cnt is record(
      vol     number,
      vol_add number);
    l_rec_cnt rec_cnt;
    l_odn_nrm number; --����������� �� ��� (��� �������� ����������)
    l_time1 date;
  begin
    l_time1 := sysdate;
    --������������� ��� �� �����, � ������� ��� �������� �.�.
    --(��� �� �������)

    --��� ������� ������
    select nvl(u.fk_calc_tp, 0), u.fk_usl_chld, u.usl, d.house_id, d.edt_norm
      into fk_calc_tp_, fk_usl_chld_, l_usl, l_house, l_edt_norm
      from usl u, c_vvod d
     where u.usl = d.usl
       and d.id = p_vvod;
    select nvl(u.sptarn, 0) into sptarn_ from usl u where u.usl = l_usl;

    --���������� ����� �� �����������, �� �����
    c_kart.set_part_kpr_vvod(p_vvod);

    if fk_calc_tp_ in (3, 17, 38) then
      tp_ := 0; --�.�.
    elsif fk_calc_tp_ in (4, 18, 40) then
      tp_ := 1; --�.�.
    elsif fk_calc_tp_ in (31) then
      tp_ := 2; --��.��.
    end if;

    ---������� ���������� ���-------------------------
    gen_clear_odn(p_usl      => l_usl,
                  p_usl_chld => fk_usl_chld_,
                  p_house    => null,
                  p_vvod     => p_vvod);

    if tp_ in (0, 1) then
      --�.�. ��� �.�.
      --���-�� �����������
      select nvl(sum(e.kpr2), 0) as kpr,
             sum(case
                   when nvl(e.sch, 0) <> 0 then
                    e.kpr2
                   else
                    0
                 end),
             sum(case
                   when nvl(e.sch, 0) = 0 then
                    e.kpr2
                   else
                    0
                 end)
        into l_kpr, l_sch_kpr, l_nrm_kpr
        from kart k, nabor n, c_charge_prep e
       where k.lsk = n.lsk
         and k.lsk = e.lsk
            --    and k.house_id=l_house
         and n.fk_vvod = p_vvod
         and n.usl = e.usl
         and n.usl = l_usl
         and k.psch not in (8, 9)
         and e.tp = 6 --���� ��� ���
         and k.status not in (9) /*��� �����������*/
      ;

    elsif tp_ = 2 then
      --�� ��.��. - �� ����������
      --��� ��� ����� = ������� ������ ��������� * 2.7 ���.
      begin
        --������� ���.����., ��������, ����� �� �������
        select x.n1, 2.7, nvl(round(x.n1 * 2.7, 4), 0)
          into l_area_prop, l_rate, l_limit_vol
          from t_objxpar x, v_house_pars u, c_houses h
         where x.fk_list = u.id
           and x.fk_k_lsk = h.k_lsk_id
           and h.id = l_house
           and u.cd = 'area_general_property'
           and not exists
         (select *
                  from t_objxpar x, v_house_pars u, c_houses h
                 where x.fk_list = u.id
                   and x.fk_k_lsk = h.k_lsk_id
                   and h.id = l_house
                   and u.cd = 'exist_lift'
                   and nvl(x.n1, 0) = 1

                );
         l_odn_nrm:=2.7;
      exception
        when no_data_found then
          l_limit_vol := 0;
      end;

      if l_limit_vol = 0 then
        --������ ��� � ������
        begin
          --������� ���.����., ��������, ����� �� �������
          select x.n1, 4.1, nvl(round(x.n1 * 2.7, 4), 0)
            into l_area_prop, l_rate, l_limit_vol
            from t_objxpar x, v_house_pars u, c_houses h
           where x.fk_list = u.id
             and x.fk_k_lsk = h.k_lsk_id
             and h.id = l_house
             and u.cd = 'area_general_property'
             and exists
           (select *
                    from t_objxpar x, v_house_pars u, c_houses h
                   where x.fk_list = u.id
                     and x.fk_k_lsk = h.k_lsk_id
                     and h.id = l_house
                     and u.cd = 'exist_lift'
                     and nvl(x.n1, 0) = 1

                  );
         l_odn_nrm:=4.1;
        exception
          when no_data_found then
            l_limit_vol := 0;
        end;
      end if;
      null;

    end if;

    if tp_ in (0, 1) and l_kpr <> 0 or tp_ in (2) then
      --���� ���-�� ����������� <>0, �� ����� ����� (��� �.�. � �.�., �� �� ��� ��.��.)
      for c in (select sum(k.opl) as opl,
                       case
                         when tp_ in (0, 1) then
                          opl_liter(sum(k.opl) / l_kpr) / 1000 --����� ��� �� �/�. �.�. � �.�.
                         when tp_ = 2 then
                          null --����� ��� �� �/�. ��.��.
                       end as vl
                  from kart k, nabor n
                 where k.house_id = l_house
                   and k.lsk=n.lsk
                   and n.usl=fk_usl_chld_
                   and k.psch not in (8, 9) --��� �����������
                   and nvl(k.opl, 0) <> 0) loop
        l_opl_add := c.opl;
        update nabor n
           set n.vol_add =
               (select case
                         when tp_ in (0, 1) then
                          round(k.opl * c.vl, 3)
                         when tp_ = 2 then
                          round(l_rate * l_area_prop * k.opl / c.opl, 3) --����� ��� �� �/�. ��.��.
                       end
                  from kart k
                 where k.lsk = n.lsk)
         where exists (select *
                  from kart t, nabor r
                 where t.lsk = n.lsk
                   and t.lsk = r.lsk
                   and r.fk_vvod = p_vvod
                   and nvl(t.opl, 0) <> 0)
           and n.usl = fk_usl_chld_;
        --�������� ���� �� ���.
        insert into c_charge
          (lsk, usl, test_opl, type)
          select k.lsk,
                 fk_usl_chld_,
                 case
                   when tp_ in (0, 1) then
                    round(k.opl * c.vl, 3)
                   when tp_ = 2 then
                    round(l_rate * l_area_prop * k.opl / c.opl, 3) --����� ��� �� �/�. ��.��.
                 end as test_opl,
                 5 as type
            from kart k, nabor n
           where k.lsk = n.lsk
             and n.usl = fk_usl_chld_
             and exists (select *
                    from kart t, nabor r
                   where t.lsk = n.lsk
                     and t.lsk = r.lsk
                     and r.fk_vvod = p_vvod
                     and nvl(t.opl, 0) <> 0);

        select nvl(sum(n.vol_add), 0)
          into l_cnt
          from nabor n
         where n.fk_vvod = p_vvod
           and n.usl = l_usl;
        l_odn_nrm:=c.vl*1000;--������� � �����
        --���������� -- ����� �� �����
      end loop;

      --�������� ����������� ������������
      select nvl(sum(case
                           when k.psch in (1, 2) and fk_calc_tp_ in (3, 17, 38) then
                            0
                           when k.psch in (1, 3) and fk_calc_tp_ in (4, 18, 40) then
                            0
                           when k.psch in (0, 3) and fk_calc_tp_ in (3, 17, 38) then
                            n.test_opl
                           when k.psch in (0, 2) and fk_calc_tp_ in (4, 18, 40) then
                            n.test_opl
                           when k.sch_el in (0) and fk_calc_tp_ in (31) then
                            n.test_opl
                         end),
                     0),
                 nvl(sum(case
                           when k.psch in (1, 2) and fk_calc_tp_ in (3, 17, 38) then
                            n.test_opl
                           when k.psch in (1, 3) and fk_calc_tp_ in (4, 18, 40) then
                            n.test_opl
                           when k.psch in (0, 3) and fk_calc_tp_ in (3, 17, 38) then
                            0
                           when k.psch in (0, 2) and fk_calc_tp_ in (4, 18, 40) then
                            0
                           when k.sch_el in (1) and fk_calc_tp_ in (31) then
                            n.test_opl
                         end),
                     0)
        into l_rec_cnt
        from kart k, c_charge n
       where k.lsk = n.lsk
         and k.psch not in (8, 9)
         and n.usl = fk_usl_chld_
         and n.type = 5
         and exists (select *
                from nabor r, kart t
               where n.lsk = r.lsk
                 and r.lsk = t.lsk
                 and t.psch not in (8, 9)
                 and r.fk_vvod = p_vvod
                 and r.usl = l_usl);
      --�����
      l_kub_nrm_fact := l_rec_cnt.vol;
      l_kub_sch_fact := l_rec_cnt.vol_add;
      l_kub_fact     := l_kub_nrm_fact + l_kub_sch_fact;

      update c_vvod t
         set t.kub_nrm_fact = l_kub_nrm_fact,
             t.kub_sch_fact = l_kub_sch_fact,
             t.kub_sch      = null,
             t.sch_cnt      = null,
             t.sch_kpr      = l_sch_kpr,
             t.kpr          = l_nrm_kpr,
             t.cnt_lsk      = null,
             t.kub_norm     = null,
             t.kub_fact     = l_kub_fact,
             t.kub_man      = null,
             t.kub_dist     = null,
             t.opl_add      = l_opl_add,
             t.nrm          = l_odn_nrm
       where t.id = p_vvod;
    end if;
      logger.log_(l_time1,
                '������������: p_vvod.gen_dist_wo_vvod_usl, p_vvod='||p_vvod);

    --����� ������
    --commit;
  end;

  --����������� ���� (�� ���������)
  procedure gen_vvod(p_vvod_id in number) is
  begin
    for c in (select d.* from c_vvod d where d.id=p_vvod_id
        )
      loop
        if c.dist_tp in (4,5) then
        --������������ �����, ���� ��� ����
        p_vvod.gen_dist_wo_vvod_usl(c.id);
        else
        --������������ �����, ���� ���� ����
        p_vvod.gen_dist(p_klsk => c.fk_k_lsk,
                        p_dist_tp => c.dist_tp,
                        p_usl => c.usl,
                        p_use_sch => c.use_sch,
                        p_old_use_sch => c.use_sch,
                        p_kub_nrm_fact => c.kub_nrm_fact,
                        p_kub_sch_fact => c.kub_sch_fact,
                        p_kub_ar_fact => c.kub_ar_fact,
                        p_kub_ar => c.kub_ar,
                        p_opl_ar => c.opl_ar,
                        p_kub_sch => c.kub_sch,
                        p_sch_cnt => c.sch_cnt,
                        p_sch_kpr => c.sch_kpr,
                        p_kpr => c.kpr,
                        p_cnt_lsk => c.cnt_lsk,
                        p_kub_norm => c.kub_norm,
                        p_kub_fact => c.kub_fact,
                        p_kub_man => c.kub_man,
                        p_kub => c.kub,
                        p_edt_norm => c.edt_norm,
                        p_kub_dist => c.kub_dist,
                        p_id => c.id,
                        p_house_id => c.house_id,
                        p_opl_add => c.opl_add,
                        p_old_kub => c.kub,
                        p_limit_proc => c.limit_proc,
                        p_old_limit_proc => c.limit_proc,
                        p_gen_part_kpr => 1,
                        p_wo_limit => c.wo_limit
                        );
      end if;
      end loop;
      commit;
 end;


  procedure gen_test_one_vvod(p_cur_dt  in date,
                              p_vvod_id in c_vvod.id%type) is
    l_cnt number;
    a     number;
  begin
    --�������� ������������� �� ������ ���������� �����

    --���� ����� ��� ����������
    a := init.set_date(p_cur_dt);
    for c in (select d.* from c_vvod d where d.id = p_vvod_id) loop
      p_vvod.gen_dist(p_klsk           => c.fk_k_lsk,
                      p_dist_tp        => c.dist_tp,
                      p_usl            => c.usl,
                      p_use_sch        => c.use_sch,
                      p_old_use_sch    => c.use_sch,
                      p_kub_nrm_fact   => c.kub_nrm_fact,
                      p_kub_sch_fact   => c.kub_sch_fact,
                      p_kub_ar_fact    => c.kub_ar_fact,
                      p_kub_ar         => c.kub_ar,
                      p_opl_ar         => c.opl_ar,
                      p_kub_sch        => c.kub_sch,
                      p_sch_cnt        => c.sch_cnt,
                      p_sch_kpr        => c.sch_kpr,
                      p_kpr            => c.kpr,
                      p_cnt_lsk        => c.cnt_lsk,
                      p_kub_norm       => c.kub_norm,
                      p_kub_fact       => c.kub_fact,
                      p_kub_man        => c.kub_man,
                      p_kub            => c.kub,
                      p_edt_norm       => c.edt_norm,
                      p_kub_dist       => c.kub_dist,
                      p_id             => c.id,
                      p_house_id       => c.house_id,
                      p_opl_add        => c.opl_add,
                      p_old_kub        => c.kub,
                      p_limit_proc     => c.limit_proc,
                      p_old_limit_proc => c.limit_proc,
                      p_gen_part_kpr   => 1,
                      p_wo_limit       => c.wo_limit);
      commit;
    end loop;
  end;

  procedure del_broken_sch_all is
    a number;
  begin
    if utils.get_int_param('VER_METER1') <> 0 then
      Raise_application_error(-20000, '������� �� �������� � ����� ������!');
    end if;
    --����� ������� ��������� � ����������� �� �������� ��������/���
    --�� ���� �������
    --(������ ���������� �� ��������� ������������)
    for c in (select u.usl from usl u where u.counter is not null) loop
      del_broken_sch(c.usl);
    end loop;
  end;

  procedure del_broken_sch(p_usl in usl.usl%type) is
    l_counter varchar2(100);
    cursor c is
      select substr(b.lsk, 1, 8) as lsk,
             b.state,
             b.dt1 as dt1,
             case
               when to_char(b.dt1, 'YYYYMM') <> p.period then
                to_date(p.period || '01', 'YYYYMMDD')
               else
                b.dt1
             end as dt2,
             b.psch,
             months_between(to_date(p.period || '01', 'YYYYMMDD'), b.dt1) as cnt_months
        from (select max(t.lsk) as lsk,
                     max(a.cd) keep(dense_rank last order by t.dt1) as state,
                     max(t.dt1) keep(dense_rank last order by t.dt1) as dt1,
                     max(k.psch) keep(dense_rank last order by t.dt1) as psch
                from kart k, c_reg_sch t, u_list a
               where t.fk_state = a.id
                 and k.lsk = t.lsk
                 and (k.psch in (1, 2) and l_counter = 'phw' or
                     (k.psch in (1, 3) and l_counter = 'pgw') or
                     (k.sch_el = 1 and l_counter = 'pel'))
                 and exists (select *
                        from u_list u
                       where u.cd = '������� ��'
                         and u.id = t.fk_tp)
                 and t.fk_usl = p_usl
               group by t.lsk, t.fk_usl) b,
             params p
       where b.state = '���������� ��';

 --������ 6 ���.�� ���� �������� �������
  cursor c2 is
  select k.lsk, k.psch, to_date(p.period || '01', 'YYYYMMDD') as dt2
     from scott.kart k, scott.params p where not exists (
    select t.*
      from scott.t_objxpar t, scott.u_list s, scott.u_listtp tp, scott.params p
     where t.fk_list = s.id
       and t.tp =0
       and s.fk_listtp=tp.id
       and tp.cd='��������� ���.�����'
       and t.fk_usl=p_usl
       and s.cd='ins_vol_sch'
       and nvl(t.n1,0)>0
       and k.psch not in (8,9)
       and t.mg>=to_char(add_months(to_date(p.period || '01', 'YYYYMMDD'),-6),'YYYYMM') --����� �� 6 �������
       and t.fk_lsk=k.lsk
    )
    and (k.psch in (1, 2) and l_counter = 'phw' or
        (k.psch in (1, 3) and l_counter = 'pgw') or
        (k.sch_el = 1 and l_counter = 'pel'));

    l_rec    c%rowtype;
    l_rec2    c2%rowtype;
    l_res    number;
    l_usl_nm varchar2(100);
  begin
    if utils.get_int_param('VER_METER1') <> 0 then
      Raise_application_error(-20000, '������� �� �������� � ����� ������!');
    end if;
    --�� ��������, �� ��������� N �������, �� �� ����� ��� �� ��������� 3 ���.
    select trim(t.counter), trim(t.nm)
      into l_counter, l_usl_nm
      from usl t
     where t.usl = p_usl;

    --���������� ��� �������� � ��������, ���� �������� ������������
    open c;
    loop
      fetch c
        into l_rec;
      exit when c%notfound;
      if l_rec.cnt_months > 2 then
        --������ ��� 2 ������ ���������� ������ �����
        if l_counter = 'phw' then
          l_res := utils.set_krt_psch(dat_       => l_rec.dt2,
                                      fk_status_ => case
                                                      when l_rec.psch = 1 then
                                                       3
                                                      when l_rec.psch = 2 then
                                                       0
                                                    end,
                                      lsk_       => l_rec.lsk);
          if l_res <> 1 then
            raise_application_error(-20000,
                                    '������ ������ ������� ����� �� ������: ' ||
                                    l_usl_nm || ', � �/� ' || l_rec.lsk);
          end if;
          logger.log_act(l_rec.lsk,
                         '���������� �/�: ' || l_rec.lsk ||
                         ' ����������� ������� �� ������: ' || l_usl_nm ||
                         ', >= 3 ������, ���������� ��������',
                         2);
        elsif l_counter = 'pgw' then
          l_res := utils.set_krt_psch(dat_       => l_rec.dt2,
                                      fk_status_ => case
                                                      when l_rec.psch = 1 then
                                                       2
                                                      when l_rec.psch = 3 then
                                                       0
                                                    end,
                                      lsk_       => l_rec.lsk);
          if l_res <> 1 then
            raise_application_error(-20000,
                                    '������ ������ ������� ����� �� ������: ' ||
                                    l_usl_nm || ', � �/�' || l_rec.lsk);
          end if;
          logger.log_act(l_rec.lsk,
                         '���������� �/�: ' || l_rec.lsk ||
                         ' ����������� ������� �� ������: ' || l_usl_nm ||
                         ', >= 3 ������, ���������� ��������',
                         2);
        elsif l_counter = 'pel' then
          update kart k set k.sch_el = 0 where k.lsk = l_rec.lsk;
          logger.log_act(l_rec.lsk,
                         '���������� �/�: ' || l_rec.lsk ||
                         ' ����������� ������� �� ������: ' || l_usl_nm ||
                         ', >= 3 ������, ���������� ��������',
                         2);
        end if;
      else
        -- <= 2 ������ ���������� ������ �����
        --������ ������ ������, ���� ����� (��� ��������������, - ���������� �� ��������)
        if l_counter = 'phw' then
          update kart k set k.mhw = 0 where k.lsk = l_rec.lsk;
          logger.log_act(l_rec.lsk,
                         '���������� �/�: ' || l_rec.lsk ||
                         ' ����������� ������� �� ������: ' || l_usl_nm ||
                         ', < 3 ������, ��������� �� ��������',
                         2);
        elsif l_counter = 'pgw' then
          update kart k set k.mgw = 0 where k.lsk = l_rec.lsk;
          logger.log_act(l_rec.lsk,
                         '���������� �/�: ' || l_rec.lsk ||
                         ' ����������� ������� �� ������: ' || l_usl_nm ||
                         ', < 3 ������, ��������� �� ��������',
                         2);
        elsif l_counter = 'pel' then
          update kart k set k.mel = 0 where k.lsk = l_rec.lsk;
          logger.log_act(l_rec.lsk,
                         '���������� �/�: ' || l_rec.lsk ||
                         ' ����������� ������� �� ������: ' || l_usl_nm ||
                         ', < 3 ������, ��������� �� ��������',
                         2);
        end if;

      end if;
    end loop;
    close c;


    --���������� ��� �������� � ��������, ���� �� ���� �������� ��������� �� ���
    open c2;
    loop
      fetch c2
        into l_rec2;
      exit when c2%notfound;
        if l_counter = 'phw' then
          l_res := utils.set_krt_psch(dat_       => l_rec2.dt2,
                                      fk_status_ => case
                                                      when l_rec2.psch = 1 then
                                                       3
                                                      when l_rec2.psch = 2 then
                                                       0
                                                    end,
                                      lsk_       => l_rec2.lsk);
          if l_res <> 1 then
            raise_application_error(-20000,
                                    '������ ������ ������� ����� �� ������: ' ||
                                    l_usl_nm || ', � �/� ' || l_rec2.lsk);
          end if;
          logger.log_act(l_rec2.lsk,
                         '���������� �/�: ' || l_rec2.lsk ||
                         ' �� �������� �� ���������� ��������� >= 6 �������, �� ������: ' || l_usl_nm ||
                         ' ���������� ��������',
                         2);
        elsif l_counter = 'pgw' then
          l_res := utils.set_krt_psch(dat_       => l_rec2.dt2,
                                      fk_status_ => case
                                                      when l_rec2.psch = 1 then
                                                       2
                                                      when l_rec2.psch = 3 then
                                                       0
                                                    end,
                                      lsk_       => l_rec2.lsk);
          if l_res <> 1 then
            raise_application_error(-20000,
                                    '������ ������ ������� ����� �� ������: ' ||
                                    l_usl_nm || ', � �/�' || l_rec2.lsk);
          end if;
          logger.log_act(l_rec2.lsk,
                         '���������� �/�: ' || l_rec2.lsk ||
                         ' �� �������� �� ���������� ��������� >= 6 �������, �� ������: ' || l_usl_nm ||
                         ' ���������� ��������',
                         2);
        elsif l_counter = 'pel' then
          update kart k set k.sch_el = 0 where k.lsk = l_rec2.lsk;
          logger.log_act(l_rec2.lsk,
                         '���������� �/�: ' || l_rec2.lsk ||
                         ' �� �������� �� ���������� ��������� >= 6 �������, �� ������: ' || l_usl_nm ||
                         ' ���������� ��������',
                         2);
        end if;
  end loop;
  close c2;

  end;

  function gen_auto_chrg_all(p_set in number, p_usl in usl.usl%type)
    return number is
    l_counter usl.counter%type;
    l_mg1     params.period%type;
    l_mg2     params.period%type;
    l_cnt     t_objxpar.n1%type;
    l_tp      t_objxpar.tp%type;
    l_ret     number;
    l_months  spr_params.parn1%type;
    l_usl_nm  varchar2(100);
    l_otop    number; --������.������
  begin
    if utils.get_int_param('VER_METER1') <> 0 then
      Raise_application_error(-20000, '������� �� �������� � ����� ������!');
    end if;

    begin
    logger.log_(null, 'p_vvod.gen_auto_chrg_all ������');
    --���������� ���������� ���������� - ������� �������������� (����� ������� ��� ���� g_tp=3)
    g_tp := 1;
    --����� ������� ����������� ���������
    if utils.get_int_param('DEL_BRK_SCH')=1 then
      del_broken_sch(p_usl);
    end if;
    --����� ���������� ����������
    g_tp := 0;

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
      --������������� �� ��������
      --������, �� ���� ����� �� �������� ������
      select to_char(add_months(to_date(p.period || '01', 'YYYYMMDD'),
                                -1 * l_months),
                     'YYYYMM'),
             to_char(add_months(to_date(p.period || '01', 'YYYYMMDD'), -1),
                     'YYYYMM')
        into l_mg1, l_mg2
        from params p;

      --����� ����������� �������� (���������� � ���������)
      if utils.get_int_param('DEL_BRK_SCH')=1 then  --������ ������????
        del_broken_sch(p_usl);
      end if;

      --���������� ���������� ���������� - ������� ��������������
      g_tp := 1;

      for c in (select a.lsk,
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
                  from arch_kart a
                 where a.mg between l_mg1 and l_mg2
                   and (l_otop = 0 and l_counter = 'pgw' and not exists --������������ ����� �� ����.��������� (������ ��� �.�.!!!)
                        (select *
                           from kart k
                          where k.lsk = a.lsk
                            and k.kran1 = 1) or
                        l_otop = 1 and l_counter = 'pgw' or
                        l_counter <> 'pgw')
                   and exists
                 (select *
                          from kart k
                         where k.k_lsk_id = a.k_lsk_id -- and k.lsk='04002933'
                           and ((k.psch in (1, 2) and l_counter = 'phw' and
                               nvl(k.mhw, 0) = 0) or
                               (k.psch in (1, 3) and l_counter = 'pgw' and
                               nvl(k.mgw, 0) = 0) or
                               (k.sch_el = 1 and l_counter = 'pel') and
                               nvl(k.mel, 0) = 0)

                           and k.psch not in (8, 9))
                 group by a.lsk) loop
        --��������!, ���������� ��� ���, ���� ����� ������������ ������������� �� �������!
        if l_counter = 'phw' then
          --������������� �� �.�.
          if c.m_hw >= 3 and c.cnt_hw > 0 then
            --�� ����� 3 ������� �������
            l_ret := 0;
            update kart k
               set k.phw = nvl(k.phw, 0) + round(c.cnt_hw / c.m_hw, 3)
             where k.lsk = c.lsk;
          end if;
        elsif l_counter = 'pgw' then
          --������������� �� �.�.
          if c.m_gw >= 3 and c.cnt_gw > 0 then
            --�� ����� 3 ������� �������
            l_ret := 0;
            update kart k
               set k.pgw = nvl(k.pgw, 0) + round(c.cnt_gw / c.m_gw, 3)
             where k.lsk = c.lsk;
          end if;
        elsif l_counter = 'pel' then
          --������������� �� ��.��.
          if c.m_el >= 3 and c.cnt_el > 0 then
            --�� ����� 3 ������� �������
            l_ret := 0;
            update kart k
               set k.pel = nvl(k.pel, 0) + round(c.cnt_el / c.m_el, 3)
             where k.lsk = c.lsk;
          end if;
        end if;
      end loop;
    elsif p_set = 0 then
      --����� �������������� (������) (��������� ��������)
      --���������� ���������� ���������� - ������� ������ ��������������
      g_tp := 2;

      for c in (select t.fk_lsk, max(t.id) as max_id
                  from t_objxpar t, params p, u_list s, u_listtp tp
                 where t.mg = p.period
                   and tp.id = s.fk_listtp
                   and tp.cd = '��������� ���.�����'
                   and s.cd = 'ins_vol_sch'
                   and t.fk_list = s.id
                   and t.fk_usl = p_usl
                   and t.tp in (1, 2) --��� - �������������, ������ ����������.
                --         and exists (select * from kart k where k.kran1=1 and k.lsk=t.fk_lsk)  �������� ���� ����� �������� �� ����. ���������
                 group by t.fk_lsk) loop
        select t.tp, nvl(t.n1, 0)
          into l_tp, l_cnt
          from t_objxpar t
         where t.id = c.max_id;

        --��������!, ���������� ��� ���, ���� ����� ������������ ������������� �� �������!
        if l_tp = 1 and l_cnt <> 0 then
          l_ret := 0;
          --����������� �������� ������ ��������������!
          --(�� ������ ���, � �� ������ ����)
          if l_counter = 'phw' then
            --����� �������������� �� �.�.
            update kart k
               set k.phw = nvl(k.phw, 0) - l_cnt
             where k.lsk = c.fk_lsk
               and k.psch in (1, 2);
          elsif l_counter = 'pgw' then
            --����� �������������� �� �.�.
            update kart k
               set k.pgw = nvl(k.pgw, 0) - l_cnt
             where k.lsk = c.fk_lsk
               and k.psch in (1, 3);
          elsif l_counter = 'pel' then
            --����� �������������� �� ��.��.
            update kart k
               set k.pel = nvl(k.pel, 0) - l_cnt
             where k.lsk = c.fk_lsk
               and k.sch_el in (1);
          end if;
        end if;
      end loop;

    end if;
    --����� ���������� ���������� - ������� ��������������
    g_tp := 0;
    commit;
    if p_set = 1 then
      logger.log_(null,
                  'p_vvod.gen_auto_chrg_all ���������-������������� �� ��������');
    elsif p_set = 0 then
      logger.log_(null,
                  'p_vvod.gen_auto_chrg_all ���������-������:�������������� �� ��������');
    end if;
    exception when others then
      --���� ������ - ����� ���������� ���������� - ������� ��������������, ����� ��� �������� �� ���� ������� ��������� (���� �� ����� �� ���������)
      g_tp := 0;
      raise;
    end;

    return l_ret;
  end;

  function opl_liter(p_opl_man in number) return number is
  begin
    --������� ��� �������� ��������� ����������� (� ������) �� �����.������� �� ��������
    case round(p_opl_man)
      when 1 then
        return 2;
      when 2 then
        return 2;
      when 3 then
        return 2;
      when 4 then
        return 10;
      when 5 then
        return 10;
      when 6 then
        return 10;
      when 7 then
        return 10;
      when 8 then
        return 10;
      when 9 then
        return 10;
      when 10 then
        return 9;
      when 11 then
        return 8.2;
      when 12 then
        return 7.5;
      when 13 then
        return 6.9;
      when 14 then
        return 6.4;
      when 15 then
        return 6.0;
      when 16 then
        return 5.6;
      when 17 then
        return 5.3;
      when 18 then
        return 5.0;
      when 19 then
        return 4.7;
      when 20 then
        return 4.5;
      when 21 then
        return 4.3;
      when 22 then
        return 4.1;
      when 23 then
        return 3.9;
      when 24 then
        return 3.8;
      when 25 then
        return 3.6;
      when 26 then
        return 3.5;
      when 27 then
        return 3.3;
      when 28 then
        return 3.2;
      when 29 then
        return 3.1;
      when 30 then
        return 3.0;
      when 31 then
        return 2.9;
      when 32 then
        return 2.8;
      when 33 then
        return 2.7;
      when 34 then
        return 2.6;
      when 35 then
        return 2.6;
      when 36 then
        return 2.5;
      when 37 then
        return 2.4;
      when 38 then
        return 2.4;
      when 39 then
        return 2.3;
      when 40 then
        return 2.3;
      when 41 then
        return 2.2;
      when 42 then
        return 2.1;
      when 43 then
        return 2.1;
      when 44 then
        return 2;
      when 45 then
        return 2;
      when 46 then
        return 2;
      when 47 then
        return 1.9;
      when 48 then
        return 1.9;
      when 49 then
        return 1.8;
      else
        return 1.8;
    end case;
  end;

  function create_vvod (house_id_ c_houses.id%TYPE, usl_ c_vvod.usl%TYPE,
    num_ c_vvod.vvod_num%TYPE)
           RETURN number is
    cnt_ number;
    id_ c_vvod.id%type;
  begin
  --�������� ����� �� ����
    select count(*) into cnt_
      from c_vvod c where c.house_id=house_id_ and c.usl=usl_
        and c.vvod_num=num_;
    if cnt_ = 0 then
      --������� ����
      insert into c_vvod(house_id, usl, vvod_num)
        values (house_id_, usl_, num_)
        returning id into id_;
      commit;
      return id_;
    else
      --������ ���� ��� ���������� � ����!
      return -1;
    end if;
  end;

  function delete_vvod (id_ c_vvod.id%TYPE)
           RETURN number is
    cnt_ number;
  begin
  --�������� ����� �� ����
    select count(*) into cnt_
      from c_vvod c where c.id=id_;
    if cnt_ = 1 then
      --������� ����
      begin
       delete from c_vvod c where c.id=id_;
      exception
      when others then
        raise_application_error(-20001,
                                '������ ���� ������������, ������� ��� ������ � ��������� �� ����!');
      end;
      commit;
      return 0;
    else
      --������ ���� �� ���������� � ����!
      return 1;
    end if;
  end;

  --������� ������� ��� klsk ���� (��� ��� ���)
  function create_vvod_by_house_klsk (p_klsk number, p_num c_vvod.vvod_num%TYPE)
           RETURN number is
    l_vvod_klsk number;
  begin
    begin
      --���������� ������� ���������
      select d.fk_k_lsk into l_vvod_klsk
        from c_houses h, c_vvod d where h.k_lsk_id=p_klsk and d.usl is null
          and d.vvod_num=p_num and d.house_id=h.id;
    exception
    when NO_DATA_FOUND then
      --����� ���, �������
      for c in (select h.id from c_houses h where h.k_lsk_id=p_klsk)
      loop
        insert into c_vvod(house_id, vvod_num)
          values (c.id, p_num)
          returning fk_k_lsk into l_vvod_klsk;
        exit;
      end loop;
   end;
   --������� klsk �����
   return l_vvod_klsk;

  end;

end p_vvod;
/

