CREATE OR REPLACE TYPE SCOTT."REC_STATE"                                                                          as object (
  fk_kart_pr     number,
  fk_status      number,
  tp             number,
  dt1            date,
  dt2            date,
  dat_rog        date,
  rel_cd         varchar2(128)
   )
/

