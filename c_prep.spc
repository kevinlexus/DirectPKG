create or replace package scott.c_prep is

  procedure dist_summa;
  procedure dist_summa2;
  --������������ ����� ��������� (����� ����), ���������������, �� ������ ���������
  function dist_summa_full(p_sum in number, t_summ in out tab_summ)
    return number;
  --������������ ������ �� �������� ����������� (��� �������� �������� �� ���.�����)
  procedure dist_summa3(p_lsk     in kart.lsk%type, --�.�.
                        p_mg      in params.period%type, --���.������
                        p_mg_back in params.period%type --������ �� ����� �����
                        );
end c_prep;
/

