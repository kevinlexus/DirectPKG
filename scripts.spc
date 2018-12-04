create or replace package scott.scripts is
  procedure swap_payment;
  procedure swap_payment9;
  procedure swap_payment7;
  procedure swap_payment2;
  procedure swap_payment3;
  procedure gen_del_add_partitions;
  procedure new_usl(usl_ in varchar2);
  procedure script_renumber(oldreu_ in kart.reu%type,
                            reu_    in kart.reu%type);
  procedure create_uk(newreu_ in kart.reu%type,
                      nreu_   in varchar2,
                      mg1_    in params.period%type,
                      mg2_    in params.period%type);
  procedure close_uk(newreu_ in kart.reu%type, mg2_ in params.period%type);
  procedure clear_tables;
  procedure saldo_uk_div;
  procedure swap_payment4(reu_ in varchar2, newreu_ in varchar2);
  procedure swap_payment5;
  procedure swap_changes;
  procedure upd_nabor(oldorg_ in number, org_ in number, newreu_ in kart.reu%type);
  procedure go_back_month;
  procedure create_killme;
  procedure swap_oborot;
  procedure ins_vvod;
  procedure create_kart;
  procedure find_table;
  procedure swap_payment8;
  procedure set_sal_mg;
  procedure swap_oborot2;
  procedure swap_oborot3;
  procedure close_sal;
  procedure close_sal2;
  procedure close_sal3;
  procedure swap_sal1;
  procedure swap_sal_MAIN;
  procedure swap_sal_MAIN_BY_LSK;
  procedure create_uk_new_SPECIAL(newreu_ in kart.reu%type);
  procedure swap_sal2;
  procedure swap_sal3;
  procedure swap_sal4;
  --сн€тие сальдо "в никуда"
  procedure swap_sal_TO_NOTHING;
  procedure swap_sal_chpay;
  procedure swap_sal_chpay2;
  procedure swap_sal_chpay3;
  procedure create_uk_new(newreu_ in kart.reu%type,
    lsk_ in kart.lsk%type, -- лиц.счет, если Ќ≈ заполнен - то присоединение к существующему ” 
    p_lsk_tp_src in varchar2, -- ќб€зательно указать, с какого типа счетов перенос!
    p_get_all in number, -- признак какие брать лс (1 - все лс, в т.ч. закрытые, 0-только открытые)
    p_close_src in number, -- закрывать период в лс. источника (mg2='999999') 1-да,0-нет
    p_close_dst in number, -- закрывать период в лс. назначени€ (mg2='999999') 1-да,0-нет
    p_move_resident in number, -- переносить проживающих? 1-да,0-нет
    p_forced_status in number, -- установить новый статус счета (0-открытый, NULL - такой же как был в счете источника)
    p_forced_tp in varchar2, -- установить новый тип счета (NULL-вз€ть из источника, например 'LSK_TP_RSO' - –—ќ)
    p_tp_sal in number, --признак как переносить сальдо 0-не переносить, 2 - переносить и дебет и кредит, 1-только дебет, 3 - только кредит
    p_special_tp in varchar2, -- создать дополнительный лиц.счет в добавок к вновь созданному (NULL- не создавать, 'LSK_TP_ADDIT' - капремонт)
    p_special_reu in varchar2, -- ”  дополнительного лиц.счета
    p_mg_sal in c_change.mgchange%type, -- период сальдо
    p_remove_nabor_usl in varchar2 default null, -- удалить данные услуги (задавать как '033;034;035;' строго!), из справочника наборов Ћ— источника (null - не удал€ть) и перенести в назначение 
    p_mg_pen in c_change.mgchange%type -- период по которому перенести пеню. null - не переносить (обычно мес€ц назад)
  );
  --перенос информации по закрытым лиц.счетам
  procedure transfer_closed_all(p_reu in kart.reu%type,  -- рэу назначени€
                              p_lsk_recommend in kart.lsk%type); -- рекоммендуемый лиц.счет, дл€ начала или Null);
  --перенос информации по закрытому лиц.счету
  procedure transfer_closed_lsk(p_lsk in kart.lsk%type, --лиц счет
                       p_reu in kart.reu%type, --рэу назначени€
                       p_cd in varchar2, --CD
                       p_lsk_recommend in kart.lsk%type -- рекоммендуемый лиц.счет, дл€ начала или Null
                       );
  procedure swap_sal_chpay4;
  --перебросить сальдо с одной группы орг (кредитовое) на другую
  procedure swap_sal_chpay5;
end scripts;
/

