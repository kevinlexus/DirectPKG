CREATE OR REPLACE PACKAGE SCOTT.P_HOUSES IS
  --���������� ����������, ������ ���� ���.������, � �������� ��������
  --0- � ���������, 1 - � ���������������, 2-�� �����
  g_sel_lsk_tp number;


  FUNCTION create_house(reu_ IN kart.reu%TYPE, kul_ IN c_houses.kul%TYPE, nd_ IN c_houses.nd%TYPE) RETURN NUMBER;

  PROCEDURE house_add_usl(
   p_lvl in number,
   lsk_ in kart.lsk%TYPE,
   house_id_ in c_houses.id%TYPE,
   p_reu in kart.reu%TYPE,
   p_trest in kart.reu%TYPE,
   usl_ in nabor.usl%TYPE,
   org_ in nabor.org%TYPE,
   koeff_ in number,
   norm_ in number,
   p_chrg in number,
   p_dt1    IN DATE,
   p_dt2     IN DATE
   );

 PROCEDURE house_chng_usl(
   p_lvl in number,
   house_id_ in c_houses.id%TYPE,
   p_reu in kart.reu%TYPE,
   p_trest in kart.reu%TYPE,
   usl_ in nabor.usl%TYPE,
   old_org_ in nabor.org%TYPE,
   new_org_ in nabor.org%TYPE,
   old_koeff_ in number,
   old_norm_ in number,
   new_koeff_ in number,
   new_norm_ in number,
   p_chrg in number,
   p_dt1_old    IN DATE,
   p_dt2_old     IN DATE,
   p_dt1    IN DATE,
   p_dt2     IN DATE
   );

 PROCEDURE house_del_usl(
   p_lvl     IN NUMBER,
  lsk_      IN kart.lsk%TYPE,
  house_id_ IN c_houses.id%TYPE,
  p_reu      IN kart.reu%TYPE,
  p_trest    IN kart.reu%TYPE,
  usl_      IN nabor.usl%TYPE,
  org_      IN nabor.org%TYPE,
  koeff_    IN NUMBER,
  norm_     IN NUMBER,
  p_chrg in number,
   p_dt1    IN DATE,
   p_dt2     IN DATE
   );

  PROCEDURE change_house_status(house_id_   IN c_houses.id%TYPE,
                                status_     IN kart.status%TYPE,
                                old_status_ IN kart.status%TYPE);

  PROCEDURE change_house_vvod(house_id_    IN c_houses.id%TYPE,
                              usl_         IN nabor.usl%TYPE,
                              fk_vvod_new_ IN nabor.fk_vvod%TYPE,
                              fk_vvod_old_ IN nabor.fk_vvod%TYPE);

  FUNCTION change_tarif(tsource_ IN NUMBER, tdest_ IN NUMBER) RETURN NUMBER;
  FUNCTION change_prog_tarif(id_            IN spr_tarif.id%TYPE,
                             parent_id_     IN spr_tarifxprogs.fk_tarif%TYPE,
                             old_parent_id_ IN spr_tarifxprogs.fk_tarif%TYPE) RETURN NUMBER;
  FUNCTION copy_prog_tarif(id_ IN spr_tarif.id%TYPE, parent_id_ IN spr_tarifxprogs.fk_tarif%TYPE) RETURN NUMBER;
  FUNCTION del_prog_tarif(id_ IN spr_tarif.id%TYPE, parent_id_ IN spr_tarifxprogs.fk_tarif%TYPE) RETURN NUMBER;
  PROCEDURE add_house_list(p_err      OUT VARCHAR2, p_fk_house IN t_housexlist.fk_house%TYPE,
                           p_fk_list  IN t_housexlist.fk_list%TYPE);
  PROCEDURE del_house_list(p_id IN t_housexlist.id%TYPE);
  FUNCTION add_prog(lsk_      IN nabor_progs.lsk%TYPE,
                    fk_tarif_ IN nabor_progs.fk_tarif%TYPE,
                    usl_      IN nabor_progs.usl%TYPE,
                    id_dvb_   IN NUMBER) RETURN NUMBER;
  FUNCTION del_prog(lsk_ IN nabor_progs.lsk%TYPE, id_ IN nabor_progs.fk_tarif%TYPE) RETURN NUMBER;
  FUNCTION del_prog(lsk_ IN nabor_progs.lsk%TYPE) RETURN NUMBER;

  FUNCTION ins_unq_k_lsk(p_addr_tp_cd in varchar2, p_search_holes in number) RETURN number;
  FUNCTION find_unq_lsk(p_reu IN kart.reu%type,
                        p_lsk in kart.lsk%type --��������������� ���.��.
                        )
  RETURN VARCHAR2;
  function kart_lsk_special_add_house(
         p_house in kart.house_id%type, -- Id ����
         p_lsk_tp in varchar2, -- ��� ������ ��
         p_forced_status in number, -- ������������� ���������� ������ (null - �� �������������, 0-�������� � �.�.)
         p_del_usl_from_dst in number, -- ������� ������ �� nabor ��������� (1-�������,0-���)
         p_reu in varchar2 -- ���� ������, ��������� ������ ��� ��, ���� ���, �������� �� ���������
         ) return number;
