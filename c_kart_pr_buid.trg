CREATE OR REPLACE TRIGGER SCOTT.c_kart_pr_buid
  before update or delete or insert on c_kart_pr
begin
  c_charges.tab_lsk.delete;
  if inserting then
    --добавление прописанных
    c_charges.tab_c_kart_pr_id.delete;
  elsif deleting then
    --каскадное удаление - флаг включен
    c_charges.trg_c_kart_pr_bd     := 1;
  end if;
end;
/

