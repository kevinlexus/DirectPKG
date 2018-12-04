CREATE OR REPLACE PROCEDURE SCOTT.test IS
begin
  -- получить список всех таблиц с определенными полями
  dbms_output.enable(1000000);     
  for c in (select * from all_objects t where t.OBJECT_TYPE='TABLE' 
      and t.OWNER='SCOTT' order by t.object_name) loop
      
    begin
      execute immediate 'select count(*) from '||c.object_name||' where reu is not null and rownum=-1';
      dbms_output.put_line('alter table '||c.owner||'.'||c.object_name||' modify reu CHAR(3);');
    exception
      when others then 
        null;
    end;    
    begin
      execute immediate 'select count(*) from '||c.object_name||' where forreu is not null and rownum=-1';
      dbms_output.put_line('alter table '||c.owner||'.'||c.object_name||' modify forreu CHAR(3);');
    exception
      when others then 
        null;
    end;    
    
  end loop;

END test;
/

