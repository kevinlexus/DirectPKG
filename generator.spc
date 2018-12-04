CREATE OR REPLACE PACKAGE SCOTT.generator IS
  time_ DATE;
  -- Author  : LEV
  -- Created : 24/02/04 15:08:53
  -- Purpose :
  -- Public type declarations
  TYPE rep_refcursor IS REF CURSOR;
  TYPE sal_refcursor IS REF CURSOR;
  PROCEDURE disable_keys(var_ IN NUMBER);
  PROCEDURE enable_keys(var_ IN NUMBER);
  PROCEDURE test_constr_errs(cnt_ OUT NUMBER, var_ IN NUMBER);
  PROCEDURE del_table_rows(tname_      IN VARCHAR2,
                           field_name_ IN VARCHAR2,
                           dat1_       IN DATE,
                           dat2_       IN DATE);
  PROCEDURE del_table_rows_allxito(dat_ IN VARCHAR2);
  PROCEDURE insert_charges(lsk_   IN VARCHAR2,
                           usl_   IN VARCHAR2,
                           mg_    IN VARCHAR2,
                           summa_ IN NUMBER);
  PROCEDURE delete_charges(lsk1_ IN VARCHAR2, lsk2_ IN VARCHAR2);
  PROCEDURE delete_subsidii(lsk1_ IN VARCHAR2, lsk2_ IN VARCHAR2);
  PROCEDURE insert_subsidii(lsk_   IN VARCHAR2,
                            usl_   IN VARCHAR2,
                            mg_    IN VARCHAR2,
                            summa_ IN NUMBER);
  PROCEDURE report_saldo(reu_           IN VARCHAR2,
                         trest_         IN VARCHAR2,
                         mg_            IN VARCHAR2,
                         mg1_           IN VARCHAR2,
                         prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_debit(type_          IN NUMBER,
                         trest_         IN S_REU_TREST.trest%TYPE,
                         prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_proc_org(prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_proc_plan(reu_           IN S_REU_TREST.reu%TYPE,
                             trest_         IN S_REU_TREST.trest%TYPE,
                             dat1_          IN PROC_PLAN_LOADED.dat%TYPE,
                             dat2_          IN PROC_PLAN_LOADED.dat%TYPE,
                             prep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_opl_tr_own(prep_refcursor IN OUT rep_refcursor);

  PROCEDURE report_pen(var_            IN NUMBER,
                       reu_            IN VARCHAR2,
                       trest_          IN VARCHAR2,
                       dat_            IN DATE,
                       dat1_           IN DATE,
                       mg_             IN VARCHAR2,
                       mg1_            IN VARCHAR2,
                       v_rep_refcursor IN OUT rep_refcursor);
  PROCEDURE report_check_rep(var_            IN NUMBER,
                             mg_             IN XITOG3.mg%TYPE,
                             mg1_            IN XITOG3.mg%TYPE,
                             v_rep_refcursor IN OUT rep_refcursor);
/*  procedure report_lg_usl_org(var_           in number,
                              var1_          in number,
                              reu_           in xito_lg2.reu%type,
                              trest_         in xito_lg2.trest%type,
                              houses_        in number,
                              org_           in xito_lg2.org_id%type,
                              mg_            in xito_lg2.mg%type,
                              mg1_           in xito_lg2.mg%type,
                              prep_refcursor in out rep_refcursor);
  procedure report_lg_stat(mg_            in xito_lg2.mg%type,
                           prep_refcursor in out rep_refcursor);*/

  PROCEDURE report_bank(var_           IN NUMBER,
                        dat_           IN XITO5.dat%TYPE,
                        dat1_          IN XITO5.dat%TYPE,
                        mg_            IN XITO5.mg%TYPE,
                        mg1_           IN XITO5.mg%TYPE,
                        prep_refcursor OUT rep_refcursor);
  PROCEDURE list_choice(clr_           IN NUMBER,
                        prep_refcursor IN OUT rep_refcursor);
  PROCEDURE list_choice_set(set_ IN NUMBER);
  PROCEDURE list_choice_uch(clr_           IN NUMBER,
                            prep_refcursor IN OUT rep_refcursor);
  PROCEDURE list_choice_set_uch(set_ IN NUMBER);
  PROCEDURE list_choice_usl(clr_           IN NUMBER,
                            prep_refcursor IN OUT rep_refcursor);
  PROCEDURE list_choice_usl_set(set_ IN NUMBER);
  PROCEDURE list_choice_reu(clr_           IN NUMBER,
                            prep_refcursor IN OUT rep_refcursor);
  procedure list_choice_hs_set(set_ in number);
  procedure list_choice_hs(clr_ in number,
                        prep_refcursor in out rep_refcursor);
  PROCEDURE del_day_payments(mg_ IN VARCHAR2);
  PROCEDURE check_day_hints(cnt_ OUT NUMBER);
END generator;
/

