CREATE OR REPLACE PACKAGE BODY SCOTT.c_charges IS

  TYPE rec_kpr IS RECORD(
    kpr    kart.kpr%TYPE,
    kpr_ot kart.kpr_ot%TYPE,
    kpr_wr kart.kpr_ot%TYPE);

  FUNCTION get_upd_tab RETURN tab_rec_states
    PARALLEL_ENABLE
    PIPELINED IS
  BEGIN
    --функция пока не используется (не нашла применение) 29.04.2011
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
    --для основной услуги
    SELECT u.cd, u.usl_p, u.usl_empt
      FROM usl u WHERE u.usl = usl_;
    rec_usl c%ROWTYPE;
    --для канализования
    cursor c2 is
    SELECT u.cd, u2.cd as cd2, u3.cd as cd3
      FROM usl u, usl u2, usl u3 WHERE u.cd = 'канализ'
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
    --просто узнать текущие показания счетчика
      IF rec_usl.cd = 'х.вода' THEN
        --последние показания по х.воде (обраб в триггере)
        SELECT k.phw
        INTO   cnt2_
        FROM   kart k
        WHERE  k.lsk = lpad(lsk_, 8, '0');
      ELSIF rec_usl.cd = 'г.вода' THEN
        --последние показания по г.воде (обраб в триггере)
        SELECT k.pgw
        INTO   cnt2_
        FROM   kart k
        WHERE  k.lsk = lpad(lsk_, 8, '0');
      ELSIF rec_usl.cd = 'эл.энерг.2' THEN
        --последние показания по эл.эн. (обраб в триггере)
        SELECT k.pel
        INTO   cnt2_
        FROM   kart k
        WHERE  k.lsk = lpad(lsk_, 8, '0');
      END IF;
      RETURN cnt2_;
    ELSE
      --установить текущие показания счетчика и расчитать начисление

      --начисление до ввода кубов
      cnt2_ := gen_charges(lpad(lsk_, 8, '0'),
                           lpad(lsk_, 8, '0'),
                           NULL,
                           NULL,
                           0,
                           0);
      IF rec_usl.cd IN ('х.вода', 'г.вода') THEN
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
                 --свыше с.н.
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
                 --без проживающих
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
                 --канализ.
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
      ELSIF rec_usl.cd IN ('эл.энерг.2') THEN
        --начисление после ввода киловат, разница
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
                 --свыше с.н.
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

      IF rec_usl.cd IN ('х.вода') THEN
        --последние показания по х.воде (обраб в триггере)
        UPDATE kart k SET k.phw = cnt_ WHERE k.lsk = lpad(lsk_, 8, '0');
      ELSIF rec_usl.cd IN ('г.вода') THEN
        --последние показания по г.воде (обраб в триггере)
        UPDATE kart k SET k.pgw = cnt_ WHERE k.lsk = lpad(lsk_, 8, '0');
      ELSIF rec_usl.cd IN ('эл.энерг.2') THEN
        --последние показания по эл.эн. (обраб в триггере)
        UPDATE kart k SET k.pel = cnt_ WHERE k.lsk = lpad(lsk_, 8, '0');
      END IF;

      cnt2_ := gen_charges(lpad(lsk_, 8, '0'),
                           lpad(lsk_, 8, '0'),
                           NULL,
                           NULL,
                           0,
                           0);

      IF rec_usl.cd IN ('х.вода', 'г.вода') THEN
        --начисление после ввода кубов, разница
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
                 --свыше с.н.
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
                 --без проживающих
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
                 --канализ.
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

      ELSIF rec_usl.cd IN ('эл.энерг.2') THEN
        --начисление после ввода киловат, разница
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
                 --свыше с.н.
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
    --глобальный перерасчет начисления
    IF nvl(p_lvl, 0) = 0 THEN
      --по Городу
      --все лицевые с промежуточным коммитом, по каждому лицевому...

      l_cnt := c_charges.gen_charges(NULL, NULL, NULL, NULL, 2, 1);


    --ПОПРОБУЮ НА JOB-ах
  --запускаем 3 JOB-a!
  --разделил весьма грубо на 3 части
