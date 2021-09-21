CREATE OR REPLACE PACKAGE BODY SCOTT.c_charges IS

  TYPE rec_kpr IS RECORD(
    kpr    kart.kpr%TYPE,
    kpr_ot kart.kpr_ot%TYPE,
    kpr_wr kart.kpr_ot%TYPE);

  FUNCTION get_upd_tab RETURN tab_rec_states
    PARALLEL_ENABLE
    PIPELINED IS
  BEGIN
    --������� ���� �� ������������ (�� ����� ����������) 29.04.2011
    FOR element IN 1 .. c_charges.tb_rec_states.count LOOP
  --    PIPE ROW(c_charges.tb_rec_states(element));
  null;
    END LOOP;
    RETURN;
  END;

  FUNCTION gen_charges_sch(lsk_ VARCHAR2,
                           usl_ IN usl.usl%TYPE,
                           var_ IN NUMBER,
                           cnt_ IN NUMBER) RETURN NUMBER IS
    --  PRAGMA AUTONOMOUS_TRANSACTION;
    cnt2_     NUMBER;
    sum_chrg_ NUMBER;
    cursor c is
    --��� �������� ������
    SELECT u.cd, u.usl_p, u.usl_empt
      FROM usl u WHERE u.usl = usl_;
    rec_usl c%ROWTYPE;
    --��� �������������
    cursor c2 is
    SELECT u.cd, u2.cd as cd2, u3.cd as cd3
      FROM usl u, usl u2, usl u3 WHERE u.cd = '�������'
       and u.usl_p=u2.usl(+) and u.usl_empt=u3.usl(+)
      ;
    rec_usl2 c2%ROWTYPE;

  BEGIN
    open c;
    loop
      fetch c into rec_usl;
      exit when c%notfound;

    end loop;
    close c;

    open c2;
    loop
      fetch c2 into rec_usl2;
      exit when c2%notfound;

    end loop;
    close c2;

    IF var_ = 0 THEN
    --������ ������ ������� ��������� ��������
      IF rec_usl.cd = '�.����' THEN
        --��������� ��������� �� �.���� (����� � ��������)
        SELECT k.phw
        INTO   cnt2_
        FROM   kart k
        WHERE  k.lsk = lpad(lsk_, 8, '0');
      ELSIF rec_usl.cd = '�.����' THEN
        --��������� ��������� �� �.���� (����� � ��������)
        SELECT k.pgw
        INTO   cnt2_
        FROM   kart k
        WHERE  k.lsk = lpad(lsk_, 8, '0');
      ELSIF rec_usl.cd = '��.�����.2' THEN
        --��������� ��������� �� ��.��. (����� � ��������)
        SELECT k.pel
        INTO   cnt2_
        FROM   kart k
        WHERE  k.lsk = lpad(lsk_, 8, '0');
      END IF;
      RETURN cnt2_;
    ELSE
      --���������� ������� ��������� �������� � ��������� ����������

      --���������� �� ����� �����
      cnt2_ := gen_charges(lpad(lsk_, 8, '0'),
                           lpad(lsk_, 8, '0'),
                           NULL,
                           NULL,
                           0,
                           0);
      IF rec_usl.cd IN ('�.����', '�.����') THEN
        SELECT nvl(SUM(summa), 0)
        INTO   sum_chrg_
        FROM   (SELECT summa
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = usl_
                 AND    c.type = 1
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = usl_
                 AND    c.type = 2
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = usl_
                 AND    c.type = 4
                 --����� �.�.
                 UNION ALL
                 SELECT summa
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_p
                 AND    c.type = 1
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_p
                 AND    c.type = 2
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_p
                 AND    c.type = 4
                 --��� �����������
                 UNION ALL
                 SELECT summa
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_empt
                 AND    c.type = 1
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_empt
                 AND    c.type = 2
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_empt
                 AND    c.type = 4
                 --�������.
                 UNION ALL
                 SELECT summa
                 FROM   c_charge c, usl u
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl=u.usl
                 and    u.cd in (rec_usl2.cd, rec_usl2.cd2, rec_usl2.cd3)
                 AND    c.type = 1
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c, usl u
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl=u.usl
                 and    u.cd in (rec_usl2.cd, rec_usl2.cd2, rec_usl2.cd3)
                 AND    c.type = 2
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c, usl u
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl=u.usl
                 and    u.cd in (rec_usl2.cd, rec_usl2.cd2, rec_usl2.cd3)
                 AND    c.type = 4);
      ELSIF rec_usl.cd IN ('��.�����.2') THEN
        --���������� ����� ����� �������, �������
        SELECT nvl(SUM(summa), 0)
        INTO   sum_chrg_
        FROM   (SELECT summa
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = usl_
                 AND    c.type = 1
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = usl_
                 AND    c.type = 2
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = usl_
                 AND    c.type = 4
                 --����� �.�.
                 UNION ALL
                 SELECT summa
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_p
                 AND    c.type = 1
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_p
                 AND    c.type = 2
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_p
                 AND    c.type = 4);
      END IF;

      IF rec_usl.cd IN ('�.����') THEN
        --��������� ��������� �� �.���� (����� � ��������)
        UPDATE kart k SET k.phw = cnt_ WHERE k.lsk = lpad(lsk_, 8, '0');
      ELSIF rec_usl.cd IN ('�.����') THEN
        --��������� ��������� �� �.���� (����� � ��������)
        UPDATE kart k SET k.pgw = cnt_ WHERE k.lsk = lpad(lsk_, 8, '0');
      ELSIF rec_usl.cd IN ('��.�����.2') THEN
        --��������� ��������� �� ��.��. (����� � ��������)
        UPDATE kart k SET k.pel = cnt_ WHERE k.lsk = lpad(lsk_, 8, '0');
      END IF;

      cnt2_ := gen_charges(lpad(lsk_, 8, '0'),
                           lpad(lsk_, 8, '0'),
                           NULL,
                           NULL,
                           0,
                           0);

      IF rec_usl.cd IN ('�.����', '�.����') THEN
        --���������� ����� ����� �����, �������
        SELECT nvl(SUM(summa), 0) - sum_chrg_
        INTO   sum_chrg_
        FROM   (SELECT summa
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = usl_
                 AND    c.type = 1
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = usl_
                 AND    c.type = 2
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = usl_
                 AND    c.type = 4
                 --����� �.�.
                 UNION ALL
                 SELECT summa
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_p
                 AND    c.type = 1
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_p
                 AND    c.type = 2
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_p
                 AND    c.type = 4
                 --��� �����������
                 UNION ALL
                 SELECT summa
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_empt
                 AND    c.type = 1
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_empt
                 AND    c.type = 2
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_empt
                 AND    c.type = 4
                 --�������.
                 UNION ALL
                 SELECT c.summa
                 FROM   c_charge c, usl u
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl=u.usl
                 and    u.cd in (rec_usl2.cd, rec_usl2.cd2, rec_usl2.cd3)
                 AND    c.type = 1
                 UNION ALL
                 SELECT c.summa * -1
                 FROM   c_charge c, usl u
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl=u.usl
                 and    u.cd in (rec_usl2.cd, rec_usl2.cd2, rec_usl2.cd3)
                 AND    c.type = 2
                 UNION ALL
                 SELECT c.summa * -1
                 FROM   c_charge c, usl u
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl=u.usl
                 and    u.cd in (rec_usl2.cd, rec_usl2.cd2, rec_usl2.cd3)
                 AND    c.type = 4);

/*                 delete from check1;
                 insert into check1(id, summa)
                 SELECT 1, c.summa
                 FROM   c_charge c, usl u
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl=u.usl
                 and    u.cd in (rec_usl2.cd, rec_usl2.usl_p, rec_usl2.usl_empt)
                 AND    c.type = 1
                 UNION ALL
                 SELECT 2, c.summa * -1
                 FROM   c_charge c, usl u
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl=u.usl
                 and    u.cd in (rec_usl2.cd, rec_usl2.usl_p, rec_usl2.usl_empt)
                 AND    c.type = 2
                 UNION ALL
                 SELECT 4, c.summa * -1
                 FROM   c_charge c, usl u
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl=u.usl
                 and    u.cd in (rec_usl2.cd, rec_usl2.usl_p, rec_usl2.usl_empt)
                 AND    c.type = 4;*/

      ELSIF rec_usl.cd IN ('��.�����.2') THEN
        --���������� ����� ����� �������, �������
        SELECT nvl(SUM(summa), 0) - sum_chrg_
        INTO   sum_chrg_
        FROM   (SELECT summa
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = usl_
                 AND    c.type = 1
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = usl_
                 AND    c.type = 2
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = usl_
                 AND    c.type = 4
                 --����� �.�.
                 UNION ALL
                 SELECT summa
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_p
                 AND    c.type = 1
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_p
                 AND    c.type = 2
                 UNION ALL
                 SELECT summa * -1
                 FROM   c_charge c
                 WHERE  c.lsk = lpad(lsk_, 8, '0')
                 AND    c.usl = rec_usl.usl_p
                 AND    c.type = 4);
      END IF;
      --   rollback;
      RETURN sum_chrg_;
    END IF;
  END;

  PROCEDURE gen_chrg_all(p_lvl     IN NUMBER,
                         house_id_ IN c_houses.id%TYPE,
                         p_reu     IN kart.reu%TYPE,
                         p_trest   IN kart.reu%TYPE) IS
    l_cnt NUMBER;
/*    i number;
    l_job number;
    l_job1 number;
    l_job2 number;
    l_job3 number;
    l_start_row number;
    l_end_row number; */
  BEGIN
    --���������� ���������� ����������
    IF nvl(p_lvl, 0) = 0 THEN
      --�� ������
      --��� ������� � ������������� ��������, �� ������� ��������...

      l_cnt := c_charges.gen_charges(NULL, NULL, NULL, NULL, 2, 1);


    --�������� �� JOB-��
  --��������� 3 JOB-a!
  --�������� ������ ����� �� 3 �����
/*  i:=1;
  --������� JOB
  while i <= 3
  loop
    if i=1 then
      l_start_row:=1;
      l_end_row:=9999;
    elsif i=2 then
      l_start_row:=10000;
      l_end_row:=19999;
    elsif i=3 then
      l_start_row:=20000;
      l_end_row:=999999;
    end if;

    dbms_job.submit(job => l_job,
      what => '
      declare
       l_cnt number;
      begin
       for c in (select * from
         (select k.lsk, rownum as rn from kart k
        where k.psch not in (8,9) order by k.lsk) a
            where a.rn between '||l_start_row||' and '||l_end_row||')
         loop

         l_cnt := c_charges.gen_charges(c.lsk, c.lsk, NULL, NULL, 1, 0);

         end loop;
      exception when others
        then
          logger.log_(null, ''������ �� JOB-����������: ''||SQLERRM);
          raise;

      end;'
      );
    COMMIT;
    dbms_job.broken(job => l_job, broken => TRUE);

    if i=1 then
      l_job1:=l_job;
    elsif i=2 then
      l_job2:=l_job;
    elsif i=3 then
      l_job3:=l_job;
    end if;
    i:=i+1;
  end loop;


  --������� ���������� JOB
  while true
  loop
    for c in (select t.*
     from user_jobs t where t.job in (l_job1, l_job2, l_job3)
      and t.FAILURES <> 0)
    loop
         --������� Job-�
         for c2 in (select t.*
         from user_jobs t where t.job in (l_job1, l_job2, l_job3)
          )
        loop
          DBMS_JOB.REMOVE(c2.job);
          COMMIT;
        end loop;
        Raise_application_error(-20000, '������ #1 �� ����� ���������� (��.Log)!');
    end loop;

    select nvl(count(*),0) into l_cnt
     from dba_jobs_running t where t.job in (l_job1, l_job2, l_job3);
    if l_cnt = 0 then
      exit;
    end if;
    dbms_lock.sleep(2);
  end loop;
  */

    ELSIF nvl(p_lvl, 0) = 1 THEN
      --�� �����
      --���������� ����������� - ������
      FOR c IN (SELECT * FROM c_houses) LOOP
        l_cnt := c_charges.gen_charges(NULL, NULL, c.id, NULL, 2, 1);
      END LOOP;
    ELSIF nvl(p_lvl, 0) = 2 THEN
      --�� ��
      --���������� ����������� - ������
      FOR c IN (SELECT distinct t.id
                  FROM c_houses t, kart k
                 WHERE EXISTS (SELECT *
                          FROM s_reu_trest s
                         WHERE s.reu = k.reu
                           AND s.trest = p_trest)
                           and t.id=k.house_id) LOOP
        l_cnt := c_charges.gen_charges(NULL, NULL, c.id, NULL, 2, 1);
      END LOOP;
    ELSIF nvl(p_lvl, 0) = 3 THEN
      --�� ����
      --���, ������������ ����� ���� ���!!! ��������. ��� 01.02.2015
--      FOR c IN (SELECT * FROM c_houses t WHERE t.reu = p_reu) LOOP
      l_cnt := c_charges.gen_charges(NULL, NULL, house_id_, NULL, 1, 1);
--      END LOOP;
    END IF;
  END;

  -- ������� ��� Java
  procedure gen_charges(house_id_ c_houses.id%TYPE) IS
  l_ret number;
  begin
    l_ret:=gen_charges(lsk_      => null,
                lsk_end_  => null,
                house_id_ => house_id_,
                p_vvod    => null,
                iscommit_ => 1,
                sendmsg_  => 0);

  end;

