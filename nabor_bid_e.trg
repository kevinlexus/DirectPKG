CREATE OR REPLACE TRIGGER SCOTT.nabor_bid_e
  before delete or insert on nabor
  for each row
declare
  l_cnt number;
  aud_text_ log_actions.text%type;
  txt_ usl.nm%type;
  l_org_name t_org.name%type;
begin

if inserting then
  select trim(nm) into txt_ from usl u where u.usl=:new.usl;
  select trim(o.name) into l_org_name from t_org o where o.id=:new.org;
  aud_text_:='Добавлена услуга '||trim(txt_)||' c коэфф.='||:new.koeff||' и нормативом='||:new.norm
  ||' и Орг='||l_org_name;
  if length(aud_text_) > 0 then
    logger.log_act(:new.lsk, aud_text_, 2);
  end if;

  if :new.fk_vvod is not null then
    select nvl(count(*),0) into l_cnt
             from kart k where not exists
             (select * from c_vvod c where c.id=:new.fk_vvod
              and c.usl=:new.usl
              and c.house_id=k.house_id)
              and :new.lsk=k.lsk
              and :new.fk_vvod is not null;
              
    select trim(nm) into txt_ from usl u where u.usl=:new.usl;
    if l_cnt <> 0 then
      RAISE_APPLICATION_ERROR(-20001, 'По услуге '||trim(txt_)||'- не найден соответствующий ввод!');
    end if;
    aud_text_:=aud_text_||logger.log_text('Установлен ввод по услуге '||trim(txt_)||': ', :old.fk_vvod, :new.fk_vvod);
  end if;

  select nvl(count(*),0) into l_cnt
     from usl u where u.usl=:new.usl and u.sptarn=1;
  if l_cnt <> 0
   and nvl(:new.koeff,0) <> 0 then
    RAISE_APPLICATION_ERROR(-20001, 'По услуге '||trim(txt_)||'-коэффициент не допустим!');
  end if;

  select nvl(count(*),0) into l_cnt
     from usl u where u.usl=:new.usl and u.sptarn=0;
  if l_cnt <> 0
    and nvl(:new.norm,0) <> 0 then
    RAISE_APPLICATION_ERROR(-20001, 'По услуге '||trim(txt_)||'-норматив не допустим!');
  end if;

elsif deleting then
  --проверить наличие перерасчётов с пустой организацией,
  --которые возможно необходимо удалить предварительно
  select nvl(count(*),0) into l_cnt
    from c_change t, params p where t.lsk=:old.lsk and
     t.mgchange >= p.period and t.org is null
     and t.usl=:old.usl;
  if l_cnt > 0 then
    Raise_application_error(-20000, 'Попытка удаления услуги, по которой имеется действующий текущим периодом перерасчет! Л.С: '||:old.lsk);
  end if;

  select trim(nm) into txt_ from usl u where u.usl=:old.usl;
  select trim(o.name) into l_org_name from t_org o where o.id=:old.org;
  aud_text_:='Удалена услуга '||trim(txt_)||' с коэфф.='||:old.koeff||' и нормативом='||:old.norm
  ||' и Орг='||l_org_name;
  if length(aud_text_) > 0 then
    logger.log_act(:old.lsk, aud_text_, 2);
  end if;
end if;
end;
/

