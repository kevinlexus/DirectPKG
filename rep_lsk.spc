create or replace package scott.rep_lsk is
  type rep_refcursor is ref cursor;
  procedure rep(p_rep_cd in varchar2, --CD ������
              p_lsk in kart.lsk%type, --���.����.
              p_mg1 in varchar2, --������ �������
              p_mg2 in varchar2, --��������� �������
              prep_refcursor in out rep_refcursor
              );
end rep_lsk;
/

