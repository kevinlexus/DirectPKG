create or replace package scott.rep_saldo is
TYPE rep_refcursor IS REF CURSOR;
  PROCEDURE report_saldo(reu_           IN VARCHAR2,
                         trest_         IN VARCHAR2,
                         uslm_         IN VARCHAR2,
                         mg_            IN VARCHAR2,
                         mg1_           IN VARCHAR2,
                         var_         IN NUMBER,
                         prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_saldo_org_uslm(reu_           IN VARCHAR2,
                                  trest_         IN VARCHAR2,
                                  mg_            IN VARCHAR2,
                                  mg1_           IN VARCHAR2,
                                  kul_           IN VARCHAR2,
                                  nd_            IN VARCHAR2,
                                  var_           IN NUMBER,
                                  prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_saldo_uslm2(reu_           IN VARCHAR2,
                               trest_         IN VARCHAR2,
                               mg_            IN VARCHAR2,
                               mg1_           IN VARCHAR2,
                               kul_           IN VARCHAR2,
                               nd_            IN VARCHAR2,
                               uch_           IN NUMBER,
                               var_           IN NUMBER,
                               prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_saldo_org_uslm_itog(type_          IN NUMBER,
                                       reu_           IN VARCHAR2,
                                       trest_         IN VARCHAR2,
                                       uslk_          IN uslk.uslk%TYPE,
                                       mg_            IN VARCHAR2,
                                       mg1_           IN VARCHAR2,
                                       kul_           IN VARCHAR2,
                                       nd_            IN VARCHAR2,
                                       prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_saldo_org_uslm_itog2(type_          IN NUMBER,
                                        reu_           IN VARCHAR2,
                                        trest_         IN VARCHAR2,
                                        uslk_          IN uslk.uslk%TYPE,
                                        mg_            IN VARCHAR2,
                                        mg1_           IN VARCHAR2,
                                        kul_           IN VARCHAR2,
                                        nd_            IN VARCHAR2,
                                        uch_           IN NUMBER,
                                        prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_charges_usl(reu_           IN VARCHAR2,
                               trest_         IN VARCHAR2,
                               mg_            IN VARCHAR2,
                               mg1_           IN VARCHAR2,
                               var_           IN NUMBER,
                               type_           IN NUMBER,
                               det_           IN NUMBER,
                               prep_refcursor IN OUT rep_refcursor);
end rep_saldo;
/

