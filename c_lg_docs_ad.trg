CREATE OR REPLACE TRIGGER SCOTT.C_LG_DOCS_AD
  after delete on c_lg_docs
declare
  cnt_ number;
begin
  select nvl(count(*),0) into cnt_ from c_kart_pr p where not exists
  (select * from c_lg_docs c
    where p.id=c.c_kart_pr_id)
    and p.lsk=c_charges.trg_c_lg_docs_bd_lsk;
  if cnt_ > 0 then
    Raise_application_error(-20000, 'Запрещено удалять единственную льготу у проживающего, замените на "Раб/Служ"');
  end if;

  --каскадное удаление, восстановить признак
  c_charges.trg_c_lg_docs_bd:=0;

end C_LG_DOCS_BD;
/

