create or replace package scott.scripts is
  TYPE type_saldo_usl IS table of saldo_usl%rowtype;
  t_tab_corr type_saldo_usl;
  procedure swap_sal_MAIN_BY_LSK;
  procedure swap_sal_TO_NOTHING;
  procedure CREATE_UK_NEW2(p_reu_dst          in kart.reu%type, -- код УК назначения (вместо бывшего new_reu_), если не заполнен, то возьмется из лиц.счета источника
                           p_reu_src          in varchar2, -- код УК источника (если не заполнено, то любое) Заполняется если переносятся ЛС из РСО в другую РСО
                           p_lsk_tp_src       in varchar2, -- С какого типа счетов перенос, если не указано - будет взято по наличию p_remove_nabor_usl
                           p_house_src        in varchar2, -- House_id через запятую, например '3256,5656,7778,'
                           p_get_all          in number, -- признак какие брать лс (1 - все лс, в т.ч. закрытые, 0-только открытые)
                           p_close_src        in number, -- закрывать лс. источника (mg2='999999') 1-да,0-нет,2-закрывать только если не ОСНОВНОЙ счет
                           p_close_dst        in number, -- закрывать лс. назначения (mg2='999999') 1-да,0-нет
                           p_move_resident    in number, -- переносить проживающих? 1-да,0-нет
                           p_forced_status    in number, -- установить новый статус счета (0-открытый, NULL - такой же как был в счете источника)
                           p_forced_tp        in varchar2, -- установить новый тип счета (NULL-взять из источника, например 'LSK_TP_RSO' - РСО)
                           p_tp_sal           in number, --признак как переносить сальдо 0-не переносить, 2 - переносить и дебет и кредит, 1-только дебет, 3 - только кредит
                           p_special_tp       in varchar2, -- создать дополнительный лиц.счет в добавок к вновь созданному (NULL- не создавать, 'LSK_TP_ADDIT' - капремонт)
                           p_special_reu      in varchar2, -- УК дополнительного лиц.счета
                           p_mg_sal           in c_change.mgchange%type, -- период сальдо
                           p_remove_nabor_usl in varchar2 default null, -- переместить данные услуги (задавать как 033,034,035)
                           p_create_nabor_usl in varchar2 default null, -- создать данные услуги (задавать как 033,034,035) не использовать совместно с p_remove_nabor_usl!
                           p_forced_usl       in varchar2 default null, -- установить данную услугу в назначении (если не указано, взять из источника)
                           p_forced_org       in number default null, -- установить организацию в наборе назначения (null - брать из источника)
                           p_mg_pen           in c_change.mgchange%type, -- период по которому перенести пеню. null - не переносить (обычно месяц назад)
                           p_move_meter       in number default 0,-- перемещать показания счетчиков (Обычно Полыс) 1-да,0-нет - при перемещении на РСО - не надо включать
                           p_cpn              in number default 0-- начислять пеню в новых лиц счетах? (0, null, -да, 1 - нет)
                           );
  procedure sub_ZERO_kis;
  procedure swap_sal_PEN(
     p_reu_src          in varchar2, -- код УК источника
     p_usl_src in varchar2, -- переместить с данной услуги
     p_usl_dst in varchar2, -- код услуги назначения
     p_org_src in number, -- орг источника
     p_org_dst in number -- орг назначения
  );  
  procedure swap_sal_PEN2;
  procedure swap_sal_and_pen;
  procedure swap_sal_PEN3;
  procedure swap_sal_from_main_to_rso;
  procedure swap_sal_from_main_to_rso2;
  procedure swap_sal_chpay13;
  procedure move_sal_pen_main_to_rso;
  
  procedure dist_saldo_polis;
  procedure dist_saldo_PEN_polis;
  procedure swap_chrg_pay_by_one_org;
end scripts;
/