-- JAVA �������
  procedure gen_charges(lsk_      VARCHAR2,
                       lsk_end_  VARCHAR2,
                       house_id_ c_houses.id%TYPE,
                       p_vvod c_vvod.id%type,
                       iscommit_ NUMBER,
                       sendmsg_  NUMBER) IS
  a number;
  begin
  a := c_charges.gen_charges(lsk_ => lsk_,
                                   lsk_end_ => lsk_end_,
                                   house_id_ => house_id_,
                                   p_vvod => p_vvod,
                                   iscommit_ => iscommit_,
                                   sendmsg_ => sendmsg_);
  end;

  FUNCTION gen_charges(lsk_      VARCHAR2,
                       lsk_end_  VARCHAR2,
                       house_id_ c_houses.id%TYPE,
                       p_vvod c_vvod.id%type,
                       iscommit_ NUMBER,
                       sendmsg_  NUMBER) RETURN NUMBER IS

    --��������� ��� �������� �������
    t_nabor tab_nabor;

    CURSOR cur_krt IS
      SELECT k.k_lsk_id, k.lsk, k.house_id, k.reu, k.psch, nvl(k.sch_el, 0) AS sch_el, k.schel_dt, k.schel_end, nvl(k.opl,
                  0) AS opl, nvl(k.mhw, 0) AS mhw, nvl(k.mgw, 0) AS mgw, nvl(k.mel,
                  0) AS mel, k.kran, k.kran1, k.kan_sch, k.el, k.el1, k.subs_cor, k.subs_cur, k.subs_inf, k.eksub1, k.eksub2, k.sgku, k.doppl, k.status, decode(k.komn,
                     NULL,
                     2,
                     0,
                     2,
                     k.komn) AS komnat, p.subs_ob, p.kan_sch AS kan_sch2, p.sv_soc AS sv_soc, p.org_var AS org_var, nvl(k.kfg,
                  0) AS kfg, nvl(p.corr_lg, 0) AS corr_lg, p.period, u.cd as tp, k.parent_lsk
      FROM   kart k, params p, u_list u
      WHERE  k.fk_tp=u.id and k.lsk BETWEEN '' || lsk_ || '' AND '' || lsk_end_ || '';

    CURSOR cur_krt2 IS
      SELECT k.k_lsk_id, k.lsk, k.house_id, k.reu, k.psch, nvl(k.sch_el, 0) AS sch_el, k.schel_dt, k.schel_end, nvl(k.opl,
                  0) AS opl, nvl(k.mhw, 0) AS mhw, nvl(k.mgw, 0) AS mgw, nvl(k.mel,
                  0) AS mel, k.kran, k.kran1, k.kan_sch, k.el, k.el1, k.subs_cor, k.subs_cur, k.subs_inf, k.eksub1, k.eksub2, k.sgku, k.doppl, k.status, decode(k.komn,
                     NULL,
                     2,
                     0,
                     2,
                     k.komn) AS komnat, p.subs_ob, p.kan_sch AS kan_sch2, p.sv_soc AS sv_soc, p.org_var AS org_var, nvl(k.kfg,
                  0) AS kfg, nvl(p.corr_lg, 0) AS corr_lg, p.period, u.cd as tp, k.parent_lsk
      FROM   kart k, params p, u_list u
      WHERE  k.fk_tp=u.id and k.lsk LIKE lsk_ || '' || '%';


    CURSOR cur_krt3 IS
      SELECT k.k_lsk_id, k.lsk, k.house_id, k.reu, k.psch, nvl(k.sch_el, 0) AS sch_el, k.schel_dt, k.schel_end, nvl(k.opl,
                  0) AS opl, nvl(k.mhw, 0) AS mhw, nvl(k.mgw, 0) AS mgw, nvl(k.mel,
                  0) AS mel, k.kran, k.kran1, k.kan_sch, k.el, k.el1, k.subs_cor, k.subs_cur, k.subs_inf, k.eksub1, k.eksub2, k.sgku, k.doppl, k.status, decode(k.komn,
                     NULL,
                     2,
                     0,
                     2,
                     k.komn) AS komnat, p.subs_ob, p.kan_sch AS kan_sch2, p.sv_soc AS sv_soc, p.org_var AS org_var, nvl(k.kfg,
                  0) AS kfg, nvl(p.corr_lg, 0) AS corr_lg, p.period, u.cd as tp, k.parent_lsk
      FROM   kart k, params p, u_list u
      WHERE  k.fk_tp=u.id and k.house_id = house_id_;


    CURSOR cur_krt4 IS
      SELECT k.k_lsk_id, k.lsk, k.house_id, k.reu, k.psch, nvl(k.sch_el, 0) AS sch_el, k.schel_dt, k.schel_end, nvl(k.opl,
                  0) AS opl, nvl(k.mhw, 0) AS mhw, nvl(k.mgw, 0) AS mgw, nvl(k.mel,
                  0) AS mel, k.kran, k.kran1, k.kan_sch, k.el, k.el1, k.subs_cor, k.subs_cur, k.subs_inf, k.eksub1, k.eksub2, k.sgku, k.doppl, k.status, decode(k.komn,
                     NULL,
                     2,
                     0,
                     2,
                     k.komn) AS komnat, p.subs_ob, p.kan_sch AS kan_sch2, p.sv_soc AS sv_soc, p.org_var AS org_var, nvl(k.kfg,
                  0) AS kfg, nvl(p.corr_lg, 0) AS corr_lg, p.period, u.cd as tp, k.parent_lsk
      FROM   kart k, params p, u_list u
       where k.fk_tp=u.id;

    CURSOR cur_krt5 IS
      SELECT k.k_lsk_id, k.lsk, k.house_id, k.reu, k.psch, nvl(k.sch_el, 0) AS sch_el, k.schel_dt, k.schel_end, nvl(k.opl,
                  0) AS opl, nvl(k.mhw, 0) AS mhw, nvl(k.mgw, 0) AS mgw, nvl(k.mel,
                  0) AS mel, k.kran, k.kran1, k.kan_sch, k.el, k.el1, k.subs_cor, k.subs_cur, k.subs_inf, k.eksub1, k.eksub2, k.sgku, k.doppl, k.status, decode(k.komn,
                     NULL,
                     2,
                     0,
                     2,
                     k.komn) AS komnat, p.subs_ob, p.kan_sch AS kan_sch2, p.sv_soc AS sv_soc, p.org_var AS org_var, nvl(k.kfg,
                  0) AS kfg, nvl(p.corr_lg, 0) AS corr_lg, p.period, u.cd as tp, k.parent_lsk
      FROM   kart k, params p, u_list u
      where k.fk_tp=u.id and
      exists (select * from nabor n where k.lsk=n.lsk and n.fk_vvod=p_vvod); --����� ������ ������������ ��������� t_nabor, ��� ��� �� ����������!

    rec_krt cur_krt%ROWTYPE;

    --������ ��� ������� �� ������� ����� (� ������ �����)
    --������ �� ��������, �� ��� �����
    CURSOR cur_nabor IS
      SELECT n.usl, n.fk_calc_tp, n.usl_p, n.usl_p AS usl_h, --���.27.12.2010
             nvl(decode(n.sptarn,
                         0,
                         nvl(s.koeff, 1) * nvl(n.koeff, 0),
                         1,
                         nvl(n.norm, 0),
                         2,
                         nvl(n.koeff, 0) * nvl(n.norm, 0),
                         3,
                         nvl(n.koeff, 0) * nvl(n.norm, 0)),
                  0) AS chrg1, --������� ���������� �� ��� �����, chrg1
             n.fk_tarif, nvl(c.chrg2, 0) AS chrg2, --������� ���������� ����� ���.�����, chrg2
             nvl(m.kub, 0) AS kub, nvl(m.use_sch, 0) AS use_sch, m.dist_tp, nvl(n.vol,0) AS vol,
             nvl(n.vol_add, 0) AS vol_add, n.usl_empt,
             n.linked_usl,
             n.parent_usl, u.cd as usl_cd
      FROM   (SELECT a.lsk, a.usl, a.koeff, a.norm, a.fk_vvod, a.vol, a.vol_add, a.fk_tarif,
               b.sptarn, b.usl_order, r.usl as usl_p, b.usl_empt, b.fk_calc_tp, a.kf_kpr, a.nrm_kpr,
               b.linked_usl, b.parent_usl
               FROM table(t_nabor) a, usl b,
               (select d.usl from table(t_nabor) d where d.lsk=rec_krt.lsk) r
               WHERE  a.usl = b.usl
               and b.usl_p=r.usl(+)
               AND    nvl(b.usl_norm,0) = 0) n, (SELECT m.lsk, m.usl, decode(k.sptarn,
                              0,
                              m.koeff,
                              1,
                              nvl(m.norm,
                                  0),
                              2,
                              nvl(m.koeff,
                                  0) *
                              nvl(m.norm,
                                  0),
                              3,
                              nvl(m.koeff,
                                  0) *
                              nvl(m.norm,
                                  0)) AS chrg2
               FROM   table(t_nabor) m, usl k
               WHERE  m.usl = k.usl
               AND    m.lsk = rec_krt.lsk
               AND    nvl(k.usl_norm,0) = 1) c, c_vvod m, (SELECT sk.id, su.usl, sk.koeff
               FROM   spr_koeff sk, spr_koeff_usl su
               WHERE  su.fk_spr_koeff =
                      sk.id) s, usl u
      WHERE  n.lsk = rec_krt.lsk
      AND    n.usl = u.usl
      AND    n.lsk = c.lsk(+)
      AND    n.usl_p = c.usl(+)
      AND    n.usl = s.usl(+)
      AND    s.id(+) = rec_krt.kfg
      AND    n.usl = m.usl(+)
      AND    n.fk_vvod = m.id(+)
      ORDER  BY n.usl_order;
    rec_nabor cur_nabor%ROWTYPE;

    cursor cur_nabor2 (p_usl in usl.usl%type) is
    select * from table(t_nabor) n
      where n.lsk=rec_krt.lsk
        and n.usl=p_usl;
    rec_nabor2 cur_nabor2%ROWTYPE;

    --������
    usl_ VARCHAR2(3);
    --���������
    CURSOR cur_params IS
      SELECT param, message, ver, period, agent_uptime, mess_hint, period_pl, subs_ob, id, period_debits, dt_otop1, dt_otop2, part, cnt_sch, kan_sch, sv_soc, state_base_, org_var, splash, gen_exp_lst, kart_ed1, auto_sign, find_street, penya_month, corr_lg, recharge_bill, show_exp_pay, bill_pen, penya_var, nvl(is_fullmonth,
                  0) AS is_fullmonth, wait_ver
      FROM   params;
    rec_params cur_params%ROWTYPE;

    --���-�� ����������� (� ������ ��.�����. � ��.������.)
    kpr_ NUMBER;
    -- ���-�� ����������� (��� ��������) - ������ !
    --kpr_price_ NUMBER;

    l_usl_round usl.usl%type;
    --������ ��� ������� �� ���������� ����� (��� ����� �����)
    CURSOR cur_wo_peop(p_usl in usl.usl%type  --���� �� ��������� p_usl, �������� usl_
      ) IS
      SELECT nvl(s.koeff, 1) * nvl(n.koeff, 0) AS tarkoef, nvl(n.norm, 0) AS tarnorm,
                    CASE WHEN rec_krt.status = 9 THEN 0 --���������� - ���� = 0
                           ELSE
                    round(nvl(s.koeff, 1) * nvl(n.koeff, 0) *
                     decode(u.sptarn, 3, nvl(n.norm, 0), 1) * --�������� ��� ��.� ������������
                     nvl(e2.summa, e.summa),
                     2)
                   END AS cena,
                   CASE WHEN rec_krt.status = 9 THEN 0 --���������� - ���� = 0
                           ELSE
                    round(nvl(s.koeff, 1) * nvl(n.koeff, 0) *
                     decode(u.sptarn, 3, nvl(n.norm, 0), 1) * --�������� ��� ��.� ��� ����������� (���� ���� ��������)
                     nvl(e2.summa3, e.summa3),
                     2)
                   END AS cena_for_empty,
                   u.usl_subs, m.dist_tp, nvl(m.kub, 0) AS kub, n.fk_vvod
      FROM   kart k, table(t_nabor) n, c_vvod m, prices e, prices e2, params w, usl u, /* prices e1, */ (SELECT sk.id, su.usl, sk.koeff
               FROM   spr_koeff sk, spr_koeff_usl su
               WHERE  su.fk_spr_koeff =
                      sk.id) s
      WHERE  k.lsk = '' || rec_krt.lsk || ''
      AND    k.lsk = n.lsk
      AND    n.usl = e.usl(+) --������� ��������
      AND    n.usl = e2.usl(+) --�������� �����������������
      AND    n.org = e2.fk_org(+)
      and    n.fk_vvod=m.id(+)
      AND    e.fk_org IS NULL
      AND    n.usl = e2.usl(+) --�������� ��
      AND    nvl(p_usl, usl_) = s.usl(+)
      AND    k.kfg = s.id(+)
      AND    n.usl = u.usl
      AND    n.usl = nvl(p_usl, usl_);
    rec_wo_peop cur_wo_peop%ROWTYPE;
    rec_wo_peop2 cur_wo_peop%ROWTYPE;

    --������ ��� ������� �� ���������� ����� (��� ����� �����) ��� ������� ����! ���.18.01.2018
    CURSOR cur_wo_peop_gw(p_usl in usl.usl%type) IS
      SELECT nvl(n.koeff, 0) AS tarkoef, nvl(n.norm, 0) AS tarnorm,
                    CASE WHEN rec_krt.status = 9 THEN 0 --���������� - ���� = 0
                           ELSE
                    round(nvl(n.koeff, 0) *
                     decode(u.sptarn, 3, nvl(n.norm, 0), 1) * --�������� ��� ��.� ������������
                     nvl(e2.summa, e.summa),
                     2)
                   END AS cena,
                   CASE WHEN rec_krt.status = 9 THEN 0 --���������� - ���� = 0
                           ELSE
                    round(nvl(n2.koeff, 0) *
                     decode(u.sptarn, 3, nvl(n2.norm, 0), 1) * --�������� ��� ��. 0 ����������� (���� ���� ��������)
                     nvl(e2.summa3, e.summa3),
                     2)
                   END AS cena_for_empty
      FROM   kart k join nabor n on k.lsk = '' || rec_krt.lsk || '' and k.lsk=n.lsk and n.usl=nvl(p_usl, usl_)
             join usl u on n.usl=u.usl
             left join prices e on n.usl=e.usl and e.fk_org is null  -- ������� ��������
             left join prices e2 on n.usl=e2.usl and n.org=e2.fk_org -- �������� �����������������
             left join nabor n2 on k.lsk=n2.lsk and u.usl_empt=n2.usl; -- ������ 0 ������.
    rec_wo_peop_gw cur_wo_peop_gw%ROWTYPE;

    CURSOR cur_memof IS
      SELECT * FROM load_memof;
    rec_memof cur_memof%ROWTYPE;

    --������ ��� ������� ����������� � ����������, � ��� �� �� ����� � �����
    cursor cur_charge_prep(p_usl in usl.usl%type,  --���� �� ��������� p_usl, �������� usl_
                           p_lsk in kart.lsk%type --�� ���������� �.�.
                          )  is
    select a.vol, a.vol_nrm, a.vol_sv_nrm,
      a.empty, a.sch, a.kpr, a.kprz, a.kpro, a.opl,
      sum(a.vol) over (partition by 0) as sum_vol,
      a.usl_cd from
      (select sum(t.vol) as vol,
        sum(t.vol_nrm) as vol_nrm,
        sum(t.vol_sv_nrm) as vol_sv_nrm,
        decode(nvl(t.kpr,0),0,1,0) as empty,
        sum(t.kpr) as kpr,
        sum(t.kprz) as kprz,
        sum(t.kpro) as kpro,
        sum(t.opl) as opl,
        t.sch, u.cd as usl_cd
        from c_charge_prep t, usl u
        where t.lsk=coalesce(p_lsk, rec_krt.lsk) and t.usl=nvl(p_usl, usl_) and t.tp=1
        and t.usl=u.usl
        group by decode(nvl(t.kpr,0),0,1,0),t.sch, u.cd) a
        order by a.empty, a.sch; --order by - �� ������, ������ �� ������!
    --���-�� �����������, �� ����� �� ��������
    cursor cur_charge_prep_kpr is
    select
        sum(t.kpr) as kpr,
        sum(t.kprz) as kprz,
        sum(t.kpro) as kpro
        from c_charge_prep t
        where t.lsk=rec_krt.lsk
        and t.usl=usl_ and t.tp=1;

    --������ ��� ������� ����������� � ����������, � ��� �� �� ����� � �����
    --�� ������ ����� p_list_cd_usl - ������ �����, ����� �������
    --�������� '�.����,�.����'
    --regexp_instr(l_str_tp, '8[,]{1,}',1) <> 0 (regexp ���� ������ ����� '8' � ������, � �������������� �������
    cursor cur_charge_prep_usl_cd(p_list_usl_cd in varchar2) is
    select a.vol, a.sch, a.vol_nrm, a.vol_sv_nrm,
      a.empty, --a.kpr, a.kprz, a.kpro, ������ ����� �������� ���-�� ������, ��� ��� ��� ����� ������������ ������!
      sum(a.vol) over (partition by 0) as sum_vol from
      (select sum(t.vol) as vol,
        sum(t.vol_nrm) as vol_nrm,
        sum(t.vol_sv_nrm) as vol_sv_nrm,
        decode(nvl(t.kpr,0),0,1,0) as empty,
        t.sch
        from c_charge_prep t, usl u
        where t.lsk=rec_krt.lsk and t.usl=u.usl
        and regexp_instr(p_list_usl_cd, '(,|^)'||u.cd||'(,|$){1,}') <> 0
        and t.tp=1
        group by decode(nvl(t.kpr,0),0,1,0),t.sch) a
        order by a.empty, a.sch; --order by - �� ������, ������ �� ������! (������ �� ������ ��, ����� ������)

    -- ������ ��� ������ ���������� �� k_lsk (�� ���� ����������� � ���� ��), �������� ��� ������������� ��� ��� ������ (���.28.09.2018)
    cursor cur_charge_prep_usl_cd_by_klsk(p_list_usl_cd in varchar2) is
    select a.vol, a.sch, a.vol_nrm, a.vol_sv_nrm,
      a.empty, --a.kpr, a.kprz, a.kpro, ������ ����� �������� ���-�� ������, ��� ��� ��� ����� ������������ ������!
      sum(a.vol) over (partition by 0) as sum_vol from
      (select sum(t.vol) as vol,
        sum(t.vol_nrm) as vol_nrm,
        sum(t.vol_sv_nrm) as vol_sv_nrm,
        decode(nvl(t.kpr,0),0,1,0) as empty,
        t.sch
        from kart k, c_charge_prep t, usl u
        where k.lsk=t.lsk and k.k_lsk_id=rec_krt.k_lsk_id and t.usl=u.usl
        and regexp_instr(p_list_usl_cd, '(,|^)'||u.cd||'(,|$){1,}') <> 0
        and t.tp=1
        group by decode(nvl(t.kpr,0),0,1,0),t.sch) a
        order by a.empty, a.sch; --order by - �� ������, ������ �� ������! (������ �� ������ ��, ����� ������)

    --������� ��� ������������� �� �����, �� ������
    cursor cur_vvod_tp(p_usl_cd in varchar2) is
      select d.dist_tp from c_vvod d, nabor n, usl u
        where d.id=n.fk_vvod and u.cd=p_usl_cd
        and n.lsk=rec_krt.lsk and n.usl=u.usl;

    --������� ��� ������������� �� �����, �� ������
    cursor cur_vvod_tp2(p_usl_cd in varchar2) is
      select d.dist_tp from c_vvod d, usl u
        where d.usl=u.usl and u.cd=p_usl_cd and d.house_id=rec_krt.house_id;

    --���-�� ������. ��� ������� ��������,
    --����� �� ���������,
    --����� �� ��������,
    --���-�� ������. �� ����� (�����)
    --���-�� ������. �� ��. (�����)
    cursor cur_prep is
    select sum(decode(t.tp, 2, t.kpr, 0)) as nrm_kpr,
           sum(case when t.tp=1 then t.vol
                    else 0
                    end) as vol, --����� �����
           sum(case when t.tp=1 and t.sch=0 then t.vol
                    else 0
                    end) as nrm_vol, --����������� �����
           sum(case when t.tp=1 and t.sch=1 then t.vol
                    else 0
                    end) as sch_vol, --���� �� ���������
           sum(case when t.tp=1 then t.kpr
                    else 0 end) as kpr, --����� ���-�� ������
           sum(case when t.tp=1 and t.sch=0 then t.kpr
                    else 0
                    end) as kf_kpr, --���-�� ������ �� ���������
           sum(case when t.tp=1 and t.sch=1 then t.kpr
                    else 0
                    end) as kf_kpr_sch, --���-�� ������ �� ��������
           sum(t.kpr2) as kpr2 --���-�� ������. � ������ �����, �.�.,�.�. � �.�. (��� ������� ������...) 07.08.2015
        from c_charge_prep t
        where t.lsk=rec_krt.lsk and t.usl=usl_ and t.tp in (1,2);
    rec_prep cur_prep%ROWTYPE;

    -- ���������� �� ������ � ���� ����� p_tp_sch - ������� �������� 1-�� 0-���
    -- ��� ������ �� �����.�����
    cursor cur_chrg(p_usl in usl.usl%type, p_tp_sch in number) is
      select sum(t.summa) as summa from c_charge t, usl u
         where t.lsk=rec_krt.lsk and nvl(t.sch,0)=p_tp_sch
         and t.usl=u.usl
         and t.type=1
         and exists (select * from usl u2 -- ������� ��� ���������
             where u2.usl=p_usl and u2.uslm=u.uslm);

    -- ���������� �� ������ � ���� ����� p_tp_sch - ������� �������� 1-�� 0-���.
    -- ��� ������ �� �����.�����
    -- �� klsk, ��� ��� ������
    cursor cur_chrg_by_klsk(p_usl in usl.usl%type, p_tp_sch in number) is
      select sum(t.summa) as summa from kart k, c_charge t, usl u
         where k.lsk=t.lsk and k.k_lsk_id=rec_krt.k_lsk_id and nvl(t.sch,0)=p_tp_sch
         and t.usl=u.usl
         and t.type=1
         and exists (select * from usl u2 -- ������� ��� ���������
             where u2.usl=p_usl and u2.uslm=u.uslm);
    rec_chrg cur_chrg%ROWTYPE;

    -- ������� ������� ������ �� �������� / ��������� � �������, �� ������
    -- ������ ������������ ��� ���������� ����� ���
    -- ���� 0 �����, �� �������=0 ��������=0
    cursor cur_proc_sch(p_usl in usl.usl%type) is
      select case when nvl(a.vol,0) <> 0 then a.vol_sch/a.vol else 0 end as proc_sch,
             case when nvl(a.vol,0) <> 0 then a.vol_nrm/a.vol else 0 end as proc_nrm
      from (
      select sum(decode(t.sch, 1, t.test_opl)) as vol_sch,
             sum(decode(t.sch, 0, t.test_opl)) as vol_nrm,
             sum(t.test_opl) as vol
       from c_charge t, usl u where t.lsk=rec_krt.lsk and t.type=1
           and t.usl=u.usl
           and exists (select * from usl u2 -- ������� ��� ���������
               where u2.usl=p_usl and u2.uslm=u.uslm)
               ) a;
    -- ������� ������� ������ �� �������� / ��������� � �������, �� ������
    -- ������ ������������ ��� ���������� ����� ���
    -- ���� 0 �����, �� �������=0 ��������=0
    cursor cur_proc_sch_by_klsk(p_usl in usl.usl%type) is
      select case when nvl(a.vol,0) <> 0 then a.vol_sch/a.vol else 0 end as proc_sch,
             case when nvl(a.vol,0) <> 0 then a.vol_nrm/a.vol else 0 end as proc_nrm
      from (
      select sum(decode(t.sch, 1, t.test_opl)) as vol_sch,
             sum(decode(t.sch, 0, t.test_opl)) as vol_nrm,
             sum(t.test_opl) as vol
       from kart k, c_charge t, usl u where k.lsk=t.lsk and k.k_lsk_id=rec_krt.k_lsk_id and t.type=1
           and t.usl=u.usl
           and exists (select * from usl u2 -- ������� ��� ���������
               where u2.usl=p_usl and u2.uslm=u.uslm)
               ) a;

--    rec_sch cur_sch%ROWTYPE;
    --���.����� �� ������������
    socn_ NUMBER;
    --����� �������, ��� �������
    opl_ NUMBER;
    --����� �������, ��� �������, ���������
    opl_save_ NUMBER;
    --������� �� ������������, ��� �������
    opl_man_ NUMBER;
    --������� ����� ���.�����
    opl_sv_ NUMBER;

    --������ �� ������ (��� �������) (��������, ��� �����)
    hv_kub_ NUMBER;
    --������ �� ������ (��� �������) (��������, ��� �����)
    gv_kub_ NUMBER;

    --����� ������ �� �������� ����
    hv_ NUMBER;

    socn_kub_ NUMBER;
    --������ �������� ���� �� ������������, ��� �������
    hv_man_ NUMBER;
    --�.�. ����� ���.�����
    hv_sv_ NUMBER;
    --����� ������ �� ������� ����
    gv_ NUMBER;

    --��������������
    el_ number;
    --�������������� ���� (����� �� �����)
    el_kan_ number;

    --������ ������� ���� �� ������������, ��� �������
    gv_man_ NUMBER;
    --�.�. ����� ���.�����
    gv_sv_ NUMBER;
    --����� ������ �� �������������
    kan_       NUMBER;
    saved_kan_ NUMBER;
    --������ ������������� �� ������������, ��� �������
    kan_man_ NUMBER;
    hv_kan_  NUMBER;
    gv_kan_  NUMBER;

    --�����, ����������� �� ������������ ���������� (���������� ��� ����������)
    hv_kan_nrm_ NUMBER;
    --�����, ����������� �� ���������� � �������� �����
    hv_kan_sch_ NUMBER;

    gv_kan_nrm_ NUMBER;
    gv_kan_sch_ NUMBER;
    hv_kan_add_ NUMBER;
    gv_kan_add_ NUMBER;
    --���. ����� ���.�����
    kan_sv_ NUMBER;
    --id ������������
    TYPE t_peoples IS TABLE OF NUMBER;
    t_peop_id t_peoples := t_peoples(NULL);
    --���� ���� ������ id
    exists_ NUMBER;
    --���� ������ �� ���.�����
    cena_sn_ NUMBER;

    --��� �������, �������+
    cena_ NUMBER;

    --������������� ����������, ��� �������� ����� ����������
    summa_ NUMBER;
    --������������� ����������, ��� ���������� ����������
    summaf_ NUMBER;

    --������ ������������� ��� �������������?
    sign_kub_ NUMBER;

    --���������� ��������
    sov_doh1_   NUMBER;
    koef_doh_   NUMBER;
    koef_subs_  NUMBER;
    mdd_        NUMBER;
    poprav_     NUMBER;
    sgku_1_     NUMBER;
    sum_subsid_ NUMBER;
    koeff_rasp_ NUMBER;
    koef_lg_    NUMBER;
    pl_norma_   NUMBER;
    it_izm_s_   NUMBER;
    subs_       NUMBER;
    --���������� ��� �������� ��������
    chk_subs_corr_ NUMBER;
    --����� ���������� �� �������
    sit_ NUMBER;
    --����� ���������� �� ������� � �����������
    sit_s_ NUMBER;
    --����� ���������� ��� ������
    msit_ NUMBER;
    --���-�� �������
    cnt_lsk_ NUMBER;
    --��� ������������ � �������
    cnt_10 NUMBER;
    dbid_  NUMBER;
    --� ���������� ���������� �������
    npp_ NUMBER;
    --������� ������������� ����������
    var_ NUMBER;
    --��������� �� ���������� (�������� ����)
    is_round_charge_ NUMBER;
    --������� ������� ��������� (��������, �� ��������� ��������� ���������� �� ���� (��� ���������� � ���������� ���� �� �� � �����)
    sch_ NUMBER;
    --��� ���������� ��������
    l_cena number;
    --��� ������� ��������� � �������������
    l_norm number;
    l_vol number;
    --��� ���������� ����� ������
    l_sign number;
    --��������� ����������
    l_str varchar2(128);
    -- ��� �������� �������� ������)))
    l_dummy number;

    --��� ���������� �������� ������������� c_vvod.dist_tp �� ������������ ������, ��� ������������� � ������������ �� ���
