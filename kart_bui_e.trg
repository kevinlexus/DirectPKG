CREATE OR REPLACE TRIGGER SCOTT.kart_bui_e
  before update or insert on kart
  for each row
declare
  house_id_ number;
  var_ number;
  correct_lg_ number;
  aud_text_ log_actions.text%type;
  status_txt_ status.name%type;
  status_txt2_ status.name%type;
  street_txt_ spul.name%type;
  street_txt2_ spul.name%type;
  l_usl usl.usl%type;
  l_id number;
  l_cnt number;
  l_tp_cd u_list.cd%type;
  l_write_for_trg number;
begin

   l_write_for_trg:=0;

   aud_text_:='';

   if :new.mg1 > :new.mg2 and :new.mg2 is not null then
        raise_application_error(-20001,
       'Некорректный период закрытия счета!');
   end if;

   if :new.psch is null then
        raise_application_error(-20001,
       'Попытка установить пустое значение признака счёта!');
   end if;
   if :new.kw is null then
        raise_application_error(-20001,
       'Попытка установить пустой № квартиры!');
   end if;
   if :new.nd is null then
        raise_application_error(-20001,
       'Попытка установить пустой № дома!');
   end if;

   if updating  then
   --Аудит по прочим параметрам
   --общ.пл.
   if nvl(:new.opl,0) <> nvl(:old.opl,0) then
    l_write_for_trg:=1;
    aud_text_:=aud_text_||logger.log_text('Общ.площадь.', :old.opl, :new.opl);
   end if;
   --Этаж
   if nvl(:new.et,0) <> nvl(:old.et,0) then
    aud_text_:=aud_text_||logger.log_text('Этаж', :old.et, :new.et);
   end if;
   --Комнат
   if nvl(:new.komn,0) <> nvl(:old.komn,0) then
    aud_text_:=aud_text_||logger.log_text('Комнат', :old.komn, :new.komn);
   end if;
   --Кол-во прожив.
   if nvl(:new.kpr,0) <> nvl(:old.kpr,0) then
    aud_text_:=aud_text_||logger.log_text('Кол-во прожив.', :old.kpr, :new.kpr);
   end if;
   --Кол-во вр.зарег.
   if nvl(:new.kpr_wr,0) <> nvl(:old.kpr_wr,0) then
    aud_text_:=aud_text_||logger.log_text('Кол-во вр.зарег.', :old.kpr_wr, :new.kpr_wr);
   end if;
   --Кол-во вр.отсут.
   if nvl(:new.kpr_ot,0) <> nvl(:old.kpr_ot,0) then
    aud_text_:=aud_text_||logger.log_text('Кол-во вр.отсут.', :old.kpr_ot, :new.kpr_ot);
   end if;
   --Кол-во льготников
   if nvl(:new.ki,0) <> nvl(:old.ki,0) then
    aud_text_:=aud_text_||logger.log_text('Кол-во льготников', :old.ki, :new.ki);
   end if;

   --Дата договора (для Энерг+)
   if (:new.schel_dt <> :old.schel_dt
     and :new.schel_dt is not null and :old.schel_dt is not null) or
     (:new.schel_dt is null and :old.schel_dt is not null) or
     (:new.schel_dt is not null and :old.schel_dt is null) then
    aud_text_:=aud_text_||logger.log_text('Дата начала договора:',
      to_char(:old.schel_dt,'DD.MM.YYYY'), to_char(:new.schel_dt,'DD.MM.YYYY'));
   end if;
   if (:new.schel_end <> :old.schel_end
     and :new.schel_end is not null and :old.schel_end is not null) or
     (:new.schel_end is null and :old.schel_end is not null) or
     (:new.schel_end is not null and :old.schel_end is null) then
    aud_text_:=aud_text_||logger.log_text('Дата окончания договора:',
      to_char(:old.schel_end,'DD.MM.YYYY'), to_char(:new.schel_end,'DD.MM.YYYY'));
   end if;

   if nvl(:new.psch,0) <> nvl(:old.psch,0) then
   --при изменении типов счетчиков чистим их расходы-показания

   --дата открытия-закрытия счета
     if :new.psch in (8,9) then
       :new.schel_end:=trunc(sysdate);
       else
       if :new.schel_dt is null then
         :new.schel_dt:=trunc(sysdate);
       end if;
       :new.schel_end:=null;
     end if;
   end if;

   --PSCH
   if nvl(:new.psch,0) <> nvl(:old.psch,0) then
     select decode(:old.psch, 0, 'Норматив', 1, 'Счетчики Х.В,Г.В', 2,
       'Счетчик Х.В', 3, 'Счетчик Г.В', 8, 'Старый фонд', 9, 'Закрытый л.с.')
       into status_txt_ from dual;
     select decode(:new.psch, 0, 'Норматив', 1, 'Счетчики Х.В,Г.В', 2,
       'Счетчик Х.В', 3, 'Счетчик Г.В', 8, 'Старый фонд', 9, 'Закрытый л.с.')
       into status_txt2_ from dual;

    aud_text_:=aud_text_||logger.log_text('Признак счета, счетчика.', status_txt_,
     status_txt2_);
   end if;

   --SCH_EL
   if nvl(:new.sch_el,0) <> nvl(:old.sch_el,0) then
     select decode(nvl(:old.sch_el,0), 0, 'Норматив', 1, 'Счетчик')
       into status_txt_ from dual;
     select decode(nvl(:new.sch_el,0), 0, 'Норматив', 1, 'Счетчик')
       into status_txt2_ from dual;

    aud_text_:=aud_text_||logger.log_text('Признак счетчика Эл.Эн.', status_txt_,
     status_txt2_);
   end if;

  :new.kw:=substr(lpad(rtrim(:new.kw), 7,'0'),1,7);

