create or replace package body scott.c_obj_par is

 /*function get_num_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in u_list.cd%type) return t_objxpar.n1%type is
 begin
  return c_obj_par.get_num_param(p_k_lsk_id => p_k_lsk_id,
                                     p_lsk => p_lsk,
                                     p_cd => p_cd,
                                     p_cdtp => 'Параметры лиц.счета');
 end;*/

 function get_num_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in u_list.cd%type) return t_objxpar.n1%type is
 l_val_tp u_list.val_tp%type;
 l_result t_objxpar.n1%type;
 begin
   --возращает значение параметра Number либо по k_lsk.id либо по kart.lsk
   begin
   if p_k_lsk_id is not null then
     select x.n1, s.val_tp into l_result, l_val_tp
            from t_objxpar x, u_list s where upper(s.cd)=upper(p_cd)
            and x.fk_k_lsk=p_k_lsk_id
            and x.fk_list=s.id
            ;
   elsif p_lsk is not null then
     select x.n1, s.val_tp into l_result, l_val_tp
            from t_objxpar x, u_list s where upper(s.cd)=upper(p_cd)
            and x.fk_lsk=p_lsk
            and x.fk_list=s.id;
   else
     Raise_application_error(-20000, 'Стоп! Один из двух обязательных параметров p_lsk или p_k_lsk_id - не используется!');
   end if;

   if l_val_tp <> 'NM' then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не является NUMBER типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      return null;
--      raise_application_error(-20001,
--                              'Параметр - '||p_cd||' не зарегистрирован!');
   end;
   return l_result;
 end;

 /*function get_str_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in u_list.cd%type) return t_objxpar.s1%type is
 begin
   return c_obj_par.get_str_param(p_k_lsk_id => p_k_lsk_id,
                                 p_lsk => p_lsk,
                                 p_cd => p_cd,
                                 p_cdtp => 'Параметры лиц.счета');
 end;*/

 function get_str_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in u_list.cd%type) return t_objxpar.s1%type is
 l_val_tp u_list.val_tp%type;
 l_result t_objxpar.s1%type;
 begin
   --возращает значение параметра Number либо по k_lsk.id либо по kart.lsk
   begin
   if p_k_lsk_id is not null then
     select x.s1, s.val_tp into l_result, l_val_tp
            from t_objxpar x, u_list s where upper(s.cd)=upper(p_cd)
            and x.fk_k_lsk=p_k_lsk_id
            and x.fk_list=s.id;
   elsif p_lsk is not null then
     select x.s1, s.val_tp into l_result, l_val_tp
            from t_objxpar x, u_list s where upper(s.cd)=upper(p_cd)
            and x.fk_lsk=p_lsk
            and x.fk_list=s.id;
   else
     Raise_application_error(-20000, 'Стоп! Один из двух обязательных параметров p_lsk или p_k_lsk_id - не используется!');
   end if;

   if l_val_tp <> 'ST' then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не является VARCHAR2 типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      return null;
--      raise_application_error(-20001,
--                              'Параметр - '||p_cd||' не зарегистрирован!');
   end;
   return l_result;
 end;

