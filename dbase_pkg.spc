create or replace package scott.dbase_pkg
as

    -- procedure to a load a table with records
    -- from a DBASE file.
    --
    -- Uses a BFILE to read binary data and dbms_sql
    -- to dynamically insert into any table you
    -- have insert on.
    --
    -- p_dir is the name of an ORACLE Directory Object
    --       that was created via the CREATE DIRECTORY
    --       command
    --
    -- p_file is the name of a file in that directory
    --        will be the name of the DBASE file
    --
    -- p_tname is the name of the table to load from
    --
    -- p_cnames is an optional list of comma separated
    --          column names.  If not supplied, this pkg
    --          assumes the column names in the DBASE file
    --          are the same as the column names in the
    --          table
    --
    -- p_show boolean that if TRUE will cause us to just
    --        PRINT (and not insert) what we find in the
    --        DBASE files (not the data, just the info
    --        from the dbase headers....)
  function parse_row_txt(txt_ in varchar2, at_ in number, ch in varchar2 default '|')
  return varchar2;

  function get_cnt_to_load(p_org in t_org.id%type) return number;
  --procedure ins_to_kart(p_org in t_org.id%type);
  procedure load_other_file_dbf(p_dir in varchar2,
                      p_file in varchar2);
  procedure load_file_txt_bulk(p_dir in varchar2,
                      p_file in varchar2);
  procedure load_file_txt(p_dir in varchar2,
                      p_file in varchar2);
  procedure load_file_txt2(p_dir in varchar2,
                      p_file in varchar2);
  procedure load_file_dbf(p_dir in varchar2,
                      p_file in varchar2);
  procedure load_file_dbf2(p_dir in varchar2,
                      p_file in varchar2);
  procedure load_db(p_dir in varchar2,
                      isdel_ in number,
                      fname_ in varchar2,
                      tname_ in varchar2);
  --загрузка dbf
  procedure load_db(p_dir in varchar2,
                        isdel_ in number,
                        fname_ in varchar2,
                        tname_ in varchar2,
                        p_is_comm in number --0-без коммита, 1-коммит
                        );
  procedure load_Table( p_dir    in varchar2,
                          p_file   in varchar2,
                          p_tname  in varchar2,
                          p_cnames in varchar2 default NULL,
                          p_show   in BOOLEAN default FALSE);
end;
/

