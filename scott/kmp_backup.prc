create or replace procedure scott.kmp_backup(p_tname in varchar2) is
begin
  execute immediate 'delete from scott.'||trim(p_tname)||' t where t.mg=''201701''';
  Raise_application_error(-20000, 'insert into scott.'||trim(p_tname)||' select * from loader1.'||trim(p_tname)||' t where t.mg=''201701''');
  execute immediate 'insert into scott.'||trim(p_tname)||' select * from loader1.'||trim(p_tname)||' t where t.mg=''201701''';
  commit;
  dbms_output.put_line(trim(p_tname)||'-успешно');
end kmp_backup;
/

