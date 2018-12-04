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
  aud_text_:='��������� ������ '||trim(txt_)||' c �����.='||:new.koeff||' � ����������='||:new.norm
  ||' � ���='||l_org_name;
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
      RAISE_APPLICATION_ERROR(-20001, '�� ������ '||trim(txt_)||'- �� ������ ��������������� ����!');
    end if;
    aud_text_:=aud_text_||logger.log_text('���������� ���� �� ������ '||trim(txt_)||': ', :old.fk_vvod, :new.fk_vvod);
  end if;

  select nvl(count(*),0) into l_cnt
     from usl u where u.usl=:new.usl and u.sptarn=1;
  if l_cnt <> 0
   and nvl(:new.koeff,0) <> 0 then
    RAISE_APPLICATION_ERROR(-20001, '�� ������ '||trim(txt_)||'-����������� �� ��������!');
  end if;

  select nvl(count(*),0) into l_cnt
     from usl u where u.usl=:new.usl and u.sptarn=0;
  if l_cnt <> 0
    and nvl(:new.norm,0) <> 0 then
    RAISE_APPLICATION_ERROR(-20001, '�� ������ '||trim(txt_)||'-�������� �� ��������!');
  end if;

elsif deleting then
  --��������� ������� ������������ � ������ ������������,
  --������� �������� ���������� ������� ��������������
  select nvl(count(*),0) into l_cnt
    from c_change t, params p where t.lsk=:old.lsk and
     t.mgchange >= p.period and t.org is null
     and t.usl=:old.usl;
  if l_cnt > 0 then
    Raise_application_error(-20000, '������� �������� ������, �� ������� ������� ����������� ������� �������� ����������! �.�: '||:old.lsk);
  end if;

  select trim(nm) into txt_ from usl u where u.usl=:old.usl;
  select trim(o.name) into l_org_name from t_org o where o.id=:old.org;
  aud_text_:='������� ������ '||trim(txt_)||' � �����.='||:old.koeff||' � ����������='||:old.norm
  ||' � ���='||l_org_name;
  if length(aud_text_) > 0 then
    logger.log_act(:old.lsk, aud_text_, 2);
  end if;
end if;
end;
/

