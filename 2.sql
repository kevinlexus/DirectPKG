-------------------------------------------
-- Export file for user EXS@ORCL         --
-- Created by Leo on 23.04.2020, 8:30:42 --
-------------------------------------------

set define off
spool 2.log

prompt
prompt Creating table CRONE
prompt ====================
prompt
@@crone.tab
prompt
prompt Creating table EOLINK
prompt =====================
prompt
@@eolink.tab
prompt
prompt Creating table EOLXEOL
prompt ======================
prompt
@@eolxeol.tab
prompt
prompt Creating table EOLXPAR
prompt ======================
prompt
@@eolxpar.tab
prompt
prompt Creating table U_LISTTP
prompt =======================
prompt
@@u_listtp.tab
prompt
prompt Creating table U_LIST
prompt =====================
prompt
@@u_list.tab
prompt
prompt Creating table METER_VAL
prompt ========================
prompt
@@meter_val.tab
prompt
prompt Creating table PDOC
prompt ===================
prompt
@@pdoc.tab
prompt
prompt Creating table NOTIF
prompt ====================
prompt
@@notif.tab
prompt
prompt Creating table REESTR
prompt =====================
prompt
@@reestr.tab
prompt
prompt Creating table SERVGIS
prompt ======================
prompt
@@servgis.tab
prompt
prompt Creating table TASK
prompt ===================
prompt
@@task.tab
prompt
prompt Creating table TASKXEOL
prompt =======================
prompt
@@taskxeol.tab
prompt
prompt Creating table TASKXPAR
prompt =======================
prompt
@@taskxpar.tab
prompt
prompt Creating table TASKXTASK
prompt ========================
prompt
@@taskxtask.tab
prompt
prompt Creating sequence SEQ_BASE
prompt ==========================
prompt
@@seq_base.seq
prompt
prompt Creating sequence SEQ_CRONE
prompt ===========================
prompt
@@seq_crone.seq
prompt
prompt Creating sequence SEQ_EOLINK
prompt ============================
prompt
@@seq_eolink.seq
prompt
prompt Creating sequence SEQ_EOLXEOL
prompt =============================
prompt
@@seq_eolxeol.seq
prompt
prompt Creating sequence SEQ_EOLXPAR
prompt =============================
prompt
@@seq_eolxpar.seq
prompt
prompt Creating sequence SEQ_LOG
prompt =========================
prompt
@@seq_log.seq
prompt
prompt Creating sequence SEQ_METER_VAL
prompt ===============================
prompt
@@seq_meter_val.seq
prompt
prompt Creating sequence SEQ_NOTIF
prompt ===========================
prompt
@@seq_notif.seq
prompt
prompt Creating sequence SEQ_PARXDEP
prompt =============================
prompt
@@seq_parxdep.seq
prompt
prompt Creating sequence SEQ_PDOC
prompt ==========================
prompt
@@seq_pdoc.seq
prompt
prompt Creating sequence SEQ_REESTR
prompt ============================
prompt
@@seq_reestr.seq
prompt
prompt Creating sequence SEQ_SERVGIS
prompt =============================
prompt
@@seq_servgis.seq
prompt
prompt Creating sequence SEQ_TASK
prompt ==========================
prompt
@@seq_task.seq
prompt
prompt Creating sequence SEQ_TASKXEOL
prompt ==============================
prompt
@@seq_taskxeol.seq
prompt
prompt Creating sequence SEQ_TASKXPAR
prompt ==============================
prompt
@@seq_taskxpar.seq
prompt
prompt Creating sequence SEQ_TASKXTASK
prompt ===============================
prompt
@@seq_taskxtask.seq
prompt
prompt Creating package P_GIS
prompt ======================
prompt
@@p_gis.pck
prompt
prompt Creating trigger CRONE_BIU_E
prompt ============================
prompt
@@crone_biu_e.trg
prompt
prompt Creating trigger EOLINK_BIU_E
prompt =============================
prompt
@@eolink_biu_e.trg
prompt
prompt Creating trigger EOLXEOL_BI_E
prompt =============================
prompt
@@eolxeol_bi_e.trg
prompt
prompt Creating trigger EOLXPAR_BI_E
prompt =============================
prompt
@@eolxpar_bi_e.trg
prompt
prompt Creating trigger EXS_REESTR_BI
prompt ==============================
prompt
@@exs_reestr_bi.trg
prompt
prompt Creating trigger METER_VAL_BIU_E
prompt ================================
prompt
@@meter_val_biu_e.trg
prompt
prompt Creating trigger NOTIF_BIU_E
prompt ============================
prompt
@@notif_biu_e.trg
prompt
prompt Creating trigger PDOC_BIU_E
prompt ===========================
prompt
@@pdoc_biu_e.trg
prompt
prompt Creating trigger SERVGIS_BI_E
prompt =============================
prompt
@@servgis_bi_e.trg
prompt
prompt Creating trigger TASKXEOL_BI_E
prompt ==============================
prompt
@@taskxeol_bi_e.trg
prompt
prompt Creating trigger TASKXPAR_BI_E
prompt ==============================
prompt
@@taskxpar_bi_e.trg
prompt
prompt Creating trigger TASKXTASK_BI_E
prompt ===============================
prompt
@@taskxtask_bi_e.trg
prompt
prompt Creating trigger TASK_BIU_E
prompt ===========================
prompt
@@task_biu_e.trg
prompt
prompt Creating trigger U_LISTTP_BI
prompt ============================
prompt
@@u_listtp_bi.trg
prompt
prompt Creating trigger U_LIST_BIE
prompt ===========================
prompt
@@u_list_bie.trg

spool off
