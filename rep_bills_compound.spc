create or replace package scott.rep_bills_compound is
  type ccur is ref cursor;
  tab tab_bill_detail;

procedure main(p_sel_obj in number, -- вариант выборки: 0 - по klsk, 1 - по адресу, 2 - по УК
               p_reu in kart.reu%type, -- код УК
               p_kul in kart.kul%type, -- код улицы
               p_nd in kart.nd%type,   -- № дома
               p_kw in kart.kw%type,   -- № квартиры
               p_lsk in kart.lsk%type, -- лиц.начальный
               p_lsk1 in kart.lsk%type,-- лиц.конечный
               p_klsk_id   in number default null, -- фин.лиц счет, используется при p_sel_obj=1
               p_firstNum in number, -- начальный номер счета (для печати по УК)
               p_lastNum in number,  -- конечный номер счета
               p_is_closed in number, -- выводить ли закрытый фонд, если есть долг? (0-нет, 1-да)
               p_mg in params.period%type, -- период выборки
               p_sel_uk in varchar2, -- список УК
               p_postcode  in varchar2, -- почтовый индекс (при p_sel_obj=2)
               p_exp_email in number default 0, -- выгрузить для отправки по эл.почте, 0 - нет, 1 - да
               p_rfcur out ccur -- исх.рефкурсор
  );

procedure main_arch(p_sel_obj   in number, -- вариант выборки: 0 - по лиц.счету, 1 - по адресу, 2 - по УК
               p_kul       in kart.kul%type, -- код улицы
               p_nd        in kart.nd%type, -- № дома
               p_kw        in kart.kw%type, -- № квартиры
               p_lsk       in kart.lsk%type, -- лиц.начальный
               p_lsk1      in kart.lsk%type, -- лиц.конечный
               p_is_closed in number, -- выводить ли закрытый фонд, если есть долг? (0-нет, 1-да)
               p_firstNum  in number default null, -- начальный номер счета (для печати по УК) -- убрать после тестирования! ред.28.05.2020
               p_lastNum   in number default null, -- конечный номер счета -- убрать после тестирования! ред.28.05.2020
               p_mg        in params.period%type default null, -- период выборки (для арх.справки-обычно текущий период) -- убрать после тестирования! ред.28.05.2020
               p_sel_uk    in varchar2, -- список УК
               p_rfcur     out ccur -- исх.рефкурсор
               );
procedure contractors(p_klsk in number, -- klsk помещения
                 p_is_closed in number, -- выводить ли закрытый фонд, если есть долг? (0-нет, 1-да)
                 p_mg in params.period%type, -- период выборки
                 p_sel_flt_tp in number, -- дополнительный фильтр
                 p_sel_uk in varchar2, -- список УК
                 p_rfcur out ccur);

procedure getQr(p_klsk in number, -- klsk помещения
                 p_is_closed in number, -- выводить ли закрытый фонд, если есть долг? (0-нет, 1-да)
                 p_mg in params.period%type, -- период выборки
                 p_sel_tp in number, -- 0 - тип лиц.счетов: Основные и РСО, 1 - кап.рем, 3 - вообще все
                 p_sel_flt_tp in number, -- дополнительный фильтр
                 p_sel_uk in varchar2, -- список УК
                 p_rfcur out ccur
  );

procedure detail(p_klsk in number, -- klsk помещения
                 p_is_closed in number, -- выводить ли закрытый фонд, если есть долг? (0-нет, 1-да)
                 p_mg in params.period%type, -- период выборки
                 p_sel_tp in number, -- 0 - тип лиц.счетов: Основные и РСО, 1 - кап.рем
                 p_sel_flt_tp in number, -- дополнительный фильтр
                 p_sel_uk in varchar2, -- список УК
                 p_rfcur out ccur
  );
procedure funds_flow_by_klsk(
                 p_klsk in number, -- klsk помещения
                 p_sel_tp in number, -- 0 - тип лиц.счетов: Основные и РСО, 1 - кап.рем
                 p_sel_flt_tp in number, -- дополнительный фильтр
                 p_is_closed in number, -- выводить ли закрытый фонд, если есть долг? (0-нет, 1-да)
                 p_mg in params.period%type, -- период выборки
                 p_sel_uk in varchar2, -- список УК
                 p_rfcur out ccur
  );
procedure get_chargepay(p_lsk in varchar2, -- лиц.сч.
                 p_mg in params.period%type default '000000', -- основной период
                 p_mg_from in params.period%type default '000000', -- период выборки
                 p_mg_to in params.period%type default '999999', -- период выборки
                 p_rfcur out ccur
  );
  
end rep_bills_compound;
/

