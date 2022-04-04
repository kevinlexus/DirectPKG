CREATE OR REPLACE TRIGGER SCOTT.c_kwtp_mg_ai_e
  after insert on c_kwtp_mg
  for each row
declare
  rec_        c_kwtp_mg%rowtype;
  l_reu       varchar2(3);
  l_Java_Dist number;
begin
  --распределение платежа после вставки строки оплаты
  l_Java_Dist := utils.get_int_param('JAVA_DIST_KWTP_MG');
  if nvl(:new.is_dist, 0) = 0 then
    --если оплата еще не распределена (распределена бывает после реверс.операции)
    if l_Java_Dist <> 0 then
      for c in (select * from c_comps t where t.nkom=:new.nkom) loop
        -- вызов Java распределени€
        p_java.distKwtpMg(:new.id,
                          :new.lsk,
                          :new.summa,
                          :new.penya,
                          :new.debt,
                          :new.dopl,
                          :new.nink,
                          :new.nkom,
                          :new.oper,
                          :new.dtek,
                          :new.dat_ink,
                          c.use_java_queue -- использовать очередь дл€ распределени€?
                            -- не использовать очередь дл€ распределени€ дл€ Ќ≈ банковских компов (проставить это в справочнике c_comps!),
                            -- так как могут начать инкассировать, и т.п. пока распредел€етс€ в очереди. и произойдЄт перекос средств.
                            -- очередь используетс€ только при распределении больших объемов ред. 25.09.2019

                          );
      end loop;
    else
      select :new.lsk, :new.summa, :new.penya, :new.oper, :new.dopl, :new.nink, :new.nkom, :new.dtek, :new.nkvit, :new.dat_ink, :new.ts, :new.c_kwtp_id, :new.cnt_sch, :new.cnt_sch0, :new.id, :new.is_dist
        into rec_.lsk, rec_.summa, rec_.penya, rec_.oper, rec_.dopl, rec_.nink, rec_.nkom, rec_.dtek, rec_.nkvit, rec_.dat_ink, rec_.ts, rec_.c_kwtp_id, rec_.cnt_sch, rec_.cnt_sch0, rec_.id, rec_.is_dist
        from dual;
      if rec_.dtek <= init.g_dt_end then
        --если платЄж прин€т датой, меньшей чем окончание периода,
        --то распределить его по услугам-орг, в противном случае- нет!
        --нужно дл€ того, чтобы не было ошибки кол-ва итераций в c_gen_pay! ред. 15.09.14
        --потом сделать распределение платежей, прин€тых будущими периодами
        if utils.get_int_param('DIST_PAY_TP') = 0 then
          --по-сальдовый способ распределени€ оплаты
          --c_gen_pay.dist_pay_lsk(rec_, 0);
         Raise_application_error(-20000, 'DIST_PAY_TP=0 не используетс€!');
        else
          --по-периодный способ распределени€ оплаты (ѕолыс.)
          select reu into l_reu from kart k where k.lsk = rec_.lsk;
          c_dist_pay.dist_pay_deb_mg_lsk(l_reu, rec_);
        end if;
      end if;

      /* if utils.get_int_param('IS_NOTIF') = 1 then
         -- создать »звещение дл€ √»— ∆ ’
         c_get_pay.create_notification_gis(rec_);
       end if;
      */
    end if;
  end if;
end c_kwtp_mg_ai_e;
/

