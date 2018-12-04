CREATE OR REPLACE PACKAGE BODY SCOTT.c_load_privs IS
--Пакет посвещен загрузке и обработке реестров льготников

--очистить подготовительные справочники
procedure clear_spr is
begin
  delete from prep_street;
  delete from prep_house;
end clear_spr;

--очистить подготовительные таблицы
procedure clear_tabs is
begin
  delete from load_privs;
  delete from prep_file;
end clear_tabs;

--добавить строку с наименованием файла, обновить залитые строки
procedure add_file(p_name in prep_file.name%type) is
 l_id number;
begin
  insert into prep_file(name)
   values(p_name)
   returning id into l_id;
  update load_privs t set t.fk_file=l_id where t.fk_file is null;
end;

--подоговить таблицу соответствий улиц
procedure prep_street is
begin
  insert into prep_street
    (ext_nylic)
  select distinct t.nylic from load_privs t
   where not exists 
    (select * from prep_street r where t.nylic=r.ext_nylic);
end prep_street;

--подоговить таблицу соответствий домов 
procedure prep_house is
begin
--загрузить только новые дома
insert into prep_house
  (ext_ndom, ext_nkorp, ext_nylic)
select distinct t.ndom, t.nkorp, t.nylic
   from prep_street r join
   load_privs t on r.ext_nylic=t.nylic
   where not exists (select * from prep_house p where p.ext_nylic=r.ext_nylic
                     and p.ext_ndom=t.ndom and nvl(p.ext_nkorp,'XXXXX')=nvl(t.nkorp,'XXXXX'))
   and r.kul is not null;

--попытаться проставить в домах без буквы корректный номер дома
--в домах с буквой - пользователь сам проставит
update prep_house t
 set t.nd=(select max(k.nd) from kart k, prep_street s
    where k.kul=s.kul and s.ext_nylic=t.ext_nylic and k.nd=lpad(t.ext_ndom,6,'0')
    and k.psch not in (8,9))
 where t.nd is null
       and t.ext_nkorp is null
 and exists
 (select k.* from kart k, prep_street s
    where k.kul=s.kul and s.ext_nylic=t.ext_nylic and k.nd=lpad(t.ext_ndom,6,'0')
    and k.psch not in (8,9));

end;

--подготовка таблицы к выгрузке
procedure prep_output(p_mg in params.period%type, p_file in number, p_cnt out number) is
 l_mg params.period%type;
 l_cnt number;
