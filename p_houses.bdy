create or replace package body scott.P_HOUSES is

  function create_house(reu_ in kart.reu%type, kul_ in c_houses.kul%type,
    nd_ in c_houses.nd%type) return number is
   house_id_ number;
   k_lsk_id_ number;
   l_fk_klsk_premise number;
   maxlsk_ kart.lsk%type;
  begin
     select max(c.id) into house_id_ from c_houses c
      where c.kul=kul_ and c.nd=lpad(trim(nd_), 6, '0');
     if house_id_ is not null then
      RAISE_APPLICATION_ERROR(-20001, 'Указан существующий дом!');
     else 
       --добавляем новый дом
       --сам дом
       if utils.get_int_param('HAVE_PASP') = 1 then
       --если есть паспортный - ставим null
         insert into c_houses h (h.id, h.kul, h.nd)
          values(c_house_id.nextval, kul_, lpad(nd_,6,'0'));
         select c_house_id.currval into house_id_ from dual;
       else
       --если паспортного нет, берем первый id из базы (значит 1 имеется код паспортного)
         insert into c_houses h (h.id, h.kul, h.nd)
          values(c_house_id.nextval, kul_, lpad(nd_,6,'0'));
         select c_house_id.currval into house_id_ from t_org t,
         t_org_tp tp where t.fk_orgtp=tp.id and tp.cd='Паспортный стол';
       end if;

       --первый лицевой по дому
       select k_lsk_id.nextval into k_lsk_id_ from dual;
       insert into k_lsk (id, fk_addrtp)
         select k_lsk_id_, u.id
         from u_list u, u_listtp tp
         where
         u.cd='flat' and tp.cd='object_type';

      maxlsk_:=find_unq_lsk(reu_, null);
      -- klsk Помещения
      l_fk_klsk_premise:=ins_unq_k_lsk('PREMISE',1);
       --добавляем 1 -ый лиц.счет
       insert into kart k (lsk, reu, kul, nd, kw, psch, kpr, kpr_wr,
         kpr_ot, status, kfg, kfot, house_id, k_lsk_id, fk_klsk_premise, mg1, mg2, fk_tp)
       select maxlsk_, reu_, kul_, lpad(nd_,6,'0'), '0000001',
          0, 0, 0, 0, 2, 2, 2, house_id_, k_lsk_id_, l_fk_klsk_premise, p.period, '999999', tp.id as fk_tp
          from params p, v_lsk_tp tp
          where tp.cd='LSK_TP_MAIN';
       insert into kart_detail (lsk)  
        select maxlsk_ from dual;
   
       --добавить статус счета обязательно (норматив)
        insert into c_states_sch(lsk, fk_status)
        values
        (maxlsk_, 0);
      commit;
      return 1;
    end if;
  end;

  PROCEDURE house_add_usl(p_lvl     IN NUMBER,
                          lsk_      IN kart.lsk%TYPE,
                          house_id_ IN c_houses.id%TYPE,
                          p_reu     IN kart.reu%TYPE,
                          p_trest   IN kart.reu%TYPE,
                          usl_      IN nabor.usl%TYPE,
                          org_      IN nabor.org%TYPE,
                          koeff_    IN NUMBER,
                          norm_     IN NUMBER,
                          p_chrg in number) IS
    sptarn_ NUMBER;
    p_lsk_tp varchar2(256);
  BEGIN
    --Добавление услуги по лс/дому/фонду/городу, (по данному коэфф-нормативу, организации)
    --в те л.с. в которых их нет
    SELECT MAX(u.sptarn) INTO sptarn_ FROM usl u WHERE u.usl = usl_;
    p_lsk_tp:=utils.getScd_list_param('REP_TP_SCH_SEL');
    SELECT u.sptarn INTO sptarn_ FROM usl u WHERE u.usl = usl_;
    IF nvl(p_lvl, 0) = 0 THEN
      --по Городу
      IF sptarn_ = 0 AND nvl(koeff_, 0) <> 0 THEN
        --коэфф
        INSERT INTO nabor
          (lsk, usl, org, koeff, norm)
          SELECT k.lsk, usl_, org_, koeff_, NULL AS norm
            FROM kart k, v_lsk_tp tp
           WHERE NOT EXISTS (SELECT *
                    FROM nabor n
                   WHERE n.lsk = k.lsk
                     AND n.usl = usl_)
           and k.fk_tp=tp.id
           and tp.cd=p_lsk_tp;
      ELSIF sptarn_ = 1 AND nvl(norm_, 0) <> 0 THEN
        --норматив
        INSERT INTO nabor
          (lsk, usl, org, koeff, norm)
          SELECT k.lsk, usl_, org_, NULL AS koeff, norm_
            FROM kart k, v_lsk_tp tp
           WHERE NOT EXISTS (SELECT *
                    FROM nabor n
                   WHERE n.lsk = k.lsk
                     AND n.usl = usl_)
           and k.fk_tp=tp.id
           and tp.cd=p_lsk_tp;
      ELSIF sptarn_ IN (2, 3, 4) AND nvl(koeff_, 0) <> 0 AND nvl(norm_, 0) <> 0 THEN
        --и коэфф и норматив
        INSERT INTO nabor
          (lsk, usl, org, koeff, norm)
          SELECT k.lsk, usl_, org_, koeff_, norm_
            FROM kart k, v_lsk_tp tp
           WHERE NOT EXISTS (SELECT *
                    FROM nabor n
                   WHERE n.lsk = k.lsk
                     AND n.usl = usl_)
           and k.fk_tp=tp.id
           and tp.cd=p_lsk_tp;
      END IF;
    ELSIF nvl(p_lvl, 0) = 1 THEN
      --по Фонду
      IF sptarn_ = 0 AND nvl(koeff_, 0) <> 0 THEN
        --коэфф
        INSERT INTO nabor
          (lsk, usl, org, koeff, norm)
          SELECT k.lsk, usl_, org_, koeff_, NULL AS norm
            FROM kart k, v_lsk_tp tp
           WHERE
             EXISTS (SELECT *
                  FROM kart t, s_reu_trest s
                 WHERE k.lsk = t.lsk
                   AND t.reu = s.reu
                   AND s.trest = p_trest)
             AND NOT EXISTS (SELECT *
                    FROM nabor n
                   WHERE n.lsk = k.lsk
                     AND n.usl = usl_)
             and k.fk_tp=tp.id
             and tp.cd=p_lsk_tp;
      ELSIF sptarn_ = 1 AND nvl(norm_, 0) <> 0 THEN
        --норматив
        INSERT INTO nabor
          (lsk, usl, org, koeff, norm)
          SELECT k.lsk, usl_, org_, NULL AS koeff, norm_
            FROM kart k, v_lsk_tp tp
           WHERE
            EXISTS (SELECT *
                  FROM kart t, s_reu_trest s
                 WHERE k.lsk = t.lsk
                   AND t.reu = s.reu
                   AND s.trest = p_trest)
             AND NOT EXISTS (SELECT *
                    FROM nabor n
                   WHERE n.lsk = k.lsk
                     AND n.usl = usl_)
             and k.fk_tp=tp.id
             and tp.cd=p_lsk_tp;
      ELSIF sptarn_ IN (2, 3, 4) AND nvl(koeff_, 0) <> 0 AND nvl(norm_, 0) <> 0 THEN
        --и коэфф и норматив
        INSERT INTO nabor
          (lsk, usl, org, koeff, norm)
          SELECT k.lsk, usl_, org_, koeff_, norm_
            FROM kart k, v_lsk_tp tp
           WHERE
            EXISTS (SELECT *
                  FROM kart t, s_reu_trest s
                 WHERE k.lsk = t.lsk
                   AND t.reu = s.reu
                   AND s.trest = p_trest)
             AND NOT EXISTS (SELECT *
                    FROM nabor n
                   WHERE n.lsk = k.lsk
                     AND n.usl = usl_)
             and k.fk_tp=tp.id
             and tp.cd=p_lsk_tp;
      END IF;
    ELSIF nvl(p_lvl, 0) = 2 THEN
      --по УК
      IF sptarn_ = 0 AND nvl(koeff_, 0) <> 0 THEN
        --коэфф
        INSERT INTO nabor
          (lsk, usl, org, koeff, norm)
          SELECT k.lsk, usl_, org_, koeff_, NULL AS norm
            FROM kart k, v_lsk_tp tp
           WHERE
             EXISTS (SELECT *
                  FROM kart t
                 WHERE k.lsk = t.lsk
                   AND t.reu = p_reu)
             AND NOT EXISTS (SELECT *
                    FROM nabor n
                   WHERE n.lsk = k.lsk
                     AND n.usl = usl_)
             and k.fk_tp=tp.id
             and tp.cd=p_lsk_tp;
      ELSIF sptarn_ = 1 AND nvl(norm_, 0) <> 0 THEN
        --норматив
        INSERT INTO nabor
          (lsk, usl, org, koeff, norm)
          SELECT k.lsk, usl_, org_, NULL AS koeff, norm_
            FROM kart k, v_lsk_tp tp
           WHERE
            EXISTS (SELECT *
              FROM kart t
             WHERE k.lsk = t.lsk
               AND t.reu = p_reu)
             AND NOT EXISTS (SELECT *
                    FROM nabor n
                   WHERE n.lsk = k.lsk
                     AND n.usl = usl_)
             and k.fk_tp=tp.id
             and tp.cd=p_lsk_tp;
      ELSIF sptarn_ IN (2, 3, 4) AND nvl(koeff_, 0) <> 0 AND nvl(norm_, 0) <> 0 THEN
        --и коэфф и норматив
        INSERT INTO nabor
          (lsk, usl, org, koeff, norm)
          SELECT k.lsk, usl_, org_, koeff_, norm_
            FROM kart k, v_lsk_tp tp
           WHERE
            EXISTS (SELECT *
              FROM kart t
             WHERE k.lsk = t.lsk
               AND t.reu = p_reu)
             AND NOT EXISTS (SELECT *
                    FROM nabor n
                   WHERE n.lsk = k.lsk
                     AND n.usl = usl_)
             and k.fk_tp=tp.id
             and tp.cd=p_lsk_tp;
      END IF;
    ELSIF nvl(p_lvl, 0) = 3 THEN
      --по дому
      IF sptarn_ = 0 AND nvl(koeff_, 0) <> 0 THEN
        --коэфф
        INSERT INTO nabor
          (lsk, usl, org, koeff, norm)
          SELECT k.lsk, usl_, org_, koeff_, NULL AS norm
            FROM kart k, v_lsk_tp tp
           WHERE k.house_id = house_id_
             AND NOT EXISTS (SELECT *
                    FROM nabor n
                   WHERE n.lsk = k.lsk
                     AND n.usl = usl_)
             and k.fk_tp=tp.id
             and tp.cd=p_lsk_tp
             and k.reu = p_reu;
      ELSIF sptarn_ = 1 AND nvl(norm_, 0) <> 0 THEN
        --норматив
        INSERT INTO nabor
          (lsk, usl, org, koeff, norm)
          SELECT k.lsk, usl_, org_, NULL AS koeff, norm_
            FROM kart k, v_lsk_tp tp
           WHERE k.house_id = house_id_
             AND NOT EXISTS (SELECT *
                    FROM nabor n
                   WHERE n.lsk = k.lsk
                     AND n.usl = usl_)
             and k.fk_tp=tp.id
             and tp.cd=p_lsk_tp
             and k.reu = p_reu;
      ELSIF sptarn_ IN (2, 3, 4) AND nvl(koeff_, 0) <> 0 AND nvl(norm_, 0) <> 0 THEN
        --и коэфф и норматив
        INSERT INTO nabor
          (lsk, usl, org, koeff, norm)
          SELECT k.lsk, usl_, org_, koeff_, norm_
            FROM kart k, v_lsk_tp tp
           WHERE k.house_id = house_id_
             AND NOT EXISTS (SELECT *
                    FROM nabor n
                   WHERE n.lsk = k.lsk
                     AND n.usl = usl_)
             and k.fk_tp=tp.id
             and tp.cd=p_lsk_tp
             and k.reu = p_reu;
      END IF;
    ELSIF nvl(p_lvl, 0) = 4 THEN
      --по л/с
      INSERT INTO nabor
        (lsk, usl, org, koeff, norm)
        SELECT k.lsk, usl_, org_, koeff_, norm_
          FROM kart k
         WHERE k.lsk = lsk_
           AND NOT EXISTS (SELECT *
                  FROM nabor n
                 WHERE n.lsk = k.lsk
                   AND n.usl = usl_);
      --по л/c коммит не делается
    END IF;
    --переcчет начислений
    if p_chrg =1 then
     c_charges.gen_chrg_all(p_lvl, house_id_, p_reu, p_trest);
    end if;
    COMMIT;
  END;

  PROCEDURE house_chng_usl(p_lvl      IN NUMBER,
                           house_id_  IN c_houses.id%TYPE,
                           p_reu      IN kart.reu%TYPE,
                           p_trest    IN kart.reu%TYPE,
                           usl_       IN nabor.usl%TYPE,
                           old_org_   IN nabor.org%TYPE,
                           new_org_   IN nabor.org%TYPE,
                           old_koeff_ IN NUMBER,
                           old_norm_  IN NUMBER,
                           new_koeff_ IN NUMBER,
                           new_norm_  IN NUMBER,
                           p_chrg in number) IS
    sptarn_ NUMBER;
    p_lsk_tp varchar2(256);  
  BEGIN
    --Изменение услуги (по данному коэфф-нормативу, организации)
    p_lsk_tp:=utils.getScd_list_param('REP_TP_SCH_SEL');
    SELECT u.sptarn INTO sptarn_ FROM usl u WHERE u.usl = usl_;
    IF nvl(p_lvl, 0) = 0 THEN
      --по Городу
      IF sptarn_ = 0 THEN
        --коэфф
        UPDATE nabor n
           SET n.koeff = ROUND(nvl(new_koeff_, 0),10), n.org = new_org_
         WHERE n.usl = usl_
           AND ROUND(nvl(n.koeff, 0),10) = ROUND(nvl(old_koeff_, 0),10)
           AND n.org = old_org_
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=p_lsk_tp
                          );
      ELSIF sptarn_ = 1 THEN
        --норматив
        UPDATE nabor n
           SET n.norm = ROUND(nvl(new_norm_, 0),10), n.org = new_org_
         WHERE n.usl = usl_
           AND ROUND(nvl(n.norm, 0),10) = ROUND(nvl(old_norm_, 0),10)
           AND n.org = old_org_
                    and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=p_lsk_tp
                          );
      ELSIF sptarn_ IN (2, 3, 4) THEN
        --и коэфф и норматив
        UPDATE nabor n
           SET n.koeff = ROUND(nvl(new_koeff_, 0),10),
             n.norm = ROUND(nvl(new_norm_, 0),10), n.org = new_org_
         WHERE n.usl = usl_
           AND ROUND(nvl(n.koeff, 0),10) = ROUND(nvl(old_koeff_, 0),10)
           AND ROUND(nvl(n.norm, 0),10) = ROUND(nvl(old_norm_, 0),10)
           AND n.org = old_org_
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=p_lsk_tp
                          );
          
      END IF;
    ELSIF nvl(p_lvl, 0) = 1 THEN
      --по Фонду
      IF sptarn_ = 0 THEN
        --коэфф
        UPDATE nabor n
           SET n.koeff = ROUND(nvl(new_koeff_, 0),10), n.org = new_org_
         WHERE EXISTS (SELECT *
                  FROM kart k, s_reu_trest s
                 WHERE k.lsk = n.lsk
                   AND k.reu = s.reu
                   AND s.trest = p_trest)
           AND n.usl = usl_
           AND ROUND(nvl(n.koeff, 0),10) = ROUND(nvl(old_koeff_, 0),10)
           AND n.org = old_org_
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=p_lsk_tp
                          );

      ELSIF sptarn_ = 1 THEN
        --норматив
        UPDATE nabor n
           SET n.norm = ROUND(nvl(new_norm_, 0),10), n.org = new_org_
         WHERE EXISTS (SELECT *
                  FROM kart k, s_reu_trest s
                 WHERE k.lsk = n.lsk
                   AND k.reu = s.reu
                   AND s.trest = p_trest)
           AND n.usl = usl_
           AND ROUND(nvl(n.norm, 0),10) = ROUND(nvl(old_norm_, 0),10)
           AND n.org = old_org_
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=p_lsk_tp
                          );
           
      ELSIF sptarn_ IN (2, 3, 4) THEN
        --и коэфф и норматив
        UPDATE nabor n
           SET n.koeff = ROUND(nvl(new_koeff_, 0),10),
               n.norm = ROUND(nvl(new_norm_, 0),10), n.org = new_org_
         WHERE EXISTS (SELECT *
                  FROM kart k, s_reu_trest s
                 WHERE k.lsk = n.lsk
                   AND k.reu = s.reu
                   AND s.trest = p_trest)
           AND n.usl = usl_
           AND ROUND(nvl(n.koeff, 0),10) = ROUND(nvl(old_koeff_, 0),10)
           AND ROUND(nvl(n.norm, 0),10) = ROUND(nvl(old_norm_, 0),10)
           AND n.org = old_org_
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=p_lsk_tp
                          );
           
      END IF;
    ELSIF nvl(p_lvl, 0) = 2 THEN
      --по УК
      IF sptarn_ = 0 THEN
        --коэфф
        UPDATE nabor n
           SET n.koeff = ROUND(nvl(new_koeff_, 0),10), n.org = new_org_
         WHERE EXISTS (SELECT *
                  FROM kart k
                 WHERE k.lsk = n.lsk
                   AND k.reu = p_reu)
           AND n.usl = usl_
           AND ROUND(nvl(n.koeff, 0),10) = ROUND(nvl(old_koeff_, 0),10)
           AND n.org = old_org_
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=p_lsk_tp
                          );
           
      ELSIF sptarn_ = 1 THEN
        --норматив
        UPDATE nabor n
           SET n.norm = ROUND(nvl(new_norm_, 0),10), n.org = new_org_
         WHERE EXISTS (SELECT *
                  FROM kart k
                 WHERE k.lsk = n.lsk
                   AND k.reu = p_reu)
           AND n.usl = usl_
           AND ROUND(nvl(n.norm, 0),10) = ROUND(nvl(old_norm_, 0),10)
           AND n.org = old_org_
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=p_lsk_tp
                          );
           
      ELSIF sptarn_ IN (2, 3, 4) THEN
        --и коэфф и норматив
        UPDATE nabor n
           SET n.koeff = ROUND(nvl(new_koeff_, 0),10),
               n.norm = ROUND(nvl(new_norm_, 0),10), n.org = new_org_
         WHERE EXISTS (SELECT *
                  FROM kart k
                 WHERE k.lsk = n.lsk
                   AND k.reu = p_reu)
           AND n.usl = usl_
           AND ROUND(nvl(n.koeff, 0),10) = ROUND(nvl(old_koeff_, 0),10)
           AND ROUND(nvl(n.norm, 0),10) = ROUND(nvl(old_norm_, 0),10)
           AND n.org = old_org_
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=p_lsk_tp
                          );
           
      END IF;
    ELSIF nvl(p_lvl, 0) = 3 THEN
      --по дому
      IF sptarn_ = 0 THEN
        --коэфф
        UPDATE nabor n
           SET n.koeff = ROUND(nvl(new_koeff_, 0),10), n.org = new_org_
         WHERE EXISTS (SELECT *
                  FROM kart k
                 WHERE k.lsk = n.lsk
                   AND k.house_id = house_id_
                   and k.reu = p_reu)
           AND n.usl = usl_
           AND ROUND(nvl(n.koeff, 0),10) = ROUND(nvl(old_koeff_, 0),10)
           AND n.org = old_org_
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=p_lsk_tp
                          );
           
      ELSIF sptarn_ = 1 THEN
        --норматив
        UPDATE nabor n
           SET n.norm = ROUND(nvl(new_norm_, 0),10), n.org = new_org_
         WHERE EXISTS (SELECT *
                  FROM kart k
                 WHERE k.lsk = n.lsk
                   AND k.house_id = house_id_
                   and k.reu = p_reu)
           AND n.usl = usl_
           AND ROUND(nvl(n.norm, 0),10) = ROUND(nvl(old_norm_, 0),10)
           AND n.org = old_org_
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=p_lsk_tp
                          );
           
      ELSIF sptarn_ IN (2, 3, 4) THEN
        --и коэфф и норматив
        UPDATE nabor n
           SET n.koeff = ROUND(nvl(new_koeff_, 0),10),
               n.norm = ROUND(nvl(new_norm_, 0),10), n.org = new_org_
         WHERE EXISTS (SELECT *
                  FROM kart k
                 WHERE k.lsk = n.lsk
                   AND k.house_id = house_id_
                   and k.reu = p_reu)
           AND n.usl = usl_
           AND ROUND(nvl(n.koeff, 0),10) = ROUND(nvl(old_koeff_, 0),10)
           AND ROUND(nvl(n.norm, 0),10) = ROUND(nvl(old_norm_, 0),10)
           AND n.org = old_org_
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=p_lsk_tp
                          );
           
      END IF;
    ELSIF nvl(p_lvl, 0) = 4 THEN
      --по л/с
      --нет, потому что изменяются параметры в самой карточке
      NULL;
    END IF;

    IF SQL%NOTFOUND THEN
        Raise_application_error(-20000, 'Не произведено изменений!');
    ELSE
      --переcчет начислений
      if p_chrg =1 then
        c_charges.gen_chrg_all(p_lvl, house_id_, p_reu, p_trest);
      end if;
      COMMIT;
    END IF;
  END;

  PROCEDURE house_del_usl(p_lvl     IN NUMBER,
                          lsk_      IN kart.lsk%TYPE,
                          house_id_ IN c_houses.id%TYPE,
                          p_reu      IN kart.reu%TYPE,
                          p_trest    IN kart.reu%TYPE,
                          usl_      IN nabor.usl%TYPE,
                          org_      IN nabor.org%TYPE,
                          koeff_    IN NUMBER,
                          norm_     IN NUMBER,
                          p_chrg in number) IS
    sptarn_ NUMBER;
    l_sel varchar2(256);
  BEGIN
    --Удаление услуги (по данному коэфф-нормативу, организации)
    SELECT MAX(u.sptarn) INTO sptarn_ FROM usl u WHERE u.usl = usl_;
    l_sel:=utils.getScd_list_param('REP_TP_SCH_SEL');
    IF nvl(p_lvl, 0) = 0 THEN
      --по Городу
      IF sptarn_ = 0 THEN
        --коэфф
        DELETE FROM nabor n
         WHERE
           n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff, 0) = nvl(koeff_, 0)
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=l_sel
                          );
           
      ELSIF sptarn_ = 1 THEN
        --норматив
        DELETE FROM nabor n
         WHERE
           n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff, 0) = nvl(norm_, 0)
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=l_sel
                          );
          
      ELSIF sptarn_ IN (2, 3, 4) THEN
        --и коэфф и норматив
        DELETE FROM nabor n
         WHERE
           n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff, 0) = nvl(koeff_, 0)
           AND nvl(n.norm, 0) = nvl(norm_, 0)
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=l_sel
                          );
           
      END IF;
    ELSIF nvl(p_lvl, 0) = 1 THEN
      --по Фонду
      IF sptarn_ = 0 THEN
        --коэфф
        DELETE FROM nabor n
         WHERE EXISTS (SELECT *
                  FROM kart k, s_reu_trest s
                 WHERE k.lsk = n.lsk
                   AND k.reu=s.reu
                   AND s.trest = p_trest)
           AND n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff, 0) = nvl(koeff_, 0)
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=l_sel
                          );
           
      ELSIF sptarn_ = 1 THEN
        --норматив
        DELETE FROM nabor n
         WHERE EXISTS (SELECT *
                  FROM kart k, s_reu_trest s
                 WHERE k.lsk = n.lsk
                   AND k.reu=s.reu
                   AND s.trest = p_trest)
           AND n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff, 0) = nvl(norm_, 0)
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=l_sel
                          );
           
      ELSIF sptarn_ IN (2, 3, 4) THEN
        --и коэфф и норматив
        DELETE FROM nabor n
         WHERE EXISTS (SELECT *
                  FROM kart k, s_reu_trest s
                 WHERE k.lsk = n.lsk
                   AND k.reu=s.reu
                   AND s.trest = p_trest)
           AND n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff, 0) = nvl(koeff_, 0)
           AND nvl(n.norm, 0) = nvl(norm_, 0)
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=l_sel
                          );
           
      END IF;
    ELSIF nvl(p_lvl, 0) = 2 THEN
      --по УК
      IF sptarn_ = 0 THEN
        --коэфф
        DELETE FROM nabor n
         WHERE EXISTS (SELECT *
                  FROM kart k
                 WHERE k.lsk = n.lsk
                   AND k.reu = p_reu)
           AND n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff, 0) = nvl(koeff_, 0)
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=l_sel
                          );
           
      ELSIF sptarn_ = 1 THEN
        --норматив
        DELETE FROM nabor n
         WHERE EXISTS (SELECT *
                  FROM kart k
                 WHERE k.lsk = n.lsk
                   AND k.reu = p_reu)
           AND n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff, 0) = nvl(norm_, 0)
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=l_sel
                          );
           
      ELSIF sptarn_ IN (2, 3, 4) THEN
        --и коэфф и норматив
        DELETE FROM nabor n
         WHERE EXISTS (SELECT *
                  FROM kart k
                 WHERE k.lsk = n.lsk
                   AND k.reu = p_reu)
           AND n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff, 0) = nvl(koeff_, 0)
           AND nvl(n.norm, 0) = nvl(norm_, 0)
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=l_sel
                          );
           
      END IF;
    ELSIF nvl(p_lvl, 0) = 3 THEN
      --по дому
      IF sptarn_ = 0 THEN
        --коэфф
        DELETE FROM nabor n
         WHERE EXISTS (SELECT *
                  FROM kart k
                 WHERE k.lsk = n.lsk
                   AND k.house_id = house_id_
                   and k.reu = p_reu)
           AND n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff, 0) = nvl(koeff_, 0)
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=l_sel
                          );
           
      ELSIF sptarn_ = 1 THEN
        --норматив
        DELETE FROM nabor n
         WHERE EXISTS (SELECT *
                  FROM kart k
                 WHERE k.lsk = n.lsk
                   AND k.house_id = house_id_
                   and k.reu = p_reu)
           AND n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff, 0) = nvl(norm_, 0)
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=l_sel
                          );
           
      ELSIF sptarn_ IN (2, 3, 4) THEN
        --и коэфф и норматив
        DELETE FROM nabor n
         WHERE EXISTS (SELECT *
                  FROM kart k
                 WHERE k.lsk = n.lsk
                   AND k.house_id = house_id_
                   and k.reu = p_reu)
           AND n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff, 0) = nvl(koeff_, 0)
           AND nvl(n.norm, 0) = nvl(norm_, 0)
           and exists (select * from kart k, v_lsk_tp tp where k.lsk=n.lsk
                          and k.fk_tp=tp.id
                          and tp.cd=l_sel
                          );
           
      END IF;
    ELSIF nvl(p_lvl, 0) = 4 THEN
      --по л/с
      IF sptarn_ = 0 THEN
        --коэфф
        DELETE FROM nabor n
         WHERE n.lsk = lsk_
           AND n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff,0) = koeff_;
      ELSIF sptarn_ = 1 THEN
        --норматив
        DELETE FROM nabor n
         WHERE n.lsk = lsk_
           AND n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff,0) = norm_;
      ELSIF sptarn_ IN (2, 3, 4) THEN
        --и коэфф и норматив
        DELETE FROM nabor n
         WHERE n.lsk = lsk_
           AND n.usl = usl_
           AND n.org = org_
           AND nvl(n.koeff,0) = koeff_
           AND nvl(n.norm,0) = norm_;
      END IF;
    END IF;
    IF SQL%NOTFOUND THEN
        Raise_application_error(-20000, 'Не произведено изменений!');
    ELSIF nvl(p_lvl, 0) <> 4 THEN
      --по л/c коммит и перерасчет не делается
      --переcчет начислений
      if p_chrg =1 then
        c_charges.gen_chrg_all(p_lvl, house_id_, p_reu, p_trest);
      end if;
      COMMIT;
    END IF;
  END;

  PROCEDURE change_house_status(
     house_id_ in c_houses.id%TYPE,
     status_ in kart.status%TYPE,
     old_status_ in kart.status%TYPE) is
  begin
  --изменение статуса квартир дома (муницип, приват)
  update kart k set k.status=status_ where k.status=old_status_
   and k.house_id=house_id_;
  commit;

  end;

  PROCEDURE change_house_vvod(
     house_id_ in c_houses.id%TYPE,
     usl_ in nabor.usl%type,
     fk_vvod_new_ in nabor.fk_vvod%TYPE,
     fk_vvod_old_ in nabor.fk_vvod%TYPE) is
  begin
  --изменение № ввода квартир дома
  update nabor n set n.fk_vvod=fk_vvod_new_
    where nvl(n.fk_vvod,0)=fk_vvod_old_
     and n.usl=usl_
     and exists
     (select * from kart k where
             k.house_id=house_id_ and k.lsk=n.lsk);
  commit;

  end;


   function change_tarif(tsource_ in number, tdest_ in number)
   return number is
    cnt_ number;
  begin
  -- замена тарифа в лицевых счетах
    --кол-во л.с., использующих тариф
    select count(*) into cnt_ from nabor n
      where n.fk_tarif=tsource_;
    if cnt_ <> 0 then
     update nabor n set n.fk_tarif=tdest_
       where n.fk_tarif=tsource_;
    end if;
  ----удаляем из справочника тарифов--- зачем????
  --  delete from spr_tarif s where s.id=tsource_;
  --  commit;
    return cnt_;

  end;

  /* function add_prog(lsk_ in nabor_progs.lsk%type, fk_tarif_ in nabor_progs.fk_tarif%type,
     parent_id_ in nabor_progs.parent_id%type, usl_ in nabor_progs.usl%type)
   return number is
    cnt_ number;
    cnt2_ number;
    root_id_ number;
  begin
  -- добавление пакета/программы из справочника в набор абонента
    cnt_:=0;
    --кол-во л.с., использующих тариф
    select nvl(count(*),0) into cnt2_ from nabor_progs n
      where n.lsk=lsk_;
    if cnt2_ = 0 then
    --если нет вообще программ в наборе, добавим корневой
       insert into nabor_progs(id, parent_id, lsk, usl, fk_tarif)
       select nabor_progs_id.nextval, null, lsk_, usl_, t.id
        from spr_tarif t where t.cd='000';
      select nabor_progs_id.currval into root_id_ from dual;
    else
  --    root_id_:=parent_id_;
     --запрещаем добавлять программы не в корень набора
      select n.id into root_id_ from
        nabor_progs n, spr_tarif t where n.lsk=lsk_ and
          n.fk_tarif=t.id
          and t.cd = '000';
    end if;

    --если нет программы в наборе
    select nvl(count(*),0) into cnt2_ from nabor_progs n
      where n.lsk=lsk_ and n.fk_tarif=fk_tarif_;
    if cnt2_ = 0 then
       select
       insert into nabor_progs(id, parent_id, lsk, usl, fk_tarif)
       select nabor_progs_id.nextval, root_id_, lsk_, usl_, s.id from
         spr_tarif s
         start with id=fk_tarif_
         connect by s.parent_id=prior s.id;
    else
      --программа уже существует в наборе абонента
      cnt_:=1;
    end if;
  --  commit;
    return cnt_;

  end;
  */

   function change_prog_tarif(id_ in spr_tarif.id%type,
     parent_id_ in spr_tarifxprogs.fk_tarif%type,
     old_parent_id_ in spr_tarifxprogs.fk_tarif%type)
   return number is
   cnt_ number;
  begin
  -- перемещение пакета/программы в справочнике тарифов
    cnt_:=0;

    delete from spr_tarifxprogs t where t.fk_tarif=parent_id_ and t.fk_prog=id_;
    delete from spr_tarifxprogs t where t.fk_tarif=old_parent_id_ and t.fk_prog=id_;
    insert into spr_tarifxprogs
      (fk_tarif, fk_prog)
    values
      (parent_id_, id_);
    return cnt_;
  end;

   function copy_prog_tarif(id_ in spr_tarif.id%type,
     parent_id_ in spr_tarifxprogs.fk_tarif%type)
   return number is
   cnt_ number;
  begin
  -- копирование пакета/программы в справочнике тарифов
    cnt_:=0;

    delete from spr_tarifxprogs t where t.fk_tarif=parent_id_ and t.fk_prog=id_;
    insert into spr_tarifxprogs
      (fk_tarif, fk_prog)
    values
      (parent_id_, id_);
    return cnt_;
  end;

   function del_prog_tarif(id_ in spr_tarif.id%type,
     parent_id_ in spr_tarifxprogs.fk_tarif%type)
   return number is
   cnt2_ number;
   cnt_ number;
  begin
    -- Удаление программы из пакета в справочнике тарифов
    cnt_:=0;
    delete from spr_tarifxprogs t where t.fk_tarif=parent_id_ and t.fk_prog=id_;
    -- удаление вообще из справочника тарифов, если не используется
    -- другими пакетами и наборами абонента
    select nvl(count(*),0) into cnt2_ from (
    select 1 as cnt from nabor_progs n
     where n.fk_tarif=id_
     union all
    select 1 as cnt from nabor n
     where n.fk_tarif=id_);
    if cnt2_ <> 0 then
      cnt_:=1;
    else
      delete from spr_tarif t where t.id=id_ and not exists
        (select * from spr_tarifxprogs p where p.fk_prog=t.id);
    end if;
    return cnt_;
  end;

  PROCEDURE add_house_list(p_err OUT varchar2, p_fk_house IN t_housexlist.fk_house%TYPE,
                           p_fk_list  IN t_housexlist.fk_list%TYPE) IS
  l_cnt number;
  BEGIN

    if to_char(sysdate,'YYYYMM')>='201307' then
      --отловить, кто пользуется этим функционалом
      --пользуется Э+ - сделать миграцию в нормальные параметры k_lsk_id!!!
      Raise_application_error(-20000, 'Ошибка #1554! в пакете P_HOUSES');
    end if;
    --добавить реквизит по дому (например Участок)
    --если его еще не существует
    SELECT nvl(COUNT(*), 0)
      INTO l_cnt
      FROM t_housexlist t
     WHERE t.fk_house = p_fk_house
       AND EXISTS (SELECT * FROM
         u_list s, u_list u
         WHERE u.id=p_fk_list
           AND s.fk_listtp=u.fk_listtp
           AND s.id=t.fk_list);
    IF l_cnt <> 0 THEN
      --Вернуть ошибку
      p_err:='Реквизит данным типом уже существует в доме!';
    ELSE
      --Добавить реквизит
      INSERT INTO t_housexlist
        (fk_list, fk_house, kul, nd)
        SELECT p_fk_list, p_fk_house, t.kul, t.nd
          FROM c_houses t
          WHERE
          t.id=p_fk_house;
      COMMIT;
      p_err:=null;
    END IF;
  END;

  PROCEDURE del_house_list(p_id IN t_housexlist.id%TYPE) IS
  BEGIN
    if to_char(sysdate,'YYYYMM')>='201307' then
      --отловить, кто пользуется этим функционалом
      --пользуется Э+ - сделать миграцию в нормальные параметры k_lsk_id!!!
      Raise_application_error(-20000, 'Ошибка #1555! в пакете P_HOUSES');
    end if;
    --удалить реквизит по дому (например Участок)
    DELETE FROM t_housexlist t
       WHERE t.id=p_id;
    COMMIT;
  END;

   function add_prog(lsk_ in nabor_progs.lsk%type, fk_tarif_ in nabor_progs.fk_tarif%type,
     usl_ in nabor_progs.usl%type, id_dvb_ in number)
   return number is
    cnt_ number;
    cnt2_ number;
  begin
  -- добавление пакета/программы из справочника в набор абонента
    cnt_:=0;
  --  select t.id into root_id_
  --   from spr_tarif t where t.cd='000';
    --кол-во л.с., использующих тариф
  --  select nvl(count(*),0) into cnt2_ from nabor_progs n
  --    where n.lsk=lsk_;

  --  if cnt2_ = 0 then
    --если нет вообще программ в наборе, добавим корневой
  --     insert into nabor_progs(lsk, usl, fk_tarif)
  --     values (lsk_, usl_, root_id_);
  --  end if;

    --если нет программы в наборе ???????????
  --  select nvl(count(*),0) into cnt2_ from nabor_progs n
  --    where n.lsk=lsk_ and n.fk_tarif=fk_tarif_;
    select nvl(count(*),0) into cnt2_ from nabor_progs n
      where n.lsk=lsk_ and n.fk_tarif=fk_tarif_;/* and exists
      (select * from
         spr_tarif s
         where s.id=n.fk_tarif
         start with s.id=fk_tarif_
         connect by s.parent_id=prior s.id)*/

    if cnt2_ = 0 then
       insert into nabor_progs(lsk, usl, fk_tarif, id_dvb)
       select lsk_, usl_, s.id, id_dvb_ from
         spr_tarif s
         where s.id=fk_tarif_;
  /*     select decode(level, 1, root_id_, s.parent_id), lsk_, usl_, s.id from
         spr_tarif s
         start with s.id=fk_tarif_
         connect by s.parent_id=prior s.id;*/
    else
      --программа уже существует в наборе абонента
      cnt_:=1;
    end if;
  --  commit;
    return cnt_;

  end;

   function del_prog(lsk_ in nabor_progs.lsk%type, id_ in nabor_progs.fk_tarif%type)
   return number is
   cnt_ number;
  begin
  -- удаление пакета/программы в наборе абонента
     delete from nabor_progs n
        where n.lsk=lsk_ and n.fk_tarif=id_;
        /* and exists (select * from
         spr_tarif s
         where s.id=n.fk_tarif
         start with s.id=id_
         connect by s.parent_id=prior s.id)*/
     --удаляем из набора корневую запись
     --если кроме неё нет больше записей
     select nvl(count(*),0) into cnt_ from
       nabor_progs n, spr_tarif s where n.lsk=lsk_ and
       s.id=n.fk_tarif and s.cd<>'000';

     if cnt_ = 0 then
       delete from nabor_progs n where n.lsk=lsk_;
     end if;

   return 0;
  end;

   function del_prog(lsk_ in nabor_progs.lsk%type)
   return number is
  begin
  -- удаление всех пакетов/программ из набора абонента
     delete from nabor_progs n
        where n.lsk=lsk_;
     --удаляем из набора корневую запись
     delete from nabor_progs n where n.lsk=lsk_;

   return 0;
  end;

  -- добавить уникальный k_lsk, найти дырку по возможности
  FUNCTION ins_unq_k_lsk(p_addr_tp_cd in varchar2, p_search_holes in number) RETURN number IS
  BEGIN
    LOCK TABLE k_lsk IN EXCLUSIVE MODE; -- блокировка будет длиться до следующего COMMIT;
    if p_search_holes=1 then
      for c in (select a.rn, s.id as fk_addr_tp
                  from (select rownum as rn from k_lsk) a
                  left join k_lsk k
                    on a.rn = k.id
                  join u_list s on s.cd=p_addr_tp_cd  
                 where k.id is null
                 order by a.rn) loop
        insert into k_lsk (id, fk_addrtp) values (c.rn, c.fk_addr_tp);
        return c.rn;
      end loop;
    end if;
    -- не найдены дырки, получить следующий id
    insert into k_lsk
      (id, fk_addrtp)
    select 
      k_lsk_id.nextval, s.id as fk_addrtp
       from u_list s where s.cd=p_addr_tp_cd;
    return k_lsk_id.currval;

  end;


  FUNCTION find_unq_lsk(p_reu IN kart.reu%type, 
                        p_lsk in kart.lsk%type --рекоммендованый лиц.сч.
    ) RETURN VARCHAR2 IS
    l_cnt NUMBER;
    l_i number;
    l_maxlsk kart.lsk%type;
    l_lsk kart.lsk%type; 
    i number;
    l_flag number;
  BEGIN
    --поиск уникальных лицевых, "дырок" в списке л/с по УК
    if p_reu is null then
      i:=1;
      while i<100000000 
      loop
        l_flag:=0;     
        for c in (select k.lsk from kart k
                   where k.lsk=lpad(i, 8, '0')) loop
              l_flag:=1;     
        end loop;
        if l_flag=0 then 
          return lpad(i, 8, '0');
        end if;
        i:=i+1;
      end loop;  
   elsif p_lsk is null then
      FOR c IN (SELECT DISTINCT (substr(k.lsk, 1, 4)) AS sbstr
          FROM kart k WHERE k.reu = p_reu 
          ORDER BY sbstr) LOOP
        for c2 in (with a as (select rownum rn, c.sbstr||lpad(rownum-1,4,'0') as lsk
                   from (select level from dual connect by level <= 10000) k ),
              b as (select k.lsk from kart k)

              select a.lsk from a left join b on a.lsk=b.lsk
                      and b.lsk like c.sbstr||'%' 
              where b.lsk is null and a.lsk <>'00000000'        
              order by a.rn)
        loop
          return c2.lsk;
        end loop;      

        --не было получено из первой 1000, попробовать получить из следующей 5000
        
      END LOOP;
    else 
    --по рекоммендованному лиц.счету
        select trim(max(k.lsk))  into l_maxlsk
          FROM kart k where k.reu=p_reu and k.lsk like p_lsk||'%';
        if l_maxlsk is null then  
          l_i := rpad(p_lsk,8,'0');
        else
          l_i := l_maxlsk;
        end if;  
        WHILE l_i <= 99999999 loop
          l_lsk:=lpad(to_char(l_i),8,'0');
          SELECT NVL(COUNT(*), 0)
            INTO l_cnt
            FROM kart k
           WHERE k.lsk = l_lsk;
          IF l_cnt = 0 and lpad(to_char(l_i),8,'0') <> '00000000' THEN
            RETURN lpad(to_char(l_i),8,'0');
          END IF;
          l_i := l_i + 1;
        END LOOP;
    
    end if;
    
    --не найдено, просто взять последний из базы
     select lpad(max(lsk)+1,8,'0') into l_maxlsk from
       kart k;
    RETURN l_maxlsk;
  END;

  

  --добавить к существующему основному, -дополнительный лицевой счет -по дому
  --(например для капремонта)
  --(ПОКА не используется в программе, сделал для автоматизации добавления) ред.26.09.2018
  function kart_lsk_special_add_house(
           p_house in kart.house_id%type, -- Id дома
           p_lsk_tp in varchar2, -- тип нового лс
           p_forced_status in number, -- принудительно установить статус (null - не устанавливать, 0-открытый и т.п.)
           p_del_usl_from_dst in number, -- удалить услуги из nabor источника (1-удалить,0-нет)
           p_reu in varchar2 -- если указан, применить данный код УК, если нет, оставить УК источника
           ) return number is
    a number;
    l_lsk_new kart.lsk%type;
  begin
    for c in (select k.lsk from kart k join v_lsk_tp tp on k.fk_tp=tp.id
                     where tp.cd='LSK_TP_MAIN'
                     and k.house_id=p_house 
                     and k.psch not in (8,9)
                     )
    loop
      l_lsk_new:=null;
      --создать по каждому открытому л.с.  
      a:=kart_lsk_add(p_lsk_src              => c.lsk,
                           p_lsk_tp           => p_lsk_tp,
                           p_lsk_new          => l_lsk_new,
                           p_get_usl_from_src => 1,
                           p_del_usl_from_src => 1,
                           p_var => 0,
                           p_kw => null,
                           p_reu              => null,
                           p_klsk_dst => null,
                           p_close_src => 0,
                           p_klsk_premise_dst => null
                           );
      if a != 0 then
        -- вернуть код ошибки, если произошла
        return a;
      end if;                     
    end loop;
    return 0;
  end;


  -- скопировать все субсчета (Основной, РСО и т.п.) при разделении финансового лиц.счета клиента и при создании нового помещения
  function kart_lsk_group_add(p_lsk_src in kart.lsk%type,-- лс источника, для копирования лиц.счета
           p_lsk_tp in varchar2, -- тип нового лс (Основной, РСО и т.п.)
           p_lsk_new in kart.lsk%type, -- либо null, либо указан новый лс
           p_get_usl_from_src in number, -- скопировать услуги из nabor источника (1-да,0-нет)
           p_del_usl_from_src in number, -- удалить услуги из nabor источника (1-да,0-нет) (при создании лиц. по капрем.)
           p_kw in varchar2, -- № квартиры
           p_reu in varchar2, -- если указан, применить данный код УК
           p_close_src in number, -- закрыть лицевой источник? (1-да, 0-нет)
           p_var in number  -- 3- новое помещение. Скопировать помещение вместе со всеми лиц счетами
                            -- 4- новый фин.лиц счет. Скопировать все лиц. счета, ID помещения тот же
           ) return number is
    l_klsk_dst number;
    l_klsk_premise_dst number;
    l_lsk_new kart.lsk%type;
    l_var number;
    a number;
  begin
   l_klsk_dst:=ins_unq_k_lsk('flat',0);
   if p_var = 3 then   
     l_var:=2;
     l_klsk_premise_dst:=ins_unq_k_lsk('PREMISE',1);
   elsif p_var = 4 then   
     l_var:=1;  
   end if;  

   for c in (select t.lsk, t.k_lsk_id, tp.cd as tp_cd from kart t join kart k on t.k_lsk_id=k.k_lsk_id 
                    join v_lsk_tp tp on t.fk_tp=tp.id
               where k.lsk=p_lsk_src and t.psch not in (8,9)) loop
     l_lsk_new:=null;
     a:=kart_lsk_add(p_lsk_src          => c.lsk,
                  p_lsk_tp           => c.tp_cd,
                  p_lsk_new          => l_lsk_new,
                  p_get_usl_from_src => p_get_usl_from_src,
                  p_del_usl_from_src => p_del_usl_from_src,
                  p_var              => l_var, -- новый фин лиц.счет или новое помещение
                  p_kw               => p_kw,
                  p_reu              => p_reu,
                  p_klsk_dst         => l_klsk_dst,
                  p_close_src        => p_close_src,
                  p_klsk_premise_dst => l_klsk_premise_dst
                  );
     if a <>0 then
       return a;
     end if;                
    end loop;
    return 0;
  end;


  -- Создание лиц.счета, обертка для Java
  procedure kart_lsk_add(
           p_lsk_tp in varchar2, -- тип нового лс (Основной, РСО и т.п.)
           p_lsk_src in kart.lsk%type default null, -- лс источника, для копирования лиц.счета
           p_lsk_new in out kart.lsk%type, -- либо null, либо указан новый лс
           p_var in number, -- только 0 и 3:  0- новый лиц.счет того же собственника, того же помещения (тот же KLSK, тот же KLSK_PREMISE), 
                            --                3- новое помещение в другом доме (другой KLSK, другой KLSK_PREMISE)
           p_kw in varchar2, -- № квартиры
           p_reu in varchar2, -- если указан, применить данный код УК
           p_house number,-- Id дома
           p_klsk_dst in number, -- klsk фин.лиц.счета
           p_klsk_premise_dst in number, -- klsk помещения
           p_fam in varchar2, -- фамилия
           p_im in varchar2,  -- имя 
           p_ot in varchar2,   -- отчество владельца
           p_result out number 
           ) is
  begin           
    p_result := p_houses.kart_lsk_add(p_lsk_src => p_lsk_src,
                                     p_lsk_tp => p_lsk_tp,
                                     p_lsk_new => p_lsk_new,
                                     p_get_usl_from_src => 0,
                                     p_del_usl_from_src => 0,
                                     p_var => p_var,
                                     p_kw => p_kw,
                                     p_reu => p_reu,
                                     p_klsk_dst => p_klsk_dst,
                                     p_close_src => 0,
                                     p_klsk_premise_dst => p_klsk_premise_dst,
                                     p_house => p_house,
                                     p_fam => p_fam,
                                     p_im => p_im,
                                     p_ot => p_ot
                                     );

  end;

  -- добавить новый лиц.счет
  function kart_lsk_add(
           p_lsk_tp in varchar2, -- тип нового лс (Основной, РСО и т.п.)
           p_lsk_src in kart.lsk%type,-- лс источника, для копирования лиц.счета
           p_lsk_new in out kart.lsk%type, -- либо null, либо указан новый лс
           p_get_usl_from_src in number, -- скопировать услуги из nabor источника (1-да,0-нет)
           p_del_usl_from_src in number, -- удалить услуги из nabor источника (1-да,0-нет) (при создании лиц. по капрем.)
           p_var in number, -- 0- новый лиц.счет того же собственника, того же помещения (тот же KLSK, тот же KLSK_PREMISE), 
                            -- 1- новый фин.лиц.счет (другой KLSK, тот же KLSK_PREMISE)
                            -- 2- новое помещение в том же доме (другой KLSK, другой KLSK_PREMISE) (скопировать дом с указанного в p_lsk_src)
                            -- 3- новое помещение в другом доме (другой KLSK, другой KLSK_PREMISE)
           p_kw in varchar2, -- № квартиры
           p_reu in varchar2, -- если указан, применить данный код УК
           p_klsk_dst in number, -- klsk фин.лиц.счета
           p_close_src in number, -- закрыть лицевой источник? (1-да, 0-нет)
           p_klsk_premise_dst in number, -- klsk помещения
           p_house number default null,-- Id дома
           p_fam in varchar2 default null, -- фамилия
           p_im in varchar2 default null,  -- имя 
           p_ot in varchar2 default null   -- отчество владельца
           ) return number is
    l_lsk kart.lsk%type;
    l_lsk_src kart.lsk%type;
    l_klsk_dst number;
    l_klsk_premise_dst number;
    l_klsk_obj_dst number;
    l_klsk_src number;
    l_klsk_premise_src number;
    l_reu kart.reu%type;
    l_cnt number;
    l_kw kart.kw%type;
    l_kw_src kart.kw%type;
  begin
    -- новый klsk на лиц.счет + блокировка получения нового лиц счета
    l_klsk_obj_dst:=ins_unq_k_lsk('LSK',0);

    if p_lsk_src is null then
      l_reu:=p_reu; 
    else
      l_lsk_src:=lpad(p_lsk_src, 8, '0');
      select nvl(p_reu, t.reu), t.k_lsk_id, t.fk_klsk_premise, t.kw 
        into l_reu, l_klsk_src, l_klsk_premise_src, l_kw_src from kart t where t.lsk=l_lsk_src;
    end if;

    if p_lsk_new is null then
      -- получить новый лс
      l_lsk:=find_unq_lsk(l_reu, null);
      -- сохранить для использования в Java полученный лиц.сч.
      p_lsk_new:=l_lsk;
    else
      l_lsk:=trim(p_lsk_new);
    end if;
    
    begin
      select 1 into l_cnt
       from dual where regexP_like(l_lsk,'[[:digit:]]{8}')
       and length(l_lsk)=8
       and not exists (select * from kart k where k.lsk=l_lsk);
    exception
      when no_data_found then
        return 1; -- формат лиц.счета не соответствует требованиям
    end;

    if p_var=0 then
      -- новый лиц.счет того же собственника, того же помещения (тот же KLSK, тот же KLSK_PREMISE), 
      l_klsk_dst:= l_klsk_src;
      l_klsk_premise_dst:=l_klsk_premise_src;
      l_kw:=l_kw_src;
    elsif p_var=1 then    
      -- новый фин.лиц.счет (другой KLSK, тот же KLSK_PREMISE)
      if p_klsk_dst is not null then
        l_klsk_dst:=p_klsk_dst;
      else
        l_klsk_dst:=ins_unq_k_lsk('flat',0);
      end if;  
      l_klsk_premise_dst:=l_klsk_premise_src;
      l_kw:=l_kw_src;
    elsif p_var=2 then    
      -- новое помещение (другой KLSK, другой KLSK_PREMISE)
      if p_klsk_dst is not null then
        l_klsk_dst:=p_klsk_dst;
      else
        l_klsk_dst:=ins_unq_k_lsk('flat',0);
      end if;  
      if p_klsk_premise_dst is null then 
        l_klsk_premise_dst:=ins_unq_k_lsk('PREMISE',1);
      else 
        l_klsk_premise_dst:=p_klsk_premise_dst;
      end if;  
      if p_kw is not null then
        l_kw:=lpad(p_kw, 7, '0');
      else
        l_kw:=l_kw_src;
      end if;  
    elsif p_var=3 then    
      -- новое помещение (новые: LSK, KLSK, KLSK_PREMISE)
      l_klsk_dst:=ins_unq_k_lsk('flat',0);
      l_klsk_premise_dst:=ins_unq_k_lsk('PREMISE',1);
      l_kw:=lpad(p_kw, 7, '0');
    end if;
    
   
    if p_var=3 then
      -- новый лиц.счет без выполнения копирования с другого лиц.счета
      insert into kart k (lsk, reu, kul, nd, kw, k_fam, k_im, k_ot, psch, 
        status, kfg, kfot, house_id, k_lsk_id, fk_klsk_premise, fk_klsk_obj, mg1, mg2, fk_tp, 
        kpr, kpr_wr, kpr_ot,
        opl, entr)
      select l_lsk, l_reu, h.kul, h.nd, l_kw, p_fam as k_fam, p_im as k_im, p_ot as k_ot,
        0 as psch, s.id as status, 2 as kfg, 2 as kfot, p_house, l_klsk_dst, l_klsk_premise_dst, l_klsk_obj_dst,
        p.period as mg1, '999999' as mg2, tp.id as fk_tp, 
        0 as kpr, 0 as kpr_wr, 0 as kpr_ot, 0 as opl, 
        1 -- 1 подъезд по умолчанию
        from dual k, params p, v_lsk_tp tp, status s, c_houses h
        where tp.cd=p_lsk_tp and s.cd='PRV' and h.id=p_house;
    else 
      -- скопировать на новый лиц счет в том же доме
      insert into kart k (lsk, reu, kul, nd, kw, k_fam, k_im, k_ot, psch, 
        status, kfg, kfot, house_id, k_lsk_id, fk_klsk_premise, fk_klsk_obj, mg1, mg2, fk_tp, 
        kpr, kpr_wr, kpr_ot,
        opl, entr)
      select l_lsk, l_reu, k.kul, k.nd, l_kw, k.k_fam, k.k_im, k.k_ot,
        k.psch, k.status, 2 as kfg, 2 as kfot, k.house_id, l_klsk_dst, l_klsk_premise_dst, l_klsk_obj_dst,
        p.period as mg1, '999999' as mg2, tp.id as fk_tp, 
        0 as kpr, 0 as kpr_wr, 0 as kpr_ot, 
        k.opl, k.entr
        from kart k, params p, v_lsk_tp tp
        where k.lsk=l_lsk_src
        and tp.cd=p_lsk_tp;
    end if;  
      
    if sql%rowcount=0 then
       rollback;
       return 3; -- добавление произошло неудачно, лиц.счет не добавлен!
    end if;   

    insert into kart_detail (lsk)  
      select l_lsk from dual;
   
    if sql%rowcount=0 then
       rollback;
       return 3; -- добавление произошло неудачно, лиц.счет не добавлен!
    end if;   

    if p_lsk_tp='LSK_TP_ADDIT' then
      begin
      insert into nabor
      (lsk, usl, org, koeff, norm)
       select l_lsk, u.usl, o.id as org, 1.18182 as koeff, null as norm
        from usl u 
        join t_org_tp tp on tp.cd='РКЦ' --применить организацию - РКЦ
        join t_org o on o.fk_orgtp=tp.id
        where u.cd='кап.';

       if sql%rowcount=0 then
         rollback;
         return 2; --не добавлены услуги
       end if;  
      exception
        when no_data_found then
          rollback;
          return 2; --не добавлены услуги
      end;    
     -- удалить в старом лиц.счете услуги (обычно капрем.)
     if p_del_usl_from_src = 1 then
        delete from nabor n
           where n.lsk=l_lsk_src and exists (select * from usl u where u.usl=n.usl and u.cd in ('кап.', 'кап/св.нор'));     
     end if;
    elsif p_lsk_tp in ('LSK_TP_MAIN','LSK_TP_RSO') then
      if p_get_usl_from_src = 1 then
        -- скопировать услуги из лиц. источника
        insert into nabor
          (lsk, usl, org, koeff, norm)
        select
           l_lsk, usl, org, koeff, norm
        from nabor n where n.lsk=l_lsk_src;
      end if;  
    end if; 
    -- закрыть лиц.счет - источник при разделе фин.лиц.счетов, если указано
    if p_close_src=1 then
     delete from c_states_sch t where t.lsk=l_lsk_src;
     insert into c_states_sch
        (lsk, fk_status, dt1, dt2, fk_close_reason)
        select k.lsk, 8 as fk_status, to_date(p.period || '01', 'YYYYMMDD') as dt1, null as dt2, a.id as fk_close_reson
          from kart k
          join params p on 1=1
          join (select u.id, s.name
                  from exs.u_list u
                  join exs.u_list s
                    on u.id = s.parent_id
                  join exs.u_listtp t
                    on s.fk_listtp = t.id
                 where t.cd = 'GIS_NSI_22'
                   and s.s1 = 'Изменение реквизитов лицевого счета') a
            on 1 = 1
         where k.lsk = l_lsk_src;
    end if;          
     -- установить статус нового лс (открытый)
     insert into c_states_sch
       (lsk, fk_status, dt1, dt2)
     select l_lsk, 
     0 as fk_status,
     init.get_dt_start, null
     from dual;

  return 0;   
  end;

  procedure set_g_lsk_tp(p_tp in number) is
  begin
    --установить глоб переменную
    g_sel_lsk_tp:=p_tp;
  end;
    
  function get_g_lsk_tp return number is
  begin
    --прочитать глоб переменную
    if g_sel_lsk_tp is null then
       Raise_application_error(-20000, 'Не установленна глоб.перменная g_sel_lsk_tp!');
    end if;
    return g_sel_lsk_tp;
  end;

  --получить открытые лицевые счета которые привязаны к основому (дополнительному) счету, включая входящий лицевой счет
  function get_other_lsk(p_lsk in kart.lsk%type) return tab_lsk is
   t_lsk tab_lsk;
  begin
    select rec_lsk(k.lsk) bulk collect into t_lsk from kart k
     where exists (select * from kart t where t.lsk=p_lsk 
       and t.k_lsk_id=k.k_lsk_id and t.psch not in (8,9));
    return t_lsk;                        

  end;

  --вернуть klsk по GUID дома
  function get_klsk_by_guid(p_guid in varchar2) return number is
   p_klsk number;
  begin

   begin
   select h.k_lsk_id into p_klsk from c_houses h join prep_house_fias f on h.id=f.fk_house
     and upper(f.houseguid)=upper(p_guid);
   exception
     WHEN no_data_found then
       return -1;
     when others then
       raise;
   end;  
   return p_klsk;

  end;  

  end P_HOUSES;
/

