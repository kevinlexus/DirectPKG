create or replace package body scott.P_HOUSES is

function create_house(reu_ in kart.reu%type, kul_ in c_houses.kul%type,
  nd_ in c_houses.nd%type) return number is
 cnt_ number;
 house_id_ number;
 k_lsk_id_ number;
 c_lsk_id_ number;
 --ID �����
 vvod_hw_id_ number;
 vvod_gw_id_ number;
 vvod_rkc_id_ number;
 maxlsk_ kart.lsk%type;
 l_elsd k_lsk.elsd%type;
begin
   select max(c.id) into house_id_ from c_houses c
    where c.kul=kul_ and c.nd=lpad(trim(nd_), 6, '0');
   if house_id_ is not null then
    RAISE_APPLICATION_ERROR(-20001, '������ ������������ ���!');
   else 
     --��������� ����� ���
     --��� ���
     if utils.get_int_param('HAVE_PASP') = 1 then
     --���� ���� ���������� - ������ null
       insert into c_houses h (h.id, h.kul, h.nd)
        values(c_house_id.nextval, kul_, lpad(nd_,6,'0'));
       select c_house_id.currval into house_id_ from dual;
     else
     --���� ����������� ���, ����� ������ id �� ���� (������ 1 ������� ��� �����������)
       insert into c_houses h (h.id, h.kul, h.nd)
        values(c_house_id.nextval, kul_, lpad(nd_,6,'0'));
       select c_house_id.currval into house_id_ from t_org t,
       t_org_tp tp where t.fk_orgtp=tp.id and tp.cd='���������� ����';
     end if;

     --������ ������� �� ����
     l_elsd:= get_next_elsd;  
     select k_lsk_id.nextval into k_lsk_id_ from dual;
     insert into k_lsk (id, fk_addrtp, elsd)
       select k_lsk_id_, u.id, l_elsd
       from u_list u, u_listtp tp
       where
       u.cd='flat' and tp.cd='object_type';

     select c_lsk_id.nextval into c_lsk_id_ from dual;
     insert into c_lsk (id)
       values (c_lsk_id_);

    maxlsk_:=find_unq_lsk(reu_, null);
     --��������� 1 -�� ��������
     insert into kart k (lsk, reu, kul, nd, kw, psch, kpr, kpr_wr,
       kpr_ot, status, kfg, kfot, house_id, k_lsk_id, c_lsk_id, mg1, mg2, fk_tp)
     select maxlsk_, reu_, kul_, lpad(nd_,6,'0'), '0000001',
        0, 0, 0, 0, 2, 2, 2, house_id_, k_lsk_id_, c_lsk_id_, p.period, '999999', tp.id as fk_tp
        from params p, v_lsk_tp tp
        where tp.cd='LSK_TP_MAIN';
     --�������� ������ ����� ����������� (��������)
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
  --���������� ������ �� ��/����/�����/������, (�� ������� �����-���������, �����������)
  --� �� �.�. � ������� �� ���
  SELECT MAX(u.sptarn) INTO sptarn_ FROM usl u WHERE u.usl = usl_;
  p_lsk_tp:=utils.getScd_list_param('REP_TP_SCH_SEL');
  SELECT u.sptarn INTO sptarn_ FROM usl u WHERE u.usl = usl_;
  IF nvl(p_lvl, 0) = 0 THEN
    --�� ������
    IF sptarn_ = 0 AND nvl(koeff_, 0) <> 0 THEN
      --�����
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
      --��������
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
      --� ����� � ��������
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
    --�� �����
    IF sptarn_ = 0 AND nvl(koeff_, 0) <> 0 THEN
      --�����
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
      --��������
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
      --� ����� � ��������
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
    --�� ��
    IF sptarn_ = 0 AND nvl(koeff_, 0) <> 0 THEN
      --�����
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
      --��������
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
      --� ����� � ��������
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
    --�� ����
    IF sptarn_ = 0 AND nvl(koeff_, 0) <> 0 THEN
      --�����
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
      --��������
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
      --� ����� � ��������
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
    --�� �/�
    INSERT INTO nabor
      (lsk, usl, org, koeff, norm)
      SELECT k.lsk, usl_, org_, koeff_, norm_
        FROM kart k
       WHERE k.lsk = lsk_
         AND NOT EXISTS (SELECT *
                FROM nabor n
               WHERE n.lsk = k.lsk
                 AND n.usl = usl_);
    --�� �/c ������ �� ��������
  END IF;
  --����c��� ����������
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
  --��������� ������ (�� ������� �����-���������, �����������)
  p_lsk_tp:=utils.getScd_list_param('REP_TP_SCH_SEL');
  SELECT u.sptarn INTO sptarn_ FROM usl u WHERE u.usl = usl_;
  IF nvl(p_lvl, 0) = 0 THEN
    --�� ������
    IF sptarn_ = 0 THEN
      --�����
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
      --��������
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
      --� ����� � ��������
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
    --�� �����
    IF sptarn_ = 0 THEN
      --�����
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
      --��������
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
      --� ����� � ��������
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
    --�� ��
    IF sptarn_ = 0 THEN
      --�����
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
      --��������
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
      --� ����� � ��������
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
    --�� ����
    IF sptarn_ = 0 THEN
      --�����
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
      --��������
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
      --� ����� � ��������
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
    --�� �/�
    --���, ������ ��� ���������� ��������� � ����� ��������
    NULL;
  END IF;

  IF SQL%NOTFOUND THEN
      Raise_application_error(-20000, '�� ����������� ���������!');
  ELSE
    --����c��� ����������
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
  cnt_    NUMBER;
  l_sel varchar2(256);
