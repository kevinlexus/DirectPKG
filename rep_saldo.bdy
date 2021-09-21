CREATE OR REPLACE PACKAGE BODY SCOTT.rep_saldo IS
  PROCEDURE report_saldo(reu_           IN VARCHAR2,
                         trest_         IN VARCHAR2,
                         uslm_         IN VARCHAR2,
                         mg_            IN VARCHAR2,
                         mg1_           IN VARCHAR2,
                         var_         IN NUMBER,
                         prep_refcursor IN OUT rep_refcursor) IS
    --Оборотка по РЭУ/домам
-- sql_ varchar2(200);
  BEGIN
/*  if uslm_ ='000' then
     sql_:='';
  else
     sql_:=' and u.uslm = '''||uslm_||'''';
  end if;*/

    IF var_ = 4 THEN
      --по дому
      OPEN prep_refcursor FOR select null as predpr, h.name_reu||' '||p.name||', '||ltrim(h.nd,'0') as adr, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(o.changes+o.changes2) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select u.reu, u.kul, u.nd, u.usl, u.org, u.status, u2.uslm, u.fk_lsk_tp,  trim(s.name_reu) as name_reu from t_saldo_reu_kul_nd_st u, s_reu_trest s, usl u2
      where u.usl=u2.usl and u.reu=s.reu and exists (select * from list_choices t
      where t.reu=u.reu and u.kul=t.kul and u.nd=t.nd and t.sel = 0)
       and (uslm_ = '000' or u2.uslm=uslm_) ) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp, sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, uslm m, org l, spul p
      where h.kul=p.id and
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=3 and h.org=d.kod and h.uslm=m.uslm
      group by h.name_reu||' '||p.name||', '||ltrim(h.nd,'0')
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by h.name_reu||' '||p.name||', '||ltrim(h.nd,'0');
          --USING mg_, mg_, mg1_, mg1_;
    ELSIF var_ = 3 THEN
      --по ЖЭО
      OPEN prep_refcursor FOR select l.name||h.name_reu as predpr, p.name||', '||ltrim(h.nd,'0') as adr, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(o.changes+o.changes2) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select u.reu, u.kul, u.nd, u.usl, u.org, u.status, u2.uslm, u.fk_lsk_tp,  trim(s.name_reu) as name_reu from t_saldo_reu_kul_nd_st u, s_reu_trest s, usl u2
      where u.usl=u2.usl and u.reu=s.reu and exists (select * from list_choices t
      where u.reu=reu_ and t.reu=u.reu and u.kul=t.kul and u.nd=t.nd and t.sel = 0)
       and (uslm_ = '000' or u2.uslm=uslm_)) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp,sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, uslm m, org l, spul p
      where h.kul=p.id and
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=3 and h.org=d.kod and h.uslm=m.uslm
      group by l.name||h.name_reu, p.name||', '||ltrim(h.nd,'0')
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by  l.name||h.name_reu, p.name||', '||ltrim(h.nd,'0');
--          USING reu_, mg_, mg_, mg1_, mg1_;
    ELSIF var_ = 2  THEN
      --по Фонду
      OPEN prep_refcursor FOR select l.name||t.name_tr as predpr, p.name||', '||ltrim(h.nd,'0') as adr, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(o.changes+o.changes2) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select u.reu, u.kul, u.nd, u.usl, u.org, u.status, u2.uslm, u.fk_lsk_tp,  trim(s.name_reu) as name_reu from t_saldo_reu_kul_nd_st u, s_reu_trest s, usl u2
      where u.usl=u2.usl and u.reu=s.reu and exists (select * from list_choices t
      where u.reu=reu_ and t.reu=u.reu and u.kul=t.kul and u.nd=t.nd and t.sel = 0)
       and s.trest = trest_
       and (uslm_ = '000' or u2.uslm=uslm_)) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp, sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, uslm m, org l, spul p, s_reu_trest t
      where h.kul=p.id and h.reu=t.reu and
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=2 and h.org=d.kod and h.uslm=m.uslm
      group by l.name||t.name_tr, p.name||', '||ltrim(h.nd,'0')
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by l.name||t.name_tr, p.name||', '||ltrim(h.nd,'0');
--          USING trest_, mg_, mg_, mg1_, mg1_;
    ELSIF var_ = 1 THEN
      --по Городу
      OPEN prep_refcursor FOR select l.name as predpr, p.name||', '||ltrim(h.nd,'0') as adr, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.poutsal) as poutsal, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(o.changes+o.changes2) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select u.reu, u.kul, u.nd, u.usl, u.org, u.status, u2.uslm, u.fk_lsk_tp,  trim(s.name_reu) as name_reu from t_saldo_reu_kul_nd_st u, s_reu_trest s, usl u2
      where u.usl=u2.usl and u.reu=s.reu and exists (select * from list_choices t
      where u.reu=reu_ and t.reu=u.reu and u.kul=t.kul and u.nd=t.nd and t.sel = 0)
       and s.trest = trest_
       and (uslm_ = '000' or u2.uslm=uslm_)) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp, sum(charges) as charges, sum(poutsal) as poutsal,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, uslm m, org l, spul p
      where h.kul=p.id and
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=1 and h.org=d.kod and h.uslm=m.uslm
      group by l.name, p.name||', '||ltrim(h.nd,'0')
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by l.name, p.name||', '||ltrim(h.nd,'0');
     --     USING mg_, mg_, mg1_, mg1_;
     END IF;
  END report_saldo;

  PROCEDURE report_saldo_org_uslm(reu_           IN VARCHAR2,
                                  trest_         IN VARCHAR2,
                                  mg_            IN VARCHAR2,
                                  mg1_           IN VARCHAR2,
                                  kul_           IN VARCHAR2,
                                  nd_            IN VARCHAR2,
                                  var_           IN NUMBER,
                                  prep_refcursor IN OUT rep_refcursor) IS
    --Оборотка по предприятиям - услугам
  BEGIN
    IF reu_ IS NOT NULL AND kul_ IS NULL AND nd_ IS NULL THEN
    -- По ЖЭО
      OPEN prep_refcursor FOR select d.npp, l.name||h.name_reu as predpr,null as type, to_char(d.kod)||' '||d.name as org, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1) as nm1, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(o.changes+o.changes2) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select e.reu, e.kul, e.nd, e.usl, e.org, e.status, u.uslm, s.name_reu, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, s_reu_trest s, usl u
      where e.usl=u.usl and e.reu=reu_ and e.reu=s.reu) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp, sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(changes+changes2) as changesall,
       sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status, fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, usl m, org l
      where
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and 
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=3 and h.org=d.kod and h.usl=m.usl
      group by d.npp, l.name||h.name_reu, to_char(d.kod)||' '||d.name, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1)
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by d.npp;
--        USING reu_, mg_, mg_, mg1_, mg1_;
    ELSIF trest_ IS NOT NULL THEN
    -- По Фонду
      OPEN prep_refcursor FOR select d.npp,l.name||h.name_tr as predpr, null as type, to_char(d.kod)||' '||d.name as org, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1) as nm1, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(o.changes+o.changes2) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select e.reu, e.kul, e.nd, e.usl, e.org, e.status, u.uslm, s.name_reu, s.name_tr, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, s_reu_trest s, usl u
      where e.usl=u.usl and s.trest=trest_ and e.reu=s.reu) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp, sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, usl m, org l
      where
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=2 and h.org=d.kod and h.usl=m.usl
      group by d.npp, l.name||h.name_tr, to_char(d.kod)||' '||d.name, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1)
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by d.npp;
--        USING trest_, mg_, mg_, mg1_, mg1_;
    ELSIF reu_ IS NULL AND trest_ IS NULL THEN
    -- По Городу
      OPEN prep_refcursor FOR select d.npp, l.name as predpr,null as type, to_char(d.kod)||' '||d.name as org, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1) as nm1, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(o.changes+o.changes2) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select e.reu, e.kul, e.nd, e.usl, e.org, e.status, u.uslm, s.name_reu, s.name_tr, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, s_reu_trest s, usl u
      where e.usl=u.usl and e.reu=s.reu) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp, sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, usl m, org l
      where
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=1 and h.org=d.kod and h.usl=m.usl
      group by d.npp, l.name, to_char(d.kod)||' '||d.name, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1)
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by d.npp;
      --  USING mg_, mg_, mg1_, mg1_;
    ELSIF reu_ IS NOT NULL AND kul_ IS NOT NULL AND nd_ IS NOT NULL THEN
    -- По выбранному дому
      OPEN prep_refcursor FOR select d.npp, h.name_reu||' '||l.name||h.name||', '||ltrim(h.nd,'0') as predpr,
      null as type, to_char(d.kod)||' '||d.name as org, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1) as nm1,
      sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(o.changes+o.changes2) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (
      select e.reu, e.kul, e.nd, e.usl, e.org, e.status, u.uslm, t.name_tr, 
        trim(t.name_reu) as name_reu, s.name, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, s_reu_trest t, spul s, usl u
      where e.usl=u.usl and e.reu=t.reu and e.kul=s.id and exists (select * from list_choices l
      where l.reu=e.reu and l.kul=e.kul and l.nd=e.nd and l.sel=0)
      ) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp, sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, usl m, org l
      where
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=4 and h.org=d.kod and h.usl=m.usl
      group by d.npp, h.name_reu||' '||l.name||h.name||', '||ltrim(h.nd,'0'),
      to_char(d.kod)||' '||d.name, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1)
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by h.name_reu||' '||l.name||h.name||', '||ltrim(h.nd,'0'), d.npp;
--        USING  mg_, mg_, mg1_, mg1_;
  END IF;
  END report_saldo_org_uslm;

  PROCEDURE report_saldo_uslm2(reu_           IN VARCHAR2,
                               trest_         IN VARCHAR2,
                               mg_            IN VARCHAR2,
                               mg1_           IN VARCHAR2,
                               kul_           IN VARCHAR2,
                               nd_            IN VARCHAR2,
                               uch_           IN NUMBER,
                               var_            IN NUMBER,
                               prep_refcursor IN OUT rep_refcursor) IS
    --Оборотка по услугам
  BEGIN
    -- По ЖЭО
    IF reu_ IS NOT NULL AND kul_ IS NULL AND nd_ IS NULL THEN
      OPEN prep_refcursor FOR select l.name||h.name_reu as predpr, null as type, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1) as nm1, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(o.changes+o.changes2) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select e.reu, e.kul, e.nd, e.usl, e.org, e.status, u.uslm, s.name_reu, s.name_tr, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, s_reu_trest s, usl u
      where e.usl=u.usl and e.reu=s.reu and e.reu=reu_) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp, sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, usl m, org l
      where
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=3 and h.org=d.kod and h.usl=m.usl
      group by l.name||h.name_reu, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1)
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1);
       -- USING reu_, mg_, mg_, mg1_, mg1_;
    ELSIF trest_ IS NOT NULL THEN
    --По Фонду
      OPEN prep_refcursor FOR select l.name||h.name_tr as predpr, null as type, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1) as nm1,
      sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(o.changes+o.changes2) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select e.reu, e.kul, e.nd, e.usl, e.org, e.status, u.uslm, s.name_reu, s.name_tr, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, s_reu_trest s, usl u
      where e.usl=u.usl and e.reu=s.reu and s.trest=trest_) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp,sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, usl m, org l
      where
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=2 and h.org=d.kod and h.usl=m.usl
      group by l.name||h.name_tr, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1)
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1);
--        USING trest_, mg_, mg_, mg1_, mg1_;
    -- По Городу
    ELSIF reu_ IS NULL AND trest_ IS NULL AND uch_ IS NULL THEN
      OPEN prep_refcursor FOR select l.name as predpr, null as type, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1) as nm1, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(o.changes+o.changes2) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select e.reu, e.kul, e.nd, e.usl, e.org, e.status, u.uslm, s.name_reu, s.name_tr, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, s_reu_trest s, usl u
      where e.usl=u.usl and e.reu=s.reu) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp, sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, usl m, org l
      where
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=1 and h.org=d.kod and h.usl=m.usl
      group by l.name, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1)
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1);
--        USING mg_, mg_, mg1_, mg1_;
    -- По выбранному дому
    ELSIF reu_ IS NOT NULL AND kul_ IS NOT NULL AND nd_ IS NOT NULL THEN
      OPEN prep_refcursor FOR select h.name_reu||', по '||l.name||h.name||', '||ltrim(h.nd,'0') as predpr, null as type,
      to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1) as nm1, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      h.reu, h.kul, h.nd,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(o.changes+o.changes2) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from (select e.reu, e.kul, e.nd, e.usl, e.org, e.status, u.uslm, t.name_tr, 
        trim(t.name_reu) as name_reu, s.name, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, s_reu_trest t, spul s, usl u
      where e.usl=u.usl and e.reu=t.reu and e.kul=s.id and exists (select * from list_choices l
      where l.reu=e.reu and l.kul=e.kul and l.nd=e.nd and l.sel=0)) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp, sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, usl m, org l
      where
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=4 and h.org=d.kod and h.usl=m.usl
      group by h.name_reu||', по '||l.name||h.name||', '||ltrim(h.nd,'0'), to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1), h.reu, h.kul, h.nd
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by h.name_reu||', по '||l.name||h.name||', '||ltrim(h.nd,'0'), to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1);
--        USING mg_, mg_, mg1_, mg1_;
    END IF;
  END report_saldo_uslm2;

  PROCEDURE report_saldo_org_uslm_itog(type_          IN NUMBER,
                                       reu_           IN VARCHAR2,
                                       trest_         IN VARCHAR2,
                                       uslk_          IN USLK.USLK%TYPE,
                                       mg_            IN VARCHAR2,
                                       mg1_           IN VARCHAR2,
                                       kul_           IN VARCHAR2,
                                       nd_            IN VARCHAR2,
                                       prep_refcursor IN OUT rep_refcursor) IS
    --Сноска по отчету сальдо по предприятиям, по услугам
    tname_ VARCHAR2(20);
  BEGIN
    IF type_ = 0 THEN
      tname_ := 'charges';
    ELSE
      tname_ := 'subsid';
    END IF;

    IF reu_ IS NOT NULL AND kul_ IS NULL AND nd_ IS NULL THEN
      OPEN prep_refcursor FOR 'select round(sum(t.' || tname_ || ' * a.summa/b.summa),2) as summa,round(sum(t.' || tname_ || '),2) as summa2, c.name
          FROM XITOG3 t,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=:uslk_) a,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=''001'') b, USLK c
          WHERE t.mg=a.mg AND t.mg=b.mg
          AND t.mg BETWEEN :mg_ AND :mg1_
          AND t.USLM=''002''
          AND c.USLK=:uslk_ AND t.reu=:reu_
          GROUP BY c.name'
        USING uslk_, mg_, mg1_, uslk_, reu_;
    ELSIF trest_ IS NOT NULL THEN
      OPEN prep_refcursor FOR 'select round(sum(t.' || tname_ || ' * a.summa/b.summa),2) as summa,round(sum(t.' || tname_ || '),2) as summa2, c.name
          FROM XITOG3 t, S_REU_TREST k,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=:uslk_) a,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=''001'') b, USLK c
          WHERE t.mg=a.mg AND t.mg=b.mg
          AND t.mg BETWEEN :mg_ AND :mg1_
          AND t.USLM=''002''
          AND c.USLK=:uslk_ AND t.reu=k.reu AND k.trest=:trest_
          GROUP BY c.name'
        USING uslk_, mg_, mg1_, uslk_, trest_;
    ELSIF reu_ IS NOT NULL AND kul_ IS NOT NULL AND nd_ IS NOT NULL THEN
      OPEN prep_refcursor FOR 'select round(sum(t.' || tname_ || ' * a.summa/b.summa),2) as summa,round(sum(t.' || tname_ || '),2) as summa2, c.name
          FROM XITOG3 t,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=:uslk_) a,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=''001'') b, USLK c
          WHERE t.mg=a.mg AND t.mg=b.mg
          AND t.mg BETWEEN :mg_ AND :mg1_
          AND t.USLM=''002''
          AND c.USLK=:uslk_ AND t.reu=:reu_ AND t.kul=:kul_ AND t.nd=:nd_
          GROUP BY c.name'
        USING uslk_, mg_, mg1_, uslk_, reu_, kul_, nd_;
    ELSE
      -- По МП УЕЗЖКУ
      OPEN prep_refcursor FOR 'select round(sum(t.' || tname_ || ' * a.summa/b.summa),2) as summa,round(sum(t.' || tname_ || '),2) as summa2, c.name
          FROM XITOG3 t,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=:uslk_) a,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=''001'') b, USLK c
          WHERE t.mg=a.mg AND t.mg=b.mg
          AND t.mg BETWEEN :mg_ AND :mg1_
          AND t.USLM=''002''
          AND c.USLK=:uslk_
          GROUP BY c.name'
        USING uslk_, mg_, mg1_, uslk_;
    END IF;
  END report_saldo_org_uslm_itog;

  PROCEDURE report_saldo_org_uslm_itog2(type_          IN NUMBER,
                                        reu_           IN VARCHAR2,
                                        trest_         IN VARCHAR2,
                                        uslk_          IN USLK.USLK%TYPE,
                                        mg_            IN VARCHAR2,
                                        mg1_           IN VARCHAR2,
                                        kul_           IN VARCHAR2,
                                        nd_            IN VARCHAR2,
                                        uch_           IN NUMBER,
                                        prep_refcursor IN OUT rep_refcursor) IS
    --Сноска по отчету сальдо по предприятиям, по услугам
    tname_ VARCHAR2(20);
  BEGIN
    IF type_ = 0 THEN
      tname_ := 'charges';
    ELSE
      tname_ := 'subsid';
    END IF;

    IF reu_ IS NOT NULL AND kul_ IS NULL AND nd_ IS NULL AND uch_ IS NULL THEN
      OPEN prep_refcursor FOR 'select round(sum(t.' || tname_ || ' * a.summa/b.summa),2) as summa,round(sum(t.' || tname_ || '),2) as summa2, c.name
          FROM XITOG3 t,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=:uslk_) a,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=''001'') b, USLK c
          WHERE t.mg=a.mg AND t.mg=b.mg
          AND t.mg BETWEEN :mg_ AND :mg1_
          AND t.USLM=''002''
          AND c.USLK=:uslk_ AND t.reu=:reu_
          GROUP BY c.name'
        USING uslk_, mg_, mg1_, uslk_, reu_;
    ELSIF trest_ IS NOT NULL AND uch_ IS NULL THEN
      OPEN prep_refcursor FOR 'select round(sum(t.' || tname_ || ' * a.summa/b.summa),2) as summa,round(sum(t.' || tname_ || '),2) as summa2, c.name
          FROM XITOG3 t, S_REU_TREST k,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=:uslk_) a,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=''001'') b, USLK c
          WHERE t.mg=a.mg AND t.mg=b.mg
          AND t.mg BETWEEN :mg_ AND :mg1_
          AND t.USLM=''002''
          AND c.USLK=:uslk_ AND t.reu=k.reu AND k.trest=:trest_
          GROUP BY c.name'
        USING uslk_, mg_, mg1_, uslk_, trest_;
    ELSIF reu_ IS NOT NULL AND kul_ IS NOT NULL AND nd_ IS NOT NULL AND
          uch_ IS NULL THEN
      OPEN prep_refcursor FOR 'select round(sum(t.' || tname_ || ' * a.summa/b.summa),2) as summa,
          ROUND(SUM(t.' || tname_ || '),2) AS summa2, c.name
          FROM XITOG3 t,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=:uslk_) a,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=''001'') b, USLK c
          WHERE t.mg=a.mg AND t.mg=b.mg
          AND t.mg BETWEEN :mg_ AND :mg1_
          AND t.USLM=''002''
          AND c.USLK=:uslk_ AND
          EXISTS (SELECT * FROM LIST_CHOICES l
               WHERE l.reu=t.reu AND l.kul=t.kul AND l.nd=t.nd AND l.sel=0)
          GROUP BY c.name'
        USING uslk_, mg_, mg1_, uslk_;
    ELSIF reu_ IS NOT NULL AND kul_ IS NOT NULL AND nd_ IS NOT NULL AND
          uch_ IS NOT NULL THEN
      OPEN prep_refcursor FOR 'select round(sum(t.' || tname_ || ' * a.summa/b.summa),2) as summa,
          ROUND(SUM(t.' || tname_ || '),2) AS summa2, c.name
          FROM XITOG3 t, KOOP_UCH k,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=:uslk_) a,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=''001'') b, USLK c
          WHERE t.mg=a.mg AND t.mg=b.mg
          AND t.mg BETWEEN :mg_ AND :mg1_
          AND t.USLM=''002''
          AND c.USLK=:uslk_ AND t.reu=k.reu AND t.kul=k.kul AND t.nd=k.nd AND
          EXISTS (SELECT * FROM LIST_CHOICES_UCH l
               WHERE l.reu=t.reu AND l.uch=k.uch AND l.sel=0)
          GROUP BY c.name'
        USING uslk_, mg_, mg1_, uslk_;
    ELSE
      -- По МП УЕЗЖКУ
      OPEN prep_refcursor FOR 'select round(sum(t.' || tname_ || ' * a.summa/b.summa),2) as summa,round(sum(t.' || tname_ || '),2) as summa2, c.name
          FROM XITOG3 t,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=:uslk_) a,
          (SELECT p.mg, p.summa FROM PRICES_USLK p
          WHERE p.USLK=''001'') b, USLK c
          WHERE t.mg=a.mg AND t.mg=b.mg
          AND t.mg BETWEEN :mg_ AND :mg1_
          AND t.USLM=''002''
          AND c.USLK=:uslk_
          GROUP BY c.name'
        USING uslk_, mg_, mg1_, uslk_;
    END IF;
  END report_saldo_org_uslm_itog2;

  PROCEDURE report_charges_usl(reu_           IN VARCHAR2,
                               trest_         IN VARCHAR2,
                               mg_            IN VARCHAR2,
                               mg1_           IN VARCHAR2,
                               var_           IN NUMBER,
                               type_           IN NUMBER,
                               det_           IN NUMBER,
                               prep_refcursor IN OUT rep_refcursor) IS
    --Начисление по услугам
  field_ VARCHAR2(20);
  BEGIN
  IF det_ = 0 THEN --Без детализации
   IF var_ = 3 THEN --По дому
      OPEN prep_refcursor FOR 'select ''РЭУ:''||x.reu||'' ''||s.name||'', ''||LTRIM(x.nd,''0'') as predpr,
             x.USL, SUBSTR(u.nm,1,15) AS nm, SUBSTR(u.nm1,1,15) AS nm1, SUM(x.summa) AS summa
             FROM XITO13 x, USL u, SPUL s
             WHERE x.mg BETWEEN :mg_ AND :mg1_ AND x.USL=u.USL AND x.kul=s.id
             AND EXISTS (SELECT * FROM LIST_CHOICES l
               WHERE l.reu=x.reu AND l.kul=x.kul AND l.nd=x.nd AND l.sel=0)
             GROUP BY ''РЭУ:''||x.reu||'' ''||s.name||'', ''||LTRIM(x.nd,''0''), x.USL, SUBSTR(u.nm,1,15), SUBSTR(u.nm1,1,15)'
        USING mg_, mg1_;
   ELSIF var_ = 2 THEN --По РЭУ
      OPEN prep_refcursor FOR 'select s.name||'', ''||LTRIM(x.nd,''0'') as predpr,
             x.USL, SUBSTR(u.nm,1,15) AS nm, SUBSTR(u.nm1,1,15) AS nm1, SUM(x.summa) AS summa
             FROM XITO13 x, USL u, SPUL s
             WHERE x.reu=:reu_ AND x.mg BETWEEN :mg_ AND :mg1_ AND x.USL=u.USL AND x.kul=s.id
             GROUP BY s.name||'', ''||LTRIM(x.nd,''0''), x.USL, SUBSTR(u.nm,1,15), SUBSTR(u.nm1,1,15)'
        USING reu_, mg_, mg1_;
   ELSIF var_ = 1 THEN --По ЖЭО
      OPEN prep_refcursor FOR 'select ''РЭУ:''||x.reu as predpr,
             x.USL, SUBSTR(u.nm,1,15) AS nm, SUBSTR(u.nm1,1,15) AS nm1, SUM(x.summa) AS summa
             FROM XITO13 x, USL u, SPUL s
             WHERE x.trest=:trest_ AND x.mg BETWEEN :mg_ AND :mg1_ AND x.USL=u.USL AND x.kul=s.id
             GROUP BY ''РЭУ:''||x.reu, x.USL, SUBSTR(u.nm,1,15), SUBSTR(u.nm1,1,15)'
        USING trest_, mg_, mg1_;
   ELSIF var_ = 0 THEN --По МП УЕЗЖКУ (все тресты)
      OPEN prep_refcursor FOR 'select ''ЖЭО:''||t.name_tr as predpr,
             x.USL, SUBSTR(u.nm,1,15) AS nm, SUBSTR(u.nm1,1,15) AS nm1, SUM(x.summa) AS summa
             FROM XITO13 x, USL u, SPUL s, S_REU_TREST t
             WHERE x.mg BETWEEN :mg_ AND :mg1_ AND x.USL=u.USL AND x.kul=s.id
             AND x.trest= t.trest
             GROUP BY ''ЖЭО:''||t.name_tr, x.USL, SUBSTR(u.nm,1,15), SUBSTR(u.nm1,1,15)'
        USING mg_, mg1_;
   END IF;
  ELSE
   IF type_ = 0 THEN
      field_:='charges';
   ELSIF type_ = 1 THEN
      field_:='changes';
   ELSIF type_ = 2 THEN
      field_:='subsid';
   ELSIF type_ = 3 THEN
      field_:='payment';
   ELSIF type_ = 4 THEN
      field_:='pn';
   END IF;

   IF var_ = 3 THEN --По дому
      OPEN prep_refcursor FOR 'select ''РЭУ:''||x.reu||'' ''||s.name||'', ''||LTRIM(x.nd,''0'') as predpr,
             SUBSTR(u.nm1,1,15) AS nm1, SUM(x.'||field_||') AS summa
             FROM XITOG3 x, USLM u, SPUL s
             WHERE x.mg BETWEEN :mg_ AND :mg1_ AND x.USLM=u.USLM AND x.kul=s.id
             AND EXISTS (SELECT * FROM LIST_CHOICES l
               WHERE l.reu=x.reu AND l.kul=x.kul AND l.nd=x.nd AND l.sel=0)
             GROUP BY ''РЭУ:''||x.reu||'' ''||s.name||'', ''||LTRIM(x.nd,''0''), SUBSTR(u.nm1,1,15)'
        USING mg_, mg1_;
   ELSIF var_ = 2 THEN --По РЭУ
      OPEN prep_refcursor FOR 'select s.name||'', ''||LTRIM(x.nd,''0'') as predpr,
             SUBSTR(u.nm1,1,15) AS nm1, SUM(x.'||field_||') AS summa
             FROM XITOG3 x, USLM u, SPUL s
             WHERE x.reu=:reu_ AND x.mg BETWEEN :mg_ AND :mg1_ AND x.USLM=u.USLM AND x.kul=s.id
             GROUP BY s.name||'', ''||LTRIM(x.nd,''0''), SUBSTR(u.nm1,1,15)'
        USING reu_, mg_, mg1_;
   ELSIF var_ = 1 THEN --По ЖЭО
      OPEN prep_refcursor FOR 'select ''РЭУ:''||x.reu as predpr,
             SUBSTR(u.nm1,1,15) AS nm1, SUM(x.'||field_||') AS summa
             FROM XITOG3 x, USLM u, SPUL s
             WHERE x.trest=:trest_ AND x.mg BETWEEN :mg_ AND :mg1_ AND x.USLM=u.USLM AND x.kul=s.id
             GROUP BY ''РЭУ:''||x.reu, SUBSTR(u.nm1,1,15)'
        USING trest_, mg_, mg1_;
   ELSIF var_ = 0 THEN --По МП УЕЗЖКУ (все тресты)
      OPEN prep_refcursor FOR 'select ''ЖЭО:''||t.name_tr as predpr,
             SUBSTR(u.nm1,1,15) AS nm1, SUM(x.'||field_||') AS summa
             FROM XITOG3 x, USLM u, SPUL s, S_REU_TREST t
             WHERE x.mg BETWEEN :mg_ AND :mg1_ AND x.USLM=u.USLM AND x.kul=s.id
             AND x.trest= t.trest
             GROUP BY ''ЖЭО:''||t.name_tr, SUBSTR(u.nm1,1,15)'
        USING mg_, mg1_;
   END IF;
  END IF;
  END report_charges_usl;

END rep_saldo;
/

