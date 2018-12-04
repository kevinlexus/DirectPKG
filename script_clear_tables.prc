create or replace procedure scott.script_clear_tables is
begin
-- RAISE_APPLICATION_ERROR(-20001,
-- 'Запрещено запускать скрипт, без корректировки');

 for c in (select * from all_tables a where owner='SCOTT')
 loop
 begin
   execute immediate 'delete from '||c.table_name||' where mg < ''200811''';
 commit;
 EXCEPTION
  WHEN OTHERS THEN
  null;
 end;
 end loop;

 commit;
end script_clear_tables;
/

