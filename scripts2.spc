create or replace package scott.scripts2 is
  --����������� ������ � ����� ������ ��� (����������) �� ������
  procedure swap_sal_chpay6;
  procedure swap_sal_chpay7;
  procedure swap_sal_chpay8;
  procedure swap_sal_chpay9;
  procedure swap_sal_with_pen10;
  procedure sub_ZERO_kis;
  procedure sub_ZERO_polis;
  procedure sub_ZERO_polis_main;
  procedure sub_ZERO_polis_usl(p_tmp_usl in scott.tab_tmp, -- ������ �����
                               p_tmp_org in scott.tab_tmp,  -- ������ �����������
                               p_tmp_reu in scott.tab_tmp,  -- ������ ��  (���� �� ������������)
                               p_org in number,  -- �����������
                               p_mark in varchar2, -- ������
                               p_mg in varchar2, -- ������� ������,
                               p_dat in date -- ������� ���� 
                               );
  procedure swap_sal_chpay10;
  procedure swap_sal_chpay11;
  procedure swap_sal_chpay11_2;
  procedure swap_sal_chpay11_3;
  procedure cr_new_xitog3(p_mg in params.period%type);
  procedure swap_sal_chpay12;
  procedure swap_sal_chpay13;
  --procedure move_kart_pr(p_lsk in kart.lsk%type);
  --procedure move_kart_pr_lsk(p_lsk in kart.lsk%type);
end scripts2;
/

