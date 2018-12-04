create or replace procedure scott.script_make_tree_obj is
  maxid_ number;
begin
 delete from tree_objects;

--муп
 insert into tree_objects (id, obj_level)
  values (0, 0);

--трест
 insert into tree_objects (main_id, id, obj_level, trest)
   select 0, rownum as rn, 1, trest from
     (select distinct trest from s_reu_trest);

 select max(id) into maxid_
   from tree_objects t where t.obj_level=1;

--рэу
 insert into tree_objects (main_id, id, obj_level, reu)
   select main_id, maxid_+rownum as rn, 2, reu from
     (select distinct s.reu, t.id as main_id
       from s_reu_trest s, tree_objects t
       where s.trest=t.trest and t.obj_level=1);
 select max(id) into maxid_
   from tree_objects t where t.obj_level=2;

--дома
 insert into tree_objects (main_id, id, obj_level, reu, kul, nd)
   select main_id, maxid_+rownum as rn, 3, reu, kul, nd from
   (select distinct k.reu, k.kul, s.name, k.nd, t.id as main_id
     from kart k, tree_objects t, spul s
      where k.reu=t.reu and k.kul=s.id and t.obj_level=2
      ) a
      order by a.reu, a.name, a.nd;

commit;
end script_make_tree_obj;
/

