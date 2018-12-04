create or replace package scott.c_load_privs is
  type rep_refcursor is ref cursor;
  --�������� ���������������� �����������
  procedure clear_spr;
  --�������� ���������������� �������
  procedure clear_tabs;
  --�������� ������ � ������������� �����, �������� ������� ������
  procedure add_file(p_name in prep_file.name%type);
  --���������� ������� ������������ ����
  procedure prep_street;
  --���������� ������� ������������ ����� 
  procedure prep_house;

  --���������� ������� � ��������
  procedure prep_output(p_mg in params.period%type, p_file in number, p_cnt out number);
  --��������� ��� ��������
  procedure rep(p_file in number, prep_refcursor in out rep_refcursor);
  
end c_load_privs;
/

