CREATE OR REPLACE TRIGGER SCOTT.c_lg_docs_bd_e
  before delete on c_lg_docs
  for each row
begin
  --каскадное удаление
  --сохраняем фио для аудита
  if nvl(c_charges.trg_c_kart_pr_bd,0) = 1 then
     --было каскадное удаление от c_kart_pr
     c_charges.trg_c_lg_docs_bd_fio := c_charges.trg_c_kart_pr_bd_fio;
     c_charges.trg_c_lg_docs_bd_lsk := c_charges.trg_c_kart_pr_bd_lsk;
  else
    for c in (select t.lsk, t.fio from c_kart_pr t where t.id = :old.c_kart_pr_id) loop
      c_charges.trg_c_lg_docs_bd_fio := c.fio;
      c_charges.trg_c_lg_docs_bd_lsk := c.lsk;
      exit;
    end loop;
  end if;

end c_lg_docs_bd_e;
/

