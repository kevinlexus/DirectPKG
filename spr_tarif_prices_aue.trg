CREATE OR REPLACE TRIGGER SCOTT.spr_tarif_prices_aue
  after update of cena, mg1, mg2 on spr_tarif_prices
  for each row
declare
  period_ params.period%type;
begin
  --�������
  --���������� �������� �� ������
  --��������������, ����� �������� ��� �������� ������������
  --�������� � nabor, ������� ������� ����� 16.11.2010
/*  select period into period_ from params;
  if period_ between :new.mg1 and :new.mg2 then
    update nabor n set n.koeff=:new.cena
      where n.fk_tarif=:old.fk_tarif;
  end if;*/
  null;
end;
/