/*  i:=1;
  --создать JOB
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
          logger.log_(null, ''Ошибка из JOB-начисления: ''||SQLERRM);
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


  --ожидать выполнения JOB
  while true
  loop
    for c in (select t.*
     from user_jobs t where t.job in (l_job1, l_job2, l_job3)
      and t.FAILURES <> 0)
    loop
         --удалить Job-ы
         for c2 in (select t.*
         from user_jobs t where t.job in (l_job1, l_job2, l_job3)
          )
        loop
          DBMS_JOB.REMOVE(c2.job);
          COMMIT;
        end loop;
        Raise_application_error(-20000, 'Ошибка #1 во время начисления (см.Log)!');
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
      --по Фонду
      --начисление формировать - домами
      FOR c IN (SELECT * FROM c_houses) LOOP
        l_cnt := c_charges.gen_charges(NULL, NULL, c.id, NULL, 2, 1);
      END LOOP;
    ELSIF nvl(p_lvl, 0) = 2 THEN
      --по УК
      --начисление формировать - домами
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
      --по дому
      --ёпт, формировался сразу весь РЭУ!!! Исправил. Ред 01.02.2015
--      FOR c IN (SELECT * FROM c_houses t WHERE t.reu = p_reu) LOOP
      l_cnt := c_charges.gen_charges(NULL, NULL, house_id_, NULL, 1, 1);
--      END LOOP;
    END IF;
  END;

  -- обертка для Java
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

-- JAVA обертка
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

    --коллекция для загрузки наборов
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
      exists (select * from nabor n where k.lsk=n.lsk and n.fk_vvod=p_vvod); --Здесь нельзя использовать коллекцию t_nabor, она еще не определена!

    rec_krt cur_krt%ROWTYPE;

    --курсор для расчета по сложной схеме (с учетом льгот)
    --услуги по лицевому, по соц норме
    CURSOR cur_nabor IS
      SELECT n.usl, n.fk_calc_tp, n.usl_p, n.usl_p AS usl_h, --ред.27.12.2010
             nvl(decode(n.sptarn,
                         0,
                         nvl(s.koeff, 1) * nvl(n.koeff, 0),
                         1,
                         nvl(n.norm, 0),
                         2,
                         nvl(n.koeff, 0) * nvl(n.norm, 0),
                         3,
                         nvl(n.koeff, 0) * nvl(n.norm, 0)),
                  0) AS chrg1, --признак начисления по соц норме, chrg1
             n.fk_tarif, nvl(c.chrg2, 0) AS chrg2, --признак начисления свыше соц.нормы, chrg2
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

    --услуга
    usl_ VARCHAR2(3);
    --параметры
    CURSOR cur_params IS
      SELECT param, message, ver, period, agent_uptime, mess_hint, period_pl, subs_ob, id, period_debits, dt_otop1, dt_otop2, part, cnt_sch, kan_sch, sv_soc, state_base_, org_var, splash, gen_exp_lst, kart_ed1, auto_sign, find_street, penya_month, corr_lg, recharge_bill, show_exp_pay, bill_pen, penya_var, nvl(is_fullmonth,
                  0) AS is_fullmonth, wait_ver
      FROM   params;
    rec_params cur_params%ROWTYPE;

    --кол-во проживающих (с учетом вр.зарег. и вр.отстут.)
    kpr_ NUMBER;
    -- кол-во проживающих (для расценок) - убрать !
    --kpr_price_ NUMBER;

    l_usl_round usl.usl%type;
    --курсор для расчета по упрощенной схеме (без учета льгот)
    CURSOR cur_wo_peop(p_usl in usl.usl%type  --если не заполнено p_usl, возьмётся usl_
      ) IS
      SELECT nvl(s.koeff, 1) * nvl(n.koeff, 0) AS tarkoef, nvl(n.norm, 0) AS tarnorm,
                    CASE WHEN rec_krt.status = 9 THEN 0 --Арендаторы - цена = 0
                           ELSE
                    round(nvl(s.koeff, 1) * nvl(n.koeff, 0) *
                     decode(u.sptarn, 3, nvl(n.norm, 0), 1) * --расценка для кв.с проживающими
                     nvl(e2.summa, e.summa),
                     2)
                   END AS cena,
                   CASE WHEN rec_krt.status = 9 THEN 0 --Арендаторы - цена = 0
                           ELSE
                    round(nvl(s.koeff, 1) * nvl(n.koeff, 0) *
                     decode(u.sptarn, 3, nvl(n.norm, 0), 1) * --расценка для кв.с без проживающих (если есть расценка)
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
      AND    n.usl = e.usl(+) --базовые расценки
      AND    n.usl = e2.usl(+) --расценки Ресурсоснабжающей
      AND    n.org = e2.fk_org(+)
      and    n.fk_vvod=m.id(+)
      AND    e.fk_org IS NULL
      AND    n.usl = e2.usl(+) --расценки УК
      AND    nvl(p_usl, usl_) = s.usl(+)
      AND    k.kfg = s.id(+)
      AND    n.usl = u.usl
      AND    n.usl = nvl(p_usl, usl_);
    rec_wo_peop cur_wo_peop%ROWTYPE;
    rec_wo_peop2 cur_wo_peop%ROWTYPE;

    --курсор для расчета по упрощенной схеме (без учета льгот) для горячей воды! ред.18.01.2018
    CURSOR cur_wo_peop_gw(p_usl in usl.usl%type) IS
      SELECT nvl(n.koeff, 0) AS tarkoef, nvl(n.norm, 0) AS tarnorm,
                    CASE WHEN rec_krt.status = 9 THEN 0 --Арендаторы - цена = 0
                           ELSE
                    round(nvl(n.koeff, 0) *
                     decode(u.sptarn, 3, nvl(n.norm, 0), 1) * --расценка для кв.с проживающими
                     nvl(e2.summa, e.summa),
                     2)
                   END AS cena,
                   CASE WHEN rec_krt.status = 9 THEN 0 --Арендаторы - цена = 0
                           ELSE
                    round(nvl(n2.koeff, 0) *
                     decode(u.sptarn, 3, nvl(n2.norm, 0), 1) * --расценка для кв. 0 проживающих (если есть расценка)
                     nvl(e2.summa3, e.summa3),
                     2)
                   END AS cena_for_empty
      FROM   kart k join nabor n on k.lsk = '' || rec_krt.lsk || '' and k.lsk=n.lsk and n.usl=nvl(p_usl, usl_)
             join usl u on n.usl=u.usl
             left join prices e on n.usl=e.usl and e.fk_org is null  -- базовые расценки
             left join prices e2 on n.usl=e2.usl and n.org=e2.fk_org -- расценки Ресурсоснабжающей
             left join nabor n2 on k.lsk=n2.lsk and u.usl_empt=n2.usl; -- услуга 0 прожив.
    rec_wo_peop_gw cur_wo_peop_gw%ROWTYPE;

    CURSOR cur_memof IS
      SELECT * FROM load_memof;
    rec_memof cur_memof%ROWTYPE;

    --объемы при наличии проживающих и отсутствии, а так же по норме и свыше
    cursor cur_charge_prep(p_usl in usl.usl%type,  --если не заполнено p_usl, возьмётся usl_
                           p_lsk in kart.lsk%type --по указанному л.с.
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
        order by a.empty, a.sch; --order by - не менять, влияет на расчёт!
    --кол-во проживающих, не глядя на счетчики
    cursor cur_charge_prep_kpr is
    select
        sum(t.kpr) as kpr,
        sum(t.kprz) as kprz,
        sum(t.kpro) as kpro
        from c_charge_prep t
        where t.lsk=rec_krt.lsk
        and t.usl=usl_ and t.tp=1;

    --объемы при наличии проживающих и отсутствии, а так же по норме и свыше
    --по списку услуг p_list_cd_usl - список услуг, через запятую
    --например 'х.вода,г.вода'
    --regexp_instr(l_str_tp, '8[,]{1,}',1) <> 0 (regexp ищет первую цифру '8' в строке, с необязательной запятой
    cursor cur_charge_prep_usl_cd(p_list_usl_cd in varchar2) is
    select a.vol, a.sch, a.vol_nrm, a.vol_sv_nrm,
      a.empty, --a.kpr, a.kprz, a.kpro, нельзя здесь получать кол-во прожив, так как оно будет складываться вместе!
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
        order by a.empty, a.sch; --order by - не менять, влияет на расчёт! (сперва не пустая кв, потом пустая)

    -- курсор для поиска информации по k_lsk (по всем привязанным к нему лс), например для канализования для РСО счетов (ред.28.09.2018)
    cursor cur_charge_prep_usl_cd_by_klsk(p_list_usl_cd in varchar2) is
    select a.vol, a.sch, a.vol_nrm, a.vol_sv_nrm,
      a.empty, --a.kpr, a.kprz, a.kpro, нельзя здесь получать кол-во прожив, так как оно будет складываться вместе!
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
        order by a.empty, a.sch; --order by - не менять, влияет на расчёт! (сперва не пустая кв, потом пустая)

    --вернуть тип распределения по вводу, по услуге
    cursor cur_vvod_tp(p_usl_cd in varchar2) is
      select d.dist_tp from c_vvod d, nabor n, usl u
        where d.id=n.fk_vvod and u.cd=p_usl_cd
        and n.lsk=rec_krt.lsk and n.usl=u.usl;

    --вернуть тип распределения по вводу, по услуге
    cursor cur_vvod_tp2(p_usl_cd in varchar2) is
      select d.dist_tp from c_vvod d, usl u
        where d.usl=u.usl and u.cd=p_usl_cd and d.house_id=rec_krt.house_id;

    --кол-во прожив. для расчета соцнормы,
    --объем по нормативу,
    --объем по счетчику,
    --кол-во прожив. по норме (коэфф)
    --кол-во прожив. по сч. (коэфф)
    cursor cur_prep is
    select sum(decode(t.tp, 2, t.kpr, 0)) as nrm_kpr,
           sum(case when t.tp=1 then t.vol
                    else 0
                    end) as vol, --общий объем
           sum(case when t.tp=1 and t.sch=0 then t.vol
                    else 0
                    end) as nrm_vol, --нормативный объем
           sum(case when t.tp=1 and t.sch=1 then t.vol
                    else 0
                    end) as sch_vol, --обем по счетчикам
           sum(case when t.tp=1 then t.kpr
                    else 0 end) as kpr, --общее кол-во прожив
           sum(case when t.tp=1 and t.sch=0 then t.kpr
                    else 0
                    end) as kf_kpr, --кол-во прожив по нормативу
           sum(case when t.tp=1 and t.sch=1 then t.kpr
                    else 0
                    end) as kf_kpr_sch, --кол-во прожив по счетчику
           sum(t.kpr2) as kpr2 --кол-во прожив. с учётом всего, В.О.,В.З. и т.п. (для очистки сделал...) 07.08.2015
        from c_charge_prep t
        where t.lsk=rec_krt.lsk and t.usl=usl_ and t.tp in (1,2);
    rec_prep cur_prep%ROWTYPE;

    -- начисление по услуге в виде суммы p_tp_sch - наличие счетчика 1-да 0-нет
    -- для услуги по повыш.коэфф
    cursor cur_chrg(p_usl in usl.usl%type, p_tp_sch in number) is
      select sum(t.summa) as summa from c_charge t, usl u
         where t.lsk=rec_krt.lsk and nvl(t.sch,0)=p_tp_sch
         and t.usl=u.usl
         and t.type=1
         and exists (select * from usl u2 -- выбрать все подуслуги
             where u2.usl=p_usl and u2.uslm=u.uslm);

    -- начисление по услуге в виде суммы p_tp_sch - наличие счетчика 1-да 0-нет.
    -- для услуги по повыш.коэфф
    -- по klsk, для РСО счетов
    cursor cur_chrg_by_klsk(p_usl in usl.usl%type, p_tp_sch in number) is
      select sum(t.summa) as summa from kart k, c_charge t, usl u
         where k.lsk=t.lsk and k.k_lsk_id=rec_krt.k_lsk_id and nvl(t.sch,0)=p_tp_sch
         and t.usl=u.usl
         and t.type=1
         and exists (select * from usl u2 -- выбрать все подуслуги
             where u2.usl=p_usl and u2.uslm=u.uslm);
    rec_chrg cur_chrg%ROWTYPE;

    -- процент наличия объема по счетчику / нормативу в периоде, по услуге
    -- обычно используется для повышающих коэфф ОДН
    -- если 0 объем, то счетчик=0 норматив=0
    cursor cur_proc_sch(p_usl in usl.usl%type) is
      select case when nvl(a.vol,0) <> 0 then a.vol_sch/a.vol else 0 end as proc_sch,
             case when nvl(a.vol,0) <> 0 then a.vol_nrm/a.vol else 0 end as proc_nrm
      from (
      select sum(decode(t.sch, 1, t.test_opl)) as vol_sch,
             sum(decode(t.sch, 0, t.test_opl)) as vol_nrm,
             sum(t.test_opl) as vol
       from c_charge t, usl u where t.lsk=rec_krt.lsk and t.type=1
           and t.usl=u.usl
           and exists (select * from usl u2 -- выбрать все подуслуги
               where u2.usl=p_usl and u2.uslm=u.uslm)
               ) a;
    -- процент наличия объема по счетчику / нормативу в периоде, по услуге
    -- обычно используется для повышающих коэфф ОДН
    -- если 0 объем, то счетчик=0 норматив=0
    cursor cur_proc_sch_by_klsk(p_usl in usl.usl%type) is
      select case when nvl(a.vol,0) <> 0 then a.vol_sch/a.vol else 0 end as proc_sch,
             case when nvl(a.vol,0) <> 0 then a.vol_nrm/a.vol else 0 end as proc_nrm
      from (
      select sum(decode(t.sch, 1, t.test_opl)) as vol_sch,
             sum(decode(t.sch, 0, t.test_opl)) as vol_nrm,
             sum(t.test_opl) as vol
       from kart k, c_charge t, usl u where k.lsk=t.lsk and k.k_lsk_id=rec_krt.k_lsk_id and t.type=1
           and t.usl=u.usl
           and exists (select * from usl u2 -- выбрать все подуслуги
               where u2.usl=p_usl and u2.uslm=u.uslm)
               ) a;

--    rec_sch cur_sch%ROWTYPE;
    --соц.норма на проживающего
    socn_ NUMBER;
    --общая площадь, для расчета
    opl_ NUMBER;
    --общая площадь, для расчета, сохраняем
    opl_save_ NUMBER;
    --площадь на проживающего, для расчета
    opl_man_ NUMBER;
    --площадь свыше соц.нормы
    opl_sv_ NUMBER;

    --расход по вводам (для канализ) (УСТАРЕВШ, для Полыс)
    hv_kub_ NUMBER;
    --расход по вводам (для канализ) (УСТАРЕВШ, для Полыс)
    gv_kub_ NUMBER;

    --общий расход по холодной воде
    hv_ NUMBER;

    socn_kub_ NUMBER;
    --расход холодной воды на проживающего, для расчета
    hv_man_ NUMBER;
    --х.в. свыше соц.нормы
    hv_sv_ NUMBER;
    --общий расход по горячей воде
    gv_ NUMBER;

    --электроэнергия
    el_ number;
    --электроэнергия итог (может не нужна)
    el_kan_ number;

    --расход горячей воды на проживающего, для расчета
    gv_man_ NUMBER;
    --г.в. свыше соц.нормы
    gv_sv_ NUMBER;
    --общий расход по канализованию
    kan_       NUMBER;
    saved_kan_ NUMBER;
    --расход канализования на проживающего, для расчета
    kan_man_ NUMBER;
    hv_kan_  NUMBER;
    gv_kan_  NUMBER;

    --объём, посчитанный по нормативному начислению (разделение для статистики)
    hv_kan_nrm_ NUMBER;
    --объём, посчитанный по начислению с прибором учета
    hv_kan_sch_ NUMBER;

    gv_kan_nrm_ NUMBER;
    gv_kan_sch_ NUMBER;
    hv_kan_add_ NUMBER;
    gv_kan_add_ NUMBER;
    --кан. свыше соц.нормы
    kan_sv_ NUMBER;
    --id проживающего
    TYPE t_peoples IS TABLE OF NUMBER;
    t_peop_id t_peoples := t_peoples(NULL);
    --флаг если найден id
    exists_ NUMBER;
    --цена услуги по соц.норме
    cena_sn_ NUMBER;

    --для антенны, энергии+
    cena_ NUMBER;

    --промежуточная переменная, для хранения суммы начисления
    summa_ NUMBER;
    --промежуточная переменная, для округления начисления
    summaf_ NUMBER;

    --расход положительный или отрицательный?
    sign_kub_ NUMBER;

    --переменные субсидии
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
    --переменная для проверки субсидии
    chk_subs_corr_ NUMBER;
    --сумма начисления со льготой
    sit_ NUMBER;
    --сумма начисления со льготой и изменениями
    sit_s_ NUMBER;
    --сумма начисления без льготы
    msit_ NUMBER;
    --кол-во лицевых
    cnt_lsk_ NUMBER;
    --для прогрессбара в Директе
    cnt_10 NUMBER;
    dbid_  NUMBER;
    --№ порядковый выполнения расчёта
    npp_ NUMBER;
    --вариант использования начисления
    var_ NUMBER;
    --округлять ли начисление (параметр базы)
    is_round_charge_ NUMBER;
    --признак наличия счетчиков (ВРЕМЕННО, ДО ПЕРЕДЕЛКИ АЛГОРИТМА НАЧИСЛЕНИЯ ПО ВОДЕ (ДЛЯ РАЗДЕЛЕНИЯ В СТАТИСТИКЕ ВОДЫ ПО СЧ И НОРМЕ)
    sch_ NUMBER;
    --для сохранения расценки
    l_cena number;
    --для расчета норматива в канализовании
    l_norm number;
    l_vol number;
    --для сохранения знака объема
    l_sign number;
    --временная переменная
    l_str varchar2(128);
    -- для хранения ненужных данных)))
    l_dummy number;

    --для сохранения признака распределения c_vvod.dist_tp по родительской услуге, для использования в доначислении по ОДН
/*    l_hw_dist_tp c_vvod.dist_tp%type;
    l_gw_dist_tp c_vvod.dist_tp%type;
    l_el_dist_tp c_vvod.dist_tp%type;*/
    l_ot_dist_tp c_vvod.dist_tp%type;

    --временные переменные
    l_kpr number;
    l_kprz number;
    l_kpro number;
    l_flag number;
    i number;
    l_tmp_usl usl.usl%type;
    l_tmp_vol number;
    -- доля наличия норматива по услуге (для повыш коэфф)
    l_proc_nrm number;
    -- начисление на Java?
    l_Java_Charge number;
    l_klsk_id number;

  PROCEDURE ins_chrg2(p_vol   IN NUMBER,   --объем
                      p_cena     IN NUMBER,--цена
                      p_proc in number,     --% коэфф к объему (напр. для отопления)
                      p_usl in usl.usl%type,
                      p_sch in c_charge.sch%type, --наличие счетчика
                      p_kpr in c_charge.kpr%type, --кол-во прожив.
                      p_kprz in c_charge.kprz%type, --кол-во вр.зарег.
                      p_kpro in c_charge.kpro%type, --кол-во вр.отсут.
                      p_opl in c_charge.opl%type --площадь!
                      ) IS
    summa_  number;
    summaf_ number;
    l_proc  number;
  BEGIN
  --локальная процедура ins_chrg2
  --взамен устаревающей ins_chrg
    if p_proc is null then
      l_proc:=1;
    else
      l_proc:=p_proc;
    end if;
    IF p_vol <> 0 or p_kpr <> 0 THEN --или есть объем или есть проживающие ред. 17.10.14
      npp_ := npp_ + 1;
      --со льготой
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
      --без льготы
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
  --локальная процедура ins_chrg (УСТАРЕВАЕТ)
    IF vol_in_ * cena_ <> 0 THEN
      vol_ := vol_in_ * sign_kub_;
      npp_ := npp_ + 1;
      --со льготой
      sit_    := sit_ + round(vol_ * cena_, 2);
      summaf_ := vol_ * cena_;
      summa_  := round(summaf_, 2);
      INSERT INTO c_charge
        (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef, sch)
      VALUES
        (0, lsk_, usl_, summa_, summaf_, NULL, 0, NULL, vol_, cena_, NULL, NULL, sch_);

      --без льготы
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
    -- НАЧАЛО расчета
    l_Java_Charge := utils.get_int_param('JAVA_CHARGE');
    if l_Java_Charge=1 then
      -- вызов Java начисления - не должно использоваться, заблокировать позже!
      if lsk_ is not null then
        select k.k_lsk_id into l_klsk_id from kart k where k.lsk=lsk_;
      end if;
      l_dummy:=p_java.gen(p_tp        => 0,
                 p_house_id  => house_id_,
                 p_vvod_id   => p_vvod,
                 p_usl_id    => null,
                 p_klsk_id   => l_klsk_id,
                 p_debug_lvl => 0,
                 p_gen_dt    => nvl(init.dtek_, gdt(32,0,0)), -- не заполнен dtek_, вернуть последний день текущего периода
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
    --Устанавливаем статусы проживания
    --выполнять ДО открытия основных курсоров
    -- временно закоментировал, UPDATE для подолевого расчета 25.04.2011
    IF house_id_ IS NOT NULL THEN
      var_ := 3;
    ELSIF p_vvod IS NOT NULL THEN
      var_ := 5;
      --думаю надо выполнять данный код после перехода - прим.от 12.04.2011
    ELSIF lsk_ IS NOT NULL AND lsk_end_ IS NULL THEN
      var_ := 2;
    ELSIF lsk_ IS NOT NULL AND lsk_end_ IS NOT NULL THEN
      var_ := 1;
    ELSIF lsk_ IS NULL AND lsk_end_ IS NULL THEN
      var_ := 4;
    END IF;

    IF var_ = 1 THEN
      --по группе л.с.
      OPEN cur_krt;
    ELSIF var_ = 2 THEN
      --по 1 л.с.
      OPEN cur_krt2;
    ELSIF var_ = 3 THEN
      --по выбранному house_id дому
      OPEN cur_krt3;
    ELSIF var_ = 4 THEN
      --по всему фонду
      OPEN cur_krt4;
    ELSIF var_ = 5 THEN
      --по вводу
      OPEN cur_krt5;
    END IF;

    LOOP
      --Цикл по лицевым счетам
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


      --установить коэфф по проживающим
      c_kart.set_part_kpr(rec_krt.lsk, null, null, rec_krt.tp);

      if iscommit_=1 then
        COMMIT; --Коммит нужен - иначе проблемы с DEADLOCK!
      end if;

      --загрузить nabor в коллекцию
      if t_nabor is not null then
        t_nabor.delete;
      end if;

      select scott.rec_nabor(lsk, usl, org, koeff, norm, fk_tarif, fk_vvod, vol, vol_add, kf_kpr, sch_auto,
       nrm_kpr, kf_kpr_sch, kf_kpr_wrz, kf_kpr_wro, kf_kpr_wrz_sch, kf_kpr_wro_sch, limit, nrm_kpr2)
      bulk collect into t_nabor
      from nabor t where t.lsk=rec_krt.lsk ;

      --удаляем прежний расчёт
      DELETE FROM c_charge c WHERE c.lsk = rec_krt.lsk AND c.type in (0,1,2,3,4);--удаляем всё,
                                                                                 --кроме информац.по ОДН


      --если не закрытый лицевой счёт, то считаем
      IF rec_krt.psch NOT IN (8, 9) AND
         ((nvl(rec_krt.org_var, 0) <> 0 AND
         nvl(rec_krt.schel_dt, to_date('19000101', 'YYYYMMDD')) <=
         to_date(rec_krt.period || '15', 'YYYYMMDD') AND
         nvl(rec_krt.schel_end, to_date('29000101', 'YYYYMMDD')) >
         to_date(rec_krt.period || '15', 'YYYYMMDD')) OR
         nvl(rec_krt.org_var, 0) = 0) THEN

        cnt_lsk_ := cnt_lsk_ + 1;
        cnt_10   := cnt_10 + 1;
        --сообщение для  Директа
        IF cnt_10 = 10 AND nvl(sendmsg_, 0) = 1 THEN
          cnt_10 := 0;
          admin.send_message(lower(USER) || '-lsk:' || rec_krt.lsk);
        END IF;
        --предустановки
        sit_      := 0;
        msit_     := 0;
        pl_norma_ := 0;

        OPEN cur_nabor;
        --выбираем набор услуг по этому лицевому, по соцнорме
        LOOP
          rec_nabor:=null;
          FETCH cur_nabor
            INTO rec_nabor;
          EXIT WHEN cur_nabor%NOTFOUND;

          --выбираем проживающих по этому лицевому
          usl_ := rec_nabor.usl;

          --Для отмотки счетчиков обратно
          sign_kub_ := 1;
          --общая площадь
          opl_      := rec_krt.opl;
          opl_save_ := opl_;
          --нулим соцнорму
          socn_:=0;

          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА С РАСЦЕНКОЙ ДЛЯ ПУСТЫХ КВАРТИР
          --текущее содержание, отопление, лифт, дератиз, кап.ремонт
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (25) or --#25#33
             rec_nabor.fk_calc_tp IN (33) AND rec_krt.status <> 1 --капремонт (единый)
           THEN
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --сохранить расценку
            l_cena:=rec_wo_peop.cena;
            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --расчет для не пустой квартиры
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --расчет для пустой квартиры
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --ОКАЗЫВАЕТСЯ НАДО НУЛИТЬ
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                --if rec_krt.status <> 1 then
                --Было:для не муниципальных квартир, расценка как для пустых квартир
                --ред.21.08.14 -сделал и по муницип расенку как для пустых приватизир.
                l_cena:=rec_wo_peop.cena_for_empty;
                --end if;
                if rec_nabor2.usl is not null then
                  --есть выделенная услуга "без проживающих"
                    ins_chrg2(c.vol, l_cena, null, rec_nabor.usl_p, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                    --нет выделенной услуги "без проживающих", ставим на ту же услугу
                    ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА С РАСЦЕНКОЙ ДЛЯ ПУСТЫХ КВАРТИР
          --отопление гигакаллории #14#
          IF rec_nabor.fk_calc_tp IN (14) AND rec_krt.opl <> 0 then
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --сохранить расценку
            l_cena:=rec_wo_peop.cena;
            --сохранить для доначисления признак наличия счетчика ОДПУ
            l_ot_dist_tp:=rec_wo_peop.dist_tp;
            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --расчет для не пустой квартиры
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, c.opl);
              elsif c.empty = 1 then
                --расчет для пустой квартиры
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --ОКАЗЫВАЕТСЯ НАДО НУЛИТЬ
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
--                if rec_krt.status <> 1 then
                --Было:для не муниципальных квартир, расценка как для пустых квартир
                --ред.21.08.14 -сделал и по муницип расенку как для пустых приватизир.
                  l_cena:=rec_wo_peop.cena_for_empty;
--                end if;
                if rec_nabor2.usl is not null then
                  --есть выделенная услуга "без проживающих"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor.usl_p, c.sch, c.kpr, c.kprz, c.kpro, c.opl);
                  else
                  --нет выделенной услуги "без проживающих", ставим на ту же услугу
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, c.opl);
                end if;
              end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --текущее содержание, отопление, лифт, дератиз, упр.жил.домом, эл.энерг-2
          --УСЛУГА С СОЦНОРМОЙ И СВЫШЕ А ТАКЖЕ С РАСЦЕНКОЙ ДЛЯ ПУСТЫХ КВАРТИР
          --(ВЗАМЕН 0 и 2 УСЛУГИ! (тек.содерж, отопление, эл.энерг2) #36#)
          IF (rec_nabor.fk_calc_tp IN (36) AND rec_krt.opl <> 0) then
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --РЕШИЛ НЕ МУТИТЬ ЗДЕСЬ с РАСЦЕНКАМИ по МУНИЦИП кв. (так как только для ТСЖ эта ветка)
            --ред. 26.03.14
            --l_el_dist_tp:=rec_wo_peop.dist_tp;
            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --расчет для не пустой квартиры
                --по норме
                ins_chrg2(c.vol_nrm, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                --свыше соц.нормы
                if rec_nabor.usl_p is null then
                  --нет услуги свыше с.н., ставим на соц.н.
                  ins_chrg2(c.vol_sv_nrm, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                else
                  --есть услуга свыше с.н.
                  OPEN cur_wo_peop(rec_nabor.usl_p);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
                  ins_chrg2(c.vol_sv_nrm, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              elsif c.empty = 1 then
                --пустая квартира - пишем в услугу "без проживающих"
                if rec_nabor.usl_empt is not null then --да да, сделал так грубо))
                  OPEN cur_wo_peop(rec_nabor.usl_empt);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
                  ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor.usl_empt, c.sch, c.kpr, c.kprz, c.kpro, null);
                else
                  --нет услуги "без проживающих, ставим на св.соцнормы"
                  --свыше соц.нормы
                  if rec_nabor.usl_p is null then
                    --нет услуги свыше с.н., ставим на соц.н.
                    ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                    --есть услуга свыше с.н.
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
          -- кап.ремонт c 70 летними! #37#
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
            --УСЛУГА С СОЦНОРМОЙ И СВЫШЕ БЕЗ РАСЦЕНКИ ДЛЯ ПУСТЫХ КВАРТИР
            --ИСПОЛЬЗУЕТСЯ в Полыс, в ТСЖ
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (3) THEN --#3#
            --сначала по нормативу считаем (это НЕ в любом случае идёт по соц.норме, например если
            --распределится по дому много)
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

            --сколько кубов по соцнорме допустимо
            socn_kub_ := round(rec_prep.nrm_kpr * rec_wo_peop.tarnorm, 3);
            hv_kan_nrm_ := rec_prep.nrm_vol; --расход по х.в. для канализ.
            --счетчики по х.в.
            hv_kan_sch_ := rec_prep.sch_vol; --расход по х.в. для канализ.
            --общий расход
            hv_ := hv_kan_nrm_ + hv_kan_sch_;

            --Если расход отрицательный то...
            IF hv_ >= 0 THEN
              sign_kub_ := 1;
            ELSE
              sign_kub_ := -1;
            END IF;
            hv_ := abs(hv_);
            --соцнорма
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
                       END /*временная конструкция*/);
            ELSE
              ins_chrg(npp_,
                       rec_krt.lsk,
                       sign_kub_,
                       usl_,
                       socn_kub_,
                       rec_wo_peop.cena,
                       sit_,
                       msit_,
                       CASE WHEN hv_kan_sch_ <> 0 THEN 1 ELSE 0 END /*временная конструкция*/);
              IF rec_nabor.chrg2 <> 0 THEN
                --свыше с.нормы
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
                         CASE WHEN hv_kan_sch_ <> 0 THEN 1 ELSE 0 END /*временная конструкция*/);
              END IF;
            END IF;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА С СОЦНОРМОЙ И СВЫШЕ БЕЗ РАСЦЕНКИ ДЛЯ ПУСТЫХ КВАРТИР
          --ИСПОЛЬЗУЕТСЯ в Полыс, в ТСЖ
          -- горячая вода (г.в.)- ред от 19.09.11
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (4) THEN  --#4#
            --сначала по нормативу считаем (это НЕ в любом случае идёт по соц.норме, например если
            --распределится по дому много)
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

            --сколько кубов по соцнорме допустимо
            socn_kub_ := round(rec_prep.nrm_kpr * rec_wo_peop.tarnorm, 3);


            --сколько кубов по соцнорме допустимо
            socn_kub_ := round(rec_prep.nrm_kpr * rec_wo_peop.tarnorm, 3);
            gv_kan_nrm_ := rec_prep.nrm_vol; --расход по г.в. для канализ.
            --счетчики по г.в.
            gv_kan_sch_ := rec_prep.sch_vol; --расход по г.в. для канализ.
            --общий расход
            gv_ := gv_kan_nrm_ + gv_kan_sch_; --прибавить расход временно проживающих (вычисленных)
            --Если расход отрицательный то...
            IF gv_ >= 0 THEN
              sign_kub_ := 1;
            ELSE
              sign_kub_ := -1;
            END IF;
            gv_ := abs(gv_);
            --соцнорма
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
                       END /*временная конструкция*/);
            ELSE
              ins_chrg(npp_,
                       rec_krt.lsk,
                       sign_kub_,
                       usl_,
                       socn_kub_,
                       rec_wo_peop.cena,
                       sit_,
                       msit_,
                       CASE WHEN gv_kan_sch_ <> 0 THEN 1 ELSE 0 END /*временная конструкция*/);
              IF rec_nabor.chrg2 <> 0 THEN
                --свыше с.нормы
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
                         CASE WHEN gv_kan_sch_ <> 0 THEN 1 ELSE 0 END /*временная конструкция*/);
              END IF;
            END IF;
          END IF;




          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА С РАСЦЕНКОЙ ДЛЯ ПУСТЫХ КВАРТИР С СОЦНОРМОЙ И СВЫШЕ
          -- холодная вода, горячая вода /ревизия для ТСЖ. от 29.04.2014/
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (38, 40) THEN --#38#40#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            l_flag:=0;
            /*if rec_nabor.usl_cd = 'х.вода' then
              --сохранить для повыш.коэфф. Х.В.
              l_hw_dist_tp:=rec_wo_peop.dist_tp;
            elsif rec_nabor.usl_cd = 'г.вода' then
              --сохранить для повыш.коэфф. Г.В.
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
                --расчет для не пустой квартиры
                --по норме
                ins_chrg2(c.vol_nrm, rec_wo_peop.cena, null, usl_, c.sch, l_kpr, l_kprz, l_kpro, null);
--                l_kpr:=0; -убрал, так как у Ларисы испортился отчет по субсидированию г.в. и отоп.
--                l_kprz:=0;
--                l_kpro:=0;
                OPEN cur_wo_peop(rec_nabor.usl_p);
                FETCH cur_wo_peop
                  INTO rec_wo_peop;
                CLOSE cur_wo_peop;
                --свыше соц.нормы
                if rec_nabor.usl_p is not null then --ред.20.11.14, сделал, так как стал вылетать exception о пустой услуге rec_nabor.usl_p
                  ins_chrg2(c.vol_sv_nrm, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, l_kpr, l_kprz, l_kpro, null);
                  l_kpr:=0;
                  l_kprz:=0;
                  l_kpro:=0;
                end if;
              elsif c.empty = 1 then
                --расчет для пустой квартиры
                OPEN cur_nabor2(rec_nabor.usl_empt);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --ОКАЗЫВАЕТСЯ НАДО НУЛИТЬ
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                OPEN cur_wo_peop(rec_nabor.usl_empt);
                FETCH cur_wo_peop
                  INTO rec_wo_peop;
                CLOSE cur_wo_peop;

                if rec_nabor2.usl is not null then
                  --есть выделенная услуга "без проживающих"
                  ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor2.usl, c.sch, null, null, null, null);
                  else
                  --нет выделенной услуги "без проживающих", ищем по свыше с.н.
                  --расчет для пустой квартиры
                  OPEN cur_wo_peop(rec_nabor.usl_p);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
                  ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, null, null, null, null);
                  --    Raise_application_error(-20000, 'Нет выделенной услуги "без проживающих" л.с.:'||rec_krt.lsk);
                end if;
              end if;
            end loop;
          END IF;

          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА С РАСЦЕНКОЙ ДЛЯ ПУСТЫХ КВАРТИР С СОЦНОРМОЙ И СВЫШЕ
          -- канализование /ревизия для для ТСЖ. от 19.05.2014/
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND rec_nabor.fk_calc_tp IN (39) THEN --#39#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            OPEN cur_prep;
            FETCH cur_prep
              INTO rec_prep;
            CLOSE cur_prep;
            --ТОЛЬКО в этой услуге реализован расчет свыше соц нормы не в C_KART!
            l_kpr:=0;
            l_kprz:=0;
            l_kpro:=0;
            for c2 in cur_charge_prep(null, null)
            loop
              l_kpr:=c2.kpr;
              l_kprz:=c2.kprz;
              l_kpro:=c2.kpro;
            end loop;

            /*if rec_nabor.usl_cd = 'х.вода' then
              --сохранить для повыш.коэфф. Х.В.
              l_hw_dist_tp:=rec_wo_peop.dist_tp;
            elsif rec_nabor.usl_cd = 'г.вода' then
              --сохранить для повыш.коэфф. Г.В.
              l_gw_dist_tp:=rec_wo_peop.dist_tp;
            end if;*/

            for c in cur_charge_prep_usl_cd('х.вода,г.вода')
            loop
              if c.empty = 0 then
                --расчет для не пустой квартиры
                l_norm:=rec_wo_peop.tarnorm*rec_prep.kpr;
                l_vol:=abs(c.vol);
                l_sign:=sign(c.vol);

                while l_norm >0 and l_vol >0
                loop
                  if l_norm >0 and l_norm > l_vol then
                    --по норме
