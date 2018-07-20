create or replace force view scott.v_messages as
select m.id, m.user_id, m.from_id, m.text, is_read, is_read_lamp,
     decode(uid,m.from_id,0,1) as can_set_is_read,  m.dat
    from messages m
   where m.user_id=uid or m.from_id=uid;

