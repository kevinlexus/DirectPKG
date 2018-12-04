create or replace package scott.p_vvod is
  g_tp number;
  procedure gen_dist(p_klsk           in c_vvod.fk_k_lsk%type,
                     p_dist_tp        in c_vvod.dist_tp%type,
                     p_usl            in c_vvod.usl%type,
                     p_use_sch        in out c_vvod.use_sch%type,
                     p_old_use_sch    in c_vvod.use_sch%type,
                     p_kub_nrm_fact   in out c_vvod.kub_nrm_fact%type,
                     p_kub_sch_fact   in out c_vvod.kub_sch_fact%type,
                     p_kub_ar_fact    in out c_vvod.kub_ar_fact%type,
                     p_kub_ar         in out c_vvod.kub_ar%type,
                     p_opl_ar         in out c_vvod.opl_ar%type,
                     p_kub_sch        in out c_vvod.kub_sch%type,
                     p_sch_cnt        in out c_vvod.sch_cnt%type,
                     p_sch_kpr        in out c_vvod.sch_kpr%type,
                     p_kpr            in out c_vvod.kpr%type,
                     p_cnt_lsk        in out c_vvod.cnt_lsk%type,
                     p_kub_norm       in out c_vvod.kub_norm%type,
                     p_kub_fact       in out c_vvod.kub_fact%type,
                     p_kub_man        in out c_vvod.kub_man%type,
                     p_kub            in c_vvod.kub%type,
                     p_edt_norm       in c_vvod.edt_norm%type,
                     p_kub_dist       out c_vvod.kub%type,
                     p_id             in c_vvod.id%type,
                     p_opl_add        in out c_vvod.opl_add%type,
                     p_house_id       in c_vvod.house_id%type,
                     p_old_kub        in c_vvod.kub%type,
                     p_limit_proc     in c_vvod.limit_proc%type,
                     p_old_limit_proc in c_vvod.limit_proc%type,
                     p_gen_part_kpr   in number,
                     p_wo_limit       in c_vvod.wo_limit%type);
  procedure gen_dist_all_houses;
  procedure gen_clear_odn(p_usl      in c_vvod.usl%type,
                          p_usl_chld in c_vvod.usl%type,
                          p_house    in c_houses.id%type,
                          p_vvod     in c_vvod.id%type);
  --распределить ОДН во вводах, где нет ОДПУ
  procedure gen_dist_wo_vvod_usl(p_vvod in c_vvod.id%type);
  --пересчитать ввод (из программы)
  procedure gen_vvod(p_vvod_id in number);
  procedure gen_test_one_vvod(p_cur_dt  in date,
                              p_vvod_id in c_vvod.id%type);
  procedure del_broken_sch_all;
  procedure del_broken_sch(p_usl in usl.usl%type);
  function gen_auto_chrg_all(p_set in number, p_usl in usl.usl%type)
    return number;
  function opl_liter(p_opl_man in number) return number;
  function create_vvod (house_id_ c_houses.id%TYPE, usl_ c_vvod.usl%TYPE,
           num_ c_vvod.vvod_num%TYPE)
           RETURN number;
  function delete_vvod (id_ c_vvod.id%TYPE)
           RETURN number;
  --создать подъезд для klsk дома (для ГИС ЖКХ)
  function create_vvod_by_house_klsk (p_klsk number, p_num c_vvod.vvod_num%TYPE)
           RETURN number;

end p_vvod;
/