/*    l_hw_dist_tp c_vvod.dist_tp%type;
    l_gw_dist_tp c_vvod.dist_tp%type;
    l_el_dist_tp c_vvod.dist_tp%type;*/
    l_ot_dist_tp c_vvod.dist_tp%type;

    --��������� ����������
    l_kpr number;
    l_kprz number;
    l_kpro number;
    l_flag number;
    i number;
    l_tmp_usl usl.usl%type;
    l_tmp_vol number;
    -- ���� ������� ��������� �� ������ (��� ����� �����)
    l_proc_nrm number;
    -- ���������� �� Java?
    l_Java_Charge number;
    l_klsk_id number;

  PROCEDURE ins_chrg2(p_vol   IN NUMBER,   --�����
                      p_cena     IN NUMBER,--����
                      p_proc in number,     --% ����� � ������ (����. ��� ���������)
                      p_usl in usl.usl%type,
                      p_sch in c_charge.sch%type, --������� ��������
                      p_kpr in c_charge.kpr%type, --���-�� ������.
                      p_kprz in c_charge.kprz%type, --���-�� ��.�����.
                      p_kpro in c_charge.kpro%type, --���-�� ��.�����.
                      p_opl in c_charge.opl%type --�������!
                      ) IS
    summa_  number;
    summaf_ number;
    l_proc  number;
  BEGIN
  --��������� ��������� ins_chrg2
  --������ ������������ ins_chrg
    if p_proc is null then
      l_proc:=1;
    else
      l_proc:=p_proc;
    end if;
    IF p_vol <> 0 or p_kpr <> 0 THEN --��� ���� ����� ��� ���� ����������� ���. 17.10.14
      npp_ := npp_ + 1;
      --�� �������
      sit_    := sit_ + round(p_vol * p_cena * l_proc, 2);
      summaf_ := p_vol * p_cena * l_proc;
      summa_  := round(summaf_, 2);
      INSERT INTO c_charge
        (npp, lsk, usl, summa, summaf, kart_pr_id, type,
        spk_id, test_opl, test_cena, test_tarkoef,
        test_spk_koef, sch, kpr, kprz, kpro, opl)
      VALUES
        (0, rec_krt.lsk, p_usl, summa_, summaf_, NULL,
        0, NULL, p_vol, p_cena, NULL, NULL,
        p_sch, p_kpr, p_kprz, p_kpro, p_opl);
      --��� ������
      msit_   := msit_ + round(p_vol * p_cena * l_proc, 2);
      summaf_ := p_vol * p_cena * l_proc;
      summa_  := round(summaf_, 2);
      INSERT INTO c_charge
        (npp, lsk, usl, summa, summaf, kart_pr_id, type,
        spk_id, test_opl, test_cena, test_tarkoef,
        test_spk_koef, sch, kpr, kprz, kpro, opl)
      VALUES
        (npp_, rec_krt.lsk, p_usl, summa_, summaf_, NULL,
        1, NULL, p_vol, p_cena, NULL, NULL, p_sch,
        p_kpr, p_kprz, p_kpro, p_opl);
    END IF;
  END ins_chrg2;

  PROCEDURE ins_chrg(npp_      IN OUT NUMBER,
                     lsk_      IN kart.lsk%TYPE,
                     sign_kub_ IN NUMBER,
                     usl_      IN usl.usl%TYPE,
                     vol_in_   IN NUMBER,
                     cena_     IN NUMBER,
                     sit_      IN OUT NUMBER,
                     msit_     IN OUT NUMBER,
                     sch_      IN NUMBER) IS
    summa_  NUMBER;
    summaf_ NUMBER;
    vol_    NUMBER;
  BEGIN
  --��������� ��������� ins_chrg (����������)
    IF vol_in_ * cena_ <> 0 THEN
      vol_ := vol_in_ * sign_kub_;
      npp_ := npp_ + 1;
      --�� �������
      sit_    := sit_ + round(vol_ * cena_, 2);
      summaf_ := vol_ * cena_;
      summa_  := round(summaf_, 2);
      INSERT INTO c_charge
        (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef, sch)
      VALUES
        (0, lsk_, usl_, summa_, summaf_, NULL, 0, NULL, vol_, cena_, NULL, NULL, sch_);

      --��� ������
      msit_   := msit_ + round(vol_ * cena_, 2);
      summaf_ := vol_ * cena_;
      summa_  := round(summaf_, 2);
      INSERT INTO c_charge
        (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef, sch)
      VALUES
        (npp_, lsk_, usl_, summa_, summaf_, NULL, 1, NULL, vol_, cena_, NULL, NULL, sch_);
    END IF;
  END ins_chrg;

  BEGIN
    -- ������ �������
    l_Java_Charge := utils.get_int_param('JAVA_CHARGE');
    if l_Java_Charge=1 then
      -- ����� Java ���������� - �� ������ ��������������, ������������� �����!
      if lsk_ is not null then
        select k.k_lsk_id into l_klsk_id from kart k where k.lsk=lsk_;
      end if;
      l_dummy:=p_java.gen(p_tp        => 0,
                 p_house_id  => house_id_,
                 p_vvod_id   => p_vvod,
                 p_usl_id    => null,
                 p_klsk_id   => l_klsk_id,
                 p_debug_lvl => 0,
                 p_gen_dt    => nvl(init.dtek_, gdt(32,0,0)), -- �� �������� dtek_, ������� ��������� ���� �������� �������
                 p_stop      => 0);
      return 0;
    end if;
    is_round_charge_ := utils.get_int_param('IS_ROUND_CHARGE');
    OPEN cur_memof;
    FETCH cur_memof
      INTO rec_memof;
    CLOSE cur_memof;

    OPEN cur_params;
    FETCH cur_params
      INTO rec_params;
    CLOSE cur_params;

    SELECT dbid INTO dbid_ FROM sys.v_$database;

    cnt_10   := 0;
    cnt_lsk_ := 0;
    --������������� ������� ����������
    --��������� �� �������� �������� ��������
    -- �������� ��������������, UPDATE ��� ���������� ������� 25.04.2011
    IF house_id_ IS NOT NULL THEN
      var_ := 3;
    ELSIF p_vvod IS NOT NULL THEN
      var_ := 5;
      --����� ���� ��������� ������ ��� ����� �������� - ����.�� 12.04.2011
    ELSIF lsk_ IS NOT NULL AND lsk_end_ IS NULL THEN
      var_ := 2;
    ELSIF lsk_ IS NOT NULL AND lsk_end_ IS NOT NULL THEN
      var_ := 1;
    ELSIF lsk_ IS NULL AND lsk_end_ IS NULL THEN
      var_ := 4;
    END IF;

    IF var_ = 1 THEN
      --�� ������ �.�.
      OPEN cur_krt;
    ELSIF var_ = 2 THEN
      --�� 1 �.�.
      OPEN cur_krt2;
    ELSIF var_ = 3 THEN
      --�� ���������� house_id ����
      OPEN cur_krt3;
    ELSIF var_ = 4 THEN
      --�� ����� �����
      OPEN cur_krt4;
    ELSIF var_ = 5 THEN
      --�� �����
      OPEN cur_krt5;
    END IF;

    LOOP
      --���� �� ������� ������
      IF var_ = 1 THEN
        FETCH cur_krt
          INTO rec_krt;
        EXIT WHEN cur_krt%NOTFOUND;
      ELSIF var_ = 2 THEN
        FETCH cur_krt2
          INTO rec_krt;
        EXIT WHEN cur_krt2%NOTFOUND;
      ELSIF var_ = 3 THEN
        FETCH cur_krt3
          INTO rec_krt;
        EXIT WHEN cur_krt3%NOTFOUND;
      ELSIF var_ = 4 THEN
        FETCH cur_krt4
          INTO rec_krt;
        EXIT WHEN cur_krt4%NOTFOUND;
      ELSIF var_ = 5 THEN
        FETCH cur_krt5
          INTO rec_krt;
        EXIT WHEN cur_krt5%NOTFOUND;
      END IF;

      hv_kub_     := 0;
      gv_kub_     := 0;
      hv_kan_     := 0;
      gv_kan_     := 0;
      hv_kan_nrm_ := 0;
      hv_kan_sch_ := 0;
      gv_kan_nrm_ := 0;
      gv_kan_sch_ := 0;
      hv_kan_add_ := 0;
      gv_kan_add_ := 0;

      npp_ := 0;


      --���������� ����� �� �����������
      c_kart.set_part_kpr(rec_krt.lsk, null, null, rec_krt.tp);

      if iscommit_=1 then
        COMMIT; --������ ����� - ����� �������� � DEADLOCK!
      end if;

      --��������� nabor � ���������
      if t_nabor is not null then
        t_nabor.delete;
      end if;

      select scott.rec_nabor(lsk, usl, org, koeff, norm, fk_tarif, fk_vvod, vol, vol_add, kf_kpr, sch_auto,
       nrm_kpr, kf_kpr_sch, kf_kpr_wrz, kf_kpr_wro, kf_kpr_wrz_sch, kf_kpr_wro_sch, limit, nrm_kpr2)
      bulk collect into t_nabor
      from nabor t where t.lsk=rec_krt.lsk ;

      --������� ������� ������
      DELETE FROM c_charge c WHERE c.lsk = rec_krt.lsk AND c.type in (0,1,2,3,4);--������� ��,
                                                                                 --����� ��������.�� ���


      --���� �� �������� ������� ����, �� �������
      IF rec_krt.psch NOT IN (8, 9) AND
         ((nvl(rec_krt.org_var, 0) <> 0 AND
         nvl(rec_krt.schel_dt, to_date('19000101', 'YYYYMMDD')) <=
         to_date(rec_krt.period || '15', 'YYYYMMDD') AND
         nvl(rec_krt.schel_end, to_date('29000101', 'YYYYMMDD')) >
         to_date(rec_krt.period || '15', 'YYYYMMDD')) OR
         nvl(rec_krt.org_var, 0) = 0) THEN

        cnt_lsk_ := cnt_lsk_ + 1;
        cnt_10   := cnt_10 + 1;
        --��������� ���  �������
        IF cnt_10 = 10 AND nvl(sendmsg_, 0) = 1 THEN
          cnt_10 := 0;
          admin.send_message(lower(USER) || '-lsk:' || rec_krt.lsk);
        END IF;
        --�������������
        sit_      := 0;
        msit_     := 0;
        pl_norma_ := 0;

        OPEN cur_nabor;
        --�������� ����� ����� �� ����� ��������, �� ��������
        LOOP
          rec_nabor:=null;
          FETCH cur_nabor
            INTO rec_nabor;
          EXIT WHEN cur_nabor%NOTFOUND;

          --�������� ����������� �� ����� ��������
          usl_ := rec_nabor.usl;

          --��� ������� ��������� �������
          sign_kub_ := 1;
          --����� �������
          opl_      := rec_krt.opl;
          opl_save_ := opl_;
          --����� ��������
          socn_:=0;

          --||||||||||||||||||||||||||||||||||||||--
          --������ � ��������� ��� ������ �������
          --������� ����������, ���������, ����, �������, ���.������
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (25) or --#25#33
             rec_nabor.fk_calc_tp IN (33) AND rec_krt.status <> 1 --��������� (������)
           THEN
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --��������� ��������
            l_cena:=rec_wo_peop.cena;
            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --������ ��� �� ������ ��������
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --������ ��� ������ ��������
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --����������� ���� ������
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                --if rec_krt.status <> 1 then
                --����:��� �� ������������� �������, �������� ��� ��� ������ �������
                --���.21.08.14 -������ � �� ������� ������� ��� ��� ������ ����������.
                l_cena:=rec_wo_peop.cena_for_empty;
                --end if;
                if rec_nabor2.usl is not null then
                  --���� ���������� ������ "��� �����������"
                    ins_chrg2(c.vol, l_cena, null, rec_nabor.usl_p, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                    --��� ���������� ������ "��� �����������", ������ �� �� �� ������
                    ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --������ � ��������� ��� ������ �������
          --��������� ������������ #14#
          IF rec_nabor.fk_calc_tp IN (14) AND rec_krt.opl <> 0 then
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --��������� ��������
            l_cena:=rec_wo_peop.cena;
            --��������� ��� ������������ ������� ������� �������� ����
            l_ot_dist_tp:=rec_wo_peop.dist_tp;
            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --������ ��� �� ������ ��������
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, c.opl);
              elsif c.empty = 1 then
                --������ ��� ������ ��������
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --����������� ���� ������
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
--                if rec_krt.status <> 1 then
                --����:��� �� ������������� �������, �������� ��� ��� ������ �������
                --���.21.08.14 -������ � �� ������� ������� ��� ��� ������ ����������.
                  l_cena:=rec_wo_peop.cena_for_empty;
