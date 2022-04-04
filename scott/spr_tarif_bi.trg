CREATE OR REPLACE TRIGGER SCOTT.spr_tarif_bi
  before insert on spr_tarif
declare
 spr_tarif_id_ number;
begin
 --�������� ��������� ID ��� ������ ������
 select nvl(max(s.id),0) into spr_tarif_id_ from spr_tarif s;
 utils.spr_tarif_id_:=spr_tarif_id_+1;

 --�������� �������� ������� ����������� �������
 select t.id into utils.spr_tarif_root_id_
    from spr_tarif t where
     t.cd='000';
end;
/

