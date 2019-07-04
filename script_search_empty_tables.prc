create or replace procedure scott.script_search_empty_tables is
  l_cnt number;
  l_cnt2 number;
begin
 dbms_output.enable(1000000);
 
 for c in (select * from all_tables a where owner in ('SCOTT','EXS','BS','ORALV','SEC'))
 loop
   dbms_output.put_line(c.owner||'.'||c.table_name);
   begin
   execute immediate 'select count(*) from '||c.owner||'.'||c.table_name into l_cnt;
   execute immediate 'select count(*) from '||c.owner||'.'||c.table_name||'@ORCL_OLD' into l_cnt2;
   exception when others then
    dbms_output.put_line('???????? Проблемная таблица:'||c.owner||'.'||c.table_name);
   end;
   if l_cnt=0 and l_cnt2>0 then
    dbms_output.put_line('!!!!!!!! Пустая таблица:'||c.owner||'.'||c.table_name);
   end if; 
   if l_cnt <> l_cnt2 then
    dbms_output.put_line('Не идёт кол-во записей:'||c.owner||'.'||c.table_name);
   end if; 
   
 end loop;
end script_search_empty_tables;
/

