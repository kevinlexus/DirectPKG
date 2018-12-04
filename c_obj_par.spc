create or replace package scott.c_obj_par is
 TYPE rep_refcursor IS REF CURSOR;
 function get_num_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in u_list.cd%type) return t_objxpar.n1%type;
 function get_str_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in u_list.cd%type) return t_objxpar.s1%type;
 function set_num_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.n1%type)
   return t_objxpar.id%type;
 function set_str_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.s1%type)
   return t_objxpar.id%type;
 --�������� Str �������� ��������� �� CD
 function get_str_param_by_qry(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2)
   return varchar2;
 --���������� Str �������� ��������� �� CD, ��������� ���������
 function set_str_param_by_qry(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_cd_val in varchar2)
   return t_objxpar.id%type; 
 function set_date_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.d1%type, p_dflt in number) return t_objxpar.id%type;
 function set_md5_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in varchar2) return t_objxpar.id%type;
 function ins_num_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.n1%type,
   p_usl in usl.usl%type,
   p_tp in t_objxpar.tp%type) return t_objxpar.id%type;
--������ (������� � ������ ����������) �������� ��������� Number ���� �� k_lsk.id ���� �� kart.lsk �� ���� p_tp_par
 function ins_num_tp_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.n1%type,
   p_tp_par in varchar2) return t_objxpar.id%type;
 --������ (������� � ������ ����������) �������� ��������� ���� ID ���� �� k_lsk.id ���� �� kart.lsk
 function ins_id_tp_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.fk_val%type,
   p_tp_par in varchar2
   ) return t_objxpar.id%type;
 --�������� ������ �� ID ��������� (�� list)
 procedure get_list_by_id(p_par_id in number, prep_refcursor out rep_refcursor);
end c_obj_par;
/

