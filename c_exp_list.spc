CREATE OR REPLACE PACKAGE SCOTT.C_EXP_LIST IS
  time_ DATE;
  PROCEDURE privs_export;
  PROCEDURE changes_export;
  PROCEDURE charges_export;
END C_EXP_LIST;
/

