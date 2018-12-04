CREATE OR REPLACE TYPE SCOTT."REC_BILL_DETAIL" as object
(
  is_amnt_sum      number,  -- суммировать в итог в fastreport
  usl         CHAR(3), -- код услуги
  npp           NUMBER, -- № п.п.
  name         VARCHAR2(100), -- наименование
  price        NUMBER, -- цена
  vol          NUMBER, -- объем
  charge       NUMBER, -- начисление
  change1      NUMBER, -- перерасчет
  change_proc1 NUMBER, -- % по перерасчету
  change2      NUMBER, -- перерасчет
  amnt         NUMBER, -- итого
  deb          NUMBER, -- сальдо(задолженность)
  bill_col     number, -- в какой колонке выводить сумму (смотреть usl.bill_col)
  bill_col2    number, -- отнести объем к Доп.инф. (смотреть usl.bill_col2)
  kub          number  -- объем ОДПУ
  )
/

