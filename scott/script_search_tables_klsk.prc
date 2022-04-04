create or replace procedure scott.script_search_tables_klsk is
  l_cnt number;
  l_cnt2 number;
  l_klsk number;
begin
 -- поиск klsk во всех таблицах
 dbms_output.enable(1000000);
 l_klsk:=0;
 for c in (select * from all_tables a where owner in ('SCOTT','EXS','BS','ORALV','SEC'))
 loop
   l_cnt2:=0;
   begin
     execute immediate 'select count(*) from '||c.owner||'.'||c.table_name||' where k_lsk_id='||l_klsk into l_cnt;
    l_cnt2:=1;
   exception when others then
     null;
   end;
   begin
     execute immediate 'select count(*) from '||c.owner||'.'||c.table_name||' where fk_klsk_obj='||l_klsk into l_cnt;
    l_cnt2:=l_cnt2+1;
   exception when others then
     null;
   end;
   begin
     execute immediate 'select count(*) from '||c.owner||'.'||c.table_name||' where fk_klsk='||l_klsk into l_cnt;
    l_cnt2:=l_cnt2+1;
   exception when others then
     null;
   end;
   begin
     execute immediate 'select count(*) from '||c.owner||'.'||c.table_name||' where fk_k_lsk='||l_klsk into l_cnt;
    l_cnt2:=l_cnt2+1;
   exception when others then
     null;
   end;
   if l_cnt2>0 then
     dbms_output.put_line(c.owner||'.'||c.table_name);
   end if;
 end loop;
end script_search_tables_klsk;
/

