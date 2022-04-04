CREATE OR REPLACE TRIGGER SCOTT.c_vvod_bi_e
  before insert on c_vvod for each row
declare
begin
  if :new.id is null then
        select scott.c_vvod_id.nextval into :new.id from dual;
  end if;
  if :new.dist_tp is null then
    --по умолчанию сделать тип распределения - по площади
    :new.dist_tp:=1;
  end if;

  --установить klsk
  if :new.fk_k_lsk is null then
    insert into k_lsk (id, fk_addrtp)
       select k_lsk_id.nextval, u.id
       from u_list u, u_listtp tp
       where
       u.cd='vvod' and tp.cd='object_type';
    select k_lsk_id.currval into :new.fk_k_lsk from dual;
  end if;

end;
/