/* function set_num_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.n1%type) return t_objxpar.id%type is
 begin
   --вернуть id параметра
   return c_obj_par.set_num_param(p_k_lsk_id => p_k_lsk_id,
                                     p_lsk => p_lsk,
                                     p_cd => p_cd,
                                     p_val => p_val,
                                     p_cdtp => 'Параметры лиц.счета');

 end;*/

 function set_num_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.n1%type) return t_objxpar.id%type is
 l_val_tp u_list.val_tp%type;
 l_id_list u_list.id%type;
 l_t_objxpar_id t_objxpar.id%type;
 l_cnt number;
 begin
   --задает (создает в случае отсутствия) значение параметра Number либо по k_lsk.id либо по kart.lsk
   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, 'Попытка использовать LSK и K_LSK_ID одовременно при установке параметра!');
   end if;
   begin
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd);
   if l_val_tp <> 'NM' then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не является NUMBER типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не зарегистрирован!');
   end;

   if p_k_lsk_id is not null then

     update t_objxpar x set x.n1=p_val, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_k_lsk=p_k_lsk_id;

     if SQL%NOTFOUND then
       --возможно не найден параметр - создать
       select nvl(count(*),0) into l_cnt from
         t_objxpar x where x.fk_k_lsk=p_k_lsk_id
          and x.fk_list=l_id_list;
       if l_cnt = 0 then
         insert into t_objxpar
           (fk_lsk, fk_k_lsk, fk_list, n1)
           values (p_lsk, p_k_lsk_id, l_id_list, p_val)
           returning id into l_t_objxpar_id;
       end if;
     end if;

   elsif p_lsk is not null then
     update t_objxpar x set x.n1=p_val, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_lsk=p_lsk;
     if SQL%NOTFOUND then
       --возможно не найден параметр - создать
       select nvl(count(*),0) into l_cnt from
         t_objxpar x where x.fk_lsk=p_lsk
          and x.fk_list=l_id_list;
       if l_cnt = 0 then
         insert into t_objxpar
           (fk_lsk, fk_k_lsk, fk_list, n1)
           values (p_lsk, p_k_lsk_id, l_id_list, p_val)
           returning id into l_t_objxpar_id;
       end if;
     end if;

   else
     Raise_application_error(-20000, 'Стоп! Один из двух обязательных параметров p_lsk или p_k_lsk_id - не используется!');
   end if;

   --коммит не делается
   --commit;
   --вернуть id параметра
   return l_t_objxpar_id;
 end;


