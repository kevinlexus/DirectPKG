CREATE OR REPLACE PACKAGE SCOTT.logger IS
  procedure log_act(lsk_ in log_actions.lsk%type,
    text_ in log_actions.text%type,
    fk_type_act_ in log_actions.fk_type_act%type);
  function log_text(fld_ in varchar2, old_ in varchar2, new_  in varchar2) return varchar2;
  PROCEDURE log_(time_ IN DATE, comments_ IN VARCHAR2);
  PROCEDURE log_ext_(time_ IN DATE, comments_ IN scott.log.comments_ext%type);
  procedure log_sec_;
  procedure log_error(p_ip in varchar2, p_errcode in number, p_errmessage in varchar2);
  procedure ins_period_rep(cd_ in reports.cd%type,
   mg_ in period_reports.mg%type, dat_ in period_reports.dat%type,
    signed_in_ in period_reports.signed%type);
  function prep_err return varchar2;
  procedure raiseError(
    error_source varchar2,
    error_message varchar2 default prep_err || sqlerrm,
    error_code number default -20001
  );

END logger;
/

