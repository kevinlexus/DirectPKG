create or replace package scott.C_DIST_PAY2 is

 procedure gen_deb_usl_all;
 procedure gen_deb_usl(l_lsk in kart.lsk%type, l_commit in number);
 procedure dist_pay_all;
 procedure dist_pay_deb_mg_lsk(p_reu in kart.reu%type, p_rec in c_kwtp_mg%rowtype);
 procedure dist_pay_lsk_force;

 --������ ��� ������� �� ��������� 
 --��������!!!!(������ ��� ����������!!!! �� ������������ ��� ��������� ������, ��� ��� �� ��������� �������� ������)
 function redirect_org (p_tp in number, --1-������, 0 - ����
                        p_reu in varchar2, --��� ���
                        p_usl_src in varchar2, --�������� ������
                        p_org_src in number,  --�������� ���.
                        t_redir in tab_redir --������� ����������
                        ) return number;
 --�������� ������/���� 
 procedure redirect (p_tp in number, --1-������, 0 - ����
                        p_reu in varchar2, --��� ���
                        p_usl_src in varchar2, --�������� ������
                        p_usl_dst out varchar2,--���������������� ������
                        p_org_src in number,  --�������� ���.
                        p_org_dst out number, --���������������� ���.
                        t_redir in tab_redir --������� ����������
                        );
  procedure dist_pay_lsk_avnc_force;
end C_DIST_PAY2;
/

