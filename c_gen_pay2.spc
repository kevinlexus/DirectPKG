create or replace package scott.c_gen_pay2 is
  g_mg params.period%type;

  procedure dist_all;
  procedure dist_mg(p_mg in params.period%type);

  procedure dist_pay_lsk(rec2_ in a_kwtp_mg%rowtype, --строка из c_kwtp_mg
                         itr_ in number --номер итерации
                        );

  procedure dist_pay_var(p_reu     in varchar2,
                         excl_usl_ in oper.fk_usl%type,
                         rec_      in a_kwtp_mg%rowtype,
                         var_      in number,
                         fk_distr_ in number);
  procedure dist_pay_prep(rec_         in a_kwtp_mg%rowtype,
                          l_summa      in number,
                          fk_distr_    in number,
                          l_itg        out number,
                          l_priznak    in loader1.kwtp_day.priznak%type,
                          l_forсesign in number);
  --редирект оплаты/пени
  procedure redirect(p_tp      in number, --1-оплата, 0 - пеня
                     p_reu     in varchar2, --код РЭУ
                     p_usl_src in varchar2, --исходная услуга
                     p_usl_dst out varchar2, --исходная орг.
                     p_org_src in number, --перенаправленная услуга
                     p_org_dst out number --перенаправленная орг.
                     );

end c_gen_pay2;
/