begin
/*  select '201509' into l_mg from params p;*/
  l_mg:=p_mg;
  delete from load_privs t where t.tp=1 and t.fk_file=p_file;
  delete from tmp_a_charge2;
  delete from tmp_a_nabor2;
  
  insert into tmp_a_charge2
    (id, lsk, usl, summa, kart_pr_id, spk_id, type, test_opl, test_cena, test_tarkoef, test_spk_koef, main, lg_doc_id, 
    npp, sch, kpr, kprz, kpro, kpr2, opl, mgfrom, mgto)
  select t.id, t.lsk, t.usl, t.summa, t.kart_pr_id, t.spk_id, t.type, t.test_opl, t.test_cena, t.test_tarkoef,
   t.test_spk_koef, t.main, t.lg_doc_id, t.npp, t.sch, t.kpr, t.kprz, t.kpro, t.kpr2, t.opl, t.mgfrom, t.mgto
  from a_charge2 t, v_load_privs m where l_mg between t.mgfrom and t.mgto
  and t.lsk=m.lsk
  and m.fk_file=p_file;
  
  insert into tmp_a_nabor2
   (lsk, usl, org, koeff, norm, fk_tarif, fk_vvod, vol, fk_dvb, vol_add, kf_kpr, sch_auto, nrm_kpr, kf_kpr_sch, kf_kpr_wrz, 
   kf_kpr_wro, kf_kpr_wrz_sch, kf_kpr_wro_sch, limit, nrm_kpr2, id, mgfrom, mgto)
  select t.lsk, t.usl, t.org, t.koeff, t.norm, t.fk_tarif, t.fk_vvod, t.vol, t.fk_dvb, t.vol_add, t.kf_kpr, t.sch_auto, 
  t.nrm_kpr, t.kf_kpr_sch, t.kf_kpr_wrz, t.kf_kpr_wro, t.kf_kpr_wrz_sch, t.kf_kpr_wro_sch, t.limit, t.nrm_kpr2, t.id, t.mgfrom, t.mgto
  from a_nabor2 t, v_load_privs m where l_mg between t.mgfrom and t.mgto
  and t.lsk=m.lsk
  and m.fk_file=p_file;
  
  --подсчитать кол-во записей - источников
  select nvl(count(*),0) into l_cnt from load_privs t where nvl(t.tp,0)=0 and t.fk_file=p_file;
  
  insert into load_privs
    (fk_src, org1, datn, posel, nasp, nylic, ndom, nkorp, nkw, nkomn, lchet, famil,
     imja, otch, drog, id_pku, pku, gku1, lchet1, ed_izm1, fakt1, sum_f1, prz1,
     gku2, lchet2, ed_izm2, fakt2, sum_f2, norm2, fakt21, sum_f21, o_pl2, prz2,
     gku3, lchet3, ed_izm3, fakt3, sum_f3, norm3, pr3_1, pr3_2, pr3_3, o_pl3,
     prz3, gku4, lchet4, ed_izm4, fakt4, sum_f4, norm4, prz4, gku5, lchet5,
     ed_izm5, fakt5, sum_f5, norm5, fakt51, sum_f51, o_pl5, prz5, gku6, lchet6,
     ed_izm6, fakt6, sum_f6, norm6, prz6, gku7, lchet7, ed_izm7, fakt7, sum_f7,
     norm7, fakt71, sum_f71, o_pl7, prz7, gku8, lchet8, ed_izm8, fakt8, sum_f8,
     norm8, prz8, gku9, lchet9, ed_izm9, fakt9, sum_f9, norm9, fakt91, tf_n,
     tf_sv, o_pl9, prz9, gku10, lchet10, ed_izm10, fakt10, sum_f10, prz10, tp, fk_file)
  select /*+ USE_HASH( m, s, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, c1, c2, c4, c5, c6, c7, c8, c9, c10, c11, c12) */ 
      m.id, m.org1, m.datn, m.posel, m.nasp, m.nylic, m.ndom, m.nkorp, m.nkw, m.nkomn, 
      s.lsk as lchet, m.famil, m.imja, m.otch, m.drog, m.id_pku, m.pku,
       /*'Электроэнергия' as gku1,
       s.lsk as lchet1,
       'квт.' as edizm1,*/
       m.gku1, m.lchet1, m.ed_izm1,
       e5.test_opl as fakt1,
       e5.summa_itg as sum_f1,
       case when nvl(e5.test_opl,0)<>0 then 1 else null end as prz1,

       /*'Электроэнергия на ОДН' as gku2,
       s.lsk as lchet2,
       'квт.' as ed_izm2,*/
       m.gku2, m.lchet2, m.ed_izm2,
       nvl(e6.test_opl,0) as fakt2,
       e6.summa_itg as sum_f2,
       e6.nrm as norm2,
       case when nvl(s.opl,0)<>0 then
                 e6.test_opl/s.opl
                 else 0 end as fakt21,
       case when nvl(s.opl,0)<>0 then
                 e6.summa_itg/s.opl
                 else null end as sum_f21,
       s.opl as o_pl2,
       case when nvl(e6.test_opl,0)<>0 then 1 else null end as prz2,

       m.gku3,
       m.lchet3,
       m.ed_izm3,
       0 as fakt3,
       null as sum_f3,
       null as norm3,
       null as pr3_1,
       null as pr3_2,
       null as pr3_3,
       null as o_pl3,
       null as prz3,

/*       'ХВС' as gku4,
       s.lsk as lchet4,
       'м3' as edizm4,*/
       m.gku4, m.lchet4, m.ed_izm4,

       nvl(e7.test_opl,0) as fakt4,
       e7.summa_itg as sum_f4,
       e7.norm as norm4,
       case when nvl(e7.test_opl,0)<>0 then 1 else null end as prz4,

