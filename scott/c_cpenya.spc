create or replace package scott.C_CPENYA is
  time_ date;

  procedure gen_charge_pay_pen;
  procedure gen_charge_pay_pen(p_dt in date);
  procedure gen_charge_pay_pen_house(p_house in number);
  procedure gen_charge_pay_pen(
                             p_dt in date, --дата формир.
                             p_var in number --формировать пеню? (0-нет, 1-да (старый вызов)
          );
  procedure gen_charge_pay_pen(p_lsk in kart.lsk%type, -- лиц счет (если null - то все лиц.счета)
                               p_dt in date, --дата формир.
                               p_var in number --формировать пеню? (0-нет, 1-да (старый вызов)
            );

  procedure gen_charge_pay_full;

  procedure gen_charge_pay(lsk_ in kart.lsk%type, iscommit_ in number);
  procedure gen_charge_pay(lsk_      in kart.lsk%type, --лиц счет
                           iscommit_ in number, --ставить ли коммит
                           p_dt      in date --дата по которую принимать транзакции
                           );

  procedure gen_penya(lsk_         in kart.lsk%type,
                      islastmonth_ in number,
                      p_commit     in number);
  procedure gen_penya(lsk_         in kart.lsk%type,
                      dat_         in date,
                      islastmonth_ in number,
                      p_commit     in number);

  function corr_sal_pen(p_lsk in kart.lsk%type,
                        p_mg  in c_pen_corr.dopl%type) return number;
  function corr_all_sal_pen(p_lsk in kart.lsk%type) return number;
  function corr_sal_pen2(p_lsk in kart.lsk%type, p_lsk2 in kart.lsk%type)
    return number;

end C_CPENYA;
/

