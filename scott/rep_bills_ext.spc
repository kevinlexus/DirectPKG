create or replace package scott.rep_bills_ext is
  type ccur is ref cursor;
  tab tab_bill_detail;
  -- детализация счета, перегруженный метод, для старых вызовов
  procedure detail(p_lsk  IN KART.lsk%TYPE, -- лиц.счет
                 p_mg   IN PARAMS.period%type, -- период запроса
                 p_rfcur out ccur);
  -- детализация счета
  procedure detail(p_lsk  IN KART.lsk%TYPE, -- лиц.счет
                 p_mg   IN PARAMS.period%type, -- период запроса
                 p_includeSaldo in number, -- включать ли сальдо в запрос (1-да, 0 - нет)
                 p_rfcur out ccur);

-- обработать запись для счета
function procRow(p_lvl in number, -- текущий уровень
                 p_parent_usl in usl.usl%type, -- код родительской услуги.
                 t_bill_row IN tab_bill_row, -- строки с начислением, сальдо и т.п.
                 p_bill_var IN number,
                 p_house_id IN number,
                 p_tp IN number
                 ) return rec_bill_row;
function getRow(
                 p_usl in usl.usl%type, -- код услуги.
                 t_bill_row IN tab_bill_row -- строки с начислением, сальдо и т.п.
                 ) return rec_bill_row;

-- получить сумму по дочерним записям для счета
/*function getChildRowSum(
                 p_is_sum_vol in number, -- суммировать объем (0-нет,1-да)
                 p_parent_usl in usl.usl%type, -- код родительской услуги.
                 t_bill_row IN tab_bill_row -- строки с начислением, сальдо и т.п.
                 ) return rec_bill_row;
*/
end rep_bills_ext;
/

