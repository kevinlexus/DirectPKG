CREATE OR REPLACE TRIGGER SCOTT.c_lg_docs_biu_e
  before update or insert on c_lg_docs
  for each row
declare
  aud_text_ log_actions.text%type;
  fio_ c_kart_pr.fio%type;
begin
  aud_text_:='';
  if inserting then
    if :new.id is null then
      select scott.c_lg_docs_id.nextval into :new.id from dual;
    end if;

  elsif updating then
    if (:new.dat_begin <> :old.dat_begin) or (:new.dat_begin is not null and :old.dat_begin is null)
       or (:new.dat_begin is null and :old.dat_begin is not null) then
      select p.fio into fio_ from c_kart_pr p where
       p.id=:old.c_kart_pr_id;
      aud_text_:='Обновлены данные по документу льготы проживающего: '||trim(fio_)||', '
      ||logger.log_text('Дата начала', to_char(:old.dat_begin,'DD/MM/YYYY'), to_char(:new.dat_begin,'DD/MM/YYYY'));
    end if;
  end if;
end c_lg_docs_biu_e;
/

