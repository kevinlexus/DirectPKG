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
                     p_gen_part_kpr   in number, --пересчитывать ли доли проживающих (обычно из триггера) (и начисление)
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

    type rec_ar_sch is record( --Арендаторы
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
    use_sch_     number; --УСТАРЕВАЕТ, УДАЛИТЬ ПОСЛЕ 15.10.12
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
    l_vol        number; --временная переменная для распр.экономии
    l_lsk_round  nabor.lsk%type; --временные переменные для округления небаланса
    l_vol_round  number; --временные переменные для округления небаланса
    l_flag       number;
    l_limit_vol  number; --допустимый лимит ОДН по законодательству (общий)

    l_area_prop  number; --площадь общего имущества дома
    l_rate       number; --норматив по ОДН
    l_limit_area number; --допустимый лимит ОДН на 1 м2

    l_opl_man   number; -- площадь на одного проживающего на 1 чел., для расчета ограничения
    l_opl_liter number; --кол-во литров на метр2 по таблице, для расчета ограничения
    l_usl_cd    usl.cd%type;
    l_cnt       number;
    --переменная для округления
    l_for_round number;
    l_time date;
    l_odn_nrm number; --ограничение по ОДН (еще называют нормативом)
    l_kub_fact_upnorm number; -- объем свыше норматива по ОДН
    cursor cur1 is --курсор для расчета экономии
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

             f.vol as vol_add, --объем по счетчику
             d.vol as vol, --объем по нормативу
             nvl(f.vol, 0) + nvl(d.vol, 0) as lsk_vl --общий объем
        from kart k, nabor n, c_charge_prep f, c_charge_prep d
       where k.lsk = n.lsk
         and n.lsk = f.lsk(+)
         and n.usl = f.usl(+)
         and f.tp(+) = 6 --итог по счетчику итог без ОДН
         and f.sch(+) = 1
         and n.lsk = d.lsk(+)
         and n.usl = d.usl(+)
         and d.tp(+) = 6 --итог по нормативу итог без ОДН
         and d.sch(+) = 0
         and n.fk_vvod = p_id
         and n.usl = p_usl
         and k.psch not in (8, 9)
         and nvl(f.vol, 0) + nvl(d.vol, 0) > 0; --там, где вообще есть объемы > 0

    cursor cur2 is --курсор для расчета экономии, без счетчиков
      select k.lsk,
             round(nvl((p_kub_dist - all_kub_) / all_kpr_, 0) *
                   nvl(d.kpr2, 0),
                   3) as dist_vl,
             0 as vol_add, --объем по счетчику (нельзя NULL - логика меняется)
             d.vol as vol, --объем по нормативу
             nvl(d.vol, 0) as lsk_vl --общий объем
        from kart k, nabor n, c_charge_prep d
       where k.lsk = n.lsk
         and n.lsk = d.lsk(+)
         and n.usl = d.usl(+)
         and d.tp(+) = 6 --итог по нормативу итог без ОДН
         and d.sch(+) = 0
         and n.fk_vvod = p_id
         and n.usl = p_usl
         and k.psch not in (8, 9)
         and nvl(d.vol, 0) > 0 --там, где вообще есть объемы > 0
         and not exists (select *
                from c_charge_prep e
               where n.lsk = e.lsk
                 and n.usl = e.usl
                 and e.tp = 7 --где нет наличия счетчика в тек.периоде
                 and e.sch = 1);

    cursor cur3 is --курсор для расчета экономии, либо по арендаторам, либо чтобы кто то проживал
      select k.lsk,
             round(nvl((p_kub_dist - all_kub_) / all_kpr_, 0) *
                   (nvl(d.kpr2, 0) + decode(use_sch_, 1, nvl(f.kpr2, 0), 0)),
                   3) as dist_vl,

             f.vol as vol_add, --объем по счетчику
             d.vol as vol, --объем по нормативу
             nvl(f.vol, 0) + nvl(d.vol, 0) as lsk_vl --общий объем
        from kart k, nabor n, c_charge_prep f, c_charge_prep d
       where k.lsk = n.lsk
         and n.lsk = f.lsk(+)
         and n.usl = f.usl(+)
         and f.tp(+) = 6 --итог по счетчику итог без ОДН
         and f.sch(+) = 1
         and n.lsk = d.lsk(+)
         and n.usl = d.usl(+)
         and d.tp(+) = 6 --итог по нормативу итог без ОДН
         and d.sch(+) = 0
         and n.fk_vvod = p_id
         and n.usl = p_usl
         and k.psch not in (8, 9)
         and nvl(f.vol, 0) + nvl(d.vol, 0) > 0 --там, где вообще есть объемы > 0
         and (k.status = 9 or exists
              (select *
                 from c_charge_prep e
                where k.lsk = e.lsk
                  and e.usl = p_usl
                  and e.tp = 6 --итог без ОДН
                  and e.kpr2 <> 0));
    rec cur1%rowtype;
    -- распределение на Java?
    l_Java_Charge number;
  begin

    --распределение воды по вводу с поддержкой последней редакции 307 постановления от 06.05.11
    --(редакция приложения № 3) взято из http://www.consultant.ru/online/base/?req=doc;base=LAW;n=114247;p=7
    --ИСПОЛЬЗОВАТЬ ТАБЛИЦУ C_VVOD В ЗАПРОСАХ в данном триггере - НЕЛЬЗЯ, ТАК КАК ОНА МУТИРУЕТ

    --ОПРЕДЕЛЕНИЕ:
    --Запись в таблице C_VVOD означает один, общий счетчик,
    --остальные счетчики (например подъездные) должны быть прикреплены к основному через PARENT_ID
    --(пока не реализовано)
    --TO DO: Внести зависимость от обновления параметра площади общего имущества по дому (выполнять перерасчет)
    --сделать, начиная с 01.07.2013


    l_Java_Charge := utils.get_int_param('JAVA_CHARGE');
    if l_Java_Charge=1 then 
      -- вызов Java распределения
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

    --тип распределения по вводу
    dist_tp_ := nvl(p_dist_tp, 0);

    --рассчитать доли объемов, проживающих, для использования в распределении
    --только в тех л.с, которые принадлежат вводу
    if p_gen_part_kpr = 1 then
      c_kart.set_part_kpr_vvod(p_id);
    end if;

    --вид расчета услуги
    begin
      select nvl(u.fk_calc_tp, 0), u.fk_usl_chld, u.cd
        into fk_calc_tp_, fk_usl_chld_, l_usl_cd
        from usl u
       where u.usl = p_usl;
    exception
      when no_data_found then
        Raise_application_error(-20000, 'Ввод id='||p_id||'не содержит корректный код услуги!');
    end;

    select nvl(u.sptarn, 0) into sptarn_ from usl u where u.usl = p_usl;

    --использовать ли счетчики при распределении объема х.в., г.в. (1-да, 0 - нет)
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
        tp_ := 0; --х.в.
      elsif fk_calc_tp_ in (4, 18, 40) then
        tp_ := 1; --г.в.
      elsif fk_calc_tp_ in (31) then
        tp_ := 2; --эл.эн.
      end if;

      --ред.от
      --сумма кубов Х.В./Г.В. по счетчикам, кол-во счетчиков, кол-во людей, площадь
      ---------------------------------------------------
      --------СБОР ИНФОРМАЦИИ ДЛЯ РАСЧЕТА ОДН------------

      if nvl(p_kub, 0) <> 0.001 then
        --p_kub <> 0.001
        --подсчет итогов
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
           and e.sch = 1 --счетчики
           and e.tp = 6 --итог без ОДН
           and k.status not in (9) /*без Арендаторов*/
           /*and exists (select *
                  from nabor r
                 where r.lsk = n.lsk --там где есть услуга ОДН
                   and r.usl = fk_usl_chld_)*/;

        p_kub_sch := rec_sch_.kub_sch;
        p_sch_cnt := rec_sch_.cnt;
        p_sch_kpr := rec_sch_.kpr;

        --кол-во кубов, людей по нормативу, кол-во лицевых, площадь
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
           and e.sch = 0 --нормативщики
           and e.tp = 6 --итог без ОДН
           and k.status not in (9) /*без Арендаторов*/
           /*and exists (select *
                  from nabor r
                 where r.lsk = n.lsk --там где есть услуга ОДН
                   and r.usl = fk_usl_chld_)*/;

        p_kub_norm := rec_norm_.kub_norm;
        p_cnt_lsk  := rec_norm_.cnt_lsk;
        p_kpr      := rec_norm_.kpr;

        --общее кол-во прожив.
        if use_sch_ = 1 then
          all_kpr_ := rec_norm_.kpr + rec_sch_.kpr;
        else
          all_kpr_ := rec_norm_.kpr;
        end if;
        --кол-во кубов, кол-во лицевых, площадь по арендаторам (для пост.354)
        --Юр.лица(арендаторы)

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
           and e.sch = 1 --счетчики
           and e.tp = 6 --итог без ОДН
           and k.status in (9) /*Арендаторы*/
           /*and exists (select *
                  from nabor r
                 where r.lsk = n.lsk --там где есть услуга ОДН
                   and r.usl = fk_usl_chld_)*/;

        --объем арендаторов
        p_kub_ar := rec_ar_sch_.kub;

        --площадь арендаторов
        p_opl_ar := rec_ar_sch_.opl;

        --суммируем расход по вводу
        all_kub_ := rec_sch_.kub_sch + rec_norm_.kub_norm + rec_ar_sch_.kub;

        --суммируем площадь по вводу
        if dist_tp_ <> 3 and use_sch_ = 1 then
          --либо в т.ч. счетчики
          select nvl(sum(k.opl), 0)
            into all_opl_
            from kart k, nabor n
           where k.lsk = n.lsk
             and n.fk_vvod = p_id
             and n.usl = p_usl
             and k.psch not in (8, 9)
             /*and exists (select *
                    from nabor r
                   where r.lsk = n.lsk --там где есть услуга ОДН
                     and r.usl = fk_usl_chld_)*/;

        elsif dist_tp_ <> 3 and use_sch_ = 0 then
          --либо чтобы НЕ были в этом периоде счетчики
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
                     and e.tp = 7 --наличие счетчика в тек.периоде
                     and e.sch = 1)
             /*and exists (select *
                    from nabor r
                   where r.lsk = n.lsk --там где есть услуга ОДН
                     and r.usl = fk_usl_chld_)*/;
        elsif dist_tp_ = 3 then
          --если тип распр.=3 то либо арендатор, либо должен кто-то быть прописан
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
                      and e.tp = 6 --итог без ОДН
                      and e.kpr2 <> 0))
             /*and exists (select *
                    from nabor r
                   where r.lsk = n.lsk --там где есть услуга ОДН
                     and r.usl = fk_usl_chld_)*/;
        end if;

        p_opl_add := all_opl_;

        ---------------------------------------------------
        --------ОГРАНИЧЕНИЕ ПО ОДН-------------------------
        if nvl(p_wo_limit, 0) = 0 then
          l_limit_vol := 0; -- не используется в dist_tp_ in (1, 2, 3)
          begin
            if all_opl_ > 0 and all_kpr_ > 0 then
              --площадь > 0 и кол-во прожив > 0

              --ограничение ОДН, для поиска по таблице (округл. до целых)
              if tp_ in (0, 1) then
                --х.в. и г.в.
                l_opl_man   := round(all_opl_ / all_kpr_);
                l_opl_liter := opl_liter(l_opl_man);
                l_limit_vol := l_opl_liter / 1000 * all_opl_;
                --лимит на площадь
                l_limit_area := l_opl_liter / 1000;
                if p_dist_tp <> 2 then --кроме вводов, где нет услуги ОДН (ввод должен быть)
                  l_odn_nrm:=l_opl_liter;
                else
                  l_odn_nrm:=null;
                end if;
              elsif tp_ = 2 then
                --эл.эн.
                --по эл.эн. - по особенному
                --дом без лифта = площадь общего имущества * 2.7 квт.
                begin
                  --площадь общ.имущ., норматив, объем на площадь
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

                  /*            and not exists  --убрал, так как есть такие дома, где лифт сидит в текущем содержании! (Кис)
                  (select * from kart k, nabor n, usl u where k.house_id=h.id
                      and k.lsk=n.lsk
                      and n.usl=u.usl
                      and u.cd in ('лифт')
                      and c_kart.get_is_chrg(u.sptarn, n.koeff, n.norm)=1
                      );*/
                exception
                  when no_data_found then
                    l_limit_vol := 0;
                end;

                if l_limit_vol = 0 then
                  --значит дом с лифтом
                  begin
                    --площадь общ.имущ., норматив, объем на площадь
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
                        and u.cd in ('лифт')
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
          -- как будто не работает этот блок (limit_proc нигде не заполнен):
          if nvl(p_limit_proc, 0) <> 0 then
            --если установлено ограничение по доначислению ОДН в %
            --Вариант 2 расчета предельно допустимого объема ОДН
            if p_kub >
               round(all_kub_ + p_kub / 100 * nvl(p_limit_proc, 0), 3) then
              --установить предельно допустимый объем по дому
              p_kub_dist := round(all_kub_ +
                                  p_kub / 100 * nvl(p_limit_proc, 0),
                                  3);
              l_kub_fact_upnorm := p_kub-p_kub_dist;
            end if;
          elsif l_limit_vol > 0 and tp_ in (0, 1, 2) then
            --только для услуг х.в. и г.в. и эл.эн.
            --Вариант ограничения ОДН по нормативу
            if p_kub > round(all_kub_ + l_limit_vol, 3) then
              --установить предельно допустимый объем по дому
              p_kub_dist := round(all_kub_ + l_limit_vol, 3);
              l_kub_fact_upnorm := p_kub-p_kub_dist;
            end if;
          end if;
          -- как будто не работает этот блок (limit_proc нигде не заполнен):

        end if;
      end if;

      ---------------------------------------------------
      --------СБОР ИНФОРМАЦИИ ДЛЯ РАСЧЕТА ОДН------------

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

      ---ОЧИСТКА ИНФОРМАЦИИ ОДН-------------------------
      gen_clear_odn(p_usl      => p_usl,
                    p_usl_chld => fk_usl_chld_,
                    p_house    => null,
                    p_vvod     => p_id);

      if all_kub_ = 0 and p_kub_dist <> 0.001 then
        --p_kub <> 0.001
        --чтобы предотвратить ошибку деление на ноль
        null;
      else
        if dist_tp_ in (1, 2, 3) then
          --РАСПРЕДЕЛЕНИЕ пропорционально площади,объему (307, 354 пост.)
          if nvl(p_kub_dist, 0) <> 0 and p_kub_dist - all_kub_ <> 0 then
            ---------------------------------------------------
            --------РАСПРЕДЕЛЕНИЕ ОДН--------------------------

            if dist_tp_ in (1, 3) then
              --доначисление или экономия по 344 пост.
              -- ПЕРЕРАСХОД
              if p_kub_dist - all_kub_ > 0 then
                --доначисление пропорционально площади (в т.ч.арендаторы), если небаланс > 0
                if dist_tp_ <> 3 and use_sch_ = 1 then
                  --либо в т.ч. счетчики
                  update nabor k
                     set k.vol_add = round((select t.opl
                                              from kart t
                                             where t.lsk = k.lsk) *
                                           (p_kub_dist - all_kub_) /
                                           (all_opl_),
                                           3),
                         k.limit   = round((select case
                                                    when tp_ in (0, 1) then
                                                     l_limit_area * t.opl --лимит ОДН по л/с. г.в.,х.в.
                                                    when tp_ = 2 then
                                                     l_rate * l_area_prop *
                                                     t.opl / all_opl_ --лимит ОДН по л/с. Эл.эн.
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
                             and nvl(t.opl, 0) <> 0 --где есть площадь
                             and t.psch not in (8, 9)
                             and n.usl = p_usl
                             and n.fk_vvod = p_id);
                  -- commit;
                  -- Raise_application_error(-20000, l_limit_area||'-'||l_rate||'-'||l_area_prop||'-'||all_opl_);

                elsif dist_tp_ <> 3 and use_sch_ = 0 then
                  --либо чтобы НЕ были в этом периоде счетчики
                  update nabor k
                     set k.vol_add = round((select t.opl
                                              from kart t
                                             where t.lsk = k.lsk) *
                                           (p_kub_dist - all_kub_) /
                                           (all_opl_),
                                           3),
                         k.limit   = round((select case
                                                    when tp_ in (0, 1) then
                                                     l_limit_area * t.opl --лимит ОДН по л/с. г.в.,х.в.
                                                    when tp_ = 2 then
                                                     l_rate * l_area_prop *
                                                     t.opl / all_opl_ --лимит ОДН по л/с. Эл.эн.
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
                             and nvl(t.opl, 0) <> 0 --где есть площадь
                             and t.psch not in (8, 9)
                             and n.usl = p_usl
                             and n.fk_vvod = p_id
                             and not exists (select *
                                    from c_charge_prep e
                                   where n.lsk = e.lsk
                                     and n.usl = e.usl
                                     and e.tp = 7 --наличие счетчика в тек.периоде
                                     and e.sch = 1));
                elsif dist_tp_ = 3 then
                  --если тип распр.=3 то либо арендатор, либо должен кто-то быть прописан
                  update nabor k
                     set k.vol_add = round((select t.opl
                                              from kart t
                                             where t.lsk = k.lsk) *
                                           (p_kub_dist - all_kub_) /
                                           (all_opl_),
                                           3),
                         k.limit   = round((select case
                                                    when tp_ in (0, 1) then
                                                     l_limit_area * t.opl --лимит ОДН по л/с. г.в.,х.в.
                                                    when tp_ = 2 then
                                                     l_rate * l_area_prop *
                                                     t.opl / all_opl_ --лимит ОДН по л/с. Эл.эн.
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
                             and nvl(t.opl, 0) <> 0 --где есть площадь
                             and t.psch not in (8, 9)
                             and n.usl = p_usl
                             and n.fk_vvod = p_id
                             and (t.status = 9 or exists
                                  (select *
                                     from c_charge_prep e
                                    where t.lsk = e.lsk
                                      and e.usl = p_usl
                                      and e.tp = 6 --итог без ОДН
                                      and e.kpr2 <> 0)));
                end if;

                --добавить инфу по ОДН.
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
                --ЭКОНОМИЯ пропорционально кол-ва проживающих, если небаланс < 0
                --но не более потребленного объема
                --            Raise_application_error(-20000, all_kpr_||'-'||p_kub - all_kub_);

                if dist_tp_ <> 3 and use_sch_ = 1 then
                  --либо в т.ч. счетчики
                  open cur1;
                elsif dist_tp_ <> 3 and use_sch_ = 0 then
                  --либо чтобы НЕ были в этом периоде счетчики
                  open cur2;
                elsif dist_tp_ = 3 then
                  --если тип распр.=3 то либо арендатор, либо должен кто-то быть прописан
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
                  --а вот снимаем как раз не по дочерней услуге (ОДН) а по основной...
                  --ред 02.10.12
                  l_proc := rec.vol_add / rec.lsk_vl; --доля счетчика в объеме
                  l_vol  := 0;
                  if l_proc > 0 then
                    if abs(l_proc * rec.dist_vl) > rec.vol_add then
                      l_vol := round(l_proc * rec.vol_add, 3); --если ABS(распределенный небаланс) > расход
                    elsif abs(l_proc * rec.dist_vl) <= rec.vol_add then
                      l_vol := abs(round(l_proc * rec.dist_vl, 3)); --если ABS(распределенный небаланс) < расход
                    end if;
                    --установить лимит ОДН для статистики
                    update nabor n
                       set n.limit = round((select case
                                                    when tp_ in (0, 1) then
                                                     l_limit_area * t.opl --лимит ОДН по л/с. г.в.,х.в.
                                                    when tp_ = 2 then
                                                     l_rate * l_area_prop *
                                                     t.opl / all_opl_ --лимит ОДН по л/с. Эл.эн.
                                                    else
                                                     null
                                                  end as limit
                                             from kart t
                                            where t.lsk = n.lsk),
                                           3)
                     where n.lsk = rec.lsk
                       and n.usl = fk_usl_chld_;

                    --экономия распред.на счетчики
                    if l_vol > 0 then
                      --добавить инфу по ОДН.
                      -- УБРАЛ ЭКОНОМИЮ ОДН, чтоб случайно не повлияла на начисление! ред. 30.01.2017
                      -- Вернул экономию ОДН, так как опять стало востребовано начисление ОДН.31.08.2017 ред.
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
                                              'Недопустимый объем распр.счетчиков в Л/С:' ||
                                              rec.lsk || ' ' || l_vol);
                    end if;
                  elsif l_proc < 0 then
                    raise_application_error(-20000,
                                            'Недопустимый % распределения в Л/С:' ||
                                            rec.lsk || ' ' || l_proc);
                  end if;
                  --остаток от объема для распределения
                  --экономия распред.на норматив
                  l_dist_vl := abs(rec.dist_vl) - l_vol;
                  if l_dist_vl > 0 and rec.vol > 0 then
                    --если осталась экономия и есть объем по нормативу

                    -- УБРАЛ ЭКОНОМИЮ ОДН, чтоб случайно не повлияла на начисление! ред. 30.01.2017
                    -- Вернул экономию ОДН, так как опять стало востребовано начисление ОДН.31.08.2017 ред.
                    insert into c_charge_prep
                      (lsk, usl, vol, sch, tp)
                    values
                      (rec.lsk,
                       p_usl,
                       -1 * case when l_dist_vl > rec.vol then rec.vol --если ABS(распределенный небаланс) > расход
                       when l_dist_vl <= rec.vol then l_dist_vl --если ABS(распределенный небаланс) < расход
                       end,
                       0,
                       4);

                    --добавить инфу по ОДН.
                    --совместить с основным распр.
                    insert into c_charge
                      (lsk, usl, test_opl, type)
                    values
                      (rec.lsk,
                       fk_usl_chld_,
                       -1 * case when l_dist_vl > rec.vol then rec.vol --если ABS(распределенный небаланс) > расход
                       when l_dist_vl <= rec.vol then l_dist_vl --если ABS(распределенный небаланс) < расход
                       end,
                       5);
                  elsif l_dist_vl < 0 then
                    raise_application_error(-20000,
                                            'Недопустимый объем распр.остатка на норматив в Л/С:' ||
                                            rec.lsk || ' ' || l_dist_vl);
                  end if;
                end loop;
                if dist_tp_ <> 3 and use_sch_ = 1 then
                  --либо в т.ч. счетчики
                  close cur1;
                elsif dist_tp_ <> 3 and use_sch_ = 0 then
                  --либо чтобы НЕ были в этом периоде счетчики
                  close cur2;
                elsif dist_tp_ = 3 then
                  --если тип распр.=3 то либо арендатор, либо должен кто-то быть прописан
                  close cur3;
                end if;

              end if;

            elsif dist_tp_ = 2 then
              --доначисление пропорционально потреб. объему
              --код не поддерживается 22.04.14
              raise_application_error(-20000,
                                      'Error #2-код не поддерживается');

              /*             update nabor k
                             set k.vol_add = --доначисление по нормативщику, счетчику небаланс, (+ или -)
                                   round((select nvl(sum(t.vol),0)
                                         from c_charge_prep t where t.lsk = k.lsk --уже базируется на сделанном распр.выше
                                          and t.usl=p_usl
                                          and t.tp=6 --итог без ОДН
                                          )/(all_kub_) * (p_kub_dist - all_kub_) ,
                                         3)
                           where k.usl = fk_usl_chld_
                                  and k.fk_vvod = p_id
                                      and (use_sch_ = 1 or use_sch_ = 0 and not exists
                                      (select * from nabor n, c_charge_prep e where
                                        k.lsk=e.lsk --либо в т.ч. счетчики, либо чтобы НЕ были в этом периоде счетчики
                                        and t.lsk=n.lsk
                                        and n.usl=p_usl
                                        and n.fk_vvod = p_id
                                        and e.usl=p_usl
                                        and e.tp=7 --наличие счетчика
                                         ))
                                      and (dist_tp_ <> 3 or dist_tp_ = 3 and (t.status = 9 or exists
                                      (select * from c_charge_prep e where
                                        t.lsk=e.lsk
                                        and e.usl=p_usl
                                        and e.tp=6 --итог без ОДН
                                        and e.kpr2 <> 0) --если тип распр.=3 то либо арендатор, либо должен кто-то быть прописан
                                         ))
                                         );
              */
              null;

            end if;
            ---------------------------------------------------
            --------РАСПРЕДЕЛЕНИЕ ОДН--------------------------

            ---------------------------------------------------
            --------ОКРУГЛЕНИЕ ОДН--------------------------
            --ОКРУГЛЕНИЕ доначисления по 354 пост.
            if dist_tp_ in (1, 3) then
              --доначисление пропорционально площади
              if p_kub_dist - all_kub_ > 0 then
                --округление доначисления пропорционально площади (в т.ч.арендаторы), если небаланс > 0
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
                            'p_vvod.gen_dist: округление по вводу ' || p_id || ' =' ||
                            to_char(p_kub_dist - all_kub_ - l_for_round));
                if p_kub_dist - all_kub_ - l_for_round > 0.5 then
                  raise_application_error(-20000,
                                          'Стоп! Значение округления составило ' ||
                                          to_char(p_kub_dist - all_kub_ -
                                                  l_for_round) ||
                                          ' по вводу: ' || p_id);
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
                                       dist_tp_ <> 3) --если тип распр.=3 то либо арендатор, либо должен кто-то быть прописан
                                   and k.psch not in (8, 9)
                                   and r.fk_vvod = p_id
                                   and r.usl = p_usl /*с Арендаторами*/
                                ))
                   and t.usl = fk_usl_chld_
                   and t.vol_add <> 0
                returning t.lsk, nvl(t.vol_add, 0) into l_lsk_round, l_vol_round;

                if l_lsk_round is not null and l_vol_round <> 0 then
                  --обновить инфу по ОДН.
                  update c_charge t
                     set t.test_opl = l_vol_round
                   where t.lsk = l_lsk_round
                     and t.usl = fk_usl_chld_
                     and t.type = 5;
                end if;
              else
                --округление экономии пропорционально проживающим, если небаланс < 0
                --и не более собственного расхода!!
                select nvl(sum(n.test_opl), 0)
                  into l_nbalans --сумма распределенного небаланса
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
                  --ЕСЛИ сумма небаланса - распределение небаланса меньше 0.01, то округлить
                  --на случайного СЧЕТЧИКА, ЕСЛИ больше - то значит экономия вся использована, в пределах
                  --потребления
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
                            having nvl(sum(t.vol), 0) > 0 --там где еще положительные объемы есть, куда округлять
                            ) loop
                    --добавляем корректировку
                    -- УБРАЛ ЭКОНОМИЮ ОДН, чтоб случайно не повлияла на начисление! ред. 30.01.2017
                    -- Вернул экономию ОДН, так как опять стало востребовано начисление ОДН.31.08.2017 ред.
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
                                    and r.usl = p_usl--без Арендаторов
                                    ))
                    and t.usl = p_usl
                    and t.vol_add > 0.01 --там где еще положительные объемы есть, куда округлять
                    returning t.lsk, nvl(t.vol_add,0) into l_lsk_round, l_vol_round; */

                  if sql%notfound then
                    --округлить по нормативщику, если не найдены счетчики
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
                              having nvl(sum(t.vol), 0) > 0 --там где еще положительные объемы есть, куда округлять
                              ) loop
                      --добавляем корректировку

                      -- УБРАЛ ЭКОНОМИЮ ОДН, чтоб случайно не повлияла на начисление! ред. 30.01.2017
                      -- Вернул экономию ОДН, так как опять стало востребовано начисление ОДН.31.08.2017 ред.
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
                                      and r.usl = p_usl--с Арендаторами))
                      and t.usl = p_usl
                      and t.vol >= 0.01 --там где еще положительные объемы есть, куда округлять
                      returning t.lsk into l_lsk_round;  */
                  end if;
                  if l_lsk_round is not null then
                    --обновить инфу по ОДН.
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
              --доначисление пропорционально потреб. объему

              raise_application_error(-20000,
                                      'КОД НЕ ИСПОЛЬЗУЕТСЯ!');
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
                                and r.usl = p_usl--с Арендаторами))
                and t.usl = fk_usl_chld_
                and t.vol_add <> 0; */
            end if;
            ---------------------------------------------------
            --------ОКРУГЛЕНИЕ ОДН-----------------------------
          end if;

          ---------------------------------------------------
          --------ИТОГИ РАСПРЕДЕЛЕНИЯ ОДН--------------------
          --итоговые выполненные доначисления
          --по жилым помещениям
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
          --итоги
          p_kub_nrm_fact := rec_cnt_.vol;
          p_kub_sch_fact := rec_cnt_.vol_add;
          --итоговые выполненные доначисления
          --по нежилым помещениям
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
          --РАСПРЕДЕЛЕНИЕ пропорционально объему (Кис) (устаревает)
          raise_application_error(-20000,
                                  'КОД НЕ ИСПОЛЬЗУЕТСЯ!');
        end if;

        ---------------------------------------------------
        --------РАСПРЕДЕЛЕНИЕ------------------------------

      end if;

    elsif fk_calc_tp_ = 1 and dist_tp_ = 0 then
      --устаревает, смотри услугу 31
      --распределение Электроэнергии МОП, пропорционально площади, по дочерней услуге (ТСЖ)
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
             count(*) as cnt, --да, да 0 по нормативу (нужно сделать kpr * норматив) доделать! ред 21.03.12
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

      --суммируем расход по вводу
      all_kub_ := rec_sch_tsj_.kub_sch + rec_norm_tsj_.kub_norm;
      --суммируем площадь по вводу
      all_opl_ := rec_sch_tsj_.opl + rec_norm_tsj_.opl;

      update nabor k
         set k.vol_add = --доначисление по нормативщику, счетчику небаланс, (+ или -)
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

      --округление на случайного нормативщика/cчетчика
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
      --итоговые выполненные доначисления
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
      --итоги
      p_kub_nrm_fact := rec_cnt_.vol;
      p_kub_sch_fact := rec_cnt_.vol_add;
      p_kub_fact     := p_kub_nrm_fact + p_kub_sch_fact;
      ---------
      ---------
    elsif fk_calc_tp_ = 1 and dist_tp_ = 1 then
      --начисление по Электр.энерг (Кис)
      select nvl(sum(mel), 0), count(*), nvl(sum(k.kpr - k.kpr_ot), 0)
        into kub_rec_
        from kart k, nabor n
       where k.sch_el in (1)
         and k.lsk = n.lsk
         and k.psch not in (8, 9)
         and n.usl = p_usl
         and case
               when sptarn_ = 0 and nvl(n.koeff, 0) <> 0 then
                1 --определяем наличие услуги в л.с.
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

      --колво людей по нормативу
      select count(*), nvl(sum(k.kpr - k.kpr_ot), 0)
        into kpr_rec_
        from kart k, nabor n
       where k.sch_el not in (1)
         and k.lsk = n.lsk
         and n.usl = p_usl
         and k.psch not in (8, 9)
         and case
               when sptarn_ = 0 and nvl(n.koeff, 0) <> 0 then
                1 --определяем наличие услуги в л.с.
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

      --Обновляем кол-во квт по карточкам, по нормативу
      if (p_kub_dist - kub_rec_.kub_sch) < 0 then
        -- не реальная ситуация ( квт по сч > кубов по дому)
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
                          1 --определяем наличие услуги в л.с.
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

        --расход квт по каждому человеку, по этому вводу
        p_kub_man := 0;
      elsif kpr_rec_.kpr > 0 then
        --если есть люди
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
                          1 --определяем наличие услуги в л.с.
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
        --расход квт по каждому человеку, по этому вводу
        p_kub_man := (p_kub_dist - kub_rec_.kub_sch) / kpr_rec_.kpr;
      elsif kpr_rec_.kpr = 0 then
        --если нет людей
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
                          1 --определяем наличие услуги в л.с.
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
        --расход квт по каждому человеку, по этому вводу
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
      --распределение по услуге РКЦ ЖКХ (пропорционально площади)
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
      --распределение по прочей услуге, расчитываемой как расценка * vol_add, пропорционально площади
      --например, эл.энерг МОП в Кис., в ТСЖ, эл.эн.ОДН в Полыс.
      --здесь же распределяется услуга ОДН, которая не предполагает собой
      --начисление по основной услуге в лицевых счетах
      l_limit_vol := 0;

      if l_usl_cd in ('эл.эн.ОДН', 'эл.эн.МОП2', 'эл.эн.учет УО ОДН') and nvl(p_wo_limit, 0) = 0 then
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
          --значит дом с лифтом
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

        --проверяем ограничение ОДН
        if p_kub_dist > l_limit_vol then
          p_kub_dist := l_limit_vol;
        end if;
      end if;

      --нулим по вводу-услуге
      update nabor k
         set k.vol = 0, k.vol_add = 0, k.limit = null
       where k.usl = p_usl
         and exists (select *
                from nabor n, kart t
               where n.lsk = k.lsk
                 and n.lsk = t.lsk
                 and n.usl = p_usl
                 and n.fk_vvod = p_id);
      --распределяем
      update nabor n
         set n.vol_add = round(p_kub_dist /
                               (select sum(k.opl)
                                  from kart k, nabor r
                                 where k.lsk = r.lsk
                                   and r.fk_vvod = p_id
                                   and nvl(r.koeff, 0) <> 0 --добавил 01.02.2016
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

      --распределено фактически
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
                                'Возможно лицевые счета в карточке не привязаны ко вводу, распределение по id=' || p_id||', разница='||(p_kub_dist - p_kub_fact));
      end if;

      --округление
      update nabor t
         set t.vol_add = t.vol_add + p_kub_dist - p_kub_fact
       where t.fk_vvod = p_id
         and t.lsk = (select max(lsk)
                        from nabor n
                       where n.fk_vvod = p_id
                         and n.vol_add <> 0
                         and n.usl = p_usl)
         and t.vol_add <> 0;

      --и опять.. распределено фактически
      select sum(c.vol_add)
        into p_kub_fact
        from kart k, nabor c
       where c.fk_vvod = p_id
         and c.usl = p_usl
         and k.psch not in (8, 9)
         and nvl(c.koeff, 0) <> 0
         and k.lsk = c.lsk;

    elsif fk_calc_tp_ = 15 then
      --Электроэнергия распр (для ТСЖ), (по лицевым счетам)
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
                                  'Возможно отсутствует услуга в лицевых счетах, деление на ноль в вводе ID=' || p_id);

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
      --начисление по услуге отопление в гигах
      --поправочный коэфф. для перевода расц за гиг в расц за площадь
      --коэфф. един для отопления по норме и свыше

      --коэфф по норме
      koeff_ := 1;
      --распределяем СТРОГО по тем НЕ ЗАКРЫТЫМ квартирам, в которых ВКЛЮЧЕНА услуга
        --распределить без норматива, гКал пропорционально площади