BEGIN
  --�������� ������ (�� ������� �����-���������, �����������)
  SELECT MAX(u.sptarn) INTO sptarn_ FROM usl u WHERE u.usl = usl_;
  l_sel:=utils.getScd_list_param('REP_TP_SCH_SEL');
  IF nvl(p_lvl, 0) = 0 THEN
    --�� ������
    IF sptarn_ = 0 THEN
      --�����
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
      --��������
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
      --� ����� � ��������
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
    --�� �����
    IF sptarn_ = 0 THEN
      --�����
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
      --��������
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
      --� ����� � ��������
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
    --�� ��
    IF sptarn_ = 0 THEN
      --�����
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
      --��������
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
      --� ����� � ��������
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
    --�� ����
    IF sptarn_ = 0 THEN
      --�����
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
      --��������
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
      --� ����� � ��������
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
    --�� �/�
    IF sptarn_ = 0 THEN
      --�����
      DELETE FROM nabor n
       WHERE n.lsk = lsk_
         AND n.usl = usl_
         AND n.org = org_
         AND n.koeff = koeff_;
    ELSIF sptarn_ = 1 THEN
      --��������
      DELETE FROM nabor n
       WHERE n.lsk = lsk_
         AND n.usl = usl_
         AND n.org = org_
         AND n.koeff = norm_;
    ELSIF sptarn_ IN (2, 3, 4) THEN
      --� ����� � ��������
      DELETE FROM nabor n
       WHERE n.lsk = lsk_
         AND n.usl = usl_
         AND n.org = org_
         AND n.koeff = koeff_
         AND n.norm = norm_;
    END IF;
  END IF;
  IF SQL%NOTFOUND THEN
      Raise_application_error(-20000, '�� ����������� ���������!');
  ELSIF nvl(p_lvl, 0) <> 4 THEN
    --�� �/c ������ � ���������� �� ��������
    --����c��� ����������
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
--��������� ������� ������� ���� (�������, ������)
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
--��������� � ����� ������� ����
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
-- ������ ������ � ������� ������
  --���-�� �.�., ������������ �����
  select count(*) into cnt_ from nabor n
    where n.fk_tarif=tsource_;
  if cnt_ <> 0 then
   update nabor n set n.fk_tarif=tdest_
     where n.fk_tarif=tsource_;
  end if;
----������� �� ����������� �������--- �����????
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
-- ���������� ������/��������� �� ����������� � ����� ��������
  cnt_:=0;
  --���-�� �.�., ������������ �����
  select nvl(count(*),0) into cnt2_ from nabor_progs n
    where n.lsk=lsk_;
  if cnt2_ = 0 then
  --���� ��� ������ �������� � ������, ������� ��������
     insert into nabor_progs(id, parent_id, lsk, usl, fk_tarif)
     select nabor_progs_id.nextval, null, lsk_, usl_, t.id
      from spr_tarif t where t.cd='000';
    select nabor_progs_id.currval into root_id_ from dual;
  else
--    root_id_:=parent_id_;
   --��������� ��������� ��������� �� � ������ ������
    select n.id into root_id_ from
      nabor_progs n, spr_tarif t where n.lsk=lsk_ and
        n.fk_tarif=t.id
        and t.cd = '000';
  end if;

  --���� ��� ��������� � ������
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
    --��������� ��� ���������� � ������ ��������
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
 cnt2_ number;
 cnt_ number;