/* function set_str_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.s1%type) return t_objxpar.id%type is
begin
  return c_obj_par.set_str_param(p_k_lsk_id => p_k_lsk_id,
                                     p_lsk => p_lsk,
                                     p_cd => p_cd,
                                     p_val => p_val,
                                     p_cdtp =>'Параметры лиц.счета');
end;*/



 function set_str_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.s1%type)
   return t_objxpar.id%type is
 l_val_tp u_list.val_tp%type;
 l_id_list u_list.id%type;
 l_t_objxpar_id t_objxpar.id%type;
 l_cnt number;
 begin
   --задает (создает в случае отсутствия) значение параметра Varchar2 либо по k_lsk.id либо по kart.lsk
   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, 'Попытка использовать LSK и K_LSK_ID ондовременно при установке параметра!');
   end if;
   begin
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd);
   if l_val_tp <> 'ST' then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не является VARCHAR2 типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не зарегистрирован!');
   end;
   if p_k_lsk_id is not null then
     update t_objxpar x set x.s1=p_val, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_k_lsk=p_k_lsk_id;
     if SQL%NOTFOUND then
       --возможно не найден параметр - создать
       select nvl(count(*),0) into l_cnt from
         t_objxpar x where x.fk_k_lsk=p_k_lsk_id
          and x.fk_list=l_id_list;
       if l_cnt = 0 then
         insert into t_objxpar
           (fk_lsk, fk_k_lsk, fk_list, s1)
           values (p_lsk, p_k_lsk_id, l_id_list, p_val)
           returning id into l_t_objxpar_id;
       end if;
     end if;

   elsif p_lsk is not null then
     update t_objxpar x set x.s1=p_val, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_lsk=p_lsk;
     if SQL%NOTFOUND then
       --возможно не найден параметр - создать
       select nvl(count(*),0) into l_cnt from
         t_objxpar x where x.fk_lsk=p_lsk
          and x.fk_list=l_id_list;
       if l_cnt = 0 then
         insert into t_objxpar
           (fk_lsk, fk_k_lsk, fk_list, s1)
           values (p_lsk, p_k_lsk_id, l_id_list, p_val)
           returning id into l_t_objxpar_id;
       end if;
     end if;
   else
     Raise_application_error(-20000, 'Стоп! Один из двух обязательных параметров p_lsk или p_k_lsk_id - не используется!');
   end if;

   --коммит не делается
   --commit;
   --вернуть id параметра
   return l_t_objxpar_id;
 end;

 --получить Str значение параметра по CD
 function get_str_param_by_qry(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2)
   return varchar2 is
   l_s1 t_objxpar.s1%type;
   l_val_tp u_list.val_tp%type;
 begin
   begin
   if p_k_lsk_id is not null then
     select x.s1, s.val_tp into l_s1, l_val_tp
            from t_objxpar x, u_list s where upper(s.cd)=upper(p_cd)
            and x.fk_k_lsk=p_k_lsk_id
            and x.fk_list=s.id;
   elsif p_lsk is not null then
     select x.s1, s.val_tp into l_s1, l_val_tp
            from t_objxpar x, u_list s where upper(s.cd)=upper(p_cd)
            and x.fk_lsk=p_lsk
            and x.fk_list=s.id;
   else
     Raise_application_error(-20000, 'Стоп! Один из двух обязательных параметров p_lsk или p_k_lsk_id - не используется!');
   end if;

   if l_val_tp <> 'ID' then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не является ID типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      return null;
   end;
   return l_s1;

 end;


 --установить Str значение параметра по CD, используя подзапрос
 function set_str_param_by_qry(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_cd_val in varchar2)
   return t_objxpar.id%type is
 l_val_tp u_list.val_tp%type;
 l_id_list u_list.id%type;
 l_t_objxpar_id t_objxpar.id%type;
 l_cnt number;
 l_id number;
 l_sqltext u_list.sqltext%type;
 l_name u_list.name%type;
 l_cd u_list.cd%type;
 TYPE cur_type IS REF CURSOR;
    cur cur_type;
 begin
   --задает (создает в случае отсутствия) значение параметра Varchar2 либо по k_lsk.id либо по kart.lsk
   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, 'Попытка использовать LSK и K_LSK_ID ондовременно при установке параметра!');
   end if;
   begin
     select s.id, s.val_tp, s.sqltext into l_id_list, l_val_tp, l_sqltext
            from u_list s where upper(s.cd)=upper(p_cd);
   if l_val_tp <> 'ID' then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не является ID типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не зарегистрирован!');
   end;

    OPEN cur FOR l_sqltext;
    LOOP
        FETCH cur INTO l_id, l_name, l_cd;
        EXIT WHEN cur%NOTFOUND;
        if l_cd = p_cd_val then
          exit;
        end if;
    END LOOP;
    CLOSE cur;
   if l_cd is null then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не найден в запросе!');
   end if;

   if p_k_lsk_id is not null then
     update t_objxpar x set x.fk_val=l_id, x.s1=l_cd, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_k_lsk=p_k_lsk_id;
     if SQL%NOTFOUND then
       --возможно не найден параметр - создать
       select nvl(count(*),0) into l_cnt from
         t_objxpar x where x.fk_k_lsk=p_k_lsk_id
          and x.fk_list=l_id_list;
       if l_cnt = 0 then
         insert into t_objxpar
           (fk_lsk, fk_k_lsk, fk_list, fk_val, s1)
           values (p_lsk, p_k_lsk_id, l_id_list, l_id, l_cd)
           returning id into l_t_objxpar_id;
       end if;
     end if;

   elsif p_lsk is not null then
     update t_objxpar x set x.fk_val=l_id, x.s1=l_cd, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_lsk=p_lsk;
     if SQL%NOTFOUND then
       --возможно не найден параметр - создать
       select nvl(count(*),0) into l_cnt from
         t_objxpar x where x.fk_lsk=p_lsk
          and x.fk_list=l_id_list;
       if l_cnt = 0 then
         insert into t_objxpar
           (fk_lsk, fk_k_lsk, fk_list, fk_val, s1)
           values (p_lsk, p_k_lsk_id, l_id_list, l_id, l_cd)
           returning id into l_t_objxpar_id;
       end if;
     end if;
   else
     Raise_application_error(-20000, 'Стоп! Один из двух обязательных параметров p_lsk или p_k_lsk_id - не используется!');
   end if;

   --коммит не делается
   --commit;
   --вернуть id параметра
   return l_t_objxpar_id;
 end;

