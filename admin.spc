CREATE OR REPLACE PACKAGE SCOTT.ADMIN IS
  time_ date;
  procedure fix_base(fix_ in number);
  PROCEDURE sign_reports;
  PROCEDURE disable_logons(param_ IN PARAMS.param%TYPE,
                           mess_  IN PARAMS.message%TYPE);
  PROCEDURE send_message(msg_ IN MESSAGES.text%TYPE);
  procedure analyze_all_tables;
  PROCEDURE ANALYZE(table_ IN sys.all_tables.table_name%TYPE);
  PROCEDURE analyze_db;
  PROCEDURE make_readed_message(id_ IN MESSAGES.id%TYPE);
  PROCEDURE trg_del_var;
  PROCEDURE trg_set_var(id_ IN NUMBER);
  PROCEDURE trg_del_rec;
  procedure test_tables;
  procedure user_add_perm(fk_pasp_org_ in c_users_perm.fk_pasp_org%type,
    fk_reu_ in c_users_perm.fk_reu%type,
    user_id_ in t_user.id%type, fk_perm_tp_ in c_users_perm.fk_perm_tp%type,
    fk_comp_ in c_users_perm.fk_comp%type);
  procedure user_del_perm(fk_pasp_org_ in c_users_perm.fk_pasp_org%type,
    fk_reu_ in c_users_perm.fk_reu%type,
    user_id_ in t_user.id%type, fk_perm_tp_ in c_users_perm.fk_perm_tp%type,
    fk_comp_ in c_users_perm.fk_comp%type);
  procedure set_state_base(var_ in number);
  function get_state_base
   return number;
  procedure set_ver(ver_ in number, type_ in number);
  procedure dsb_constr;
  procedure enb_constr;
  --найти все таблицы, содержащие поле kul, выполнить с ними действие
  procedure replace_kul;
  procedure truncate_partitions;
  --разовая процедура по переносу пени в новую таблицу, сжатую по дням
  --procedure move_to_new_cur_pen;
  
END ADMIN;
/

