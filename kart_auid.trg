CREATE OR REPLACE TRIGGER SCOTT.kart_auid
  after update or insert on kart
begin
  --�������� ���� �� ��������������� �������� �����, ���� �� ���������
  if c_charges.trg_tab_klsk.count <>0 and nvl(c_charges.trg_klsk_flag,0)=0 then
  for i in c_charges.trg_tab_klsk.FIRST .. c_charges.trg_tab_klsk.LAST loop --��, �� � �������� ����� ���� ����� ���.��.!
   c_charges.trg_klsk_flag:=1;
   for c in (select k.k_fam, k.k_im, k.k_ot, k.status, k.opl, k2.lsk, k.kw, k.nd, k.kul, k.kpr, k.kpr_wr, k.kpr_ot
                from kart k, v_lsk_tp tp, kart k2, v_lsk_tp tp2
               where k.k_lsk_id = c_charges.trg_tab_klsk(i)
                 and k.k_lsk_id = k2.k_lsk_id
                 and k.fk_tp = tp.id
                 and tp.cd = 'LSK_TP_MAIN'
                 and k2.fk_tp = tp2.id
                 and tp2.cd in ('LSK_TP_ADDIT','LSK_TP_RSO')
                 and k.psch not in (8,9)
                 and k2.psch not in (8,9)
                 ) loop
      --��������� ��������� ������� � ��������� ������ ��������
      update kart t
         set t.k_fam = c.k_fam, t.k_im = c.k_im, t.k_ot = c.k_ot,
             t.status = c.status, t.opl = c.opl, t.kw=c.kw, t.nd=c.nd, t.kul=c.kul, 
             t.kpr=c.kpr, t.kpr_wr=c.kpr_wr, t.kpr_ot=c.kpr_ot
       where t.lsk = c.lsk;
    end loop;
    c_charges.trg_klsk_flag:=0;
  end loop;
  end if;


end;
/

