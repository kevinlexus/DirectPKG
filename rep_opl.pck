CREATE OR REPLACE PACKAGE SCOTT.rep_opl IS
  TYPE rep_refcursor IS REF CURSOR;
  PROCEDURE report_xito10(var_           IN XXITO12.var%TYPE,
                          reptype_       IN NUMBER,
                          det_           IN NUMBER, --�������������� ����������� �� ������������
                          reu_           IN XXITO12.reu%TYPE,
                          kul_           IN XXITO12.kul%TYPE,
                          nd_            IN XXITO12.nd%TYPE,
                          trest_         IN XXITO12.trest%TYPE,
                          org_           IN NUMBER,
                          dat_           IN XXITO12.dat%TYPE,
                          dat1_          IN XXITO12.dat%TYPE,
                          status_        IN XXITO12.STATUS%TYPE,
                          mg_            IN XXITO12.mg%TYPE,
                          mg1_           IN XXITO12.mg%TYPE,
                          period_        IN XXITO12.dopl%TYPE,
                          period1_       IN XXITO12.dopl%TYPE,
                          prep_refcursor IN OUT rep_refcursor);

  PROCEDURE report_xito3(reu_           IN VARCHAR2,
                         trest_         IN VARCHAR2,
                         mg_            IN VARCHAR2,
                         mg1_           IN VARCHAR2,
                         prep_refcursor IN OUT rep_refcursor);

  PROCEDURE report_xito11(oper_          IN VARCHAR2,
                          reu_           IN VARCHAR2,
                          trest_         IN VARCHAR2,
                          org_           IN NUMBER,
                          dat_           IN XITO5.dat%TYPE,
                          dat1_          IN XITO5.dat%TYPE,
                          mg_            IN VARCHAR2,
                          mg1_           IN VARCHAR2,
                          prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_xito5(var_           IN NUMBER,
                         type_          IN NUMBER,
                         reu_           IN VARCHAR2,
                         trest_         IN VARCHAR2,
                         dat_           IN XITO5.dat%TYPE,
                         dat1_          IN XITO5.dat%TYPE,
                         mg_            IN VARCHAR2,
                         mg1_           IN VARCHAR2,
                         prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_xito5_itog(var_           IN NUMBER,
                              type_          IN NUMBER,
                              dat_           IN XITO5.dat%TYPE,
                              dat1_          IN XITO5.dat%TYPE,
                              mg_            IN VARCHAR2,
                              mg1_           IN VARCHAR2,
                              prep_refcursor IN OUT rep_refcursor);
END rep_opl;
/

CREATE OR REPLACE PACKAGE BODY SCOTT.rep_opl IS
  PROCEDURE report_xito10(var_           IN XXITO12.var%TYPE, --������� ������ (������. �� ������.)
                          reptype_       IN NUMBER, --������� ����� �� ������
                          det_           IN NUMBER, --�������������� ����������� �� ������������
                          reu_           IN XXITO12.reu%TYPE,
                          kul_           IN XXITO12.kul%TYPE,
                          nd_            IN XXITO12.nd%TYPE,
                          trest_         IN XXITO12.trest%TYPE,
                          org_           IN NUMBER,
                          dat_           IN XXITO12.dat%TYPE,
                          dat1_          IN XXITO12.dat%TYPE,
                          status_        IN XXITO12.STATUS%TYPE, --����������� �� �������
                          mg_            IN XXITO12.mg%TYPE,
                          mg1_           IN XXITO12.mg%TYPE,
                          period_        IN XXITO12.dopl%TYPE,
                          period1_       IN XXITO12.dopl%TYPE,
                          prep_refcursor IN OUT rep_refcursor) IS
    sqlstr1 VARCHAR2(500);
    sqlstr2 VARCHAR2(500);
    sqlstr3 VARCHAR2(500);
    sqlstr4 VARCHAR2(500);
    sqlstr5 varchar2(2000);
    tables_ VARCHAR2(500);
  BEGIN

    tables_ := '';
    sqlstr4 := '';
    IF status_ = 1 OR status_ = 0 THEN
      --������� ����������� �� �������
/*      IF var_ = 1 THEN
        --�� ���������������
        sqlstr1 := ' and t.var in (1) and t.status=' || TO_CHAR(status_);
      ELSIF var_ = 2 THEN
        --�� �� ���������������
        sqlstr1 := ' and t.var in (0) and t.status=' || TO_CHAR(status_);
      ELSE
        --�� ����
        sqlstr1 := ' and t.var in (0,1) and t.status=' || TO_CHAR(status_);
      END IF;
*/
      IF org_ IS NOT NULL THEN
        --������ �� �����������
        sqlstr1 := sqlstr1 || ' and t.org IN (' || org_ || ') ';
      END IF;

      IF reptype_ = 1 THEN
        --�.2.2.��������, ��������� �� ��� ������� (����� ����)
        sqlstr2 := ' and forreu=s.reu and d.trest <> s.trest and t.reu=d.reu m';
        sqlstr3 := ' d.trest, substr(d.name_tr,1,15) ';
--        sqlstr5 := ' and t.reu=r.reu ';
      ELSIF reptype_ = 2 THEN
        --�.2.3.��������, ��������� ��� �� ������ (����� ����)
        sqlstr2 := ' and t.reu=s.reu and d.trest <> s.trest and t.forreu=d.reu ';
        sqlstr3 := ' d.trest, substr(d.name_tr,1,15) ';
--        sqlstr5 := ' and t.forreu=r.reu ';
      ELSIF reptype_ = 3 THEN
        --�.2.4.��������, ��������� ��� �� ������ (������� ����) (������)
        sqlstr2 := ' and t.reu=s.reu and t.forreu=d.reu ';
        sqlstr3 := ' d.trest, substr(d.name_tr,1,15) ';
--        sqlstr5 := ' and t.forreu=r.reu ';
      ELSE
        --�.2.1.��� ��������� ���������
        IF reu_ IS NOT NULL OR trest_ IS NOT NULL THEN
          --�� ��� � �� ������ ��������� ��-������� ������
          sqlstr2 := ' and forreu=s.reu and t.reu=d.reu ';
          sqlstr3 := ' d.trest, substr(d.name_tr,1,15)';
--          sqlstr5 := ' and t.reu=r.reu ';
        ELSE
          sqlstr2 := ' and t.forreu=s.reu and s.reu=d.reu '; --��������� �������������
          sqlstr3 := ' s.trest, substr(s.name_tr,1,15) ';
--          sqlstr5 := ' and t.reu=r.reu ';
        END IF;
      END IF;

      IF period_ IS NOT NULL AND period1_ IS NOT NULL THEN
        sqlstr2 := sqlstr2 || ' and t.dopl BETWEEN ' || period_ || ' AND ' ||
                   period1_;
      END IF;

      IF det_ = 1 THEN
        tables_ := ', v_org_periods r';
        sqlstr1 := sqlstr1 ||
                   ' and t.org=r.org and t.dopl between r.dat and r.dat1 and t.forreu=r.reu';
        sqlstr4 := sqlstr4 ||
                   'rtrim(to_char(o.kod)||'' ''||substr(o.name,1,35))||r.mg';
      ELSE
        sqlstr4 := sqlstr4 ||
                   'rtrim(to_char(o.kod)||'' ''||substr(o.name,1,35))';
      END IF;

      IF trest_ IS NOT NULL THEN
        --�� �������
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, SUBSTR(u.nm1,1,22) AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO12 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.dat BETWEEN :dat_ AND :dat1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND s.trest=:trest_ AND t.USL=u.USL
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', SUBSTR(u.nm1,1,22)'
            USING dat_, dat1_, trest_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, SUBSTR(u.nm1,1,22) AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO12 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.mg BETWEEN :mg_ AND :mg1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND s.trest=:trest_ AND t.USL=u.USL
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', SUBSTR(u.nm1,1,22)'
            USING mg_, mg1_, trest_;
        END IF;
      ELSIF reu_ IS NOT NULL AND kul_ IS NULL AND nd_ IS NULL THEN
        --�� ���
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, SUBSTR(u.nm1,1,22) AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO12 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.dat BETWEEN :dat_ AND :dat1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND s.reu=:reu_ AND t.USL=u.USL
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', SUBSTR(u.nm1,1,22)'
            USING dat_, dat1_, reu_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, SUBSTR(u.nm1,1,22) AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO12 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.mg BETWEEN :mg_ AND :mg1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND s.reu=:reu_ AND t.USL=u.USL
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', SUBSTR(u.nm1,1,22)'
            USING mg_, mg1_, reu_;
        END IF;
      ELSIF reu_ IS NOT NULL AND kul_ IS NOT NULL AND nd_ IS NOT NULL THEN
        --�� ������
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, SUBSTR(u.nm1,1,22) AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO12 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.dat BETWEEN :dat_ AND :dat1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND s.reu=:reu_ AND t.kul=:kul_ AND t.nd=:nd_ AND t.USL=u.USL
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', SUBSTR(u.nm1,1,22)'
            USING dat_, dat1_, reu_, kul_, nd_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, SUBSTR(u.nm1,1,22) AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO12 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.mg BETWEEN :mg_ AND :mg1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND s.reu=:reu_ AND t.kul=:kul_ AND t.nd=:nd_ AND t.USL=u.USL
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', SUBSTR(u.nm1,1,22)'
            USING mg_, mg1_, reu_, kul_, nd_;
        END IF;
      ELSE
        --�� ���� ���
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, u.nm1 AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO12 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.dat BETWEEN :dat_ AND :dat1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND t.USL=u.USL
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1'
            USING dat_, dat1_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN

          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          TO_CHAR(o.kod)||'' ''||' || sqlstr4 || ' AS name, u.nm1 AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO12 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.mg BETWEEN :mg_ AND :mg1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND t.USL=u.USL
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1'
            USING mg_, mg1_;
        END IF;
      END IF;
    ELSE
      --��� ����������� �� �������
/*      IF var_ = 1 THEN
        --�� ���������������
        sqlstr1 := ' and t.var in (1) ';
      ELSIF var_ = 2 THEN
        --�� �� ���������������
        sqlstr1 := ' and t.var in (0) ';
      ELSE
        --�� ����
        sqlstr1 := ' and t.var in (0,1) ';
      END IF;
*/
      IF org_ IS NOT NULL THEN
        --������ �� �����������
        sqlstr1 := sqlstr1 || ' and t.org IN (TO_NUMBER(' || TO_CHAR(org_) ||
                   ')) ';
      END IF;

      IF reptype_ = 1 THEN
        --�.2.2.��������, ��������� �� ��� ������� (����� ����)
        sqlstr2 := ' and forreu=s.reu and d.trest <> s.trest and t.reu=d.reu ';
        sqlstr3 := ' d.trest, substr(d.name_tr,1,15) ';
--        sqlstr5 := ' and t.forreu=r.reu ';
      ELSIF reptype_ = 2 THEN
        --�.2.3.��������, ��������� ��� �� ������ (����� ����)
        sqlstr2 := ' and t.reu=s.reu and d.trest <> s.trest and t.forreu=d.reu ';
        sqlstr3 := ' d.trest, substr(d.name_tr,1,15) ';
--        sqlstr5 := ' and t.forreu=r.reu ';
      ELSIF reptype_ = 3 THEN
        --�.2.4.��������, ��������� ��� �� ������ (������� ����) (������)
        sqlstr2 := ' and t.reu=s.reu and t.forreu=d.reu ';
        sqlstr3 := ' d.trest, substr(d.name_tr,1,15) ';
--        sqlstr5 := ' and t.forreu=r.reu ';
      ELSE
        --�.2.1.��� ��������� ���������
        IF reu_ IS NOT NULL OR trest_ IS NOT NULL THEN
          --�� ��� � �� ������ ��������� ��-������� ������
          sqlstr2 := ' and forreu=s.reu and t.reu=d.reu ';
          sqlstr3 := ' d.trest, substr(d.name_tr,1,15) ';
--          sqlstr5 := ' and t.forreu=r.reu ';
        ELSE
          sqlstr2 := ' and t.forreu=s.reu and s.reu=d.reu '; --��������� �������������
          sqlstr3 := ' s.trest, substr(s.name_tr,1,15) ';
--          sqlstr5 := ' and t.forreu=r.reu ';
        END IF;
      END IF;

      IF period_ IS NOT NULL AND period1_ IS NOT NULL THEN
        sqlstr2 := sqlstr2 || ' and t.dopl BETWEEN ' || period_ || ' AND ' ||
                   period1_;
      END IF;

      IF det_ = 1 THEN
        sqlstr1 := sqlstr1 ||
                   ' and o.kod=r.org and t.dopl between r.dat and r.dat1 and t.forreu=r.reu';
        tables_ := ', v_org_periods r';
        sqlstr4 := sqlstr4 ||
                   'rtrim(to_char(o.kod)||'' ''||substr(o.name,1,35))||r.mg';
      ELSE
        sqlstr4 := sqlstr4 ||
                   'rtrim(to_char(o.kod)||'' ''||substr(o.name,1,35))';
      END IF;

      IF trest_ IS NOT NULL THEN
        --�� �������
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, SUBSTR(u.nm1,1,22) AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO10 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.dat BETWEEN :dat_ AND :dat1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND s.trest=:trest_ AND t.USL=u.USL AND t.oborot IN (1)
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', SUBSTR(u.nm1,1,22)'
            USING dat_, dat1_, trest_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, SUBSTR(u.nm1,1,22) AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO10 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.mg BETWEEN :mg_ AND :mg1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND s.trest=:trest_ AND t.USL=u.USL AND t.oborot IN (1)
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', SUBSTR(u.nm1,1,22)'
            USING mg_, mg1_, trest_;
        END IF;
      ELSIF reu_ IS NOT NULL AND kul_ IS NULL AND nd_ IS NULL THEN
        --�� ���
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, SUBSTR(u.nm1,1,22) AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO10 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.dat BETWEEN :dat_ AND :dat1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND s.reu=:reu_ AND t.USL=u.USL AND t.oborot IN (1)
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', SUBSTR(u.nm1,1,22)'
            USING dat_, dat1_, reu_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
         sqlstr5 := 'select ' || sqlstr3 || ' as name_tr,
          TO_CHAR(o.kod)||'' ''||' || sqlstr4 || ' AS name, u.nm1 AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO12 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.mg BETWEEN :mg_ AND :mg1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND t.USL=u.USL
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1';
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, SUBSTR(u.nm1,1,22) AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO10 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.mg BETWEEN :mg_ AND :mg1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND s.reu=:reu_ AND t.USL=u.USL AND t.oborot IN (1)
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', SUBSTR(u.nm1,1,22)'
            USING mg_, mg1_, reu_;
        END IF;
      ELSIF reu_ IS NOT NULL AND kul_ IS NOT NULL AND nd_ IS NOT NULL THEN
        --�� ������
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, SUBSTR(u.nm1,1,22) AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO12 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.dat BETWEEN :dat_ AND :dat1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND s.reu=:reu_ AND t.kul=:kul_ AND t.nd=:nd_ AND t.USL=u.USL
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', SUBSTR(u.nm1,1,22)'
            USING dat_, dat1_, reu_, kul_, nd_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, SUBSTR(u.nm1,1,22) AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO12 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.mg BETWEEN :mg_ AND :mg1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND s.reu=:reu_ AND t.kul=:kul_ AND t.nd=:nd_ AND t.USL=u.USL
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', SUBSTR(u.nm1,1,22)'
            USING mg_, mg1_, reu_, kul_, nd_;
        END IF;
      ELSE
        --�� ���� ���
        IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, u.nm1 AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO10 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.dat BETWEEN :dat_ AND :dat1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND t.USL=u.USL AND t.oborot IN (1)
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1'
            USING dat_, dat1_;
        ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
          OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
          ' || sqlstr4 || ' AS name, u.nm1 AS nm1, ROUND(SUM(summa),2) AS summa FROM XXITO10 t,
          S_REU_TREST s, S_REU_TREST d, SPRORG o, USL u' || tables_ || '
          WHERE  t.mg BETWEEN :mg_ AND :mg1_ ' || sqlstr2 || ' AND t.ORG=o.kod
          ' || sqlstr1 || ' AND t.USL=u.USL AND t.oborot IN (1)
          GROUP BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1
          ORDER BY   ' || sqlstr3 || ', ' || sqlstr4 || ', u.nm1'
            USING mg_, mg1_;
        END IF;
      END IF;
    END IF;

  END report_xito10;

  PROCEDURE report_xito3(reu_           IN VARCHAR2,
                         trest_         IN VARCHAR2,
                         mg_            IN VARCHAR2,
                         mg1_           IN VARCHAR2,
                         prep_refcursor IN OUT rep_refcursor) IS
  BEGIN
    IF trest_ IS NOT NULL THEN
      OPEN prep_refcursor FOR 'select u.nm1, t.dopl, substr(t.dopl,5,2)||''/''||substr(t.dopl,1,4) as period, substr(t.dopl,1,4)||'' �.'' as year,
         o.name||s.name_tr AS predpr, SUM(summa) AS summa
         FROM XXITO3 t, USL u, ORG o, S_REU_TREST s
         WHERE mg BETWEEN :mg_ AND :mg1_ AND t.USL=u.USL AND t.trest=:trest_ AND o.id=2 AND t.reu=s.reu
         GROUP BY u.nm1, t.dopl, SUBSTR(t.dopl,5,2)||''/''||SUBSTR(t.dopl,1,4), SUBSTR(t.dopl,1,4)||'' �.'', o.name||s.name_tr
         ORDER BY t.dopl, u.nm1'
        USING mg_, mg1_, trest_;
    ELSIF reu_ IS NOT NULL THEN
      OPEN prep_refcursor FOR 'select u.nm1, t.dopl, substr(t.dopl,5,2)||''/''||substr(t.dopl,1,4) as period, substr(t.dopl,1,4)||'' �.'' as year,
         s.name_reu AS predpr,SUM(summa) AS summa
         FROM XXITO3 t, USL u, ORG o, S_REU_TREST s
         WHERE mg BETWEEN :mg_ AND :mg1_ AND t.USL=u.USL AND t.reu=:reu AND o.id=3 AND t.reu=s.reu
         GROUP BY u.nm1, t.dopl, SUBSTR(t.dopl,5,2)||''/''||SUBSTR(t.dopl,1,4), SUBSTR(t.dopl,1,4)||'' �.'', s.name_reu
         ORDER BY t.dopl, u.nm1'
        USING mg_, mg1_, reu_;
    ELSE
      OPEN prep_refcursor FOR 'select u.nm1, t.dopl, substr(t.dopl,5,2)||''/''||substr(t.dopl,1,4) as period, substr(t.dopl,1,4)||'' �.'' as year,
         o.name AS predpr, SUM(summa) AS summa
         FROM XXITO3 t, USL u, ORG o
         WHERE mg BETWEEN :mg_ AND :mg1_ AND t.USL=u.USL AND o.id=1
         GROUP BY u.nm1, t.dopl, SUBSTR(t.dopl,5,2)||''/''||SUBSTR(t.dopl,1,4), SUBSTR(t.dopl,1,4)||'' �.'', o.name
         ORDER BY t.dopl, u.nm1'
        USING mg_, mg1_;
    END IF;
  END report_xito3;

  PROCEDURE report_xito11(oper_          IN VARCHAR2,
                          reu_           IN VARCHAR2,
                          trest_         IN VARCHAR2,
                          org_           IN NUMBER,
                          dat_           IN XITO5.dat%TYPE,
                          dat1_          IN XITO5.dat%TYPE,
                          mg_            IN VARCHAR2,
                          mg1_           IN VARCHAR2,
                          prep_refcursor IN OUT rep_refcursor) IS
    sqlstr_ VARCHAR2(500);
  BEGIN
    -- �. 2.4
    IF oper_ = '00' THEN
      --������� ��� ��������
      sqlstr_ := 'and :oper_ = ''00'' AND t.oper IN (SELECT oper FROM oper WHERE SUBSTR(oigu,1,1)=''1'')';
    ELSE
      --������� ���������� ��������
      sqlstr_ := 'and t.oper=:oper_';
    END IF;

    IF org_ IS NOT NULL THEN
      --������ �� �����������
      sqlstr_ := sqlstr_ || ' and t.org IN (' || TO_CHAR(org_) || ') ';
    END IF;

    IF trest_ IS NOT NULL THEN
      --�� �������
      IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
        OPEN prep_refcursor FOR 'select /*+ ORDERED */ s.trest, substr(s.name_tr,1,15) as name_tr, t.oper,
          TO_CHAR(o.kod)||'' ''||SUBSTR(o.name,1,20) AS name, SUBSTR(u.nm1,1,20) AS nm1, SUM(summa) FROM XXITO11 t,
          S_REU_TREST s, SPRORG o, USL u
          WHERE  t.dat BETWEEN :dat_ AND :dat1_ AND t.forreu=s.reu AND t.ORG=o.kod
         ' || sqlstr_ || ' AND s.trest=:trest_ AND t.USL=u.USL
          GROUP BY s.trest, SUBSTR(s.name_tr,1,15), t.OPER, TO_CHAR(o.kod)||'' ''||SUBSTR(o.name,1,20), SUBSTR(u.nm1,1,20)'
          USING dat_, dat1_, oper_, trest_;
      ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
        OPEN prep_refcursor FOR 'select /*+ ORDERED */ s.trest, substr(s.name_tr,1,15) as name_tr, t.oper,
          TO_CHAR(o.kod)||'' ''||SUBSTR(o.name,1,20) AS name, SUBSTR(u.nm1,1,20) AS nm1, SUM(summa) FROM XXITO11 t,
          S_REU_TREST s, SPRORG o, USL u
          WHERE  t.mg BETWEEN :mg_ AND :mg1_ AND t.forreu=s.reu AND t.ORG=o.kod
          ' || sqlstr_ || ' AND s.trest=:trest_ AND t.USL=u.USL
          GROUP BY s.trest, SUBSTR(s.name_tr,1,15), t.OPER, TO_CHAR(o.kod)||'' ''||SUBSTR(o.name,1,20), SUBSTR(u.nm1,1,20)'
          USING mg_, mg1_, oper_, trest_;
      END IF;
    ELSIF reu_ IS NOT NULL THEN
      --�� ���
      IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
        OPEN prep_refcursor FOR 'select /*+ ORDERED */ s.trest, substr(s.name_tr,1,15) as name_tr, t.oper,
          TO_CHAR(o.kod)||'' ''||SUBSTR(o.name,1,20) AS name, SUBSTR(u.nm1,1,20) AS nm1, SUM(summa) FROM XXITO11 t,
          S_REU_TREST s, SPRORG o, USL u
          WHERE  t.dat BETWEEN :dat_ AND :dat1_ AND t.forreu=s.reu AND t.ORG=o.kod
          ' || sqlstr_ || ' AND s.reu=:reu_ AND t.USL=u.USL
          GROUP BY s.trest, SUBSTR(s.name_tr,1,15), t.OPER, TO_CHAR(o.kod)||'' ''||SUBSTR(o.name,1,20), SUBSTR(u.nm1,1,20)'
          USING dat_, dat1_, oper_, reu_;
      ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
        OPEN prep_refcursor FOR 'select /*+ ORDERED */ s.trest, substr(s.name_tr,1,15) as name_tr, t.oper,
          TO_CHAR(o.kod)||'' ''||SUBSTR(o.name,1,20) AS name, SUBSTR(u.nm1,1,20) AS nm1, SUM(summa) FROM XXITO11 t,
          S_REU_TREST s, SPRORG o, USL u
          WHERE  t.mg BETWEEN :mg_ AND :mg1_ AND t.forreu=s.reu AND t.ORG=o.kod
          ' || sqlstr_ || ' AND s.reu=:reu_ AND t.USL=u.USL
          GROUP BY s.trest, SUBSTR(s.name_tr,1,15), t.OPER, TO_CHAR(o.kod)||'' ''||SUBSTR(o.name,1,20), SUBSTR(u.nm1,1,20)'
          USING mg_, mg1_, oper_, reu_;
      END IF;
    ELSE
      --�� ���� ���
      IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
        OPEN prep_refcursor FOR 'select /*+ ORDERED */ s.trest, substr(s.name_tr,1,15) as name_tr, t.oper,
          TO_CHAR(o.kod)||'' ''||SUBSTR(o.name,1,20) AS name, SUBSTR(u.nm1,1,20) AS nm1, SUM(summa) FROM XXITO11 t,
          S_REU_TREST s, SPRORG o, USL u
          WHERE  t.dat BETWEEN :dat_ AND :dat1_ AND t.forreu=s.reu AND t.ORG=o.kod
          ' || sqlstr_ || ' AND t.USL=u.USL
          GROUP BY s.trest, SUBSTR(s.name_tr,1,15), t.OPER, TO_CHAR(o.kod)||'' ''||SUBSTR(o.name,1,20), SUBSTR(u.nm1,1,20)
          ORDER BY s.trest'
          USING dat_, dat1_, oper_;
      ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
        OPEN prep_refcursor FOR 'select /*+ ORDERED */ s.trest, substr(s.name_tr,1,15) as name_tr, t.oper,
          TO_CHAR(o.kod)||'' ''||SUBSTR(o.name,1,20) AS name, SUBSTR(u.nm1,1,20) AS nm1, SUM(summa) FROM XXITO11 t,
          S_REU_TREST s, SPRORG o, USL u
          WHERE  t.mg BETWEEN :mg_ AND :mg1_ AND t.forreu=s.reu AND t.ORG=o.kod
          ' || sqlstr_ || ' AND t.USL=u.USL
          GROUP BY s.trest, SUBSTR(s.name_tr,1,15), t.OPER, TO_CHAR(o.kod)||'' ''||SUBSTR(o.name,1,20), SUBSTR(u.nm1,1,20)
          ORDER BY s.trest'
          USING mg_, mg1_, oper_;
      END IF;
    END IF;

  END report_xito11;
  PROCEDURE report_xito5(var_           IN NUMBER,
                         type_          IN NUMBER,
                         reu_           IN VARCHAR2,
                         trest_         IN VARCHAR2,
                         dat_           IN XITO5.dat%TYPE,
                         dat1_          IN XITO5.dat%TYPE,
                         mg_            IN VARCHAR2,
                         mg1_           IN VARCHAR2,
                         prep_refcursor IN OUT rep_refcursor) IS
    --����� �� ���������
    tname_  VARCHAR2(20);
    sqlstr1 VARCHAR2(50);
  BEGIN
/*    IF var_ = 1 THEN
      --�� ���������������
      sqlstr1 := ' and t.var in (1)';
    ELSIF var_ = 2 THEN
      --�� �� ���������������
      sqlstr1 := ' and t.var in (0)';
    ELSE
      --�� ����
      sqlstr1 := '';
    END IF;
*/
    IF type_ = 0 THEN
      --�� �����������
      tname_ := 'xito5';
    ELSE
      --��� ���������
      tname_ := 'xito5_';
    END IF;

    IF trest_ IS NOT NULL THEN
      --�� �������
      IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
        OPEN prep_refcursor FOR 'SELECT SUM(a.ska) AS ska, SUM(a.pn) AS pn, r.name as nm, s.name_tr as name, a.other, a.nal, a.ink, o.naim
       FROM ' || tname_ || ' a, S_REU_TREST s, OPER o, ORG r, (SELECT DISTINCT reu,var FROM s_reu_trest) t WHERE a.dat BETWEEN :dat_ AND :dat1_ AND s.trest=:trest_
       AND a.reu=s.reu AND a.OPER=o.OPER AND r.id=2 AND s.reu=t.reu ' || sqlstr1 || '
       GROUP BY r.name, s.name_tr, a.other, a.nal, a.ink, o.naim'
          USING dat_, dat1_, trest_;
      ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
        OPEN prep_refcursor FOR 'SELECT SUM(a.ska) AS ska, SUM(a.pn) AS pn, r.name as nm, s.name_tr as name, a.other, a.nal, a.ink, o.naim
       FROM ' || tname_ || ' a, S_REU_TREST s, OPER o, ORG r, (SELECT DISTINCT reu,var FROM s_reu_trest) t WHERE a.mg BETWEEN :mg_ AND :mg1_ AND s.trest=:trest_
       AND a.reu=s.reu AND a.OPER=o.OPER AND r.id=2 AND s.reu=t.reu ' || sqlstr1 || '
       GROUP BY r.name, s.name_tr, a.other, a.nal, a.ink, o.naim'
          USING mg_, mg1_, trest_;
      END IF;
    ELSIF reu_ IS NOT NULL THEN
      --�� ���
      IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
        OPEN prep_refcursor FOR 'SELECT SUM(a.ska) AS ska, SUM(a.pn) AS pn, r.name as nm, s.name_reu as name, a.other, a.nal, a.ink, o.naim
       FROM ' || tname_ || ' a, S_REU_TREST s, OPER o, ORG r, (SELECT DISTINCT reu,var FROM s_reu_trest) t WHERE a.dat BETWEEN :dat_ AND :dat1_ AND a.reu=:reu_
       AND a.reu=s.reu AND a.OPER=o.OPER AND r.id=3 AND s.reu=t.reu ' || sqlstr1 || '
       GROUP BY r.name, s.name_reu, a.other, a.nal, a.ink, o.naim'
          USING dat_, dat1_, reu_;
      ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
        OPEN prep_refcursor FOR 'SELECT SUM(a.ska) AS ska, SUM(a.pn) AS pn, r.name as nm, s.name_reu as name, a.other, a.nal, a.ink, o.naim
       FROM ' || tname_ || ' a, S_REU_TREST s, OPER o, ORG r, (SELECT DISTINCT reu,var FROM s_reu_trest) t WHERE a.mg BETWEEN :mg_ AND :mg1_ AND a.reu=:reu_
       AND a.reu=s.reu AND a.OPER=o.OPER AND r.id=3 AND s.reu=t.reu ' || sqlstr1 || '
       GROUP BY r.name, s.name_reu, a.other, a.nal, a.ink, o.naim'
          USING mg_, mg1_, reu_;
      END IF;
    ELSE
      --�� ���� ���
      IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
        OPEN prep_refcursor FOR 'SELECT SUM(a.ska) AS ska, SUM(a.pn) AS pn, r.name as nm, r1.name as nm1, s.name_tr as name, a.other, a.nal, a.ink, o.naim
       FROM ' || tname_ || ' a, S_REU_TREST s, OPER o, ORG r, ORG r1, (SELECT DISTINCT reu,var FROM s_reu_trest) t WHERE a.dat BETWEEN :dat_ AND :dat1_
       AND a.reu=s.reu AND a.OPER=o.OPER AND r.id=2 AND r1.id=1 AND s.reu=t.reu ' || sqlstr1 || '
       GROUP BY r.name, r1.name, s.trest, s.name_tr, a.other, a.nal, a.ink, o.naim
       ORDER BY s.trest'
          USING dat_, dat1_;
      ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
        OPEN prep_refcursor FOR 'SELECT SUM(a.ska) AS ska, SUM(a.pn) AS pn, r.name as nm, r1.name as nm1, s.name_tr as name, a.other, a.nal, a.ink, o.naim
       FROM ' || tname_ || ' a, S_REU_TREST s, OPER o, ORG r, ORG r1, (SELECT DISTINCT reu,var FROM s_reu_trest) t WHERE a.mg BETWEEN :mg_ AND :mg1_
       AND a.reu=s.reu AND a.OPER=o.OPER AND r.id=2 AND r1.id=1 AND s.reu=t.reu ' || sqlstr1 || '
       GROUP BY r.name, r1.name, s.trest, s.name_tr, a.other, a.nal, a.ink, o.naim
       ORDER BY s.trest'
          USING mg_, mg1_;
      END IF;
    END IF;

  END report_xito5;

  PROCEDURE report_xito5_itog(var_           IN NUMBER,
                              type_          IN NUMBER,
                              dat_           IN XITO5.dat%TYPE,
                              dat1_          IN XITO5.dat%TYPE,
                              mg_            IN VARCHAR2,
                              mg1_           IN VARCHAR2,
                              prep_refcursor IN OUT rep_refcursor) IS
    --����� �� ��������� (�����)
    tname_  VARCHAR2(20);
    sqlstr1 VARCHAR2(50);
  BEGIN
/*    IF var_ = 1 THEN
      --�� ���������������
      sqlstr1 := ' and t.var in (1)';
    ELSIF var_ = 2 THEN
      --�� �� ���������������
      sqlstr1 := ' and t.var in (0)';
    ELSE
      --�� ����
      sqlstr1 := '';
    END IF;*/

    IF type_ = 0 THEN
      --�� �����������
      tname_ := 'xito5';
    ELSE
      --��� ���������
      tname_ := 'xito5_';
    END IF;

    IF dat_ IS NOT NULL AND dat1_ IS NOT NULL THEN
      OPEN prep_refcursor FOR 'SELECT SUM(a.ska) AS ska, SUM(a.pn) AS pn, a.other, a.nal, a.ink, o.naim
       FROM ' || tname_ || ' a, S_REU_TREST s, (SELECT DISTINCT reu,var FROM s_reu_trest) t, OPER o WHERE a.dat BETWEEN :dat_ AND :dat1_
       AND a.reu=s.reu AND a.OPER=o.OPER AND s.reu=t.reu ' || sqlstr1 || '
       GROUP BY a.other, a.nal, a.ink, o.naim'
        USING dat_, dat1_;
    ELSIF mg_ IS NOT NULL AND mg1_ IS NOT NULL THEN
      OPEN prep_refcursor FOR 'SELECT SUM(a.ska) AS ska, SUM(a.pn) AS pn, a.other, a.nal, a.ink, o.naim
       FROM ' || tname_ || ' a, S_REU_TREST s, (SELECT DISTINCT reu,var FROM s_reu_trest) t, OPER o WHERE a.mg BETWEEN :mg_ AND :mg1_
       AND a.reu=s.reu AND a.OPER=o.OPER AND s.reu=t.reu ' || sqlstr1 || '
       GROUP BY a.other, a.nal, a.ink, o.naim'
        USING mg_, mg1_;
    END IF;

  END report_xito5_itog;
END rep_opl;
/

