create or replace package scott.c_gen_pay is
  time_ date;
  procedure distrib_payment_mg;
  procedure distrib_days(dat1_ in date, dat2_ in date);

  procedure dist_pay_prep(rec_         in c_kwtp_mg%rowtype,
                          l_summa      in number,
                          fk_distr_    in number,
                          l_itg        out number,
                          l_priznak    in kwtp_day.priznak%type,
                          l_forсesign in number);
  procedure load_ext_pay;
  procedure dist_pay_del_corr(p_lsk in kart.lsk%type default null);
  procedure dist_pay_add_corr(var_ in number, p_lsk in kart.lsk%type default null);
  --редирект оплаты/пени
  procedure redirect(p_tp      in number, --1-оплата, 0 - пеня
                     p_reu     in varchar2, --код РЭУ
                     p_usl_src in varchar2, --исходная услуга
                     p_usl_dst out varchar2, --исходная орг.
                     p_org_src in number, --перенаправленная услуга
                     p_org_dst out number --перенаправленная орг.
                     );
  procedure dist_sal_corr;
end c_gen_pay;
/

