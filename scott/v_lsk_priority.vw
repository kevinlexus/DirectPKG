create or replace force view scott.v_lsk_priority as
select "LSK","KUL","ND","KW","FIO","KPR","KPR_WR","KPR_OT","KPR_CEM","KPR_S","OPL","PPL","PLDOP","KI","PSCH","PSCH_DT","STATUS","KWT","LODPL","BEKPL","BALPL","KOMN","ET","KFG","KFOT","PHW","MHW","PGW","MGW","PEL","MEL","SUB_NACH","SUBSIDII","SUB_DATA","POLIS","SCH_EL","REU","TEXT","SCHEL_DT","EKSUB1","EKSUB2","KRAN","KRAN1","EL","EL1","SGKU","DOPPL","SUBS_COR","HOUSE_ID","C_LSK_ID","MG1","MG2","KAN_SCH","SUBS_INF","K_LSK_ID","DOG_NUM","SCHEL_END","FK_DEB_ORG","SUBS_CUR","K_FAM","K_IM","K_OT","MEMO","FK_DISTR","LAW_DOC","FK_PASP_ORG","FLAG","FLAG1","FK_ERR","LAW_DOC_DT","PRVT_DOC","PRVT_DOC_DT","CPN","KPR_WRP","PN_DT","LSK_EXT","FK_TP","SEL1","VVOD_OT","ENTR","POT","MOT","ELSK","PARENT_LSK","FK_KLSK_OBJ","DT_CR","LSK_MAIN"
 from (
              select k2.*,
               first_value(k2.lsk) over (partition by k2.k_lsk_id order by decode(k2.psch,8,1,9,1,0), tp2.npp) as lsk_main
               from kart k2 join v_lsk_tp tp2 on k2.fk_tp=tp2.id) a where a.lsk=a.lsk_main;