function kart_lsk_group_add(p_lsk_src in kart.lsk%type,-- �� ���������
         p_lsk_tp in varchar2, -- ��� ������ �� (��������, ��� � �.�.)
         p_lsk_new in kart.lsk%type, -- ���� null, ���� ������ ����� ��
         p_get_usl_from_src in number, -- ����������� ������ �� nabor ��������� (1-��,0-���)
         p_del_usl_from_src in number, -- ������� ������ �� nabor ��������� (1-��,0-���) (��� �������� ���. �� ������.)
         p_kw in varchar2, -- � ��������
         p_reu in varchar2, -- ���� ������, ��������� ������ ��� ��
         p_close_src in number, -- ������� ������� ��������? (1-��, 0-���)
         p_var in number -- 1- ����� ���.���.���� (������ KLSK, ��� �� KLSK_PREMISE)
                          -- 2- ����� ��������� (������ KLSK, ������ KLSK_PREMISE)
         ) return number;
  procedure kart_lsk_add(
           p_lsk_tp in varchar2, -- ��� ������ �� (��������, ��� � �.�.)
           p_lsk_src in kart.lsk%type default null, -- �� ���������, ��� ����������� ���.�����
           p_lsk_new in out kart.lsk%type, -- ���� null, ���� ������ ����� ��
           p_var in number, -- 0- ����� ���.���� ���� �� ������������, ���� �� ��������� (��� �� KLSK, ��� �� KLSK_PREMISE),
                            -- 1- ����� ���.���.���� (������ KLSK, ��� �� KLSK_PREMISE)
                            -- 2- ����� ��������� � ��� �� ���� (������ KLSK, ������ KLSK_PREMISE) (����������� ��� � ���������� � p_lsk_src)
                            -- 3- ����� ��������� � ������ ���� (������ KLSK, ������ KLSK_PREMISE)
           p_kw in varchar2, -- � ��������
           p_reu in varchar2, -- ���� ������, ��������� ������ ��� ��
           p_house number,-- Id ����
           p_klsk_dst in number, -- klsk ���.���.�����
           p_klsk_premise_dst in number, -- klsk ���������
           p_fam in varchar2, -- �������
           p_im in varchar2,  -- ���
           p_ot in varchar2,   -- �������� ���������
           p_result out number
           );
  function kart_lsk_add(
           p_lsk_tp in varchar2, -- ��� ������ �� (��������, ��� � �.�.)
           p_lsk_src in kart.lsk%type,-- �� ���������, ��� ����������� ���.�����
           p_lsk_new in out kart.lsk%type, -- ���� null, ���� ������ ����� ��
           p_get_usl_from_src in number, -- ����������� ������ �� nabor ��������� (1-��,0-���)
           p_del_usl_from_src in number, -- ������� ������ �� nabor ��������� (1-��,0-���) (��� �������� ���. �� ������.)
           p_var in number, -- 0- ����� ���.���� ���� �� ������������, ���� �� ��������� (��� �� KLSK, ��� �� KLSK_PREMISE),
                            -- 1- ����� ���.���.���� (������ KLSK, ��� �� KLSK_PREMISE)
                            -- 2- ����� ��������� � ��� �� ���� (������ KLSK, ������ KLSK_PREMISE) (����������� ��� � ���������� � p_lsk_src)
                            -- 3- ����� ��������� � ������ ���� (������ KLSK, ������ KLSK_PREMISE)
           p_kw in varchar2, -- � ��������
           p_reu in varchar2, -- ���� ������, ��������� ������ ��� ��
           p_klsk_dst in number, -- klsk ���.���.�����
           p_close_src in number, -- ������� ������� ��������? (1-��, 0-���)
           p_klsk_premise_dst in number, -- klsk ���������
           p_house number default null,-- Id ����
           p_fam in varchar2 default null, -- �������
           p_im in varchar2 default null,  -- ���
           p_ot in varchar2 default null   -- �������� ���������
         ) return number;
  procedure set_g_lsk_tp(p_tp in number);
  function get_g_lsk_tp return number;
  function get_other_lsk(p_lsk in kart.lsk%type) return tab_lsk;
  --������� klsk �� GUID ����
  function get_klsk_by_guid(p_guid in varchar2) return number;
END P_HOUSES;
/

