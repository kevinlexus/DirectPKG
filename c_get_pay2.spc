create or replace package scott.C_GET_PAY2 is
  --глобальна€ переменна€ определ€юща€ текущий номер компьютера пользовател€
  TYPE rep_refcursor IS REF CURSOR;
  type ccur is ref cursor;

  --флаг распределени€ оплаты
  g_flag_upd number;
  function get_payment_bank_date return date;
  function check_payment_bank_date return number;
  function check_payment_bank_nink(nink_ in c_kwtp.nink%type) return number;
  function get_payment_bank_summa return number;
  function get_payment_bank_summp return number;
  procedure cur_payment_bank(id_            in number,
                             prep_refcursor in out rep_refcursor);
  function recv_payment_bank(nink_ in c_kwtp.nink%type) return number;

  procedure get_payment(dtek_      in c_kwtp.dtek%type,
                        lsk_       in c_kwtp.lsk%type,
                        summa_     in c_kwtp.summa%type,
                        penya_     in c_kwtp.penya%type,
                        oper_      in c_kwtp.oper%type,
                        dopl_      in c_kwtp.dopl%type,
                        iscorrect_ number,
                        nkvit1_    in c_kwtp.nkvit%type,
                        iscommit_  in number,
                        num_doc_   in c_kwtp.num_doc%type,
                        dat_doc_   in c_kwtp.dat_doc%type,
                        nink_      in number default 0,
                        dat_ink_   in date default null);

  procedure get_payment_mg(id_      in c_kwtp.id%type,
                           nkvit_   in c_kwtp.nkvit%type,
                           lsk_     in c_kwtp.lsk%type,
                           summa_   in c_kwtp.summa%type,
                           penya_   in c_kwtp.penya%type,
                           oper_    in c_kwtp.oper%type,
                           dopl_    in c_kwtp.dopl%type,
                           p_pay_tp in number,
                           nkom_    in c_kwtp.nkom%type,
                           dtek_    in c_kwtp.dtek%type,
                           nink_    in c_kwtp.nink%type,
                           dat_ink_ in date);

  function get_tails return number;
  function dst_money_cur_month(summa_ number) return number;
  function dst_money_cur_month2(summa_ number) return number;
  function get_money_nal(lsk_ in kart.lsk%type) return c_kwtp.id%type;
  procedure get_money_nal2(prep_refcursor in out rep_refcursor);
  procedure make_inkass;
  procedure init_c_kwtp_temp_dolg(p_lsk in kart.lsk%type);
  procedure remove_pay(id_ in c_kwtp.id%type);
  procedure remove_inkass(nkom_ in c_kwtp.nkom%type,
                          nink_ in c_kwtp.nink%type);
  function reverse_pay(p_kwtp_id in c_kwtp.id%type) return number;
  /*procedure create_notification_gis(rec c_kwtp_mg%rowtype);
  procedure create_notification_gis_all;
  */
  procedure get_receipt_detail(p_kwtp_id in number, -- id платежа дет. до периода
                               p_rfcur   out ccur -- исх.рефкурсор
                               );
end C_GET_PAY2;
/