/* УБРАЛ ЭТО СТранное округление round (5), приводило к некорректному распределению (увидел в полыс) 25.07.2016
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
      /* --ветка странная if... не работает видимо ред. 28.04.12
      elsif fk_calc_tp_ = 1 then
        --начисление по Электр.энерг
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

        --колво людей по нормативу
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

        --Обновляем кол-во квт по карточкам, по нормативу
        if (p_kub - kub_rec_.kub_sch) < 0 then
          -- не реальная ситуация ( квт по сч > кубов по дому)
          update kart k
             set k.mel = 0
           where k.house_id = p_house_id
             and k.sch_el not in (1)
             and exists (select *
                    from nabor n
                   where n.lsk = k.lsk
                     and n.usl = p_usl
                     and n.fk_vvod = p_id);

          --расход квт по каждому человеку, по этому вводу
          p_kub_man := 0;
        elsif kpr_rec_.kpr > 0 then
          --если есть люди
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
          --расход квт по каждому человеку, по этому вводу
          p_kub_man := (p_kub - kub_rec_.kub_sch) / kpr_rec_.kpr;
        elsif kpr_rec_.kpr = 0 then
          --если нет людей
          update kart k
             set k.mel = 0
           where k.house_id = p_house_id
             and k.sch_el not in (1)
             and exists (select *
                    from nabor n
                   where n.lsk = k.lsk
                     and n.usl = p_usl
                     and n.fk_vvod = p_id);
          --расход квт по каждому человеку, по этому вводу
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

    --обновить вводы выходными параметрами
    --не выполнить случайно обновление по циклу!

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
    --  --расчет начисления (если из триггера)
    --  l_cnt := c_charges.gen_charges(null, null, null, p_id, 0, 0);
    --end if;
    logger.log_(l_time,
                'Выполнено: p_vvod.gen_dist: vvod_id=' || p_id);

  end;

    --перераспределение объемов по всем домам
  procedure gen_dist_all_houses is
    l_cnt number;
    time_  date;
    time1_ date;
    i number;
  begin
    time_  := sysdate;
    time1_ := sysdate;
    --сперва, на всякий случай чистим инфу, там где ВООБЩЕ нет счетчиков (нет записи в c_vvod)
    logger.log_(time1_,
                'p_vvod.gen_dist_all_houses - Начало распределения объемов по ОДПУ');
    for c in (select u.usl, u.fk_usl_chld
                from usl u, usl odn
               where u.cd in ('х.вода',
                              'г.вода',
                              'х.в. для гвс',
                              'эл.энерг.2',
                              'эл.эн.учет УО',
                              'эл.эн.ОДН',
                              'отоп.гкал.')
                 and u.fk_usl_chld = odn.usl) loop
      for c2 in (select h.id
                   from c_houses h
                  where nvl(h.psch, 0) = 0 --не закрытые дома
                    and h.id=6962
                    and not exists
                  (select * from c_vvod d where d.usl = c.usl)
                  order by h.id) loop
            logger.log_(time1_,
                'p_vvod.gen_dist_all_houses - I - Фаза:Дом c_house.id='||c2.id);
            --почистить
            gen_clear_odn(p_usl      => c.usl,
                          p_usl_chld => c.fk_usl_chld,
                          p_house    => c2.id,
                          p_vvod     => null);
      end loop;
    end loop;

    --commit, чтобы ускорить процесс
    commit;
    logger.log_(time1_,
                'p_vvod.gen_dist_all_houses - закончена I - Фаза:Очистка там где вообще нет записи во вводе');
    time1_ := sysdate;

    --распределить ОДН в домах, где нет ОДПУ
    i:=0;
    for c in (select d.id
                from c_vvod d, c_houses h
               where d.house_id = h.id
                    and h.id=6962
                 and d.dist_tp in (4,5) --дома без ОДПУ
                 and nvl(h.psch, 0) = 0 --не закрытые дома
               order by d.id) loop
      --распределить объем
      gen_dist_wo_vvod_usl(c.id);
    end loop;

    logger.log_(time1_,
                'p_vvod.gen_dist_all_houses - закончена II - Фаза:Распр в домах, где нет ОДПУ');
    time1_ := sysdate;

    i:=0;
    --распределить объемы по домам с ОДПУ
    for c in (select distinct d.*
                from c_vvod d, c_houses h
               where d.house_id = h.id
                    and h.id=6962
                 and nvl(h.psch, 0) = 0 --не закрытые дома
                 and d.dist_tp not in (4,5,2) --дома с ОДПУ и с услугой для распределения, например ОДН (dist_tp<>2)
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
                'p_vvod.gen_dist_all_houses - закончена III - Фаза:Распр в домах, где есть ОДПУ');
    logger.log_(time_,
                'p_vvod.gen_dist_all_houses: Окончание распределения');

  end;

  procedure gen_clear_odn(p_usl      in c_vvod.usl%type,
                          p_usl_chld in c_vvod.usl%type,
                          p_house    in c_houses.id%type,
                          p_vvod     in c_vvod.id%type) is
  l_time1 date;
  begin
    --почистить информацию по ОДН
    l_time1 := sysdate;
    if p_vvod is not null then
      --удаляем информацию по распр.ОДН.по информационным записям
      delete from c_charge t
       where t.type = 5
         and t.usl = p_usl_chld
         and exists (select *
                from nabor n
               where n.fk_vvod = p_vvod
                 and n.usl = p_usl
                 and n.lsk = t.lsk);
      --удаляем информацию по корректировкам ОДН
      delete from c_charge_prep t
       where t.usl = p_usl
         and t.tp = 4
         and exists (select *
                from nabor n
               where n.fk_vvod = p_vvod
                 and n.usl = p_usl
                 and n.lsk = t.lsk);

      --нулим по вводу-услуге
      update nabor k
         set k.vol = 0, k.vol_add = 0, k.limit = null
       where k.usl = p_usl
         and exists (select *
                from nabor n, kart t
               where n.lsk = k.lsk
                 and n.lsk = t.lsk
                 and n.usl = p_usl
                 and n.fk_vvod = p_vvod);
      --нулим по зависимым услугам
      update nabor k
         set k.vol = 0, k.vol_add = 0, k.limit = null
       where k.usl = p_usl_chld
         and exists (select *
                from nabor n, kart t
               where n.lsk = k.lsk
                 and n.lsk = t.lsk
                 and n.usl = p_usl
                 and n.fk_vvod = p_vvod);
      --почистить нормативы (ограничения)
      update c_vvod t set t.nrm=null where t.id=p_vvod;
    elsif p_house is not null then
      --удаляем информацию по распр.ОДН.по информационным записям
      delete from c_charge t
       where t.type = 5
         and t.usl = p_usl_chld
         and exists (select *
                from nabor n, kart k
               where k.house_id = p_house
                 and k.lsk = n.lsk
                 and n.usl = p_usl
                 and n.lsk = t.lsk);

      --нулим по вводу-услуге
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
      --нулим по зависимым услугам
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
      --почистить нормативы (ограничения)
      update c_vvod t set t.nrm=null where t.house_id=p_house and t.usl=p_usl;
    end if;
    logger.log_(l_time1,
                'Выполнена очистка: p_vvod.gen_clear_odn p_house='||p_house||', p_vvod='||p_vvod);

  end;

  --распределить ОДН во вводах, где нет ОДПУ
  procedure gen_dist_wo_vvod_usl(p_vvod in c_vvod.id%type) is
    fk_usl_chld_ usl.usl%type;
    fk_calc_tp_  number;
    sptarn_      number;
    l_kpr        number;
    l_cnt        number;
    tp_          number;
    l_rate       number; --норматив по ОДН
    l_area_prop  number; --площадь общего имущества дома
    l_limit_vol  number; --допустимый лимит ОДН по законодательству (общий)
    l_usl        c_vvod.usl%type; --услуга
    l_house      c_vvod.house_id%type; --id дома
    l_nrm_kpr    number; --кол-во людей по нормативу
    l_sch_kpr    number; --кол-во людей по счетчику
    --начисленные факты
    l_kub_nrm_fact number;
    l_kub_sch_fact number;
    l_kub_fact     number;
    l_opl_add      number;
    l_edt_norm number;
    type rec_cnt is record(
      vol     number,
      vol_add number);
    l_rec_cnt rec_cnt;
    l_odn_nrm number; --ограничение по ОДН (еще называют нормативом)
    l_time1 date;
  begin
    l_time1 := sysdate;
    --распределение ОДН по домам, в которых нет домового П.У.
    --(ОДН по формуле)

    --вид расчета услуги
    select nvl(u.fk_calc_tp, 0), u.fk_usl_chld, u.usl, d.house_id, d.edt_norm
      into fk_calc_tp_, fk_usl_chld_, l_usl, l_house, l_edt_norm
      from usl u, c_vvod d
     where u.usl = d.usl
       and d.id = p_vvod;
    select nvl(u.sptarn, 0) into sptarn_ from usl u where u.usl = l_usl;

    --установить коэфф по проживающим, по вводу
    c_kart.set_part_kpr_vvod(p_vvod);

    if fk_calc_tp_ in (3, 17, 38) then
      tp_ := 0; --х.в.
    elsif fk_calc_tp_ in (4, 18, 40) then
      tp_ := 1; --г.в.
    elsif fk_calc_tp_ in (31) then
      tp_ := 2; --эл.эн.
    end if;

    ---ОЧИСТКА ИНФОРМАЦИИ ОДН-------------------------
    gen_clear_odn(p_usl      => l_usl,
                  p_usl_chld => fk_usl_chld_,
                  p_house    => null,
                  p_vvod     => p_vvod);

    if tp_ in (0, 1) then
      --х.в. или г.в.
      --кол-во проживающих
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
         and e.tp = 6 --итог без ОДН
         and k.status not in (9) /*без Арендаторов*/
      ;

    elsif tp_ = 2 then
      --по эл.эн. - по особенному
      --дом без лифта = площадь общего имущества * 2.7 квт.
      begin
        --площадь общ.имущ., норматив, объем на площадь
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
        --значит дом с лифтом
        begin
          --площадь общ.имущ., норматив, объем на площадь
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
      --если кол-во проживающих <>0, то имеет смысл (для х.в. и г.в., но не для эл.эн.)
      for c in (select sum(k.opl) as opl,
                       case
                         when tp_ in (0, 1) then
                          opl_liter(sum(k.opl) / l_kpr) / 1000 --лимит ОДН по л/с. х.в. и г.в.
                         when tp_ = 2 then
                          null --лимит ОДН по л/с. Эл.эн.
                       end as vl
                  from kart k, nabor n
                 where k.house_id = l_house
                   and k.lsk=n.lsk
                   and n.usl=fk_usl_chld_
                   and k.psch not in (8, 9) --без арендаторов
                   and nvl(k.opl, 0) <> 0) loop
        l_opl_add := c.opl;
        update nabor n
           set n.vol_add =
               (select case
                         when tp_ in (0, 1) then
                          round(k.opl * c.vl, 3)
                         when tp_ = 2 then
                          round(l_rate * l_area_prop * k.opl / c.opl, 3) --лимит ОДН по л/с. Эл.эн.
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
        --добавить инфу по ОДН.
        insert into c_charge
          (lsk, usl, test_opl, type)
          select k.lsk,
                 fk_usl_chld_,
                 case
                   when tp_ in (0, 1) then
                    round(k.opl * c.vl, 3)
                   when tp_ = 2 then
                    round(l_rate * l_area_prop * k.opl / c.opl, 3) --лимит ОДН по л/с. Эл.эн.
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
        l_odn_nrm:=c.vl*1000;--вернуть в литры
        --округление -- здесь не нужно
      end loop;

      --итоговые выполненные доначисления
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
      --итоги
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
                'Распределено: p_vvod.gen_dist_wo_vvod_usl, p_vvod='||p_vvod);

    --убрал коммит
    --commit;
  end;

  --пересчитать ввод (из программы)
  procedure gen_vvod(p_vvod_id in number) is
  begin
    for c in (select d.* from c_vvod d where d.id=p_vvod_id
        )
      loop
        if c.dist_tp in (4,5) then
        --распределить объем, если нет ОДПУ
        p_vvod.gen_dist_wo_vvod_usl(c.id);
        else
        --распределить объем, если есть ОДПУ
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
    --проверка распределения по одному выбранному вводу

    --дата нужна для начисления
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
      Raise_application_error(-20000, 'Функция не работает в новой версии!');
    end if;
    --снять признак счетчиков в зависимости от признака исправен/нет
    --по всем услугам
    --(обычно вызывается из итогового формирования)
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
                       where u.cd = 'Поверка ПУ'
                         and u.id = t.fk_tp)
                 and t.fk_usl = p_usl
               group by t.lsk, t.fk_usl) b,
             params p
       where b.state = 'Неисправен ПУ';

 --больше 6 мес.не было передано объемов
  cursor c2 is
  select k.lsk, k.psch, to_date(p.period || '01', 'YYYYMMDD') as dt2
     from scott.kart k, scott.params p where not exists (
    select t.*
      from scott.t_objxpar t, scott.u_list s, scott.u_listtp tp, scott.params p
     where t.fk_list = s.id
       and t.tp =0
       and s.fk_listtp=tp.id
       and tp.cd='Параметры лиц.счета'
       and t.fk_usl=p_usl
       and s.cd='ins_vol_sch'
       and nvl(t.n1,0)>0
       and k.psch not in (8,9)
       and t.mg>=to_char(add_months(to_date(p.period || '01', 'YYYYMMDD'),-6),'YYYYMM') --назад на 6 месяцев
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
      Raise_application_error(-20000, 'Функция не работает в новой версии!');
    end if;
    --по среднему, за последний N месяцев, но не менее чем за последние 3 мес.
    select trim(t.counter), trim(t.nm)
      into l_counter, l_usl_nm
      from usl t
     where t.usl = p_usl;

    --Переделать все счетчики в норматив, если признаны неисправными
    open c;
    loop
      fetch c
        into l_rec;
      exit when c%notfound;
      if l_rec.cnt_months > 2 then
        --больше чем 2 месяца неисправен прибор учета
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
                                    'Ошибка снятия прибора учета по услуге: ' ||
                                    l_usl_nm || ', в Л/С ' || l_rec.lsk);
          end if;
          logger.log_act(l_rec.lsk,
                         'Обновление л/с: ' || l_rec.lsk ||
                         ' Неисправный счетчик по услуге: ' || l_usl_nm ||
                         ', >= 3 месяца, установлен норматив',
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
                                    'Ошибка снятия прибора учета по услуге: ' ||
                                    l_usl_nm || ', в Л/С' || l_rec.lsk);
          end if;
          logger.log_act(l_rec.lsk,
                         'Обновление л/с: ' || l_rec.lsk ||
                         ' Неисправный счетчик по услуге: ' || l_usl_nm ||
                         ', >= 3 месяца, установлен норматив',
                         2);
        elsif l_counter = 'pel' then
          update kart k set k.sch_el = 0 where k.lsk = l_rec.lsk;
          logger.log_act(l_rec.lsk,
                         'Обновление л/с: ' || l_rec.lsk ||
                         ' Неисправный счетчик по услуге: ' || l_usl_nm ||
                         ', >= 3 месяца, установлен норматив',
                         2);
        end if;
      else
        -- <= 2 месяца неисправен прибор учета
        --просто убрать расход, если введён (при автоначислении, - начислится по среднему)
        if l_counter = 'phw' then
          update kart k set k.mhw = 0 where k.lsk = l_rec.lsk;
          logger.log_act(l_rec.lsk,
                         'Обновление л/с: ' || l_rec.lsk ||
                         ' Неисправный счетчик по услуге: ' || l_usl_nm ||
                         ', < 3 месяца, начислено по среднему',
                         2);
        elsif l_counter = 'pgw' then
          update kart k set k.mgw = 0 where k.lsk = l_rec.lsk;
          logger.log_act(l_rec.lsk,
                         'Обновление л/с: ' || l_rec.lsk ||
                         ' Неисправный счетчик по услуге: ' || l_usl_nm ||
                         ', < 3 месяца, начислено по среднему',
                         2);
        elsif l_counter = 'pel' then
          update kart k set k.mel = 0 where k.lsk = l_rec.lsk;
          logger.log_act(l_rec.lsk,
                         'Обновление л/с: ' || l_rec.lsk ||
                         ' Неисправный счетчик по услуге: ' || l_usl_nm ||
                         ', < 3 месяца, начислено по среднему',
                         2);
        end if;

      end if;
    end loop;
    close c;


    --Переделать все счетчики в норматив, если не было передано показаний по ним
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
                                    'Ошибка снятия прибора учета по услуге: ' ||
                                    l_usl_nm || ', в Л/С ' || l_rec2.lsk);
          end if;
          logger.log_act(l_rec2.lsk,
                         'Обновление л/с: ' || l_rec2.lsk ||
                         ' По счетчику не передавали показаний >= 6 месяцев, по услуге: ' || l_usl_nm ||
                         ' установлен норматив',
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
                                    'Ошибка снятия прибора учета по услуге: ' ||
                                    l_usl_nm || ', в Л/С' || l_rec2.lsk);
          end if;
          logger.log_act(l_rec2.lsk,
                         'Обновление л/с: ' || l_rec2.lsk ||
                         ' По счетчику не передавали показаний >= 6 месяцев, по услуге: ' || l_usl_nm ||
                         ' установлен норматив',
                         2);
        elsif l_counter = 'pel' then
          update kart k set k.sch_el = 0 where k.lsk = l_rec2.lsk;
          logger.log_act(l_rec2.lsk,
                         'Обновление л/с: ' || l_rec2.lsk ||
                         ' По счетчику не передавали показаний >= 6 месяцев, по услуге: ' || l_usl_nm ||
                         ' установлен норматив',
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
    l_otop    number; --отопит.период
  begin
    if utils.get_int_param('VER_METER1') <> 0 then
      Raise_application_error(-20000, 'Функция не работает в новой версии!');
    end if;

    begin
    logger.log_(null, 'p_vvod.gen_auto_chrg_all Начало');
    --установить глобальную переменную - признак автоначисления (потом сделать как нить g_tp=3)
    g_tp := 1;
    --снять статусы неисправных счетчиков
    if utils.get_int_param('DEL_BRK_SCH')=1 then
      del_broken_sch(p_usl);
    end if;
    --снять глобальную переменную
    g_tp := 0;

    --автоначисление по счетчикам, по услуге
    l_ret := 1;

    --узнать отопительный ли сезон?
    --(по последней дате месяца) - пока так... ничего умнее не придумал
    select case
             when last_day(to_date(p.period || '01', 'YYYYMMDD')) between
                  utils.get_date_param('MONTH_HEAT1') --обраб.отопит.период
                  and utils.get_date_param('MONTH_HEAT2') then
              1
             else
              0
           end
      into l_otop
      from params p;

    --по среднему, за последний N месяцев, но не менее чем за последние 3 мес.
    select trim(t.counter), trim(t.nm)
      into l_counter, l_usl_nm
      from usl t
     where t.usl = p_usl;
    l_months := utils.get_int_param('AUTOCHRGM');

    if p_set = 1 then
      --автоначислить по среднему
      --период, от года назад до прошлого месяца
      select to_char(add_months(to_date(p.period || '01', 'YYYYMMDD'),
                                -1 * l_months),
                     'YYYYMM'),
             to_char(add_months(to_date(p.period || '01', 'YYYYMMDD'), -1),
                     'YYYYMM')
        into l_mg1, l_mg2
        from params p;

      --снять неисправные счетчики (превратить в нормативы)
      if utils.get_int_param('DEL_BRK_SCH')=1 then  --ПОЧЕМУ ДВАЖДЫ????
        del_broken_sch(p_usl);
      end if;

      --установить глобальную переменную - признак автоначисления
      g_tp := 1;

      for c in (select a.lsk,
                       nvl(sum(case
                                 when a.psch in (1, 2) then
                                  1
                                 else
                                  0
                               end),
                           0) as m_hw, --месяцев, когда счетчик был установлен
                       nvl(sum(case
                                 when a.psch in (1, 2) then
                                  a.mhw
                                 else
                                  0
                               end),
                           0) as cnt_hw, --объем, когда счетчик был установлен
                       nvl(sum(case
                                 when a.psch in (1, 3) then
                                  1
                                 else
                                  0
                               end),
                           0) as m_gw, --и так далее...
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
                   and (l_otop = 0 and l_counter = 'pgw' and not exists --обрабатываем краны из сист.отопления (только для Г.В.!!!)
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
        --ВНИМАНИЕ!, ПЕРЕПИСАТЬ ДЛЯ КИС, ЕСЛИ БУДУТ ИСПОЛЬЗОВАТЬ распределение по расходу!
        if l_counter = 'phw' then
          --автоначислить по х.в.
          if c.m_hw >= 3 and c.cnt_hw > 0 then
            --не менее 3 месяцев счетчик
            l_ret := 0;
            update kart k
               set k.phw = nvl(k.phw, 0) + round(c.cnt_hw / c.m_hw, 3)
             where k.lsk = c.lsk;
          end if;
        elsif l_counter = 'pgw' then
          --автоначислить по г.в.
          if c.m_gw >= 3 and c.cnt_gw > 0 then
            --не менее 3 месяцев счетчик
            l_ret := 0;
            update kart k
               set k.pgw = nvl(k.pgw, 0) + round(c.cnt_gw / c.m_gw, 3)
             where k.lsk = c.lsk;
          end if;
        elsif l_counter = 'pel' then
          --автоначислить по эл.эн.
          if c.m_el >= 3 and c.cnt_el > 0 then
            --не менее 3 месяцев счетчик
            l_ret := 0;
            update kart k
               set k.pel = nvl(k.pel, 0) + round(c.cnt_el / c.m_el, 3)
             where k.lsk = c.lsk;
          end if;
        end if;
      end loop;
    elsif p_set = 0 then
      --снять автоначисление (отмена) (последнюю итерацию)
      --установить глобальную переменную - признак снятия автоначисления
      g_tp := 2;

      for c in (select t.fk_lsk, max(t.id) as max_id
                  from t_objxpar t, params p, u_list s, u_listtp tp
                 where t.mg = p.period
                   and tp.id = s.fk_listtp
                   and tp.cd = 'Параметры лиц.счета'
                   and s.cd = 'ins_vol_sch'
                   and t.fk_list = s.id
                   and t.fk_usl = p_usl
                   and t.tp in (1, 2) --тип - автоначислено, отмена автоначисл.
                --         and exists (select * from kart k where k.kran1=1 and k.lsk=t.fk_lsk)  включить если нужно отменить по сист. отопления
                 group by t.fk_lsk) loop
        select t.tp, nvl(t.n1, 0)
          into l_tp, l_cnt
          from t_objxpar t
         where t.id = c.max_id;

        --ВНИМАНИЕ!, ПЕРЕПИСАТЬ ДЛЯ КИС, ЕСЛИ БУДУТ ИСПОЛЬЗОВАТЬ распределение по расходу!
        if l_tp = 1 and l_cnt <> 0 then
          l_ret := 0;
          --Возможность отменить только автоначисление!
          --(Но только его, а не другие типы)
          if l_counter = 'phw' then
            --снять автоначисление по х.в.
            update kart k
               set k.phw = nvl(k.phw, 0) - l_cnt
             where k.lsk = c.fk_lsk
               and k.psch in (1, 2);
          elsif l_counter = 'pgw' then
            --снять автоначисление по г.в.
            update kart k
               set k.pgw = nvl(k.pgw, 0) - l_cnt
             where k.lsk = c.fk_lsk
               and k.psch in (1, 3);
          elsif l_counter = 'pel' then
            --снять автоначисление по эл.эн.
            update kart k
               set k.pel = nvl(k.pel, 0) - l_cnt
             where k.lsk = c.fk_lsk
               and k.sch_el in (1);
          end if;
        end if;
      end loop;

    end if;
    --снять глобальную переменную - признак автоначисления
    g_tp := 0;
    commit;
    if p_set = 1 then
      logger.log_(null,
                  'p_vvod.gen_auto_chrg_all Окончание-автоначислено по среднему');
    elsif p_set = 0 then
      logger.log_(null,
                  'p_vvod.gen_auto_chrg_all Окончание-Снятие:автоначисления по среднему');
    end if;
    exception when others then
      --если ошибка - снять глобальную переменную - признак автоначисления, иначе она повлияет на ввод обычных счетчиков (если не выйти из программы)
      g_tp := 0;
      raise;
    end;

    return l_ret;
  end;

  function opl_liter(p_opl_man in number) return number is
  begin
    --таблица для возврата норматива потребления (в литрах) по соотв.площади на человека
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
  --создание ввода на доме
    select count(*) into cnt_
      from c_vvod c where c.house_id=house_id_ and c.usl=usl_
        and c.vvod_num=num_;
    if cnt_ = 0 then
      --создаем ввод
      insert into c_vvod(house_id, usl, vvod_num)
        values (house_id_, usl_, num_)
        returning id into id_;
      commit;
      return id_;
    else
      --данный ввод уже существует в доме!
      return -1;
    end if;
  end;

  function delete_vvod (id_ c_vvod.id%TYPE)
           RETURN number is
    cnt_ number;
  begin
  --удаление ввода на доме
    select count(*) into cnt_
      from c_vvod c where c.id=id_;
    if cnt_ = 1 then
      --удаляем ввод
      begin
       delete from c_vvod c where c.id=id_;
      exception
      when others then
        raise_application_error(-20001,
                                'Данный ввод используется, удалите все ссылки в карточках на него!');
      end;
      commit;
      return 0;
    else
      --данный ввод НЕ существует в доме!
      return 1;
    end if;
  end;

  --создать подъезд для klsk дома (для ГИС ЖКХ)
  function create_vvod_by_house_klsk (p_klsk number, p_num c_vvod.vvod_num%TYPE)
           RETURN number is
    l_vvod_klsk number;
  begin
    begin
      --попытаться вернуть имеющийся
      select d.fk_k_lsk into l_vvod_klsk
        from c_houses h, c_vvod d where h.k_lsk_id=p_klsk and d.usl is null
          and d.vvod_num=p_num and d.house_id=h.id;
    exception
    when NO_DATA_FOUND then
      --ввода нет, создать
      for c in (select h.id from c_houses h where h.k_lsk_id=p_klsk)
      loop
        insert into c_vvod(house_id, vvod_num)
          values (c.id, p_num)
          returning fk_k_lsk into l_vvod_klsk;
        exit;
      end loop;
   end;
   --вернуть klsk ввода
   return l_vvod_klsk;

  end;

end p_vvod;
/

