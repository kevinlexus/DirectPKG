CREATE OR REPLACE TYPE SCOTT."REC_NABOR"                                                                          as object (
  lsk            CHAR(8),
  usl            CHAR(3),
  org            NUMBER(3),
  koeff          NUMBER,
  norm           NUMBER,
  fk_tarif       NUMBER,
  fk_vvod        NUMBER,
  vol            NUMBER,
  vol_add        NUMBER,
  kf_kpr         NUMBER,
  sch_auto       NUMBER,
  nrm_kpr        NUMBER,
  kf_kpr_sch     NUMBER,
  kf_kpr_wrz     NUMBER,
  kf_kpr_wro     NUMBER,
  kf_kpr_wrz_sch NUMBER,
  kf_kpr_wro_sch NUMBER,
  limit          NUMBER,
  nrm_kpr2       number
   )
/

