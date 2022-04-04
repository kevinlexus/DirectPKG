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

--���������� ������� � �������� - ������ � ���� ������ �� fk_klsk (���.���.�����)
  procedure prep_output2(p_mg in params.period%type, -- ������
                       p_file in number,           -- Id �����
                       p_cnt out number,            -- ���-�� �������, ��� ������
                       p_tp in number             -- ��� (0-�������� ��������, 1-���)
                       );
  --���������� ������� � ��������
  procedure prep_output(p_mg in params.period%type, p_file in number, p_cnt out number);
  --��������� ��� ��������
  procedure rep(p_file in number, prep_refcursor in out rep_refcursor, -- Id �����
                p_tp in number             -- ��� (0-�������� ��������, 1-���)
                );
  procedure rep_to_dbf(p_file in number, -- Id �����
              p_tp in number,             -- ��� (0-�������� ��������, 1-���)
              p_fname in varchar2
              );
end c_load_privs;
/