--                    ins_chrg2(l_vol*l_sign, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null); --жесть
                    ins_chrg2(l_vol*l_sign, rec_wo_peop.cena, null, usl_, c.sch, l_kpr, l_kprz, l_kpro, null); --жесть (убрал неправильно считающееся кол-во прож по канализ)
--                l_kpr:=0; -убрал, так как у Ларисы испортился отчет по субсидированию г.в. и отоп.
--                l_kprz:=0;
--                l_kpro:=0;
                    l_norm:=l_norm-l_vol;
                    l_vol:=0;
                  elsif l_norm >0 and l_norm <=l_vol then
                    --по норме
--                    ins_chrg2(l_norm*l_sign, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null); --жесть
                    ins_chrg2(l_norm*l_sign, rec_wo_peop.cena, null, usl_, c.sch, l_kpr, l_kprz, l_kpro, null); --жесть (убрал неправильно считающееся кол-во прож по канализ)
--                l_kpr:=0; -убрал, так как у Ларисы испортился отчет по субсидированию г.в. и отоп.
--                l_kprz:=0;
--                l_kpro:=0;
                    l_vol:=l_vol-l_norm;
                    l_norm:=0;
                  end if;
                end loop;
                if l_vol > 0 and rec_nabor.usl_p is not null then --добавил, если rec_nabor.usl_p - не пустая... 13.04.2015
                  --свыше соцнормы
                  OPEN cur_wo_peop(rec_nabor.usl_p);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
