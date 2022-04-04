create or replace package scott.C_KART is
--  procedure set_part_kpr_old(l_lsk in kart.lsk%type);
 /* procedure set_part_kpr_all(p_kart_pr in c_kart_pr.id%type);
  procedure set_part_kpr_all_lsk;
  procedure set_part_kpr_house(p_house_id in c_houses.id%type);
*/
  procedure set_part_kpr_vvod(p_vvod in c_vvod.id%type);
/*  procedure set_part_kpr(p_lsk in kart.lsk%type, --лицевой
                         p_tp in u_list.cd%type --тип лицевого, для расчета капремонта в доп.счетах (для подстановки проживающих из основного
                         );*/
  procedure set_part_kpr(p_lsk in kart.lsk%type, p_usl in usl.usl%type,
                       p_set_utl_kpr in number,
                       p_tp in u_list.cd%type --тип лицевого, для расчета капремонта в доп.счетах (для подстановки проживающих из основного
                       );
  procedure get_days(
     p_usl in usl.usl%type,
     p_usl_type2 in usl.usl_type2%type,
     p_days in out number,
     p_days_wrz in out number, p_days_wro in out number,
     p_days_kpr2 in out number,
     p_prop in c_states_pr.fk_status%type,
     p_prop_reg in c_states_pr.fk_status%type,
   p_var_cnt_kpr in number);
  function get_is_sch (
    p_fk_calc in usl.fk_calc_tp%type,
    p_psch in kart.psch%type, p_sch_el in kart.sch_el%type) return number;
  function get_is_chrg(p_sptarn in usl.sptarn%type,
      p_koeff in nabor.koeff%type, p_norm in nabor.norm%type) return number;

  --установить параметры квартиры (в основном для ГИС ЖКХ)
  function set_kw_par(p_house_guid in varchar2, p_kw in varchar2, p_entr in number) return number;
  --установить единый лиц.счет
  function set_elsk (p_lsk in kart.lsk%type, p_elsk in varchar2) return number;
  function find_correct (p_lsk in kart.lsk%type -- лиц.счет по которому искать
           ) return kart.lsk%type;
  function replace_klsk (p_lsk in kart.lsk%type, -- лиц.счет по которому искать
                       p_klsk_dst in number   -- klsk на который заменить
                       ) return number;
  function replace_house_id (p_lsk in kart.lsk%type, -- лиц.счет по которому искать
                       p_house_dst in number   -- house_id на который заменить
                       ) return number;

end C_KART;
/