/* -- не должны меняться ID домов!
  if nvl(:new.house_id,-1) <> nvl(:old.house_id,-1) then
    --изменился ID дома
    select h.nd into :new.nd from c_houses h
      where h.id=:new.house_id;
  elsif nvl(:new.kul,'XXXXXXXX') <> nvl(:old.kul,'XXXXXXXX')
     or nvl(:new.nd,'XXXXXXXX') <> nvl(:old.nd,'XXXXXXXX') then
   :new.nd:=substr(lpad(rtrim(:new.nd), 6,'0'),1,6);
   select max(h.id) into house_id_ --max - чтоб не было exception
    from c_houses h               --считает правильно (primary key на h.id)
    where h.reu=:new.reu and
      h.kul=:new.kul and
      h.nd=:new.nd
      and nvl(h.psch,0) = 0;
    if house_id_ is null then --не найдено указанного дома для вставки в kart
      RAISE_APPLICATION_ERROR(-20001, 'Указанный дом не найден!');
    else
      :new.house_id:=house_id_;
    end if;
  end if;
*/
  --Аудит
  if :new.kw <> :old.kw then
    l_write_for_trg:=1;
    aud_text_:=aud_text_||logger.log_text('№ квартиры', :old.kw, :new.kw);
  end if;
  if :new.kul <> :old.kul then
    l_write_for_trg:=1;
    select s.name into street_txt_ from spul s where s.id=:old.kul;
    select s.name into street_txt2_ from spul s where s.id=:new.kul;
    aud_text_:=aud_text_||logger.log_text('Улица', street_txt_, street_txt2_);
  end if;
  if :new.nd <> :old.nd then
    l_write_for_trg:=1;
    aud_text_:=aud_text_||logger.log_text('№ дома', :old.nd, :new.nd);
  end if;

  if nvl(:new.cpn,0) <> nvl(:old.cpn,0) then
    aud_text_:=aud_text_||logger.log_text('Признак не начисления пени', nvl(:old.cpn,0) , nvl(:new.cpn,0) );
  end if;

  if nvl(to_char(:new.pn_dt,'DD.MM.YYYY'),'xxx') <> nvl(to_char(:old.pn_dt,'DD.MM.YYYY'),'xxx') then
    aud_text_:=aud_text_||logger.log_text('Дата ограничения начисления пени',
      nvl(to_char(:old.pn_dt,'DD.MM.YYYY'),'') , nvl(to_char(:new.pn_dt,'DD.MM.YYYY'),'') );
  end if;

   --найм убрал такое поведение триггера 16.05.2018 по просьбе Кис. (заметили что автоматом меняется)