/*function set_date_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.d1%type, p_dflt in number)
   return t_objxpar.id%type is
begin
  return c_obj_par.set_date_param(p_k_lsk_id => p_k_lsk_id,
                                      p_lsk => p_lsk,
                                      p_cd => p_cd,
                                      p_val => p_val,
                                      p_dflt => p_dflt,
                                      p_cdtp => 'Параметры лиц.счета');

end;*/

function set_date_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.d1%type, p_dflt in number) return t_objxpar.id%type is
 l_val_tp u_list.val_tp%type;
 l_id_list u_list.id%type;
 l_t_objxpar_id t_objxpar.id%type;
 l_cnt number;
 l_val t_objxpar.d1%type;
 begin
   --задает (создает в случае отсутствия) значение параметра Date либо по k_lsk.id либо по kart.lsk
   if p_dflt=1 then
     --в случае отсутствия параметра и при наличии флага установить по умлочанию
     if p_val is null then
       l_val:=sysdate;
     end if;
   else
     l_val:=p_val;
   end if;
   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, 'Попытка использовать LSK и K_LSK_ID ондовременно при установке параметра!');
   end if;
   begin
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd);
   if l_val_tp <> 'DT' then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не является DATE типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не зарегистрирован!');
   end;
   if p_k_lsk_id is not null then
     update t_objxpar x set x.d1=l_val, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_k_lsk=p_k_lsk_id;
     if SQL%NOTFOUND then
       --возможно не найден параметр - создать
       select nvl(count(*),0) into l_cnt from
         t_objxpar x where x.fk_k_lsk=p_k_lsk_id
          and x.fk_list=l_id_list;
       if l_cnt = 0 then
         insert into t_objxpar
           (fk_lsk, fk_k_lsk, fk_list, d1)
           values (p_lsk, p_k_lsk_id, l_id_list, l_val)
           returning id into l_t_objxpar_id;
       end if;
     end if;

   elsif p_lsk is not null then
     update t_objxpar x set x.d1=l_val, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_lsk=p_lsk;
     if SQL%NOTFOUND then
       --возможно не найден параметр - создать
       select nvl(count(*),0) into l_cnt from
         t_objxpar x where x.fk_lsk=p_lsk
          and x.fk_list=l_id_list;
       if l_cnt = 0 then
         insert into t_objxpar
           (fk_lsk, fk_k_lsk, fk_list, d1)
           values (p_lsk, p_k_lsk_id, l_id_list, l_val)
           returning id into l_t_objxpar_id;
       end if;
     end if;
   else
     Raise_application_error(-20000, 'Стоп! Один из двух обязательных параметров p_lsk или p_k_lsk_id - не используется!');
   end if;

   --коммит не делается
   --commit;
   --вернуть id параметра
   return l_t_objxpar_id;
 end;

 function set_md5_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in varchar2) return t_objxpar.id%type is
 l_val_tp u_list.val_tp%type;
 l_id_tp u_listtp.id%type;
 l_id_list u_list.id%type;
 l_t_objxpar_id t_objxpar.id%type;
 l_md5 RAW(50);
 begin
   --задает (создает в случае отсутствия) значение параметра RAW, зашифрованное MD5 либо по k_lsk.id либо по kart.lsk
   --чтение параметра - не предусмотрено
   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, 'Попытка использовать LSK и K_LSK_ID ондовременно при установке параметра!');
   end if;
   begin
   select t.id into l_id_tp from u_listtp t where t.cd='Параметры лиц.счета';
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd)
              and s.fk_listtp=l_id_tp;
   if l_val_tp <> 'RW' then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не является RAW типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не зарегистрирован!');
   end;
   l_md5:=utl_raw.cast_to_raw(dbms_obfuscation_toolkit.md5
                          (input_string => p_val));

   if p_k_lsk_id is not null then
     update t_objxpar x set x.pass=l_md5, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_k_lsk=p_k_lsk_id;
   elsif p_lsk is not null then
     update t_objxpar x set x.pass=l_md5, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_lsk=p_lsk;
   end if;

   if SQL%NOTFOUND then
     --не найден параметр - создать
     insert into t_objxpar
       (fk_lsk, fk_k_lsk, fk_list, pass)
       values (p_lsk, p_k_lsk_id, l_id_list, l_md5)
       returning id into l_t_objxpar_id;
   end if;

   --коммит не делается
   --commit;
   --вернуть id параметра
   return l_t_objxpar_id;
 end;


 --задает (создает в случае отсутствия) значение параметра Number либо по k_lsk.id либо по kart.lsk
 function ins_num_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.n1%type,
   p_usl in usl.usl%type,
   p_tp in t_objxpar.tp%type) return t_objxpar.id%type is
 l_val_tp u_list.val_tp%type;
 l_id_tp u_listtp.id%type;
 l_id_list u_list.id%type;
 l_t_objxpar_id t_objxpar.id%type;
 l_user number;
 l_mg params.period%type;
 begin
   --получить ID пользователя
   l_user:=init.get_user;

   --текущий период
   select p.period into l_mg from
     params p;

   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, 'Попытка использовать LSK и K_LSK_ID одовременно при установке параметра!');
   end if;
   begin
   select t.id into l_id_tp from u_listtp t where t.cd='Параметры лиц.счета';
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd)
              and s.fk_listtp=l_id_tp;
   if l_val_tp <> 'NM' then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не является NUMBER типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не зарегистрирован!');
   end;

   if p_k_lsk_id is not null then
     --создать строку
     insert into t_objxpar
       (fk_lsk, fk_k_lsk, fk_list, n1, fk_user, fk_usl, tp, ts, mg)
       values (p_lsk, p_k_lsk_id, l_id_list, p_val, l_user, p_usl, p_tp, sysdate, l_mg)
       returning id into l_t_objxpar_id;
   elsif p_lsk is not null then
     insert into t_objxpar
       (fk_lsk, fk_k_lsk, fk_list, n1, fk_user, fk_usl, tp, ts, mg)
       values (p_lsk, p_k_lsk_id, l_id_list, p_val, l_user, p_usl, p_tp, sysdate, l_mg)
       returning id into l_t_objxpar_id;
   end if;

   --коммит не делается
   --commit;
   --вернуть id параметра
   return l_t_objxpar_id;
 end;