--                end if;
                if rec_nabor2.usl is not null then
                  --���� ���������� ������ "��� �����������"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor.usl_p, c.sch, c.kpr, c.kprz, c.kpro, c.opl);
                  else
                  --��� ���������� ������ "��� �����������", ������ �� �� �� ������
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, c.opl);
                end if;
              end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --������� ����������, ���������, ����, �������, ���.���.�����, ��.�����-2
          --������ � ��������� � ����� � ����� � ��������� ��� ������ �������
          --(������ 0 � 2 ������! (���.������, ���������, ��.�����2) #36#)
          IF (rec_nabor.fk_calc_tp IN (36) AND rec_krt.opl <> 0) then
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --����� �� ������ ����� � ���������� �� ������� ��. (��� ��� ������ ��� ��� ��� �����)
            --���. 26.03.14
            --l_el_dist_tp:=rec_wo_peop.dist_tp;
            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --������ ��� �� ������ ��������
                --�� �����
                ins_chrg2(c.vol_nrm, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                --����� ���.�����
                if rec_nabor.usl_p is null then
                  --��� ������ ����� �.�., ������ �� ���.�.
                  ins_chrg2(c.vol_sv_nrm, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                else
                  --���� ������ ����� �.�.
                  OPEN cur_wo_peop(rec_nabor.usl_p);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
                  ins_chrg2(c.vol_sv_nrm, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              elsif c.empty = 1 then
                --������ �������� - ����� � ������ "��� �����������"
                if rec_nabor.usl_empt is not null then --�� ��, ������ ��� �����))
                  OPEN cur_wo_peop(rec_nabor.usl_empt);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
                  ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor.usl_empt, c.sch, c.kpr, c.kprz, c.kpro, null);
                else
                  --��� ������ "��� �����������, ������ �� ��.��������"
                  --����� ���.�����
                  if rec_nabor.usl_p is null then
                    --��� ������ ����� �.�., ������ �� ���.�.
                    ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                    --���� ������ ����� �.�.
                    OPEN cur_wo_peop(rec_nabor.usl_p);
                    FETCH cur_wo_peop
                      INTO rec_wo_peop;
                    CLOSE cur_wo_peop;
                    ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, c.kpr, c.kprz, c.kpro, null);
                  end if;
                end if;
              end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- ���.������ c 70 �������! #37#
          IF rec_nabor.fk_calc_tp IN (37) AND rec_krt.status <> 1 then
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            for c in cur_charge_prep(null, null)
            loop
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, rec_krt.opl);
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
            --������ � ��������� � ����� ��� �������� ��� ������ �������
            --������������ � �����, � ���
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (3) THEN --#3#
            --������� �� ��������� ������� (��� �� � ����� ������ ��� �� ���.�����, �������� ����
            --������������� �� ���� �����)
            socn_kub_   := 0;
            hv_kan_     := 0;
            hv_kan_nrm_ := 0;
            hv_kan_sch_ := 0;
            hv_kan_nrm_ := 0;
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;

            OPEN cur_prep;
            FETCH cur_prep
              INTO rec_prep;
            CLOSE cur_prep;

            --������� ����� �� �������� ���������
            socn_kub_ := round(rec_prep.nrm_kpr * rec_wo_peop.tarnorm, 3);
            hv_kan_nrm_ := rec_prep.nrm_vol; --������ �� �.�. ��� �������.
            --�������� �� �.�.
            hv_kan_sch_ := rec_prep.sch_vol; --������ �� �.�. ��� �������.
            --����� ������
            hv_ := hv_kan_nrm_ + hv_kan_sch_;

            --���� ������ ������������� ��...
            IF hv_ >= 0 THEN
              sign_kub_ := 1;
            ELSE
              sign_kub_ := -1;
            END IF;
            hv_ := abs(hv_);
            --��������
            IF hv_ <= socn_kub_ THEN
              ins_chrg(npp_,
                       rec_krt.lsk,
                       sign_kub_,
                       usl_,
                       hv_,
                       rec_wo_peop.cena,
                       sit_,
                       msit_,
                       CASE
                         WHEN hv_kan_sch_ <> 0 THEN
                          1
                         ELSE
                          0
                       END /*��������� �����������*/);
            ELSE
              ins_chrg(npp_,
                       rec_krt.lsk,
                       sign_kub_,
                       usl_,
                       socn_kub_,
                       rec_wo_peop.cena,
                       sit_,
                       msit_,
                       CASE WHEN hv_kan_sch_ <> 0 THEN 1 ELSE 0 END /*��������� �����������*/);
              IF rec_nabor.chrg2 <> 0 THEN
                --����� �.�����
                usl_ := rec_nabor.usl_p;
                OPEN cur_wo_peop(null);
                FETCH cur_wo_peop
                  INTO rec_wo_peop;
                CLOSE cur_wo_peop;
                ins_chrg(npp_,
                         rec_krt.lsk,
                         sign_kub_,
                         usl_,
                         hv_ - socn_kub_,
                         rec_wo_peop.cena,
                         sit_,
                         msit_,
                         CASE WHEN hv_kan_sch_ <> 0 THEN 1 ELSE 0 END /*��������� �����������*/);
              END IF;
            END IF;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --������ � ��������� � ����� ��� �������� ��� ������ �������
          --������������ � �����, � ���
          -- ������� ���� (�.�.)- ��� �� 19.09.11
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (4) THEN  --#4#
            --������� �� ��������� ������� (��� �� � ����� ������ ��� �� ���.�����, �������� ����
            --������������� �� ���� �����)
            socn_kub_   := 0;
            gv_kan_     := 0;
            gv_kan_nrm_ := 0;
            gv_kan_sch_ := 0;
            gv_kan_nrm_ := 0;
            gv_         := 0;
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;

            OPEN cur_prep;
            FETCH cur_prep
              INTO rec_prep;
            CLOSE cur_prep;

            --������� ����� �� �������� ���������
            socn_kub_ := round(rec_prep.nrm_kpr * rec_wo_peop.tarnorm, 3);


            --������� ����� �� �������� ���������
            socn_kub_ := round(rec_prep.nrm_kpr * rec_wo_peop.tarnorm, 3);
            gv_kan_nrm_ := rec_prep.nrm_vol; --������ �� �.�. ��� �������.
            --�������� �� �.�.
            gv_kan_sch_ := rec_prep.sch_vol; --������ �� �.�. ��� �������.
            --����� ������
            gv_ := gv_kan_nrm_ + gv_kan_sch_; --��������� ������ �������� ����������� (�����������)
            --���� ������ ������������� ��...
            IF gv_ >= 0 THEN
              sign_kub_ := 1;
            ELSE
              sign_kub_ := -1;
            END IF;
            gv_ := abs(gv_);
            --��������
            IF gv_ <= socn_kub_ THEN
              ins_chrg(npp_,
                       rec_krt.lsk,
                       sign_kub_,
                       usl_,
                       gv_,
                       rec_wo_peop.cena,
                       sit_,
                       msit_,
                       CASE
                         WHEN gv_kan_sch_ <> 0 THEN
                          1
                         ELSE
                          0
                       END /*��������� �����������*/);
            ELSE
              ins_chrg(npp_,
                       rec_krt.lsk,
                       sign_kub_,
                       usl_,
                       socn_kub_,
                       rec_wo_peop.cena,
                       sit_,
                       msit_,
                       CASE WHEN gv_kan_sch_ <> 0 THEN 1 ELSE 0 END /*��������� �����������*/);
              IF rec_nabor.chrg2 <> 0 THEN
                --����� �.�����
                usl_ := rec_nabor.usl_p;
                OPEN cur_wo_peop(null);
                FETCH cur_wo_peop
                  INTO rec_wo_peop;
                CLOSE cur_wo_peop;
                ins_chrg(npp_,
                         rec_krt.lsk,
                         sign_kub_,
                         usl_,
                         gv_ - socn_kub_,
                         rec_wo_peop.cena,
                         sit_,
                         msit_,
                         CASE WHEN gv_kan_sch_ <> 0 THEN 1 ELSE 0 END /*��������� �����������*/);
              END IF;
            END IF;
          END IF;




          --||||||||||||||||||||||||||||||||||||||--
          --������ � ��������� ��� ������ ������� � ��������� � �����
          -- �������� ����, ������� ���� /������� ��� ���. �� 29.04.2014/
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (38, 40) THEN --#38#40#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            l_flag:=0;
            /*if rec_nabor.usl_cd = '�.����' then
              --��������� ��� �����.�����. �.�.
              l_hw_dist_tp:=rec_wo_peop.dist_tp;
            elsif rec_nabor.usl_cd = '�.����' then
              --��������� ��� �����.�����. �.�.
              l_gw_dist_tp:=rec_wo_peop.dist_tp;
            end if;*/

            for c in cur_charge_prep(null, null)
            loop
              if l_flag=0 then
                l_flag:=1;
                l_kpr:=c.kpr;
                l_kprz:=c.kprz;
                l_kpro:=c.kpro;
              end if;

              if c.empty = 0 then
                --������ ��� �� ������ ��������
                --�� �����
                ins_chrg2(c.vol_nrm, rec_wo_peop.cena, null, usl_, c.sch, l_kpr, l_kprz, l_kpro, null);
