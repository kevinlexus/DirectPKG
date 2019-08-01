CREATE OR REPLACE PACKAGE SCOTT.generator IS
  time_ DATE;
  -- Author  : LEV
  -- Created : 24/02/04 15:08:53
  -- Purpose :
  -- Public type declarations
  TYPE rep_refcursor IS REF CURSOR;
  TYPE sal_refcursor IS REF CURSOR;
  PROCEDURE disable_keys(var_ IN NUMBER);
  PROCEDURE enable_keys(var_ IN NUMBER);
  PROCEDURE test_constr_errs(cnt_ OUT NUMBER, var_ IN NUMBER);
  PROCEDURE del_table_rows(tname_      IN VARCHAR2,
                           field_name_ IN VARCHAR2,
                           dat1_       IN DATE,
                           dat2_       IN DATE);
  PROCEDURE del_table_rows_allxito(dat_ IN VARCHAR2);
  PROCEDURE insert_charges(lsk_   IN VARCHAR2,
                           usl_   IN VARCHAR2,
                           mg_    IN VARCHAR2,
                           summa_ IN NUMBER);
  PROCEDURE delete_charges(lsk1_ IN VARCHAR2, lsk2_ IN VARCHAR2);
  PROCEDURE delete_subsidii(lsk1_ IN VARCHAR2, lsk2_ IN VARCHAR2);
  PROCEDURE insert_subsidii(lsk_   IN VARCHAR2,
                            usl_   IN VARCHAR2,
                            mg_    IN VARCHAR2,
                            summa_ IN NUMBER);
  PROCEDURE report_saldo(reu_           IN VARCHAR2,
                         trest_         IN VARCHAR2,
                         mg_            IN VARCHAR2,
                         mg1_           IN VARCHAR2,
                         prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_debit(type_          IN NUMBER,
                         trest_         IN S_REU_TREST.trest%TYPE,
                         prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_proc_org(prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_proc_plan(reu_           IN S_REU_TREST.reu%TYPE,
                             trest_         IN S_REU_TREST.trest%TYPE,
                             dat1_          IN PROC_PLAN_LOADED.dat%TYPE,
                             dat2_          IN PROC_PLAN_LOADED.dat%TYPE,
                             prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_opl_tr_own(prep_refcursor IN OUT rep_refcursor);

  PROCEDURE report_pen(var_            IN NUMBER,
                       reu_            IN VARCHAR2,
                       trest_          IN VARCHAR2,
                       dat_            IN DATE,
                       dat1_           IN DATE,
                       mg_             IN VARCHAR2,
                       mg1_            IN VARCHAR2,
                       v_rep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_check_rep(var_            IN NUMBER,
                             mg_             IN XITOG3.mg%TYPE,
                             mg1_            IN XITOG3.mg%TYPE,
                             v_rep_refcursor IN OUT rep_refcursor);
/*  procedure report_lg_usl_org(var_           in number,
                              var1_          in number,
                              reu_           in xito_lg2.reu%type,
                              trest_         in xito_lg2.trest%type,
                              houses_        in number,
                              org_           in xito_lg2.org_id%type,
                              mg_            in xito_lg2.mg%type,
                              mg1_           in xito_lg2.mg%type,
                              prep_refcursor in out rep_refcursor);
  procedure report_lg_stat(mg_            in xito_lg2.mg%type,
                           prep_refcursor in out rep_refcursor);*/

  PROCEDURE report_bank(var_           IN NUMBER,
                        dat_           IN XITO5.dat%TYPE,
                        dat1_          IN XITO5.dat%TYPE,
                        mg_            IN XITO5.mg%TYPE,
                        mg1_           IN XITO5.mg%TYPE,
                        prep_refcursor OUT rep_refcursor);
  PROCEDURE list_choice(clr_           IN NUMBER,
                        prep_refcursor IN OUT rep_refcursor);
  PROCEDURE list_choice_set(set_ IN NUMBER);
  PROCEDURE list_choice_uch(clr_           IN NUMBER,
                            prep_refcursor IN OUT rep_refcursor);
  PROCEDURE list_choice_set_uch(set_ IN NUMBER);
  PROCEDURE list_choice_usl(clr_           IN NUMBER,
                            prep_refcursor IN OUT rep_refcursor);
  PROCEDURE list_choice_usl_set(set_ IN NUMBER);
  PROCEDURE list_choice_reu(clr_           IN NUMBER,
                            prep_refcursor IN OUT rep_refcursor);
  procedure list_choice_hs_set(set_ in number);
  procedure list_choice_hs(clr_ in number,
                        prep_refcursor in out rep_refcursor);
  PROCEDURE del_day_payments(mg_ IN VARCHAR2);
  PROCEDURE check_day_hints(cnt_ OUT NUMBER);
END generator;
/

CREATE OR REPLACE PACKAGE BODY SCOTT.generator IS

  PROCEDURE disable_keys(var_ IN NUMBER) IS
    stmt VARCHAR2(2000);
    TYPE empcurtyp IS REF CURSOR;
    c     empcurtyp;
    tname VARCHAR2(50);
    cname VARCHAR2(50);
  BEGIN
    time_ := SYSDATE;
      stmt := 'select table_name,constraint_name from sys.user_constraints t
    WHERE constraint_type=''R'' ORDER BY constraint_type DESC';
    OPEN c FOR stmt;
    LOOP
      FETCH c
        INTO tname, cname;
      EXIT WHEN c%NOTFOUND;
      BEGIN
        stmt := 'ALTER TABLE ' || tname || ' DISABLE CONSTRAINT ' || cname ||
                ' CASCADE ';
        EXECUTE IMMEDIATE stmt;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END LOOP;
    CLOSE c;

    stmt := 'select table_name,constraint_name from sys.user_constraints t
    WHERE (constraint_type=''P'' OR constraint_type=''U''  OR constraint_type=''C'') ORDER BY constraint_type DESC';
    OPEN c FOR stmt;
    LOOP
      FETCH c
        INTO tname, cname;
      EXIT WHEN c%NOTFOUND;
      BEGIN
        stmt := 'ALTER TABLE ' || tname || ' DISABLE CONSTRAINT ' || cname ||
                ' CASCADE ';
        EXECUTE IMMEDIATE stmt;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END LOOP;
    CLOSE c;
    logger.log_(time_, 'generator.disable_keys');
  END disable_keys;

  PROCEDURE enable_keys(var_ IN NUMBER) IS
    stmt VARCHAR2(2000);
    TYPE empcurtyp IS REF CURSOR;
    c     empcurtyp;
    tname VARCHAR2(50);
    cname VARCHAR2(50);
  BEGIN
    time_ := SYSDATE;
      stmt := 'select table_name,constraint_name from sys.user_constraints t
    WHERE (constraint_type=''P'' OR constraint_type=''U'' OR constraint_type=''C'')';
    OPEN c FOR stmt;
    LOOP
      FETCH c
        INTO tname, cname;
      EXIT WHEN c%NOTFOUND;
      BEGIN
        stmt := 'ALTER TABLE ' || tname || ' ENABLE CONSTRAINT ' || cname;
        EXECUTE IMMEDIATE stmt;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END LOOP;
    CLOSE c;

      stmt := 'select table_name,constraint_name from sys.user_constraints t
    WHERE constraint_type=''R''';

    OPEN c FOR stmt;
    LOOP
      FETCH c
        INTO tname, cname;
      EXIT WHEN c%NOTFOUND;
      BEGIN
        stmt := 'ALTER TABLE ' || tname || ' ENABLE CONSTRAINT ' || cname;
        EXECUTE IMMEDIATE stmt;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END LOOP;
    CLOSE c;
    logger.log_(time_, 'generator.enable_keys');
  END enable_keys;

  PROCEDURE test_constr_errs(cnt_ OUT NUMBER, var_ IN NUMBER)
  --Используется при загрузке дневных
   IS
    stmt VARCHAR2(2000);
    TYPE empcurtyp IS REF CURSOR;
    c    empcurtyp;
    rec_ sys.user_constraints%ROWTYPE;
  BEGIN
    IF var_ = 0 THEN
      --Текущие платежи
      stmt := 'select * from sys.user_constraints t where status=''DISABLED''
     AND table_name  IN (SELECT tname FROM TABLELIST WHERE var IN (0))';
    ELSE
      --За период
      stmt := 'select * from sys.user_constraints t where status=''DISABLED''
     AND table_name  IN (SELECT tname FROM TABLELIST WHERE var IN (0,1))';
    END IF;
    OPEN c FOR stmt;
    FETCH c
      INTO rec_;
    IF c%FOUND THEN
      cnt_ := 1;
    ELSE
      cnt_ := 0;
    END IF;
    CLOSE c;
  END test_constr_errs;

  PROCEDURE del_table_rows(tname_      IN VARCHAR2,
                           field_name_ IN VARCHAR2,
                           dat1_       IN DATE,
                           dat2_       IN DATE) IS
    stmt VARCHAR2(2000);
  BEGIN
    --Чистка таблицы tname_
    stmt := 'DELETE FROM ' || tname_ || ' WHERE ' || field_name_ ||
            ' BETWEEN :dat1 AND :dat2';
    EXECUTE IMMEDIATE stmt
      USING dat1_, dat2_;
    COMMIT;
  END del_table_rows;

  PROCEDURE del_table_rows_allxito(dat_ IN VARCHAR2) IS
    stmt VARCHAR2(2000);
  BEGIN
    --Чистка всех итоговых таблиц , дневных платежей, за период (как правило прошлый месяц)
    --Чистка всех дней в таблице доступных периодов
    stmt := 'DELETE FROM period_reports WHERE TO_CHAR(dat,''YYYYMM'') = :dat_ AND ID IN (2,3,4,5)';
    EXECUTE IMMEDIATE stmt
      USING dat_;

    stmt := 'DELETE FROM xito5 WHERE TO_CHAR(dat,''YYYYMM'') = :dat_';
    EXECUTE IMMEDIATE stmt
      USING dat_;
    COMMIT;
    stmt := 'DELETE FROM xito5_ WHERE TO_CHAR(dat,''YYYYMM'') = :dat_';
    EXECUTE IMMEDIATE stmt
      USING dat_;
    COMMIT;
    stmt := 'DELETE FROM xxito10 WHERE TO_CHAR(dat,''YYYYMM'') = :dat_';
    EXECUTE IMMEDIATE stmt
      USING dat_;
    COMMIT;
  END del_table_rows_allxito;

  PROCEDURE insert_charges(lsk_   IN VARCHAR2,
                           usl_   IN VARCHAR2,
                           mg_    IN VARCHAR2,
                           summa_ IN NUMBER)
  --Формирование начисления через OLE
   IS
    stmt VARCHAR2(2000);
  BEGIN
    stmt := 'INSERT INTO charges (lsk, usl, summa, mg) VALUES (:lsk_, :usl_, :mg_, :summa_)';
    EXECUTE IMMEDIATE stmt
      USING lsk_, usl_, summa_, mg_;
    --    COMMIT;
  END insert_charges;

  PROCEDURE delete_charges(lsk1_ IN VARCHAR2, lsk2_ IN VARCHAR2)
  --Чистка таблицы начисления текущего месяца
   IS
    stmt VARCHAR2(2000);
  BEGIN
    stmt := 'DELETE FROM charges WHERE lsk BETWEEN :lsk1_ AND :lsk2_';
    EXECUTE IMMEDIATE stmt
      USING lsk1_, lsk2_;
    COMMIT;
  END delete_charges;

  PROCEDURE delete_subsidii(lsk1_ IN VARCHAR2, lsk2_ IN VARCHAR2)
  --Чистка таблицы начисления текущего месяца
   IS
    stmt VARCHAR2(2000);
  BEGIN
    stmt := 'DELETE FROM subsidii WHERE lsk BETWEEN :lsk1_ AND :lsk2_';
    EXECUTE IMMEDIATE stmt
      USING lsk1_, lsk2_;
    COMMIT;
  END delete_subsidii;

  PROCEDURE insert_subsidii(lsk_   IN VARCHAR2,
                            usl_   IN VARCHAR2,
                            mg_    IN VARCHAR2,
                            summa_ IN NUMBER) IS
    stmt VARCHAR2(2000);
  BEGIN
    stmt := 'INSERT INTO subsidii (lsk, usl, summa, mg) VALUES (:lsk_, :usl_, :mg_, :summa_)';
    EXECUTE IMMEDIATE stmt
      USING lsk_, usl_, summa_, mg_;
  END insert_subsidii;

  PROCEDURE report_saldo(reu_           IN VARCHAR2,
                         trest_         IN VARCHAR2,
                         mg_            IN VARCHAR2,
                         mg1_           IN VARCHAR2,
                         prep_refcursor IN OUT rep_refcursor) IS
    --Оборотка по РЭУ/домам
  BEGIN
    NULL;
    RETURN;
    --Удалить процедуру, перенесена в pakage  rep_saldo

    IF reu_ IS NOT NULL THEN
      OPEN prep_refcursor FOR 'SELECT e_0.REU
  , s.trest
  , p.name
  , LTRIM(e_0.ND, ''0'') AS nd
  , e_1.UCH
  , NVL(e_1.INDEBET, 0) AS indebet
  , NVL(e_1.INKREDIT, 0) AS inkredit
  , NVL(o.CHARGES, 0) AS CHARGES
  , NVL(o.CHANGES, 0) AS CHANGES
  , NVL(o.subsid, 0) AS subsid
  , NVL(o.payment, 0) AS payment
  , NVL(o.pn, 0) AS pn
  , NVL(e.OUTDEBET, 0) AS outdebet
  , NVL(e.OUTKREDIT, 0) AS outkredit
FROM HOUSES e_0
  , XITOG1 x
  , S_REU_TREST s
  , XITOG1 e_1
  , (SELECT /*+ FULL (t) */
       reu
       , kul
       , nd
       , SUM(CHARGES) AS CHARGES
       , SUM(CHANGES) AS CHANGES
       , SUM(subsid) AS subsid
       , SUM(payment) AS payment
       , SUM(pn) AS pn
     FROM XITOG1 t
     WHERE t.mg
         BETWEEN :mg_ AND :mg1_
     GROUP BY reu, kul, nd) o
  , XITOG1 e
  , SPUL p
WHERE e_0.REU = e_1.REU (+)
  AND e_0.KUL = e_1.KUL (+)
  AND e_0.ND = e_1.ND (+)
  AND e_0.REU = o.reu(+)
  AND e_0.KUL = o.kul(+)
  AND e_0.ND = o.nd(+)
  AND e_0.REU = e.REU (+)
  AND e_0.KUL = e.KUL (+)
  AND e_0.ND = e.ND (+)
  AND e_0.KUL = p.id
  AND e_0.reu = :reu_
  AND e_0.reu = x.reu(+)
  AND e_0.kul = x.kul(+)
  AND e_0.nd = x.nd(+)
  AND e_0.reu = s.reu
  AND x.mg = :mg1_
  AND e_1.mg (+) = :mg_
  AND e.mg (+) = :mg1_
ORDER BY e_0.REU
  , NVL(x.uch, 0)
  , e_0.KUL
  , e_0.ND'
        USING mg_, mg1_, reu_, mg1_, mg_, mg1_;
    ELSIF trest_ IS NOT NULL THEN
      OPEN prep_refcursor FOR 'SELECT /*+ ORDERED USE_HASH (p) */
  e_0.REU
  , s.trest AS tr
  , s.name_tr AS trest
  , SUM(e_1.INDEBET) AS indebet
  , SUM(e_1.INKREDIT) AS inkredit
  , SUM(o.CHARGES) AS CHARGES
  , SUM(o.CHANGES) AS CHANGES
  , SUM(o.subsid) AS subsid
  , SUM(o.payment) AS payment
  , SUM(o.pn) AS pn
  , SUM(e.OUTDEBET) AS outdebet
  , SUM(e.OUTKREDIT) AS outkredit
FROM HOUSES e_0
  , S_REU_TREST s
  , XITOG1 e_1
  , (SELECT reu
       , kul
       , nd
       , SUM(CHARGES) AS CHARGES
       , SUM(CHANGES) AS CHANGES
       , SUM(subsid) AS subsid
       , SUM(payment) AS payment
       , SUM(pn) AS pn
     FROM XITOG1 t
     WHERE t.mg
         BETWEEN :mg_ AND :mg1_
     GROUP BY reu, kul, nd) o
  , XITOG1 e
  , SPUL p
WHERE e_0.REU = e_1.REU (+)
  AND e_0.KUL = e_1.KUL (+)
  AND e_0.ND = e_1.ND (+)
  AND e_0.REU = o.reu(+)
  AND e_0.KUL = o.kul(+)
  AND e_0.ND = o.nd(+)
  AND e_0.REU = e.REU (+)
  AND e_0.KUL = e.KUL (+)
  AND e_0.ND = e.ND (+)
  AND e_0.KUL = p.id
  AND e_0.reu = s.reu
  AND s.trest = :trest_
  AND e_1.mg (+) = :mg_
  AND e.mg (+) = :mg1_
GROUP BY s.trest, s.name_tr, e_0.REU'
        USING mg_, mg1_, trest_, mg_, mg1_;
    ELSIF reu_ IS NULL AND trest_ IS NULL THEN
      OPEN prep_refcursor FOR 'SELECT /*+ USE_HASH (e_0) */
            e_0.REU
            , s.trest AS tr
            , s.name_tr AS trest
            , SUM(e_1.INDEBET) AS indebet
            , SUM(e_1.INKREDIT) AS inkredit
            , SUM(o.CHARGES) AS CHARGES
            , SUM(o.CHANGES) AS CHANGES
            , SUM(o.subsid) AS subsid
            , SUM(o.payment) AS payment
            , SUM(o.pn) AS pn
            , SUM(e.OUTDEBET) AS outdebet
            , SUM(e.OUTKREDIT) AS outkredit
          FROM HOUSES e_0
            , S_REU_TREST s
            , XITOG1 e_1
            , (SELECT reu
                 , kul
                 , nd
                 , SUM(CHARGES) AS CHARGES
                 , SUM(CHANGES) AS CHANGES
                 , SUM(subsid) AS subsid
                 , SUM(payment) AS payment
                 , SUM(pn) AS pn
               FROM XITOG1 t
               WHERE t.mg
                   BETWEEN :mg_ AND :mg1_
               GROUP BY reu, kul, nd) o
            , XITOG1 e
            , SPUL p
          WHERE e_0.REU = e_1.REU (+)
            AND e_0.KUL = e_1.KUL (+)
            AND e_0.ND = e_1.ND (+)
            AND e_0.REU = o.reu(+)
            AND e_0.KUL = o.kul(+)
            AND e_0.ND = o.nd(+)
            AND e_0.REU = e.REU (+)
            AND e_0.KUL = e.KUL (+)
            AND e_0.ND = e.ND (+)
            AND e_0.KUL = p.id
            AND e_0.reu = s.reu
            AND e_1.mg (+) = :mg_
            AND e.mg (+) = :mg1_
          GROUP BY s.trest, s.name_tr, e_0.REU'
        USING mg_, mg1_, mg_, mg1_;
    END IF;
  END report_saldo;

  PROCEDURE report_debit(type_          IN NUMBER,
                         trest_         IN S_REU_TREST.trest%TYPE,
                         prep_refcursor IN OUT rep_refcursor) IS
    --Задолженность по предприятиям
  BEGIN
    IF trest_ IS NOT NULL THEN
      --по тресту
      IF type_ = 1 THEN
        --с учетом текущих сборов
        OPEN prep_refcursor FOR 'SELECT (x.summa-z.summa)/1000 AS summa, x.type, x.org, o.name||'' ''||t.name_tr AS org_name, s.name, (SELECT MAX(dat) FROM xxito10) AS dat
          FROM
          (SELECT NVL(SUM(a.outdebet),0)+NVL(SUM(a.outkredit),0) AS summa, u.TYPE, a.ORG, a.trest
              FROM XITOG2 a, USLM u, v_params v
               WHERE a.mg=v.period3 AND a.USLM=u.USLM AND a.trest=:trest_
               GROUP BY u.TYPE, a.ORG, a.trest) x,
          (SELECT NVL(SUM(b.summa),0) AS summa, b.ORG, b.trest
              FROM XXITO10 b, v_params v
               WHERE TO_CHAR(b.dat,''YYYYMM'')=v.period
               GROUP BY b.ORG, b.trest) z,
          SPRORG s, (SELECT * FROM ORG WHERE ORG.id=2) o, s_trest t
          WHERE x.ORG=z.ORG(+) AND x.trest=t.trest(+)
               AND x.trest=z.trest(+) AND x.ORG=s.kod
          ORDER BY x.TYPE, x.ORG'
          USING trest_;
      ELSE
        --без учета текущих сборов
        OPEN prep_refcursor FOR 'SELECT (x.summa)/1000 AS summa, x.type, x.org, o.name  AS org_name, s.name, TO_DATE(''01''||TO_CHAR(sysdate,''MMYYYY''), ''DDMMYYYY'') AS dat
          FROM
          (SELECT NVL(SUM(a.outdebet),0)+NVL(SUM(a.outkredit),0) AS summa, u.TYPE, a.ORG
              FROM XITOG2 a, USLM u, v_params v
               WHERE a.mg=v.period3 AND a.USLM=u.USLM AND a.trest=:trest_
               GROUP BY u.TYPE, a.ORG) x,
          SPRORG s, ORG o
          WHERE x.ORG=s.kod AND o.id=1
          ORDER BY x.TYPE, x.ORG'
          USING trest_;
      END IF;
    ELSE
      --по МП УЕЗЖКУ
      IF type_ = 1 THEN
        --с учетом текущих сборов
        OPEN prep_refcursor FOR 'SELECT (x.summa-z.summa)/1000 AS summa, x.type, x.org, o.name AS org_name, s.name, (SELECT MAX(dat) FROM xxito10) AS dat
          FROM
          (SELECT NVL(SUM(a.outdebet),0)+NVL(SUM(a.outkredit),0) AS summa, u.TYPE, a.ORG
              FROM XITOG2 a, USLM u, v_params v
               WHERE a.mg=v.period3 AND a.USLM=u.USLM
               GROUP BY u.TYPE, a.ORG) x,
          (SELECT NVL(SUM(b.summa),0) AS summa, b.ORG
              FROM XXITO10 b, v_params v
               WHERE TO_CHAR(b.dat,''YYYYMM'')=v.period
               GROUP BY b.ORG) z,
          SPRORG s, ORG o
          WHERE x.ORG=z.ORG AND x.ORG=s.kod AND o.id=1
          ORDER BY x.TYPE, x.ORG';
      ELSE
        --без учета текущих сборов
        /*        open prep_refcursor for 'SELECT (x.summa)/1000 AS summa, x.type, x.org, o.name  AS org_name, s.name, TO_DATE(''01''||TO_CHAR(sysdate,''MMYYYY''), ''DDMMYYYY'') AS dat
        FROM
        (SELECT NVL(sum(a.outdebet),0)+NVL(sum(a.outkredit),0) AS summa, u.type, a.org
            FROM xitog2 a, uslm u
             WHERE a.mg=''200412'' AND a.uslm=u.uslm
             GROUP BY u.type, a.org) x,
        sprorg s, org o
        WHERE x.org=s.kod AND o.id=1
        ORDER BY x.type, x.org';*/
        OPEN prep_refcursor FOR 'SELECT (x.summa)/1000 AS summa, x.type, x.org, o.name  AS org_name, s.name, TO_DATE(''01''||TO_CHAR(sysdate,''MMYYYY''), ''DDMMYYYY'') AS dat
          FROM
          (SELECT NVL(SUM(a.outdebet),0)+NVL(SUM(a.outkredit),0) AS summa, u.TYPE, a.ORG
              FROM XITOG2 a, USLM u, v_params v
               WHERE a.mg=v.period3 AND a.USLM=u.USLM
               GROUP BY u.TYPE, a.ORG) x,
          SPRORG s, ORG o
          WHERE x.ORG=s.kod AND o.id=1
          ORDER BY x.TYPE, x.ORG';
      END IF;
    END IF;
  END report_debit;

  PROCEDURE report_proc_org(prep_refcursor IN OUT rep_refcursor) IS
    --выполнение по предприятиям
  BEGIN
    OPEN prep_refcursor FOR 'select sum(charges),sum(payment),
          NVL(ROUND(SUM(CHARGES)/SUM(payment),2)*100,0) proc, ORG
          FROM XITOG2 t
          WHERE mg=''200410''
          GROUP BY ORG';
  END report_proc_org;

  PROCEDURE report_proc_plan(reu_           IN S_REU_TREST.reu%TYPE,
                             trest_         IN S_REU_TREST.trest%TYPE,
                             dat1_          IN PROC_PLAN_LOADED.dat%TYPE,
                             dat2_          IN PROC_PLAN_LOADED.dat%TYPE,
                             prep_refcursor IN OUT rep_refcursor) IS
  BEGIN
    IF reu_ IS NOT NULL THEN
      --          case when p.sumplan<>0 then ROUND((a.summa+b.summa)/10/p.sumplan,2) else 0 end as procplan,
      OPEN prep_refcursor FOR 'select s.reu, s.name_tr, a.summa, b.summa as penya,
          c.summa AS sumbn, b.summa+a.summa AS sumall, p.sumplan,
          CASE WHEN p.sumplan<>0 THEN ROUND((a.summa)/10/p.sumplan,2) ELSE 0 END AS procplan,
           p.sumplan*1000-a.summa AS plan_no
           FROM
          v_trest_plan s, PROC_PLAN p, PARAMS m,
          (SELECT SUM(ska) AS summa, k.reu FROM PROC_PLAN_LOADED k, OPER o
          WHERE k.OPER=o.OPER AND SUBSTR(o.oigu,1,1)=''1''
               AND k.dat BETWEEN :dat1_ AND :dat2_ AND k.reu=:reu_
          GROUP BY k.reu) a,
          (SELECT SUM(pn) AS summa, k.reu FROM PROC_PLAN_LOADED k, OPER o
          WHERE k.OPER=o.OPER
               AND k.dat BETWEEN :dat1_ AND :dat2_ AND k.reu=:reu_
          GROUP BY k.reu) b,
          (SELECT SUM(ska) AS summa, k.reu FROM PROC_PLAN_LOADED k, OPER o
          WHERE k.OPER=o.OPER AND SUBSTR(o.oigu,1,2)=''10''
               AND k.dat BETWEEN :dat1_ AND :dat2_ AND k.reu=:reu_
          GROUP BY k.reu) c
          WHERE s.reu=a.reu(+) AND s.reu=b.reu(+) AND s.reu=c.reu(+) AND s.reu=p.reu
               AND m.period_pl=p.mg AND s.reu=:reu_ ORDER BY s.trest, s.reu'
        USING dat1_, dat2_, reu_, dat1_, dat2_, reu_, dat1_, dat2_, reu_, reu_;
    ELSIF trest_ IS NOT NULL THEN
      --          case when p.sumplan<>0 then ROUND((a.summa+b.summa)/10/p.sumplan,2) else 0 end as procplan,
      OPEN prep_refcursor FOR 'select s.reu, s.name_tr, a.summa, b.summa as penya,
          c.summa AS sumbn, b.summa+a.summa AS sumall, p.sumplan,
          CASE WHEN p.sumplan<>0 THEN ROUND((a.summa)/10/p.sumplan,2) ELSE 0 END AS procplan,
          p.sumplan*1000-a.summa AS plan_no
           FROM
          v_trest_plan s, PROC_PLAN p, PARAMS m,
          (SELECT SUM(ska) AS summa, k.reu FROM PROC_PLAN_LOADED k, OPER o
          WHERE k.OPER=o.OPER AND SUBSTR(o.oigu,1,1)=''1''
               AND k.dat BETWEEN :dat1_ AND :dat2_
          GROUP BY k.reu) a,
          (SELECT SUM(pn) AS summa, k.reu FROM PROC_PLAN_LOADED k, OPER o
          WHERE k.OPER=o.OPER
               AND k.dat BETWEEN :dat1_ AND :dat2_
          GROUP BY k.reu) b,
          (SELECT SUM(ska) AS summa, k.reu FROM PROC_PLAN_LOADED k, OPER o
          WHERE k.OPER=o.OPER AND SUBSTR(o.oigu,1,2)=''10''
               AND k.dat BETWEEN :dat1_ AND :dat2_
          GROUP BY k.reu) c
          WHERE s.reu=a.reu(+) AND s.reu=b.reu(+) AND s.reu=c.reu(+) AND s.reu=p.reu
               AND m.period_pl=p.mg AND s.trest=:trest_ ORDER BY s.trest, s.reu'
        USING dat1_, dat2_, dat1_, dat2_, dat1_, dat2_, trest_;
    ELSE
      --          case when p.sumplan<>0 then ROUND((a.summa+b.summa)/10/p.sumplan,2) else 0 end as procplan,
      OPEN prep_refcursor FOR 'select s.reu, s.name_tr, a.summa, b.summa as penya,
          c.summa AS sumbn, b.summa+a.summa AS sumall, p.sumplan,
          CASE WHEN p.sumplan<>0 THEN ROUND((a.summa)/10/p.sumplan,2) ELSE 0 END AS procplan,
           p.sumplan*1000-a.summa AS plan_no
           FROM
          v_trest_plan s, PROC_PLAN p, PARAMS m,
          (SELECT SUM(ska) AS summa, k.reu FROM PROC_PLAN_LOADED k, OPER o
          WHERE k.OPER=o.OPER AND SUBSTR(o.oigu,1,1)=''1''
               AND k.dat BETWEEN :dat1_ AND :dat2_
          GROUP BY k.reu) a,
          (SELECT SUM(pn) AS summa, k.reu FROM PROC_PLAN_LOADED k, OPER o
          WHERE k.OPER=o.OPER
               AND k.dat BETWEEN :dat1_ AND :dat2_
          GROUP BY k.reu) b,
          (SELECT SUM(ska) AS summa, k.reu FROM PROC_PLAN_LOADED k, OPER o
          WHERE k.OPER=o.OPER AND SUBSTR(o.oigu,1,2)=''10''
               AND k.dat BETWEEN :dat1_ AND :dat2_
          GROUP BY k.reu) c
          WHERE s.reu=a.reu(+) AND s.reu=b.reu(+) AND s.reu=c.reu(+) AND s.reu=p.reu
               AND m.period_pl=p.mg ORDER BY s.trest, s.reu'
        USING dat1_, dat2_, dat1_, dat2_, dat1_, dat2_;
    END IF;
  END report_proc_plan;

  PROCEDURE report_opl_tr_own(prep_refcursor IN OUT rep_refcursor) IS
    --Средства, собранные трестами, собой
  BEGIN
    OPEN prep_refcursor FOR 'select o.name, u.nm1, s.trest, s.name_tr, sum(summa) as summa
               FROM XXITO10 t, S_REU_TREST s, USL u, SPRORG o
               WHERE t.reu=s.reu AND t.USL=u.USL AND t.ORG=o.kod
               GROUP BY o.name, u.nm1, s.trest, s.name_tr';
  END report_opl_tr_own;







  PROCEDURE report_pen(var_            IN NUMBER,
                       reu_            IN VARCHAR2,
                       trest_          IN VARCHAR2,
                       dat_            IN DATE,
                       dat1_           IN DATE,
                       mg_             IN VARCHAR2,
                       mg1_            IN VARCHAR2,
                       v_rep_refcursor IN OUT rep_refcursor) IS
  BEGIN
    IF var_ = 0 THEN
      --Пеня, принятая за ЖЭО, кроме сборов этого ЖЭО
      IF trest_ IS NOT NULL THEN
        --По трестам
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN v_rep_refcursor FOR 'select sum(pn) as summa, s.name_tr, x.from_reu
          FROM XITO5_ x, S_REU_TREST s, S_REU_TREST d
          WHERE dat BETWEEN :dat_ AND :dat1_ AND x.from_reu=s.reu AND x.reu=d.reu
          AND d.trest=:trest_ AND s.trest<>d.trest AND x.pn<>0
          GROUP BY s.trest, s.name_tr, x.from_reu
          ORDER BY s.trest, x.from_reu'
            USING dat_, dat1_, trest_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
          OPEN v_rep_refcursor FOR 'select sum(pn) as summa, s.name_tr, x.from_reu
          FROM XITO5_ x, S_REU_TREST s, S_REU_TREST d
          WHERE mg BETWEEN :mg_ AND :mg1_ AND x.from_reu=s.reu AND x.reu=d.reu
          AND d.trest=:trest_ AND s.trest<>d.trest AND x.pn<>0
          GROUP BY s.trest, s.name_tr, x.from_reu
          ORDER BY s.trest, x.from_reu'
            USING mg_, mg1_, trest_;
        END IF;
      ELSIF reu_ IS NOT NULL THEN
        --По РЭУ
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN v_rep_refcursor FOR 'select sum(pn) as summa, s.name_tr, x.from_reu
          FROM XITO5_ x, S_REU_TREST s, S_REU_TREST d
          WHERE dat BETWEEN :dat_ AND :dat1_ AND x.from_reu=s.reu AND x.reu=d.reu
          AND d.reu=:reu_ AND s.trest<>d.trest AND x.pn<>0
          GROUP BY s.trest, s.name_tr, x.from_reu
          ORDER BY s.trest, x.from_reu'
            USING dat_, dat1_, reu_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
          OPEN v_rep_refcursor FOR 'select sum(pn) as summa, s.name_tr, x.from_reu
          FROM XITO5_ x, S_REU_TREST s, S_REU_TREST d
          WHERE mg BETWEEN :mg_ AND :mg1_ AND x.from_reu=s.reu AND x.reu=d.reu
          AND d.reu=:reu_ AND s.trest<>d.trest AND x.pn<>0
          GROUP BY s.trest, s.name_tr, x.from_reu
          ORDER BY s.trest, x.from_reu'
            USING mg_, mg1_, reu_;
        END IF;
      ELSE
        --По всем ЖЭО
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN v_rep_refcursor FOR 'select sum(pn) as summa, s.name_tr, x.from_reu
          FROM XITO5_ x, S_REU_TREST s
          WHERE dat BETWEEN :dat_ AND :dat1_ AND x.from_reu=s.reu
          AND x.pn<>0
          GROUP BY s.trest, s.name_tr, x.from_reu
          ORDER BY s.trest, x.from_reu'
            USING dat_, dat1_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
          OPEN v_rep_refcursor FOR 'select sum(pn) as summa, s.name_tr, x.from_reu
          FROM XITO5_ x, S_REU_TREST s
          WHERE mg BETWEEN :mg_ AND :mg1_ AND x.from_reu=s.reu
          AND x.pn<>0
          GROUP BY s.trest, s.name_tr, x.from_reu
          ORDER BY s.trest, x.from_reu'
            USING mg_, mg1_;
        END IF;
      END IF;
    ELSE
      --Пеня, принятая ЖЭО за других, кроме сборов за этот ЖЭО
      IF trest_ IS NOT NULL THEN
        --По трестам
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN v_rep_refcursor FOR 'select sum(pn) as summa, s.name_tr, x.reu as from_reu
          FROM XITO5_ x, S_REU_TREST s, S_REU_TREST d
          WHERE dat BETWEEN :dat_ AND :dat1_ AND x.reu=s.reu AND x.from_reu=d.reu
          AND d.trest=:trest_ AND s.trest<>d.trest AND x.pn<>0
          GROUP BY s.trest, s.name_tr, x.reu
          ORDER BY s.trest, x.reu'
            USING dat_, dat1_, trest_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
          OPEN v_rep_refcursor FOR 'select sum(pn) as summa, s.name_tr, x.reu as from_reu
          FROM XITO5_ x, S_REU_TREST s, S_REU_TREST d
          WHERE mg BETWEEN :mg_ AND :mg1_ AND x.reu=s.reu AND x.from_reu=d.reu
          AND d.trest=:trest_ AND s.trest<>d.trest AND x.pn<>0
          GROUP BY s.trest, s.name_tr, x.reu
          ORDER BY s.trest, x.reu'
            USING mg_, mg1_, trest_;
        END IF;
      ELSIF reu_ IS NOT NULL THEN
        --По РЭУ
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN v_rep_refcursor FOR 'select sum(pn) as summa, s.name_tr, x.reu as from_reu
          FROM XITO5_ x, S_REU_TREST s, S_REU_TREST d
          WHERE dat BETWEEN :dat_ AND :dat1_ AND x.reu=s.reu AND x.from_reu=d.reu
          AND d.reu=:reu_ AND s.trest<>d.trest AND x.pn<>0
          GROUP BY s.trest, s.name_tr, x.reu
          ORDER BY s.trest, x.reu'
            USING dat_, dat1_, reu_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
          OPEN v_rep_refcursor FOR 'select sum(pn) as summa, s.name_tr, x.reu as from_reu
          FROM XITO5_ x, S_REU_TREST s, S_REU_TREST d
          WHERE mg BETWEEN :mg_ AND :mg1_ AND x.reu=s.reu AND x.from_reu=d.reu
          AND d.reu=:reu_ AND s.trest<>d.trest AND x.pn<>0
          GROUP BY s.trest, s.name_tr, x.reu
          ORDER BY s.trest, x.reu'
            USING mg_, mg1_, reu_;
        END IF;
      ELSE
        --По всем ЖЭО
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN v_rep_refcursor FOR 'select sum(pn) as summa, s.name_tr, x.reu as from_reu
          FROM XITO5_ x, S_REU_TREST s
          WHERE dat BETWEEN :dat_ AND :dat1_ AND x.reu=s.reu
          AND x.pn<>0
          GROUP BY s.trest, s.name_tr, x.reu
          ORDER BY s.trest, x.reu'
            USING dat_, dat1_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
          OPEN v_rep_refcursor FOR 'select sum(pn) as summa, s.name_tr, x.reu as from_reu
          FROM XITO5_ x, S_REU_TREST s
          WHERE mg BETWEEN :mg_ AND :mg1_ AND x.reu=s.reu
          AND x.pn<>0
          GROUP BY s.trest, s.name_tr, x.reu
          ORDER BY s.trest, x.reu'
            USING mg_, mg1_;
        END IF;
      END IF;
    END IF;
  END report_pen;

  PROCEDURE report_check_rep(var_            IN NUMBER,
                             mg_             IN XITOG3.mg%TYPE,
                             mg1_            IN XITOG3.mg%TYPE,
                             v_rep_refcursor IN OUT rep_refcursor) IS
  BEGIN
    --Отчет: Сверка по концу месяца - Оборотка с оплатой по операциям
    IF var_ = 0 THEN
      OPEN v_rep_refcursor FOR '(select s.trest, s.name_tr, sum(x.summa) as summa1, sum(i.summa) as summa2,
         NVL(SUM(x.summa),0) - NVL(SUM(i.summa),0) AS diff
               FROM (SELECT reu, SUM(payment) AS summa
               FROM XITOG2 d WHERE d.mg BETWEEN :mg_ AND :mg1_
               AND NOT EXISTS (SELECT USLM FROM USLM u WHERE TYPE IN (0) AND u.USLM=d.USLM)
                    GROUP BY reu) x,
               (SELECT from_reu AS reu, SUM(ska) AS summa
               FROM XITO5_ d WHERE d.other=1 AND d.mg BETWEEN :mg_ AND :mg1_ GROUP BY from_reu) i,
               S_REU_TREST s
               WHERE s.reu=i.reu(+) AND s.reu=x.reu(+)
               GROUP BY s.trest, s.name_tr)
          ORDER BY s.trest'
        USING mg_, mg1_, mg_, mg1_;
    ELSIF var_ = 1 THEN
      OPEN v_rep_refcursor FOR '(select s.trest, s.name_tr, sum(x.summa) as summa1, sum(i.summa) as summa2,
         NVL(SUM(x.summa),0) - NVL(SUM(i.summa),0) AS diff
               FROM (SELECT reu, SUM(pn) AS summa
               FROM XITOG2 d WHERE d.mg BETWEEN :mg_ AND :mg1_
               AND NOT EXISTS (SELECT USLM FROM USLM u WHERE TYPE IN (0) AND u.USLM=d.USLM)
                    GROUP BY reu) x,
               (SELECT from_reu AS reu, SUM(pn) AS summa
               FROM XITO5_ d WHERE d.other=1 AND d.mg BETWEEN :mg_ AND :mg1_ GROUP BY from_reu) i,
               S_REU_TREST s
               WHERE s.reu=i.reu(+) AND s.reu=x.reu(+)
               GROUP BY s.trest, s.name_tr)
          ORDER BY s.trest'
        USING mg_, mg1_, mg_, mg1_;
    ELSIF var_ = 2 THEN
      OPEN v_rep_refcursor FOR '(select s.trest, s.name_tr, sum(x.summa) as summa1, sum(i.summa) as summa2,
         NVL(SUM(x.summa),0) - NVL(SUM(i.summa),0) AS diff
               FROM (SELECT reu, SUM(NVL(payment,0)+NVL(pn,0)) AS summa
               FROM XITOG2 d WHERE d.mg BETWEEN :mg_ AND :mg1_
               AND NOT EXISTS (SELECT USLM FROM USLM u WHERE TYPE IN (0) AND u.USLM=d.USLM)
                    GROUP BY reu) x,
               (SELECT  from_reu AS reu, SUM(NVL(ska,0)+NVL(pn,0)) AS summa
               FROM XITO5_ d WHERE d.other=1 AND d.mg BETWEEN :mg_ AND :mg1_ GROUP BY from_reu) i,
               S_REU_TREST s
               WHERE s.reu=i.reu(+) AND s.reu=x.reu(+)
               GROUP BY s.trest, s.name_tr)
          ORDER BY s.trest'
        USING mg_, mg1_, mg_, mg1_;
    END IF;
  END;

/*  procedure report_lg_usl_org(var_           in number,
                              var1_          in number,
                              reu_           in xito_lg2.reu%type,
                              trest_         in xito_lg2.trest%type,
                              houses_        in number,
                              org_           in xito_lg2.org_id%type,
                              mg_            in xito_lg2.mg%type,
                              mg1_           in xito_lg2.mg%type,
                              prep_refcursor in out rep_refcursor) is
    --Отчет: Льготники (по услугам или предприятиям)
  begin
    if var_ = 1 then
      --По услугам
      if var1_ = 0 then
        --Суммы возмещения
        if trest_ is not null then
          --По трестам
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.nm1, 1, 15) as nm1,
                   sum(x.summa) as summa
              from xito_lg2 x, spk s, spk_gr g, uslm u
             where x.uslm_id = u.uslm
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and x.trest = trest_
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.nm1, 1, 15);
        elsif reu_ is not null then
          --По РЭУ
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.nm1, 1, 15) as nm1,
                   sum(x.summa) as summa
              from xito_lg2 x, spk s, spk_gr g, uslm u
             where x.uslm_id = u.uslm
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and x.reu = reu_
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.nm1, 1, 15);
        elsif houses_ is not null then
          --По Домам
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.nm1, 1, 15) as nm1,
                   sum(x.summa) as summa
              from xito_lg2 x, spk s, spk_gr g, uslm u
             where x.uslm_id = u.uslm
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and exists (select *
                      from list_choices l
                     where l.reu = x.reu
                       and l.kul = x.kul
                       and l.nd = x.nd
                       and l.sel = 0)
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.nm1, 1, 15);
        else
          --По всем ЖЭО
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.nm1, 1, 15) as nm1,
                   sum(x.summa) as summa
              from xito_lg2 x, spk s, spk_gr g, uslm u
             where x.uslm_id = u.uslm
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.nm1, 1, 15);
        end if;
      elsif var1_ = 1 then
        --Кол-во льготников
        if trest_ is not null then
          --По трестам
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.nm1, 1, 15) as nm1,
                   sum(x.cnt_main) as cnt_main,
                   sum(x.cnt) as cnt
              from (select reu,
                           trest,
                           kul,
                           nd,
                           uslm_id,
                           lg_id,
                           mg,
                           max(cnt_main) as cnt_main,
                           max(cnt) as cnt
                      from xito_lg2
                     group by reu, trest, kul, nd, uslm_id, lg_id, mg) x,
                   spk s,
                   spk_gr g,
                   uslm u
             where x.uslm_id = u.uslm
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and x.trest = trest_
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.nm1, 1, 15);
        elsif reu_ is not null then
          --По РЭУ
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.nm1, 1, 15) as nm1,
                   sum(x.cnt_main) as cnt_main,
                   sum(x.cnt) as cnt
              from (select reu,
                           trest,
                           kul,
                           nd,
                           uslm_id,
                           lg_id,
                           mg,
                           max(cnt_main) as cnt_main,
                           max(cnt) as cnt
                      from xito_lg2
                     group by reu, trest, kul, nd, uslm_id, lg_id, mg) x,
                   spk s,
                   spk_gr g,
                   uslm u
             where x.uslm_id = u.uslm
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and x.reu = reu_
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.nm1, 1, 15);
        elsif houses_ is not null then
          --По домам
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.nm1, 1, 15) as nm1,
                   sum(x.cnt_main) as cnt_main,
                   sum(x.cnt) as cnt
              from (select reu,
                           trest,
                           kul,
                           nd,
                           uslm_id,
                           lg_id,
                           mg,
                           max(cnt_main) as cnt_main,
                           max(cnt) as cnt
                      from xito_lg2
                     group by reu, trest, kul, nd, uslm_id, lg_id, mg) x,
                   spk s,
                   spk_gr g,
                   uslm u
             where x.uslm_id = u.uslm
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and exists (select *
                      from list_choices l
                     where l.reu = x.reu
                       and l.kul = x.kul
                       and l.nd = x.nd
                       and l.sel = 0)
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.nm1, 1, 15);
        else
          --По всем ЖЭО
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.nm1, 1, 15) as nm1,
                   sum(x.cnt_main) as cnt_main,
                   sum(x.cnt) as cnt
              from (select reu,
                           trest,
                           kul,
                           nd,
                           uslm_id,
                           lg_id,
                           mg,
                           max(cnt_main) as cnt_main,
                           max(cnt) as cnt
                      from xito_lg2
                     group by reu, trest, kul, nd, uslm_id, lg_id, mg) x,
                   spk s,
                   spk_gr g,
                   uslm u
             where x.uslm_id = u.uslm
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.nm1, 1, 15);
        end if;
      end if;
    elsif var_ = 0 then
      --По организациям
      if var1_ = 0 then
        --Суммы возмещения
        if trest_ is not null then
          --По трестам
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.name, 1, 25) as nm1,
                   sum(x.summa) as summa
              from xito_lg2 x, spk s, spk_gr g, sprorg u
             where x.org_id = u.kod
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and x.trest = trest_
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.name, 1, 25);
        elsif reu_ is not null then
          --По РЭУ
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.name, 1, 25) as nm1,
                   sum(x.summa) as summa
              from xito_lg2 x, spk s, spk_gr g, sprorg u
             where x.org_id = u.kod
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and x.reu = reu_
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.name, 1, 25);
        elsif houses_ is not null then
          --По домам
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.name, 1, 25) as nm1,
                   sum(x.summa) as summa
              from xito_lg2 x, spk s, spk_gr g, sprorg u
             where x.org_id = u.kod
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and exists (select *
                      from list_choices l
                     where l.reu = x.reu
                       and l.kul = x.kul
                       and l.nd = x.nd
                       and l.sel = 0)
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.name, 1, 25);
        else
          --По всем ЖЭО
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.name, 1, 25) as nm1,
                   sum(x.summa) as summa
              from xito_lg2 x, spk s, spk_gr g, sprorg u
             where x.org_id = u.kod
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.name, 1, 25);
        end if;
      elsif var1_ = 1 then
        --Кол-во льготников
        if trest_ is not null then
          --По трестам
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.name, 1, 15) as nm1,
                   sum(x.cnt_main) as cnt_main,
                   sum(x.cnt) as cnt
              from (select reu,
                           trest,
                           kul,
                           nd,
                           org_id,
                           lg_id,
                           mg,
                           max(cnt_main) as cnt_main,
                           max(cnt) as cnt
                      from xito_lg2
                     group by reu, trest, kul, nd, org_id, lg_id, mg) x,
                   spk s,
                   spk_gr g,
                   sprorg u
             where x.org_id = u.kod
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and x.trest = trest_
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.name, 1, 15);
        elsif reu_ is not null then
          --По РЭУ
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.name, 1, 15) as nm1,
                   sum(x.cnt_main) as cnt_main,
                   sum(x.cnt) as cnt
              from (select reu,
                           trest,
                           kul,
                           nd,
                           org_id,
                           lg_id,
                           mg,
                           max(cnt_main) as cnt_main,
                           max(cnt) as cnt
                      from xito_lg2
                     group by reu, trest, kul, nd, org_id, lg_id, mg) x,
                   spk s,
                   spk_gr g,
                   sprorg u
             where x.org_id = u.kod
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and x.reu = reu_
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.name, 1, 15);
        elsif houses_ is not null then
          --По домам
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.name, 1, 15) as nm1,
                   sum(x.cnt_main) as cnt_main,
                   sum(x.cnt) as cnt
              from (select reu,
                           trest,
                           kul,
                           nd,
                           org_id,
                           lg_id,
                           mg,
                           max(cnt_main) as cnt_main,
                           max(cnt) as cnt
                      from xito_lg2
                     group by reu, trest, kul, nd, org_id, lg_id, mg) x,
                   spk s,
                   spk_gr g,
                   sprorg u
             where x.org_id = u.kod
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and exists (select *
                      from list_choices l
                     where l.reu = x.reu
                       and l.kul = x.kul
                       and l.nd = x.nd
                       and l.sel = 0)
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.name, 1, 15);
        else
          --По всем ЖЭО
          open prep_refcursor for
            select substr(g.name, 1, 60) as gr_name,
                   substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                   substr(u.name, 1, 15) as nm1,
                   sum(x.cnt_main) as cnt_main,
                   sum(x.cnt) as cnt
              from (select reu,
                           trest,
                           kul,
                           nd,
                           org_id,
                           lg_id,
                           mg,
                           max(cnt_main) as cnt_main,
                           max(cnt) as cnt
                      from xito_lg2
                     group by reu, trest, kul, nd, org_id, lg_id, mg) x,
                   spk s,
                   spk_gr g,
                   sprorg u
             where x.org_id = u.kod
               and x.lg_id = s.id
               and mg between mg_ and mg1_
               and s.gr_id = g.id
             group by substr(g.name, 1, 60),
                      substr(to_char(s.id) || ' ' || s.name, 1, 15),
                      substr(u.name, 1, 15);
        end if;
      end if;
    elsif var_ = 2 then
      --Возмещение, кол-во льготников (по выбранной организации)
      if trest_ is not null then
        --По трестам
        open prep_refcursor for
          select substr(g.name, 1, 60) as gr_name,
                 substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                 substr(u.nm1, 1, 15) as nm1,
                 sum(x.summa) as summa,
                 sum(x.cnt_main) as cnt_main,
                 sum(x.cnt) as cnt
            from xito_lg2 x, spk s, spk_gr g, uslm u
           where x.uslm_id = u.uslm
             and x.lg_id = s.id
             and mg between mg_ and mg1_
             and x.trest = trest_
             and s.gr_id = g.id
             and x.org_id = org_
           group by substr(g.name, 1, 60),
                    substr(to_char(s.id) || ' ' || s.name, 1, 15),
                    substr(u.nm1, 1, 15);
      elsif reu_ is not null then
        --По РЭУ
        open prep_refcursor for
          select substr(g.name, 1, 60) as gr_name,
                 substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                 substr(u.nm1, 1, 15) as nm1,
                 sum(x.summa) as summa,
                 sum(x.cnt_main) as cnt_main,
                 sum(x.cnt) as cnt
            from xito_lg2 x, spk s, spk_gr g, uslm u
           where x.uslm_id = u.uslm
             and x.lg_id = s.id
             and mg between mg_ and mg1_
             and x.reu = reu_
             and s.gr_id = g.id
             and x.org_id = org_
           group by substr(g.name, 1, 60),
                    substr(to_char(s.id) || ' ' || s.name, 1, 15),
                    substr(u.nm1, 1, 15);
      elsif houses_ is not null then
        --По домам
        open prep_refcursor for
          select substr(g.name, 1, 60) as gr_name,
                 substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                 substr(u.nm1, 1, 15) as nm1,
                 sum(x.summa) as summa,
                 sum(x.cnt_main) as cnt_main,
                 sum(x.cnt) as cnt
            from xito_lg2 x, spk s, spk_gr g, uslm u
           where x.uslm_id = u.uslm
             and x.lg_id = s.id
             and mg between mg_ and mg1_
             and exists (select *
                    from list_choices l
                   where l.reu = x.reu
                     and l.kul = x.kul
                     and l.nd = x.nd
                     and l.sel = 0)
             and s.gr_id = g.id
             and x.org_id = org_
           group by substr(g.name, 1, 60),
                    substr(to_char(s.id) || ' ' || s.name, 1, 15),
                    substr(u.nm1, 1, 15);
      else
        --По всем ЖЭО
        open prep_refcursor for
          select substr(g.name, 1, 60) as gr_name,
                 substr(to_char(s.id) || ' ' || s.name, 1, 15) as name,
                 substr(u.nm1, 1, 15) as nm1,
                 sum(x.summa) as summa,
                 sum(x.cnt_main) as cnt_main,
                 sum(x.cnt) as cnt
            from xito_lg2 x, spk s, spk_gr g, uslm u
           where x.uslm_id = u.uslm
             and x.lg_id = s.id
             and mg between mg_ and mg1_
             and s.gr_id = g.id
             and x.org_id = org_
           group by substr(g.name, 1, 60),
                    substr(to_char(s.id) || ' ' || s.name, 1, 15),
                    substr(u.nm1, 1, 15);
        /*        OPEN prep_refcursor FOR
        SELECT substr(g.NAME, 1, 60) AS gr_name,
               substr(to_char(s.id) || ' ' || s.NAME, 1, 15) AS NAME,
               substr(u.nm1, 1, 15) AS nm1, SUM(x.summa) AS summa,
               SUM(x.cnt_main) AS cnt_main, SUM(x.cnt) AS cnt
          FROM (SELECT reu, trest, kul, nd, uslm_id, lg_id, mg,
                        SUM(summa) AS summa, SUM(cnt_main) AS cnt_main,
                        SUM(cnt) AS cnt
                   FROM xito_lg2
                  WHERE org_id = org_
                  GROUP BY reu, trest, kul, nd, uslm_id, lg_id, mg) x,
               spk s, spk_gr g, uslm u
         WHERE x.uslm_id = u.uslm
           AND x.lg_id = s.id
           AND mg BETWEEN mg_ AND mg1_
           AND s.gr_id = g.id
         GROUP BY substr(g.NAME, 1, 60),
                  substr(to_char(s.id) || ' ' || s.NAME, 1, 15),
                  substr(u.nm1, 1, 15);*/
/*      end if;
    elsif var_ = 3 then
      --Возмещение, кол-во льготников (по совокупности)
      if trest_ is not null then
        --По трестам
        open prep_refcursor for
          select substr(g.name, 1, 160) as gr_name,
                 substr(to_char(s.id) || ' ' || s.name, 1, 45) as name,
                 sum(x.summa) as summa,
                 sum(x.cnt_main) as cnt_main,
                 sum(x.cnt) as cnt
            from xito_lg1 x, spk s, spk_gr g
           where x.lg_id = s.id
             and mg between mg_ and mg1_
             and x.trest = trest_
             and s.gr_id = g.id
           group by g.id,
                    s.id,
                    substr(g.name, 1, 160),
                    substr(to_char(s.id) || ' ' || s.name, 1, 45)
           order by g.id, s.id;
      elsif reu_ is not null then
        --По РЭУ
        open prep_refcursor for
          select substr(g.name, 1, 160) as gr_name,
                 substr(to_char(s.id) || ' ' || s.name, 1, 45) as name,
                 sum(x.summa) as summa,
                 sum(x.cnt_main) as cnt_main,
                 sum(x.cnt) as cnt
            from xito_lg1 x, spk s, spk_gr g
           where x.lg_id = s.id
             and mg between mg_ and mg1_
             and x.reu = reu_
             and s.gr_id = g.id
           group by g.id,
                    s.id,
                    substr(g.name, 1, 160),
                    substr(to_char(s.id) || ' ' || s.name, 1, 45)
           order by g.id, s.id;
      elsif houses_ is not null then
        --По домам
        open prep_refcursor for
          select substr(g.name, 1, 160) as gr_name,
                 substr(to_char(s.id) || ' ' || s.name, 1, 45) as name,
                 sum(x.summa) as summa,
                 sum(x.cnt_main) as cnt_main,
                 sum(x.cnt) as cnt
            from xito_lg1 x, spk s, spk_gr g
           where x.lg_id = s.id
             and mg between mg_ and mg1_
             and exists (select *
                    from list_choices l
                   where l.reu = x.reu
                     and l.kul = x.kul
                     and l.nd = x.nd
                     and l.sel = 0)
             and s.gr_id = g.id
           group by g.id,
                    s.id,
                    substr(g.name, 1, 160),
                    substr(to_char(s.id) || ' ' || s.name, 1, 45)
           order by g.id, s.id;
      else
        --По всем ЖЭО
        open prep_refcursor for
          select substr(g.name, 1, 160) as gr_name,
                 substr(to_char(s.id) || ' ' || s.name, 1, 45) as name,
                 sum(x.summa) as summa,
                 sum(x.cnt_main) as cnt_main,
                 sum(x.cnt) as cnt
            from xito_lg1 x, spk s, spk_gr g
           where x.lg_id = s.id
             and mg between mg_ and mg1_
             and s.gr_id = g.id
           group by g.id,
                    s.id,
                    substr(g.name, 1, 160),
                    substr(to_char(s.id) || ' ' || s.name, 1, 45)
           order by g.id, s.id;
      end if;
    elsif var_ = 4 then
      --Возмещение, кол-во льготников (ИТОГИ по совокупности)
      if trest_ is not null then
        --По трестам
        open prep_refcursor for
          select substr(u.nm1, 1, 25) as nm1,
                 sum(x.summa) as summa,
                 sum(x.cnt_main) as cnt_main,
                 sum(x.cnt) as cnt
            from xito_lg2 x, uslm u
           where x.uslm_id = u.uslm
             and mg between mg_ and mg1_
             and x.trest = trest_
           group by substr(u.nm1, 1, 25);
      elsif reu_ is not null then
        --По РЭУ
        open prep_refcursor for
          select substr(u.nm1, 1, 25) as nm1,
                 sum(x.summa) as summa,
                 sum(x.cnt_main) as cnt_main,
                 sum(x.cnt) as cnt
            from xito_lg2 x, uslm u
           where x.uslm_id = u.uslm
             and mg between mg_ and mg1_
             and x.reu = reu_
           group by substr(u.nm1, 1, 25);
      elsif houses_ is not null then
        --По Домам
        open prep_refcursor for
          select substr(u.nm1, 1, 25) as nm1,
                 sum(x.summa) as summa,
                 sum(x.cnt_main) as cnt_main,
                 sum(x.cnt) as cnt
            from xito_lg2 x, uslm u
           where x.uslm_id = u.uslm
             and mg between mg_ and mg1_
             and exists (select *
                    from list_choices l
                   where l.reu = x.reu
                     and l.kul = x.kul
                     and l.nd = x.nd
                     and l.sel = 0)
           group by substr(u.nm1, 1, 25);
      else
        --По всем ЖЭО
        open prep_refcursor for
          select substr(u.nm1, 1, 25) as nm1,
                 sum(x.summa) as summa,
                 sum(x.cnt_main) as cnt_main,
                 sum(x.cnt) as cnt
            from (select reu,
                         trest,
                         kul,
                         nd,
                         uslm_id,
                         lg_id,
                         mg,
                         sum(summa) as summa,
                         max(cnt_main) as cnt_main,
                         max(cnt) as cnt
                    from xito_lg2
                   group by reu, trest, kul, nd, uslm_id, lg_id, mg) x,
                 uslm u
           where x.uslm_id = u.uslm
             and mg between mg_ and mg1_
           group by substr(u.nm1, 1, 25);
      end if;
    end if;
  end report_lg_usl_org;
*/




  PROCEDURE report_bank(var_           IN NUMBER,
                        dat_           IN XITO5.dat%TYPE,
                        dat1_          IN XITO5.dat%TYPE,
                        mg_            IN XITO5.mg%TYPE,
                        mg1_           IN XITO5.mg%TYPE,
                        prep_refcursor OUT rep_refcursor) IS
    reu_  CONSTANT CHAR(2) := '90'; --Id Банковского компьютера
    oper_ CONSTANT CHAR(2) := '39'; --Id Банковского компьютера
  BEGIN

    IF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
      IF var_ = 0 THEN
        --Оплата банка без детских пл., включая пеню
        OPEN prep_refcursor FOR
          SELECT SUM(x.ska + x.pn) AS summa, s.name_tr
            FROM XITO5_ x, S_REU_TREST s
           WHERE x.mg BETWEEN mg_ AND mg1_
             AND x.OPER NOT IN (oper_)
             AND x.from_reu = reu_
             AND x.reu = s.reu AND x.trest NOT IN ('04','17') --без кировского (и мупа кировского)
           GROUP BY s.trest, s.name_tr
           ORDER BY s.trest;
      ELSIF var_ = 1 THEN
        --Оплата банка (включая детские площадки, по дням)
        OPEN prep_refcursor FOR
          SELECT SUM(x.ska) AS summa, SUM(x.pn) AS penya, x.dat
            FROM XITO5_ x, S_REU_TREST s
           WHERE TO_CHAR(x.dat, 'YYYYMM') BETWEEN mg_ AND mg1_
             AND x.from_reu = reu_ AND x.trest NOT IN ('04','17') --без кировского (и мупа кировского)
             AND x.reu = s.reu
           GROUP BY x.dat
           ORDER BY x.dat;
      END IF;
    ELSE
      IF var_ = 0 THEN
        --Оплата банка без детских пл., включая пеню
        OPEN prep_refcursor FOR
          SELECT SUM(x.ska + x.pn) AS summa, s.name_tr
            FROM XITO5_ x, S_REU_TREST s
           WHERE x.dat BETWEEN dat_ AND dat1_
             AND x.OPER NOT IN (oper_)
             AND x.from_reu = reu_ AND x.trest NOT IN ('04','17') --без кировского (и мупа кировского)
             AND x.reu = s.reu
           GROUP BY s.trest, s.name_tr
           ORDER BY s.trest;
      ELSIF var_ = 1 THEN
        --Оплата банка (включая детские площадки, по дням)
        OPEN prep_refcursor FOR
          SELECT SUM(x.ska) AS summa, SUM(x.pn) AS penya, x.dat
            FROM XITO5_ x, S_REU_TREST s
           WHERE x.dat BETWEEN dat_ AND dat1_
             AND x.from_reu = reu_ AND x.trest NOT IN ('04','17') --без кировского (и мупа кировского)
             AND x.reu = s.reu
           GROUP BY x.dat
           ORDER BY x.dat;
      END IF;
    END IF;
  END;



  PROCEDURE list_choice(clr_           IN NUMBER,
                        prep_refcursor IN OUT rep_refcursor) IS
    --Временная таблица для выбора домов
  BEGIN
    IF clr_ = 1 THEN
      DELETE FROM LIST_CHOICES;
      INSERT INTO LIST_CHOICES t
        (reu, kul, nd, uch, house_id, sel)
        SELECT distinct k.reu, h.kul, h.nd, h.uch, h.id, 1
          FROM scott.kart k, scott.c_houses h, scott.v_permissions_reu p
         WHERE k.reu = p.reu and k.house_id=h.id;
    END IF;
    OPEN prep_refcursor FOR 'SELECT t.rowid, t.reu, upper(LTRIM(t.nd, ''0'')) AS nd,
      uch, upper(s.name) as name, t.sel
           FROM LIST_CHOICES t, SPUL s
           WHERE t.kul=s.id
           ORDER BY t.sel, s.name, t.nd, t.reu, uch ';
  END;

  PROCEDURE list_choice_set(set_ IN NUMBER) IS
  BEGIN
    UPDATE LIST_CHOICES SET sel = set_;
  END;

  PROCEDURE list_choice_uch(clr_           IN NUMBER,
                            prep_refcursor IN OUT rep_refcursor) IS
    --Временная таблица для выбора участков
  BEGIN
  --не работает в принципе
    IF clr_ = 1 THEN
      DELETE FROM LIST_CHOICES_UCH;
      INSERT INTO LIST_CHOICES_UCH t
        (reu, uch, sel)
        SELECT DISTINCT null as reu, null as uch, 1
          FROM v_permissions_reu p
         WHERE p.reu is null;
    END IF;
    OPEN prep_refcursor FOR 'SELECT t.rowid, t.reu, t.uch, t.sel
           FROM LIST_CHOICES_UCH t
           ORDER BY t.reu, t.uch ';
  END;

  PROCEDURE list_choice_set_uch(set_ IN NUMBER) IS
  BEGIN
    UPDATE LIST_CHOICES_UCH SET sel = set_;
  END;

  PROCEDURE list_choice_usl(clr_           IN NUMBER,
                            prep_refcursor IN OUT rep_refcursor) IS
    --Временная таблица для выбора услуг
  BEGIN
    IF clr_ = 1 THEN
      DELETE FROM LIST_CHOICES_USL;
      INSERT INTO LIST_CHOICES_USL t
        (USLM, sel)
        SELECT r.USLM, 1 FROM USLM r;
    END IF;
    OPEN prep_refcursor FOR 'SELECT t.rowid,r.nm1, t.sel,r.uslm
           FROM LIST_CHOICES_USL t, USLM r
           WHERE t.USLM=r.USLM
           ORDER BY r.USLM';
  END list_choice_usl;

  PROCEDURE list_choice_usl_set(set_ IN NUMBER) IS
  BEGIN
    UPDATE LIST_CHOICES_USL SET sel = set_;
  END list_choice_usl_set;

  PROCEDURE list_choice_reu(clr_           IN NUMBER,
                            prep_refcursor IN OUT rep_refcursor) IS
    --Временная таблица для выбора услуг
  BEGIN
    IF clr_ = 1 THEN
      delete from list_choices_reu;
      insert into list_choices_reu t
        (reu, sel)
        select t.reu, 1 from s_reu_trest t;
    END IF;
    OPEN prep_refcursor FOR 'select t.rowid, r.name_reu, t.sel, r.reu
           from list_choices_reu t, s_reu_trest r
           where t.reu=r.reu
           order by r.reu';
  END list_choice_reu;

  procedure list_choice_hs_set(set_ in number) is
  begin
    update list_choices_hs set sel = set_;
  end;

  procedure list_choice_hs(clr_           in number,
                        prep_refcursor in out rep_refcursor) is
    --Временная таблица для выбора домов
  begin
    if clr_ = 1 then
      delete from list_choices_hs;
      insert into list_choices_hs t
        (kul, nd, sel)
        select distinct h.kul, h.nd, 1
          from kart h, v_permissions_reu p
         where h.reu = p.reu;
    end if;
    open prep_refcursor for 'SELECT t.rowid, upper(LTRIM(t.nd, ''0'')) AS nd,
         upper(s.name) as name,
         upper(s.name)||'',''||upper(LTRIM(t.nd, ''0'')) as adr,
         t.sel
           FROM list_choices_hs t, spul s
           WHERE t.kul=s.id
           ORDER BY t.sel, s.name, t.nd';
  end;

  PROCEDURE del_day_payments(mg_ IN VARCHAR2) IS
    --Удаление текущих платежей по концу месяца
    stmt VARCHAR2(2000);
  BEGIN
    stmt := 'DELETE FROM period_reports  WHERE mg IS null AND TO_CHAR(dat, ''YYYYMM'')=:mg_';
    EXECUTE IMMEDIATE stmt
      USING mg_;
    stmt := 'DELETE FROM xito5   WHERE mg IS null AND TO_CHAR(dat, ''YYYYMM'')=:mg_';
    EXECUTE IMMEDIATE stmt
      USING mg_;
    stmt := 'DELETE FROM xito5_  WHERE mg IS null AND TO_CHAR(dat, ''YYYYMM'')=:mg_';
    EXECUTE IMMEDIATE stmt
      USING mg_;
    stmt := 'DELETE FROM xxito10 WHERE mg IS null AND TO_CHAR(dat, ''YYYYMM'')=:mg_';
    EXECUTE IMMEDIATE stmt
      USING mg_;
    stmt := 'DELETE FROM xxito11 WHERE mg IS null AND TO_CHAR(dat, ''YYYYMM'')=:mg_';
    EXECUTE IMMEDIATE stmt
      USING mg_;
    stmt := 'DELETE FROM xxito3  WHERE mg IS null AND TO_CHAR(dat, ''YYYYMM'')=:mg_';
    EXECUTE IMMEDIATE stmt
      USING mg_;
    COMMIT;
  END del_day_payments;

  PROCEDURE check_day_hints(cnt_ OUT NUMBER)
  --Проверка прочитан ли совет дня.
   IS
    CURSOR c IS
      SELECT * FROM DAY_HINTS WHERE user_name = USER;
    record_ c%ROWTYPE;
  BEGIN
    OPEN c;
    FETCH c
      INTO record_;
    IF c%rowcount = 0 THEN
      INSERT INTO DAY_HINTS (user_name, dat) VALUES (USER, SYSDATE);
      COMMIT;
      CLOSE c;
      cnt_ := 0;
      RETURN;
    END IF;
    UPDATE DAY_HINTS SET dat = SYSDATE WHERE user_name = USER;
    COMMIT;
    CLOSE c;
    cnt_ := 1;
    RETURN;
  END check_day_hints;

END generator;
/

