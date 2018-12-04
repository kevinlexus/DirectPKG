CREATE OR REPLACE TRIGGER SCOTT.C_LG_DOCS_BD
  before delete on c_lg_docs
declare
begin
  --каскадное удаление
  c_charges.trg_c_lg_docs_bd:=1;

end C_LG_DOCS_BD;
/