--                l_kpr:=0; -�����, ��� ��� � ������ ���������� ����� �� �������������� �.�. � ����.
--                l_kprz:=0;
--                l_kpro:=0;
                OPEN cur_wo_peop(rec_nabor.usl_p);
                FETCH cur_wo_peop
                  INTO rec_wo_peop;
                CLOSE cur_wo_peop;
                --����� ���.�����
                if rec_nabor.usl_p is not null then --���.20.11.14, ������, ��� ��� ���� �������� exception � ������ ������ rec_nabor.usl_p
                  ins_chrg2(c.vol_sv_nrm, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, l_kpr, l_kprz, l_kpro, null);
                  l_kpr:=0;
                  l_kprz:=0;
                  l_kpro:=0;
                end if;
              elsif c.empty = 1 then
                --������ ��� ������ ��������
                OPEN cur_nabor2(rec_nabor.usl_empt);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --����������� ���� ������
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                OPEN cur_wo_peop(rec_nabor.usl_empt);
                FETCH cur_wo_peop
                  INTO rec_wo_peop;
                CLOSE cur_wo_peop;

                if rec_nabor2.usl is not null then
                  --���� ���������� ������ "��� �����������"
                  ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor2.usl, c.sch, null, null, null, null);
                  else
                  --��� ���������� ������ "��� �����������", ���� �� ����� �.�.
                  --������ ��� ������ ��������
                  OPEN cur_wo_peop(rec_nabor.usl_p);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
                  ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, null, null, null, null);
                  --    Raise_application_error(-20000, '��� ���������� ������ "��� �����������" �.�.:'||rec_krt.lsk);
                end if;
              end if;
            end loop;
          END IF;

          --||||||||||||||||||||||||||||||||||||||--
          --������ � ��������� ��� ������ ������� � ��������� � �����
          -- ������������� /������� ��� ��� ���. �� 19.05.2014/
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND rec_nabor.fk_calc_tp IN (39) THEN --#39#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            OPEN cur_prep;
            FETCH cur_prep
              INTO rec_prep;
            CLOSE cur_prep;
            --������ � ���� ������ ���������� ������ ����� ��� ����� �� � C_KART!
            l_kpr:=0;
            l_kprz:=0;
            l_kpro:=0;
            for c2 in cur_charge_prep(null, null)
            loop
              l_kpr:=c2.kpr;
              l_kprz:=c2.kprz;
              l_kpro:=c2.kpro;
            end loop;

            /*if rec_nabor.usl_cd = '�.����' then
              --��������� ��� �����.�����. �.�.
              l_hw_dist_tp:=rec_wo_peop.dist_tp;
            elsif rec_nabor.usl_cd = '�.����' then
              --��������� ��� �����.�����. �.�.
              l_gw_dist_tp:=rec_wo_peop.dist_tp;
            end if;*/

            for c in cur_charge_prep_usl_cd('�.����,�.����')
            loop
              if c.empty = 0 then
                --������ ��� �� ������ ��������
                l_norm:=rec_wo_peop.tarnorm*rec_prep.kpr;
                l_vol:=abs(c.vol);
                l_sign:=sign(c.vol);

                while l_norm >0 and l_vol >0
                loop
                  if l_norm >0 and l_norm > l_vol then
                    --�� �����
--                    ins_chrg2(l_vol*l_sign, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null); --�����
                    ins_chrg2(l_vol*l_sign, rec_wo_peop.cena, null, usl_, c.sch, l_kpr, l_kprz, l_kpro, null); --����� (����� ����������� ����������� ���-�� ���� �� �������)
--                l_kpr:=0; -�����, ��� ��� � ������ ���������� ����� �� �������������� �.�. � ����.
--                l_kprz:=0;
--                l_kpro:=0;
                    l_norm:=l_norm-l_vol;
                    l_vol:=0;
                  elsif l_norm >0 and l_norm <=l_vol then
                    --�� �����
--                    ins_chrg2(l_norm*l_sign, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null); --�����
                    ins_chrg2(l_norm*l_sign, rec_wo_peop.cena, null, usl_, c.sch, l_kpr, l_kprz, l_kpro, null); --����� (����� ����������� ����������� ���-�� ���� �� �������)
--                l_kpr:=0; -�����, ��� ��� � ������ ���������� ����� �� �������������� �.�. � ����.
--                l_kprz:=0;
--                l_kpro:=0;
                    l_vol:=l_vol-l_norm;
                    l_norm:=0;
                  end if;
                end loop;
                if l_vol > 0 and rec_nabor.usl_p is not null then --�������, ���� rec_nabor.usl_p - �� ������... 13.04.2015
                  --����� ��������
                  OPEN cur_wo_peop(rec_nabor.usl_p);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
--                  ins_chrg2(l_vol*l_sign, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, c.kpr, c.kprz, c.kpro, null); --�����
                  ins_chrg2(l_vol*l_sign, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, l_kpr, l_kprz, l_kpro, null); --����� (����� ����������� ����������� ���-�� ���� �� �������)
                  l_kpr:=0;
                  l_kprz:=0;
                  l_kpro:=0;
                  l_vol:=0;
                end if;
              elsif c.empty = 1 then
                --������ ��� ������ ��������
                OPEN cur_nabor2(rec_nabor.usl_empt);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --����������� ���� ������
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;

                if rec_nabor2.usl is not null then
                  --���� ���������� ������ "��� �����������"
                  OPEN cur_wo_peop(rec_nabor.usl_empt);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
--                  ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null); --�����
                  ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor2.usl, c.sch, null, null, null, null); --����� (����� ����������� ����������� ���-�� ���� �� �������)
                  elsif rec_nabor.usl_p is not null then
                  --��� ���������� ������ "��� �����������", ���� �� ����� �.�.
                  --������ ��� ������ ��������
                  --Raise_application_error(-20000, 'rec_nabor.usl_p'||rec_nabor.usl_p);

                  OPEN cur_wo_peop(rec_nabor.usl_p);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
--                    ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, c.kpr, c.kprz, c.kpro, null); --�����
                    ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, null, null, null, null); --����� (����� ����������� ����������� ���-�� ���� �� �������)
                  else -- ������ ��� ������� ����� �����.�.�. � 0 ������
                  OPEN cur_wo_peop(usl_);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
--                    ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, c.kpr, c.kprz, c.kpro, null); --�����
                    ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, null, null, null, null);
                end if;
              end if;
            end loop;

          END IF;


          --||||||||||||||||||||||||||||||||||||||--
            --������ (����������)
            --������������ � �����, � ���
            --������� �� ��������� ������� (��� �� � ����� ������ ��� �� ���.�����, �������� ����
            --������������� �� ���� �����)
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND rec_nabor.fk_calc_tp IN (5) THEN --#5#
            socn_kub_ := 0;
            kan_      := 0;
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;

            OPEN cur_prep;
            FETCH cur_prep
              INTO rec_prep;
            CLOSE cur_prep;

            --������� ����� �� �������� ���������
            socn_kub_ := round(rec_prep.nrm_kpr * rec_wo_peop.tarnorm, 3);
            --����� ������
            kan_ := hv_kan_nrm_ + hv_kan_sch_ + gv_kan_nrm_ + gv_kan_sch_;
            --���� ������ ������������� ��...
            IF kan_ >= 0 THEN
              sign_kub_ := 1;
            ELSE
              sign_kub_ := -1;
            END IF;
            kan_ := abs(kan_);
            --��������
            IF kan_ <= socn_kub_ THEN
              ins_chrg(npp_,
                       rec_krt.lsk,
                       sign_kub_,
                       usl_,
                       kan_,
                       rec_wo_peop.cena,
                       sit_,
                       msit_,
                       CASE
                         WHEN gv_kan_sch_ <> 0 OR hv_kan_sch_ <> 0 THEN
                          1
                         ELSE
                          0
                       END /*��������� �����������*/);
            ELSE
              ins_chrg(npp_,
                       rec_krt.lsk,
                       sign_kub_,
                       usl_,
                       socn_kub_,
                       rec_wo_peop.cena,
                       sit_,
                       msit_,
                       CASE WHEN gv_kan_sch_ <> 0 OR hv_kan_sch_ <> 0 THEN 1 ELSE 0 END /*��������� �����������*/);
              IF rec_nabor.chrg2 <> 0 THEN
                --����� �.�����
                usl_ := rec_nabor.usl_p;
                OPEN cur_wo_peop(null);
                FETCH cur_wo_peop
                  INTO rec_wo_peop;
                CLOSE cur_wo_peop;
                ins_chrg(npp_,
                         rec_krt.lsk,
                         sign_kub_,
                         usl_,
                         kan_ - socn_kub_,
                         rec_wo_peop.cena,
                         sit_,
                         msit_,
                         CASE WHEN gv_kan_sch_ <> 0 OR hv_kan_sch_ <> 0 THEN 1 ELSE 0 END /*��������� �����������*/);
              END IF;
            END IF;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --������ � ��������� ��� ������ �������
          -- �������� ����/������� ��� ���. �� 18.01.2018/
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (17) THEN --#17
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --������ ��� �� ������ ��������
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --������ ��� ������ ��������
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --����������� ���� ������
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                l_cena:=rec_wo_peop.cena_for_empty;
                if rec_nabor2.usl is not null then
                  --���� ���������� ������ "��� �����������"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --��� ���������� ������ "��� �����������", ������ �� �� �� ������
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --������ � ��������� ��� ������ �������
          -- ������� ���� /������� ��� ���. �� 18.01.2018/
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (18) THEN --#18
            OPEN cur_wo_peop_gw(null);
            FETCH cur_wo_peop_gw
              INTO rec_wo_peop_gw;
            CLOSE cur_wo_peop_gw;
            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --������ ��� �� ������ ��������
                ins_chrg2(c.vol, rec_wo_peop_gw.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --������ ��� ������ ��������
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --����������� ���� ������
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                l_cena:=rec_wo_peop_gw.cena_for_empty;
                if rec_nabor2.usl is not null then
                  --���� ���������� ������ "��� �����������"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --��� ���������� ������ "��� �����������", ������ �� �� �� ������
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --������ � ��������� ��� ������ �������
          -- ������������� /������� ��� ���. �� 01.03.2014/
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND rec_nabor.fk_calc_tp IN (19) THEN --#19#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --��������� ��������
            l_cena:=rec_wo_peop.cena;
            i:=0;
            -- ����� �� ���� �� ������������� klsk
            for c in cur_charge_prep_usl_cd_by_klsk('�.����,�.����,�.�. ��� ���')
            loop
              if c.empty = 0 then
                --������ ��� �� ������ ��������
                if i=0 then
                --������ ���� ��� ���������� ���-�� �����������
                  for c2 in cur_charge_prep_kpr
                  loop
                    ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c2.kpr, c2.kprz, c2.kpro, null);
                  end loop;
                  i:=1;
                else
                  ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, null, null, null, null);
                end if;
              elsif c.empty = 1 then
                --������ ��� ������ ��������
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --����������� ���� ������
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
--                if rec_krt.status <> 1 then
                --����:��� �� ������������� �������, �������� ��� ��� ������ �������
                --���.21.08.14 -������ � �� ������� ������� ��� ��� ������ ����������.
                l_cena:=rec_wo_peop.cena_for_empty;
--                end if;
                if rec_nabor2.usl is not null then
                  --���� ���������� ������ "��� �����������"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, null, null, null, null);
                  else
                  --��� ���������� ������ "��� �����������", ������ �� �� �� ������
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, null, null, null, null);
                end if;
              end if;
            end loop;

          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --������ � ��������� ��� ������ �������
          -- �������������� - ������ ������  /������� ��� ���. �� 01.03.2014/
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND rec_nabor.fk_calc_tp IN (31) THEN --#31#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --��������� ��������
            l_cena:=rec_wo_peop.cena;
            --��������� ��� �����.�����.
            --l_el_dist_tp:=rec_wo_peop.dist_tp;

            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --������ ��� �� ������ ��������
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --������ ��� ������ ��������
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --����������� ���� ������
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                if rec_krt.status <> 1 then
                --��� �� ������������� �������, �������� ��� ��� ������ �������
                  l_cena:=rec_wo_peop.cena_for_empty;
                end if;

                if rec_nabor2.usl is not null then
                  --���� ���������� ������ "��� �����������"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --��� ���������� ������ "��� �����������", ������ �� �� �� ������
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- �������� ���� - ������������ �� 354 /������� ��� ��, ��� ������ ��� ��������� �������/
           IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp IN (20) THEN --#20#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --��������� ��������
            l_cena:=rec_wo_peop.cena;

            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --������ ��� �� ������ ��������
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --������ ��� ������ ��������
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --����������� ���� ������
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                --if rec_krt.status <> 1 then
                --����:��� �� ������������� �������, �������� ��� ��� ������ �������
                --���.21.08.14 -������ � �� ������� ������� ��� ��� ������ ����������.
                  l_cena:=rec_wo_peop.cena_for_empty;
                --end if;
                if rec_nabor2.usl is not null then
                  --���� ���������� ������ "��� �����������"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --��� ���������� ������ "��� �����������", ������ �� �� �� ������
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end if;
            end loop;
/*
            hv_kan_add_ := 0;
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            hv_kan_add_ := nvl(rec_nabor.vol_add,0); --������ �� �.�. ��� ��� �������. ���
            ins_chrg2(rec_nabor.vol_add, rec_wo_peop.cena, null, usl_);*/

          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- ������� ���� - ������������ �� 354 /������� ��� ��, ��� ������ ��� ��������� �������/
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp IN (21) THEN --#21#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --��������� ��������
            l_cena:=rec_wo_peop.cena;

            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --������ ��� �� ������ ��������
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --������ ��� ������ ��������
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --����������� ���� ������
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
--                if rec_krt.status <> 1 then
                --����:��� �� ������������� �������, �������� ��� ��� ������ �������
                --���.21.08.14 -������ � �� ������� ������� ��� ��� ������ ����������.
                  l_cena:=rec_wo_peop.cena_for_empty;
--                end if;
                if rec_nabor2.usl is not null then
                  --���� ���������� ������ "��� �����������"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --��� ���������� ������ "��� �����������", ������ �� �� �� ������
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end if;
            end loop;
/*
            gv_kan_add_ := 0;
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            gv_kan_add_ := nvl(rec_nabor.vol_add,0); --������ �� �.�. ��� ��� �������. ���
            ins_chrg2(rec_nabor.vol_add, rec_wo_peop.cena, null, usl_);*/
          END IF;

          -- �������� ���� - ������������ �� 354 ��� ��� /������� ��� ��, ��� ������ ��� ��������� �������/
           IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp IN (41) THEN --#41#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --��������� ��������
            l_cena:=rec_wo_peop.cena;

            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --������ ��� �� ������ ��������
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --������ ��� ������ ��������
                OPEN cur_nabor2(rec_nabor.usl_empt);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --����������� ���� ������
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                  l_cena:=rec_wo_peop.cena_for_empty;
                if rec_nabor2.usl is not null then
                  --���� ���������� ������ "��� �����������"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --��� ���������� ������ "��� �����������", ������ �� �� �� ������
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end if;
            end loop;

          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- ������� ���� - ������������ �� 354  ��� ��� /������� ��� ��, ��� ������ ��� ��������� �������/
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp IN (42) THEN --#42#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --��������� ��������
            l_cena:=rec_wo_peop.cena;

            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --������ ��� �� ������ ��������
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --������ ��� ������ ��������
                OPEN cur_nabor2(rec_nabor.usl_empt);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --����������� ���� ������
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                  l_cena:=rec_wo_peop.cena;
                if rec_nabor2.usl is not null then
                  --���� ���������� ������ "��� �����������"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --��� ���������� ������ "��� �����������", ������ �� �� �� ������
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end if;
            end loop;
