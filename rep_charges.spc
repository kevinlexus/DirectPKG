CREATE OR REPLACE PACKAGE SCOTT.rep_charges IS
  TYPE rep_refcursor IS REF CURSOR;
  PROCEDURE report_xito13(reu_           IN XITO13.reu%TYPE,
                          kul_           IN XITO13.kul%TYPE,
                          nd_            IN XITO13.nd%TYPE,
                          trest_         IN XITO13.trest%TYPE,
                          mg_            IN XITO13.mg%TYPE,
                          mg1_           IN XITO13.mg%TYPE,
                          prep_refcursor IN OUT rep_refcursor);
END rep_charges;
/