begin
-- ����������� ������/��������� � ����������� �������
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
 cnt2_ number;
 cnt_ number;
begin
-- ����������� ������/��������� � ����������� �������
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
  -- �������� ��������� �� ������ � ����������� �������
  cnt_:=0;
  delete from spr_tarifxprogs t where t.fk_tarif=parent_id_ and t.fk_prog=id_;
  -- �������� ������ �� ����������� �������, ���� �� ������������
  -- ������� �������� � �������� ��������
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
    --��������, ��� ���������� ���� ������������
    --���������� �+ - ������� �������� � ���������� ��������� k_lsk_id!!!
    Raise_application_error(-20000, '������ #1554! � ������ P_HOUSES');
  end if;
  --�������� �������� �� ���� (�������� �������)
  --���� ��� ��� �� ����������
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
    --������� ������
    p_err:='�������� ������ ����� ��� ���������� � ����!';
  ELSE
    --�������� ��������
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
    --��������, ��� ���������� ���� ������������
    --���������� �+ - ������� �������� � ���������� ��������� k_lsk_id!!!
    Raise_application_error(-20000, '������ #1555! � ������ P_HOUSES');
  end if;
  --������� �������� �� ���� (�������� �������)
  DELETE FROM t_housexlist t
     WHERE t.id=p_id;
  COMMIT;
END;

 function add_prog(lsk_ in nabor_progs.lsk%type, fk_tarif_ in nabor_progs.fk_tarif%type,
   usl_ in nabor_progs.usl%type, id_dvb_ in number)
 return number is
  cnt_ number;
  cnt2_ number;
  root_id_ number;
begin
-- ���������� ������/��������� �� ����������� � ����� ��������
  cnt_:=0;
--  select t.id into root_id_
--   from spr_tarif t where t.cd='000';
  --���-�� �.�., ������������ �����
--  select nvl(count(*),0) into cnt2_ from nabor_progs n
--    where n.lsk=lsk_;

--  if cnt2_ = 0 then
  --���� ��� ������ �������� � ������, ������� ��������
--     insert into nabor_progs(lsk, usl, fk_tarif)
--     values (lsk_, usl_, root_id_);
--  end if;

  --���� ��� ��������� � ������ ???????????
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
    --��������� ��� ���������� � ������ ��������
    cnt_:=1;
  end if;
--  commit;
  return cnt_;

end;

 function del_prog(lsk_ in nabor_progs.lsk%type, id_ in nabor_progs.fk_tarif%type)
 return number is
 cnt_ number;
begin
-- �������� ������/��������� � ������ ��������
   delete from nabor_progs n
      where n.lsk=lsk_ and n.fk_tarif=id_;
      /* and exists (select * from
       spr_tarif s
       where s.id=n.fk_tarif
       start with s.id=id_
       connect by s.parent_id=prior s.id)*/
   --������� �� ������ �������� ������
   --���� ����� �� ��� ������ �������
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
 cnt_ number;
begin
-- �������� ���� �������/�������� �� ������ ��������
   delete from nabor_progs n
      where n.lsk=lsk_;
   --������� �� ������ �������� ������
   delete from nabor_progs n where n.lsk=lsk_;

 return 0;
end;

FUNCTION find_unq_lsk(p_reu IN kart.reu%type, 
                      p_lsk in kart.lsk%type --��������������� ���.��.
  ) RETURN VARCHAR2 IS
  l_cnt NUMBER;
  l_i number;
  l_maxlsk kart.lsk%type;
  l_lsk kart.lsk%type; 
  i number;
  l_flag number;
BEGIN
  --����� ���������� �������, "�����" � ������ �/� �� ��
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
            where b.lsk is null        
            order by a.rn)
      loop
        return c2.lsk;
      end loop;      

      --�� ���� �������� �� ������ 1000, ����������� �������� �� ��������� 5000
      
    END LOOP;
  else 
  --�� ����������������� ���.�����
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
  
  --�� �������, ������ ����� ��������� �� ����
   select lpad(max(lsk)+1,8,'0') into l_maxlsk from
     kart k;
  RETURN l_maxlsk;
END;

