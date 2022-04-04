create or replace package body scott.c_obj_par is

 /*function get_num_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in u_list.cd%type) return t_objxpar.n1%type is
 begin
  return c_obj_par.get_num_param(p_k_lsk_id => p_k_lsk_id,
                                     p_lsk => p_lsk,
                                     p_cd => p_cd,
                                     p_cdtp => '��������� ���.�����');
 end;*/

 function get_num_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in u_list.cd%type) return t_objxpar.n1%type is
 l_val_tp u_list.val_tp%type;
 l_result t_objxpar.n1%type;
 begin
   --��������� �������� ��������� Number ���� �� k_lsk.id ���� �� kart.lsk
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
     Raise_application_error(-20000, '����! ���� �� ���� ������������ ���������� p_lsk ��� p_k_lsk_id - �� ������������!');
   end if;

   if l_val_tp <> 'NM' then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� �������� NUMBER �����!');
   end if;
    exception
    when NO_DATA_FOUND then
      return null;
--      raise_application_error(-20001,
--                              '�������� - '||p_cd||' �� ���������������!');
   end;
   return l_result;
 end;

 /*function get_str_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in u_list.cd%type) return t_objxpar.s1%type is
 begin
   return c_obj_par.get_str_param(p_k_lsk_id => p_k_lsk_id,
                                 p_lsk => p_lsk,
                                 p_cd => p_cd,
                                 p_cdtp => '��������� ���.�����');
 end;*/

 function get_str_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in u_list.cd%type) return t_objxpar.s1%type is
 l_val_tp u_list.val_tp%type;
 l_result t_objxpar.s1%type;
 begin
   --��������� �������� ��������� Number ���� �� k_lsk.id ���� �� kart.lsk
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
     Raise_application_error(-20000, '����! ���� �� ���� ������������ ���������� p_lsk ��� p_k_lsk_id - �� ������������!');
   end if;

   if l_val_tp <> 'ST' then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� �������� VARCHAR2 �����!');
   end if;
    exception
    when NO_DATA_FOUND then
      return null;
--      raise_application_error(-20001,
--                              '�������� - '||p_cd||' �� ���������������!');
   end;
   return l_result;
 end;

/* function set_num_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.n1%type) return t_objxpar.id%type is
 begin
   --������� id ���������
   return c_obj_par.set_num_param(p_k_lsk_id => p_k_lsk_id,
                                     p_lsk => p_lsk,
                                     p_cd => p_cd,
                                     p_val => p_val,
                                     p_cdtp => '��������� ���.�����');

 end;*/

 function set_num_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.n1%type) return t_objxpar.id%type is
 l_val_tp u_list.val_tp%type;
 l_id_list u_list.id%type;
 l_t_objxpar_id t_objxpar.id%type;
 l_cnt number;
 begin
   --������ (������� � ������ ����������) �������� ��������� Number ���� �� k_lsk.id ���� �� kart.lsk
   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, '������� ������������ LSK � K_LSK_ID ����������� ��� ��������� ���������!');
   end if;
   begin
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd);
   if l_val_tp <> 'NM' then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� �������� NUMBER �����!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� ���������������!');
   end;

   if p_k_lsk_id is not null then

     update t_objxpar x set x.n1=p_val, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_k_lsk=p_k_lsk_id;

     if SQL%NOTFOUND then
       --�������� �� ������ �������� - �������
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
       --�������� �� ������ �������� - �������
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
     Raise_application_error(-20000, '����! ���� �� ���� ������������ ���������� p_lsk ��� p_k_lsk_id - �� ������������!');
   end if;

   --������ �� ��������
   --commit;
   --������� id ���������
   return l_t_objxpar_id;
 end;