--                  ins_chrg2(l_vol*l_sign, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, c.kpr, c.kprz, c.kpro, null); --жесть
                  ins_chrg2(l_vol*l_sign, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, l_kpr, l_kprz, l_kpro, null); --жесть (убрал неправильно считающееся кол-во прож по канализ)
                  l_kpr:=0;
                  l_kprz:=0;
                  l_kpro:=0;
                  l_vol:=0;
                end if;
              elsif c.empty = 1 then
                --расчет для пустой квартиры
                OPEN cur_nabor2(rec_nabor.usl_empt);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --ОКАЗЫВАЕТСЯ НАДО НУЛИТЬ
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;

                if rec_nabor2.usl is not null then
                  --есть выделенная услуга "без проживающих"
                  OPEN cur_wo_peop(rec_nabor.usl_empt);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
--                  ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null); --жесть
                  ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor2.usl, c.sch, null, null, null, null); --жесть (убрал неправильно считающееся кол-во прож по канализ)
                  elsif rec_nabor.usl_p is not null then
                  --нет выделенной услуги "без проживающих", ищем по свыше с.н.
                  --расчет для пустой квартиры
                  --Raise_application_error(-20000, 'rec_nabor.usl_p'||rec_nabor.usl_p);

                  OPEN cur_wo_peop(rec_nabor.usl_p);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
