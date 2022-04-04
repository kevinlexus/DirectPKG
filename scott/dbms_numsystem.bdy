CREATE OR REPLACE PACKAGE BODY SCOTT.dbms_numsystem AS

FUNCTION bin2dec (binval IN CHAR) RETURN NUMBER IS
  i                 NUMBER;
  digits            NUMBER;
  result            NUMBER := 0;
  current_digit     CHAR(1);
  current_digit_dec NUMBER;
BEGIN
  digits := LENGTH(binval);
  FOR i IN 1..digits LOOP
     current_digit := SUBSTR(binval, i, 1);
     current_digit_dec := TO_NUMBER(current_digit);
     result := (result * 2) + current_digit_dec;
  END LOOP;
  RETURN result;
END bin2dec;

FUNCTION dec2bin (N IN NUMBER) RETURN VARCHAR2 IS
  binval VARCHAR2(64);
  N2     NUMBER := N;
BEGIN
  WHILE ( N2 > 0 ) LOOP
     binval := MOD(N2, 2) || binval;
     N2 := TRUNC( N2 / 2 );
  END LOOP;
  RETURN binval;
END dec2bin;

FUNCTION oct2dec (octval IN CHAR) RETURN NUMBER IS
  i                 NUMBER;
  digits            NUMBER;
  result            NUMBER := 0;
  current_digit     CHAR(1);
  current_digit_dec NUMBER;
BEGIN
  digits := LENGTH(octval);
  FOR i IN 1..digits LOOP
     current_digit := SUBSTR(octval, i, 1);
     current_digit_dec := TO_NUMBER(current_digit);
     result := (result * 8) + current_digit_dec;
  END LOOP;
  RETURN result;
END oct2dec;

FUNCTION dec2oct (N IN NUMBER) RETURN VARCHAR2 IS
  octval VARCHAR2(64);
  N2     NUMBER := N;
BEGIN
  WHILE ( N2 > 0 ) LOOP
     octval := MOD(N2, 8) || octval;
     N2 := TRUNC( N2 / 8 );
  END LOOP;
  RETURN octval;
END dec2oct;

FUNCTION hex2dec (hexval IN CHAR) RETURN NUMBER IS
  i                 NUMBER;
  digits            NUMBER;
  result            NUMBER := 0;
  current_digit     CHAR(1);
  current_digit_dec NUMBER;
BEGIN
  digits := LENGTH(hexval);
  FOR i IN 1..digits LOOP
     current_digit := SUBSTR(hexval, i, 1);
     IF current_digit IN ('A','B','C','D','E','F') THEN
        current_digit_dec := ASCII(current_digit) - ASCII('A') + 10;
     ELSE
        current_digit_dec := TO_NUMBER(current_digit);
     END IF;
     result := (result * 16) + current_digit_dec;
  END LOOP;
  RETURN result;
END hex2dec;

FUNCTION dec2hex (N IN NUMBER) RETURN VARCHAR2 IS
  hexval VARCHAR2(64);
  N2     NUMBER := N;
  digit  NUMBER;
  hexdigit  CHAR;
BEGIN
  WHILE ( N2 > 0 ) LOOP
     digit := MOD(N2, 16);
     IF digit > 9 THEN
        hexdigit := CHR(ASCII('A') + digit - 10);
     ELSE
        hexdigit := TO_CHAR(digit);
     END IF;
     hexval := hexdigit || hexval;
     N2 := TRUNC( N2 / 16 );
  END LOOP;
  RETURN hexval;
END dec2hex;

END dbms_numsystem;
/

