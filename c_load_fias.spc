create or replace package scott.c_load_fias is
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
end c_load_fias;
/