/*       'Холодная вода, ОДН' as gku5,
       s.lsk as lchet5,
       'м3' as ed_izm5,*/
       m.gku5,m.lchet5, m.ed_izm5,
       
       nvl(e8.test_opl,0) as fakt5,
       e8.summa_itg as sum_f5,
       e8.nrm as norm5,
       case when nvl(s.opl,0)<>0 then
                 e8.test_opl/s.opl
                 else 0 end as fakt51,
       case when nvl(s.opl,0)<>0 then
                 e8.summa_itg/s.opl
                 else null end as sum_f51,
       s.opl as o_pl5,
       case when nvl(e8.test_opl,0)<>0 then 1 else null end as prz5,
       
/*       'Горячая вода' as gku6,
       s.lsk as lchet6,
       'м3' as edizm6,*/
       m.gku6, m.lchet6, m.ed_izm6,
       
       nvl(e9.test_opl,0) as fakt6,
       e9.summa_itg as sum_f6,
       e9.norm as norm6,
       case when nvl(e9.test_opl,0)<>0 then 1 else null end as prz6,

/*       'Горячая вода, ОДН' as gku7,
       s.lsk as lchet7,
       'м3' as edizm7,*/
       m.gku7, m.lchet7, m.ed_izm7,
       
       nvl(e10.test_opl,0) as fakt7,
       e10.summa_itg as sum_f7,
       e10.nrm as norm7,
       case when nvl(s.opl,0)<>0 then
                 e10.test_opl/s.opl
                 else 0 end as fakt71,
       case when nvl(s.opl,0)<>0 then
                 e10.summa_itg/s.opl
                 else null end as sum_f71,
       s.opl as o_pl7,
       case when nvl(e10.test_opl,0)<>0 then 1 else null end as prz7,
       
/*       'Канализация' as gku8,
       s.lsk as lchet8,
       'м3' as edizm8,*/
       m.gku8, m.lchet8, m.ed_izm8,
       
       nvl(e11.test_opl,0) as fakt8,
       e11.summa_itg as sum_f8,
       e11.norm as norm8,
       case when nvl(e11.test_opl,0)<>0 then 1 else null end as prz8,
       
/*       'Отопление' as gku9,
       s.lsk as lchet9,
       'м2' as edizm9,*/
       m.gku9, m.lchet9, m.ed_izm9,
       
       nvl(e12.test_opl,0) as fakt9,
       e12.summa_itg as sum_f9,
       e12.norm as norm9,
       case when nvl(s.opl,0)<>0 then
                 e12.test_opl/s.opl
                 else 0 end as fakt91,
       c12.tf1 as tf_n,
       c12.tf2 as tf_sv,
       s.opl as o_pl9,
       case when nvl(e12.test_opl,0)<>0 then 1 else null end as prz9,
                           
