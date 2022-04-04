create or replace package scott.rep_lsk is
  type rep_refcursor is ref cursor;
  procedure rep(p_rep_cd in varchar2, --CD отчёта
              p_lsk in kart.lsk%type, --лиц.счет.
              p_mg1 in varchar2, --начало периода
              p_mg2 in varchar2, --окончание периода
              prep_refcursor in out rep_refcursor
              );
end rep_lsk;
/