--                    ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, c.kpr, c.kprz, c.kpro, null); --жесть
                    ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, null, null, null, null); --жесть (убрал неправильно считающееся кол-во прож по канализ)
                  else -- совсем нет никаких услуг свыше.с.н. и 0 прожив
                  OPEN cur_wo_peop(usl_);
                  FETCH cur_wo_peop
                    INTO rec_wo_peop;
                  CLOSE cur_wo_peop;
--                    ins_chrg2(c.vol, rec_wo_peop.cena, null, rec_nabor.usl_p, c.sch, c.kpr, c.kprz, c.kpro, null); --жесть
                    ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, null, null, null, null);
                end if;
              end if;
            end loop;

          END IF;


          --||||||||||||||||||||||||||||||||||||||--
            --УСЛУГА (УСТАРЕВШАЯ)
            --ИСПОЛЬЗУЕТСЯ в Полыс, в ТСЖ
            --сначала по нормативу считаем (это НЕ в любом случае идёт по соц.норме, например если
            --распределится по дому много)
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

            --сколько кубов по соцнорме допустимо
            socn_kub_ := round(rec_prep.nrm_kpr * rec_wo_peop.tarnorm, 3);
            --общий расход
            kan_ := hv_kan_nrm_ + hv_kan_sch_ + gv_kan_nrm_ + gv_kan_sch_;
            --Если расход отрицательный то...
            IF kan_ >= 0 THEN
              sign_kub_ := 1;
            ELSE
              sign_kub_ := -1;
            END IF;
            kan_ := abs(kan_);
            --соцнорма
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
                       END /*временная конструкция*/);
            ELSE
              ins_chrg(npp_,
                       rec_krt.lsk,
                       sign_kub_,
                       usl_,
                       socn_kub_,
                       rec_wo_peop.cena,
                       sit_,
                       msit_,
                       CASE WHEN gv_kan_sch_ <> 0 OR hv_kan_sch_ <> 0 THEN 1 ELSE 0 END /*временная конструкция*/);
              IF rec_nabor.chrg2 <> 0 THEN
                --свыше с.нормы
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
                         CASE WHEN gv_kan_sch_ <> 0 OR hv_kan_sch_ <> 0 THEN 1 ELSE 0 END /*временная конструкция*/);
              END IF;
            END IF;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА С РАСЦЕНКОЙ ДЛЯ ПУСТЫХ КВАРТИР
          -- холодная вода/ревизия для кис. от 18.01.2018/
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (17) THEN --#17
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --расчет для не пустой квартиры
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --расчет для пустой квартиры
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --ОКАЗЫВАЕТСЯ НАДО НУЛИТЬ
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                l_cena:=rec_wo_peop.cena_for_empty;
                if rec_nabor2.usl is not null then
                  --есть выделенная услуга "без проживающих"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --нет выделенной услуги "без проживающих", ставим на ту же услугу
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА С РАСЦЕНКОЙ ДЛЯ ПУСТЫХ КВАРТИР
          -- горячая вода /ревизия для кис. от 18.01.2018/
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (18) THEN --#18
            OPEN cur_wo_peop_gw(null);
            FETCH cur_wo_peop_gw
              INTO rec_wo_peop_gw;
            CLOSE cur_wo_peop_gw;
            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --расчет для не пустой квартиры
                ins_chrg2(c.vol, rec_wo_peop_gw.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --расчет для пустой квартиры
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --ОКАЗЫВАЕТСЯ НАДО НУЛИТЬ
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                l_cena:=rec_wo_peop_gw.cena_for_empty;
                if rec_nabor2.usl is not null then
                  --есть выделенная услуга "без проживающих"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --нет выделенной услуги "без проживающих", ставим на ту же услугу
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА С РАСЦЕНКОЙ ДЛЯ ПУСТЫХ КВАРТИР
          -- канализование /ревизия для кис. от 01.03.2014/
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND rec_nabor.fk_calc_tp IN (19) THEN --#19#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --сохранить расценку
            l_cena:=rec_wo_peop.cena;
            i:=0;
            -- поиск по всем лс принадлежащим klsk
            for c in cur_charge_prep_usl_cd_by_klsk('х.вода,г.вода,х.в. для гвс')
            loop
              if c.empty = 0 then
                --расчет для не пустой квартиры
                if i=0 then
                --только один раз установить кол-во проживающих
                  for c2 in cur_charge_prep_kpr
                  loop
                    ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c2.kpr, c2.kprz, c2.kpro, null);
                  end loop;
                  i:=1;
                else
                  ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, null, null, null, null);
                end if;
              elsif c.empty = 1 then
                --расчет для пустой квартиры
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --ОКАЗЫВАЕТСЯ НАДО НУЛИТЬ
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
--                if rec_krt.status <> 1 then
                --Было:для не муниципальных квартир, расценка как для пустых квартир
                --ред.21.08.14 -сделал и по муницип расенку как для пустых приватизир.
                l_cena:=rec_wo_peop.cena_for_empty;
