CREATE OR REPLACE TRIGGER SCOTT.c_lg_pr_bui_e
  before delete or update or insert on c_lg_pr
  for each row
declare
  aud_text_ log_actions.text%type;
  txt_      spk.name%type;
  txt2_     spk.name%type;
  lsk_ c_kart_pr.lsk%type;
begin
  --проверка на соответствие льготы статусу жилья
  if inserting or updating then
    for c in (select case
                       when :new.type = 1 and s.fk_status_g is not null and
                            s.fk_status_g <> nvl(k.status, 0) then
                        0
                       when :new.type = 0 and s.fk_status_k is not null and
                            s.fk_status_k <> nvl(k.status, 0) then
                        0
                       else
                        1 --соответствует
                     end as correct_lg, p.fio, k.lsk, s.name
                from kart k, c_kart_pr p, c_lg_docs d, spk s
               where k.lsk = p.lsk
                 and p.id = d.c_kart_pr_id
                 and d.id = :new.c_lg_docs_id
                 and s.id = :new.spk_id --без учета выбывших
                 and p.status <> 4) loop
      if c.correct_lg = 0 then
        --льгота не соответствует статусу жилья
        raise_application_error(-20001,
                                'Данная льгота не соответствует статусу жилья, отмена!');
      end if;
      if inserting then
        if :new.type = 1 then
          aud_text_ := 'Добавлена льгота по тек.содерж., по проживающему:';
        else
          aud_text_ := 'Добавлена льгота по коммун.усл., по  по проживающему:';
        end if;
        aud_text_ := aud_text_ || trim(c.fio) || ', ' || trim(c.name);
      elsif updating then
        select s.name into txt_ from spk s where s.id = :old.spk_id;
        select s.name into txt2_ from spk s where s.id = :new.spk_id;
        if :new.type = 1 then
          aud_text_ := 'Обновлена льгота по тек.содерж., по проживающему:';
        else
          aud_text_ := 'Обновлена льгота по коммун.усл., по  по проживающему:';
        end if;
        aud_text_ := aud_text_ || trim(c.fio) || ', ' ||
                     logger.log_text('Льгота',
                                     trim(txt_),
                                     trim(txt2_));
      end if;

      lsk_:=c.lsk;
      exit;
    end loop;
    if length(aud_text_) > 0 then
      logger.log_act(lsk_, aud_text_, 2);
    end if;
  elsif deleting then

    --аудит, вести если не было каскадного удаления из c_kart_pr (иначе mutating в триггере)
    if nvl(c_charges.trg_c_kart_pr_bd,0) = 0 then
      select s.name into txt_ from spk s where s.id = :old.spk_id;
      if :old.type = 1 then
        aud_text_ := 'Удалена льгота по тек.содерж., по проживающему:';
      else
        aud_text_ := 'Удалена льгота по коммун.усл., по проживающему:';
      end if;
      if nvl(c_charges.trg_c_lg_docs_bd, 0) = 1 then
        --каскадное удаление от c_lg_docs...
        aud_text_ := aud_text_ || trim(c_charges.trg_c_lg_docs_bd_fio) || ', ' ||
                     trim(txt_);
        lsk_:=c_charges.trg_c_lg_docs_bd_lsk;
      else
        for c in (select case
                           when :old.type = 1 and s.fk_status_g is not null and
                                s.fk_status_g <> nvl(k.status, 0) then
                            0
                           when :old.type = 0 and s.fk_status_k is not null and
                                s.fk_status_k <> nvl(k.status, 0) then
                            0
                           else
                            1 --соответствует
                         end as correct_lg, p.fio, k.lsk, s.name
                    from kart k, c_kart_pr p, c_lg_docs d, spk s
                   where k.lsk = p.lsk
                     and p.id = d.c_kart_pr_id
                     and d.id = :old.c_lg_docs_id
                     and s.id = :old.spk_id --без учета выбывших
                     and p.status <> 4) loop
          aud_text_ := aud_text_ || trim(c.fio) || ', ' ||
                       trim(txt_);
          lsk_:=c.lsk;
          exit;
        end loop;
      end if;
    if length(aud_text_) > 0 then
      logger.log_act(lsk_, aud_text_, 2);
    end if;
    end if;
  end if;
end;
/

