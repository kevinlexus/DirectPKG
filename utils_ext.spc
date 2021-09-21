create or replace package scott.utils_ext is


function get_short_fio(p_fam in varchar2, p_im in varchar2, p_ot in varchar2) return varchar2;
function get_main_reu(p_lsk in kart.lsk%type) return kart.reu%type;
function get_type_of_kart(p_lsk in kart.lsk%type) return number;

end utils_ext;
/

