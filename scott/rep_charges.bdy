CREATE OR REPLACE PACKAGE BODY SCOTT.rep_charges IS
  PROCEDURE report_xito13(reu_           IN XITO13.reu%TYPE,
                          kul_           IN XITO13.kul%TYPE,
                          nd_            IN XITO13.nd%TYPE,
                          trest_         IN XITO13.trest%TYPE,
                          mg_            IN XITO13.mg%TYPE,
                          mg1_           IN XITO13.mg%TYPE,
                          prep_refcursor IN OUT rep_refcursor) IS
  BEGIN
    IF trest_ IS NOT NULL THEN
      NULL;
      --По трестам
      /*        OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
      substr(o.name,1,35) as name, substr(u.nm1,1,22) as nm1, round(sum(summa),2) as summa from xxito12 t,
      s_reu_trest s, s_reu_trest d, sprorg o, usl u
      where  t.mg BETWEEN :mg_ AND :mg1_ ' || sqlstr2 || ' and t.org=o.kod
      ' || sqlstr1 || ' and s.trest=:trest_ and t.usl=u.usl
      group by   ' || sqlstr3 || ', o.kod, substr(o.name,1,35), substr(u.nm1,1,22)
      order by   ' || sqlstr3 || ', o.kod, substr(u.nm1,1,22)'
      USING mg_, mg1_, trest_;*/
    ELSIF reu_ IS NOT NULL AND kul_ IS NULL AND nd_ IS NULL THEN
      --По РЭУ
      OPEN prep_refcursor FOR 'select s.name_tr, t.reu, p.name as street, LTRIM(t.ND, ''0'') as nd, u.nm, sum(t.summa) as summa
          FROM XITO13 t, S_REU_TREST s, USL u, SPUL p
          WHERE t.mg BETWEEN :mg_ AND :mg1_ AND t.reu=s.reu AND t.kul=p.id AND t.USL=u.USL
          AND t.reu=:reu_
          GROUP BY s.name_tr, t.reu, p.name, LTRIM(t.ND, ''0''), u.nm'
        USING mg_, mg1_, reu_;
    ELSIF reu_ IS NOT NULL AND kul_ IS NOT NULL AND nd_ IS NOT NULL THEN
      NULL;
      --По адресу
      /*  OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
      substr(o.name,1,35) as name, substr(u.nm1,1,22) as nm1, round(sum(summa),2) as summa from xxito12 t,
      s_reu_trest s, s_reu_trest d, sprorg o, usl u
      where  t.mg BETWEEN :mg_ AND :mg1_ ' || sqlstr2 || ' and t.org=o.kod
      ' || sqlstr1 || ' and s.reu=:reu_ and t.kul=:kul_ and t.nd=:nd_ and t.usl=u.usl
      group by   ' || sqlstr3 || ', o.kod, substr(o.name,1,35), substr(u.nm1,1,22)
      order by   ' || sqlstr3 || ', o.kod, substr(u.nm1,1,22)'
      USING mg_, mg1_, reu_, kul_, nd_;*/
    ELSE
      NULL;
      --По всем ЖЭО
      /*  OPEN prep_refcursor FOR 'select ' || sqlstr3 || ' as name_tr,
      to_char(o.kod)||'' ''||substr(o.name,1,35) as name, u.nm1 as nm1, round(sum(summa),2) as summa from xxito12 t,
      s_reu_trest s, s_reu_trest d, sprorg o, usl u
      where  t.mg BETWEEN :mg_ AND :mg1_ ' || sqlstr2 || ' and t.org=o.kod
      ' || sqlstr1 || ' and t.usl=u.usl
      group by   ' || sqlstr3 || ', to_char(o.kod)||'' ''||substr(o.name,1,35), u.nm1
      order by   ' || sqlstr3 || ', to_char(o.kod)||'' ''||substr(o.name,1,35), u.nm1'
      USING mg_, mg1_;*/
    END IF;
  END report_xito13;
END rep_charges;
/