/*   if :new.status <> :old.status and :new.status = 1 then
    update nabor n set n.koeff =1 where n.lsk=:old.lsk and n.usl='026';
   elsif :new.status <> :old.status and :new.status <> 1 then
    update nabor n set n.koeff =0 where n.lsk=:old.lsk and n.usl='026';
   end if;
*/
   if :new.status <> :old.status then
    --записать лиц. для обновления статуса, в "дополнительном л/c"
    l_write_for_trg:=1;

    select s.name into status_txt_ from status s where s.id=:old.status;
    select s.name into status_txt2_ from status s where s.id=:new.status;
    aud_text_:=aud_text_||logger.log_text('Статус', status_txt_, status_txt2_);

   end if;


-- ########################################################################
-- ТОЛЬКО В СТАРОЙ ВЕРСИИ!!!
-- ########################################################################
if utils.get_int_param('VER_METER1') = 0 then
   --работаем с показаниями счетчиков
  select nvl(p.cnt_sch,0) into var_ from params p;
   select nvl(count(*),0) into l_cnt  from c_reg_sch t, u_list i
      where t.id=(select max(c.id) from c_reg_sch c, usl u, u_list s where c.lsk=:new.lsk
      and c.lsk=t.lsk
      and c.fk_usl=u.usl
      and c.fk_state=s.id
      and u.cd='х.вода'
      and exists
      (select * from u_list u where u.cd='Поверка ПУ'
        and u.id=c.fk_tp)
      )
      and t.lsk=:new.lsk
      and t.fk_state=i.id
      and i.cd='Неисправен ПУ';

   --показания х.в.
   if nvl(:new.phw,0) <> nvl(:old.phw,0) and :new.psch in (1,2) and var_ = 1
       and nvl(:new.mhw,0) = nvl(:old.mhw,0) then
       :new.mhw:=nvl(:new.mhw,0)+nvl(:new.phw,0)-nvl(:old.phw,0);
       aud_text_:=aud_text_||logger.log_text('Показ.сч.Х.В.', :old.phw, :new.phw);
   end if;
   if l_cnt <> 0 then
     --не испр.ПУ
     :new.phw:=null;
   end if;

   select nvl(count(*),0) into l_cnt  from c_reg_sch t, u_list i
      where t.id=(select max(c.id) from c_reg_sch c, usl u, u_list s where c.lsk=:new.lsk
      and c.lsk=t.lsk
      and c.fk_usl=u.usl
      and c.fk_state=s.id
      and u.cd='г.вода'
      and exists
      (select * from u_list u where u.cd='Поверка ПУ'
        and u.id=c.fk_tp)
      )
      and t.lsk=:new.lsk
      and t.fk_state=i.id
      and i.cd='Неисправен ПУ';

   --показания г.в.
   if nvl(:new.pgw,0) <> nvl(:old.pgw,0) and :new.psch in (1,3) and var_ = 1
       and nvl(:new.mgw,0) = nvl(:old.mgw,0) then
       :new.mgw:=nvl(:new.mgw,0)+nvl(:new.pgw,0)-nvl(:old.pgw,0);
       aud_text_:=aud_text_||logger.log_text('Показ.сч.Г.В.', :old.pgw, :new.pgw);
   end if;
   if l_cnt <> 0 then
     --не испр.ПУ
     :new.pgw:=null;
   end if;

   select nvl(count(*),0) into l_cnt  from c_reg_sch t, u_list i
      where t.id=(select max(c.id) from c_reg_sch c, usl u, u_list s where c.lsk=:new.lsk
      and c.lsk=t.lsk
      and c.fk_usl=u.usl
      and c.fk_state=s.id
      and u.cd in ('эл.энерг.2','эл.эн.учет УО')
      and exists
      (select * from u_list u where u.cd='Поверка ПУ'
        and u.id=c.fk_tp)
      )
      and t.lsk=:new.lsk
      and t.fk_state=i.id
      and i.cd='Неисправен ПУ';

   --показания эл.эн.
   if nvl(:new.pel,0) <> nvl(:old.pel,0) and var_ = 1
       and nvl(:new.mel,0) = nvl(:old.mel,0) then
       :new.mel:=nvl(:new.mel,0)+nvl(:new.pel,0)-nvl(:old.pel,0);
       aud_text_:=aud_text_||logger.log_text('Показ.сч.Эл.Эн.', :old.pel, :new.pel);
   end if;
   if l_cnt <> 0 then
     --не испр.ПУ
     :new.pel:=null;
   end if;


   --показания сч.отопления
   if nvl(:new.pot,0) <> nvl(:old.pot,0) and var_ = 1
       and nvl(:new.mot,0) = nvl(:old.mot,0) then
       :new.mot:=nvl(:new.mot,0)+nvl(:new.pot,0)-nvl(:old.pot,0);
       aud_text_:=aud_text_||logger.log_text('Показ.сч.Отопления.', :old.pot, :new.pot);
   end if;

