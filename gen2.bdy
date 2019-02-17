create or replace package body scott.gen2 is

  procedure gen_opl_xito10 is
    time_ date;
    mg_ params.period%type;
  begin
    select '201811' into mg_ from params p;

    --ЗА МЕСЯЦ
    --Оплата по предприятиям/трестам/услугам
    time_ := sysdate;
    delete from xxito11 t where t.mg = mg_;
    insert into xxito11
      (usl,
       oper,
       org,
       summa,
       trest,
       reu,
       mg,
       var,
       forreu,
       oborot,
       dopl,
       dat)
      select v.usl,
             v.oper,
             v.org,
             sum(v.summar) as summar,
             v.trest,
             v.reu,
             mg_,
             v.var,
             v.forreu,
             v.oborot,
             v.dopl,
             v.dat
        from (select t.lsk, t.usl, t.org, substr(t.nkom, 1, 2) AS reu, s.trest, 0 as var,
            s.reu as forreu, to_number(substr(op.oigu, 1, 1)) AS oborot,
            t.summa as summar, t.oper, t.dat_ink as dat, t.usl as usl_b, t.org as org_b, t.dopl
             from a_kwtp_day t, arch_kart k, s_reu_trest s, oper op
           where t.lsk=k.lsk and k.reu=s.reu and t.oper=op.oper and t.priznak = 1
           and t.dat_ink between gdt(1,11,2018) and gdt(30,11,2018)
           and t.mg='201811' and k.mg=t.mg) v
       group by usl,
                oper,
                org,
                trest,
                reu,
                mg_,
                to_char(sysdate, 'DD/MM/YYYY HH24:MI'),
                var,
                forreu,
                oborot,
                dopl,
                dat;

    delete from xxito12 t where t.mg = mg_;
    insert into xxito12
      (usl,
       org,
       summa,
       trest,
       reu,
       mg,
       var,
       forreu,
       kul,
       nd,
       status,
       dopl,
       dat)
      select v.usl,
             v.org,
             sum(v.summar) as summar,
             v.trest,
             v.reu,
             mg_,
             v.var,
             k.reu,
             k.kul,
             k.nd,
             decode(k.status, 1, 0, 1),
             v.dopl,
             v.dat
        from (select t.lsk, t.usl, t.org, substr(t.nkom, 1, 2) AS reu, s.trest, 0 as var,
            s.reu as forreu, to_number(substr(op.oigu, 1, 1)) AS oborot,
            t.summa as summar, t.oper, t.dat_ink as dat, t.usl as usl_b, t.org as org_b, t.dopl
             from a_kwtp_day t, arch_kart k, s_reu_trest s, oper op
           where t.lsk=k.lsk and k.reu=s.reu and t.oper=op.oper and t.priznak = 1
           and t.dat_ink between gdt(1,11,2018) and gdt(30,11,2018)
           and t.mg='201811' and k.mg=t.mg) v, arch_kart k
       where k.lsk = v.lsk and k.mg='201811'
         and v.oborot = 1
       group by v.usl,
                v.org,
                v.trest,
                v.reu,
                mg_,
                to_char(sysdate, 'DD/MM/YYYY HH24:MI'),
                v.var,
                k.reu,
                k.kul,
                k.nd,
                decode(k.status, 1, 0, 1),
                v.dopl,
                v.dat;

    delete from xxito14_lsk t where t.mg = mg_;
    insert into xxito14_lsk
      (lsk, usl, org, summa, mg, var, status, dopl, oper, cd_tp, dat)
      select k.lsk,
             v.usl,
             v.org,
             sum(v.summar) as summar,
             mg_ as mg,
             v.var,
             decode(k.status, 1, 0, 1),
             v.dopl,
             v.oper,
             v.cd_tp,
             v.dat
        from (select t.lsk, t.usl, t.org, substr(t.nkom, 1, 2) AS reu, s.trest, 0 as var,
            s.reu as forreu, to_number(substr(op.oigu, 1, 1)) AS oborot,
            t.summa as summar, t.oper, t.dat_ink as dat, t.usl as usl_b, t.org as org_b, t.dopl,
            t.priznak as cd_tp
             from a_kwtp_day t, arch_kart k, s_reu_trest s, oper op
           where t.lsk=k.lsk and k.reu=s.reu and t.oper=op.oper
           and t.dat_ink between gdt(1,11,2018) and gdt(30,11,2018)
           and t.mg='201811' and k.mg=t.mg) v, arch_kart k
       where k.lsk = v.lsk and k.mg='201811'
         and v.oborot = 1
       group by k.lsk,
                v.usl,
                v.org,
                v.var,
                decode(k.status, 1, 0, 1),
                v.dopl,
                v.oper,
                v.cd_tp,
                v.dat;

    delete from xxito14 t where t.mg = mg_;
    insert into xxito14
      (usl,
       org,
       summa,
       sum_distr,
       fk_distr,
       trest,
       reu,
       mg,
       var,
       forreu,
       kul,
       nd,
       status,
       dopl,
       oper,
       cd_tp,
       dat)
      select v.usl,
             v.org,
             sum(v.summar) as summar,
             sum(v.sum_distr) as sum_distr,
             v.fk_distr as fk_distr,
             v.trest,
             v.reu,
             mg_,
             v.var,
             k.reu,
             k.kul,
             k.nd,
             decode(k.status, 1, 0, 1),
             v.dopl,
             v.oper,
             v.cd_tp,
             v.dat
        from (select t.lsk, t.usl, t.org, substr(t.nkom, 1, 2) AS reu, s.trest, 0 as var,
            s.reu as forreu, to_number(substr(op.oigu, 1, 1)) AS oborot,
            t.summa as summar, t.sum_distr, t.fk_distr, t.oper, t.dat_ink as dat,
            t.usl as usl_b, t.org as org_b, t.dopl, t.priznak as cd_tp
             from a_kwtp_day t, arch_kart k, s_reu_trest s, oper op
           where t.lsk=k.lsk and k.reu=s.reu and t.oper=op.oper
           and t.dat_ink between gdt(1,11,2018) and gdt(30,11,2018)
           and t.mg='201811' and k.mg=t.mg) v, arch_kart k
       where k.lsk = v.lsk and k.mg='201811'
         and v.oborot = 1
       group by v.usl,
                v.org,
                v.trest,
                v.reu,
                v.fk_distr,
                mg_,
                to_char(sysdate, 'DD/MM/YYYY HH24:MI'),
                v.var,
                k.reu,
                k.kul,
                k.nd,
                decode(k.status, 1, 0, 1),
                v.dopl,
                v.oper,
                v.cd_tp,
                v.dat;

    delete from xxito10 t where t.mg = mg_;
    insert into xxito10
      (usl, org, summa, trest, reu, mg, var, forreu, oborot, dopl, dat)
      select v.usl,
             v.org,
             sum(v.summa),
             v.trest,
             v.reu,
             mg_,
             v.var,
             v.forreu,
             v.oborot,
             v.dopl,
             v.dat
        from xxito11 v
       where v.mg = mg_
       group by v.usl,
                v.org,
                v.trest,
                v.reu,
                mg_,
                to_char(sysdate, 'DD/MM/YYYY HH24:MI'),
                v.var,
                v.forreu,
                v.oborot,
                v.dopl,
                v.dat;
    logger.log_(time_, 'gen.gen_opl_xito10 ' || mg_);

    logger.ins_period_rep('7', mg_, null, 0);
    logger.ins_period_rep('2', mg_, null, 0);
    logger.ins_period_rep('15', mg_, null, 0);
    logger.ins_period_rep('17', mg_, null, 0);
    logger.ins_period_rep('23', mg_, null, 0);
    logger.ins_period_rep('35', mg_, null, 0);
    logger.ins_period_rep('59', mg_, null, 0);
    logger.ins_period_rep('61', mg_, null, 0);
    logger.ins_period_rep('65', mg_, null, 0);
    commit;
  end;
end gen2;
/

