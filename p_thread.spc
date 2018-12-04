create or replace package scott.P_THREAD is
--флаг для триггера, чтобы не было RECURSIVE ERROR
--g_trg_id number;

--создание списков объектов для формирования в потоках
procedure prep_obj(p_var in number);
procedure smpl_chk (p_var in number, p_ret out number);
function smpl_chk (p_var in number) return number;
--чистить инф, там где ВООБЩЕ нет счетчиков (нет записи в c_vvod)
procedure gen_clear_vol;
--распределить объемы по домам с ОДПУ
procedure gen_dist_odpu(p_vv in number);

--переключить режимы при выборе пунктов меню (в триггере)
procedure check_itms(p_itm in number, p_sel in number);


end P_THREAD;
/

