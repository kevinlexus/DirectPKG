create or replace package scott.C_CPENYA is
  time_ date;

  procedure gen_charge_pay_pen;
  procedure gen_charge_pay_pen(p_dt in date);
  procedure gen_charge_pay_pen_house(p_house in number);
  procedure gen_charge_pay_pen(
                             p_dt in date, --���� ������.
                             p_var in number --����������� ����? (0-���, 1-�� (������ �����)
          );
  procedure gen_charge_pay_pen(p_lsk in kart.lsk%type, -- ��� ���� (���� null - �� ��� ���.�����)
                               p_dt in date, --���� ������.
                               p_var in number --����������� ����? (0-���, 1-�� (������ �����)
            );

  procedure gen_charge_pay_full;

  procedure gen_charge_pay(lsk_ in kart.lsk%type, iscommit_ in number);
  procedure gen_charge_pay(lsk_      in kart.lsk%type, --��� ����
                           iscommit_ in number, --������� �� ������
                           p_dt      in date --���� �� ������� ��������� ����������
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