/*       'Газ в баллонах' as gku10,
       null as lchet10,
       null as edizm10,*/
       m.gku10, m.lchet10, m.ed_izm10,
       
       0 as fakt10,
       null as sum_f10,
       null as prz10,
       1 as tp,
       p_file as fk_file
      from 
      v_load_privs m left join 
      (select s.* from arch_kart s, s_reu_trest e where s.mg=l_mg
       /*and e.reu='01'
       and s.lsk='00000001'*/
       and s.reu=e.reu
       and s.psch not in (8,9) --только открытые
       and s.status not in (7)--убрал нежилые
       ) s on s.lsk=m.lsk
           left join t_org c on s.reu=c.reu
           left join t_org_tp tp on tp.cd='Город'
           left join t_org c2 on c2.fk_orgtp=tp.id
           left join spul l on s.kul=l.id
           left join 
      (select s.lsk, 
       sum(s.summa) as summa_itg
         from tmp_a_charge2 s, usl u 
          where 
          l_mg between s.mgFrom and s.mgTo
           and s.usl=u.usl and
         u.cd in ('т/сод', 'т/сод/св.нор', 'лифт', 'лифт/св.нор', 'дерат.', 'дерат/св.нор', 'мус.площ.', 'мус.площ./св.нор',
         'выв.мус.', 'выв.мус./св.нор')
         and s.type=1 --текущее содержание, вместе с под-услугами
       group by s.lsk) e2 on s.lsk = e2.lsk
           left join 
      (select s.lsk,
       sum(s.summa) as summa_itg
         from tmp_a_charge2 s, usl u where 
         l_mg between s.mgFrom and s.mgTo
         and s.usl=u.usl and
        u.cd in ('кап.', 'кап/св.нор') and s.type=1 --капремонт
       group by s.lsk) e3 on s.lsk = e3.lsk
           left join 
      (select s.lsk,
       sum(s.summa) as summa_itg
         from tmp_a_charge2 s, usl u where 
          l_mg between s.mgFrom and s.mgTo
         and s.usl=u.usl and
        u.cd in ('найм') and s.type=1 --найм
       group by s.lsk) e4 on s.lsk = e4.lsk
           left join 
      (select s.lsk,
       sum(s.test_opl) as test_opl,
       sum(s.summa) as summa_itg
         from tmp_a_charge2 s, usl u 
         where s.usl=u.usl and
         l_mg between s.mgFrom and s.mgTo and 
        u.cd in ('эл.энерг.2','эл.эн.2/св.нор', 'эл.эн.учет УО', 'эл.эн.учет УО 0 зар.') and s.type=1 --эл.энерг
       group by s.lsk) e5 on s.lsk = e5.lsk
           left join 
      (select s.lsk,
       sum(s.test_opl) as test_opl,
       sum(s.summa) as summa_itg,
       null as nrm
         from tmp_a_charge2 s
         join usl u on s.usl=u.usl and u.cd in ('эл.эн.ОДН', 'эл.эн.МОП2', 'EL_SOD') and s.type=1 and
         l_mg between s.mgFrom and s.mgTo
       group by s.lsk
      /*select s.lsk,
       max(s.test_opl) as test_opl,
       sum(s.summa) as summa_itg,
       max(d.nrm) as nrm
         from tmp_a_charge2 s
         join tmp_a_nabor2 n on s.lsk=n.lsk and 
         l_mg between s.mgFrom and s.mgTo and 
         l_mg between n.mgFrom and n.mgTo
         and s.usl=n.usl
         join a_vvod d on n.fk_vvod=d.id and n.usl=d.usl
         and l_mg=d.mg
         join usl u2 on n.usl=u2.usl and u2.cd in ('эл.энерг.2', 'эл.эн.учет УО', 'эл.эн.учет УО 0 зар.', 'эл.эн.ОДН', 'эл.эн.МОП2', 'EL_SOD') --АД
         join usl u on s.usl=u.usl and u.cd in ('эл.эн.ОДН', 'эл.эн.МОП2', 'EL_SOD') and s.type=1 --эл.энерг
       group by s.lsk*/) e6 on s.lsk = e6.lsk
           left join 
      (select s.lsk,
       sum(s.test_opl) as test_opl,
       sum(s.summa) as summa_itg,
       max(n.norm) as norm
         from tmp_a_charge2 s, tmp_a_nabor2 n, usl u where 
         s.usl=u.usl and s.lsk=n.lsk and
         l_mg between s.mgFrom and s.mgTo and 
         l_mg between n.mgFrom and n.mgTo
         and s.usl=n.usl and
         u.cd in ('х.вода', 'х.вода/св.нор') and s.type=1
       group by s.lsk) e7 on s.lsk = e7.lsk
           left join 
      (select s.lsk,
       sum(s.test_opl) as test_opl,
       sum(s.summa) as summa_itg,
       null as nrm
         from tmp_a_charge2 s
         join usl u on s.usl=u.usl and u.cd in ('х.вода.ОДН', 'HW_SOD') and s.type=1 and
         l_mg between s.mgFrom and s.mgTo
       group by s.lsk
       /*select s.lsk,
       sum(s.test_opl) as test_opl,
       sum(s.summa) as summa_itg,
       max(d.nrm) as nrm
         from tmp_a_charge2 s
         join tmp_a_nabor2 n on s.lsk=n.lsk and 
         l_mg between s.mgFrom and s.mgTo and 
         l_mg between n.mgFrom and n.mgTo
         and s.usl=n.usl
         join a_vvod d on n.fk_vvod=d.id and n.usl=d.usl and l_mg=d.mg
         join usl u2 on n.usl=u2.usl and u2.cd in ('х.вода')
         join usl u on s.usl=u.usl and u.cd in ('х.вода.ОДН', 'HW_SOD') and s.type=1
       group by s.lsk*/
       ) e8 on s.lsk = e8.lsk
           left join 
      (select s.lsk,
       sum(s.test_opl) as test_opl,
       sum(s.summa) as summa_itg,
       max(n.norm) as norm
         from tmp_a_charge2 s, tmp_a_nabor2 n, usl u where 
         s.usl=u.usl and s.lsk=n.lsk and 
         l_mg between s.mgFrom and s.mgTo and 
         l_mg between n.mgFrom and n.mgTo
         and s.usl=n.usl and
         u.cd in ('г.вода', 'г.вода/св.нор') and s.type=1
       group by s.lsk) e9 on s.lsk = e9.lsk
           left join 
      (select s.lsk,
       sum(s.test_opl) as test_opl,
       sum(s.summa) as summa_itg,
       null as nrm
         from tmp_a_charge2 s
         join usl u on s.usl=u.usl and u.cd in ('г.вода.ОДН', 'GW_SOD') and s.type=1 and
         l_mg between s.mgFrom and s.mgTo
       group by s.lsk
       /*select s.lsk,
       sum(s.test_opl) as test_opl,
       sum(s.summa) as summa_itg,
       max(d.nrm) as nrm
         from tmp_a_charge2 s
         join tmp_a_nabor2 n on s.lsk=n.lsk and 
         l_mg between s.mgFrom and s.mgTo and 
         l_mg between n.mgFrom and n.mgTo
         and s.usl=n.usl
         join a_vvod d on n.fk_vvod=d.id and n.usl=d.usl
         and l_mg=d.mg
         join usl u2 on n.usl=u2.usl and u2.cd in ('г.вода')
         join usl u on s.usl=u.usl and u.cd in ('г.вода.ОДН', 'GW_SOD') and s.type=1 -- г.в. ОДН
       group by s.lsk*/) e10 on s.lsk = e10.lsk
           left join 
      (select s.lsk,
       sum(s.test_opl) as test_opl,
       sum(s.summa) as summa_itg,
       max(n.norm) as norm
         from tmp_a_charge2 s, tmp_a_nabor2 n, usl u where 
         l_mg between s.mgFrom and s.mgTo and s.usl=u.usl and s.lsk=n.lsk and 
         l_mg between n.mgFrom and n.mgTo
         and s.usl=n.usl and
         u.cd in ('канализ', 'канализ/св.нор') and s.type=1
       group by s.lsk) e11 on s.lsk = e11.lsk
           left join 
      (select s.lsk,
       sum(s.test_opl) as test_opl,
       sum(s.summa) as summa_itg,
       max(n.norm) as norm
         from tmp_a_charge2 s, tmp_a_nabor2 n, usl u where 
         l_mg between s.mgFrom and s.mgTo and s.usl=u.usl and s.lsk=n.lsk and 
         l_mg between n.mgFrom and n.mgTo
         and s.usl=n.usl and
         u.cd in ('отоп', 'отоп/св.нор', 'отоп.гкал.') and s.type=1 --возьмутся услуги у кого какие, проверять!
       group by s.lsk) e12 on s.lsk = e12.lsk

       left join
       (select n.lsk, round(sum(case when u.usl_norm = 0 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
               round(sum(case when u.usl_norm = 1 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
         from 
           tmp_a_nabor2 n join usl u on n.usl=u.usl 
           and l_mg between n.mgFrom and n.mgTo  
           join a_prices r on n.usl=r.usl and r.mg=l_mg
        where r.mg=l_mg
        and u.cd in ('т/сод', 'т/сод/св.нор', 'лифт', 'лифт/св.нор', 'дерат.', 'дерат/св.нор', 'мус.площ.', 'мус.площ./св.нор',
               'выв.мус.', 'выв.мус./св.нор')
        group by n.lsk       
         ) c1
         on s.lsk=c1.lsk
       left join
       (select n.lsk, round(sum(case when u.usl_norm = 0 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
               round(sum(case when u.usl_norm = 1 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
         from 
           tmp_a_nabor2 n join usl u on n.usl=u.usl 
           and l_mg between n.mgFrom and n.mgTo  
           join a_prices r on n.usl=r.usl and r.mg=l_mg
        where r.mg=l_mg
        and u.cd in ('кап.', 'кап/св.нор')
        group by n.lsk       
         ) c2
         on s.lsk=c2.lsk
         
         
       left join
       (select n.lsk, round(sum(case when u.usl_norm = 0 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
               round(sum(case when u.usl_norm = 1 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
         from 
           tmp_a_nabor2 n join usl u on n.usl=u.usl 
           and l_mg between n.mgFrom and n.mgTo  
           join a_prices r on n.usl=r.usl and r.mg=l_mg
        where r.mg=l_mg
        and u.cd in ('найм')
        group by n.lsk       
         ) c4
         on s.lsk=c4.lsk
       left join
       (select n.lsk, round(sum(case when u.usl_norm = 0 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
               round(sum(case when u.usl_norm = 1 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
         from 
           tmp_a_nabor2 n join usl u on n.usl=u.usl 
           and l_mg between n.mgFrom and n.mgTo  
           join a_prices r on n.usl=r.usl and r.mg=l_mg
        where r.mg=l_mg
        and u.cd in ('эл.энерг.2','эл.эн.2/св.нор', 'эл.эн.учет УО', 'эл.эн.учет УО 0 зар.')
        group by n.lsk       
         ) c5
         on s.lsk=c5.lsk
         
       left join
       (select n.lsk, round(sum(case when u.usl_norm = 0 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
               round(sum(case when u.usl_norm = 1 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
         from 
           tmp_a_nabor2 n join usl u on n.usl=u.usl 
           and l_mg between n.mgFrom and n.mgTo  
           join a_prices r on n.usl=r.usl and r.mg=l_mg
        where r.mg=l_mg
        and u.cd in ('эл.эн.ОДН')
        group by n.lsk       
         ) c6
         on s.lsk=c6.lsk
         
       left join
       (select n.lsk, round(sum(case when u.usl_norm = 0 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
               round(sum(case when u.usl_norm = 1 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
         from 
           tmp_a_nabor2 n join usl u on n.usl=u.usl 
           and l_mg between n.mgFrom and n.mgTo  
           join a_prices r on n.usl=r.usl and r.mg=l_mg
        where r.mg=l_mg
        and u.cd in ('х.вода', 'х.вода/св.нор')
        group by n.lsk       
         ) c7
         on s.lsk=c7.lsk       
         
       left join
       (select n.lsk, round(sum(case when u.usl_norm = 0 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
               round(sum(case when u.usl_norm = 1 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
         from 
           tmp_a_nabor2 n join usl u on n.usl=u.usl 
           and l_mg between n.mgFrom and n.mgTo  
           join a_prices r on n.usl=r.usl and r.mg=l_mg
        where r.mg=l_mg
        and u.cd in ('х.вода.ОДН')
        group by n.lsk       
         ) c8
         on s.lsk=c8.lsk       

       left join
       (select n.lsk, round(sum(case when u.usl_norm = 0 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
               round(sum(case when u.usl_norm = 1 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
         from 
           tmp_a_nabor2 n join usl u on n.usl=u.usl 
           and l_mg between n.mgFrom and n.mgTo  
           join a_prices r on n.usl=r.usl and r.mg=l_mg
        where r.mg=l_mg
        and u.cd in ('г.вода', 'г.вода/св.нор')
        group by n.lsk       
         ) c9
         on s.lsk=c9.lsk       

       left join
       (select n.lsk, round(sum(case when u.usl_norm = 0 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
               round(sum(case when u.usl_norm = 1 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
         from 
           tmp_a_nabor2 n join usl u on n.usl=u.usl 
           and l_mg between n.mgFrom and n.mgTo  
           join a_prices r on n.usl=r.usl and r.mg=l_mg
        where r.mg=l_mg 
        and u.cd in ('г.вода.ОДН')
        group by n.lsk       
         ) c10
         on s.lsk=c10.lsk       

       left join
       (select n.lsk, round(sum(case when u.usl_norm = 0 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
               round(sum(case when u.usl_norm = 1 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
         from 
           tmp_a_nabor2 n join usl u on n.usl=u.usl 
           and l_mg between n.mgFrom and n.mgTo  
           join a_prices r on n.usl=r.usl and r.mg=l_mg
        where r.mg=l_mg 
        and u.cd in ('канализ', 'канализ/св.нор')
        group by n.lsk       
         ) c11
         on s.lsk=c11.lsk       

       left join
       (select n.lsk, round(sum(case when u.usl_norm = 0 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
               round(sum(case when u.usl_norm = 1 then 
          case when n.koeff is not null and u.sptarn in (0,2,3) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
         from 
           tmp_a_nabor2 n join usl u on n.usl=u.usl 
           and l_mg between n.mgFrom and n.mgTo  
           join a_prices r on n.usl=r.usl and r.mg=l_mg
        where r.mg=l_mg 
        and u.cd in ('отоп', 'отоп/св.нор')
        group by n.lsk       
         ) c12
         on s.lsk=c12.lsk    
      where m.fk_file=p_file

      order by l.name, s.nd, s.kw;

  --подсчитать кол-во записей - после выгрузки
  select l_cnt-nvl(count(*),0) into l_cnt
    from load_privs t where nvl(t.tp,0)=1 and t.fk_file=p_file;
  if l_cnt > 0 then  
    --кол-во записей в выгрузке меньше чем в источнике!
    p_cnt:=1;
  elsif l_cnt < 0 then  
    --кол-во записей в выгрузке больше чем в источнике!
    p_cnt:=2;
  else
    --кол-во записей совпало
    p_cnt:=0;
  end if;
    

end;


--рефкурсор для выгрузки
procedure rep(p_file in number, prep_refcursor in out rep_refcursor) is
begin
  open prep_refcursor for
    select org1, datn, posel, nasp, nylic, ndom, nkorp, nkw, nkomn, lchet,
           famil, imja, otch, drog, id_pku, pku, gku1, lchet1, ed_izm1,
           fakt1, sum_f1, prz1, gku2, lchet2, ed_izm2, fakt2, sum_f2, norm2,
           fakt21, sum_f21, o_pl2, prz2, gku3, lchet3, ed_izm3, fakt3,
           sum_f3, norm3, pr3_1, pr3_2, pr3_3, o_pl3, prz3, gku4, lchet4,
           ed_izm4, fakt4, sum_f4, norm4, prz4, gku5, lchet5, ed_izm5, fakt5,
           sum_f5, norm5, fakt51, sum_f51, o_pl5, prz5, gku6, lchet6,
           ed_izm6, fakt6, sum_f6, norm6, prz6, gku7, lchet7, ed_izm7, fakt7,
           sum_f7, norm7, fakt71, sum_f71, o_pl7, prz7, gku8, lchet8,
           ed_izm8, fakt8, sum_f8, norm8, prz8, gku9, lchet9, ed_izm9, fakt9,
           sum_f9, norm9, fakt91, tf_n, tf_sv, o_pl9, prz9, gku10, lchet10,
           ed_izm10, fakt10, sum_f10, prz10
      from load_privs t
     where t.fk_file = p_file and t.tp=1;

end;
END c_load_privs;
/

