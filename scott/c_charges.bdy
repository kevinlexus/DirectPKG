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
    l_klsk_id number;
    l_dummy number;
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

    if lsk_ is not null then
      select k.k_lsk_id into l_klsk_id from kart k where k.lsk=lsk_;
    end if;

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
    l_dummy:=p_java.gen(p_tp        => 0,
               p_house_id  => null,
               p_vvod_id   => null,
               p_usl_id    => null,
               p_klsk_id   => l_klsk_id,
               p_debug_lvl => 0,
               p_gen_dt    => nvl(init.dtek_, gdt(32,0,0)), -- не заполнен dtek_, вернуть последний день текущего периода
               p_stop      => 0);
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

      l_dummy:=p_java.gen(p_tp        => 0,
                 p_house_id  => null,
                 p_vvod_id   => null,
                 p_usl_id    => null,
                 p_klsk_id   => l_klsk_id,
                 p_debug_lvl => 0,
                 p_gen_dt    => nvl(init.dtek_, gdt(32,0,0)), -- не заполнен dtek_, вернуть последний день текущего периода
                 p_stop      => 0);
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


/*  FUNCTION gen_charges(lsk_      VARCHAR2,
                       lsk_end_  VARCHAR2,
                       house_id_ c_houses.id%TYPE,
                       p_vvod c_vvod.id%type,
                       iscommit_ NUMBER,
                       sendmsg_  NUMBER) RETURN NUMBER IS
  BEGIN
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

  END gen_charges;
*/

END c_charges;
/

