CREATE OR REPLACE TRIGGER SCOTT.c_house_bi_e
  before insert on c_houses
  for each row
declare
  l_id number;
begin
  if :new.id is null then
    select c_house_id.nextval into :new.id from dual;
  end if;
  if :new.k_lsk_id is null then
    insert into k_lsk (id, fk_addrtp)
       select k_lsk_id.nextval, u.id
       from u_list u, u_listtp tp
       where
       u.cd='house' and tp.cd='object_type';
    select k_lsk_id.currval into :new.k_lsk_id from dual;
  end if;

  --добавить параметр (пощадь общего имущ дома) по умолчанию для дома
  --если он не существует
  l_id := c_obj_par.set_num_param(p_k_lsk_id => :new.k_lsk_id,
                                     p_lsk => null,
                                     p_cd => 'area_general_property',
                                     p_val => null);
end;
/