function create_lsk (lsk_ kart.lsk%TYPE, lsk_new_ kart.lsk%TYPE, 
      p_lsk_ext kart.lsk_ext%type, p_fio kart.fio%type, p_lsk_tp in varchar2, -- ��� ������ ��
      p_reu in varchar2 -- ���� ������, ��������� ������ ��� ��
      )
           RETURN number is
    l_cnt number;
    l_elsd k_lsk.elsd%type;
  begin
  begin
    select 1 into l_cnt
     from dual where regexP_like(lsk_new_,'[[:digit:]]{8}')
     and length(trim(lsk_new_))=8
     and not exists (select * from kart k where k.lsk=trim(lsk_new_));
  exception
    when no_data_found then
      return 1; --������ ���.����� �� ������������� �����������
  end;
  
  insert into c_lsk (id)
    values (c_lsk_id.nextval);
  l_elsd:= get_next_elsd;  
  insert into k_lsk (id, fk_addrtp, elsd)
     select k_lsk_id.nextval, u.id, l_elsd
     from u_list u, u_listtp tp
     where
     u.cd='flat' and tp.cd='object_type';

  insert into kart
    (lsk, k_lsk_id, c_lsk_id, house_id, kul, nd, kw, fio, kpr, kpr_wr,
     kpr_ot, kpr_cem, kpr_s, opl, ppl, pldop, ki,
     psch, psch_dt, status, kwt, lodpl,
     bekpl, balpl, komn, et, kfg,
     kfot, phw, mhw, pgw, mgw, pel, mel,
     sub_nach, subsidii, sub_data,
     polis, sch_el, reu, text,
     eksub1, eksub2, kran, kran1, el,
     el1, sgku, doppl, subs_cor, subs_cur, fk_pasp_org, mg1, mg2, lsk_ext, fk_tp, sel1)
  select
     lsk_new_, k_lsk_id.currval, c_lsk_id.currval, house_id, kul, nd, kw, p_fio as fio,
     0, 0, 0, 0, 0, opl, ppl, pldop, ki,
     0, psch_dt, status, kwt, lodpl,
     bekpl, balpl, komn, et, kfg,
     kfot, 0, 0, 0, 0, 0, 0, sub_nach,
     subsidii, null,
     null as polis,
     sch_el, p_reu, null as text,
     0, 0, 0, 0, 0, 0, 0, 0, 0,  0, k.fk_pasp_org, p.period, '999999', p_lsk_ext, tp.id as fk_tp, 1 as sel1
   from kart k, params p, v_lsk_tp tp where k.lsk=lsk_ and tp.cd=p_lsk_tp;
  if SQL%ROWCOUNT = 0 then 
    Raise_application_error(-20000, '�� ��������� ������ ������� ������!');
  end if;

  insert into nabor
    (lsk, usl, org, koeff, norm)
  select
     lsk_new_, usl, org, koeff, norm
  from nabor n where n.lsk=lsk_;

  insert into c_states_sch(lsk, fk_status)
  values
  (lsk_new_, 0);
  return 0;

end;

--�������� � ������������� ���������, -�������������� ������� ���� -�� ����
--(�������� ��� ����������)
--(���� �� ������������ � ���������, ������ ��� ������������� ����������) ���.26.09.2018
function kart_lsk_special_add_house(
         p_house in kart.house_id%type, -- Id ����
         p_lsk_tp in varchar2, -- ��� ������ ��
         p_forced_status in number, -- ������������� ���������� ������ (null - �� �������������, 0-�������� � �.�.)
         p_del_usl_from_dst in number, -- ������� ������ �� nabor ��������� (1-�������,0-���)
         p_reu in varchar2 -- ���� ������, ��������� ������ ��� ��, ���� ���, �������� �� ���������
         ) return number is
  a number;
begin
  for c in (select k.lsk from kart k join v_lsk_tp tp on k.fk_tp=tp.id
                   where tp.cd='LSK_TP_MAIN'
                   and k.house_id=p_house 
                   and k.psch not in (8,9)
                   )
  loop
    --������� �� ������� ��������� �.�.  
    a:=kart_lsk_special_add(p_lsk              => c.lsk,
                         p_lsk_tp           => p_lsk_tp,
                         p_lsk_new          => null,
                         p_forced_status    => 0,
                         p_del_usl_from_dst => 1,
                         p_reu              => null);
    if a != 0 then
      -- ������� ��� ������, ���� ���������
      return a;
    end if;                     
  end loop;
  return 0;
end;

--�������� � ������������� ���������, - ������� ���� ���������� ����
--(�������� ��� ����������)
function kart_lsk_special_add(p_lsk in kart.lsk%type,-- �� ���������
         p_lsk_tp in varchar2, -- ��� ������ ��
         p_lsk_new in kart.lsk%type, -- ���� null, ���� ������ ����� ��
         p_forced_status in number, -- ������������� ���������� ������ (null - �� �������������, 0-�������� � �.�.)
         p_del_usl_from_dst in number, -- ������� ������ �� nabor ��������� (1-�������,0-���)
         p_reu in varchar2 -- ���� ������, ��������� ������ ��� ��
         ) return number is
  l_lsk kart.lsk%type;
  l_reu kart.reu%type;
  l_klsk kart.k_lsk_id%type;
  l_cnt number;
