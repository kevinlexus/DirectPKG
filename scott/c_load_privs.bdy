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


--подготовка таблицы к выгрузке - версия в одну строку по fk_klsk (фин.лиц.счету)
procedure prep_output2(p_mg in params.period%type, -- период
                       p_file in number,           -- Id файла
                       p_cnt out number,            -- кол-во записей, для сверки
                       p_tp in number             -- тип (0-основная выгрузка, 1-ТКО)
                       ) is
 l_mg params.period%type;
 l_cnt number;
begin
/*  select '201509' into l_mg from params p;*/
  l_mg:=p_mg;
  delete from load_privs t where t.tp=1 and t.fk_file=p_file;
  delete from tmp_a_charge2;
  delete from tmp_a_nabor2;

  insert into tmp_a_charge2
    (id, lsk, k_lsk_id, usl, summa, kart_pr_id, spk_id, type, test_opl, test_cena, test_tarkoef, test_spk_koef, main, lg_doc_id, npp, sch, kpr, kprz, kpro, kpr2, opl, mgfrom, mgto)
    select t.id, t.lsk, m.k_lsk_id, t.usl, t.summa, t.kart_pr_id, t.spk_id, t.type, t.test_opl, t.test_cena, t.test_tarkoef, t.test_spk_koef, t.main, t.lg_doc_id, t.npp, t.sch, t.kpr, t.kprz, t.kpro, t.kpr2, t.opl, t.mgfrom, t.mgto
      from a_charge2 t, (select t.id, k.lsk, k.k_lsk_id, k.fk_tp, t."ORG1", t."DATN", t."POSEL", t."NASP", t."NYLIC", t."NDOM", t."NKORP", t."NKW", t."NKOMN", t."LCHET", t."FAMIL", t."IMJA", t."OTCH", t."DROG", t."ID_PKU", t."PKU", t."GKU1", t."LCHET1", t."ED_IZM1", t."FAKT1", t."SUM_F1", t."PRZ1", t."GKU2", t."LCHET2", t."ED_IZM2", t."FAKT2", t."SUM_F2", t."NORM2", t."FAKT21", t."SUM_F21", t."O_PL2", t."PRZ2", t."GKU3", t."LCHET3", t."ED_IZM3", t."FAKT3", t."SUM_F3", t."NORM3", t."PR3_1", t."PR3_2", t."PR3_3", t."O_PL3", t."PRZ3", t."GKU4", t."LCHET4", t."ED_IZM4", t."FAKT4", t."SUM_F4", t."NORM4", t."PRZ4", t."GKU5", t."LCHET5", t."ED_IZM5", t."FAKT5", t."SUM_F5", t."NORM5", t."FAKT51", t."SUM_F51", t."O_PL5", t."PRZ5", t."GKU6", t."LCHET6", t."ED_IZM6", t."FAKT6", t."SUM_F6", t."NORM6", t."PRZ6", t."GKU7", t."LCHET7", t."ED_IZM7", t."FAKT7", t."SUM_F7", t."NORM7", t."FAKT71", t."SUM_F71", t."O_PL7", t."PRZ7", t."GKU8", t."LCHET8", t."ED_IZM8", t."FAKT8", t."SUM_F8", t."NORM8", t."PRZ8", t."GKU9", t."LCHET9", t."ED_IZM9", t."FAKT9", t."SUM_F9", t."NORM9", t."FAKT91", t."TF_N", t."TF_SV", t."O_PL9", t."PRZ9", t."GKU10", t."LCHET10", t."ED_IZM10", t."FAKT10", t."SUM_F10", t."PRZ10", t."FK_LSK", t."FK_FILE", t."TP"
               from load_privs t
               left join prep_house t2
                 on t.nylic = t2.ext_nylic
                and nvl(t.ndom, 'XXX') = nvl(t2.ext_ndom, 'XXX')
                and nvl(t.nkorp, 'XXX') = nvl(t2.ext_nkorp, 'XXX')
               left join prep_street t3
                 on t3.ext_nylic = t2.ext_nylic
               left join arch_kart k
                 on k.nd = t2.nd and k.mg=l_mg
                and k.kul = t3.kul
                and upper(k.kw) = lpad(upper(t.nkw), 7, '0')
                and k.psch not in (8, 9)
                and k.sel1 = 1
                and k.fk_tp in (select id from v_lsk_tp where cd in ('LSK_TP_MAIN', 'LSK_TP_RSO'))
              where nvl(t.tp, 0) = 0) m
     where l_mg between t.mgfrom and t.mgto
       and t.lsk = m.lsk
       and m.fk_file = p_file;


  insert into tmp_a_nabor2
    (lsk, k_lsk_id, usl, org, koeff, norm, mgfrom, mgto)
    select k.lsk, k.k_lsk_id, t.usl, t.org, t.koeff, t.norm, t.mgfrom, t.mgto
      from arch_kart k join a_nabor2 t on k.lsk=t.lsk
     where l_mg=k.mg and k.psch not in (8,9) and l_mg between t.mgfrom and t.mgto;

    --подсчитать кол-во записей - источников
    select nvl(count(*),0) into l_cnt from load_privs t where nvl(t.tp,0)=0 and t.fk_file=p_file;

  if p_tp = 0 then
    -- основная выгрузка льготников
    insert into load_privs
      (fk_src, org1, datn, posel, nasp, nylic, ndom, nkorp, nkw, nkomn, famil, imja, otch, drog,
      id_pku, pku, gku1, lchet1, ed_izm1, fakt1, sum_f1, prz1, gku2, lchet2, ed_izm2, fakt2, sum_f2,
      norm2, fakt21, sum_f21, o_pl2, prz2, gku3, lchet3, ed_izm3, fakt3, sum_f3, norm3, pr3_1, pr3_2,
       pr3_3, o_pl3, prz3, gku4, lchet4, ed_izm4, fakt4, sum_f4, norm4, prz4, gku5, lchet5, ed_izm5,
       fakt5, sum_f5, norm5, fakt51, sum_f51, o_pl5, prz5, gku6, lchet6, ed_izm6, fakt6, sum_f6, norm6,
       prz6, gku7, lchet7, ed_izm7, fakt7, sum_f7, norm7, fakt71, sum_f71, o_pl7, prz7, gku8,
       lchet8, ed_izm8, fakt8, sum_f8, norm8, prz8, gku9, lchet9, ed_izm9, fakt9, sum_f9, norm9,
       fakt91, tf_n, tf_sv, o_pl9, prz9, gku10, lchet10, ed_izm10, fakt10, sum_f10, prz10, tp, fk_file)
      select /*+ USE_HASH( m, s, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, c1, c2, c4, c5, c6, c7, c8, c9, c10, c11, c12) */
       m.id, m.org1, m.datn, m.posel, m.nasp, m.nylic, m.ndom, m.nkorp, m.nkw, m.nkomn, m.famil, m.imja, m.otch, m.drog, m.id_pku, m.pku,
       /*'Электроэнергия' as gku1,
       s.lsk as lchet1,
       'квт.' as edizm1,*/ m.gku1, m.lchet1, m.ed_izm1, e5.test_opl as fakt1, e5.summa_itg as sum_f1,case
         when nvl(e5.test_opl, 0) <> 0 then
          1
         else
          null
       end as prz1,

       /*'Электроэнергия на ОДН' as gku2,
       s.lsk as lchet2,
       'квт.' as ed_izm2,*/ m.gku2, m.lchet2, m.ed_izm2, nvl(e6.test_opl, 0) as fakt2, e6.summa_itg as sum_f2, e6.nrm as norm2,case
         when nvl(m.opl, 0) <> 0 then
          e6.test_opl / m.opl
         else
          0
       end as fakt21,case
         when nvl(m.opl, 0) <> 0 then
          e6.summa_itg / m.opl
         else
          null
       end as sum_f21, m.opl as o_pl2,case
         when nvl(e6.test_opl, 0) <> 0 then
          1
         else
          null
       end as prz2,

       m.gku3, m.lchet3, m.ed_izm3, 0 as fakt3, null as sum_f3, null as norm3, null as pr3_1, null as pr3_2, null as pr3_3, null as o_pl3, null as prz3,

       /*       'ХВС' as gku4,
       s.lsk as lchet4,
       'м3' as edizm4,*/ m.gku4, m.lchet4, m.ed_izm4,

       nvl(e7.test_opl, 0) as fakt4, e7.summa_itg as sum_f4, e7.norm as norm4,case
         when nvl(e7.test_opl, 0) <> 0 then
          1
         else
          null
       end as prz4,

       /*       'Холодная вода, ОДН' as gku5,
       s.lsk as lchet5,
       'м3' as ed_izm5,*/ m.gku5, m.lchet5, m.ed_izm5,

       nvl(e8.test_opl, 0) as fakt5, e8.summa_itg as sum_f5, e8.nrm as norm5,case
         when nvl(m.opl, 0) <> 0 then
          e8.test_opl / m.opl
         else
          0
       end as fakt51,case
         when nvl(m.opl, 0) <> 0 then
          e8.summa_itg / m.opl
         else
          null
       end as sum_f51, m.opl as o_pl5,case
         when nvl(e8.test_opl, 0) <> 0 then
          1
         else
          null
       end as prz5,

       /*       'Горячая вода' as gku6,
       s.lsk as lchet6,
       'м3' as edizm6,*/ m.gku6, m.lchet6, m.ed_izm6,

       nvl(e9.test_opl, 0) as fakt6, e9.summa_itg as sum_f6, e9.norm as norm6,case
         when nvl(e9.test_opl, 0) <> 0 then
          1
         else
          null
       end as prz6,

       /*       'Горячая вода, ОДН' as gku7,
       s.lsk as lchet7,
       'м3' as edizm7,*/ m.gku7, m.lchet7, m.ed_izm7,

       nvl(e10.test_opl, 0) as fakt7, e10.summa_itg as sum_f7, e10.nrm as norm7,case
         when nvl(m.opl, 0) <> 0 then
          e10.test_opl / m.opl
         else
          0
       end as fakt71,case
         when nvl(m.opl, 0) <> 0 then
          e10.summa_itg / m.opl
         else
          null
       end as sum_f71, m.opl as o_pl7,case
         when nvl(e10.test_opl, 0) <> 0 then
          1
         else
          null
       end as prz7,

       /*       'Канализация' as gku8,
       s.lsk as lchet8,
       'м3' as edizm8,*/ m.gku8, m.lchet8, m.ed_izm8,

       nvl(e11.test_opl, 0) as fakt8, e11.summa_itg as sum_f8, e11.norm as norm8,case
         when nvl(e11.test_opl, 0) <> 0 then
          1
         else
          null
       end as prz8,

       /*       'Отопление' as gku9,
       s.lsk as lchet9,
       'м2' as edizm9,*/ m.gku9, m.lchet9, m.ed_izm9,

       nvl(e12.test_opl, 0) as fakt9, e12.summa_itg as sum_f9, e12.norm as norm9,case
         when nvl(m.opl, 0) <> 0 then
          e12.test_opl / m.opl
         else
          0
       end as fakt91, c12.tf1 as tf_n, c12.tf2 as tf_sv, m.opl as o_pl9,case
         when nvl(e12.test_opl, 0) <> 0 then
          1
         else
          null
       end as prz9,
       m.gku10, m.lchet10, m.ed_izm10,
       nvl(e13.test_opl, 0) as fakt10, e13.summa_itg as sum_f10, case
         when nvl(e13.test_opl, 0) <> 0 then
          1
         else
          null
       end as prz10,
       1 as tp, p_file as fk_file
        from (select t.id, max(k.opl) as opl, max(k.kul) as kul, k.k_lsk_id,
        t."ORG1", t."DATN", t."POSEL", t."NASP", t."NYLIC", t."NDOM", t."NKORP", t."NKW", t."NKOMN",
        t."FAMIL", t."IMJA", t."OTCH", t."DROG", t."ID_PKU", t."PKU", t."GKU1", t."LCHET1", t."ED_IZM1",
        t."FAKT1", t."SUM_F1", t."PRZ1", t."GKU2", t."LCHET2", t."ED_IZM2", t."FAKT2", t."SUM_F2", t."NORM2",
         t."FAKT21", t."SUM_F21", t."O_PL2", t."PRZ2", t."GKU3", t."LCHET3", t."ED_IZM3", t."FAKT3", t."SUM_F3",
          t."NORM3", t."PR3_1", t."PR3_2", t."PR3_3", t."O_PL3", t."PRZ3", t."GKU4", t."LCHET4", t."ED_IZM4",
          t."FAKT4", t."SUM_F4", t."NORM4", t."PRZ4", t."GKU5", t."LCHET5", t."ED_IZM5", t."FAKT5", t."SUM_F5",
          t."NORM5", t."FAKT51", t."SUM_F51", t."O_PL5", t."PRZ5", t."GKU6", t."LCHET6", t."ED_IZM6", t."FAKT6",
           t."SUM_F6", t."NORM6", t."PRZ6", t."GKU7", t."LCHET7", t."ED_IZM7", t."FAKT7", t."SUM_F7", t."NORM7",
            t."FAKT71", t."SUM_F71", t."O_PL7", t."PRZ7", t."GKU8", t."LCHET8", t."ED_IZM8", t."FAKT8", t."SUM_F8",
             t."NORM8", t."PRZ8", t."GKU9", t."LCHET9", t."ED_IZM9", t."FAKT9", t."SUM_F9", t."NORM9", t."FAKT91",
             t."TF_N", t."TF_SV", t."O_PL9", t."PRZ9", t."GKU10", t."LCHET10", t."ED_IZM10", t."FAKT10", t."SUM_F10",
              t."PRZ10", t."FK_LSK", t."FK_FILE", t."TP"
                 from load_privs t
                 left join prep_house t2
                   on t.nylic = t2.ext_nylic
                  and nvl(t.ndom, 'XXX') = nvl(t2.ext_ndom, 'XXX')
                  and nvl(t.nkorp, 'XXX') = nvl(t2.ext_nkorp, 'XXX')
                 left join prep_street t3
                   on t3.ext_nylic = t2.ext_nylic
                 left join arch_kart k
                   on k.nd = t2.nd and k.mg=l_mg
                  and k.kul = t3.kul
                  and upper(k.kw) = lpad(upper(t.nkw), 7, '0')
                  and k.psch not in (8, 9)
                  and k.sel1 = 1
                  and k.fk_tp in (select id from v_lsk_tp where cd in ('LSK_TP_MAIN', 'LSK_TP_RSO'))
                where nvl(t.tp, 0) = 0 and t.fk_file = p_file
                group by t.id, k.k_lsk_id, t."ORG1", t."DATN", t."POSEL", t."NASP", t."NYLIC", t."NDOM", t."NKORP",
                t."NKW", t."NKOMN", t."FAMIL", t."IMJA", t."OTCH", t."DROG", t."ID_PKU", t."PKU", t."GKU1", t."LCHET1",
                t."ED_IZM1", t."FAKT1", t."SUM_F1", t."PRZ1", t."GKU2", t."LCHET2", t."ED_IZM2", t."FAKT2", t."SUM_F2",
                t."NORM2", t."FAKT21", t."SUM_F21", t."O_PL2", t."PRZ2", t."GKU3", t."LCHET3", t."ED_IZM3", t."FAKT3",
                t."SUM_F3", t."NORM3", t."PR3_1", t."PR3_2", t."PR3_3", t."O_PL3", t."PRZ3", t."GKU4", t."LCHET4",
                t."ED_IZM4", t."FAKT4", t."SUM_F4", t."NORM4", t."PRZ4", t."GKU5", t."LCHET5", t."ED_IZM5", t."FAKT5",
                t."SUM_F5", t."NORM5", t."FAKT51", t."SUM_F51", t."O_PL5", t."PRZ5", t."GKU6", t."LCHET6", t."ED_IZM6",
                 t."FAKT6", t."SUM_F6", t."NORM6", t."PRZ6", t."GKU7", t."LCHET7", t."ED_IZM7", t."FAKT7", t."SUM_F7",
                 t."NORM7", t."FAKT71", t."SUM_F71", t."O_PL7", t."PRZ7", t."GKU8", t."LCHET8", t."ED_IZM8", t."FAKT8",
                 t."SUM_F8", t."NORM8", t."PRZ8", t."GKU9", t."LCHET9", t."ED_IZM9", t."FAKT9", t."SUM_F9", t."NORM9",
                 t."FAKT91", t."TF_N", t."TF_SV", t."O_PL9", t."PRZ9", t."GKU10", t."LCHET10", t."ED_IZM10", t."FAKT10",
                  t."SUM_F10", t."PRZ10", t."FK_LSK", t."FK_FILE", t."TP"
                ) m
    /*    left join (select s.*
                     from arch_kart s, s_reu_trest e
                    where s.mg = l_mg
                      and s.reu = e.reu
                      and s.psch not in (8, 9) --только открытые
                      and s.status not in (7) --убрал нежилые
                   ) s
          on s.lsk = m.lsk*/
    --    left join t_org c
    --      on s.reu = c.reu
        left join t_org_tp tp
          on tp.cd = 'Город'
        left join t_org c2
          on c2.fk_orgtp = tp.id
        left join spul l
          on m.kul = l.id
        left join (select s.k_lsk_id, sum(s.summa) as summa_itg
                     from tmp_a_charge2 s, usl u
                    where l_mg between s.mgFrom and s.mgTo
                      and s.usl = u.usl
                      and u.cd in ('т/сод',
                                   'т/сод/св.нор',
                                   'лифт',
                                   'лифт/св.нор',
                                   'дерат.',
                                   'дерат/св.нор',
                                   'мус.площ.',
                                   'мус.площ./св.нор',
                                   'выв.мус.',
                                   'выв.мус./св.нор')
                      and s.type = 1 --текущее содержание, вместе с под-услугами
                    group by s.k_lsk_id) e2
          on m.k_lsk_id = e2.k_lsk_id
        left join (select s.k_lsk_id, sum(s.summa) as summa_itg
                     from tmp_a_charge2 s, usl u
                    where l_mg between s.mgFrom and s.mgTo
                      and s.usl = u.usl
                      and u.cd in ('кап.', 'кап/св.нор')
                      and s.type = 1 --капремонт
                    group by s.k_lsk_id) e3
          on m.k_lsk_id = e3.k_lsk_id
        left join (select s.k_lsk_id, sum(s.summa) as summa_itg
                     from tmp_a_charge2 s, usl u
                    where l_mg between s.mgFrom and s.mgTo
                      and s.usl = u.usl
                      and u.cd in ('найм')
                      and s.type = 1 --найм
                    group by s.k_lsk_id) e4
          on m.k_lsk_id = e4.k_lsk_id
        left join (select s.k_lsk_id, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg
                     from tmp_a_charge2 s, usl u
                    where s.usl = u.usl
                      and l_mg between s.mgFrom and s.mgTo
                      and u.cd in ('эл.энерг.2',
                                   'эл.эн.2/св.нор',
                                   'эл.эн.учет УО',
                                   'эл.эн.учет УО 0 зар.')
                      and s.type = 1 --эл.энерг
                    group by s.k_lsk_id) e5
          on m.k_lsk_id = e5.k_lsk_id
        left join (select s.k_lsk_id, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, null as nrm
                     from tmp_a_charge2 s
                     join usl u
                       on s.usl = u.usl
                      and u.cd in
                          ('эл.эн.ОДН', 'эл.эн.МОП2', 'EL_SOD')
                      and s.type = 1
                      and l_mg between s.mgFrom and s.mgTo
                    group by s.k_lsk_id
                   ) e6
          on m.k_lsk_id = e6.k_lsk_id
        left join (select s.k_lsk_id, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, max(n.norm) as norm
                     from tmp_a_charge2 s, tmp_a_nabor2 n, usl u
                    where s.usl = u.usl
                      and s.lsk = n.lsk
                      and l_mg between s.mgFrom and s.mgTo
                      and l_mg between n.mgFrom and n.mgTo
                      and s.usl = n.usl
                      and u.cd in ('х.вода', 'х.вода/св.нор')
                      and s.type = 1
                    group by s.k_lsk_id) e7
          on m.k_lsk_id = e7.k_lsk_id
        left join (select s.k_lsk_id, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, null as nrm
                     from tmp_a_charge2 s
                     join usl u
                       on s.usl = u.usl
                      and u.cd in ('х.вода.ОДН', 'HW_SOD')
                      and s.type = 1
                      and l_mg between s.mgFrom and s.mgTo
                    group by s.k_lsk_id
                   ) e8
          on m.k_lsk_id = e8.k_lsk_id
        left join (select s.k_lsk_id,
                   sum(case when u.cd in ('г.вода','г.вода/св.нор','COMPHW','COMPHW2') then s.test_opl-- ред.24.06.21 Кис просит добавить услуги
                     else null end) as test_opl,
                   sum(s.summa) as summa_itg,
                   max(case when u.cd in ('г.вода','г.вода/св.нор','COMPHW','COMPHW2') then n.norm
                     else null end) as norm
                     from tmp_a_charge2 s, tmp_a_nabor2 n, usl u
                    where s.usl = u.usl
                      and s.lsk = n.lsk
                      and l_mg between s.mgFrom and s.mgTo
                      and l_mg between n.mgFrom and n.mgTo
                      and s.usl = n.usl
                      --and u.cd in ('г.вода', 'г.вода/св.нор') -- ред.24.06.21 Кис просит добавить услуги
                      and u.cd in ('г.вода','г.вода/св.нор','COMPHW','COMPHW2','COMPTN','COMPTN2')
                      and s.type = 1
                    group by s.k_lsk_id) e9
          on m.k_lsk_id = e9.k_lsk_id
        left join (select s.k_lsk_id, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, null as nrm
                     from tmp_a_charge2 s
                     join usl u
                       on s.usl = u.usl
                      and u.cd in ('г.вода.ОДН', 'GW_SOD')
                      and s.type = 1
                      and l_mg between s.mgFrom and s.mgTo
                    group by s.k_lsk_id
                   ) e10
          on m.k_lsk_id = e10.k_lsk_id
        left join (select s.k_lsk_id, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, max(n.norm) as norm
                     from tmp_a_charge2 s, tmp_a_nabor2 n, usl u
                    where l_mg between s.mgFrom and s.mgTo
                      and s.usl = u.usl
                      and s.lsk = n.lsk
                      and l_mg between n.mgFrom and n.mgTo
                      and s.usl = n.usl
                      and u.cd in
                          ('канализ', 'канализ/св.нор')
                      and s.type = 1
                    group by s.k_lsk_id) e11
          on m.k_lsk_id = e11.k_lsk_id
        left join (select s.k_lsk_id, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, max(n.norm) as norm
                     from tmp_a_charge2 s, tmp_a_nabor2 n, usl u
                    where l_mg between s.mgFrom and s.mgTo
                      and s.usl = u.usl
                      and s.lsk = n.lsk
                      and l_mg between n.mgFrom and n.mgTo
                      and s.usl = n.usl
                      and u.cd in ('отоп',
                                   'отоп/св.нор',
                                   'отоп.гкал.')
                      and s.type = 1 --возьмутся услуги у кого какие, проверять!
                    group by s.k_lsk_id) e12
          on m.k_lsk_id = e12.k_lsk_id
        left join (select s.k_lsk_id, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, max(n.norm) as norm
                     from tmp_a_charge2 s, tmp_a_nabor2 n, usl u
                    where l_mg between s.mgFrom and s.mgTo
                      and s.usl = u.usl
                      and s.lsk = n.lsk
                      and l_mg between n.mgFrom and n.mgTo
                      and s.usl = n.usl
                      and u.cd in ('KAN_SOD')
                      and s.type = 1
                    group by s.k_lsk_id) e13
          on m.k_lsk_id = e13.k_lsk_id
        left join (select n.k_lsk_id,round(sum(case
                                      when u.usl_norm = 0 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf1,round(sum(case
                                      when u.usl_norm = 1 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf2
                     from tmp_a_nabor2 n
                     join usl u
                       on n.usl = u.usl
                      and l_mg between n.mgFrom and n.mgTo
                     join a_prices r
                       on n.usl = r.usl
                      and r.mg = l_mg
                    where r.mg = l_mg
                      and u.cd in ('т/сод',
                                   'т/сод/св.нор',
                                   'лифт',
                                   'лифт/св.нор',
                                   'дерат.',
                                   'дерат/св.нор',
                                   'мус.площ.',
                                   'мус.площ./св.нор',
                                   'выв.мус.',
                                   'выв.мус./св.нор')
                    group by n.k_lsk_id) c1
          on m.k_lsk_id = c1.k_lsk_id
        left join (select n.k_lsk_id,round(sum(case
                                      when u.usl_norm = 0 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf1,round(sum(case
                                      when u.usl_norm = 1 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf2
                     from tmp_a_nabor2 n
                     join usl u
                       on n.usl = u.usl
                      and l_mg between n.mgFrom and n.mgTo
                     join a_prices r
                       on n.usl = r.usl
                      and r.mg = l_mg
                    where r.mg = l_mg
                      and u.cd in ('кап.', 'кап/св.нор')
                    group by n.k_lsk_id) c2
          on m.k_lsk_id = c2.k_lsk_id
        left join (select n.k_lsk_id,round(sum(case
                                      when u.usl_norm = 0 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf1,round(sum(case
                                      when u.usl_norm = 1 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf2
                     from tmp_a_nabor2 n
                     join usl u
                       on n.usl = u.usl
                      and l_mg between n.mgFrom and n.mgTo
                     join a_prices r
                       on n.usl = r.usl
                      and r.mg = l_mg
                    where r.mg = l_mg
                      and u.cd in ('найм')
                    group by n.k_lsk_id) c4
          on m.k_lsk_id = c4.k_lsk_id
        left join (select n.k_lsk_id,round(sum(case
                                      when u.usl_norm = 0 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf1,round(sum(case
                                      when u.usl_norm = 1 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf2
                     from tmp_a_nabor2 n
                     join usl u
                       on n.usl = u.usl
                      and l_mg between n.mgFrom and n.mgTo
                     join a_prices r
                       on n.usl = r.usl
                      and r.mg = l_mg
                    where r.mg = l_mg
                      and u.cd in ('эл.энерг.2',
                                   'эл.эн.2/св.нор',
                                   'эл.эн.учет УО',
                                   'эл.эн.учет УО 0 зар.')
                    group by n.k_lsk_id) c5
          on m.k_lsk_id = c5.k_lsk_id
        left join (select n.k_lsk_id,round(sum(case
                                      when u.usl_norm = 0 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf1,round(sum(case
                                      when u.usl_norm = 1 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf2
                     from tmp_a_nabor2 n
                     join usl u
                       on n.usl = u.usl
                      and l_mg between n.mgFrom and n.mgTo
                     join a_prices r
                       on n.usl = r.usl
                      and r.mg = l_mg
                    where r.mg = l_mg
                      and u.cd in ('эл.эн.ОДН')
                    group by n.k_lsk_id) c6
          on m.k_lsk_id = c6.k_lsk_id
        left join (select n.k_lsk_id,round(sum(case
                                      when u.usl_norm = 0 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf1,round(sum(case
                                      when u.usl_norm = 1 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf2
                     from tmp_a_nabor2 n
                     join usl u
                       on n.usl = u.usl
                      and l_mg between n.mgFrom and n.mgTo
                     join a_prices r
                       on n.usl = r.usl
                      and r.mg = l_mg
                    where r.mg = l_mg
                      and u.cd in ('х.вода', 'х.вода/св.нор')
                    group by n.k_lsk_id) c7
          on m.k_lsk_id = c7.k_lsk_id
        left join (select n.k_lsk_id,round(sum(case
                                      when u.usl_norm = 0 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf1,round(sum(case
                                      when u.usl_norm = 1 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf2
                     from tmp_a_nabor2 n
                     join usl u
                       on n.usl = u.usl
                      and l_mg between n.mgFrom and n.mgTo
                     join a_prices r
                       on n.usl = r.usl
                      and r.mg = l_mg
                    where r.mg = l_mg
                      and u.cd in ('х.вода.ОДН')
                    group by n.k_lsk_id) c8
          on m.k_lsk_id = c8.k_lsk_id
        left join (select n.k_lsk_id,round(sum(case
                                      when u.usl_norm = 0 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf1,round(sum(case
                                      when u.usl_norm = 1 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf2
                     from tmp_a_nabor2 n
                     join usl u
                       on n.usl = u.usl
                      and l_mg between n.mgFrom and n.mgTo
                     join a_prices r
                       on n.usl = r.usl
                      and r.mg = l_mg
                    where r.mg = l_mg
                      and u.cd in ('г.вода', 'г.вода/св.нор')
                    group by n.k_lsk_id) c9
          on m.k_lsk_id = c9.k_lsk_id
        left join (select n.k_lsk_id,round(sum(case
                                      when u.usl_norm = 0 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf1,round(sum(case
                                      when u.usl_norm = 1 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf2
                     from tmp_a_nabor2 n
                     join usl u
                       on n.usl = u.usl
                      and l_mg between n.mgFrom and n.mgTo
                     join a_prices r
                       on n.usl = r.usl
                      and r.mg = l_mg
                    where r.mg = l_mg
                      and u.cd in ('г.вода.ОДН')
                    group by n.k_lsk_id) c10
          on m.k_lsk_id = c10.k_lsk_id
        left join (select n.k_lsk_id,round(sum(case
                                      when u.usl_norm = 0 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf1,round(sum(case
                                      when u.usl_norm = 1 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf2
                     from tmp_a_nabor2 n
                     join usl u
                       on n.usl = u.usl
                      and l_mg between n.mgFrom and n.mgTo
                     join a_prices r
                       on n.usl = r.usl
                      and r.mg = l_mg
                    where r.mg = l_mg
                      and u.cd in
                          ('канализ', 'канализ/св.нор')
                    group by n.k_lsk_id) c11
          on m.k_lsk_id = c11.k_lsk_id
        left join (select n.k_lsk_id,round(sum(case
                                      when u.usl_norm = 0 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf1,round(sum(case
                                      when u.usl_norm = 1 then
                                       case
                                         when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                          n.koeff
                                         else
                                          1
                                       end * r.summa
                                      else
                                       0
                                    end),
                                2) as tf2
                     from tmp_a_nabor2 n
                     join usl u
                       on n.usl = u.usl
                      and l_mg between n.mgFrom and n.mgTo
                     join a_prices r
                       on n.usl = r.usl
                      and r.mg = l_mg
                    where r.mg = l_mg
                      and u.cd in ('отоп', 'отоп/св.нор')
                    group by n.k_lsk_id) c12
          on m.k_lsk_id = c12.k_lsk_id
       order by m.NYLIC, m.NDOM, m.NKORP, m.NKW, m.NKOMN;
  elsif p_tp = 1 then
    -- выгрузка льготников для ТКО
    insert into load_privs
        (fk_src, org1, datn, posel, nasp, nylic, ndom, nkorp, nkw, nkomn, famil, imja, otch,
         drog, id_pku, pku, gku1, lchet1, ed_izm1, fakt1, sum_f1, prz1, tp, fk_file)
        select
         m.id, m.org1, m.datn, m.posel, m.nasp, m.nylic, m.ndom, m.nkorp, m.nkw, m.nkomn, m.famil, m.imja, m.otch, m.drog, m.id_pku, m.pku,
         m.gku1, m.lchet1, m.ed_izm1, e5.test_opl as fakt1, e5.summa_itg as sum_f1, case
           when nvl(e5.test_opl, 0) <> 0 then
            1
           else
            null
         end as prz1, 1 as tp, p_file as fk_file
          from (select t.id, max(k.opl) as opl, max(k.kul) as kul, k.k_lsk_id, t."ORG1", t."DATN", t."POSEL", t."NASP",
               t."NYLIC", t."NDOM", t."NKORP", t."NKW", t."NKOMN", t."FAMIL", t."IMJA", t."OTCH", t."DROG", t."ID_PKU", t."PKU",
               t."GKU1", t."LCHET1", t."ED_IZM1", t."FAKT1", t."SUM_F1", t."PRZ1", t."FK_LSK", t."FK_FILE", t."TP"
                   from load_privs t
                   left join prep_house t2
                     on t.nylic = t2.ext_nylic
                    and nvl(t.ndom, 'XXX') = nvl(t2.ext_ndom, 'XXX')
                    and nvl(t.nkorp, 'XXX') = nvl(t2.ext_nkorp, 'XXX')
                   left join prep_street t3
                     on t3.ext_nylic = t2.ext_nylic
                   left join arch_kart k
                     on k.nd = t2.nd and k.mg=l_mg
                    and k.kul = t3.kul
                    and upper(k.kw) = lpad(upper(t.nkw), 7, '0')
                    and k.psch not in (8, 9)
                    and k.sel1 = 1
                    and k.fk_tp in (select id from v_lsk_tp where cd in ('LSK_TP_MAIN', 'LSK_TP_RSO'))
                  where nvl(t.tp, 0) = 0 and t.fk_file = p_file
                  group by t.id, k.k_lsk_id, t."ORG1", t."DATN", t."POSEL", t."NASP", t."NYLIC", t."NDOM", t."NKORP", t."NKW",
                  t."NKOMN", t."FAMIL", t."IMJA", t."OTCH", t."DROG", t."ID_PKU", t."PKU", t."GKU1", t."LCHET1", t."ED_IZM1",
                  t."FAKT1", t."SUM_F1", t."FK_LSK", t."FK_FILE", t."TP", t."PRZ1"
                  ) m
          left join (select s.k_lsk_id, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg
                       from tmp_a_charge2 s, usl u
                      where s.usl = u.usl
                        and l_mg between s.mgFrom and s.mgTo
                        and u.cd in ('TKO')
                        and s.type = 1 -- ТКО
                      group by s.k_lsk_id) e5
            on m.k_lsk_id = e5.k_lsk_id
          left join t_org_tp tp
            on tp.cd = 'Город'
          left join t_org c2
            on c2.fk_orgtp = tp.id
          left join spul l
            on m.kul = l.id
         order by m.NYLIC, m.NDOM, m.NKORP, m.NKW, m.NKOMN;
  end if;

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
  (id, lsk, usl, summa, kart_pr_id, spk_id, type, test_opl, test_cena, test_tarkoef, test_spk_koef, main, lg_doc_id, npp, sch, kpr, kprz, kpro, kpr2, opl, mgfrom, mgto)
  select t.id, t.lsk, t.usl, t.summa, t.kart_pr_id, t.spk_id, t.type, t.test_opl, t.test_cena, t.test_tarkoef, t.test_spk_koef, t.main, t.lg_doc_id, t.npp, t.sch, t.kpr, t.kprz, t.kpro, t.kpr2, t.opl, t.mgfrom, t.mgto
    from a_charge2 t, (select t.id, k.lsk, k.fk_tp, t."ORG1", t."DATN", t."POSEL", t."NASP", t."NYLIC", t."NDOM", t."NKORP", t."NKW", t."NKOMN", t."LCHET", t."FAMIL", t."IMJA", t."OTCH", t."DROG", t."ID_PKU", t."PKU", t."GKU1", t."LCHET1", t."ED_IZM1", t."FAKT1", t."SUM_F1", t."PRZ1", t."GKU2", t."LCHET2", t."ED_IZM2", t."FAKT2", t."SUM_F2", t."NORM2", t."FAKT21", t."SUM_F21", t."O_PL2", t."PRZ2", t."GKU3", t."LCHET3", t."ED_IZM3", t."FAKT3", t."SUM_F3", t."NORM3", t."PR3_1", t."PR3_2", t."PR3_3", t."O_PL3", t."PRZ3", t."GKU4", t."LCHET4", t."ED_IZM4", t."FAKT4", t."SUM_F4", t."NORM4", t."PRZ4", t."GKU5", t."LCHET5", t."ED_IZM5", t."FAKT5", t."SUM_F5", t."NORM5", t."FAKT51", t."SUM_F51", t."O_PL5", t."PRZ5", t."GKU6", t."LCHET6", t."ED_IZM6", t."FAKT6", t."SUM_F6", t."NORM6", t."PRZ6", t."GKU7", t."LCHET7", t."ED_IZM7", t."FAKT7", t."SUM_F7", t."NORM7", t."FAKT71", t."SUM_F71", t."O_PL7", t."PRZ7", t."GKU8", t."LCHET8", t."ED_IZM8", t."FAKT8", t."SUM_F8", t."NORM8", t."PRZ8", t."GKU9", t."LCHET9", t."ED_IZM9", t."FAKT9", t."SUM_F9", t."NORM9", t."FAKT91", t."TF_N", t."TF_SV", t."O_PL9", t."PRZ9", t."GKU10", t."LCHET10", t."ED_IZM10", t."FAKT10", t."SUM_F10", t."PRZ10", t."FK_LSK", t."FK_FILE", t."TP"
             from load_privs t
             left join prep_house t2
               on t.nylic = t2.ext_nylic
              and nvl(t.ndom, 'XXX') = nvl(t2.ext_ndom, 'XXX')
              and nvl(t.nkorp, 'XXX') = nvl(t2.ext_nkorp, 'XXX')
             left join prep_street t3
               on t3.ext_nylic = t2.ext_nylic
             left join v_lsk_tp tp2
               on tp2.cd in ('LSK_TP_MAIN', 'LSK_TP_RSO')
             left join arch_kart k
               on k.nd = t2.nd and k.mg=l_mg
              and k.kul = t3.kul
              and upper(k.kw) = lpad(upper(t.nkw), 7, '0')
              and k.psch not in (8, 9)
              and k.fk_tp = tp2.id
              and k.sel1 = 1
            where nvl(t.tp, 0) = 0) m
   where l_mg between t.mgfrom and t.mgto
     and t.lsk = m.lsk
     and m.fk_file = p_file;

insert into tmp_a_nabor2
  (lsk, usl, org, koeff, norm, fk_tarif, fk_vvod, vol, fk_dvb, vol_add, kf_kpr, sch_auto, nrm_kpr, kf_kpr_sch, kf_kpr_wrz, kf_kpr_wro, kf_kpr_wrz_sch, kf_kpr_wro_sch, limit, nrm_kpr2, id, mgfrom, mgto)
  select t.lsk, t.usl, t.org, t.koeff, t.norm, t.fk_tarif, t.fk_vvod, t.vol, t.fk_dvb, t.vol_add, t.kf_kpr, t.sch_auto, t.nrm_kpr, t.kf_kpr_sch, t.kf_kpr_wrz, t.kf_kpr_wro, t.kf_kpr_wrz_sch, t.kf_kpr_wro_sch, t.limit, t.nrm_kpr2, t.id, t.mgfrom, t.mgto
    from a_nabor2 t, (select t.id, k.lsk, k.fk_tp, t."ORG1", t."DATN", t."POSEL", t."NASP", t."NYLIC", t."NDOM", t."NKORP", t."NKW", t."NKOMN", t."LCHET", t."FAMIL", t."IMJA", t."OTCH", t."DROG", t."ID_PKU", t."PKU", t."GKU1", t."LCHET1", t."ED_IZM1", t."FAKT1", t."SUM_F1", t."PRZ1", t."GKU2", t."LCHET2", t."ED_IZM2", t."FAKT2", t."SUM_F2", t."NORM2", t."FAKT21", t."SUM_F21", t."O_PL2", t."PRZ2", t."GKU3", t."LCHET3", t."ED_IZM3", t."FAKT3", t."SUM_F3", t."NORM3", t."PR3_1", t."PR3_2", t."PR3_3", t."O_PL3", t."PRZ3", t."GKU4", t."LCHET4", t."ED_IZM4", t."FAKT4", t."SUM_F4", t."NORM4", t."PRZ4", t."GKU5", t."LCHET5", t."ED_IZM5", t."FAKT5", t."SUM_F5", t."NORM5", t."FAKT51", t."SUM_F51", t."O_PL5", t."PRZ5", t."GKU6", t."LCHET6", t."ED_IZM6", t."FAKT6", t."SUM_F6", t."NORM6", t."PRZ6", t."GKU7", t."LCHET7", t."ED_IZM7", t."FAKT7", t."SUM_F7", t."NORM7", t."FAKT71", t."SUM_F71", t."O_PL7", t."PRZ7", t."GKU8", t."LCHET8", t."ED_IZM8", t."FAKT8", t."SUM_F8", t."NORM8", t."PRZ8", t."GKU9", t."LCHET9", t."ED_IZM9", t."FAKT9", t."SUM_F9", t."NORM9", t."FAKT91", t."TF_N", t."TF_SV", t."O_PL9", t."PRZ9", t."GKU10", t."LCHET10", t."ED_IZM10", t."FAKT10", t."SUM_F10", t."PRZ10", t."FK_LSK", t."FK_FILE", t."TP"
             from load_privs t
             left join prep_house t2
               on t.nylic = t2.ext_nylic
              and nvl(t.ndom, 'XXX') = nvl(t2.ext_ndom, 'XXX')
              and nvl(t.nkorp, 'XXX') = nvl(t2.ext_nkorp, 'XXX')
             left join prep_street t3
               on t3.ext_nylic = t2.ext_nylic
             left join v_lsk_tp tp2
               on tp2.cd in ('LSK_TP_MAIN', 'LSK_TP_RSO')
             left join arch_kart k
               on k.nd = t2.nd and k.mg=l_mg
              and k.kul = t3.kul
              and upper(k.kw) = lpad(upper(t.nkw), 7, '0')
              and k.psch not in (8, 9)
              and k.fk_tp = tp2.id
              and k.sel1 = 1
            where nvl(t.tp, 0) = 0) m
   where l_mg between t.mgfrom and t.mgto
     and t.lsk = m.lsk
     and m.fk_file = p_file;

  --подсчитать кол-во записей - источников
  select nvl(count(*),0) into l_cnt from load_privs t where nvl(t.tp,0)=0 and t.fk_file=p_file;

insert into load_privs
  (fk_src, org1, datn, posel, nasp, nylic, ndom, nkorp, nkw, nkomn, lchet, famil, imja, otch, drog, id_pku, pku, gku1, lchet1, ed_izm1, fakt1, sum_f1, prz1, gku2, lchet2, ed_izm2, fakt2, sum_f2, norm2, fakt21, sum_f21, o_pl2, prz2, gku3, lchet3, ed_izm3, fakt3, sum_f3, norm3, pr3_1, pr3_2, pr3_3, o_pl3, prz3, gku4, lchet4, ed_izm4, fakt4, sum_f4, norm4, prz4, gku5, lchet5, ed_izm5, fakt5, sum_f5, norm5, fakt51, sum_f51, o_pl5, prz5, gku6, lchet6, ed_izm6, fakt6, sum_f6, norm6, prz6, gku7, lchet7, ed_izm7, fakt7, sum_f7, norm7, fakt71, sum_f71, o_pl7, prz7, gku8, lchet8, ed_izm8, fakt8, sum_f8, norm8, prz8, gku9, lchet9, ed_izm9, fakt9, sum_f9, norm9, fakt91, tf_n, tf_sv, o_pl9, prz9, gku10, lchet10, ed_izm10, fakt10, sum_f10, prz10, tp, fk_file)
  select /*+ USE_HASH( m, s, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, c1, c2, c4, c5, c6, c7, c8, c9, c10, c11, c12) */
   m.id, m.org1, m.datn, m.posel, m.nasp, m.nylic, m.ndom, m.nkorp, m.nkw, m.nkomn, s.lsk as lchet, m.famil, m.imja, m.otch, m.drog, m.id_pku, m.pku,
   /*'Электроэнергия' as gku1,
   s.lsk as lchet1,
   'квт.' as edizm1,*/ m.gku1, m.lchet1, m.ed_izm1, e5.test_opl as fakt1, e5.summa_itg as sum_f1,case
     when nvl(e5.test_opl, 0) <> 0 then
      1
     else
      null
   end as prz1,

   /*'Электроэнергия на ОДН' as gku2,
   s.lsk as lchet2,
   'квт.' as ed_izm2,*/ m.gku2, m.lchet2, m.ed_izm2, nvl(e6.test_opl, 0) as fakt2, e6.summa_itg as sum_f2, e6.nrm as norm2,case
     when nvl(s.opl, 0) <> 0 then
      e6.test_opl / s.opl
     else
      0
   end as fakt21,case
     when nvl(s.opl, 0) <> 0 then
      e6.summa_itg / s.opl
     else
      null
   end as sum_f21, s.opl as o_pl2,case
     when nvl(e6.test_opl, 0) <> 0 then
      1
     else
      null
   end as prz2,

   m.gku3, m.lchet3, m.ed_izm3, 0 as fakt3, null as sum_f3, null as norm3, null as pr3_1, null as pr3_2, null as pr3_3, null as o_pl3, null as prz3,

   /*       'ХВС' as gku4,
   s.lsk as lchet4,
   'м3' as edizm4,*/ m.gku4, m.lchet4, m.ed_izm4,

   nvl(e7.test_opl, 0) as fakt4, e7.summa_itg as sum_f4, e7.norm as norm4,case
     when nvl(e7.test_opl, 0) <> 0 then
      1
     else
      null
   end as prz4,

   /*       'Холодная вода, ОДН' as gku5,
   s.lsk as lchet5,
   'м3' as ed_izm5,*/ m.gku5, m.lchet5, m.ed_izm5,

   nvl(e8.test_opl, 0) as fakt5, e8.summa_itg as sum_f5, e8.nrm as norm5,case
     when nvl(s.opl, 0) <> 0 then
      e8.test_opl / s.opl
     else
      0
   end as fakt51,case
     when nvl(s.opl, 0) <> 0 then
      e8.summa_itg / s.opl
     else
      null
   end as sum_f51, s.opl as o_pl5,case
     when nvl(e8.test_opl, 0) <> 0 then
      1
     else
      null
   end as prz5,

   /*       'Горячая вода' as gku6,
   s.lsk as lchet6,
   'м3' as edizm6,*/ m.gku6, m.lchet6, m.ed_izm6,

   nvl(e9.test_opl, 0) as fakt6, e9.summa_itg as sum_f6, e9.norm as norm6,case
     when nvl(e9.test_opl, 0) <> 0 then
      1
     else
      null
   end as prz6,

   /*       'Горячая вода, ОДН' as gku7,
   s.lsk as lchet7,
   'м3' as edizm7,*/ m.gku7, m.lchet7, m.ed_izm7,

   nvl(e10.test_opl, 0) as fakt7, e10.summa_itg as sum_f7, e10.nrm as norm7,case
     when nvl(s.opl, 0) <> 0 then
      e10.test_opl / s.opl
     else
      0
   end as fakt71,case
     when nvl(s.opl, 0) <> 0 then
      e10.summa_itg / s.opl
     else
      null
   end as sum_f71, s.opl as o_pl7,case
     when nvl(e10.test_opl, 0) <> 0 then
      1
     else
      null
   end as prz7,

   /*       'Канализация' as gku8,
   s.lsk as lchet8,
   'м3' as edizm8,*/ m.gku8, m.lchet8, m.ed_izm8,

   nvl(e11.test_opl, 0) as fakt8, e11.summa_itg as sum_f8, e11.norm as norm8,case
     when nvl(e11.test_opl, 0) <> 0 then
      1
     else
      null
   end as prz8,

   /*       'Отопление' as gku9,
   s.lsk as lchet9,
   'м2' as edizm9,*/ m.gku9, m.lchet9, m.ed_izm9,

   nvl(e12.test_opl, 0) as fakt9, e12.summa_itg as sum_f9, e12.norm as norm9,case
     when nvl(s.opl, 0) <> 0 then
      e12.test_opl / s.opl
     else
      0
   end as fakt91, c12.tf1 as tf_n, c12.tf2 as tf_sv, s.opl as o_pl9,case
     when nvl(e12.test_opl, 0) <> 0 then
      1
     else
      null
   end as prz9,

   /*       'Газ в баллонах' as gku10,
   null as lchet10,
   null as edizm10,*/ m.gku10, m.lchet10, m.ed_izm10,

   0 as fakt10, null as sum_f10, null as prz10, 1 as tp, p_file as fk_file
    from (select t.id, k.lsk, k.fk_tp, t."ORG1", t."DATN", t."POSEL", t."NASP", t."NYLIC", t."NDOM", t."NKORP", t."NKW", t."NKOMN", t."LCHET", t."FAMIL", t."IMJA", t."OTCH", t."DROG", t."ID_PKU", t."PKU", t."GKU1", t."LCHET1", t."ED_IZM1", t."FAKT1", t."SUM_F1", t."PRZ1", t."GKU2", t."LCHET2", t."ED_IZM2", t."FAKT2", t."SUM_F2", t."NORM2", t."FAKT21", t."SUM_F21", t."O_PL2", t."PRZ2", t."GKU3", t."LCHET3", t."ED_IZM3", t."FAKT3", t."SUM_F3", t."NORM3", t."PR3_1", t."PR3_2", t."PR3_3", t."O_PL3", t."PRZ3", t."GKU4", t."LCHET4", t."ED_IZM4", t."FAKT4", t."SUM_F4", t."NORM4", t."PRZ4", t."GKU5", t."LCHET5", t."ED_IZM5", t."FAKT5", t."SUM_F5", t."NORM5", t."FAKT51", t."SUM_F51", t."O_PL5", t."PRZ5", t."GKU6", t."LCHET6", t."ED_IZM6", t."FAKT6", t."SUM_F6", t."NORM6", t."PRZ6", t."GKU7", t."LCHET7", t."ED_IZM7", t."FAKT7", t."SUM_F7", t."NORM7", t."FAKT71", t."SUM_F71", t."O_PL7", t."PRZ7", t."GKU8", t."LCHET8", t."ED_IZM8", t."FAKT8", t."SUM_F8", t."NORM8", t."PRZ8", t."GKU9", t."LCHET9", t."ED_IZM9", t."FAKT9", t."SUM_F9", t."NORM9", t."FAKT91", t."TF_N", t."TF_SV", t."O_PL9", t."PRZ9", t."GKU10", t."LCHET10", t."ED_IZM10", t."FAKT10", t."SUM_F10", t."PRZ10", t."FK_LSK", t."FK_FILE", t."TP"
             from load_privs t
             left join prep_house t2
               on t.nylic = t2.ext_nylic
              and nvl(t.ndom, 'XXX') = nvl(t2.ext_ndom, 'XXX')
              and nvl(t.nkorp, 'XXX') = nvl(t2.ext_nkorp, 'XXX')
             left join prep_street t3
               on t3.ext_nylic = t2.ext_nylic
             left join v_lsk_tp tp2
               on tp2.cd in ('LSK_TP_MAIN', 'LSK_TP_RSO')
             left join arch_kart k
               on k.nd = t2.nd and k.mg=l_mg
              and k.kul = t3.kul
              and upper(k.kw) = lpad(upper(t.nkw), 7, '0')
              and k.psch not in (8, 9)
              and k.fk_tp = tp2.id
              and k.sel1 = 1
            where nvl(t.tp, 0) = 0)

          m
    left join (select s.*
                 from arch_kart s, s_reu_trest e
                where s.mg = l_mg
                     /*and e.reu='01'
                     and s.lsk='00000001'*/
                  and s.reu = e.reu
                  and s.psch not in (8, 9) --только открытые
                  and s.status not in (7) --убрал нежилые
               ) s
      on s.lsk = m.lsk
    left join t_org c
      on s.reu = c.reu
    left join t_org_tp tp
      on tp.cd = 'Город'
    left join t_org c2
      on c2.fk_orgtp = tp.id
    left join spul l
      on s.kul = l.id
    left join (select s.lsk, sum(s.summa) as summa_itg
                 from tmp_a_charge2 s, usl u
                where l_mg between s.mgFrom and s.mgTo
                  and s.usl = u.usl
                  and u.cd in ('т/сод',
                               'т/сод/св.нор',
                               'лифт',
                               'лифт/св.нор',
                               'дерат.',
                               'дерат/св.нор',
                               'мус.площ.',
                               'мус.площ./св.нор',
                               'выв.мус.',
                               'выв.мус./св.нор')
                  and s.type = 1 --текущее содержание, вместе с под-услугами
                group by s.lsk) e2
      on s.lsk = e2.lsk
    left join (select s.lsk, sum(s.summa) as summa_itg
                 from tmp_a_charge2 s, usl u
                where l_mg between s.mgFrom and s.mgTo
                  and s.usl = u.usl
                  and u.cd in ('кап.', 'кап/св.нор')
                  and s.type = 1 --капремонт
                group by s.lsk) e3
      on s.lsk = e3.lsk
    left join (select s.lsk, sum(s.summa) as summa_itg
                 from tmp_a_charge2 s, usl u
                where l_mg between s.mgFrom and s.mgTo
                  and s.usl = u.usl
                  and u.cd in ('найм')
                  and s.type = 1 --найм
                group by s.lsk) e4
      on s.lsk = e4.lsk
    left join (select s.lsk, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg
                 from tmp_a_charge2 s, usl u
                where s.usl = u.usl
                  and l_mg between s.mgFrom and s.mgTo
                  and u.cd in ('эл.энерг.2',
                               'эл.эн.2/св.нор',
                               'эл.эн.учет УО',
                               'эл.эн.учет УО 0 зар.')
                  and s.type = 1 --эл.энерг
                group by s.lsk) e5
      on s.lsk = e5.lsk
    left join (select s.lsk, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, null as nrm
                 from tmp_a_charge2 s
                 join usl u
                   on s.usl = u.usl
                  and u.cd in
                      ('эл.эн.ОДН', 'эл.эн.МОП2', 'EL_SOD')
                  and s.type = 1
                  and l_mg between s.mgFrom and s.mgTo
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
               group by s.lsk*/
               ) e6
      on s.lsk = e6.lsk
    left join (select s.lsk, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, max(n.norm) as norm
                 from tmp_a_charge2 s, tmp_a_nabor2 n, usl u
                where s.usl = u.usl
                  and s.lsk = n.lsk
                  and l_mg between s.mgFrom and s.mgTo
                  and l_mg between n.mgFrom and n.mgTo
                  and s.usl = n.usl
                  and u.cd in ('х.вода', 'х.вода/св.нор')
                  and s.type = 1
                group by s.lsk) e7
      on s.lsk = e7.lsk
    left join (select s.lsk, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, null as nrm
                 from tmp_a_charge2 s
                 join usl u
                   on s.usl = u.usl
                  and u.cd in ('х.вода.ОДН', 'HW_SOD')
                  and s.type = 1
                  and l_mg between s.mgFrom and s.mgTo
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
               ) e8
      on s.lsk = e8.lsk
    left join (select s.lsk, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, max(n.norm) as norm
                 from tmp_a_charge2 s, tmp_a_nabor2 n, usl u
                where s.usl = u.usl
                  and s.lsk = n.lsk
                  and l_mg between s.mgFrom and s.mgTo
                  and l_mg between n.mgFrom and n.mgTo
                  and s.usl = n.usl
                  and u.cd in ('г.вода', 'г.вода/св.нор')
                  and s.type = 1
                group by s.lsk) e9
      on s.lsk = e9.lsk
    left join (select s.lsk, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, null as nrm
                 from tmp_a_charge2 s
                 join usl u
                   on s.usl = u.usl
                  and u.cd in ('г.вода.ОДН', 'GW_SOD')
                  and s.type = 1
                  and l_mg between s.mgFrom and s.mgTo
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
               group by s.lsk*/
               ) e10
      on s.lsk = e10.lsk
    left join (select s.lsk, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, max(n.norm) as norm
                 from tmp_a_charge2 s, tmp_a_nabor2 n, usl u
                where l_mg between s.mgFrom and s.mgTo
                  and s.usl = u.usl
                  and s.lsk = n.lsk
                  and l_mg between n.mgFrom and n.mgTo
                  and s.usl = n.usl
                  and u.cd in
                      ('канализ', 'канализ/св.нор')
                  and s.type = 1
                group by s.lsk) e11
      on s.lsk = e11.lsk
    left join (select s.lsk, sum(s.test_opl) as test_opl, sum(s.summa) as summa_itg, max(n.norm) as norm
                 from tmp_a_charge2 s, tmp_a_nabor2 n, usl u
                where l_mg between s.mgFrom and s.mgTo
                  and s.usl = u.usl
                  and s.lsk = n.lsk
                  and l_mg between n.mgFrom and n.mgTo
                  and s.usl = n.usl
                  and u.cd in ('отоп',
                               'отоп/св.нор',
                               'отоп.гкал.')
                  and s.type = 1 --возьмутся услуги у кого какие, проверять!
                group by s.lsk) e12
      on s.lsk = e12.lsk

    left join (select n.lsk,round(sum(case
                                  when u.usl_norm = 0 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf1,round(sum(case
                                  when u.usl_norm = 1 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf2
                 from tmp_a_nabor2 n
                 join usl u
                   on n.usl = u.usl
                  and l_mg between n.mgFrom and n.mgTo
                 join a_prices r
                   on n.usl = r.usl
                  and r.mg = l_mg
                where r.mg = l_mg
                  and u.cd in ('т/сод',
                               'т/сод/св.нор',
                               'лифт',
                               'лифт/св.нор',
                               'дерат.',
                               'дерат/св.нор',
                               'мус.площ.',
                               'мус.площ./св.нор',
                               'выв.мус.',
                               'выв.мус./св.нор')
                group by n.lsk) c1
      on s.lsk = c1.lsk
    left join (select n.lsk,round(sum(case
                                  when u.usl_norm = 0 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf1,round(sum(case
                                  when u.usl_norm = 1 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf2
                 from tmp_a_nabor2 n
                 join usl u
                   on n.usl = u.usl
                  and l_mg between n.mgFrom and n.mgTo
                 join a_prices r
                   on n.usl = r.usl
                  and r.mg = l_mg
                where r.mg = l_mg
                  and u.cd in ('кап.', 'кап/св.нор')
                group by n.lsk) c2
      on s.lsk = c2.lsk

    left join (select n.lsk,round(sum(case
                                  when u.usl_norm = 0 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf1,round(sum(case
                                  when u.usl_norm = 1 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf2
                 from tmp_a_nabor2 n
                 join usl u
                   on n.usl = u.usl
                  and l_mg between n.mgFrom and n.mgTo
                 join a_prices r
                   on n.usl = r.usl
                  and r.mg = l_mg
                where r.mg = l_mg
                  and u.cd in ('найм')
                group by n.lsk) c4
      on s.lsk = c4.lsk
    left join (select n.lsk,round(sum(case
                                  when u.usl_norm = 0 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf1,round(sum(case
                                  when u.usl_norm = 1 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf2
                 from tmp_a_nabor2 n
                 join usl u
                   on n.usl = u.usl
                  and l_mg between n.mgFrom and n.mgTo
                 join a_prices r
                   on n.usl = r.usl
                  and r.mg = l_mg
                where r.mg = l_mg
                  and u.cd in ('эл.энерг.2',
                               'эл.эн.2/св.нор',
                               'эл.эн.учет УО',
                               'эл.эн.учет УО 0 зар.')
                group by n.lsk) c5
      on s.lsk = c5.lsk

    left join (select n.lsk,round(sum(case
                                  when u.usl_norm = 0 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf1,round(sum(case
                                  when u.usl_norm = 1 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf2
                 from tmp_a_nabor2 n
                 join usl u
                   on n.usl = u.usl
                  and l_mg between n.mgFrom and n.mgTo
                 join a_prices r
                   on n.usl = r.usl
                  and r.mg = l_mg
                where r.mg = l_mg
                  and u.cd in ('эл.эн.ОДН')
                group by n.lsk) c6
      on s.lsk = c6.lsk

    left join (select n.lsk,round(sum(case
                                  when u.usl_norm = 0 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf1,round(sum(case
                                  when u.usl_norm = 1 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf2
                 from tmp_a_nabor2 n
                 join usl u
                   on n.usl = u.usl
                  and l_mg between n.mgFrom and n.mgTo
                 join a_prices r
                   on n.usl = r.usl
                  and r.mg = l_mg
                where r.mg = l_mg
                  and u.cd in ('х.вода', 'х.вода/св.нор')
                group by n.lsk) c7
      on s.lsk = c7.lsk

    left join (select n.lsk,round(sum(case
                                  when u.usl_norm = 0 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf1,round(sum(case
                                  when u.usl_norm = 1 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf2
                 from tmp_a_nabor2 n
                 join usl u
                   on n.usl = u.usl
                  and l_mg between n.mgFrom and n.mgTo
                 join a_prices r
                   on n.usl = r.usl
                  and r.mg = l_mg
                where r.mg = l_mg
                  and u.cd in ('х.вода.ОДН')
                group by n.lsk) c8
      on s.lsk = c8.lsk

    left join (select n.lsk,round(sum(case
                                  when u.usl_norm = 0 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf1,round(sum(case
                                  when u.usl_norm = 1 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf2
                 from tmp_a_nabor2 n
                 join usl u
                   on n.usl = u.usl
                  and l_mg between n.mgFrom and n.mgTo
                 join a_prices r
                   on n.usl = r.usl
                  and r.mg = l_mg
                where r.mg = l_mg
                  and u.cd in ('г.вода', 'г.вода/св.нор')
                group by n.lsk) c9
      on s.lsk = c9.lsk

    left join (select n.lsk,round(sum(case
                                  when u.usl_norm = 0 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf1,round(sum(case
                                  when u.usl_norm = 1 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf2
                 from tmp_a_nabor2 n
                 join usl u
                   on n.usl = u.usl
                  and l_mg between n.mgFrom and n.mgTo
                 join a_prices r
                   on n.usl = r.usl
                  and r.mg = l_mg
                where r.mg = l_mg
                  and u.cd in ('г.вода.ОДН')
                group by n.lsk) c10
      on s.lsk = c10.lsk

    left join (select n.lsk,round(sum(case
                                  when u.usl_norm = 0 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf1,round(sum(case
                                  when u.usl_norm = 1 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf2
                 from tmp_a_nabor2 n
                 join usl u
                   on n.usl = u.usl
                  and l_mg between n.mgFrom and n.mgTo
                 join a_prices r
                   on n.usl = r.usl
                  and r.mg = l_mg
                where r.mg = l_mg
                  and u.cd in
                      ('канализ', 'канализ/св.нор')
                group by n.lsk) c11
      on s.lsk = c11.lsk

    left join (select n.lsk,round(sum(case
                                  when u.usl_norm = 0 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf1,round(sum(case
                                  when u.usl_norm = 1 then
                                   case
                                     when n.koeff is not null and u.sptarn in (0, 2, 3) then
                                      n.koeff
                                     else
                                      1
                                   end * r.summa
                                  else
                                   0
                                end),
                            2) as tf2
                 from tmp_a_nabor2 n
                 join usl u
                   on n.usl = u.usl
                  and l_mg between n.mgFrom and n.mgTo
                 join a_prices r
                   on n.usl = r.usl
                  and r.mg = l_mg
                where r.mg = l_mg
                  and u.cd in ('отоп', 'отоп/св.нор')
                group by n.lsk) c12
      on s.lsk = c12.lsk
   where m.fk_file = p_file

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


-- рефкурсор для выгрузки
procedure rep(p_file in number, prep_refcursor in out rep_refcursor, -- Id файла
              p_tp in number             -- тип (0-основная выгрузка, 1-ТКО)
              ) is
begin
  if p_tp = 0 then
    -- основная выгрузка льготников
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
  elsif p_tp = 1 then
    -- выгрузка льготников для ТКО
    open prep_refcursor for
      select org1, datn, posel, nasp, nylic, ndom, nkorp, nkw, nkomn, lchet,
             famil, imja, otch, drog, id_pku, pku, gku1, lchet1, ed_izm1,
             fakt1, sum_f1, prz1
        from load_privs t
       where t.fk_file = p_file and t.tp=1;
  end if;
end;

-- экспорт в DBF
procedure rep_to_dbf(p_file in number, -- Id файла
              p_tp in number,             -- тип (0-основная выгрузка, 1-ТКО)
              p_fname in varchar2
              ) is
 ret varchar2(100);             
begin
  if p_tp = 0 then
    -- основная выгрузка льготников
      delete from temp_load_privs;
      insert into temp_load_privs(org1, datn, posel, nasp, nylic, ndom, nkorp, nkw, nkomn, lchet,
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
             ed_izm10, fakt10, sum_f10, prz10)
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
       ret:=p_java.saveDBF(p_table_in_name => 'temp_debits_lsk_month', p_table_out_name => p_fname);

  elsif p_tp = 1 then
    -- выгрузка льготников для ТКО
      delete from temp_load_privs_tko;
      insert into temp_load_privs_tko(org1, datn, posel, nasp, nylic, ndom, nkorp, nkw, nkomn, lchet,
             famil, imja, otch, drog, id_pku, pku, gku1, lchet1, ed_izm1,
             fakt1, sum_f1, prz1)
      select org1, datn, posel, nasp, nylic, ndom, nkorp, nkw, nkomn, lchet,
             famil, imja, otch, drog, id_pku, pku, gku1, lchet1, ed_izm1,
             fakt1, sum_f1, prz1
        from load_privs t
       where t.fk_file = p_file and t.tp=1;
       ret:=p_java.saveDBF(p_table_in_name => 'temp_load_privs_tko', p_table_out_name => p_fname);
  end if;
end;


END c_load_privs;
/

