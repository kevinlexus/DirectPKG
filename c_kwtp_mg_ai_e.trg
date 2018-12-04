CREATE OR REPLACE TRIGGER SCOTT.c_kwtp_mg_ai_e
  after insert on c_kwtp_mg
  for each row
declare
rec_ c_kwtp_mg%rowtype;
l_reu varchar2(3);
begin
--������������� ������� ����� ������� ������ ������
 if nvl(:new.is_dist,0) = 0 then
 --���� ������ ��� �� ������������ (������������ ������ ����� ������.��������)
 select :new.lsk, :new.summa, :new.penya, :new.oper, :new.dopl, :new.nink, :new.nkom, :new.dtek, :new.nkvit,
  :new.dat_ink, :new.ts, :new.c_kwtp_id, :new.cnt_sch, :new.cnt_sch0, :new.id, :new.is_dist
  into rec_.lsk, rec_.summa, rec_.penya, rec_.oper, rec_.dopl, rec_.nink, rec_.nkom, rec_.dtek,
    rec_.nkvit, rec_.dat_ink, rec_.ts, rec_.c_kwtp_id, rec_.cnt_sch, rec_.cnt_sch0,
    rec_.id, rec_.is_dist from dual;
   if rec_.dtek <= init.g_dt_end then
     --���� ����� ������ �����, ������� ��� ��������� �������,
     --�� ������������ ��� �� �������-���, � ��������� ������- ���!
     --����� ��� ����, ����� �� ���� ������ ���-�� �������� � c_gen_pay! ���. 15.09.14
     --����� ������� ������������� ��������, �������� �������� ���������
     if utils.get_int_param('DIST_PAY_TP') = 0 then
     --��-��������� ������ ������������� ������
       c_gen_pay.dist_pay_lsk(rec_, 0);
     else
     --��-��������� ������ ������������� ������ (���., �����.)
       --������ ����������� �����������
       --(�� ����, ����������� � ���������)
       --c_dist_pay.gen_deb_usl(rec_.lsk);
       --����� ������������ ������
--       if :new.lsk<>'15042520' then
         select reu into l_reu from kart k where k.lsk=rec_.lsk;
         c_dist_pay.dist_pay_deb_mg_lsk(l_reu, rec_);
--       end if;
     end if;
    end if;
 end if;
 
/* if utils.get_int_param('IS_NOTIF') = 1 then
   -- ������� ��������� ��� ��� ���
   c_get_pay.create_notification_gis(rec_);
 end if;
*/end c_kwtp_mg_ai_e;
/

