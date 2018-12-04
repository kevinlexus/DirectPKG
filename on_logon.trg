CREATE OR REPLACE TRIGGER SCOTT.On_Logon after logon on database
begin
 Execute immediate 'alter session set NLS_NUMERIC_CHARACTERS = ". "';
end;
/

