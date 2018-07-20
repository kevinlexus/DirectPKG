CREATE OR REPLACE FORCE VIEW SCOTT.V_PERIOD_REPORTS AS
SELECT r.id, r.cd, mg, dat, dat AS cdat, p.signed
    FROM PERIOD_REPORTS p, reports r WHERE p.signed = 1
    and r.id=p.id
    ORDER BY dat DESC;

