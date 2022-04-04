create or replace force view scott.v_messages_last as
select text, dat, username, id, user_id from
(select m.text, m.dat, a.username, m.id, a.user_id
    from messages m, all_users a
   where m.user_id=uid and a.user_id=m.from_id and m.is_read_lamp=0
order by m.dat desc)
where rownum=1;

