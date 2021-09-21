CREATE OR REPLACE PACKAGE SCOTT.rep_opl IS
  TYPE rep_refcursor IS REF CURSOR;
  PROCEDURE report_xito10(var_           IN XXITO12.var%TYPE,
                          reptype_       IN NUMBER,
                          det_           IN NUMBER, --Дополнительная расшифровка по предприятиям
                          reu_           IN XXITO12.reu%TYPE,
                          kul_           IN XXITO12.kul%TYPE,
                          nd_            IN XXITO12.nd%TYPE,
                          trest_         IN XXITO12.trest%TYPE,
                          org_           IN NUMBER,
                          dat_           IN XXITO12.dat%TYPE,
                          dat1_          IN XXITO12.dat%TYPE,
                          status_        IN XXITO12.STATUS%TYPE,
                          mg_            IN XXITO12.mg%TYPE,
                          mg1_           IN XXITO12.mg%TYPE,
                          period_        IN XXITO12.dopl%TYPE,
                          period1_       IN XXITO12.dopl%TYPE,
                          prep_refcursor IN OUT rep_refcursor);

  PROCEDURE report_xito3(reu_           IN VARCHAR2,
                         trest_         IN VARCHAR2,
                         mg_            IN VARCHAR2,
                         mg1_           IN VARCHAR2,
                         prep_refcursor IN OUT rep_refcursor);

  PROCEDURE report_xito11(oper_          IN VARCHAR2,
                          reu_           IN VARCHAR2,
                          trest_         IN VARCHAR2,
                          org_           IN NUMBER,
                          dat_           IN XITO5.dat%TYPE,
                          dat1_          IN XITO5.dat%TYPE,
                          mg_            IN VARCHAR2,
                          mg1_           IN VARCHAR2,
                          prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_xito5(var_           IN NUMBER,
                         type_          IN NUMBER,
                         reu_           IN VARCHAR2,
                         trest_         IN VARCHAR2,
                         dat_           IN XITO5.dat%TYPE,
                         dat1_          IN XITO5.dat%TYPE,
                         mg_            IN VARCHAR2,
                         mg1_           IN VARCHAR2,
                         prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_xito5_itog(var_           IN NUMBER,
                              type_          IN NUMBER,
                              dat_           IN XITO5.dat%TYPE,
                              dat1_          IN XITO5.dat%TYPE,
                              mg_            IN VARCHAR2,
                              mg1_           IN VARCHAR2,
                              prep_refcursor IN OUT rep_refcursor);
END rep_opl;
/

