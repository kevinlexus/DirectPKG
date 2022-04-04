CREATE OR REPLACE TRIGGER SCOTT.t_a_logon
  after logon on database
begin
  --логгирование пользователей
  --закомментировано... бывают проблемы у Ёнергии плюс
/*  insert into log
      (id, timestampm, ip, terminal, event_id)
      select uid, sysdate, SYS_CONTEXT('USERENV','IP_ADDRESS'),
       SYS_CONTEXT('USERENV','SESSION_USER'), 1 from dual;
       */

null;
end t_a_logon;
/

