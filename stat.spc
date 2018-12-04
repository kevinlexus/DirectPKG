CREATE OR REPLACE PACKAGE SCOTT.stat IS
  TYPE rep_refcursor IS REF CURSOR;
  PROCEDURE rep_stat(reu_           IN VARCHAR2,
                     kul_           IN VARCHAR2,
                     nd_            IN VARCHAR2,
                     trest_         IN VARCHAR2,
                     mg_            IN VARCHAR2,
                     mg1_           IN VARCHAR2,
                     dat_           IN DATE,
                     dat1_          IN DATE,
                     var_           IN NUMBER,
                     det_           IN NUMBER,
                     org_           IN NUMBER,
                     oper_           IN VARCHAR2,
                     сd_            IN VARCHAR2,
                     spk_id_        IN NUMBER,
                     p_house        IN NUMBER,
                     p_out_tp       IN NUMBER,   --тип выгрузки (null- в рефкурсор, 1-в текстовый файл в дир по умолчанию)
                     prep_refcursor IN OUT rep_refcursor);
procedure rep_detail(p_cd in varchar2, p_mg in params.period%type, p_lsk in kart.lsk%type,
                       prep_refcursor in out rep_refcursor);


PROCEDURE SQLTofile(p_sql IN VARCHAR2,
                    p_dir IN VARCHAR2,
                    p_header_file IN VARCHAR2,
                    p_data_file IN VARCHAR2 := NULL,
                    p_dlmt IN Varchar2 :=';' --разделитель, по умолчанию - ';'
                    );

END stat;
/