/*
            gv_kan_add_ := 0;
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            gv_kan_add_ := nvl(rec_nabor.vol_add,0); --������ �� �.�. ��� ��� �������. ���
            ins_chrg2(rec_nabor.vol_add, rec_wo_peop.cena, null, usl_);*/
          END IF;

          --||||||||||||||||||||||||||||||||||||||--
          --������ �� ���������� �����. � ���������� �� �.344. ������ ������ ��� �������������!!!
          -- ��������, ������� ����
          --��������! ��������� ����������� ������� usl.usl_order! --������� ������ ������ ����� ������������!
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (44) THEN --#44#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;

            for c in cur_charge_prep(rec_nabor.parent_usl, null)
            loop
              --���������� ������ ���������� ��������
              --��������! �� ���� ������, � nabor.norm ��������� ����� � ������������ ������� ������������ ������!
              if c.sch = 0 and c.empty = 0 then
                -- ���� �����������
                ins_chrg2(c.vol_nrm * rec_wo_peop.tarnorm, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.sch = 0 and c.empty = 1 then
                -- ��� ����������� - ���. 31.01.19
                OPEN cur_wo_peop(rec_nabor.usl_empt);
                FETCH cur_wo_peop
                  INTO rec_wo_peop2;
                if cur_wo_peop%NOTFOUND then
                  --��� ���������� ������ "��� �����������", ������ �� �� �� ������
                  ins_chrg2(c.vol_nrm * rec_wo_peop.tarnorm, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                else
                  --���� ���������� ������ "��� �����������"
                  ins_chrg2(c.vol_nrm * rec_wo_peop2.tarnorm, rec_wo_peop2.cena, null, rec_nabor.usl_empt, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
                CLOSE cur_wo_peop;
              end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --||||||||||||||||||||||||||||||||||||||--
          --������ �� ���������� �����. � ���������� �� �.344.
          --��� ��������, ��� ������� ����
          --��������! ��������� ����������� ������� usl.usl_order! --������� ������ ������ ����� ������������!
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (45) THEN --#45#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            for c in cur_charge_prep(rec_nabor.parent_usl, null)
            loop
              --���������� ������ ���������� �������� �� ���� � ������������ ��� ���������
              --��������! �� ���� ������, � nabor.norm ��������� ����� � ������������ ������� ������������ ������!
                select decode(rec_nabor.usl_cd, '���_���_���', '�.����', '���_���_���', '�.����', '��_���_���', '��.�����.2', '��.��.���� ��', null) into l_str from dual;
                for c2 in cur_vvod_tp(l_str)
                loop
                if rec_nabor.usl_cd = '���_���_���' and c2.dist_tp=4 or
                   rec_nabor.usl_cd = '���_���_���' and c2.dist_tp=4 or
                   rec_nabor.usl_cd = '��_���_���' and c2.dist_tp=4 then
                  ins_chrg2(c.vol_nrm * rec_wo_peop.tarnorm, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end loop;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --||||||||||||||||||||||||||||||||||||||--
          --������ �� ���������� �����. � ���������� �� �.344. (����� ������� * �����, ��� ��� c_vvod.dist_tp=4) � 01.02.2019 (���.)
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (50) THEN --#50#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
          --���������� ������ ���������� �������� �� ���� � ������������ ��� ���������
          --��������! �� ���� ������, � nabor.norm ��������� ����� � ������������ ������� ������������ ������!
            select decode(rec_nabor.usl_cd, '���_���_���', '�.����', '���_���_���', '�.����', '��_���_���', '��.�����.2', '��.��.���� ��', null) into l_str from dual;
            for c2 in cur_vvod_tp2(l_str)
            loop
            if rec_nabor.usl_cd = '���_���_���' and c2.dist_tp=4 or
               rec_nabor.usl_cd = '���_���_���' and c2.dist_tp=4 or
               rec_nabor.usl_cd = '��_���_���' and c2.dist_tp=4 then
              ins_chrg2(rec_krt.opl * rec_wo_peop.tarnorm, rec_wo_peop.cena, null, usl_, 0, 0, 0, 0, null);
            end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--

          --||||||||||||||||||||||||||||||||||||||--
          --������ �� ���������� �����. � ���������� �� �.344.
          --���������
          --��������! ��������� ����������� ������� usl.usl_order! --������� ������ ������ ����� ������������!
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (46) THEN --#46#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            for c in cur_charge_prep_usl_cd('����.����.,����.����./0 �����.')
            loop
              --���������� ������ ���������� �������� �� ���� � ������������ ��� ���������
              --��������! �� ���� ������, � nabor.norm ��������� ����� � ������������ ������� ������������ ������!
              if rec_nabor.usl_cd = '����.����_���_���' and l_ot_dist_tp=4 then
                ins_chrg2(c.vol_nrm * rec_wo_peop.tarnorm, rec_wo_peop.cena, null, usl_, c.sch, null, null, null, null);
              end if;
            end loop;
          END IF;

          --||||||||||||||||||||||||||||||||||||||--
          --������ � ��������� ��� ������ �������
          -- ����.������� ��� ������� ���/������� ��� ���. �� 24.03.2015/
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (47) THEN --#47#

            --�������� ��� ������ �.�. ��� ���
            select u.usl into l_tmp_usl
              from usl u where u.cd='�.�. ��� ���';
            OPEN cur_wo_peop(l_tmp_usl);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --�������� �� ���� ����� �.�. ��� ���
            l_tmp_vol:=rec_wo_peop.kub;

            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --��������� ��������
            l_cena:=rec_wo_peop.cena;
            i:=0;
            for c in cur_charge_prep_usl_cd('�.�. ��� ���')
            loop
              if rec_wo_peop.kub <> 0 and l_tmp_vol <> 0 then
               --����������, ��� ����� �.�. ��� ��� � �������� / ����� �.�. ��� ��� �� ���� * ������ �� ���� ����.������� � ����
                l_vol:=c.vol/l_tmp_vol * rec_wo_peop.kub;
              else
                --����� �� �����, ������� ������
                exit;
              end if;

              if c.empty = 0 then
                --������ ��� �� ������ ��������
                if i=0 then
                --������ ���� ��� ���������� ���-�� �����������
                  for c2 in cur_charge_prep_kpr
                  loop
                    ins_chrg2(l_vol, rec_wo_peop.cena, null, usl_, c.sch, c2.kpr, c2.kprz, c2.kpro, null);
                  end loop;
                  i:=1;
                else
                  ins_chrg2(l_vol, rec_wo_peop.cena, null, usl_, c.sch, null, null, null, null);
                end if;
              elsif c.empty = 1 then
                --������ ��� ������ ��������
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --����������� ���� ������
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                l_cena:=rec_wo_peop.cena_for_empty;
                if rec_nabor2.usl is not null then
                  --���� ���������� ������ "��� �����������"
                  ins_chrg2(l_vol, l_cena, null, rec_nabor2.usl, c.sch, null, null, null, null);
                  else
                  --��� ���������� ������ "��� �����������", ������ �� �� �� ������
                  ins_chrg2(l_vol, l_cena, null, usl_, c.sch, null, null, null, null);
                end if;
              end if;
            end loop;

          END IF;
          --||||||||||||||||||||||||||||||||||||||--

          --||||||||||||||||||||||||||||||||||||||--
          -- ������� ����.�� (�����)
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
               rec_nabor.fk_calc_tp = 6 THEN --#6#
            --������ ���� �����������!
            OPEN cur_prep;
            FETCH cur_prep
              INTO rec_prep;
            CLOSE cur_prep;
            if rec_prep.kpr > 0 then
              OPEN cur_wo_peop(null);
              FETCH cur_wo_peop
                INTO rec_wo_peop;
              CLOSE cur_wo_peop;
              l_cena:=rec_wo_peop.cena;
              if l_cena <> 0 then
                ins_chrg2(rec_prep.kpr2, l_cena, null, usl_, null, rec_prep.kpr, null, null, null);
              end if;
            end if;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- ���� (������ �� ������������� ���������)
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp in (7) AND rec_krt.status = 1 THEN --#7#
            --������������� �����������, ������� �� �2
            OPEN cur_prep;
            FETCH cur_prep
              INTO rec_prep;
            CLOSE cur_prep;
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            l_cena:=rec_wo_peop.cena;
            if l_cena <> 0 then
              ins_chrg2(rec_krt.opl, l_cena, null, usl_, null, rec_prep.kpr, null, null, null);
            end if;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- ������ ����
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp in (8) THEN --#7#
            --������������� �����������, ������� �� �2
            OPEN cur_prep;
            FETCH cur_prep
              INTO rec_prep;
            CLOSE cur_prep;
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            l_cena:=rec_wo_peop.cena;
            if l_cena <> 0 then
              ins_chrg2(rec_prep.kpr, l_cena, null, usl_, null, rec_prep.kpr, null, null, null);
            end if;
          END IF;

          --||||||||||||||||||||||||||||||||||||||--
          -- ��.�������
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp = 9 THEN --#9#
            IF round(rec_krt.el1, 2) <> 0 THEN
              --�� �������
              --            sit_ := sit_ + round(rec_krt.el1, 2);
              OPEN cur_wo_peop(null);
              FETCH cur_wo_peop
                INTO rec_wo_peop;
              npp_    := npp_ + 1;
              summaf_ := rec_krt.el1;
              summa_  := round(summaf_, 2);
              INSERT INTO c_charge
                (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
              VALUES
                (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, NULL, rec_wo_peop.cena, NULL, NULL);
              --��� ������
              --            msit_ := msit_ + round(rec_krt.el1, 2);
              summaf_ := rec_krt.el1;
              summa_  := round(summaf_, 2);
              INSERT INTO c_charge
                (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
              VALUES
                (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, NULL, rec_wo_peop.cena, NULL, NULL);
              CLOSE cur_wo_peop;
            END IF;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- ��.������� �������
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp = 10 THEN --#10#

            Raise_application_error(-20000, '�� �������� ������!!!');
/*            IF round(rec_krt.el, 2) <> 0 THEN
              --�� �������
              npp_    := npp_ + 1;
              sit_    := sit_ + round(rec_krt.el * rec_wo_peop.usl_subs, 2);
              summaf_ := rec_krt.el;
              summa_  := round(summaf_, 2);
              INSERT INTO c_charge
                (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
              VALUES
                (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, NULL, rec_peoples.cena, NULL, NULL);
              --��� ������
              msit_   := msit_ +
                         round(rec_krt.el * rec_wo_peop.usl_subs, 2);
              summaf_ := rec_krt.el;
              summa_  := round(summaf_, 2);
              INSERT INTO c_charge
                (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
              VALUES
                (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, NULL, rec_peoples.cena, NULL, NULL);
            END IF; */
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- ������ ��� ���
          -- �� ����� ���� ���� ��� ���
          --        if (rec_nabor.chrg1 <> 0 or rec_nabor.chrg2 <> 0) and usl_ = '032' then
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp = 11 THEN --#11#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            IF round(rec_wo_peop.tarkoef, 2) <> 0 THEN
              npp_ := npp_ + 1;
              --�� �������
              --             sit_ := sit_ + round(rec_wo_peop.tarkoef, 2); --��� ������� ����� �����
              summaf_ := rec_wo_peop.tarkoef;
              summa_  := round(summaf_, 2);
              INSERT INTO c_charge
                (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
              VALUES
                (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, NULL, rec_wo_peop.cena, rec_wo_peop.tarkoef, NULL);
              --��� ������
              --             msit_ := msit_ + round(rec_wo_peop.tarkoef, 2);
              summaf_ := rec_wo_peop.tarkoef;
              summa_  := round(summaf_, 2);
              INSERT INTO c_charge
                (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
              VALUES
                (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, NULL, rec_wo_peop.cena, rec_wo_peop.tarkoef, NULL);
            END IF;
            CLOSE cur_wo_peop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- ��.����� � ����������, �������������� �� ��� (��� ���)
          -- �� ����� ���� ���� ��� ���
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp IN (15) THEN --#15#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            IF round(rec_wo_peop.tarkoef, 2) <> 0 THEN
              npp_ := npp_ + 1;
              --�� �������
              summaf_ := nvl(rec_nabor.vol, 0) * rec_wo_peop.cena;
              summa_  := round(summaf_, 2);
              INSERT INTO c_charge
                (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
              VALUES
                (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, round(rec_nabor.vol,
                        2), rec_wo_peop.cena, rec_wo_peop.tarkoef, NULL);
              --��� ������
              summaf_ := nvl(rec_nabor.vol, 0) * rec_wo_peop.cena;
              summa_  := round(summaf_, 2);
              INSERT INTO c_charge
                (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
              VALUES
                (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, round(rec_nabor.vol,
                        2), rec_wo_peop.cena, rec_wo_peop.tarkoef, NULL);
            END IF;
            CLOSE cur_wo_peop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- �������-1,2, ���.�����-1,2
          -- �� ����� ���� ���� ��� ���, �� ������� �� ������
          --        if (rec_nabor.chrg1 <> 0 or rec_nabor.chrg2 <> 0) and usl_ in ('042','043','044','045') then
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp IN (12, 13) THEN --#12# #13#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            IF round(rec_wo_peop.tarkoef * rec_wo_peop.tarnorm, 2) <> 0 THEN
              IF nvl(rec_krt.org_var, 0) <> 0 THEN
                --�����+
                SELECT MAX(s.cena)
                INTO   cena_
                FROM   spr_tarif_prices s, params p
                WHERE  s.fk_tarif = rec_nabor.fk_tarif
                AND    p.period BETWEEN s.mg1 AND s.mg2;
                npp_ := npp_ + 1;
                IF rec_nabor.fk_calc_tp IN (12) THEN
                  --��������� �+
                  --�� �������
                  summaf_ := CASE
                               WHEN rec_nabor.fk_tarif IS NULL THEN
                                rec_wo_peop.tarkoef
                               WHEN rec_nabor.fk_tarif IS NOT NULL THEN
                                cena_
                             END * rec_wo_peop.tarnorm;
                  summa_  := round(summaf_, 2);
                  INSERT INTO c_charge
                    (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
                  VALUES
                    (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, CASE WHEN
                      rec_nabor.fk_tarif IS NULL THEN
                      rec_wo_peop.tarkoef WHEN
                      rec_nabor.fk_tarif IS NOT NULL THEN
                      cena_
                      END *
                      rec_wo_peop.tarnorm, rec_wo_peop.cena, rec_wo_peop.tarkoef, NULL);
                  --��� ������
                  summaf_ := CASE
                               WHEN rec_nabor.fk_tarif IS NULL THEN
                                rec_wo_peop.tarkoef
                               WHEN rec_nabor.fk_tarif IS NOT NULL THEN
                                cena_
                             END * rec_wo_peop.tarnorm;
                  summa_  := round(summaf_, 2);
                  INSERT INTO c_charge
                    (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
                  VALUES
                    (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, CASE WHEN
                      rec_nabor.fk_tarif IS NULL THEN
                      rec_wo_peop.tarkoef WHEN
                      rec_nabor.fk_tarif IS NOT NULL THEN
                      cena_
                      END *
                      rec_wo_peop.tarnorm, rec_wo_peop.cena, rec_wo_peop.tarkoef, NULL);
                ELSIF rec_nabor.fk_calc_tp IN (13) THEN
                  --������� �+ (��� ����������)
                  INSERT INTO c_charge
                    (npp, lsk, usl, summa, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
                  VALUES
                    (0, rec_krt.lsk, usl_, NULL, NULL, 0, NULL, CASE
                        WHEN rec_nabor.fk_tarif IS NULL THEN
                         NULL
                        WHEN rec_nabor.fk_tarif IS NOT NULL THEN
                         cena_
                      END *
                      rec_wo_peop.tarnorm, rec_wo_peop.cena, rec_wo_peop.tarkoef, NULL);
                  --��� ������
                  INSERT INTO c_charge
                    (npp, lsk, usl, summa, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
                  VALUES
                    (npp_, rec_krt.lsk, usl_, NULL, NULL, 1, NULL, CASE WHEN
                      rec_nabor.fk_tarif IS NULL THEN NULL WHEN
                      rec_nabor.fk_tarif IS NOT NULL THEN
                      cena_
                      END *
                      rec_wo_peop.tarnorm, rec_wo_peop.cena, rec_wo_peop.tarkoef, NULL);
                END IF;
              ELSE
                --������, ���
                --�� �������
                npp_    := npp_ + 1;
                summaf_ := rec_wo_peop.cena;
                summa_  := round(summaf_, 2);
                INSERT INTO c_charge
                  (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
                VALUES
                  (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, round(rec_wo_peop.tarkoef *
                          rec_wo_peop.tarnorm,
                          2), rec_wo_peop.cena, rec_wo_peop.tarkoef, NULL);
                --��� ������
                summaf_ := rec_wo_peop.cena;
                summa_  := round(summaf_, 2);
                INSERT INTO c_charge
                  (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
                VALUES
                  (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, round(rec_wo_peop.tarkoef *
                          rec_wo_peop.tarnorm,
                          2), rec_wo_peop.cena, rec_wo_peop.tarkoef, NULL);
              END IF;
            END IF;

            CLOSE cur_wo_peop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- �������� �� �����+
          -- �� ����� ���� ���� ��� ���, �� ������� �� ������
          IF (rec_nabor.chrg1 <> 0) AND rec_nabor.fk_calc_tp IN (16) THEN --#16#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            --������� ����, ������������ ����� ��� �� ����������, ������� ��������
            SELECT nvl(SUM(s.cena), 0)
            INTO   cena_
            FROM   nabor_progs n, spr_tarif_prices s, params p
            WHERE  n.fk_tarif = s.fk_tarif
            AND    n.lsk = rec_krt.lsk
            AND    p.period BETWEEN s.mg1 AND s.mg2;
            npp_ := npp_ + 1;
            --��������� �+
            --�� �������
            INSERT INTO c_charge
              (npp, lsk, usl, summa, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (0, rec_krt.lsk, usl_, cena_, NULL, 0, NULL, rec_wo_peop.tarnorm, cena_, rec_wo_peop.tarkoef, NULL);
            --��� ������
            INSERT INTO c_charge
              (npp, lsk, usl, summa, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (npp_, rec_krt.lsk, usl_, cena_, NULL, 1, NULL, rec_wo_peop.tarnorm, cena_, rec_wo_peop.tarkoef, NULL);
            CLOSE cur_wo_peop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- ������ ������, ������������� ��� �������� * vol_add
          -- �������� ��.������� (� ������� � ���)
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp = 23 THEN --#23#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            sit_    := sit_ +
                       round(rec_wo_peop.cena * rec_nabor.vol_add, 2);
            npp_    := npp_ + 1;
            summaf_ := rec_wo_peop.cena * rec_nabor.vol_add;
            summa_  := round(summaf_, 2);
            INSERT INTO c_charge
              (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, rec_nabor.vol_add, rec_wo_peop.cena, NULL, NULL);
            --��� ������
            msit_   := msit_ +
                       round(rec_wo_peop.cena * rec_nabor.vol_add, 2);
            summaf_ := rec_wo_peop.cena * rec_nabor.vol_add;
            summa_  := round(summaf_, 2);
            INSERT INTO c_charge
              (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, rec_nabor.vol_add, rec_wo_peop.cena, NULL, NULL);
            CLOSE cur_wo_peop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- ������ ������, ������������� ��� �������� * �������� * ���.�������
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp = 24 THEN --#24#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            sit_    := sit_ + round(rec_krt.opl * rec_wo_peop.cena *
                                    rec_wo_peop.tarnorm,
                                    2);
            npp_    := npp_ + 1;
            summaf_ := rec_krt.opl * rec_wo_peop.cena * rec_wo_peop.tarnorm;
            summa_  := round(summaf_, 2);
            INSERT INTO c_charge
              (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, rec_krt.opl, rec_wo_peop.cena, NULL, NULL);
            --��� ������
            msit_   := msit_ + round(rec_krt.opl * rec_wo_peop.cena *
                                     rec_wo_peop.tarnorm,
                                     2);
            summaf_ := rec_krt.opl * rec_wo_peop.cena * rec_wo_peop.tarnorm;
            summa_  := round(summaf_, 2);
            INSERT INTO c_charge
              (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, rec_krt.opl, rec_wo_peop.cena, NULL, NULL);
            CLOSE cur_wo_peop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- ������ ������, ������������� ��� �������� * �������� * ���.�������, ������ �� �� ������� �����
          IF rec_nabor.chrg1 <> 0 AND rec_krt.status not in (1) AND rec_nabor.fk_calc_tp = 32 THEN --#32#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            sit_    := sit_ + round(rec_krt.opl * rec_wo_peop.cena *
                                    rec_wo_peop.tarnorm,
                                    2);
            npp_    := npp_ + 1;
            summaf_ := rec_krt.opl * rec_wo_peop.cena * rec_wo_peop.tarnorm;
            summa_  := round(summaf_, 2);
            INSERT INTO c_charge
              (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, rec_krt.opl, rec_wo_peop.cena, NULL, NULL);
            --��� ������
            msit_   := msit_ + round(rec_krt.opl * rec_wo_peop.cena *
                                     rec_wo_peop.tarnorm,
                                     2);
            summaf_ := rec_krt.opl * rec_wo_peop.cena * rec_wo_peop.tarnorm;
            summa_  := round(summaf_, 2);
            INSERT INTO c_charge
              (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, rec_krt.opl, rec_wo_peop.cena, NULL, NULL);
            CLOSE cur_wo_peop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- ������ ������, ������������� ��� �������� * ���-�� ������ * �������� (���. ��������)
          -- �������� ��.������� (�������� ��.��.��� � ���)
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp = 26 THEN --#26#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            sit_    := sit_ + round(rec_wo_peop.cena * rec_wo_peop.tarnorm * kpr_,
                                    2);
            npp_    := npp_ + 1;
            summaf_ := rec_wo_peop.cena * rec_wo_peop.tarnorm * kpr_;
            summa_  := round(summaf_, 2);
            INSERT INTO c_charge
              (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, rec_wo_peop.tarnorm * kpr_, rec_wo_peop.cena, NULL, NULL);
            --��� ������
            msit_   := msit_ + round(rec_wo_peop.cena * rec_wo_peop.tarnorm * kpr_,
                                     2);
            summaf_ := rec_wo_peop.cena * rec_wo_peop.tarnorm * kpr_;
            summa_  := round(summaf_, 2);
            INSERT INTO c_charge
              (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, rec_wo_peop.tarnorm * kpr_, rec_wo_peop.cena, NULL, NULL);
            CLOSE cur_wo_peop;
          END IF;

          --||||||||||||||||||||||||||||||||||||||--
          -- ������ ����� ������ - ���-�� ������ * �������� (���.)
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp = 49 --AND rec_krt.status != 1-- ����� �������. �� (���.03.09.18 ��� ���.) - ����� ���, �� ������� ���.14.09.18
              THEN --#49#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            OPEN cur_prep;
            FETCH cur_prep
              INTO rec_prep;
            CLOSE cur_prep;
            sit_    := sit_ + round(rec_wo_peop.cena * rec_prep.kpr2,
                                    2);
            npp_    := npp_ + 1;
            summaf_ := rec_wo_peop.cena * rec_prep.kpr2;
            summa_  := round(summaf_, 2);
            INSERT INTO c_charge
              (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, rec_prep.kpr2, rec_wo_peop.cena, NULL, NULL);
            --��� ������
            msit_   := msit_ + round(rec_wo_peop.cena * rec_prep.kpr2,
                                     2);
            summaf_ := rec_wo_peop.cena * rec_prep.kpr2;
            summa_  := round(summaf_, 2);
            INSERT INTO c_charge
              (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, rec_prep.kpr2, rec_wo_peop.cena, NULL, NULL);
          END IF;

          --||||||||||||||||||||||||||||||||||||||--
          --�������� ���� (����������, ��� �����)
          --||||||||||||||||||||||||||||||||||||||--
          -- ������ ������, ������������� ��� �������� * ����� * �������� (�� � ����������� - ��������)
          -- �������� ��.������� (� ������� � ���) -�������, ���� ����� �������� � ������ � 23
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp = 30 THEN --#30#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            sit_    := sit_ +
                       round(rec_wo_peop.cena * rec_wo_peop.tarnorm, 2);
            npp_    := npp_ + 1;
            summaf_ := rec_wo_peop.cena * rec_wo_peop.tarnorm;
            summa_  := round(summaf_, 2);
            INSERT INTO c_charge
              (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, rec_wo_peop.tarnorm, rec_wo_peop.cena, NULL, NULL);
            --��� ������
            msit_   := msit_ +
                       round(rec_wo_peop.cena * rec_wo_peop.tarnorm, 2);
            summaf_ := rec_wo_peop.cena * rec_wo_peop.tarnorm;
            summa_  := round(summaf_, 2);
            INSERT INTO c_charge
              (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, rec_wo_peop.tarnorm, rec_wo_peop.cena, NULL, NULL);
            CLOSE cur_wo_peop;
          END IF;

          --||||||||||||||||||||||||||||||||||||||--
          -- ������ ������, ������������� ��� ����� �� ������������ ������ * ����� (������ ��� ����� �����) � ������ ��������� ������ LINKED_USL!!!
          -- ��������!!! ����� ������� �������, ����� ������ �� �����������!
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp = 34 THEN --#34#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            l_proc_nrm:=1;
            if rec_nabor.linked_usl is not null then
              for c in cur_proc_sch(rec_nabor.linked_usl) loop
                l_proc_nrm:=c.proc_nrm;
              end loop;
            end if;

            for c in cur_chrg_by_klsk(rec_nabor.parent_usl, 0) loop
              sit_    := sit_ + round(c.summa * rec_wo_peop.tarnorm,2);
              npp_    := npp_ + 1;
              summaf_ := round(l_proc_nrm * c.summa * rec_wo_peop.tarnorm,2);
              summa_  := round(summaf_, 2);
              INSERT INTO c_charge
                (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
              VALUES
                (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, null, null, NULL, NULL);
              --��� ������
              msit_   := msit_ + round(c.summa * rec_wo_peop.tarnorm,2);
              summaf_ := round(l_proc_nrm * c.summa * rec_wo_peop.tarnorm,2);
              summa_  := round(summaf_, 2);
              INSERT INTO c_charge
                (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
              VALUES
                (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, rec_krt.opl, null, NULL, NULL);
              CLOSE cur_wo_peop;
            end loop;
          END IF;

          --||||||||||||||||||||||||||||||||||||||--
          -- ������ ������, ������������� ��� ����� ������������ ������ * ����� (������ ��� ����� �����. ���)
          -- ��������!!! ����� ������� �������, ����� ������ �� �����������!
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp = 48 THEN --#48#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            l_proc_nrm:=1;
            for c in cur_chrg(rec_nabor.parent_usl, 0) loop
              select decode(rec_nabor.usl_cd, '���_���_���', '�.����', '���_���_���',
                     '�.����', '��_���_���', '��.�����.2', '��.��.���� ��', null) into l_str from dual;
              for c2 in cur_vvod_tp(l_str)
              loop
                if rec_nabor.usl_cd = '���_���_���' and c2.dist_tp=4 or
                   rec_nabor.usl_cd = '���_���_���' and c2.dist_tp=4 or
                   rec_nabor.usl_cd = '��_���_���' and c2.dist_tp=4 then

                  sit_    := sit_ + round(c.summa * rec_wo_peop.tarnorm,2);
                  npp_    := npp_ + 1;
                  summaf_ := round(c.summa * rec_wo_peop.tarnorm,2);
                  summa_  := round(summaf_, 2);
                  INSERT INTO c_charge
                    (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
                  VALUES
                    (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, null, null, NULL, NULL);
                  --��� ������
                  msit_   := msit_ + round(c.summa * rec_wo_peop.tarnorm,2);
                  summaf_ := round(c.summa * rec_wo_peop.tarnorm,2);
                  summa_  := round(summaf_, 2);
                  INSERT INTO c_charge
                    (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
                  VALUES
                    (npp_, rec_krt.lsk, usl_, summa_, summaf_, NULL, 1, NULL, rec_krt.opl, null, NULL, NULL);

                end if;
              end loop;

            end loop;
            CLOSE cur_wo_peop;
          END IF;

        END LOOP;
        CLOSE cur_nabor;
        ---------������
        --�������� ������������ ����� � ���������� � ������ �����
        IF rec_krt.corr_lg = 1 THEN
          --��������� ������������� � �������
          INSERT INTO c_charge
            (npp, lsk, usl, summa, kart_pr_id, spk_id, type, main, lg_doc_id)
            SELECT t.npp, t.lsk, t.usl, round(t.summa + CASE
                            WHEN nvl(v.summa, 0) <> 0 AND nvl(x.summa, 0) <> 0 THEN
                             t.summa * v.summa / x.summa
                            ELSE
                             0
                          END,
                          2), t.kart_pr_id, t.spk_id, 4, t.main, t.lg_doc_id
            FROM   (SELECT npp, lsk, usl, r.kart_pr_id, r.spk_id, r.main, r.lg_doc_id, SUM(summa) summa
                     FROM   c_charge r, params p
                     WHERE  type = 3
                     AND    lsk = '' || rec_krt.lsk || ''
                     GROUP  BY npp, lsk, usl, r.spk_id, r.kart_pr_id, r.main, r.lg_doc_id) t, --������
                   (SELECT lsk, usl, nvl(SUM(summa), 0) AS summa
                     FROM   c_charge r, params p
                     WHERE  type = 1
                     AND    lsk = '' || rec_krt.lsk || ''
                     GROUP  BY lsk, usl) x, -- ��� ��� ���.
                   (SELECT lsk, usl, SUM(summa) summa
                     FROM   c_change c, params p
                     WHERE  c.mgchange = p.period
                     AND    lsk = '' || rec_krt.lsk || ''
                     AND    nvl(c.proc, 0) <> 0
                     AND    to_char(c.dtek, 'YYYYMM') = p.period
                     GROUP  BY lsk, usl) v --���������
            WHERE  t.lsk = x.lsk(+)
            AND    t.usl = x.usl(+)
            AND    t.lsk = v.lsk(+)
            AND    t.usl = v.usl(+);
        ELSE
          --�� ��������� ������������� � �������
          INSERT INTO c_charge
            (npp, lsk, usl, summa, kart_pr_id, spk_id, type, main, lg_doc_id)
            SELECT npp, lsk, usl, summa, kart_pr_id, spk_id, 4, main, lg_doc_id
            FROM   c_charge t
            WHERE  t.type = 3
            AND    lsk = '' || rec_krt.lsk || '';
        END IF;

        --������� ��� ��� ���������?
        IF nvl(rec_krt.subs_ob, 0) = 1 THEN
          -- ������ �������� 11.05.2006
          -- krt.eksub1 - �������.����� �� �����
          -- krt.eksub2 - �������.�����
          -- krt.sgku - �������� ����
          --& krt.doppl - ����. ������� ��� ��������
          --�������.����� �� 1 ���

          --�������� ���������� ��� �������� + ���������
          SELECT SUM(c.summa)
          INTO   it_izm_s_
          FROM   c_change c, params p, usl u
          WHERE  c.usl = u.usl
          AND    c.mgchange = p.period
          AND    c.lsk = '' || rec_krt.lsk || ''
          AND    u.usl_subs = 1
          AND    to_char(c.dtek, 'YYYYMM') = p.period
          AND    nvl(c.proc, 0) <> 0;

          IF nvl(rec_krt.subs_cor, 0) <> 0 AND
             sit_ + nvl(it_izm_s_, 0) <> 0 THEN
            -- ������������ �������������
            --�������� ���������� ��� �������� + ���������
            sit_s_ := sit_ + nvl(it_izm_s_, 0);

            subs_       := nvl(rec_krt.subs_cor, 2);
            koeff_rasp_ := subs_ / sit_s_;
            INSERT INTO c_charge
              (npp, lsk, usl, summa, kart_pr_id, spk_id, type, test_opl, test_cena, test_tarkoef, test_spk_koef)
              SELECT MAX(v.npp), v.lsk, v.usl, round(SUM(v.summa *
                                koeff_rasp_),
                            2), NULL, NULL, 2, NULL, NULL, NULL, NULL
              FROM   (SELECT t.npp, t.lsk, t.usl, t.summa
                       FROM   c_charge t, usl u
                       WHERE  t.lsk = '' || rec_krt.lsk || ''
                       AND    t.type = 1
                       AND    t.usl = u.usl
                       AND    u.usl_subs = 1 --����� ������ ����������
                       UNION ALL
                       SELECT NULL, t.lsk, t.usl, -1 * t.summa
                       FROM   c_charge t, usl u
                       WHERE  t.lsk = '' || rec_krt.lsk || ''
                       AND    t.type = 3
                       AND    t.usl = u.usl
                       AND    u.usl_subs = 1 --�������� ������ (��� �����������!!!)
                       UNION ALL
                       SELECT NULL, c.lsk, c.usl, c.summa
                       FROM   c_change c, params p, usl u
                       WHERE  c.usl = u.usl
                       AND    c.mgchange = p.period
                       AND    c.lsk = '' || rec_krt.lsk || ''
                       AND    u.usl_subs = 1
                       AND    to_char(c.dtek, 'YYYYMM') = p.period --���������� ���������
                       AND    nvl(c.proc, 0) <> 0) v
              GROUP  BY v.lsk, v.usl;
            SELECT subs_ - SUM(t.summa)
            INTO   chk_subs_corr_
            FROM   c_charge t
            WHERE  t.lsk = '' || rec_krt.lsk || ''
            AND    type = 2;
            IF chk_subs_corr_ > 0.10 THEN
              --������ ������ ������ - expception
              raise_application_error(-20001,
                                      '��������! �� �������� ' ||
                                      rec_krt.lsk ||
                                      ' ��������� �� ���������� ���������� ������������� ��������. ���������.');
            END IF;
            INSERT INTO c_charge
              (npp, lsk, usl, summa, kart_pr_id, spk_id, type, test_opl, test_cena, test_tarkoef, test_spk_koef)
              SELECT t.npp, t.lsk, t.usl, chk_subs_corr_, NULL, NULL, 2, NULL, NULL, NULL, NULL
              FROM   c_charge t, usl u
              WHERE  t.lsk = '' || rec_krt.lsk || ''
              AND    t.type = 0
              AND    t.usl = u.usl
              AND    u.usl_subs = 1
              AND    rownum = 1;
          END IF;

          IF rec_krt.subs_cur = 1 AND kpr_ <> 0 AND
             nvl(rec_krt.eksub2, 0) <> 0 THEN
            --������� ������� ��������
            SELECT SUM(summa)
            INTO   it_izm_s_
            FROM   c_change c, params p
            WHERE  c.lsk = '' || rec_krt.lsk || ''
            AND    to_char(c.dtek, 'YYYYMM') = p.period
            AND    nvl(c.proc, 0) <> 0;
            sit_s_ := sit_ + nvl(it_izm_s_, 0);

            sov_doh1_ := nvl(rec_krt.eksub1, 2) / kpr_;

            koef_doh_ := sov_doh1_ / nvl(rec_krt.eksub2, 0);

            IF koef_doh_ < 1 THEN
              koef_subs_ := 1;
            ELSIF koef_doh_ >= 1 AND koef_doh_ <= 1.5 THEN
              koef_subs_ := 1.5;
            ELSIF koef_doh_ > 1.5 AND koef_doh_ <= 1.8 THEN
              koef_subs_ := 1.8;
            ELSIF koef_doh_ > 1.8 AND koef_doh_ <= 2.0 THEN
              koef_subs_ := 2;
            ELSIF koef_doh_ > 2 AND koef_doh_ < 3 THEN
              koef_subs_ := 3;
            ELSIF koef_doh_ >= 3 THEN
              koef_subs_ := 4;
            ELSE
              koef_subs_ := 0;
            END IF;

            IF koef_subs_ = 1 THEN
              mdd_ := 5;
            ELSIF koef_subs_ = 1.5 THEN
              mdd_ := 7;
            ELSIF koef_subs_ = 1.8 THEN
              mdd_ := 10;
            ELSIF koef_subs_ = 2 THEN
              mdd_ := 15;
            ELSIF koef_subs_ = 3 THEN
              mdd_ := 20;
            ELSIF koef_subs_ = 4 THEN
              mdd_ := 22;
            ELSE
              mdd_ := 0;
            END IF;

            poprav_  := sov_doh1_ / nvl(rec_krt.eksub2, 0);
            koef_lg_ := sit_ / msit_;
            sgku_1_ := rec_krt.sgku * kpr_ + rec_krt.doppl * CASE
                         WHEN rec_krt.opl - pl_norma_ > 20 THEN
                          20
                         ELSE
                          rec_krt.opl - pl_norma_
                       END;
            IF koef_subs_ = 1 THEN
              sum_subsid_ := sgku_1_ * koef_lg_ -
                             mdd_ / 100 * nvl(rec_krt.eksub1, 2) * poprav_;
            ELSIF koef_subs_ >= 1.5 AND koef_subs_ <= 4 THEN
              sum_subsid_ := sgku_1_ * koef_lg_ -
                             mdd_ / 100 * nvl(rec_krt.eksub1, 2);
            ELSE
              sum_subsid_ := 0;
            END IF;

            --������������ �������� ��������
            IF sum_subsid_ >= sit_s_ THEN
              subs_ := sit_s_;
            ELSIF sum_subsid_ > 0 AND sum_subsid_ < sit_s_ THEN
              subs_ := sum_subsid_;
            ELSE
              subs_ := 0;
            END IF;

            koeff_rasp_ := subs_ / sit_s_;
            INSERT INTO c_charge
              (lsk, usl, summa, kart_pr_id, spk_id, type, test_opl, test_cena, test_tarkoef, test_spk_koef)
              SELECT v.lsk, v.usl, round(SUM(v.summa * koeff_rasp_), 2), NULL, NULL, 2, NULL, NULL, NULL, NULL
              FROM   (SELECT t.lsk, t.usl, t.summa
                       FROM   c_charge t, usl u
                       WHERE  t.lsk = '' || rec_krt.lsk || ''
                       AND    t.type = 0
                       AND    t.usl = u.usl
                       AND    u.usl_subs = 1
                       UNION ALL
                       SELECT lsk, usl, summa
                       FROM   c_change c, params p
                       WHERE  c.mgchange = p.period
                       AND    c.lsk = '' || rec_krt.lsk || ''
                       AND    to_char(c.dtek, 'YYYYMM') = p.period
                       AND    nvl(c.proc, 0) <> 0) v
              GROUP  BY v.lsk, v.usl;
          END IF;
        END IF;
/*        IF init.get_date > to_date('15082014', 'DDMMYYYY') THEN
          ROLLBACK;
          raise_application_error(-20001, 'Licenses has expired');
        END IF;
        --�� ������ 30 -�� ������ (����� �������� ������ �� sys.v_$database)
        IF rec_krt.lsk / 30 - round(rec_krt.lsk / 30) = 0 THEN
          IF (dbid_ = 3799038777 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2618192783 AND --��� ���
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 1314248482 AND --�����
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2606094080 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 3810881306 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2554820419 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 3814334184 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2556573722 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 3834602444 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 344733707 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 377737443 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2572869365 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2561829081 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2586286055 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2585073008 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 1230886519 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 1236135987 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2623801154 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2593178931 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 1279259503 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2652117642 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2654644677 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2632934097 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2657406262 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 1343879475 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2660587686 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2654644677 AND
             init.get_date < to_date('15082014', 'DDMMYYYY'))  OR
             (dbid_ =  1371098296 AND
             init.get_date < to_date('15082014', 'DDMMYYYY'))
              THEN
            NULL;
          ELSE
            raise_application_error(-20001, 'Licenses problem!' || dbid_);
            ROLLBACK;
          END IF;
        END IF; */

        IF iscommit_ = 2 THEN
          --���� ����� ������������� ������ - ������
          COMMIT;
        END IF;

      END IF;

      /* ����� ������ ��� ����������:
      select a.*, b.*, nvl(a.summa,0)-nvl(b.summa,0) as diff from

      (select t.lsk, sum(t.summa) as summa
       from KMP_C_CHARGE t where t.type=1
      group by t.lsk) a
      full join
      (select t.lsk, sum(t.summa) as summa
       from KMP_C_CHARGE_AFTER t where t.type=1
      group by t.lsk) b
      on a.lsk=b.lsk
      where nvl(a.summa,0)<>nvl(b.summa,0)
      and abs(nvl(a.summa,0)-nvl(b.summa,0))>0.1
      */
      -- ��������� ������� ����������, ��� ��� ���, �����������, ���� �������� ���������� usl_round
 for c in (select a.usl, nvl(round(sum(a.price) over (partition by a.lsk) * a.opl,2),0) as summa, -- ��������� �����
           nvl(sum(a.summa_fact) over (partition by a.lsk),0) as summa_fact, a.rd -- ����������� �����, �� ����������
           from (
          select u.uslm, u.usl,
                 decode(lead(u.uslm, 1) over (order by u.uslm, u.usl), u.uslm, 0, 1) * t.test_cena as price, -- ������ ��������, ���� ��� ������ ������ �� uslm
                  t.summa as summa_fact, k.lsk, k.opl, t.rd
                  from scott.kart k,
                  (select s.test_cena, s.usl, max(s.rowid) as rd, sum(s.summa) as summa from
                     scott.c_charge s, scott.usl u2 where s.usl=u2.usl and s.lsk=rec_krt.lsk and s.type=1
                  group by s.test_cena, s.usl) t
                  , scott.usl u, scott.usl_round r
                  where t.usl=u.usl and t.usl=r.usl
                  and k.lsk=rec_krt.lsk and k.reu=r.reu
                  and t.summa > 0) a
                  order by a.usl -- �� ������ �������! ����� ����������� ������ �� ���� ������, �� �������� �� ����� ����������
                  ) loop
        if abs(c.summa-c.summa_fact) <= 0.05 then
          -- �������� type=1
          update scott.c_charge t set t.summa=t.summa+(c.summa-c.summa_fact) where t.rowid=c.rd
            returning t.usl into l_usl_round;
          if sql%rowcount != 1 then
            Raise_application_error(-20000, '1.����������� ���.�� ����������� �������, �� ���.�����:'||rec_krt.lsk);
          end if;
          -- �������� type=0
          update scott.c_charge t set t.summa=t.summa+(c.summa-c.summa_fact) where t.usl = l_usl_round
            and t.lsk=rec_krt.lsk
            and t.type=0 and rownum=1;
          if sql%rowcount != 1 then
            Raise_application_error(-20000, '2.����������� ���.�� ����������� �������, �� ���.�����:'||rec_krt.lsk);
          end if;
        else
          Raise_application_error(-20000, '������������ ����������='
            ||to_char(c.summa - c.summa_fact)||', �� ���.�����:'||rec_krt.lsk);
          null;
        end if;
        exit;
      end loop;

      --����� ����� �� ������� ������
    END LOOP;

    IF var_ = 1 THEN
      CLOSE cur_krt;
    ELSIF var_ = 2 THEN
      CLOSE cur_krt2;
    ELSIF var_ = 3 THEN
      CLOSE cur_krt3;
    ELSIF var_ = 4 THEN
      CLOSE cur_krt4;
    ELSIF var_ = 5 THEN
      CLOSE cur_krt5;
    END IF;

    -- ���� ����������, ���� ���������� �������� ���.06.07.2018 - �� ������� ����� ����� ��� ����������, ����� �� � ��� � ����� ��� ���������
    -- � ��� �������� 06.07.2018
    IF is_round_charge_ = 1 THEN
      IF var_ = 1 THEN
        --�� ������ �.�.
        FOR t IN (SELECT MAX(c.id) AS id, round(SUM(summaf), 2) - SUM(summa) AS diff
                  FROM   c_charge c
                  WHERE  c.lsk BETWEEN '' || lsk_ || '' AND
                         '' || lsk_end_ || ''
                  AND    c.type IN (0, 1)
                  GROUP  BY c.lsk, c.usl, c.type
                  HAVING round(SUM(summaf), 2) - SUM(summa) <> 0) LOOP
          UPDATE c_charge r
          SET    r.summa = nvl(r.summa, 0) + t.diff
          WHERE  r.id = t.id;
        END LOOP;
      ELSIF var_ = 2 THEN
        --�� 1 �.�.
        FOR t IN (SELECT MAX(c.id) AS id, round(SUM(summaf), 2) - SUM(summa) AS diff
                  FROM   c_charge c
                  WHERE  c.lsk = '' || lsk_ || ''
                  AND    c.type IN (0, 1)
                  GROUP  BY c.lsk, c.usl, c.type
                  HAVING round(SUM(summaf), 2) - SUM(summa) <> 0) LOOP
          UPDATE c_charge r
          SET    r.summa = nvl(r.summa, 0) + t.diff
          WHERE  r.id = t.id;
        END LOOP;
      ELSIF var_ = 3 THEN
        --�� ���������� house_id ����
        FOR t IN (SELECT MAX(c.id) AS id, round(SUM(summaf), 2) - SUM(summa) AS diff
                  FROM   c_charge c, kart k
                  WHERE  k.lsk = c.lsk
                  AND    k.house_id = house_id_
                  AND    c.type IN (0, 1)
                  GROUP  BY c.lsk, c.usl, c.type
                  HAVING round(SUM(summaf), 2) - SUM(summa) <> 0) LOOP
          UPDATE c_charge r
          SET    r.summa = nvl(r.summa, 0) + t.diff
          WHERE  r.id = t.id;
        END LOOP;
      ELSIF var_ = 4 THEN
        --�� ����� �����
        FOR t IN (SELECT MAX(c.id) AS id, round(SUM(summaf), 2) - SUM(summa) AS diff
                  FROM   c_charge c, kart k
                  WHERE  k.lsk = c.lsk
                  AND    c.type IN (0, 1)
                  GROUP  BY c.lsk, c.usl, c.type
                  HAVING round(SUM(summaf), 2) - SUM(summa) <> 0) LOOP
          UPDATE c_charge r
          SET    r.summa = nvl(r.summa, 0) + t.diff
          WHERE  r.id = t.id;
        END LOOP;
      ELSIF var_ = 5 THEN
        --�� ���������� p_vvod �����
        FOR t IN (SELECT MAX(c.id) AS id, round(SUM(summaf), 2) - SUM(summa) AS diff
                  FROM   c_charge c, table(t_nabor) n
                  WHERE  n.lsk = c.lsk
                  AND    n.fk_vvod = p_vvod
                  AND    c.type IN (0, 1)
                  GROUP  BY c.lsk, c.usl, c.type
                  HAVING round(SUM(summaf), 2) - SUM(summa) <> 0) LOOP
          UPDATE c_charge r
          SET    r.summa = nvl(r.summa, 0) + t.diff
          WHERE  r.id = t.id;
        END LOOP;
      END IF;
    END IF;
    ---

    IF iscommit_ = 1 THEN
      --���� ����� ������ - ������
      COMMIT;
    END IF;

    RETURN cnt_lsk_;



  END gen_charges;


END c_charges;
/

