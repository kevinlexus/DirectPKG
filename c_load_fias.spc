create or replace package scott.c_load_fias is
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
end c_load_fias;
/

