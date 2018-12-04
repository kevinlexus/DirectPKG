CREATE OR REPLACE TRIGGER SCOTT.c_kwtp_mg_ai_e
  after insert on c_kwtp_mg
  for each row
declare
rec_ c_kwtp_mg%rowtype;
l_reu varchar2(3);
begin
--распределение платежа после вставки строки оплаты
 if nvl(:new.is_dist,0) = 0 then
 --если оплата еще не распределена (распределена бывает после реверс.операции)
 select :new.lsk, :new.summa, :new.penya, :new.oper, :new.dopl, :new.nink, :new.nkom, :new.dtek, :new.nkvit,
  :new.dat_ink, :new.ts, :new.c_kwtp_id, :new.cnt_sch, :new.cnt_sch0, :new.id, :new.is_dist
  into rec_.lsk, rec_.summa, rec_.penya, rec_.oper, rec_.dopl, rec_.nink, rec_.nkom, rec_.dtek,
    rec_.nkvit, rec_.dat_ink, rec_.ts, rec_.c_kwtp_id, rec_.cnt_sch, rec_.cnt_sch0,
    rec_.id, rec_.is_dist from dual;
   if rec_.dtek <= init.g_dt_end then
     --если платЄж прин€т датой, меньшей чем окончание периода,
     --то распределить его по услугам-орг, в противном случае- нет!
     --нужно дл€ того, чтобы не было ошибки кол-ва итераций в c_gen_pay! ред. 15.09.14
     --потом сделать распределение платежей, прин€тых будущими периодами
     if utils.get_int_param('DIST_PAY_TP') = 0 then
     --по-сальдовый способ распределени€ оплаты
       c_gen_pay.dist_pay_lsk(rec_, 0);
     else
     --по-периодный способ распределени€ оплаты ( ис., ѕолыс.)
       --сперва подготовить задолжность
       --(не надо, выполн€етс€ в процедуре)
       --c_dist_pay.gen_deb_usl(rec_.lsk);
       --потом распределить оплату
--       if :new.lsk<>'15042520' then
         select reu into l_reu from kart k where k.lsk=rec_.lsk;
         c_dist_pay.dist_pay_deb_mg_lsk(l_reu, rec_);
--       end if;
     end if;
    end if;
 end if;
 
/* if utils.get_int_param('IS_NOTIF') = 1 then
   -- создать »звещение дл€ √»— ∆ ’
   c_get_pay.create_notification_gis(rec_);
 end if;
*/end c_kwtp_mg_ai_e;
/

