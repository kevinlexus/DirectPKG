create or replace procedure scott.script_set_k_lsk_id is
  id_ number;
begin
 --проставляем k_lsk_id
 delete from k_lsk;
 for c in (select distinct c_lsk_id from kart )
 loop
   insert into k_lsk (id)
     values (k_lsk_id.nextval);
   select k_lsk_id.currval into id_ from dual;
   update kart k set k.k_lsk_id=id_ where k.c_lsk_id=c.c_lsk_id;
 end loop;
 commit;
end script_set_k_lsk_id;
/

