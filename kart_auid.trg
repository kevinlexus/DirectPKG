CREATE OR REPLACE TRIGGER SCOTT.kart_auid
  after update or insert on kart
declare
  lll number;
begin
  --обновить поля по дополнительному лицевому счету, взяв из основного
--    Raise_application_error(-20000, c_charges.trg_klsk_flag);
--    c_charges.trg_klsk_flag:=0;
  if c_charges.trg_tab_klsk.count <>0 and nvl(c_charges.trg_klsk_flag,0)=0 then
  for i in c_charges.trg_tab_klsk.FIRST .. c_charges.trg_tab_klsk.LAST loop --да, да в триггере могут быть дубли лиц.сч.!
--    Raise_application_error(-20000, 1);
--  lll:=nvl(c_charges.trg_tab_klsk(c_charges.trg_tab_klsk.last),-1);
--    begin
   c_charges.trg_klsk_flag:=1;
   for c in (select k.k_fam, k.k_im, k.k_ot, k.status, k.opl, k2.lsk, k.kw, k.nd, k.kul, k.kpr
                from kart k, v_lsk_tp tp, kart k2, v_lsk_tp tp2
               where k.k_lsk_id = c_charges.trg_tab_klsk(i)
                 and k.k_lsk_id = k2.k_lsk_id
                 and k.fk_tp = tp.id
                 and tp.cd = 'LSK_TP_MAIN'
                 and k2.fk_tp = tp2.id
                 and tp2.cd = 'LSK_TP_ADDIT'
                 and k.psch not in (8,9)
                 and k2.psch not in (8,9)
                 ) loop
      --отключить искажение массива и повторные вызовы триггера
      update kart t
         set t.k_fam = c.k_fam, t.k_im = c.k_im, t.k_ot = c.k_ot,
             t.status = c.status, t.opl = c.opl, t.kw=c.kw, t.nd=c.nd, t.kul=c.kul, t.kpr=c.kpr
       where t.lsk = c.lsk;
--       exit; - убрал exit 25.10.2017
--    Raise_application_error(-20000, c.status);
    end loop;
    c_charges.trg_klsk_flag:=0;

/*    exception
      when others then
        Raise_application_error(-20000, 'stop='||i||', count='||c_charges.trg_tab_klsk.count );
    end;*/
  end loop;
  end if;


end;
/

