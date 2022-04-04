create or replace force view scott.v_load_privs as
select t.id, k.lsk, k.fk_tp, t."ORG1",t."DATN",t."POSEL",
t."NASP",t."NYLIC",t."NDOM",t."NKORP",t."NKW",t."NKOMN",
t."LCHET",t."FAMIL",t."IMJA",t."OTCH",t."DROG",t."ID_PKU",
t."PKU",t."GKU1",t."LCHET1",t."ED_IZM1",t."FAKT1",t."SUM_F1",t."PRZ1",t."GKU2",t."LCHET2",t."ED_IZM2",t."FAKT2",t."SUM_F2",t."NORM2",t."FAKT21",t."SUM_F21",t."O_PL2",t."PRZ2",t."GKU3",t."LCHET3",t."ED_IZM3",t."FAKT3",t."SUM_F3",t."NORM3",t."PR3_1",t."PR3_2",t."PR3_3",t."O_PL3",t."PRZ3",t."GKU4",t."LCHET4",t."ED_IZM4",t."FAKT4",t."SUM_F4",t."NORM4",t."PRZ4",t."GKU5",t."LCHET5",t."ED_IZM5",t."FAKT5",t."SUM_F5",t."NORM5",t."FAKT51",t."SUM_F51",t."O_PL5",t."PRZ5",t."GKU6",t."LCHET6",t."ED_IZM6",t."FAKT6",t."SUM_F6",t."NORM6",t."PRZ6",t."GKU7",t."LCHET7",t."ED_IZM7",t."FAKT7",t."SUM_F7",t."NORM7",t."FAKT71",t."SUM_F71",t."O_PL7",t."PRZ7",t."GKU8",t."LCHET8",t."ED_IZM8",t."FAKT8",t."SUM_F8",t."NORM8",t."PRZ8",t."GKU9",t."LCHET9",t."ED_IZM9",t."FAKT9",t."SUM_F9",t."NORM9",t."FAKT91",t."TF_N",t."TF_SV",t."O_PL9",t."PRZ9",t."GKU10",t."LCHET10",t."ED_IZM10",t."FAKT10",t."SUM_F10",t."PRZ10",t."FK_LSK",t."FK_FILE",t."TP"
  from load_privs t
  left join prep_house t2
    on t.nylic=t2.ext_nylic and nvl(t.ndom,'XXX')=nvl(t2.ext_ndom,'XXX') and nvl(t.nkorp,'XXX')=nvl(t2.ext_nkorp,'XXX')
  left join prep_street t3
    on t3.ext_nylic = t2.ext_nylic
  left join v_lsk_tp tp2 on tp2.cd in ('LSK_TP_MAIN','LSK_TP_RSO')
  left join kart k
    on k.nd=t2.nd and k.kul=t3.kul and upper(k.kw)=lpad(upper(t.nkw),7,'0')
    and k.psch not in (8,9)and k.fk_tp=tp2.id and k.sel1=1
  where  nvl(t.tp,0)=0;

