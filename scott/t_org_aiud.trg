CREATE OR REPLACE TRIGGER SCOTT.t_org_aiud
  after insert or update or delete on t_org
declare
cnt_ number;
begin
 -- �� ������� ���, �� ��������� ������ ���� � �������� ����������� (��� ���. ���.04.02.2019)
 --������������� ��������� ����� ���� ��
 if nvl(c_charges.trg_t_org_flag,0)=0 then
 --��������� �������� ��������� �� �������� �����������
   c_charges.trg_t_org_flag:=1;
   begin
      for c in (select t.id from t_org t)
      loop
        update t_org o set o.fk_org2=(select id from (
        select t.id from t_org t
        connect by prior t.parent_id2=t.id
        start with t.id=c.id
        order by level desc
        ) where rownum=1)
        where o.id=c.id;
      end loop;
      --���������� ����� ����, ��� ���������� null � �����.���.
      update t_org o set o.fk_org2=o.id where o.fk_org2 is null
       and o.parent_id2 is null;
   exception
   when others then
     c_charges.trg_t_org_flag:=0;
     --��������� exception
     raise;
   end;
   c_charges.trg_t_org_flag:=0;
 end if;
 null;

end t_org_ai;
/

