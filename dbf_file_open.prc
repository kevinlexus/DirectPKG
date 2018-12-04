create or replace procedure scott.dbf_file_open
as
file_name bfile;
begin
   file_name:=bfilename('LOAD_FILES','test.dbf');
   dbms_lob.open(file_name);
   dbms_output.put_line('Successful');
end;
/

