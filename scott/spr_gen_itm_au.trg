CREATE OR REPLACE TRIGGER SCOTT.spr_gen_itm_au
  after update
  on SPR_GEN_ITM
begin
/*  --������������� recursive error
  if nvl(p_thread.g_trg_id,0) <> -1 then
    --��������� ������ ��������� �������
    p_thread.trg_upd;
  end if;*/
  null;

end spr_gen_itm_au;
/

