CREATE OR REPLACE TRIGGER SCOTT.c_change_buid_e
  before insert or update or delete on c_change
  for each row
declare
 txt_ log_actions.text%type;
begin
 if nvl(c_charges.trg_proc_next_month,0)=0 then
   --���� �� ������� ������
   if inserting or updating then
      null;
   elsif deleting then
      select trim(nm) into txt_ from usl u where u.usl=:old.usl;
      logger.log_act(:old.lsk, '������ ���������� �� ������: '||trim(txt_)||
       ' �� '||to_char(:old.dtek,'DD.MM.YYYY')||' ��� � '||to_char(:old.doc_id), 2);

   end if;
 end if;
end;
/

