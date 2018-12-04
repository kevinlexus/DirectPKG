create or replace package scott.C_DIST_PAY2 is

 procedure gen_deb_usl_all;
 procedure gen_deb_usl(l_lsk in kart.lsk%type, l_commit in number);
 procedure dist_pay_all;
 procedure dist_pay_deb_mg_lsk(p_reu in kart.reu%type, p_rec in c_kwtp_mg%rowtype);
 procedure dist_pay_lsk_force;

 --обёртка для функции по редиректу 
 --ВНИМАНИЕ!!!!(только для начисления!!!! не использовать для редиректа оплаты, так как не выполняет редирект услуги)
 function redirect_org (p_tp in number, --1-оплата, 0 - пеня
                        p_reu in varchar2, --код РЭУ
                        p_usl_src in varchar2, --исходная услуга
                        p_org_src in number,  --исходная орг.
                        t_redir in tab_redir --таблица редиректов
                        ) return number;
 --редирект оплаты/пени 
 procedure redirect (p_tp in number, --1-оплата, 0 - пеня
                        p_reu in varchar2, --код РЭУ
                        p_usl_src in varchar2, --исходная услуга
                        p_usl_dst out varchar2,--перенаправленная услуга
                        p_org_src in number,  --исходная орг.
                        p_org_dst out number, --перенаправленная орг.
                        t_redir in tab_redir --таблица редиректов
                        );
  procedure dist_pay_lsk_avnc_force;
end C_DIST_PAY2;
/

