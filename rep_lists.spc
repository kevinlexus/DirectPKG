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
end rep_lists;
/

