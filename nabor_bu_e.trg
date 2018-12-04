CREATE OR REPLACE TRIGGER SCOTT.nabor_bu_e
  before update of org, koeff, norm, fk_tarif, vol, vol_add, fk_vvod on nabor
  for each row
declare
  cnt_ number;
  cena_ number;
  id_ number;
  aud_text_ log_actions.text%type;
  txt_ usl.nm%type;
  txt2_ spr_tarif.name%type;
  txt3_ spr_tarif.name%type;
  l_org_name t_org.name%type;
  l_org_name_new t_org.name%type;
begin

--if :new.limit<> :old.limit and :new.limit is not  null then
--  Raise_application_error(-20000, 'TEST');
--end if;

--триггер выполняет проверки и логгинг по измененным полям
if nvl(c_charges.trg_proc_next_month,0) = 0  then
  --не выполнять, если идет переход месяца
  aud_text_:='';
  --обрабатывается ли данная услуга тарифами?
  select nvl(count(*),0) into cnt_
     from spr_tarif t where t.usl=:old.usl;
  if cnt_ > 0 then
    --устанавливаем похожий по цене тариф
    if nvl(init.spr_tarif_upd_,0)=0 then
      if nvl(:old.koeff,0) <> nvl(:new.koeff,0) then
        select max(t.id) into id_ from spr_tarif t, spr_tarif_prices s, params p where t.usl=:old.usl
          and t.id=s.fk_tarif and s.cena=:new.koeff and p.period between s.mg1 and s.mg2;
        :new.fk_tarif:=id_;
      end if;
    end if;
  end if;

  --разрешено ли по данной услуге править ID DVB -декодера
  select nvl(count(*),0) into cnt_
     from usl t where t.usl=:old.usl and nvl(t.n_progs,0)=1;
  select trim(nm) into txt_ from usl u where u.usl=:old.usl;

  --Аудит
  if  nvl(:new.fk_tarif,0) <> nvl(:old.fk_tarif,0) then
    select trim(nm) into txt_ from usl u where u.usl=:old.usl;
    select max(trim(s.name)) into txt2_ from spr_tarif s where s.id=:old.fk_tarif;
    select max(trim(s.name)) into txt3_ from spr_tarif s where s.id=:new.fk_tarif;
    aud_text_:=aud_text_||logger.log_text('Тариф по услуге'||trim(txt_)||': ', txt2_, txt3_);
  end if;

  if  nvl(:new.org,0) <> nvl(:old.org,0) then
    select trim(o.name) into l_org_name from t_org o where o.id=:old.org;
    select trim(o.name) into l_org_name_new from t_org o where o.id=:new.org;
    aud_text_:=aud_text_||logger.log_text('Орг. по '||trim(txt_)||': ', l_org_name, l_org_name_new);
  end if;

  if  nvl(:new.koeff,0) <> nvl(:old.koeff,0) then
    select trim(nm) into txt_ from usl u where u.usl=:old.usl;
    aud_text_:=aud_text_||logger.log_text('Коэфф по '||trim(txt_)||': ', :old.koeff, :new.koeff);
  end if;

  if  nvl(:new.norm,0) <> nvl(:old.norm,0) then
    select trim(nm) into txt_ from usl u where u.usl=:old.usl;
    aud_text_:=aud_text_||logger.log_text('Норматив по '||trim(txt_)||': ', :old.norm, :new.norm);
  end if;

  if  nvl(:new.vol,0) <> nvl(:old.vol,0) then
    select trim(nm) into txt_ from usl u where u.usl=:old.usl;
    aud_text_:=aud_text_||logger.log_text('Распределение по норме '||trim(txt_)||': ', :old.vol, :new.vol);
  end if;

  if  nvl(:new.vol_add,0) <> nvl(:old.vol_add,0) then
    select trim(nm) into txt_ from usl u where u.usl=:old.usl;
    aud_text_:=aud_text_||logger.log_text('Распределение по счетчику '||trim(txt_)||': ', :old.vol_add, :new.vol_add);
  end if;


  if  nvl(:new.fk_vvod,0) <> nvl(:old.fk_vvod,0) then
    select nvl(count(*),0) into cnt_
             from kart k where not exists
             (select * from c_vvod c where c.id=:new.fk_vvod
              and c.usl=:new.usl
              and c.house_id=k.house_id)
              and :new.lsk=k.lsk
              and :new.fk_vvod is not null;
    select trim(nm) into txt_ from usl u where u.usl=:old.usl;
    if cnt_ <> 0 then
      RAISE_APPLICATION_ERROR(-20001, 'По услуге '||trim(txt_)||'- не найден соответствующий ввод!');
    end if;
    aud_text_:=aud_text_||logger.log_text('Установлен ввод по услуге '||trim(txt_)||': ', :old.fk_vvod, :new.fk_vvod);
  end if;

  select nvl(count(*),0) into cnt_
     from usl u where u.usl=:new.usl and u.sptarn=1;
  if cnt_ <> 0
   and nvl(:new.koeff,0) <> 0 then
    RAISE_APPLICATION_ERROR(-20001, 'По услуге '||trim(txt_)||'-коэффициент не допустим!');
  end if;

  select nvl(count(*),0) into cnt_
     from usl u where u.usl=:new.usl and u.sptarn=0;
  if cnt_ <> 0
    and nvl(:new.norm,0) <> 0 then
    RAISE_APPLICATION_ERROR(-20001, 'По услуге '||trim(txt_)||'-норматив не допустим!');
  end if;



  --Энерг +
  if :old.usl='043' and nvl(:new.norm,0)>1 then
    RAISE_APPLICATION_ERROR(-20001, 'По услуге '||trim(txt_)||' -кол-во точек не допустимо больше 1!');
  end if;

  if length(aud_text_) > 0 then
    if nvl(c_charges.trg_c_vvod,0)=0 then
      logger.log_act(:new.lsk, 'Обновление услуг в карточке: '||aud_text_, 2);
    else
      logger.log_act(:new.lsk, 'Распределение объёма по вводу: '||aud_text_, 2);
    end if;
  end if;
end if;
end;
/

