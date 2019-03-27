create or replace package scott.p_meter is
  g_flag number;
  -- тип записи - klsk объекта на котором работает счетчик
  type trg_obj is record(
    klsk     number, -- klsk счетчика
    klsk_obj number, -- klsk объекта
    fk_usl   varchar2(3), -- услуга счетчика
    n1       number, -- новые показания
    isChng   number -- изменены показания (1-да, 0-нет)
    );

  -- запись объекта
  trg_rec_obj trg_obj;
  -- тип таблицы записей
  type tab_rec_obj is table of trg_rec_obj%type;
  -- таблица
  tb_rec_obj tab_rec_obj := tab_rec_obj(null);

  function ins_meter(p_npp         in number,
                     p_usl         in usl.usl%type,
                     p_dt1         in date,
                     p_dt2         in date,
                     p_n1          in number,
                     p_fk_klsk_obj in number,
                     p_tp          in u_list.cd%type) return number;
  function ins_vol_meter(p_met_klsk in number, -- klsk счетчика --либо klsk счетчика
                         p_lsk      in kart.lsk%type, --лиц.счет     --либо лиц.счет + услуга!
                         p_usl      in usl.usl%type, --услуга
                         p_vol      in number, -- объем
                         p_n1       in number, -- НЕ используется!
                         p_tp       in number default 0 -- тип (0-ручной ввод, 1-автоначисление, 2-отмена начисления (здесь не должно использ)
                         ) return number;
  procedure ins_data_meter(p_met_klsk in number, -- klsk счетчика --либо klsk счетчика
                           p_n1       in number, -- новое показание
                           p_ts       in date, -- timestamp
                           p_period   in varchar2,
                           p_ret      out number);
  function getpsch(p_lsk in kart.lsk%type) return number;
  function getElpsch(p_lsk in kart.lsk%type) return number;
  function gen_auto_chrg_all(p_set in number, p_usl in usl.usl%type)
    return number;
  procedure del_broken_meter(p_usl in varchar2);
  procedure imp_all_meter;
  procedure imp_states_meter(p_lsk      in varchar2,
                             p_klsk_met in number,
                             p_usl      in varchar2);
  procedure imp_lsk_meter(p_lsk    in kart.lsk%type,
                          p_usl_hw in varchar2,
                          p_usl_gw in varchar2,
                          p_usl_el in varchar2,
                          p_usl_ot in varchar2);
  procedure imp_arch_meter(p_lsk      in kart.lsk%type, -- лс
                           p_met_klsk in number, -- klsk счетчика
                           p_mg       in params.period%type, -- начать с периода
                           p_counter  in varchar2 -- код счетчика
                           );
  procedure test1;

end p_meter;
/

