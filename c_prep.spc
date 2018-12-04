create or replace package scott.c_prep is

  procedure dist_summa;
  procedure dist_summa2;
  --распределить сумму полностью (любой знак), пропорционально, по другим значениям
  function dist_summa_full(p_sum in number, t_summ in out tab_summ)
    return number;
  --распределить сальдо по периодам задолжности (для переноса движения по лиц.счету)
  procedure dist_summa3(p_lsk     in kart.lsk%type, --л.с.
                        p_mg      in params.period%type, --тек.период
                        p_mg_back in params.period%type --период на месяц назад
                        );
end c_prep;
/

