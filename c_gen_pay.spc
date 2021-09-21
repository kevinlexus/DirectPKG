create or replace package scott.c_gen_pay is
  time_ date;
  procedure distrib_payment_mg;
  procedure distrib_days(dat1_ in date, dat2_ in date);

  --������������� ������
  procedure dist_pay_lsk(rec2_ in c_kwtp_mg%rowtype, --������ �� c_kwtp_mg
                         itr_ in number --����� ��������
                        );

  procedure dist_pay_var(p_reu     in varchar2,
                         excl_usl_ in oper.fk_usl%type,
                         rec_      in c_kwtp_mg%rowtype,
                         var_      in number,
                         fk_distr_ in number);
  procedure dist_pay_prep(rec_         in c_kwtp_mg%rowtype,
                          l_summa      in number,
                          fk_distr_    in number,
                          l_itg        out number,
                          l_priznak    in kwtp_day.priznak%type,
                          l_for�esign in number);
  procedure dist_pay_lsk_force;
  procedure load_ext_pay;
  procedure dist_pay_del_corr(p_lsk in kart.lsk%type default null);
  procedure dist_pay_add_corr(var_ in number, p_lsk in kart.lsk%type default null);
  --�������� ������/���� 
  procedure redirect(p_tp      in number, --1-������, 0 - ����
                     p_reu     in varchar2, --��� ���
                     p_usl_src in varchar2, --�������� ������
                     p_usl_dst out varchar2, --�������� ���.
                     p_org_src in number, --���������������� ������
                     p_org_dst out number --���������������� ���.
                     );
  procedure dist_sal_corr;
end c_gen_pay;
/

