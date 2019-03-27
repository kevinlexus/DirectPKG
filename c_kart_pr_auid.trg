CREATE OR REPLACE TRIGGER SCOTT.c_kart_pr_auid
  after update or insert or delete on c_kart_pr
declare
 id_ number;
begin
  if deleting then
    --каскадное удаление - флаг выключен
    c_charges.trg_c_kart_pr_bd     := 0;
  end if;
/*  убрал льготы 25.03.2019
if inserting and nvl(c_charges.trg_c_kart_pr_flag,0) = 0 then
    for element in 1 .. c_charges.tab_c_kart_pr_id.count loop
    --вставка нового документа по льготе
     insert into c_lg_docs (c_kart_pr_id, main)
      values (c_charges.tab_c_kart_pr_id(element), 0)
      returning
       id into id_;
    --вставка новых льгот по умолчанию
     insert into c_lg_pr (c_lg_docs_id, spk_id, type)
      values (id_, 1, 0);
     insert into c_lg_pr (c_lg_docs_id, spk_id, type)
      values (id_, 1, 1);
    end loop;
  end if;*/

  --кол-во проживающих
  for element in 1 .. c_charges.tab_lsk.count loop
    if c_charges.tab_lsk(element) is not null then
      utils.set_kpr(c_charges.tab_lsk(element));
      --установка ФИО квартиросъемщика в карточку
      if nvl(c_charges.chng_relat_id,0) = 1 then
        --Raise_application_error(-20000, 'test1');
         utils.set_krt_adm(c_charges.tab_lsk(element));
      end if;
    end if;
  end loop;

  --сбрасываем флаг смены квартиросъемщика
  c_charges.chng_relat_id:=0;
end;
/

