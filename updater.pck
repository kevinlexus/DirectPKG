create or replace package scott.UPDATER is

procedure send_message(msg_ in messages.text%type);
procedure set_ver(ver_ in number, type_ in number);
procedure del_types;

end UPDATER;
/

create or replace package body scott.UPDATER is

procedure send_message(msg_ in messages.text%type) is
begin
  --�������� ��������� �������������
  sys.dbms_alert.signal('FINDAY', msg_);
  commit;
end;

procedure set_ver(ver_ in number, type_ in number)
is
begin
if nvl(type_,0) = 1 then
  --���������� ������ ������ ��� �������� ����������� ������������
  update params t set t.wait_ver=ver_;
else
  --���������� ������ ������ ����������� ������� Updater-��
  update params t set t.ver=ver_;
end if;
commit;
end;

procedure del_types
is
begin
  --�������� ���� TYPES, ��� ������������ � �������
  --��� �����, ������ ������������ ����� REP_BILLS
  --���������� ��������� 2 ���� (dependences)
  for c in
  (select * from all_objects t where t.OBJECT_TYPE='TYPE' and t.object_name like 'SYS%' --�� ��� ���� �������))
    and t.OWNER='SCOTT')
  loop
    begin
    execute immediate 'drop type '||c.owner||'.'||c.object_name;
    exception
      when others then
        null;
    end;
  end loop;
end;
end UPDATER;
/