--###### учет счетчиков в t_objxpar #######
    --счетчики
    --х.в. счетчики
    select trim(max(t.usl)) into l_usl from usl t where t.counter='phw';
    if l_usl is not null then
      if inserting and :new.phw is not null then
         l_id:=c_obj_par.ins_num_param(null, :new.lsk,
           'ins_sch', :new.phw,
           l_usl, nvl(p_vvod.g_tp,0));
      elsif updating and nvl(:new.phw,0)<>nvl(:old.phw,0) then
         l_id:=c_obj_par.ins_num_param(null, :old.lsk,
           'ins_sch', :new.phw,
           l_usl, nvl(p_vvod.g_tp,0));
      end if;
    end if;

    --х.в. расход
    if inserting and :new.mhw is not null then
       l_id:=c_obj_par.ins_num_param(null, :new.lsk,
         'ins_vol_sch', nvl(:new.mhw,0),
         l_usl, nvl(p_vvod.g_tp,0));
    elsif updating and nvl(:new.mhw,0)<>nvl(:old.mhw,0) then
       l_id:=c_obj_par.ins_num_param(null, :old.lsk,
         'ins_vol_sch', nvl(:new.mhw,0)-nvl(:old.mhw,0),
         l_usl, nvl(p_vvod.g_tp,0));
    end if;

    --г.в. счетчики
    select trim(max(t.usl)) into l_usl from usl t where t.counter='pgw';
    if l_usl is not null then
      if inserting and :new.pgw is not null then
         l_id:=c_obj_par.ins_num_param(null, :new.lsk,
           'ins_sch', :new.pgw,
           l_usl, nvl(p_vvod.g_tp,0));
      elsif updating and nvl(:new.pgw,0)<>nvl(:old.pgw,0) then
         l_id:=c_obj_par.ins_num_param(null, :old.lsk,
           'ins_sch', :new.pgw,
           l_usl, nvl(p_vvod.g_tp,0));
      end if;
    end if;

    --г.в. расход
    if inserting and :new.mgw is not null then
       l_id:=c_obj_par.ins_num_param(null, :new.lsk,
         'ins_vol_sch', :new.mgw,
         l_usl, nvl(p_vvod.g_tp,0));
    elsif updating and nvl(:new.mgw,0)<>nvl(:old.mgw,0) then
       l_id:=c_obj_par.ins_num_param(null, :old.lsk,
         'ins_vol_sch', nvl(:new.mgw,0)-nvl(:old.mgw,0),
         l_usl, nvl(p_vvod.g_tp,0));
    end if;

    --эл.эн. счетчики
    select trim(max(t.usl)) into l_usl from usl t where t.counter='pel';
    if l_usl is not null then
      if inserting and :new.pel is not null then
         l_id:=c_obj_par.ins_num_param(null, :new.lsk,
           'ins_sch', :new.pel,
           l_usl, nvl(p_vvod.g_tp,0));
      elsif updating and nvl(:new.pel,0)<>nvl(:old.pel,0) then
         l_id:=c_obj_par.ins_num_param(null, :old.lsk,
           'ins_sch', :new.pel,
           l_usl, nvl(p_vvod.g_tp,0));
      end if;
    end if;
    --эл.эн. расход
    if inserting and :new.mel is not null then
       l_id:=c_obj_par.ins_num_param(null, :new.lsk,
         'ins_vol_sch', :new.mel,
         l_usl, nvl(p_vvod.g_tp,0));
    elsif updating and nvl(:new.mel,0)<>nvl(:old.mel,0) then
       l_id:=c_obj_par.ins_num_param(null, :old.lsk,
         'ins_vol_sch', nvl(:new.mel,0)-nvl(:old.mel,0),
         l_usl, nvl(p_vvod.g_tp,0));
    end if;

    --отопление счетчики
    select trim(max(t.usl)) into l_usl from usl t where t.counter='pot';
    if l_usl is not null then
      if inserting and :new.pot is not null then
         l_id:=c_obj_par.ins_num_param(null, :new.lsk,
           'ins_sch', :new.pot,
           l_usl, nvl(p_vvod.g_tp,0));
      elsif updating and nvl(:new.pot,0)<>nvl(:old.pot,0) then
         l_id:=c_obj_par.ins_num_param(null, :old.lsk,
           'ins_sch', :new.pot,
           l_usl, nvl(p_vvod.g_tp,0));
      end if;
    end if;
    --отопление расход
    if inserting and :new.mot is not null then
       l_id:=c_obj_par.ins_num_param(null, :new.lsk,
         'ins_vol_sch', :new.mot,
         l_usl, nvl(p_vvod.g_tp,0));
    elsif updating and nvl(:new.mot,0)<>nvl(:old.mot,0) then
       l_id:=c_obj_par.ins_num_param(null, :old.lsk,
         'ins_vol_sch', nvl(:new.mot,0)-nvl(:old.mot,0),
         l_usl, nvl(p_vvod.g_tp,0));
    end if;

