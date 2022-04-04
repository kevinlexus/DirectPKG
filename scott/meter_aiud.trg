CREATE OR REPLACE TRIGGER SCOTT.meter_aiud
  after insert or update or delete on meter
declare
cnt_ number;
begin

for element in 1 .. p_meter.tb_rec_obj.count loop
  if p_meter.tb_rec_obj(element).KLSK_OBJ is not null then
    for c in (select k.lsk from kart k, v_lsk_tp tp where k.psch not in (8,9)
                           and k.k_lsk_id=p_meter.tb_rec_obj(element).klsk_obj -- Если несколько открытых лиц.сч. с одним klsk то обновится только первый!
                           and k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
      ) loop

      --обновить признак счетчика в карточке л/c
      utils.upd_krt_sch_state(c.lsk);
      --обновить текущие показания
      if nvl(p_meter.g_flag,0)=0 then
        for c2 in (select u.counter from usl u
                  where u.usl=p_meter.tb_rec_obj(element).fk_usl
                  and p_meter.tb_rec_obj(element).isChng = 1 -- статус изменения показаний
          )
        loop
           --отразить показания
           insert into t_objxpar (fk_k_lsk, fk_list, n1, fk_user, mg, tp)
             select p_meter.tb_rec_obj(element).KLSK as fk_k_lsk,
                    u.id as fk_list, p_meter.tb_rec_obj(element).N1 as n1, s.id as fk_user, p.period, 0 as tp
             from u_list u, t_user s, params p
             where u.cd in ('ins_sch') and s.cd = user;
          --обновить показания и общий расход за месяц в kart
          execute immediate 'update kart k set k.'||c2.counter||'='||nvl(p_meter.tb_rec_obj(element).N1,0)||' where k.lsk='''||c.lsk||
                  ''' and nvl(k.'||c2.counter||',0) <> '||nvl(p_meter.tb_rec_obj(element).N1,0);
          exit;
        end loop;
      end if;
      exit;
    end loop;


  end if;
end loop;

end meter_aiud;
/