--                end if;
                if rec_nabor2.usl is not null then
                  --есть выделенная услуга "без проживающих"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, null, null, null, null);
                  else
                  --нет выделенной услуги "без проживающих", ставим на ту же услугу
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, null, null, null, null);
                end if;
              end if;
            end loop;

          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА С РАСЦЕНКОЙ ДЛЯ ПУСТЫХ КВАРТИР
          -- электроэнергия - единая услуга  /ревизия для кис. от 01.03.2014/
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND rec_nabor.fk_calc_tp IN (31) THEN --#31#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --сохранить расценку
            l_cena:=rec_wo_peop.cena;
            --сохранить для повыш.коэфф.
            --l_el_dist_tp:=rec_wo_peop.dist_tp;

            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --расчет для не пустой квартиры
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --расчет для пустой квартиры
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --ОКАЗЫВАЕТСЯ НАДО НУЛИТЬ
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                if rec_krt.status <> 1 then
                --для не муниципальных квартир, расценка как для пустых квартир
                  l_cena:=rec_wo_peop.cena_for_empty;
                end if;

                if rec_nabor2.usl is not null then
                  --есть выделенная услуга "без проживающих"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --нет выделенной услуги "без проживающих", ставим на ту же услугу
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- холодная вода - доначисление по 354 /ревизия для УК, где услуга ОДН отдельной строкой/
           IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp IN (20) THEN --#20#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --сохранить расценку
            l_cena:=rec_wo_peop.cena;

            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --расчет для не пустой квартиры
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --расчет для пустой квартиры
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --ОКАЗЫВАЕТСЯ НАДО НУЛИТЬ
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                --if rec_krt.status <> 1 then
                --Было:для не муниципальных квартир, расценка как для пустых квартир
                --ред.21.08.14 -сделал и по муницип расенку как для пустых приватизир.
                  l_cena:=rec_wo_peop.cena_for_empty;
                --end if;
                if rec_nabor2.usl is not null then
                  --есть выделенная услуга "без проживающих"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --нет выделенной услуги "без проживающих", ставим на ту же услугу
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
            hv_kan_add_ := nvl(rec_nabor.vol_add,0); --расход по х.в. ОДН для канализ. ОДН
            ins_chrg2(rec_nabor.vol_add, rec_wo_peop.cena, null, usl_);*/

          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- горячая вода - доначисление по 354 /ревизия для УК, где услуга ОДН отдельной строкой/
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp IN (21) THEN --#21#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --сохранить расценку
            l_cena:=rec_wo_peop.cena;

            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --расчет для не пустой квартиры
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --расчет для пустой квартиры
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --ОКАЗЫВАЕТСЯ НАДО НУЛИТЬ
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
--                if rec_krt.status <> 1 then
                --Было:для не муниципальных квартир, расценка как для пустых квартир
                --ред.21.08.14 -сделал и по муницип расенку как для пустых приватизир.
                  l_cena:=rec_wo_peop.cena_for_empty;
