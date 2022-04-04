create or replace force view scott.v_kart as
select k."LSK",k."KUL",k."ND",k."KW",k."FIO",k."KPR",k."KPR_WR",k."KPR_OT",k."KPR_CEM",k."KPR_S",k."OPL",k."PPL",k."PLDOP",k."KI",k."PSCH",k."PSCH_DT",k."STATUS",k."KWT",k."LODPL",k."BEKPL",k."BALPL",k."KOMN",k."ET",k."KFG",k."KFOT",k."PHW",k."MHW",k."PGW",k."MGW",k."PEL",k."MEL",k."SUB_NACH",k."SUBSIDII",k."SUB_DATA",k."POLIS",k."SCH_EL",k."REU",k."TEXT",k."SCHEL_DT",k."EKSUB1",k."EKSUB2",k."KRAN",k."KRAN1",k."EL",k."EL1",k."SGKU",k."DOPPL",k."SUBS_COR",k."HOUSE_ID",k."C_LSK_ID",k."MG1",k."MG2",k."KAN_SCH",k."SUBS_INF",k."K_LSK_ID",k."DOG_NUM",k."SCHEL_END",k."FK_DEB_ORG",k."SUBS_CUR",k."K_FAM",k."K_IM",k."K_OT",k."MEMO",k."FK_DISTR",k."LAW_DOC",k."FK_PASP_ORG",k."FLAG",k."FLAG1",k."FK_ERR",k."LAW_DOC_DT",k."PRVT_DOC",k."PRVT_DOC_DT",k."CPN",k."KPR_WRP",k."PN_DT",k."LSK_EXT",k."FK_TP"
    from kart k, v_lsk_tp tp
    where k.fk_tp=tp.id(+)
    and case when p_houses.get_g_lsk_tp=0 and tp.cd='LSK_TP_MAIN' then 1 --только основные лс
             when p_houses.get_g_lsk_tp=1 and tp.cd='LSK_TP_ADDIT' then 1  --только дополнительные лс
             when p_houses.get_g_lsk_tp=2 then 1 --все лс
             else 0 end=1
;

