CREATE OR REPLACE TRIGGER SCOTT.spk_bi
  before insert on spk
declare
 spk_id_ number;
begin
--�������� � ����� ��������� ������ ����� � ���-����.
 select nvl(max(s.id),0) into spk_id_ from spk s;
 utils.spk_id_:=spk_id_+1;
end;
/

