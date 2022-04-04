create or replace force view scott.v_doc_nsi_95 as
select t.id,  t.guid, t2.s1 as name
  from EXS.U_LIST t
  join EXS.U_LIST t2
    on t2.parent_id = t.id
 where t2.name = '¬ид документа, удостовер€ющего личность'
 and t.actual=1;

