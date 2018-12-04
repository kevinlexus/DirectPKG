create or replace type scott.rec_redir as object (
  reu        varchar2(3),
  fk_usl_src char(3),
  fk_usl_dst char(3),
  fk_org_src number,
  fk_org_dst number,
  tp         number
    )
/

