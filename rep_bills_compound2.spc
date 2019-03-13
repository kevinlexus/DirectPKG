create or replace package scott.rep_bills_compound2 is
  type ccur is ref cursor;
  tab tab_bill_detail;

procedure main(p_sel_obj in number, -- вариант выборки: 0 - по klsk, 1 - по адресу, 2 - по УК
               p_reu in kart.reu%type, -- код УК
               p_kul in kart.kul%type, -- код улицы
               p_nd in kart.nd%type,   -- № дома
               p_kw in kart.kw%type,   -- № квартиры
               p_lsk in kart.lsk%type, -- лиц.начальный
               p_lsk1 in kart.lsk%type,-- лиц.конечный
               p_firstNum in number, -- начальный номер счета (для печати по УК)
               p_lastNum in number,  -- конечный номер счета
               p_is_closed in number, -- выводить ли закрытый фонд, если есть долг? (0-нет, 1-да)
               p_mg in params.period%type, -- период выборки
               p_sel_uk in varchar2, -- список УК
               p_rfcur out ccur -- исх.рефкурсор
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

end rep_bills_compound2;
/