--                end if;
                if rec_nabor2.usl is not null then
                  --есть выделенная услуга "без проживающих"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --нет выделенной услуги "без проживающих", ставим на ту же услугу
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
            gv_kan_add_ := nvl(rec_nabor.vol_add,0); --расход по г.в. ОДН для канализ. ОДН
            ins_chrg2(rec_nabor.vol_add, rec_wo_peop.cena, null, usl_);*/
          END IF;

          -- холодная вода - доначисление по 354 ДЛЯ ТСЖ /ревизия для УК, где услуга ОДН отдельной строкой/
           IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp IN (41) THEN --#41#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --сохранить расценку
            l_cena:=rec_wo_peop.cena;

            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --расчет для не пустой квартиры
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --расчет для пустой квартиры
                OPEN cur_nabor2(rec_nabor.usl_empt);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --ОКАЗЫВАЕТСЯ НАДО НУЛИТЬ
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                  l_cena:=rec_wo_peop.cena_for_empty;
                if rec_nabor2.usl is not null then
                  --есть выделенная услуга "без проживающих"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --нет выделенной услуги "без проживающих", ставим на ту же услугу
                  ins_chrg2(c.vol, l_cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end if;
            end loop;

          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- горячая вода - доначисление по 354  ДЛЯ ТСЖ /ревизия для УК, где услуга ОДН отдельной строкой/
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp IN (42) THEN --#42#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --сохранить расценку
            l_cena:=rec_wo_peop.cena;

            for c in cur_charge_prep(null, null)
            loop
              if c.empty = 0 then
                --расчет для не пустой квартиры
                ins_chrg2(c.vol, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.empty = 1 then
                --расчет для пустой квартиры
                OPEN cur_nabor2(rec_nabor.usl_empt);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --ОКАЗЫВАЕТСЯ НАДО НУЛИТЬ
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                  l_cena:=rec_wo_peop.cena;
                if rec_nabor2.usl is not null then
                  --есть выделенная услуга "без проживающих"
                  ins_chrg2(c.vol, l_cena, null, rec_nabor2.usl, c.sch, c.kpr, c.kprz, c.kpro, null);
                  else
                  --нет выделенной услуги "без проживающих", ставим на ту же услугу
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
            gv_kan_add_ := nvl(rec_nabor.vol_add,0); --расход по г.в. ОДН для канализ. ОДН
            ins_chrg2(rec_nabor.vol_add, rec_wo_peop.cena, null, usl_);*/
          END IF;

          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА ПО ПОВЫШАЮЩИМ КОЭФФ. К НОРМАТИВАМ ПО П.344. УСЛУГА ТОЛЬКО ДЛЯ НОРМАТИВЩИКОВ!!!
          -- холодная, горячая вода
          --ВНИМАНИЕ! соблюдать очередность расчета usl.usl_order! --считать услугу ТОЛЬКО после родительской!
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (44) THEN --#44#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;

            for c in cur_charge_prep(rec_nabor.parent_usl, null)
            loop
              --интересует только ОТСУТСТВИЕ счетчика
              --ВНИМАНИЕ! по этой услуге, в nabor.norm находится КОЭФФ к потреблённому расходу родительской услуги!
              if c.sch = 0 and c.empty = 0 then
                -- есть проживающие
                ins_chrg2(c.vol_nrm * rec_wo_peop.tarnorm, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
              elsif c.sch = 0 and c.empty = 1 then
                -- нет проживающих - ред. 31.01.19
                OPEN cur_wo_peop(rec_nabor.usl_empt);
                FETCH cur_wo_peop
                  INTO rec_wo_peop2;
                if cur_wo_peop%NOTFOUND then
                  --нет выделенной услуги "без проживающих", ставим на ту же услугу
                  ins_chrg2(c.vol_nrm * rec_wo_peop.tarnorm, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                else
                  --есть выделенная услуга "без проживающих"
                  ins_chrg2(c.vol_nrm * rec_wo_peop2.tarnorm, rec_wo_peop2.cena, null, rec_nabor.usl_empt, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
                CLOSE cur_wo_peop;
              end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА ПО ПОВЫШАЮЩИМ КОЭФФ. К НОРМАТИВАМ ПО П.344.
          --ОДН холодная, ОДН горячая вода
          --ВНИМАНИЕ! соблюдать очередность расчета usl.usl_order! --считать услугу ТОЛЬКО после родительской!
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (45) THEN --#45#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            for c in cur_charge_prep(rec_nabor.parent_usl, null)
            loop
              --интересует только ОТСУТСТВИЕ счетчика на ДОМЕ с возможностью его установки
              --ВНИМАНИЕ! по этой услуге, в nabor.norm находится КОЭФФ к потреблённому расходу родительской услуги!
                select decode(rec_nabor.usl_cd, 'ХВС_одн_доб', 'х.вода', 'ГВС_одн_доб', 'г.вода', 'ЭЛ_одн_доб', 'эл.энерг.2', 'эл.эн.учет УО', null) into l_str from dual;
                for c2 in cur_vvod_tp(l_str)
                loop
                if rec_nabor.usl_cd = 'ХВС_одн_доб' and c2.dist_tp=4 or
                   rec_nabor.usl_cd = 'ГВС_одн_доб' and c2.dist_tp=4 or
                   rec_nabor.usl_cd = 'ЭЛ_одн_доб' and c2.dist_tp=4 then
                  ins_chrg2(c.vol_nrm * rec_wo_peop.tarnorm, rec_wo_peop.cena, null, usl_, c.sch, c.kpr, c.kprz, c.kpro, null);
                end if;
              end loop;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА ПО ПОВЫШАЮЩИМ КОЭФФ. К НОРМАТИВАМ ПО П.344. (Общая площадь * коэфф, там где c_vvod.dist_tp=4) с 01.02.2019 (Кис.)
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (50) THEN --#50#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
          --интересует только ОТСУТСТВИЕ счетчика на ДОМЕ с возможностью его установки
          --ВНИМАНИЕ! по этой услуге, в nabor.norm находится КОЭФФ к потреблённому расходу родительской услуги!
            select decode(rec_nabor.usl_cd, 'ХВС_одн_доб', 'х.вода', 'ГВС_одн_доб', 'г.вода', 'ЭЛ_одн_доб', 'эл.энерг.2', 'эл.эн.учет УО', null) into l_str from dual;
            for c2 in cur_vvod_tp2(l_str)
            loop
            if rec_nabor.usl_cd = 'ХВС_одн_доб' and c2.dist_tp=4 or
               rec_nabor.usl_cd = 'ГВС_одн_доб' and c2.dist_tp=4 or
               rec_nabor.usl_cd = 'ЭЛ_одн_доб' and c2.dist_tp=4 then
              ins_chrg2(rec_krt.opl * rec_wo_peop.tarnorm, rec_wo_peop.cena, null, usl_, 0, 0, 0, 0, null);
            end if;
            end loop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--

          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА ПО ПОВЫШАЮЩИМ КОЭФФ. К НОРМАТИВАМ ПО П.344.
          --отопление
          --ВНИМАНИЕ! соблюдать очередность расчета usl.usl_order! --считать услугу ТОЛЬКО после родительской!
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (46) THEN --#46#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            for c in cur_charge_prep_usl_cd('отоп.гкал.,отоп.гкал./0 зарег.')
            loop
              --интересует только ОТСУТСТВИЕ счетчика на ДОМЕ с возможностью его установки
              --ВНИМАНИЕ! по этой услуге, в nabor.norm находится КОЭФФ к потреблённому расходу родительской услуги!
              if rec_nabor.usl_cd = 'Отоп.гкал_инд_доб' and l_ot_dist_tp=4 then
                ins_chrg2(c.vol_nrm * rec_wo_peop.tarnorm, rec_wo_peop.cena, null, usl_, c.sch, null, null, null, null);
              end if;
            end loop;
          END IF;

          --||||||||||||||||||||||||||||||||||||||--
          --УСЛУГА С РАСЦЕНКОЙ ДЛЯ ПУСТЫХ КВАРТИР
          -- Тепл.энергия для нагрева ХВС/ревизия для кис. от 24.03.2015/
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp IN (47) THEN --#47#

            --получить код услуги Х.В. для ГВС
            select u.usl into l_tmp_usl
              from usl u where u.cd='х.в. для гвс';
            OPEN cur_wo_peop(l_tmp_usl);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --получить по дому объем Х.В. для ГВС
            l_tmp_vol:=rec_wo_peop.kub;

            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            CLOSE cur_wo_peop;
            --сохранить расценку
            l_cena:=rec_wo_peop.cena;
            i:=0;
            for c in cur_charge_prep_usl_cd('х.в. для гвс')
            loop
              if rec_wo_peop.kub <> 0 and l_tmp_vol <> 0 then
               --рассчитать, как объем Х.В. для ГВС в квартире / объем Х.В. для ГВС по дому * расход по дому тепл.энергии в Гкал
                l_vol:=c.vol/l_tmp_vol * rec_wo_peop.kub;
              else
                --выйти из цикла, считать нечего
                exit;
              end if;

              if c.empty = 0 then
                --расчет для не пустой квартиры
                if i=0 then
                --только один раз установить кол-во проживающих
                  for c2 in cur_charge_prep_kpr
                  loop
                    ins_chrg2(l_vol, rec_wo_peop.cena, null, usl_, c.sch, c2.kpr, c2.kprz, c2.kpro, null);
                  end loop;
                  i:=1;
                else
                  ins_chrg2(l_vol, rec_wo_peop.cena, null, usl_, c.sch, null, null, null, null);
                end if;
              elsif c.empty = 1 then
                --расчет для пустой квартиры
                OPEN cur_nabor2(rec_nabor.usl_p);
                FETCH cur_nabor2
                  INTO rec_nabor2;
                if cur_nabor2%NOTFOUND then
                  --ОКАЗЫВАЕТСЯ НАДО НУЛИТЬ
                  rec_nabor2.usl:=null;
                end if;
                CLOSE cur_nabor2;
                l_cena:=rec_wo_peop.cena_for_empty;
                if rec_nabor2.usl is not null then
                  --есть выделенная услуга "без проживающих"
                  ins_chrg2(l_vol, l_cena, null, rec_nabor2.usl, c.sch, null, null, null, null);
                  else
                  --нет выделенной услуги "без проживающих", ставим на ту же услугу
                  ins_chrg2(l_vol, l_cena, null, usl_, c.sch, null, null, null, null);
                end if;
              end if;
            end loop;

          END IF;
          --||||||||||||||||||||||||||||||||||||||--

          --||||||||||||||||||||||||||||||||||||||--
          -- очистка выгр.ям (полыс)
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
               rec_nabor.fk_calc_tp = 6 THEN --#6#
            --должны быть проживающие!
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
          -- Найм (только по муниципальным квартирам)
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp in (7) AND rec_krt.status = 1 THEN --#7#
            --необязательны проживающие, рассчёт на м2
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
          -- Услуги ЕРКЦ
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp in (8) THEN --#7#
            --необязательны проживающие, рассчёт на м2
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
          -- Эл.энергия
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp = 9 THEN --#9#
            IF round(rec_krt.el1, 2) <> 0 THEN
              --со льготой
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
              --без льготы
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
          -- Эл.энергия субсиди
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp = 10 THEN --#10#

            Raise_application_error(-20000, 'Не работает услуга!!!');
/*            IF round(rec_krt.el, 2) <> 0 THEN
              --со льготой
              npp_    := npp_ + 1;
              sit_    := sit_ + round(rec_krt.el * rec_wo_peop.usl_subs, 2);
              summaf_ := rec_krt.el;
              summa_  := round(summaf_, 2);
              INSERT INTO c_charge
                (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
              VALUES
                (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, NULL, rec_peoples.cena, NULL, NULL);
              --без льготы
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
          -- Услуги РКЦ ЖКХ
          -- не важно есть люди или нет
          --        if (rec_nabor.chrg1 <> 0 or rec_nabor.chrg2 <> 0) and usl_ = '032' then
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp = 11 THEN --#11#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            IF round(rec_wo_peop.tarkoef, 2) <> 0 THEN
              npp_ := npp_ + 1;
              --со льготой
              --             sit_ := sit_ + round(rec_wo_peop.tarkoef, 2); --уже готовая сумма здесь
              summaf_ := rec_wo_peop.tarkoef;
              summa_  := round(summaf_, 2);
              INSERT INTO c_charge
                (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
              VALUES
                (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, NULL, rec_wo_peop.cena, rec_wo_peop.tarkoef, NULL);
              --без льготы
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
          -- Эл.энерг в киловаттах, распределяемая на дом (для ТСЖ)
          -- не важно есть люди или нет
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp IN (15) THEN --#15#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            IF round(rec_wo_peop.tarkoef, 2) <> 0 THEN
              npp_ := npp_ + 1;
              --со льготой
              summaf_ := nvl(rec_nabor.vol, 0) * rec_wo_peop.cena;
              summa_  := round(summaf_, 2);
              INSERT INTO c_charge
                (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
              VALUES
                (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, round(rec_nabor.vol,
                        2), rec_wo_peop.cena, rec_wo_peop.tarkoef, NULL);
              --без льготы
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
          -- Антенна-1,2, Код.замки-1,2
          -- не важно есть люди или нет, не смотрим на льготы
          --        if (rec_nabor.chrg1 <> 0 or rec_nabor.chrg2 <> 0) and usl_ in ('042','043','044','045') then
          IF (rec_nabor.chrg1 <> 0 OR rec_nabor.chrg2 <> 0) AND
             rec_nabor.fk_calc_tp IN (12, 13) THEN --#12# #13#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            IF round(rec_wo_peop.tarkoef * rec_wo_peop.tarnorm, 2) <> 0 THEN
              IF nvl(rec_krt.org_var, 0) <> 0 THEN
                --Энерг+
                SELECT MAX(s.cena)
                INTO   cena_
                FROM   spr_tarif_prices s, params p
                WHERE  s.fk_tarif = rec_nabor.fk_tarif
                AND    p.period BETWEEN s.mg1 AND s.mg2;
                npp_ := npp_ + 1;
                IF rec_nabor.fk_calc_tp IN (12) THEN
                  --Кабельное Э+
                  --со льготой
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
                  --без льготы
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
                  --Антенна Э+ (без начисления)
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
                  --без льготы
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
                --Кисель, ТСЖ
                --со льготой
                npp_    := npp_ + 1;
                summaf_ := rec_wo_peop.cena;
                summa_  := round(summaf_, 2);
                INSERT INTO c_charge
                  (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
                VALUES
                  (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, round(rec_wo_peop.tarkoef *
                          rec_wo_peop.tarnorm,
                          2), rec_wo_peop.cena, rec_wo_peop.tarkoef, NULL);
                --без льготы
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
          -- Цифровое ТВ Энерг+
          -- не важно есть люди или нет, не смотрим на льготы
          IF (rec_nabor.chrg1 <> 0) AND rec_nabor.fk_calc_tp IN (16) THEN --#16#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            --сложная цена, составляющая сумму цен по программам, пакетам абонента
            SELECT nvl(SUM(s.cena), 0)
            INTO   cena_
            FROM   nabor_progs n, spr_tarif_prices s, params p
            WHERE  n.fk_tarif = s.fk_tarif
            AND    n.lsk = rec_krt.lsk
            AND    p.period BETWEEN s.mg1 AND s.mg2;
            npp_ := npp_ + 1;
            --Кабельное Э+
            --со льготой
            INSERT INTO c_charge
              (npp, lsk, usl, summa, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (0, rec_krt.lsk, usl_, cena_, NULL, 0, NULL, rec_wo_peop.tarnorm, cena_, rec_wo_peop.tarkoef, NULL);
            --без льготы
            INSERT INTO c_charge
              (npp, lsk, usl, summa, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
            VALUES
              (npp_, rec_krt.lsk, usl_, cena_, NULL, 1, NULL, rec_wo_peop.tarnorm, cena_, rec_wo_peop.tarkoef, NULL);
            CLOSE cur_wo_peop;
          END IF;
          --||||||||||||||||||||||||||||||||||||||--
          -- Прочие услуги, расчитываемые как расценка * vol_add
          -- Например Эл.энергия (в Гаражах в тсж)
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
            --без льготы
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
          -- Прочие услуги, расчитываемые как расценка * норматив * Общ.площадь
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
            --без льготы
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
          -- Прочие услуги, расчитываемые как расценка * норматив * Общ.площадь, только НЕ по муницип фонду
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
            --без льготы
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
          -- Прочие услуги, расчитываемые как расценка * кол-во прожив * норматив (квт. например)
          -- Например Эл.энергия (вариация эл.эн.МОП в тсж)
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
            --без льготы
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
          -- Услуга вывоз мусора - кол-во прожив * норматив (Кис.)
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp = 49 --AND rec_krt.status != 1-- кроме муницип. лс (ред.03.09.18 для Кис.) - убрал это, по просьбе Кис.14.09.18
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
            --без льготы
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
          --Холодная вода (УСТАРЕВШЕЕ, для Полыс)
          --||||||||||||||||||||||||||||||||||||||--
          -- Прочие услуги, расчитываемые как расценка * коэфф * норматив (Но в потреблении - норматив)
          -- Например Эл.энергия (в Гаражах в тсж) -странно, есть такая методика в услуге № 23
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
            --без льготы
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
          -- Прочие услуги, расчитываемые как сумма по родительской услуге * коэфф (обычно для Повыш коэфф) с учетом связанной услуги LINKED_USL!!!
          -- ВНИМАНИЕ!!! ВАЖЕН ПОРЯДОК РАСЧЕТА, ИНАЧЕ УСЛУГА НЕ ПОСЧИТАЕТСЯ!
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
              --без льготы
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
          -- Прочие услуги, расчитываемые как сумма родительской услуге * коэфф (обычно для Повыш коэфф. ОДН)
          -- ВНИМАНИЕ!!! ВАЖЕН ПОРЯДОК РАСЧЕТА, ИНАЧЕ УСЛУГА НЕ ПОСЧИТАЕТСЯ!
          IF rec_nabor.chrg1 <> 0 AND rec_nabor.fk_calc_tp = 48 THEN --#48#
            OPEN cur_wo_peop(null);
            FETCH cur_wo_peop
              INTO rec_wo_peop;
            l_proc_nrm:=1;
            for c in cur_chrg(rec_nabor.parent_usl, 0) loop
              select decode(rec_nabor.usl_cd, 'ХВС_одн_доб', 'х.вода', 'ГВС_одн_доб',
                     'г.вода', 'ЭЛ_одн_доб', 'эл.энерг.2', 'эл.эн.учет УО', null) into l_str from dual;
              for c2 in cur_vvod_tp(l_str)
              loop
                if rec_nabor.usl_cd = 'ХВС_одн_доб' and c2.dist_tp=4 or
                   rec_nabor.usl_cd = 'ГВС_одн_доб' and c2.dist_tp=4 or
                   rec_nabor.usl_cd = 'ЭЛ_одн_доб' and c2.dist_tp=4 then

                  sit_    := sit_ + round(c.summa * rec_wo_peop.tarnorm,2);
                  npp_    := npp_ + 1;
                  summaf_ := round(c.summa * rec_wo_peop.tarnorm,2);
                  summa_  := round(summaf_, 2);
                  INSERT INTO c_charge
                    (npp, lsk, usl, summa, summaf, kart_pr_id, type, spk_id, test_opl, test_cena, test_tarkoef, test_spk_koef)
                  VALUES
                    (0, rec_krt.lsk, usl_, summa_, summaf_, NULL, 0, NULL, null, null, NULL, NULL);
                  --без льготы
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
        ---------льготы
        --итоговое формирование льгот и начисления с учётом льгот
        IF rec_krt.corr_lg = 1 THEN
          --учитываем корректировку в льготах
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
                     GROUP  BY npp, lsk, usl, r.spk_id, r.kart_pr_id, r.main, r.lg_doc_id) t, --льготы
                   (SELECT lsk, usl, nvl(SUM(summa), 0) AS summa
                     FROM   c_charge r, params p
                     WHERE  type = 1
                     AND    lsk = '' || rec_krt.lsk || ''
                     GROUP  BY lsk, usl) x, -- нач без льг.
                   (SELECT lsk, usl, SUM(summa) summa
                     FROM   c_change c, params p
                     WHERE  c.mgchange = p.period
                     AND    lsk = '' || rec_krt.lsk || ''
                     AND    nvl(c.proc, 0) <> 0
                     AND    to_char(c.dtek, 'YYYYMM') = p.period
                     GROUP  BY lsk, usl) v --изменения
            WHERE  t.lsk = x.lsk(+)
            AND    t.usl = x.usl(+)
            AND    t.lsk = v.lsk(+)
            AND    t.usl = v.usl(+);
        ELSE
          --НЕ учитываем корректировку в льготах
          INSERT INTO c_charge
            (npp, lsk, usl, summa, kart_pr_id, spk_id, type, main, lg_doc_id)
            SELECT npp, lsk, usl, summa, kart_pr_id, spk_id, 4, main, lg_doc_id
            FROM   c_charge t
            WHERE  t.type = 3
            AND    lsk = '' || rec_krt.lsk || '';
        END IF;

        --считать или нет субисидию?
        IF nvl(rec_krt.subs_ob, 0) = 1 THEN
          -- Расчет субсидии 11.05.2006
          -- krt.eksub1 - Совокуп.доход на семью
          -- krt.eksub2 - Душевой.доход
          -- krt.sgku - Стандарт СЖКУ
          --& krt.doppl - Увел. площади для субсидии
          --Совокуп.доход на 1 чел

          --итоговое начисление для субсидии + изменения
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
            -- распределяем корректировку
            --итоговое начисление для субсидии + изменения
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
                       AND    u.usl_subs = 1 --берем чистое начисление
                       UNION ALL
                       SELECT NULL, t.lsk, t.usl, -1 * t.summa
                       FROM   c_charge t, usl u
                       WHERE  t.lsk = '' || rec_krt.lsk || ''
                       AND    t.type = 3
                       AND    t.usl = u.usl
                       AND    u.usl_subs = 1 --вычитаем льготы (без изменениний!!!)
                       UNION ALL
                       SELECT NULL, c.lsk, c.usl, c.summa
                       FROM   c_change c, params p, usl u
                       WHERE  c.usl = u.usl
                       AND    c.mgchange = p.period
                       AND    c.lsk = '' || rec_krt.lsk || ''
                       AND    u.usl_subs = 1
                       AND    to_char(c.dtek, 'YYYYMM') = p.period --прибавляем изменения
                       AND    nvl(c.proc, 0) <> 0) v
              GROUP  BY v.lsk, v.usl;
            SELECT subs_ - SUM(t.summa)
            INTO   chk_subs_corr_
            FROM   c_charge t
            WHERE  t.lsk = '' || rec_krt.lsk || ''
            AND    type = 2;
            IF chk_subs_corr_ > 0.10 THEN
              --больше десяти копеек - expception
              raise_application_error(-20001,
                                      'Внимание! По лицевому ' ||
                                      rec_krt.lsk ||
                                      ' произошло не правильное округление корректировки субсидии. Остановка.');
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
            --признак считать субсидию
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

            --распределяем основную субсидию
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
        --по каждой 30 -ой записи (иначе тормозит селект из sys.v_$database)
        IF rec_krt.lsk / 30 - round(rec_krt.lsk / 30) = 0 THEN
          IF (dbid_ = 3799038777 AND
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 2618192783 AND --тсж клён
             init.get_date < to_date('15082014', 'DDMMYYYY')) OR
             (dbid_ = 1314248482 AND --полыс
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
          --если нужен промежуточный коммит - делаем
          COMMIT;
        END IF;

      END IF;

      /* найти ошибки при округлении:
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
      -- округлить текущее содержание, для ГИС ЖКХ, выполняется, если заполнен справочник usl_round
 for c in (select a.usl, nvl(round(sum(a.price) over (partition by a.lsk) * a.opl,2),0) as summa, -- расчетная сумма
           nvl(sum(a.summa_fact) over (partition by a.lsk),0) as summa_fact, a.rd -- фактическая сумма, до округления
           from (
          select u.uslm, u.usl,
                 decode(lead(u.uslm, 1) over (order by u.uslm, u.usl), u.uslm, 0, 1) * t.test_cena as price, -- убрать расценку, если идёт повтор услуги по uslm
                  t.summa as summa_fact, k.lsk, k.opl, t.rd
                  from scott.kart k,
                  (select s.test_cena, s.usl, max(s.rowid) as rd, sum(s.summa) as summa from
                     scott.c_charge s, scott.usl u2 where s.usl=u2.usl and s.lsk=rec_krt.lsk and s.type=1
                  group by s.test_cena, s.usl) t
                  , scott.usl u, scott.usl_round r
                  where t.usl=u.usl and t.usl=r.usl
                  and k.lsk=rec_krt.lsk and k.reu=r.reu
                  and t.summa > 0) a
                  order by a.usl -- не менять порядок! чтобы округлялось всегда на одну услугу, не зависимо от суммы начисления
                  ) loop
        if abs(c.summa-c.summa_fact) <= 0.05 then
          -- обновить type=1
          update scott.c_charge t set t.summa=t.summa+(c.summa-c.summa_fact) where t.rowid=c.rd
            returning t.usl into l_usl_round;
          if sql%rowcount != 1 then
            Raise_application_error(-20000, '1.Некорректно кол.во обновленных записей, по лиц.счету:'||rec_krt.lsk);
          end if;
          -- обновить type=0
          update scott.c_charge t set t.summa=t.summa+(c.summa-c.summa_fact) where t.usl = l_usl_round
            and t.lsk=rec_krt.lsk
            and t.type=0 and rownum=1;
          if sql%rowcount != 1 then
            Raise_application_error(-20000, '2.Некорректно кол.во обновленных записей, по лиц.счету:'||rec_krt.lsk);
          end if;
        else
          Raise_application_error(-20000, 'Некорректное округление='
            ||to_char(c.summa - c.summa_fact)||', по лиц.счету:'||rec_krt.lsk);
          null;
        end if;
        exit;
      end loop;

      --конец цикла по лицевым счетам
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

    -- Блок округления, если округление включено ред.06.07.2018 - не понятно зачем нужно это округление, вроде бы у Кис и Полыс оно отключено
    -- у ТСЖ отключил 06.07.2018
    IF is_round_charge_ = 1 THEN
      IF var_ = 1 THEN
        --по группе л.с.
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
        --по 1 л.с.
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
        --по выбранному house_id дому
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
        --по всему фонду
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
        --по выбранному p_vvod вводу
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
      --если нужен коммит - делаем
      COMMIT;
    END IF;

    RETURN cnt_lsk_;



  END gen_charges;


END c_charges;
/

