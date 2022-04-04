create or replace package scott.P_THREAD is
  TYPE rep_refcursor IS REF CURSOR;

  procedure prep_obj(p_var in number);
  procedure gen_clear_vol;
  procedure gen_dist_odpu(p_vv in number);
  procedure check_itms(p_itm in number, p_sel in number);
  procedure extended_chk(p_var          in number,
                         prep_refcursor IN OUT rep_refcursor);

end P_THREAD;
/

