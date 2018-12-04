CREATE OR REPLACE PACKAGE BODY SCOTT.logger IS

procedure log_act(lsk_ in log_actions.lsk%type,
  text_ in log_actions.text%type,
  fk_type_act_ in log_actions.fk_type_act%type) is
begin
--Аудит пользовательских действий
if lsk_ is not null and nvl(c_charges.debug_flag_,0)=0 then
  insert into log_actions (text, ts, fk_user_id, lsk, fk_type_act)
    values (text_, sysdate,
      (select t.id from t_user t where t.cd=user), lsk_, fk_type_act_);
end if;
end log_act;


function log_text(fld_ in varchar2, old_ in varchar2, new_  in varchar2) return varchar2 is
  Result varchar2(500);
begin
  Result:=' '||fld_||' '||old_||''||'-->'||new_;
  return(Result);
end log_text;


  PROCEDURE log_(time_ IN DATE, comments_ IN VARCHAR2) IS
    PRAGMA autonomous_transaction;
  BEGIN
    IF time_ IS NULL THEN
      INSERT INTO LOG
        (id, timestampm, timem, comments)
        SELECT UID, SYSDATE, ROUND((0) * 24 * 60, 2), substr(comments_,1,1000) FROM dual;
    ELSE
      INSERT INTO LOG
        (id, timestampm, timem, comments)
        SELECT UID,
               SYSDATE,
               ROUND((SYSDATE - time_) * 24 * 60, 2),
               comments_
          FROM dual;
    END IF;
    COMMIT;
  END log_;

  PROCEDURE log_ext_(time_ IN DATE, comments_ IN scott.log.comments_ext%type) IS
    PRAGMA autonomous_transaction;
  BEGIN
    IF time_ IS NULL THEN
      INSERT INTO LOG
        (id, timestampm, timem, comments_ext)
        SELECT UID, SYSDATE, ROUND((0) * 24 * 60, 2), substr(comments_,1,1000) FROM dual;
    ELSE
      INSERT INTO LOG
        (id, timestampm, timem, comments_ext)
        SELECT UID,
               SYSDATE,
               ROUND((SYSDATE - time_) * 24 * 60, 2),
               comments_
          FROM dual;
    END IF;
    COMMIT;
  END log_ext_;

  procedure log_sec_ is
    pragma autonomous_transaction;
  begin
    insert into log
      (id, timestampm, ip, terminal, event_id)
      select uid, sysdate, SYS_CONTEXT('USERENV','IP_ADDRESS'),
       SYS_CONTEXT('USERENV','SESSION_USER'), 1 from dual;
    commit;
  end log_sec_;

procedure ins_period_rep(cd_ in reports.cd%type,
   mg_ in period_reports.mg%type, dat_ in period_reports.dat%type,
    signed_in_ in period_reports.signed%type) is
signed_ number;
begin
  select nvl(auto_sign,0) into signed_ from params;
  if signed_ <> 0 then
    signed_:=1;
  else
    signed_:=signed_in_;
  end if;
  --фиксация новых периодов по отчету
  if mg_ is not null then
    delete from period_reports p
     where exists (select * from reports t where t.id=p.id and t.cd=cd_)
       and p.mg = mg_;
    insert into period_reports (id, mg, signed)
    select t.id, mg_, signed_ from reports t where t.cd=cd_;
  elsif dat_ is not null then
    delete from period_reports p
     where exists (select * from reports t where t.id=p.id and t.cd=cd_)
       and p.dat = dat_;
    insert into period_reports (id, dat, signed)
    select t.id, dat_, signed_ from reports t where t.cd=cd_;
  else
  --по умолчанию, если не указан ни один период, фиксируем текущий период
    delete from period_reports p
     where exists (select * from reports t where t.id=p.id and t.cd=cd_)
       and p.mg = (select p.period from params p);
    insert into period_reports (id, mg, signed)
    select t.id, p.period, signed_ from reports t, params p where t.cd=cd_;
  end if;
  commit;
end ins_period_rep;

function prep_err return varchar2
is
  l_back_trace varchar2(4096) default DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
  l_pos integer;
begin
  if substr(l_back_trace, length(l_back_trace), 1) = chr(10)
  then
    l_back_trace := substr(l_back_trace, 1, length(l_back_trace)-1);
  end if;
  l_pos := instr(l_back_trace, chr(10), -1);
  if l_pos > 0 then
    l_back_trace := substr(l_back_trace, l_pos+1);
  end if;
  return l_back_trace || chr(10);
end prep_err;

procedure raiseError(
  error_source varchar2,
  error_message varchar2 default prep_err || sqlerrm,
  error_code number default -20001
)
is
begin
  if not error_source is null then
    raise_application_error(
      error_code, 'error in ' || error_source || chr(10) || error_message);
  else
    raise_application_error(
      error_code, error_message);
  end if;
end RaiseError;

END logger;
/