--###### учет счетчиков в t_objxpar #######

   --Аудит по расходу х.в.
   --х.в.
   if nvl(:new.mhw,0) <> nvl(:old.mhw,0) then
    aud_text_:=aud_text_||logger.log_text('Расход.Х.В.', :old.mhw, :new.mhw);
   end if;
   --г.в.
   if nvl(:new.mgw,0) <> nvl(:old.mgw,0) then
    aud_text_:=aud_text_||logger.log_text('Расход.Г.В.', :old.mgw, :new.mgw);
   end if;
   --эл.эн.
   if nvl(:new.mel,0) <> nvl(:old.mel,0) then
    aud_text_:=aud_text_||logger.log_text('Расход.Эл.Эн.', :old.mel, :new.mel);
   end if;
   --отопление
   if nvl(:new.mot,0) <> nvl(:old.mot,0) then
    aud_text_:=aud_text_||logger.log_text('Расход.Отопл.', :old.mot, :new.mot);
   end if;
  end if;

end if;
-- ########################################################################
-- ТОЛЬКО В СТАРОЙ ВЕРСИИ!!!
-- ########################################################################


  --аудит
  if inserting then
    logger.log_act(:new.lsk, 'Добавление л/c '||:new.lsk, 2);
  elsif updating then
    if length(aud_text_) > 0 then
      logger.log_act(:new.lsk, 'Обновление л/c: '||:new.lsk||' '||aud_text_, 2);
    end if;
  end if;

  if nvl(:new.k_fam,'x') <> nvl(:old.k_fam,'x') or nvl(:new.k_im,'x') <> nvl(:old.k_im,'x') or
    nvl(:new.k_ot,'x') <> nvl(:old.k_ot,'x') then

    --записать лиц. для обновления ФИО, в "дополнительном л/c"
    l_write_for_trg:=1;
/*    select tp.cd into l_tp_cd from v_lsk_tp tp where tp.id=:new.fk_tp;
    if l_tp_cd='LSK_TP_MAIN' and nvl(c_charges.trg_klsk_flag,0)=0 then
      c_charges.trg_tab_klsk.extend;
      c_charges.trg_tab_klsk(c_charges.trg_tab_klsk.last):= :new.k_lsk_id;
    end if;  */

    aud_text_:=logger.log_text('Обновление Ф.И.О. квартиросъемщика:', :old.k_fam||' '||:old.k_im||' '||:old.k_ot,
     :new.k_fam||' '||:new.k_im||' '||:new.k_ot);
    logger.log_act(:new.lsk, 'Обновление л/c: '||:new.lsk||' '||aud_text_, 2);
  end if;
  :new.k_fam:=initcap(:new.k_fam);
  :new.k_im:=initcap(:new.k_im);
  :new.k_ot:=initcap(:new.k_ot);
  :new.fio:=:new.k_fam||' '||:new.k_im||' '||:new.k_ot;

  if l_write_for_trg=1 then
    select tp.cd into l_tp_cd from v_lsk_tp tp where tp.id=:new.fk_tp;
    if l_tp_cd='LSK_TP_MAIN' and nvl(c_charges.trg_klsk_flag,0)=0 then
      c_charges.trg_tab_klsk.extend;
      c_charges.trg_tab_klsk(c_charges.trg_tab_klsk.last):= :new.k_lsk_id;
    end if;
  end if;


end;
/

