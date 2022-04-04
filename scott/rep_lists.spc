create or replace package scott.rep_lists is
  type rep_refcursor is ref cursor;
  procedure report(rep_id_ in number,
                          mg_            in params.period%type,
                          org_ in number,
                          var_ in number,
                          cnt_ in number,
                          proc_ in number,
                          fname_ in varchar2,
                          prep_refcursor in out rep_refcursor);
  procedure report_to_dbf(rep_id_ in number,
                          p_mg            in params.period%type,
                          p_org in number,
                          p_var in number,
                          p_cnt in number,
                          p_proc in number,
                          p_fname in varchar2);
                          
end rep_lists;
/