--задает (создает в случае отсутствия) значение параметра Number либо по k_lsk.id либо по kart.lsk по типу p_tp_par
 function ins_num_tp_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.n1%type,
   p_tp_par in varchar2) return t_objxpar.id%type is
 l_val_tp u_list.val_tp%type;
 l_id_tp u_listtp.id%type;
 l_id_list u_list.id%type;
 l_t_objxpar_id t_objxpar.id%type;
 l_user number;
 l_mg params.period%type;
 begin
   --получить ID пользователя
   l_user:=init.get_user;

   --текущий период
   select p.period into l_mg from
     params p;

   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, 'Попытка использовать LSK и K_LSK_ID одовременно при установке параметра!');
   end if;
   begin
   select t.id into l_id_tp from u_listtp t where t.cd=p_tp_par;
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd)
              and s.fk_listtp=l_id_tp;
   if l_val_tp <> 'NM' then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не является NUMBER типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не зарегистрирован!');
   end;

   if p_k_lsk_id is not null then
     --создать строку
     for c in (select * from t_objxpar x where x.fk_k_lsk=p_k_lsk_id and x.fk_list=l_id_list) loop
       --если уже создано, выйти, не создавать
       return c.id;
     end loop;
     insert into t_objxpar
       (fk_lsk, fk_k_lsk, fk_list, n1, fk_user, ts, mg)
       values (p_lsk, p_k_lsk_id, l_id_list, p_val, l_user, sysdate, l_mg)
       returning id into l_t_objxpar_id;
   elsif p_lsk is not null then
     for c in (select * from t_objxpar x where x.fk_lsk=p_lsk and x.fk_list=l_id_list) loop
       --если уже создано, выйти, не создавать
       return c.id;
     end loop;
     insert into t_objxpar
       (fk_lsk, fk_k_lsk, fk_list, n1, fk_user, ts, mg)
       values (p_lsk, p_k_lsk_id, l_id_list, p_val, l_user, sysdate, l_mg)
       returning id into l_t_objxpar_id;
   end if;

   --коммит не делается
   --commit;
   --вернуть id параметра
   return l_t_objxpar_id;
 end;

 --задает (создает в случае отсутствия) значение параметра типа ID либо по k_lsk.id либо по kart.lsk по типу p_tp_par
 function ins_id_tp_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.fk_val%type,
   p_tp_par in varchar2
   ) return t_objxpar.id%type is
 l_val_tp u_list.val_tp%type;
 l_id_tp u_listtp.id%type;
 l_id_list u_list.id%type;
 l_t_objxpar_id t_objxpar.id%type;
 l_user number;
 l_mg params.period%type;
 begin
   --получить ID пользователя
   l_user:=init.get_user;

   --текущий период
   select p.period into l_mg from
     params p;

   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, 'Попытка использовать LSK и K_LSK_ID одовременно при установке параметра!');
   end if;
   begin
   select t.id into l_id_tp from u_listtp t where t.cd=p_tp_par;
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd)
              and s.fk_listtp=l_id_tp;
   if l_val_tp <> 'ID' then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не является ID типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||p_cd||' не зарегистрирован!');
   end;

   if p_k_lsk_id is not null then
     --создать строку
     for c in (select * from t_objxpar x where x.fk_k_lsk=p_k_lsk_id and x.fk_list=l_id_list) loop
       --если уже создано, выйти, не создавать
       return c.id;
     end loop;
     insert into t_objxpar
       (fk_lsk, fk_k_lsk, fk_list, n1, fk_user, ts, mg)
       values (p_lsk, p_k_lsk_id, l_id_list, p_val, l_user, sysdate, l_mg)
       returning id into l_t_objxpar_id;
   elsif p_lsk is not null then
     for c in (select * from t_objxpar x where x.fk_lsk=p_lsk and x.fk_list=l_id_list) loop
       --если уже создано, выйти, не создавать
       return c.id;
     end loop;
     insert into t_objxpar
       (fk_lsk, fk_k_lsk, fk_list, n1, fk_user, ts, mg)
       values (p_lsk, p_k_lsk_id, l_id_list, p_val, l_user, sysdate, l_mg)
       returning id into l_t_objxpar_id;
   end if;

   --коммит не делается
   --commit;
   --вернуть id параметра
   return l_t_objxpar_id;
 end;

 --получить список по ID параметра (из list)
 procedure get_list_by_id(p_par_id in number, prep_refcursor out rep_refcursor) is
 begin
   for c in (select * from u_list t where t.id=p_par_id) loop
   begin
     open prep_refcursor for
      c.sqltext;
    exception when others then
      Raise_application_error(-20000, 'Ошибка SQL запроса "'||c.sqltext||'" в тексте параметра list.id='||p_par_id);
    end;

   end loop;
 end;

end c_obj_par;
/

