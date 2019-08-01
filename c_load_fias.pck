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

CREATE OR REPLACE PACKAGE BODY SCOTT.c_load_fias IS
--����� �������� �������� � ��������� �������� ����������

--�������� ���������������� �����������
procedure clear_spr is
begin
  delete from prep_street_fias;
  delete from prep_house_fias;
null;
end clear_spr;

--�������� ���������������� �������
procedure clear_tabs is
begin
  delete from prep_file;
end clear_tabs;

--�������� ������ � ������������� �����, �������� ������� ������
procedure add_file(p_name in prep_file.name%type) is
 l_id number;
begin
  insert into prep_file(name)
   values(p_name)
   returning id into l_id;
  update load_privs t set t.fk_file=l_id where t.fk_file is null;
end;

--���������� ������� ������������ ����
procedure prep_street is
begin
  insert into prep_street_fias
    (aoguid)
  select t.aoguid from fias_addr t
   join t_org o on upper(o.aoguid)=upper(t.parentguid)
   --join t_org_tp tp on o.fk_orgtp=tp.id and tp.cd='�����' -�����, ��� ��� ����� ���� ����� ������� � ������ ���
     and gdt(0,0,0)/*init.get_dt_end*/ between t.startdate and t.enddate
   where not exists 
    (select * from prep_street_fias r where upper(t.aoguid)=upper(r.aoguid));
end prep_street;

--���������� ������� ������������ ����� 
procedure prep_house is
begin
  --��������� ������ ����� ����, ������� ������������� ���������� ������������� ������
  insert into prep_house_fias
    (kul, houseguid)
  select t.kul, h.houseguid from fias_house h join
       prep_street_fias t on upper(h.aoguid)=upper(t.aoguid) and t.kul is not null
       and gdt(0,0,0)/*init.get_dt_end*/ between h.startdate and h.enddate
       and not exists (select * from prep_house_fias p where upper(p.houseguid)=upper(h.houseguid));
     
end prep_house;

END c_load_fias;
/