begin
  select nvl(p_reu, t.reu), t.k_lsk_id into l_reu, l_klsk from kart t where t.lsk=p_lsk;

  if p_lsk_new is null then
    l_lsk:=find_unq_lsk(l_reu, null);
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
      return 1; --������ ���.����� �� ������������� �����������
  end;
    
  insert into kart k (lsk, reu, kul, nd, kw, k_fam, k_im, k_ot, psch, 
    status, kfg, kfot, house_id, k_lsk_id, c_lsk_id, mg1, mg2, fk_tp, kpr, kpr_wr, 
     kpr_ot, opl)
  select l_lsk, l_reu, k.kul, k.nd, k.kw, k.k_fam, k.k_im, k.k_ot,
    k.psch, k.status, 2 as kfg, 2 as kfot, k.house_id, k.k_lsk_id, k.c_lsk_id, 
    p.period as mg1, '999999' as mg2, tp.id as fk_tp, k.kpr as kpr, k.kpr_wr as kpr_wr,
     k.kpr_ot as kpr_ot, k.opl
    from kart k, params p, v_lsk_tp tp
    where k.lsk=p_lsk
    and tp.cd=p_lsk_tp;
  if sql%rowcount=0 then
     rollback;
     return 3; 
  end if;   

  if p_lsk_tp='LSK_TP_ADDIT' then
    begin
    insert into nabor
    (lsk, usl, org, koeff, norm)
     select l_lsk, u.usl, o.id as org, 1.18182 as koeff, null as norm
      from usl u 
      join t_org_tp tp on tp.cd='���' --��������� ����������� - ���
      join t_org o on o.fk_orgtp=tp.id
      where u.cd='���.';

     if sql%rowcount=0 then
       rollback;
       return 2; --�� ��������� ������
     end if;  
    exception
      when no_data_found then
        rollback;
        return 2; --�� ��������� ������
    end;     
  end if;  
   -- ������� � ������ ���.����� ������ ������
   if p_del_usl_from_dst = 1 then
      delete from nabor n
         where n.lsk=p_lsk and exists (select * from usl u where u.usl=n.usl and u.cd in ('���.', '���/��.���'));     
   end if;
   -- ���������� ������ ������ �� (��������, ��������)
   if p_forced_status is not null then
     insert into c_states_sch
       (lsk, fk_status, dt1, dt2)
     select l_lsk, 
     p_forced_status as fk_status,
     init.get_dt_start, null
     from dual;
   end if;  

return 0;   
end;

procedure set_g_lsk_tp(p_tp in number) is
begin
  --���������� ���� ����������
  g_sel_lsk_tp:=p_tp;
end;
  
function get_g_lsk_tp return number is
begin
  --��������� ���� ����������
  if g_sel_lsk_tp is null then
     Raise_application_error(-20000, '�� ������������ ����.��������� g_sel_lsk_tp!');
  end if;
  return g_sel_lsk_tp;
end;

--�������� �������� ������� ����� ������� ��������� � �������� (���������������) �����, ������� �������� ������� ����
function get_other_lsk(p_lsk in kart.lsk%type) return tab_lsk is
 l_lsk kart.lsk%type;
 t_lsk tab_lsk;
begin
  select rec_lsk(k.lsk) bulk collect into t_lsk from kart k
   where exists (select * from kart t where t.lsk=p_lsk 
     and t.k_lsk_id=k.k_lsk_id and t.psch not in (8,9));
  return t_lsk;                        

end;

--������� klsk �� GUID ����
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


-- ������� ���������, ���������� ELSD (����������� ���������� ������� k_lsk)
function get_next_elsd return varchar2 is
  l_elsd k_lsk.elsd%type;
begin
  -- ������������� k_lsk �� ��������� ������ ELSD
  LOCK TABLE k_lsk IN EXCLUSIVE MODE; 
  select 'A'||(max(to_number(substr(k.elsd,2,length(k.elsd)-1)))+1) into l_elsd
   from k_lsk k join u_list u on k.fk_addrtp=u.id
   and u.cd='flat';
  return l_elsd; 
end;  
   
end P_HOUSES;
/

