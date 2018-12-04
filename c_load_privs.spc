create or replace package scott.c_load_privs is
  type rep_refcursor is ref cursor;
  --очистить подготовительные справочники
  procedure clear_spr;
  --очистить подготовительные таблицы
  procedure clear_tabs;
  --добавить строку с наименованием файла, обновить залитые строки
  procedure add_file(p_name in prep_file.name%type);
  --подоговить таблицу соответствий улиц
  procedure prep_street;
  --подоговить таблицу соответствий домов 
  procedure prep_house;

  --подготовка таблицы к выгрузке
  procedure prep_output(p_mg in params.period%type, p_file in number, p_cnt out number);
  --рефкурсор для выгрузки
  procedure rep(p_file in number, prep_refcursor in out rep_refcursor);
  
end c_load_privs;
/

