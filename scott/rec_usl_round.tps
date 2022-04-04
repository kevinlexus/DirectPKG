CREATE OR REPLACE TYPE SCOTT."REC_USL_ROUND"
  as object (
    -- код услуги
    usl char(3),
    -- расценка для суммирования (если свыше соцнормы - не указывать)
    price number,
    -- сумма
    summa number
  )
/

