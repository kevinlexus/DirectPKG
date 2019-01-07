CREATE OR REPLACE TYPE SCOTT."REC_BILL_ROW" as object
(
  usl      char(3),
  parent_usl      char(3),
  vol     number,
  price     number,
  charge    number,
  deb      number,
  change1 number,
  change_proc1 NUMBER,
  change2 number,
  kub number,
  pay number,
  chargeOwn NUMBER
)
/

