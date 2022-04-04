CREATE OR REPLACE PACKAGE EXS.P_GIS IS
type ccur is ref cursor;
  
function get_root_eolink(p_id in number, -- Id ������������� ��������
                         p_tp in varchar2 -- ��� �������� ��������
                         ) return number;
  

function insert_pd_by_house(p_eol_house in number, -- Id ���� � Eolink
                            p_reu in varchar2,      -- ��� �� (���) ���� �� ��������� - �� ����� �������� ��� �����        
                            p_eol_uk in number -- Id �� � Eolink
                              ) return number;
function insert_pd_by_uk(p_eol_uk in number -- Id uk � Eolink
                              ) return number;
function insert_pd_by_rso(p_eol_uk in number -- Id ��� � Eolink
                              ) return number;
function withdraw_pd_by_uk(p_eol_uk in number -- Id uk � Eolink
                              ) return number;
function withdraw_pd_by_house(p_eol_house in number, -- Id ���� � Eolink
                              p_eol_uk in number -- Id �� � Eolink
                              ) return number;
procedure annulment_notif(
         p_kwtp_id in number, -- Id �������
         p_ret out number -- ���������
         );
procedure annulment_arch_notif(
         p_kwtp_id in number, -- Id �������
         p_ret out number -- ���������
         );
function activate_task_by_rkc(p_eol_rkc in number, -- ID ���
                         p_act_cd in varchar2
                         ) return number;
function activate_task_by_uk(
                         p_act_cd in varchar2,
                         p_proc_uk in number -- ���������� ��
                         ) return number;
function activate_task_by_house(
                                 p_eol_house in number, -- Id ���� � Eolink
                                 p_act_cd in varchar2,
                                 p_proc_uk in number -- ���������� ��
                                 ) return number;
procedure get_errs_menu(p_rfcur out ccur);
procedure show_errs(p_id in number, p_period in varchar2, p_rfcur out ccur);
function change_reu_by_house(p_eol_house in number, -- Id ���� � Eolink
                             p_reu in exs.eolink.reu%type               
                             ) return number;

END P_GIS;
/

