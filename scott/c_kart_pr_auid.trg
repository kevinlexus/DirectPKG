CREATE OR REPLACE TRIGGER SCOTT.c_kart_pr_auid
  after update or insert or delete on c_kart_pr
declare
 id_ number;
begin
  if deleting then
    --каскадное удаление - флаг выключен
    c_charges.trg_c_kart_pr_bd     := 0;
  end if;
  --кол-во проживающих
  for element in 1 .. c_charges.tab_lsk.count loop
    if c_charges.tab_lsk(element) is not null then
      utils.set_kpr(c_charges.tab_lsk(element));
      --установка ФИО квартиросъемщика в карточку - убрал 23.11.21 Теперь пользователь нажимает сам на кнопку "Установить собственника"
      --if nvl(c_charges.chng_relat_id,0) = 1 then
       -- Raise_application_error(-20000, 'test1');
      --   utils.set_krt_adm(c_charges.tab_lsk(element));
      --end if;
    end if;
  end loop;

  --сбрасываем флаг смены квартиросъемщика
  c_charges.chng_relat_id:=0;
end;
/

