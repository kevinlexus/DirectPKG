create or replace package scott.P_THREAD is
--���� ��� ��������, ����� �� ���� RECURSIVE ERROR
--g_trg_id number;

--�������� ������� �������� ��� ������������ � �������
procedure prep_obj(p_var in number);
procedure smpl_chk (p_var in number, p_ret out number);
function smpl_chk (p_var in number) return number;
--������� ���, ��� ��� ������ ��� ��������� (��� ������ � c_vvod)
procedure gen_clear_vol;
--������������ ������ �� ����� � ����
procedure gen_dist_odpu(p_vv in number);

--����������� ������ ��� ������ ������� ���� (� ��������)
procedure check_itms(p_itm in number, p_sel in number);


end P_THREAD;
/

