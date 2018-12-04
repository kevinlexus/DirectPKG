CREATE OR REPLACE PACKAGE SCOTT.agent IS
 TYPE rep_refcursor IS REF CURSOR;
 PROCEDURE uptime;
 PROCEDURE load_proc_plan;
 procedure load_subs_el;
 procedure load_subs_cor;
 procedure load_subs_inf;
 procedure recv_payment_for_en (dat1_ in date,
                                   dat2_ in date);
 procedure unload_en;
 procedure list_lsk(kul_           in kart.kul%type,
                      nd_            in kart.nd%type,
                      kw_            in kart.kw%type,
                      prep_refcursor in out rep_refcursor);

END agent;
/