/* function set_str_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.s1%type) return t_objxpar.id%type is
begin
  return c_obj_par.set_str_param(p_k_lsk_id => p_k_lsk_id,
                                     p_lsk => p_lsk,
                                     p_cd => p_cd,
                                     p_val => p_val,
                                     p_cdtp =>'��������� ���.�����');
end;*/



 function set_str_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.s1%type)
   return t_objxpar.id%type is
 l_val_tp u_list.val_tp%type;
 l_id_list u_list.id%type;
 l_t_objxpar_id t_objxpar.id%type;
 l_cnt number;
 begin
   --������ (������� � ������ ����������) �������� ��������� Varchar2 ���� �� k_lsk.id ���� �� kart.lsk
   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, '������� ������������ LSK � K_LSK_ID ������������ ��� ��������� ���������!');
   end if;
   begin
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd);
   if l_val_tp <> 'ST' then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� �������� VARCHAR2 �����!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� ���������������!');
   end;
   if p_k_lsk_id is not null then
     update t_objxpar x set x.s1=p_val, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_k_lsk=p_k_lsk_id;
     if SQL%NOTFOUND then
       --�������� �� ������ �������� - �������
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
       --�������� �� ������ �������� - �������
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
     Raise_application_error(-20000, '����! ���� �� ���� ������������ ���������� p_lsk ��� p_k_lsk_id - �� ������������!');
   end if;

   --������ �� ��������
   --commit;
   --������� id ���������
   return l_t_objxpar_id;
 end;

 --�������� Str �������� ��������� �� CD
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
     Raise_application_error(-20000, '����! ���� �� ���� ������������ ���������� p_lsk ��� p_k_lsk_id - �� ������������!');
   end if;

   if l_val_tp <> 'ID' then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� �������� ID �����!');
   end if;
    exception
    when NO_DATA_FOUND then
      return null;
   end;
   return l_s1;

 end;


 --���������� Str �������� ��������� �� CD, ��������� ���������
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
   --������ (������� � ������ ����������) �������� ��������� Varchar2 ���� �� k_lsk.id ���� �� kart.lsk
   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, '������� ������������ LSK � K_LSK_ID ������������ ��� ��������� ���������!');
   end if;
   begin
     select s.id, s.val_tp, s.sqltext into l_id_list, l_val_tp, l_sqltext
            from u_list s where upper(s.cd)=upper(p_cd);
   if l_val_tp <> 'ID' then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� �������� ID �����!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� ���������������!');
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
                              '�������� - '||p_cd||' �� ������ � �������!');
   end if;

   if p_k_lsk_id is not null then
     update t_objxpar x set x.fk_val=l_id, x.s1=l_cd, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_k_lsk=p_k_lsk_id;
     if SQL%NOTFOUND then
       --�������� �� ������ �������� - �������
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
       --�������� �� ������ �������� - �������
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
     Raise_application_error(-20000, '����! ���� �� ���� ������������ ���������� p_lsk ��� p_k_lsk_id - �� ������������!');
   end if;

   --������ �� ��������
   --commit;
   --������� id ���������
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
                                      p_cdtp => '��������� ���.�����');

end;*/

function set_date_param(p_k_lsk_id in k_lsk.id%type, p_lsk in kart.lsk%type,
   p_cd in varchar2, p_val in t_objxpar.d1%type, p_dflt in number) return t_objxpar.id%type is
 l_val_tp u_list.val_tp%type;
 l_id_list u_list.id%type;
 l_t_objxpar_id t_objxpar.id%type;
 l_cnt number;
 l_val t_objxpar.d1%type;
 begin
   --������ (������� � ������ ����������) �������� ��������� Date ���� �� k_lsk.id ���� �� kart.lsk
   if p_dflt=1 then
     --� ������ ���������� ��������� � ��� ������� ����� ���������� �� ���������
     if p_val is null then
       l_val:=sysdate;
     end if;
   else
     l_val:=p_val;
   end if;
   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, '������� ������������ LSK � K_LSK_ID ������������ ��� ��������� ���������!');
   end if;
   begin
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd);
   if l_val_tp <> 'DT' then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� �������� DATE �����!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� ���������������!');
   end;
   if p_k_lsk_id is not null then
     update t_objxpar x set x.d1=l_val, x.ts=sysdate
       where x.fk_list=l_id_list
       and x.fk_k_lsk=p_k_lsk_id;
     if SQL%NOTFOUND then
       --�������� �� ������ �������� - �������
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
       --�������� �� ������ �������� - �������
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
     Raise_application_error(-20000, '����! ���� �� ���� ������������ ���������� p_lsk ��� p_k_lsk_id - �� ������������!');
   end if;

   --������ �� ��������
   --commit;
   --������� id ���������
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
   --������ (������� � ������ ����������) �������� ��������� RAW, ������������� MD5 ���� �� k_lsk.id ���� �� kart.lsk
   --������ ��������� - �� �������������
   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, '������� ������������ LSK � K_LSK_ID ������������ ��� ��������� ���������!');
   end if;
   begin
   select t.id into l_id_tp from u_listtp t where t.cd='��������� ���.�����';
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd)
              and s.fk_listtp=l_id_tp;
   if l_val_tp <> 'RW' then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� �������� RAW �����!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� ���������������!');
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
     --�� ������ �������� - �������
     insert into t_objxpar
       (fk_lsk, fk_k_lsk, fk_list, pass)
       values (p_lsk, p_k_lsk_id, l_id_list, l_md5)
       returning id into l_t_objxpar_id;
   end if;

   --������ �� ��������
   --commit;
   --������� id ���������
   return l_t_objxpar_id;
 end;


 --������ (������� � ������ ����������) �������� ��������� Number ���� �� k_lsk.id ���� �� kart.lsk
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
   --�������� ID ������������
   l_user:=init.get_user;

   --������� ������
   select p.period into l_mg from
     params p;

   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, '������� ������������ LSK � K_LSK_ID ����������� ��� ��������� ���������!');
   end if;
   begin
   select t.id into l_id_tp from u_listtp t where t.cd='��������� ���.�����';
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd)
              and s.fk_listtp=l_id_tp;
   if l_val_tp <> 'NM' then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� �������� NUMBER �����!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� ���������������!');
   end;

   if p_k_lsk_id is not null then
     --������� ������
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

   --������ �� ��������
   --commit;
   --������� id ���������
   return l_t_objxpar_id;
 end;

