CREATE OR REPLACE TRIGGER SCOTT.spr_gen_itm_bue
  before update
  of sel on SPR_GEN_ITM
  for each row
begin
  --предотвратить recursive error и поставить значение id
/*  if nvl(p_thread.g_trg_id,0) <> -1 then
    p_thread.g_trg_id:=:new.id;
  end if;
*/
null;
end spr_gen_itm_bue;
/

