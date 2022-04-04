CREATE OR REPLACE PROCEDURE SCOTT.save_kwtp_day(p_rec_id NUMBER) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  insert into kmp_kwtp_day select * from KWTP_DAY t where t.kwtp_id=p_rec_id;
  commit;
END save_kwtp_day;
/