--������ (������� � ������ ����������) �������� ��������� Number ���� �� k_lsk.id ���� �� kart.lsk �� ���� p_tp_par
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
   --�������� ID ������������
   l_user:=init.get_user;

   --������� ������
   select p.period into l_mg from
     params p;

   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, '������� ������������ LSK � K_LSK_ID ����������� ��� ��������� ���������!');
   end if;
   begin
   select t.id into l_id_tp from u_listtp t where t.cd=p_tp_par;
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd)
              and s.fk_listtp=l_id_tp;
   if l_val_tp <> 'NM' then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� �������� NUMBER �����!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� ���������������!');
   end;

   if p_k_lsk_id is not null then
     --������� ������
     for c in (select * from t_objxpar x where x.fk_k_lsk=p_k_lsk_id and x.fk_list=l_id_list) loop
       --���� ��� �������, �����, �� ���������
       return c.id;
     end loop;
     insert into t_objxpar
       (fk_lsk, fk_k_lsk, fk_list, n1, fk_user, ts, mg)
       values (p_lsk, p_k_lsk_id, l_id_list, p_val, l_user, sysdate, l_mg)
       returning id into l_t_objxpar_id;
   elsif p_lsk is not null then
     for c in (select * from t_objxpar x where x.fk_lsk=p_lsk and x.fk_list=l_id_list) loop
       --���� ��� �������, �����, �� ���������
       return c.id;
     end loop;
     insert into t_objxpar
       (fk_lsk, fk_k_lsk, fk_list, n1, fk_user, ts, mg)
       values (p_lsk, p_k_lsk_id, l_id_list, p_val, l_user, sysdate, l_mg)
       returning id into l_t_objxpar_id;
   end if;

   --������ �� ��������
   --commit;
   --������� id ���������
   return l_t_objxpar_id;
 end;

 --������ (������� � ������ ����������) �������� ��������� ���� ID ���� �� k_lsk.id ���� �� kart.lsk �� ���� p_tp_par
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
   --�������� ID ������������
   l_user:=init.get_user;

   --������� ������
   select p.period into l_mg from
     params p;

   if p_k_lsk_id is not null and p_lsk is not null then
     Raise_application_error(-20000, '������� ������������ LSK � K_LSK_ID ����������� ��� ��������� ���������!');
   end if;
   begin
   select t.id into l_id_tp from u_listtp t where t.cd=p_tp_par;
     select s.id, s.val_tp into l_id_list, l_val_tp
            from u_list s where upper(s.cd)=upper(p_cd)
              and s.fk_listtp=l_id_tp;
   if l_val_tp <> 'ID' then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� �������� ID �����!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              '�������� - '||p_cd||' �� ���������������!');
   end;

   if p_k_lsk_id is not null then
     --������� ������
     for c in (select * from t_objxpar x where x.fk_k_lsk=p_k_lsk_id and x.fk_list=l_id_list) loop
       --���� ��� �������, �����, �� ���������
       return c.id;
     end loop;
     insert into t_objxpar
       (fk_lsk, fk_k_lsk, fk_list, n1, fk_user, ts, mg)
       values (p_lsk, p_k_lsk_id, l_id_list, p_val, l_user, sysdate, l_mg)
       returning id into l_t_objxpar_id;
   elsif p_lsk is not null then
     for c in (select * from t_objxpar x where x.fk_lsk=p_lsk and x.fk_list=l_id_list) loop
       --���� ��� �������, �����, �� ���������
       return c.id;
     end loop;
     insert into t_objxpar
       (fk_lsk, fk_k_lsk, fk_list, n1, fk_user, ts, mg)
       values (p_lsk, p_k_lsk_id, l_id_list, p_val, l_user, sysdate, l_mg)
       returning id into l_t_objxpar_id;
   end if;

   --������ �� ��������
   --commit;
   --������� id ���������
   return l_t_objxpar_id;
 end;

 --�������� ������ �� ID ��������� (�� list)
 procedure get_list_by_id(p_par_id in number, prep_refcursor out rep_refcursor) is
 begin
   for c in (select * from u_list t where t.id=p_par_id) loop
   begin
     open prep_refcursor for
      c.sqltext;
    exception when others then
      Raise_application_error(-20000, '������ SQL ������� "'||c.sqltext||'" � ������ ��������� list.id='||p_par_id);
    end;

   end loop;
 end;

end c_obj_par;
/

