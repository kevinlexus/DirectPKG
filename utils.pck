create or replace package scott.utils is
 --глобальная переменная для триггера, для добавления нового spk_id
 spk_id_ spk.id%type;
 --sprorg_kod_ sprorg.kod%type;
 spr_tarif_id_ spr_tarif.id%type;
 spr_tarif_root_id_ spr_tarif.id%type;
 oper_ oper.oper%type;

 function MONTH_NAME1(month_ NUMBER) RETURN varchar2;
 function MONTH_NAME(month_ NUMBER) RETURN VARCHAR2;
 function add_months_pr(mg_ in varchar2, cnt_ in number) return varchar2;
 FUNCTION get_org_lsk(p_lsk IN kart.lsk%TYPE)
           RETURN NUMBER;
 FUNCTION get_nkom_pay_lsk(p_lsk IN kart.lsk%TYPE)
    RETURN c_comps.nkom%type;
 function GET_LSK_BY_ADR(kul_ kart.kul%TYPE, nd_ kart.nd%TYPE, kw_ kart.kw%TYPE)
           RETURN VARCHAR2;
 function GET_C_LSK_ID_BY_ADR(kul_ kart.kul%TYPE, nd_ kart.nd%TYPE, kw_ kart.kw%TYPE)
           RETURN VARCHAR2;
function GET_LSK_BY_ADR2(house_id_ kart.house_id%TYPE, kw_ kart.kw%TYPE)
           RETURN VARCHAR2;
 function GET_LSK_BY_ADR3(house_id_ kart.house_id%TYPE, kw_ kart.kw%TYPE)
           RETURN kart.k_lsk_id%type;
 function GET_LSK_BY_ADR4(house_id_ kart.house_id%TYPE, kw_ kart.kw%TYPE)
           RETURN kart.c_lsk_id%type;
 function GET_K_LSK_ID_BY_LSK(lsk_ kart.lsk%TYPE)
           RETURN kart.k_lsk_id%type;
 function GET_C_LSK_ID_BY_LSK(lsk_ kart.lsk%TYPE)
           RETURN kart.c_lsk_id%type;
 function GET_ADR_BY_LSK(lsk_ kart.lsk%TYPE)
           RETURN varchar2;
 function ALLOW_FUNCT(fk_type_ in number)
           RETURN NUMBER;
  function ALLOW_EDIT_LSK(lsk_ kart.lsk%TYPE, cd_ in varchar2)
           RETURN NUMBER;
  function ALLOW_EDIT_LSK_BY_REU(p_reu in varchar2, p_pasp_org in number, p_cd in varchar2)
           RETURN NUMBER;
 function ALLOW_CR_NEW_LSK(lsk_ kart.lsk%TYPE)
           RETURN NUMBER;
 function ALLOW_CHANGES_LSK(lsk_ kart.lsk%TYPE)
           RETURN NUMBER;
 function GET_NEW_LSK (lsk_ in kart.lsk%TYPE, p_lsk in kart.lsk%TYPE)
           RETURN kart.lsk%type;
 FUNCTION GET_NEW_LSK_BY_REU(p_reu kart.reu%TYPE) RETURN kart.lsk%TYPE;
 procedure ins_lg_doc (kart_pr_id_ in c_kart_pr.id%type);
 procedure del_lg_doc (c_lg_docs_id_ in c_lg_docs.id%type);
 procedure count_krt_kpr (lsk_ in kart.lsk%type);
 function count_krt_kpr (user_id_ in number) return number;
 function get_report_name (id_ in number)
   return varchar2;
 function get_sum_str_2(source in number) return varchar2;
 function f_order(str_ varchar2, len_ number) return varchar2;
 function f_order2(str_ varchar2) return varchar2;
 function f_ord2(str_ varchar2) return varchar2;
 function f_ord3(p_str varchar2) return varchar2;
 function f_ord_digit(p_str varchar2) return number;
 function add_months2(mg_ in varchar2, months_ in number) return varchar2;
 procedure prep_users_tree;
 procedure prep_users_par;
 function concatenate(v_rownum    number,
                     v_string    varchar2,
                     v_delimiter varchar2 default null,
                     v_call_id number default 1) return varchar2;
 function tst_krt(lsk_ in kart.lsk%type, var_ in number) return varchar2;
 procedure set_kpr(lsk_ in kart.lsk%type);
 procedure set_krt_adm (lsk_ in c_kart_pr.lsk%type);
 procedure set_krt_adm2 (fk_kart_pr_ in c_kart_pr.id%type);
 procedure upd_c_kart_pr_state(fk_kart_pr_ in c_kart_pr.id%type);
 function add_list(cdtp_ in u_listtp.cd%type, cd_ in u_list.cd%type,
   name_ in u_list.name%type) return number;
 procedure add_usl(uslm_ in usl.uslm%type, prefix_ in varchar2,
   name_ in varchar2, name2_ in usl.nm2%type, cd_ in usl.cd%type,
   price_ in prices.summa%type, org_ in nabor.org%type,
   koeff_ in nabor.koeff%type, norm_ in nabor.norm%type,
   usl_koeff_ in usl.usl%type, usl_norm_ in usl.usl%type,
   usl_org_ in usl.usl%type);
 procedure usl_add_flds;
 function del_lsk(lsk_ in kart.lsk%type) return varchar2;
 -- удалить лиц.счет без проверок
function del_lsk_wo_check(lsk_ in kart.lsk%type) return varchar2;
procedure del_usl(usl_ in usl.usl%type);
 procedure del_uslm(uslm_ in usl.uslm%type);
 procedure cp_price(err_ out number, err_str_ out varchar2,
   usl_ in prices.usl%type, fk_org_src_ in prices.fk_org%type,
   fk_org_dst_ in prices.fk_org%type);
 procedure del_price(usl_ in prices.usl%type, fk_org_ in prices.fk_org%type);
 function set_int_param(l_cd spr_params.cd%type,
     l_val spr_params.parn1%type) return spr_params.id%type;
 function get_int_param(cd_ varchar2) return spr_params.parn1%type ;
 function getS_int_param(cd_ varchar2) return spr_params.parn1%type;
 function get_bool_param(cd_ varchar2) return spr_params.parn1%type;
 function getS_bool_param(cd_ varchar2) return spr_params.parn1%type;
 function get_str_param(cd_ varchar2) return spr_params.parvc1%type;
 function getS_str_param(cd_ varchar2) return spr_params.parvc1%type;
 function get_date_param(cd_ varchar2) return spr_params.pardt1%type;
 function getS_date_param(cd_ varchar2) return spr_params.pardt1%type;
 function getS_list_param(cd_ varchar2) return list_c.sel_id%type;
 function getScd_list_param(cd_ varchar2) return list_c.sel_cd%type;
 procedure fill_list_c (fk_par_ in spr_params.id%type);
 procedure set_list_c (fk_par_ in spr_params.id%type, id_ in list_c.id%type);
 procedure rep_add_param (fk_rep_ in reports.id%type, fk_par_ in spr_params.id%type);
 procedure rep_del_param (fk_rep_ in reports.id%type, fk_par_ in spr_params.id%type);
 function have_sch(p_lsk in kart.lsk%type, p_counter in usl.counter%type) return number;
 procedure upd_krt_sch_state(lsk_ in kart.lsk%type);
 function set_krt_psch (dat_ in c_states_sch.dt1%type,
   fk_status_ in c_states_sch.fk_status%type, lsk_ in kart.lsk%type) return integer;
 function set_base_state_gen(l_set in number) return number;

 --проверка справочника redir_pay
 function check_redir_pay return number;
end utils;
/

create or replace package body scott.utils is
  function MONTH_NAME1(month_ NUMBER) RETURN varchar2 is
  begin
    if month_ = 1 then
      return 'Января';
    elsif month_ = 2 then
      return 'Февраля';
    elsif month_ = 3 then
      return 'Марта';
    elsif month_ = 4 then
      return 'Апреля';
    elsif month_ = 5 then
      return 'Мая';
    elsif month_ = 6 then
      return 'Июня';
    elsif month_ = 7 then
      return 'Июля';
    elsif month_ = 8 then
      return 'Августа';
    elsif month_ = 9 then
      return 'Сентября';
    elsif month_ = 10 then
      return 'Октября';
    elsif month_ = 11 then
      return 'Ноября';
    elsif month_ = 12 then
      return 'Декабря';
    else
      return null;
    end if;
  end;

  function MONTH_NAME(month_ NUMBER) RETURN VARCHAR2 is
  begin
    if month_ = 1 then
      return 'Январь';
    elsif month_ = 2 then
      return 'Февраль';
    elsif month_ = 3 then
      return 'Март';
    elsif month_ = 4 then
      return 'Апрель';
    elsif month_ = 5 then
      return 'Май';
    elsif month_ = 6 then
      return 'Июнь';
    elsif month_ = 7 then
      return 'Июль';
    elsif month_ = 8 then
      return 'Август';
    elsif month_ = 9 then
      return 'Сентябрь';
    elsif month_ = 10 then
      return 'Октябрь';
    elsif month_ = 11 then
      return 'Ноябрь';
    elsif month_ = 12 then
      return 'Декабрь';
    else
      return null;
    end if;
  end;

  function add_months_pr(mg_ in varchar2, cnt_ in number) return varchar2 is
  begin
    --возвращает в формате YYYYMM период назад или вперед от заданного
    return to_char(add_months(to_date(mg_||'01','YYYYMMDD'), cnt_),'YYYYMM');
  end;

  FUNCTION get_org_lsk(p_lsk IN kart.lsk%TYPE)
    RETURN NUMBER IS
  l_fk_org number;
  BEGIN
    --вернуть ID орг, по данному л.с.
    BEGIN
    SELECT s.id INTO l_fk_org
      FROM kart t, t_org s
      WHERE t.lsk=p_lsk
      AND t.reu=s.reu;
    EXCEPTION
      WHEN no_data_found THEN
         Raise_application_error(-20000, 'Не найден код РЭУ в Л/С:'||p_lsk);
    END;
  RETURN l_fk_org;
  END;

  FUNCTION get_nkom_pay_lsk(p_lsk IN kart.lsk%TYPE)
    RETURN c_comps.nkom%type IS
  l_nkom c_comps.nkom%type;
  l_org t_org.id%type;
  p_lsk2 kart.lsk%TYPE;
  BEGIN
    --вернуть № комп.который осуществляет ввод оплаты по данному фонду
    p_lsk2:=lpad(p_lsk,8,'0');
    l_org:=get_org_lsk(p_lsk2);
    begin
      select t.nkom into l_nkom
      from c_comps t where t.fk_org=l_org;
    exception
      when no_data_found then
         Raise_application_error(-20000, 'В справочнике c_comps, не найден № компьютера соответствующий Л/С:'||p_lsk);
    end;
    return l_nkom;
  END;

  function GET_LSK_BY_ADR(kul_ kart.kul%TYPE, nd_ kart.nd%TYPE, kw_ kart.kw%TYPE)
           RETURN VARCHAR2 is
  lsk_ kart.lsk%TYPE;
  begin
  --поиск лицевого по адресу
  -- выбираем 1 - из списка (если адреса в базе не уникальны)
  if kw_ is not null then
    select max(lsk) into lsk_ from kart
           where kul=kul_ and nd=nd_ and kw=kw_ and rownum=1;
  else
    select max(lsk) into lsk_ from kart
           where kul=kul_ and nd=nd_ and rownum=1;
  end if;
  return lsk_;
  end GET_LSK_BY_ADR;

  function GET_C_LSK_ID_BY_ADR(kul_ kart.kul%TYPE, nd_ kart.nd%TYPE, kw_ kart.kw%TYPE)
           RETURN VARCHAR2 is
  c_lsk_id_ kart.c_lsk_id%TYPE;
  begin
  --поиск лицевого по адресу
  -- выбираем 1 - из списка (если адреса в базе не уникальны)
  if kw_ is not null then
    select max(c_lsk_id) into c_lsk_id_ from kart
           where kul=kul_ and nd=nd_ and kw=kw_ and rownum=1;
  else
    select max(c_lsk_id) into c_lsk_id_ from kart
           where kul=kul_ and nd=nd_ and rownum=1;
  end if;
  return c_lsk_id_;
  end GET_C_LSK_ID_BY_ADR;

  function GET_LSK_BY_ADR2(house_id_ kart.house_id%TYPE, kw_ kart.kw%TYPE)
           RETURN VARCHAR2 is
  lsk_ kart.lsk%TYPE;
  begin
  --поиск лицевого по адресу
  -- выбираем 1 - из списка (если адреса в базе не уникальны)
  if kw_ is not null then
    select max(trim(lsk)) into lsk_ from kart k
           where k.house_id = house_id_ and kw=kw_ and rownum=1;
  else
    select min(trim(lsk)) into lsk_ from kart k
           where k.house_id = house_id_ and rownum=1;
  end if;
  return lsk_;
  end GET_LSK_BY_ADR2;

  function GET_LSK_BY_ADR3(house_id_ kart.house_id%TYPE, kw_ kart.kw%TYPE)
           RETURN kart.k_lsk_id%type is
    k_lsk_id_  number;
  begin
  --поиск k_lsk_id по адресу
    select max(k.k_lsk_id) into k_lsk_id_ from kart k
           where k.house_id = house_id_ and kw=kw_ and rownum=1;
  return k_lsk_id_;
  end GET_LSK_BY_ADR3;

  function GET_LSK_BY_ADR4(house_id_ kart.house_id%TYPE, kw_ kart.kw%TYPE)
           RETURN kart.c_lsk_id%type is
    c_lsk_id_  number;
  begin
  --поиск c_lsk_id по адресу
    select max(k.c_lsk_id) into c_lsk_id_ from kart k
           where k.house_id = house_id_ and kw=kw_ and rownum=1;
  return c_lsk_id_;
  end GET_LSK_BY_ADR4;

  function GET_K_LSK_ID_BY_LSK(lsk_ kart.lsk%TYPE)
           RETURN kart.k_lsk_id%type is
    k_lsk_id_  number;
  begin
  --поиск k_lsk_id по LSK
    select max(k.k_lsk_id) into k_lsk_id_ from kart k
           where k.lsk = lpad(lsk_,8,'0') and rownum=1;
  return k_lsk_id_;
  end GET_K_LSK_ID_BY_LSK;

  function GET_C_LSK_ID_BY_LSK(lsk_ kart.lsk%TYPE)
           RETURN kart.c_lsk_id%type is
    c_lsk_id_  number;
  begin
  --поиск c_lsk_id по LSK
    select max(k.c_lsk_id) into c_lsk_id_ from kart k
           where k.lsk = lpad(lsk_,8,'0') and rownum=1;
  return c_lsk_id_;
  end GET_C_LSK_ID_BY_LSK;

  function GET_ADR_BY_LSK(lsk_ kart.lsk%TYPE)
           RETURN varchar2 is
  adr_ varchar2(200);
  begin
  --поиск адреса по LSK
    select nvl(max(trim(t.name_reu)||', '||s.name||', '||ltrim(k.nd,'0')||'-'||ltrim(k.kw,'0')),
     'Адрес не найден!')
     into adr_
    from kart k, spul s, s_reu_trest t
      where k.reu=t.reu and k.kul=s.id and
       k.lsk=lpad(lsk_,8,'0');
  return adr_;
  end GET_ADR_BY_LSK;

  function ALLOW_FUNCT(fk_type_ in number)
           RETURN NUMBER is
  cnt_ number;
  begin
  --проверяет доступность пользователю заданной функции
    select count(*) into cnt_
      from v_cur_rlxfunct t
        where t.fk_type = fk_type_ and t.fk_funct is null;
    if cnt_ > 1 then
      RAISE_APPLICATION_ERROR(-20001,
            'Найдены дублирующиеся функции для роли, настройте роли!');
    end if;
  return cnt_;
  end;

  function ALLOW_EDIT_LSK(lsk_ kart.lsk%TYPE, cd_ in varchar2)
           RETURN NUMBER is
  cnt_ number;
  l_listtp u_listtp.id%type;
  begin
  select t.id into l_listtp from u_listtp t where t.cd='Тип разрешения';
  --проверяет можно ли пользователю редактировать лицевой счет
  if cd_ in ('доступ к карт.рэу', 'доступ к карт.площадь',
     'доступ к карт.статус') then
  --для РЭУ
   select count(*) into cnt_ from t_user u, c_users_perm p, kart k, u_list i
      where u.id=p.user_id and u.cd=user
      and k.lsk = lsk_ and p.fk_reu=k.reu and k.psch <> 8
      and i.id=p.fk_perm_tp and i.cd=cd_
      and i.fk_listtp=l_listtp;
  elsif cd_='доступ к пасп.столу' then
  --для Паспортного
   select count(*) into cnt_ from t_user u, c_users_perm p, kart k, u_list i
      where u.id=p.user_id and upper(u.cd)=upper(user)
      and k.lsk = lsk_ and p.fk_pasp_org=k.fk_pasp_org and k.psch <> 8
      and i.id=p.fk_perm_tp and i.cd=cd_
      and i.fk_listtp=l_listtp;
  elsif cd_='доступ к льготам' then
  --для редактирования льгот
   select count(*) into cnt_ from t_user u, c_users_perm p, kart k, u_list i
      where u.id=p.user_id and u.cd=user
      and k.lsk = lsk_ and p.fk_reu=k.reu and k.psch <> 8
      and i.id=p.fk_perm_tp and i.cd=cd_
      and i.fk_listtp=l_listtp;
  end if;
  return cnt_;
  end;

  -- разрешение править лицевой счет, по коду УК
  function ALLOW_EDIT_LSK_BY_REU(p_reu in varchar2, p_pasp_org in number, p_cd in varchar2)
           RETURN NUMBER is
  cnt_ number;
  l_listtp u_listtp.id%type;
  begin
--    TODO СДЕЛАТЬ ПРОВЕРКУ НА ЗАКРЫТЫЕ ЛС!!!!
  select t.id into l_listtp from u_listtp t where t.cd='Тип разрешения';
  --проверяет можно ли пользователю редактировать лицевой счет
  if p_cd in ('доступ к карт.рэу', 'доступ к карт.площадь',
     'доступ к карт.статус') then
  --для РЭУ
   select count(*) into cnt_ from t_user u, c_users_perm p, u_list i
      where u.id=p.user_id and u.cd=user
      and p.fk_reu=p_reu
      and i.id=p.fk_perm_tp and i.cd=p_cd
      and i.fk_listtp=l_listtp;
  elsif p_cd='доступ к пасп.столу' then
  --для Паспортного
   select count(*) into cnt_ from t_user u, c_users_perm p, u_list i
      where u.id=p.user_id and upper(u.cd)=upper(user)
      and p.fk_pasp_org=p_pasp_org
      and i.id=p.fk_perm_tp and i.cd=p_cd
      and i.fk_listtp=l_listtp;
  elsif p_cd='доступ к льготам' then
  --для редактирования льгот
   select count(*) into cnt_ from t_user u, c_users_perm p, u_list i
      where u.id=p.user_id and u.cd=user
      and p.fk_reu=p_reu
      and i.id=p.fk_perm_tp and i.cd=p_cd
      and i.fk_listtp=l_listtp;
  end if;
  return cnt_;
  end;

  function ALLOW_CR_NEW_LSK(lsk_ kart.lsk%TYPE)
           RETURN NUMBER is
  cnt_ number;
  begin
  --проверяет можно ли пользователю создавать лицевой счет
   select count(*) into cnt_ from t_user u, c_users_perm p, kart k, u_list i
      where u.id=p.user_id and u.cd=user
      and k.lsk = lsk_ and p.fk_reu=k.reu and k.psch <> 8
      and i.id=p.fk_perm_tp and i.cd='доступ к карт.рэу'; -- k.psch <> 8 (запрещено править старый фонд);
  return cnt_;
  end;

  function ALLOW_CHANGES_LSK(lsk_ kart.lsk%TYPE)
           RETURN NUMBER is
  cnt_ number;
  begin
  --проверяет можно ли пользователю проводить изменения начисления по л.с.
   select count(*) into cnt_ from t_user u, c_users_perm p, kart k, u_list i
      where u.id=p.user_id and u.cd=user
      and k.lsk = lsk_ and p.fk_reu=k.reu-- and k.psch <> 8
      and i.id=p.fk_perm_tp and i.cd='доступ к карт.рэу'; -- k.psch <> 8 (запрещено править старый фонд);
  return cnt_;
  end;

--генерация нового лицевого счета
FUNCTION GET_NEW_LSK(lsk_ in kart.lsk%TYPE, p_lsk in kart.lsk%TYPE) RETURN kart.lsk%TYPE IS
  lsk1_ kart.lsk%TYPE;
  cnt_  NUMBER;
  l_reu kart.reu%TYPE;
BEGIN
  --ред.31.07.12
  SELECT reu INTO l_reu FROM kart k WHERE k.lsk = lsk_;
  --поиск с учётом дырок
  lsk1_ := p_houses.find_unq_lsk(l_reu, p_lsk);
  IF lsk1_ IS NULL THEN
    --исчерпались максимальные лицевые в РЭУ,
    --тупо максимальный лицевой +1 в базе
    SELECT lpad(MAX(to_number(lsk)) + 1, 8, '0') INTO lsk1_ FROM kart k;
  END IF;
  RETURN lsk1_;
END;

--генерация нового лицевого счета по РЭУ
FUNCTION GET_NEW_LSK_BY_REU(p_reu kart.reu%TYPE) RETURN kart.lsk%TYPE IS
  l_lsk kart.lsk%TYPE;
  l_cnt  NUMBER;
BEGIN
  --ред.01.10.14
  --поиск с учётом дырок
  l_lsk := p_houses.find_unq_lsk(p_reu, null);
  IF l_lsk IS NULL THEN
    --исчерпались максимальные лицевые в РЭУ,
    --тупо максимальный лицевой +1 в базе
    SELECT lpad(MAX(to_number(lsk)) + 1, 8, '0') INTO l_lsk FROM kart k;
  END IF;
  RETURN l_lsk;
END;

  procedure ins_lg_doc (kart_pr_id_ in c_kart_pr.id%type)
  is
   seq_ number;
  begin
  --добавление нового документа по льготе
   select c_lg_docs_id.nextval into seq_ from dual;
   insert into c_lg_docs (id, c_kart_pr_id, main)
    values (seq_, kart_pr_id_, 0);
  --добавление новых льгот по умолчанию
   insert into c_lg_pr (c_lg_docs_id, spk_id, type)
    values (seq_, 1, 0);
   insert into c_lg_pr (c_lg_docs_id, spk_id, type)
    values (seq_, 1, 1);
  end;

  procedure del_lg_doc (c_lg_docs_id_ in c_lg_docs.id%type) is
  begin
  --удаление документа и каскадно - льгот
   delete from c_lg_docs d where d.id = c_lg_docs_id_;
  end;

  procedure count_krt_kpr (lsk_ in kart.lsk%type) is
  begin
  --ЗАЧЕМ НУЖНА ЭТА ФУНКЦИЯ?
  --ЕСЛИ КОЛ-ВО ПРОЖИВ. СЧИТАЕТСЯ В ТРИГГЕРЕ?
  --удалить после 01.09.2010
  Raise_application_error(-20000, 'ОШИБКА');
  --подсчет кол-ва проживающих, без коммита
    --кол-во льготников
  update kart k set ki=(select /*+ RULE */ count(distinct t.id) as cnt
    from c_kart_pr t, c_lg_docs d, c_lg_pr p
    where t.id=d.c_kart_pr_id and d.id=p.c_lg_docs_id and p.spk_id <> 1
      and t.lsk=lsk_
      and t.status <> 4 ) --без учета выбывших
      where k.lsk=lsk_;
  --кол-во проживающих
  update kart k set kpr=(select count(*)
    from c_kart_pr p where p.status in (1,2,3,5) and p.lsk=lsk_ and p.status <> 4) --без учета выбывших
    where k.lsk=lsk_; --но с учетом проживающих для Начисления

  update kart k set kpr_ot=(select count(*)
    from c_kart_pr p where p.status in (2) and p.lsk=lsk_ and p.status <> 4) --без учета выбывших
    where k.lsk=lsk_;
  update kart k set kpr_wr=(select count(*)
    from c_kart_pr p where p.status in (3) and p.lsk=lsk_ and p.status <> 4) --без учета выбывших
    where k.lsk=lsk_;
  end;

  function count_krt_kpr (user_id_ in number)
   return number is
   cnt_ number;
  begin
--чё за бред? перегруженная функция???
  --Проверка на возможность удалять USER_ID
   select sum(cnt) into cnt_ from (
    select count(*) as cnt from a_change a
      where a.user_id=user_id_
     union all
    select count(*) from c_change a
      where a.user_id=user_id_
     );
    return cnt_;
  end;

  function get_report_name (id_ in number)
   return varchar2 is
   result_ reports.name%TYPE;
  begin
  --Выдает наименование отчета
   select r.name into result_ from reports r where r.id=id_;
   return result_;
  end;

function get_sum_str_2(source in number) return varchar2 is
  result varchar2(300);
begin
  -- k - копейки
  if source < 1 then
    result := 'ноль ' ||
              ltrim(to_char(source,
                            '9,9,,9,,,,,,9,9,,9,,,,,9,9,,9,,,,9,9,,9,,,.99')) || 'k';
  else
    result := ltrim(to_char(source,
                            '9,9,,9,,,,,,9,9,,9,,,,,9,9,,9,,,,9,9,,9,,,.99')) || 'k';
  end if;

  -- t - тысячи; m - милионы; M - миллиарды;
  result := replace(result, ',,,,,,', 'eM');
  result := replace(result, ',,,,,', 'em');
  result := replace(result, ',,,,', 'et');
  -- e - единицы; d - десятки; c - сотни;
  result := replace(result, ',,,', 'e');
  result := replace(result, ',,', 'd');
  result := replace(result, ',', 'c');
  -- Удаление незначащих нулей
  result := replace(result, '0c0d0et', '');
  result := replace(result, '0c0d0em', '');
  result := replace(result, '0c0d0eM', '');

  -- Обработка сотен
  result := replace(result, '0c', '');
  result := replace(result, '1c', 'сто ');
  result := replace(result, '2c', 'двести ');
  result := replace(result, '3c', 'триста ');
  result := replace(result, '4c', 'четыреста ');
  result := replace(result, '5c', 'пятьсот ');
  result := replace(result, '6c', 'шестьсот ');
  result := replace(result, '7c', 'семьсот ');
  result := replace(result, '8c', 'восемьсот ');
  result := replace(result, '9c', 'девятьсот ');

  -- Обработка десятков
  result := replace(result, '1d0e', 'десять ');
  result := replace(result, '1d1e', 'одиннадцать ');
  result := replace(result, '1d2e', 'двенадцать ');
  result := replace(result, '1d3e', 'тринадцать ');
  result := replace(result, '1d4e', 'четырнадцать ');
  result := replace(result, '1d5e', 'пятнадцать ');
  result := replace(result, '1d6e', 'шестнадцать ');
  result := replace(result, '1d7e', 'семнадцать ');
  result := replace(result, '1d8e', 'восемнадцать ');
  result := replace(result, '1d9e', 'девятнадцать ');
  result := replace(result, '0d', '');
  result := replace(result, '2d', 'двадцать ');
  result := replace(result, '3d', 'тридцать ');
  result := replace(result, '4d', 'сорок ');
  result := replace(result, '5d', 'пятьдесят ');
  result := replace(result, '6d', 'шестьдесят ');
  result := replace(result, '7d', 'семьдесят ');
  result := replace(result, '8d', 'восемьдесят ');
  result := replace(result, '9d', 'девяносто ');

  -- Обработка единиц
  result := replace(result, '0e', '');
  result := replace(result, '5e', 'пять ');
  result := replace(result, '6e', 'шесть ');
  result := replace(result, '7e', 'семь ');
  result := replace(result, '8e', 'восемь ');
  result := replace(result, '9e', 'девять ');
  --
  result := replace(result, '1e.', 'один рубль ');
  result := replace(result, '2e.', 'два рубля ');
  result := replace(result, '3e.', 'три рубля ');
  result := replace(result, '4e.', 'четыре рубля ');
  result := replace(result, '1et', 'одна тысяча ');
  result := replace(result, '2et', 'две тысячи ');
  result := replace(result, '3et', 'три тысячи ');
  result := replace(result, '4et', 'четыре тысячи ');
  result := replace(result, '1em', 'один миллион ');
  result := replace(result, '2em', 'два миллиона ');
  result := replace(result, '3em', 'три миллиона ');
  result := replace(result, '4em', 'четыре миллиона ');
  result := replace(result, '1eM', 'один миллиард ');
  result := replace(result, '2eM', 'два миллиарда ');
  result := replace(result, '3eM', 'три миллиарда ');
  result := replace(result, '4eM', 'четыре миллиарда ');

  -- Обработка копеек
  result := replace(result, '11k', '11 копеек');
  result := replace(result, '12k', '12 копеек');
  result := replace(result, '13k', '13 копеек');
  result := replace(result, '14k', '14 копеек');
  result := replace(result, '1k', '1 копейка');
  result := replace(result, '2k', '2 копейки');
  result := replace(result, '3k', '3 копейки');
  result := replace(result, '4k', '4 копейки');

  -- Обработка названий групп
  result := replace(result, '.', 'рублей ');
  result := replace(result, 't', 'тысяч ');
  result := replace(result, 'm', 'миллионов ');
  result := replace(result, 'M', 'миллиардов ');
  result := replace(result, 'k', ' копеек');
  --
  return(result);
end get_sum_str_2;





 function f_order(str_ varchar2, len_ number) return varchar2 is
 begin
   --Функция для order by в запросах
   --возвращает только цифры из выражения
   return lpad(substr(str_,
                      1,
                      length(str_) -
                      nvl(length(ltrim(str_, '0123456789')), 0)),
               len_,
               '0');
 end;

 function f_order2(str_ varchar2) return varchar2 is
 begin
   --Функция для order by в запросах
   --возвращает только символы (не цифры из выражения),
   --для правильной сортировки
   --убирает пробелы
   return nvl(replace(ltrim(str_, '0123456789'),' ',''),'0');
 end;

 function f_ord2(str_ varchar2) return varchar2 is
 begin
   --Функция для order by в запросах
   --возвращает только символы (не цифры из выражения),
   --для правильной сортировки
   return replace(translate(str_, '0123456789', ' '), ' ');
 end;

 function f_ord3(p_str varchar2) return varchar2 is
  l_symb varchar2(1000);
  l_str varchar2(1000);
  l_at number;
 begin
   --Функция для order by в запросах
   --возвращает только символы (не цифры из выражения или знаки дроби /\-),
   --для правильной сортировки
   --а так же, убирает пробелы, НО не лишние символы (-,/,\,.) (нужны для сортировки)

  l_str:=trim(p_str);
  l_symb:=substr(f_ord2(l_str),1,1);
  --пытаемся найти первый нецифровой символ в строке кода (например дома)
  l_at:=instr(l_str, substr(l_symb,1));
  if l_at > 0 then
    return trim(substr(l_str, l_at, length(l_str)));
  else
    return null;
  end if;
 end;

 function f_ord_digit(p_str varchar2) return number is
  l_symb varchar2(1000);
  l_str varchar2(1000);
  l_at number;
 begin
  --Функция для order by в запросах
  --возвращает только цифры до знака отделения от корпуса дома, например 9а --> 9
  --или 9/1 --> 9
  --использовать две функции: order by f_ord_digit(nd), f_ord3(nd)
  l_str:=trim(p_str);
  l_symb:=substr(f_ord2(l_str),1,1);
  --пытаемся найти первый не цифровой символ в строке кода (например дома)
  l_at:=instr(l_str, substr(l_symb,1));
  if l_at > 0 then
    return trunc(substr(l_str, 1, l_at-1));
  else
    return trunc(l_str);
  end if;
 end;

 function add_months2(mg_ in varchar2, months_ in number) return varchar2 is
 begin
 --вернуть период на месяц вперёд-назад
  return to_char(add_months(to_date(mg_||'01','YYYYMMDD'), months_),'YYYYMM');
 end;

procedure prep_users_tree is
  l_fk_ses number;
begin
  --новая сессия
  --заменил fk_user_ на sessionid
  select USERENV('sessionid') into l_fk_ses from dual;

  -- вернуть Id сессии в глобальную переменную init.g_session_id
  -- для Java модуля. (вообще странно, использовать USERENV('sessionid')
  -- в таблицах для Директа и t_sess.id для Java TODO - сделать рефакторинг! ред.29.05.2018
  insert into t_sess
    (dat_create, fk_ses)
  values
    (sysdate, l_fk_ses)
  returning id into init.g_session_id;

  insert into tree_objects
    (id, obj_level, trest, reu, for_reu, kul, nd, main_id, fk_user, sel, fk_house, mg1, mg2, psch, tp_show)
    select id, obj_level, trest, reu, for_reu, kul, nd, main_id, l_fk_ses, sel, fk_house, mg1, mg2, psch, tp_show
      from tree_objects t
     where t.fk_user = -1; -- взять из шаблона, который генерится в итоговом: gen.prep_template_tree_objects    
  commit;
end;

procedure prep_users_par is
 fk_ses_ number;
begin
 --подготовка параметров сессии
 --заменил fk_user_ на sessionid
 select USERENV('sessionid') into fk_ses_ from dual;
 --подготовка домов для выбора пользователями
 --временные таблицы (temporary)
 delete from spr_par_ses t;
 delete from list_c t;

 insert into spr_par_ses
   (id, cd, parvc1, parn1, name, cdtp,
    pardt1, parent_id, npp, fk_ses)
   select
    t.id, cd, parvc1, parn1, name, cdtp,
    pardt1, parent_id, npp, fk_ses_
    from spr_params t where t.fk_parcdtp='FLT_REP';

--подготовка параметров сессии, типа списки
 for c in (select * from spr_params t where t.cdtp in (4,5) and t.sql_text is not null)
 loop
   fill_list_c(c.id);
 end loop;

 commit;
end;

function concatenate(v_rownum    number,
                     v_string    varchar2,
                     v_delimiter varchar2 default null,
                     v_call_id number default 1)
  return varchar2 is
  type string4000_array_type is table of varchar2(4000) index by binary_integer;
  g_concatenated_string_array string4000_array_type;
begin
  --функция для превращения колонки в строку
  if v_rownum = 1 then
    g_concatenated_string_array(v_call_id) := v_string;
  else
    g_concatenated_string_array(v_call_id) := g_concatenated_string_array(v_call_id) ||
                                              v_delimiter || v_string;
  end if;
  return g_concatenated_string_array(v_call_id);
end;

-- проверка карточки лс на возможные ошибки
-- вызывается из Delphi:TForm_kart.save_changes(ask_: Integer);
function tst_krt(lsk_ in kart.lsk%type, var_ in number) return varchar2 is
  cnt_ number;
  last_id_ number;
  prop_dt_ date;
  l_cd v_lsk_tp.cd%type;
  kart_rec kart%rowtype;
begin
--тип счета
select k.* into kart_rec
 from kart k where k.lsk=lsk_;

select tp.cd into l_cd
 from v_lsk_tp tp where tp.id=kart_rec.fk_tp;


--проверки только для основных счетов
if l_cd='LSK_TP_MAIN' then
  --для временной регистрации не проверяется
  select nvl(count(*),0) into cnt_ from (
   select k.id,
   max(t.dt2) keep (dense_rank first order by nvl(t.dt1, to_date('01011900','DDMMYYYY')) desc) as dat
   from c_kart_pr k, c_states_pr t, u_list u, c_status_pr pr
   where k.lsk=lsk_
   and k.id=t.fk_kart_pr and t.fk_status=pr.id and  pr.fk_tp=u.id and u.cd='PROP'
   group by k.id) a
   where a.dat is not null;
   if cnt_ > 0 then
      --найден "пустой" период в статусах прописки(надо чтобы все дни текущего периода были заполнены)
      if var_=1 then
        update kart k set k.fk_err=1 where k.lsk=lsk_ and k.psch not in (8,9);
      end if;
      return 'Дата последнего периода статуса прописки проживающего должна быть открытой!';
   end if;

  select nvl(count(*),0) into cnt_ from c_kart_pr k, c_states_pr c
    where k.lsk=lsk_
    and k.id=c.fk_kart_pr
    and exists
    (select * from c_states_pr t
        where t.fk_kart_pr=k.id and t.fk_status=c.fk_status
    and t.id <> c.id and
    (nvl(t.dt1, to_date('01011900','DDMMYYYY'))
        between nvl(c.dt1, to_date('01011900','DDMMYYYY'))
        and nvl(c.dt2, to_date('01012900','DDMMYYYY'))
      or nvl(t.dt2, to_date('01012900','DDMMYYYY'))
        between nvl(c.dt1, to_date('01011900','DDMMYYYY'))
        and nvl(c.dt2, to_date('01012900','DDMMYYYY'))
    ));
   if cnt_ > 0 then
      if var_=1 then
        update kart k set k.fk_err=2 where k.lsk=lsk_;
      end if;
      return 'Период действия статуса проживающего пересекается с другим периодом!';
   end if;
end if;

 -- проверки разделенного ЕЛС
 if kart_rec.divided=1 then 
   select count(*) into cnt_ 
     from c_kart_pr t where t.lsk=lsk_ and t.use_gis_divide_els=1;
   if cnt_=0 then
      return 'В разделенном лиц.счете должны быть указаны документ или СНИЛС должника и включено "для ГИС ЖКХ"!';
   elsif cnt_>1 then
      return 'В разделенном лиц.счете установлена отметка "для ГИС ЖКХ" более чем у одного собственника';
   end if;  
 else
   select count(*) into cnt_ 
     from c_kart_pr t where t.lsk=lsk_ and t.use_gis_divide_els=1;
   if cnt_>=1 then
      return 'В разделенном лиц.счете установлена отметка "для ГИС ЖКХ" у собственника, которая не будет использована';
   end if;  
 end if;
 
   --ошибок нет
   if var_=1 then
     update kart k set k.fk_err=0 where k.lsk=lsk_;
   end if;
   return null;
end;

procedure set_kpr(lsk_ in kart.lsk%type) is
   cursor cur_params is
     select * from params;
   rec_params cur_params%rowtype;
   dat_       date;
 begin
   --кол-во проживающих
   --Установка кол-ва прожив в л.с. по c_kart_pr
   --для тех услуг, которые не используют кол-во прожив из c_charge_prep
   open cur_params;
   fetch cur_params
     into rec_params;
   close cur_params;
   dat_ := to_date(rec_params.period || '15', 'YYYYMMDD');
   if lsk_ is not null then
     --ред 24.06.11 льготники отключены
     if nvl(rec_params.is_fullmonth, 0) = 0 then
       -- Кис:
       update kart k
          set kpr =
               (select nvl(count(*),0)
                  from c_kart_pr t
                 where t.lsk = lsk_
                   and not ((t.status = 4 and --если выписан до 15 то не считать
                        nvl(t.dat_ub, to_date('19000101', 'YYYYMMDD')) <= --если нет даты выписки, то как будто бы выписан давно (в 1900 году)))
                        dat_) or
                        t.status in (1, 5) and --если прописан после 15 то не считать
                        nvl(t.dat_prop, to_date('19000101', 'YYYYMMDD')) >= --если нет даты прописки, то как будто бы прописан давно (в 1900 году)))
                        dat_)
                   and t.status not in (3,6,7)), --не берём 6 код (временно прожив) ред.24.05.12 -- не берем код 3 - временно зарег, ред. 14.12.17, 7 код ред.30.09.2019
               --без учета выбывших
              kpr_ot =
               (select count(*)
                  from c_kart_pr t
                 where t.status in (2)
                   and t.lsk = lsk_),
              kpr_wr =
               (select count(*) --ред 24.12.12 --разделил временно зарег. и временно пропис.
                  from c_kart_pr t
                 where t.status in (3)
                   and t.lsk = lsk_),
              kpr_wrp =
               (select count(*)
                  from c_kart_pr t
                 where t.status in (6)
                   and t.lsk = lsk_)
        where k.lsk = lsk_;
     else
       -- Полыс:
       update kart k
          set kpr =
               (select count(*)
                  from c_kart_pr t
                 where t.lsk = lsk_
                   and t.status not in (4,6,3,7)), -- убрал из подсчета 3 статус (В.З.)
               --без учета выбывших
              kpr_ot =
               (select count(*)
                  from c_kart_pr t
                 where t.status in (2)
                   and t.lsk = lsk_),
              kpr_wr =
               (select count(*) --ред 24.12.12 --разделил временно зарег. и временно пропис.
                  from c_kart_pr t
                 where t.status in (3)
                   and t.lsk = lsk_),
              kpr_wrp =
               (select count(*)
                  from c_kart_pr t
                 where t.status in (6)
                   and t.lsk = lsk_)
        where k.lsk = lsk_;
     end if;
   else
     Raise_application_error(-20000, 'Код не поддерживается, обратиться к программисту');
     --ред 24.06.11 льготники отключены
     --кол-во проживающих
     -- Кис:
     if nvl(rec_params.is_fullmonth, 0) = 0 then
       update kart k
          set kpr =
               (select count(*)
                  from c_kart_pr t
                 where t.lsk = k.lsk
                   and not ((t.status = 4 and --если выписан до 15 то не считать
                        nvl(t.dat_ub, to_date('19000101', 'YYYYMMDD')) <= --если нет даты выписки, то как будто бы выписан давно (в 1900 году)))
                        dat_) or
                        t.status in (1, 5) and --если прописан после 15 то не считать
                        nvl(t.dat_prop, to_date('19000101', 'YYYYMMDD')) >= --если нет даты прописки, то как будто бы прописан давно (в 1900 году)))
                        dat_)
                   and t.status not in (6)),
               --без учета выбывших
              kpr_ot =
               (select count(*)
                  from c_kart_pr t
                 where t.status in (2)
                   and t.lsk = k.lsk),
              kpr_wr =
               (select count(*) --ред 24.12.12 --разделил временно зарег. и временно пропис.
                  from c_kart_pr t
                 where t.status in (3)
                   and t.lsk = k.lsk),
              kpr_wrp =
               (select count(*)
                  from c_kart_pr t
                 where t.status in (6)
                   and t.lsk = k.lsk);
     else
       -- Полыс:
       update kart k
          set kpr =
               (select count(*)
                  from c_kart_pr t
                 where t.lsk = k.lsk
                   and t.status not in (4,6,3)), -- убрал из подсчета 3 статус (В.З.)
               --без учета выбывших
              kpr_ot =
               (select count(*)
                  from c_kart_pr t
                 where t.status in (2)
                   and t.lsk = k.lsk),
              kpr_wr =
               (select count(*) --ред 24.12.12 --разделил временно зарег. и временно пропис.
                  from c_kart_pr t
                 where t.status in (3)
                   and t.lsk = k.lsk),
              kpr_wrp =
               (select count(*)
                  from c_kart_pr t
                 where t.status in (6)
                   and t.lsk = k.lsk);
     end if;
   end if;

 end;


procedure set_krt_adm (lsk_ in c_kart_pr.lsk%type) is
  fk_kart_pr_ c_states_pr.fk_kart_pr%type;
begin
 --установить квартиросъемщика в лицевой счет
fk_kart_pr_:=null;
     for c in (select c.fk_kart_pr from c_states_pr c, c_status_pr pr, u_list u, params m where  --найти квартиросъемщика, прописанного
                  last_day(to_date(m.period||'01','YYYYMMDD')) --на последнюю дату месяца
                  between nvl(c.dt1(+), to_date('01011900','DDMMYYYY')) and
                          nvl(c.dt2(+), to_date('01012900','DDMMYYYY'))
                         and c.fk_status in (1) -- ред.13.05.2019 выявлено, что некорректно использовать 4 статус, получили искажение собственников в карточках!
                         --and c.fk_status in (1,4) -- нельзя делать статус 5 (так как устанавливается квартиросъемщик, всё серъёзно))) - ред. давно!
                                                  -- может быть выписанный (статус 4) ред. - 25.03.2019
                         and u.cd='PROP'
                         and c.fk_status=pr.id
                         and pr.fk_tp=u.id
                   and exists
                   (select *
                      from c_kart_pr p, relations s
                     where p.relat_id = s.id
                       and s.fk_relat_tp = 1
                       and p.lsk=lsk_
                       and p.id=c.fk_kart_pr)
                   order by nvl(c.dt1(+), to_date('01011900','DDMMYYYY')) desc --найти последнего прописавшегося квартиросъемщ.
                 )
  loop
  fk_kart_pr_:=c.fk_kart_pr;
  --добавили нового квартиросъемщика
  update kart k
     set k.fio = (select p.fio
                     from c_kart_pr p
                    where p.id=c.fk_kart_pr),
         k.k_fam = (select p.k_fam
                     from c_kart_pr p
                    where p.id=c.fk_kart_pr),
         k.k_im = (select p.k_im
                     from c_kart_pr p
                    where p.id=c.fk_kart_pr),
         k.k_ot = (select p.k_ot
                     from c_kart_pr p
                    where p.id=c.fk_kart_pr)
   where k.lsk = lsk_;
   exit;
   end loop;
end;

procedure set_krt_adm2 (fk_kart_pr_ in c_kart_pr.id%type) is
 lsk_ c_kart_pr.lsk%type;
 begin
 --перегруженная процедура
  select lsk into lsk_ from c_kart_pr c where c.id=fk_kart_pr_;
  set_krt_adm(lsk_);

end;

procedure upd_c_kart_pr_state(fk_kart_pr_ in c_kart_pr.id%type) is
i number;
time_ date;
ccc number;
  begin
  time_:=sysdate;
  --обновить признак статуса в карточке проживающего
    if fk_kart_pr_ is not null then
  --ред 10.11.2011
    --по данному проживающему (из триггера)
    update c_kart_pr k
       set k.dat_prop =
           (select max(a.dt1)
              from c_states_pr a, u_list u, c_status_pr pr
             where a.fk_status=pr.id and pr.fk_tp=u.id
               and u.cd = 'PROP'
               and a.fk_kart_pr = fk_kart_pr_
               and a.fk_status in (1, 5)),
           k.dat_ub  =
           (select max(a.dt1)
              from c_states_pr a, u_list u, c_status_pr pr
             where a.fk_status=pr.id and pr.fk_tp=u.id
               and u.cd = 'PROP'
               and a.fk_kart_pr = fk_kart_pr_
               and a.fk_status = 4 --если будет найдена дата убытия >= даты прописки
             having max(a.dt1) >= (select max(nvl(a.dt1, to_date('01011900', 'DDMMYYYY')))
                                    from c_states_pr a, u_list u, c_status_pr pr
                                     where a.fk_status=pr.id and pr.fk_tp=u.id
                                     and u.cd = 'PROP'
                                     and a.fk_kart_pr = fk_kart_pr_
                                     and a.fk_status in (1, 5))),
           k.status  =
           (select max(case
                         when t.fk_status is null and t2.fk_status is null then
                          4
                         when t.fk_status in (1, 5) and t2.fk_status = 2 --постоянно зарег. и временно отсут.
                          then
                          2
                         when t.fk_status = 4 and t2.fk_status in (3) --выбыл. и временно зареган.))
                          then
                          3
                         when t.fk_status is null and t2.fk_status in (3) --временно зарег. и необяз статус прописки
                          then
                          3
                         when t.fk_status = 4 and t2.fk_status in (6) --выбыл. и временно прожив.))
                          then
                          6
                         when t.fk_status is null and t2.fk_status in (6) --временно прожив. и необяз статус прописки
                          then
                          6
                         when t.fk_status is null and t2.fk_status = 2 --временно отсут. и нет обязат. статуса прописки
                          then
                          2
                         when t.fk_status is null and t2.fk_status is null then
                          4
                         else
                          t.fk_status
                       end) as status --если совсем ошибочно периоды статусов установлены, принять как временно остутств.
              from c_kart_pr c,
                   (select a.fk_kart_pr,
                           a.fk_status,
                           nvl(a.dt1, to_date('01011900', 'DDMMYYYY')) as dt1,
                           nvl(a.dt2, to_date('01012900', 'DDMMYYYY')) as dt2
                      from c_states_pr a, u_list u, params p, c_status_pr pr
                     where a.fk_status=pr.id and pr.fk_tp=u.id
                       and last_day(to_date(p.period || '01', 'YYYYMMDD')) between
                           nvl(a.dt1, to_date('01011900', 'DDMMYYYY')) and nvl(a.dt2, to_date('01012900', 'DDMMYYYY'))
                       and u.cd = 'PROP'
                       and a.fk_kart_pr = fk_kart_pr_) t,
                   (select a.fk_kart_pr,
                           a.fk_status,
                           nvl(a.dt1, to_date('01011900', 'DDMMYYYY')) as dt1,
                           nvl(a.dt2, to_date('01012900', 'DDMMYYYY')) as dt2
                      from c_states_pr a, u_list u, params p, c_status_pr pr
                     where a.fk_status=pr.id and pr.fk_tp=u.id
                       and last_day(to_date(p.period || '01', 'YYYYMMDD')) between
                           nvl(a.dt1, to_date('01011900', 'DDMMYYYY')) and nvl(a.dt2, to_date('01012900', 'DDMMYYYY'))
                       and u.cd = 'PROP_REG'
                       and a.fk_kart_pr = fk_kart_pr_) t2
             where c.id = fk_kart_pr_
               and c.id = t.fk_kart_pr(+)
               and c.id = t2.fk_kart_pr(+))
     where k.id = fk_kart_pr_;
--ред 21.10.2011
/*    update c_kart_pr k set k.dat_prop =
     (select max(a.dt1) from c_states_pr a, u_list u
              where u.id=a.fk_tp
              and u.cd='PROP'
              and a.fk_kart_pr=fk_kart_pr_
              and a.fk_status in (1,5)),
     k.dat_ub =(select max(a.dt1) from c_states_pr a, u_list u
              where u.id=a.fk_tp
              and u.cd='PROP'
              and a.fk_kart_pr=fk_kart_pr_
              and a.fk_status=4  --если будет найдена дата убытия >= даты прописки
              having max(a.dt1) >=
                (select max(nvl(a.dt1, to_date('01011900','DDMMYYYY'))) from c_states_pr a, u_list u
              where u.id=a.fk_tp
              and u.cd='PROP'
              and a.fk_kart_pr=fk_kart_pr_
              and a.fk_status in (1,5))
              )
     where k.id=fk_kart_pr_;*/
   else
   --ОЧЕНЬ МЕДЛЕННО ВЫПОЛНЯЕТСЯ...НЕ СМОГ НИЧЕГО ЛУЧШЕ ПРИДУМАТЬ...
   --по всем проживающим (после перехода)
   i:=0;
   for c in (select distinct t.fk_kart_pr
        from c_states_pr t, u_list u, c_status_pr pr where t.fk_status=pr.id and pr.fk_tp=u.id
          and (t.dt1 is not null or t.dt2 is not null)
          )
   loop
     --рекурсией вызываем себя же...
     upd_c_kart_pr_state(c.fk_kart_pr);
 --commit каждые 100 записей- иначе out of memory error (oracle падает)
     i:=i+1;
     if i >= 99 then
       i:=0;
--       logger.log_(null, c.fk_kart_pr);
       commit;
     end if;
   end loop;
   commit;
   logger.log_(time_, 'upd_c_kart_pr_state');
   end if;
  end;

function add_list(cdtp_ in u_listtp.cd%type, cd_ in u_list.cd%type,
   name_ in u_list.name%type) return number is
sel_id_ number;
tp_ number;
begin
--добавление новых реквизитов в справочник
 select t.id into tp_ from
  u_listtp t where t.cd=cdtp_;

insert into u_list
  (cd, name, fk_listtp, npp)
  values
  (cd_, name_, tp_, null)
  returning id into sel_id_;
 return sel_id_;
 --без коммита
end;

procedure add_usl(uslm_ in usl.uslm%type, prefix_ in varchar2,
 name_ in varchar2, name2_ in usl.nm2%type, cd_ in usl.cd%type,
 price_ in prices.summa%type, org_ in nabor.org%type,
 koeff_ in nabor.koeff%type, norm_ in nabor.norm%type,
 usl_koeff_ in usl.usl%type, usl_norm_ in usl.usl%type,
 usl_org_ in usl.usl%type
 ) is
 uslm2_ usl.uslm%type;
  type usl_rec is record
  (
    usl_ usl.usl%type,
    usl_order usl.usl_order%type,
    npp usl.npp%type
  );
  usl_rec_ usl_rec;
  cnt_ number;
  nm1_ usl.nm1%type;
begin
--Создание новой главной услуги
if uslm_ is null then
  select lpad(to_char(max(uslm)+1),3,'0') as uslm into uslm2_
     from uslm u;
  insert into uslm
    (uslm, nm1)
    values
    (uslm2_, name_);
  nm1_:=name_;
else
  uslm2_:=uslm_;
  select u.nm1 as nm1 into nm1_
     from uslm u where u.uslm=uslm_;
end if;

--Создание новой дочерней услуги
select lpad(to_char(max(usl)+1),3,'0'), nvl(max(u.usl_order),0)+1,
 nvl(max(u.npp),0)+1 into usl_rec_
 from usl u;

select nvl(count(*),0) into cnt_ from nabor n where n.usl=usl_rec_.usl_;

if cnt_ <> 0 then
   Raise_application_error(-20000, 'Данная услуга, usl='||usl_rec_.usl_||', уже существует в справочниках, добавление невозможно!');
end if;

insert into usl
  (uslm, usl, kartw, kwni, lpw, ed_izm, nm, nm1,
   usl_p, sptarn, usl_type,
   usl_plr, usl_norm, typ_usl,
   usl_order,
   usl_type2, usl_subs, nm2,
   cd, npp, fk_calc_tp, uslg,
   counter, have_vvod, n_progs,
   fk_usl_pen, can_vv, is_iter)
select
  uslm2_, usl_rec_.usl_,
   'N'||prefix_||'_' as kartw,
   'I'||prefix_ as kwni,
   'L'||prefix_ as lpw,
   'точ.',
   name_ as nm,
   nm1_ as nm1,
   usl_rec_.usl_ as usl_p,
   0 as sptarn,
   0 as usl_type,
   0 as usl_plr,
   0 as usl_norm,
   0 as typ_usl,
   usl_rec_.usl_order as usl_order,
   0 as usl_type2,
   0 as usl_subs,
   name2_ as nm2,
   cd_ as cd,
   usl_rec_.npp,
   null as fk_calc_tp_,
   null as uslg_,
   null as counter,
   null as have_vvod,
   null as n_progs,
   usl_rec_.usl_ as fk_usl_pen,
   0 as can_vv,
   0 as is_iter
   from dual;


insert into prices
  (usl, summa, summa2)
values
  (usl_rec_.usl_, price_, null);

insert into c_spk_usl
  (spk_id, usl_id, koef, dop_pl, prioritet, charge_part, limit_part)
select distinct
  spk_id, usl_rec_.usl_, 0 as koef, null as dop_pl, null as prioritet,
   null as charge_part, null as limit_part from c_spk_usl c;

insert into usl_bills
  (id, usl_id, mg1, mg2, is_vol, fk_bill_var)
values
  (usl_rec_.usl_, usl_rec_.usl_, '000000', '999999', 1, 1);

commit;

--добавить поля в таблицы
execute immediate 'alter table EXPKARTW add N'||prefix_||'_ number(8,2)';
execute immediate 'alter table EXPKWNI add I'||prefix_||' number(8,2)';
execute immediate 'alter table EXPPRIVS add L'||prefix_||' number(8,2)';

end;

--добавить несуществующие поля в таблицы выгрузок
procedure usl_add_flds is
l_cnt number;
begin

dbms_output.enable;

select nvl(count(*),0) into l_cnt
from (
select count(*) from usl t
  group by t.kartw
  having count(*)>1);
if l_cnt > 0 then
  dbms_output.put_line('Найдены дубликаты поля usl.kartw!');
  Raise_application_error(-20000, 'Найдены дубликаты поля usl.kartw!');
end if;

select nvl(count(*),0) into l_cnt
from (
select count(*) from usl t
  group by t.kwni
  having count(*)>1);
if l_cnt > 0 then
  dbms_output.put_line('Найдены дубликаты поля usl.kwni!');
  Raise_application_error(-20000, 'Найдены дубликаты поля usl.kwni!');
end if;

select nvl(count(*),0) into l_cnt
from (
select count(*) from usl t
  group by t.lpw
  having count(*)>1);
if l_cnt > 0 then
  dbms_output.put_line('Найдены дубликаты поля usl.lpw!');
  Raise_application_error(-20000, 'Найдены дубликаты поля usl.lpw!');
end if;

for c in (select trim(t.kartw) as kartw, trim(t.kwni) as kwni, trim(t.lpw) as lpw from usl t)
loop
begin
  execute immediate 'alter table EXPKARTW add '||c.kartw||' number(8,2)';
exception
  when others then
  dbms_output.put_line('Возможно уже есть поле:'||c.kartw||' в таблицу expkartw:');
  dbms_output.put_line('ERRcode - '||SQLCODE||' -ERRmsg- '||SQLERRM);
end;

begin
  execute immediate 'alter table EXPKWNI add '||c.kwni||' number(8,2)';
exception
  when others then
  dbms_output.put_line('Возможно уже есть поле:'||c.kwni||' в таблицу expkartw:');
  dbms_output.put_line('ERRcode - '||SQLCODE||' -ERRmsg- '||SQLERRM);
end;

begin
  execute immediate 'alter table EXPPRIVS add '||c.lpw||' number(8,2)';
exception
  when others then
  dbms_output.put_line('Возможно уже есть поле:'||c.lpw||' в таблицу expkartw:');
  dbms_output.put_line('ERRcode - '||SQLCODE||' -ERRmsg- '||SQLERRM);
end;

dbms_output.disable;

end loop;

end;

-- удалить лиц.счет
function del_lsk(lsk_ in kart.lsk%type) return varchar2 is
  l_mg  params.period%type;
  l_cnt number;
begin
  --удаление лицевого счета
  select p.period into l_mg from params p;

  select nvl(count(*), 0)
    into l_cnt
    from saldo_usl t
   where t.lsk = lsk_
     and t.mg <= l_mg;
  if l_cnt > 0 then
    return 'Лицевой счет имеет историю в сальдо, удаление не допустимо!';
  end if;

  select nvl(count(*), 0)
    into l_cnt
    from c_chargepay t
   where t.lsk = lsk_
     and t.period < l_mg;
  if l_cnt > 0 then
    return 'Лицевой счет имеет историю в оборотах, удаление не допустимо!';
  end if;

  begin
    delete from nabor t where t.lsk = lsk_;
    delete from c_states_sch t where t.lsk = lsk_;
    delete from c_kart_pr t where t.lsk = lsk_;
    delete from saldo_usl t where t.lsk = lsk_;
    delete from c_chargepay t
     where t.lsk = lsk_
       and t.period = l_mg;
    delete from c_kwtp t where t.lsk = lsk_;
    delete from c_charge t where t.lsk = lsk_; -- ред. 13.03.2020 -- пипец не стояло удаление! привело к несогласованности a_charge2 и arch_charges по удаленнным и заново восстановленным счетам, по которым было начисление
    delete from c_penya t where t.lsk = lsk_;
    delete from c_pen_corr t where t.lsk = lsk_;
    delete from c_pen_cur t where t.lsk = lsk_;
    delete from kart t where t.lsk = lsk_;
    
    -- добавил удаление из архивов (вдруг были уже сформированы архивы по этому лс), ред 17.04.19
    delete from a_penya t
     where t.lsk = lsk_
       and t.mg = l_mg;
    delete from c_chargepay t
     where t.lsk = lsk_
       and t.period = l_mg;
    delete from arch_kart t
     where t.lsk = lsk_
       and t.mg = l_mg;
    delete /*+ INDEX (a A_NABOR2_I)*/
    from a_nabor2 a
     where a.lsk = lsk_
       and l_mg between a.mgFrom and a.mgTo;
    delete from a_kwtp a
     where a.lsk = lsk_
       and a.mg = l_mg;
    delete from a_kwtp_mg a
     where a.lsk = lsk_
       and a.mg = l_mg;
    delete from a_kwtp_day a
     where a.lsk = lsk_
       and a.mg = l_mg;
    delete /*+ INDEX (a A_CHARGE2_I)*/
    from a_charge2 a
     where a.lsk = lsk_
       and l_mg between a.mgFrom and a.mgTo;
    delete from a_change a
     where a.lsk = lsk_
       and a.mg = l_mg;
    delete from a_kart_pr2 a
     where a.lsk = lsk_
       and l_mg between a.mgfrom and a.mgTo;
    delete from a_lg_docs c
     where c.mg = l_mg
       and exists (select *
              from c_kart_pr p
             where p.lsk = lsk_
               and p.id = c.c_kart_pr_id);
    delete from a_pen_corr a
     where a.lsk = lsk_
       and a.mg = l_mg;
    delete from a_pen_cur a
     where a.lsk = lsk_
       and a.mg = l_mg;
    delete from arch_charges a
     where a.lsk = lsk_
       and a.mg = l_mg;
    delete from arch_changes a
     where a.lsk = lsk_
       and a.mg = l_mg;
    delete from arch_subsidii a
     where a.lsk = lsk_
       and a.mg = l_mg;
    delete from arch_privs a
     where a.lsk = lsk_
       and a.mg = l_mg;
    delete from a_charge_prep2 a
     where a.lsk = lsk_
       and l_mg between a.mgFrom and a.mgTo;
  
  exception
    when others then
      return 'Лицевой счет используется, удаление не допустимо!';
  end;
  commit;
  return null;
end;

-- удалить лиц.счет без проверок
function del_lsk_wo_check(lsk_ in kart.lsk%type) return varchar2 is
  l_mg params.period%type;
  l_cnt number;
begin
  --удаление лицевого счета
  select p.period into l_mg from params p;

  begin
  delete from nabor t where t.lsk=lsk_;
  delete from c_states_sch t where t.lsk=lsk_;
  delete from c_kart_pr t where t.lsk=lsk_;
  delete from saldo_usl t where t.lsk=lsk_;
  delete from c_chargepay t where t.lsk=lsk_ and t.period=l_mg;
  delete from c_kwtp t where t.lsk=lsk_;
  delete from c_charge t where t.lsk=lsk_; -- ред. 13.03.2020 вернул удаление начисления! иначе несогласованность таблиц a_charge2 и arch_charges!
  delete from kart t where t.lsk=lsk_;

  exception when others then
    return 'Лицевой счет используется, удаление не допустимо!';
  end;
  commit;
  return null;
end;

procedure del_usl(usl_ in usl.usl%type) is
begin
  --удаление услуги
  delete from nabor t where t.usl=usl_;
  delete from usl_bills t where t.usl_id=usl_;
  delete from c_spk_usl t where t.usl_id=usl_;
  delete from spr_tarif t where t.usl=usl_;
  delete from prices t where t.usl=usl_;
  delete from usl t where t.usl=usl_;
  commit;
end;

procedure del_uslm(uslm_ in usl.uslm%type) is
begin
  --удаление главной услуги
  delete from uslm t where t.uslm=uslm_;
  commit;
end;

procedure cp_price(err_ out number, err_str_ out varchar2,
 usl_ in prices.usl%type, fk_org_src_ in prices.fk_org%type,
 fk_org_dst_ in prices.fk_org%type) is
 cnt_ number;
begin
 err_:=0;
--копирование расценок из орг. в орг.
  select nvl(count(*),0) into cnt_
    from prices t where t.fk_org=fk_org_dst_ and t.usl=usl_;
  if cnt_ = 0 then
    delete from prices t where t.fk_org=fk_org_dst_ and t.usl=usl_;
    insert into prices
       (usl, summa, summa2, fk_org, summa3)
    select usl_, summa, summa2, fk_org_dst_ as fk_org, summa3
     from prices t
     where t.usl=usl_ and (fk_org_src_=0 and t.fk_org is null
      or fk_org_src_ <> 0 and t.fk_org=fk_org_src_);
  else
    err_:=1;
    err_str_:='Расценка уже существует в данной организации!';
  end if;
--коммит в программе
end;

procedure del_price(usl_ in prices.usl%type, fk_org_ in prices.fk_org%type) is
begin
--удаление индивидуальных расценок по УК
  delete from prices t where t.fk_org=fk_org_ and t.usl=usl_;

end;

 function set_int_param(l_cd spr_params.cd%type,
     l_val spr_params.parn1%type) return spr_params.id%type is
 l_cdtp number;
 l_id spr_params.id%type;
 begin
   --устанавливает значение параметра Number (странно что только одна эта ф-ция, а где остальные?)
   --если параметра нет - создает его
   begin
   select s.cdtp into l_cdtp
          from spr_params s where upper(s.cd)=upper(l_cd);
   if nvl(l_cdtp,0) <> 0 then
      raise_application_error(-20001,
                              'Параметр - '||l_cd||' не является NUMBER типом!');
   end if;
    exception
    when NO_DATA_FOUND then
    --создает параметр
     insert into spr_params
       (cd, parn1, cdtp)
     values
       (l_cd, l_val, 0)
     returning id into l_id;
/*
TODO: owner="lev" created="10.12.2013"
text="Убрал коммиты на фиг"
*/
--     commit;
     return l_id;
   end;
   --обновляет параметр значением
   update spr_params t
    set t.parn1=l_val
    where t.cd=l_cd
    returning t.id into l_id;
/*
TODO: owner="lev" created="10.12.2013"
text="Убрал коммиты на фиг"
*/
--    commit;
    return l_id;
 end;

 function get_int_param(cd_ varchar2) return spr_params.parn1%type is
 cdtp_ number;
 result_ spr_params.parn1%type;
 begin
   --возращает значение параметра Number
   begin
   select s.parn1, s.cdtp into result_, cdtp_
          from spr_params s where upper(s.cd)=upper(cd_);
   if nvl(cdtp_,0) <> 0 then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не является NUMBER типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не зарегистрирован!');
   end;
   return result_;
 end;

 function getS_int_param(cd_ varchar2) return spr_params.parn1%type is
 cdtp_ number;
 result_ spr_params.parn1%type;
 fk_ses_ number;
 begin
   select USERENV('sessionid') into fk_ses_ from dual;
   --для сессии
   --возращает значение параметра Number
   begin
   select s.parn1, s.cdtp into result_, cdtp_
          from spr_par_ses s
           where s.fk_ses=fk_ses_ and upper(s.cd)=upper(cd_);
   if nvl(cdtp_,0) <> 0 then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не является NUMBER типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не зарегистрирован для sessionId='||fk_ses_);
   end;
   return result_;
 end;

 function get_bool_param(cd_ varchar2) return spr_params.parn1%type is
 cdtp_ number;
 result_ spr_params.parn1%type;
 begin
   --возращает значение параметра Boolean
   begin
   select case when nvl(s.parn1,0) = 0
          then 0
          else 1
          end, s.cdtp into result_, cdtp_
          from spr_params s
           where upper(s.cd)=upper(cd_);
   if nvl(cdtp_,0) <> 3 then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не является BOOLEAN типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не зарегистрирован!');
   end;
   return result_;
 end;

 function getS_bool_param(cd_ varchar2) return spr_params.parn1%type is
 cdtp_ number;
 result_ spr_params.parn1%type;
 fk_ses_ number;
 begin
   select USERENV('sessionid') into fk_ses_ from dual;
   --для сессии
   --возращает значение параметра Number
   begin
   select case when nvl(s.parn1,0) = 0
          then 0
          else 1
          end, s.cdtp into result_, cdtp_
          from spr_par_ses s
           where s.fk_ses=fk_ses_ and upper(s.cd)=upper(cd_);
   if nvl(cdtp_,0) <> 3 then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не является BOOLEAN типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не зарегистрирован для sessionId='||fk_ses_);
   end;
   return result_;
 end;

 function get_str_param(cd_ varchar2) return spr_params.parvc1%type is
 result_ spr_params.parvc1%type;
 cdtp_ number;
 begin
   --возращает значение параметра Varchar2
   begin
   select s.parvc1, s.cdtp into result_, cdtp_
          from spr_params s where upper(s.cd)=upper(cd_);
   if nvl(cdtp_,0)<>1 then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не является VARACHAR2 типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не зарегистрирован!');
   end;
   return result_;
 end;

 function getS_str_param(cd_ varchar2) return spr_params.parvc1%type is
 result_ spr_params.parvc1%type;
 cdtp_ number;
 fk_ses_ number;
 begin
   select USERENV('sessionid') into fk_ses_ from dual;
   --для сессии
   --возращает значение параметра Varchar2
   begin
   select s.parvc1, s.cdtp into result_, cdtp_
          from spr_par_ses s
           where s.fk_ses=fk_ses_ and upper(s.cd)=upper(cd_);
   if nvl(cdtp_,0)<>1 then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не является VARACHAR2 типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не зарегистрирован для sessionId='||fk_ses_);
   end;
   return result_;
 end;

 function get_date_param(cd_ varchar2) return spr_params.pardt1%type is
 result_ spr_params.pardt1%type;
 cdtp_ number;
 begin
   --возращает значение параметра Date
   begin
   select s.pardt1, s.cdtp into result_, cdtp_
          from spr_params s where upper(s.cd)=upper(cd_);
   if nvl(cdtp_,0) <> 2 then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не является DATE типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не зарегистрирован!');
   end;
   return result_;
 end;

 function getS_date_param(cd_ varchar2) return spr_params.pardt1%type is
 result_ spr_params.pardt1%type;
 cdtp_ number;
 fk_ses_ number;
 begin
   select USERENV('sessionid') into fk_ses_ from dual;
   --для сессии
   --возращает значение параметра Date
   begin
   select s.pardt1, s.cdtp into result_, cdtp_
          from spr_par_ses s
           where s.fk_ses=fk_ses_ and upper(s.cd)=upper(cd_);
   if nvl(cdtp_,0) <> 2 then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не является DATE типом!');
   end if;
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не зарегистрирован для sessionId='||fk_ses_);
   end;
   return result_;
 end;

  function getS_list_param(cd_ varchar2) return list_c.sel_id%type is
 result_ list_c.sel_id%type;
 cdtp_ number;
 cnt_ number;
 fk_ses_ number;
 begin
   select USERENV('sessionid') into fk_ses_ from dual;
   --для сессии
   --возращает ID параметра List... или -1 если ничего не выбрано
   begin
     select nvl(count(*),0) into cnt_
            from spr_par_ses s
           where s.fk_ses=fk_ses_ and upper(s.cd)=upper(cd_);
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не зарегистрирован!');
   end;

   begin
   select c.sel_id, s.cdtp into result_, cdtp_
          from spr_par_ses s, list_c c
           where c.fk_par=s.id and c.sel=1
          and s.fk_ses=fk_ses_ and s.fk_ses=c.fk_ses
          and upper(s.cd)=upper(cd_);
   if nvl(cdtp_,0) <> 4 then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не является LIST типом!');
   end if;
    exception
    when NO_DATA_FOUND then
       if nvl(cdtp_,0) <> 4 then
          raise_application_error(-20001,
                                  'Параметр - '||cd_||' не является LIST типом!');
       end if;
       result_:=-1;
   end;
   return result_;
 end;

  function getScd_list_param(cd_ varchar2) return list_c.sel_cd%type is
 result_ list_c.sel_cd%type;
 cdtp_ number;
 cnt_ number;
 fk_ses_ number;
 begin
   select USERENV('sessionid') into fk_ses_ from dual;
   --для сессии
   --возращает СD параметра List... или NULL если ничего не выбрано
   begin
     select nvl(count(*),0) into cnt_
            from spr_par_ses s
           where s.fk_ses=fk_ses_ and upper(s.cd)=upper(cd_);
    exception
    when NO_DATA_FOUND then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не зарегистрирован для sessionId='||fk_ses_);
   end;

   begin
   select c.sel_cd, s.cdtp into result_, cdtp_
          from spr_par_ses s, list_c c
           where c.fk_par=s.id and c.sel=1
          and s.fk_ses=fk_ses_ and s.fk_ses=c.fk_ses
          and upper(s.cd)=upper(cd_);
   if nvl(cdtp_,0) <> 4 then
      raise_application_error(-20001,
                              'Параметр - '||cd_||' не является LIST типом!');
   end if;
    exception
    when NO_DATA_FOUND then
/*       if nvl(cdtp_,0) <> 4 then
          raise_application_error(-20001,
                                  'Параметр - '||cd_||' не является LIST типом!');
       end if;*/
       result_:=null;
   end;
   return result_;
 end;

 procedure fill_list_c (fk_par_ in spr_params.id%type) is
 sql_text_ spr_params.sql_text%type;
 cd_ spr_params.cd%type;
 cnt_ number;
 fk_ses_ number;
 begin
   select USERENV('sessionid') into fk_ses_ from dual;
 --первоначальное заполнение списком значений,
 --для выбора пользователем
 --внимание! поле sel должно быть заполнено у одного элемента =1  - ??? не понял 13.12.2013
  select p.sql_text into sql_text_ from spr_par_ses t, spr_params p
   where t.id=fk_par_ and t.fk_ses=fk_ses_
   and t.id=p.id;

  select nvl(count(*),0) into cnt_ from list_c t where t.fk_par=fk_par_
   and t.fk_ses=fk_ses_;
  if cnt_ = 0 then
    begin
        --попробовать, если в запросе нет NPP
      execute immediate 'begin insert into list_c
        (sel_id, sel_cd, name, fk_ses, fk_par, sel, npp)
        '||sql_text_||'; end;'
        using fk_ses_, fk_par_;
      exception when others then
        if SQLCODE=-6550 then
          --если в запросе нет NPP
          begin
          execute immediate 'begin insert into list_c
            (sel_id, sel_cd, name, fk_ses, fk_par, sel)
            '||sql_text_||'; end;'
            using fk_ses_, fk_par_;
          exception when others then
            Raise_application_error(-20000, 'Ошибка в '||sql_text_);
          end;
        else
          Raise_application_error(-20000, 'Ошибка в '||sql_text_);
          --Raise;
        end if;

    end;
  end if;
  commit;
  end;

 procedure set_list_c (fk_par_ in spr_params.id%type, id_ in list_c.id%type) is
 fk_ses_ number;
 begin
   select USERENV('sessionid') into fk_ses_ from dual;
 --установить выбранные значения списка
 --для параметра x пользователя
   update list_c t set t.sel=0 where
    t.id <> id_ and t.fk_par=fk_par_
    and t.fk_ses=fk_ses_;
   update list_c t set t.sel=1 where
    t.id = id_ and t.fk_par=fk_par_
        and t.fk_ses=fk_ses_;
   commit;
 end;

 procedure rep_add_param (fk_rep_ in reports.id%type, fk_par_ in spr_params.id%type) is
 begin
 --добавление параметра в отчет
  insert into repxpar
    (fk_rep, fk_par)
  select
    fk_rep_, fk_par_ from dual t
    where not exists
     (select * from repxpar r where r.fk_rep=fk_rep_ and r.fk_par=fk_par_);
   commit;
 end;

 procedure rep_del_param (fk_rep_ in reports.id%type, fk_par_ in spr_params.id%type) is
 begin
 --удаление параметра из отчета
   delete from repxpar r where r.fk_rep=fk_rep_ and r.fk_par=fk_par_;
   commit;
 end;

 function have_sch(p_lsk in kart.lsk%type, p_counter in usl.counter%type) return number is
  l_cnt number;
begin
  Raise_application_error(-20000, 'Функция utils.have_sch заблокирована!');
  --проверяет, существует ли счетчик в текущем периоде
  if p_counter not in ('phw','pgw') then
    Raise_application_error(-20000, 'Некорректное использование utils.have_sch!');
  end if;
    select case when nvl(count(*),0) > 0 then 1 else 0 end into l_cnt from c_states_sch t
      where t.lsk=p_lsk and
      case
        when p_counter='phw' and t.fk_status in (1,2) then 1
        when p_counter='pgw' and t.fk_status in (1,3) then 1
        else 0
      end = 1
      and exists
      (select * from v_cur_days d where
        d.dat between nvl(t.dt1, to_date('01011900','DDMMYYYY'))
        and nvl(t.dt2, to_date('01012900','DDMMYYYY')));

return l_cnt;
end;

 --обновление признака счетчика в карточке л/c
 procedure upd_krt_sch_state(lsk_ in kart.lsk%type) is
 time_ date;
 l_psch number;
 l_pschEl number;
  begin
  time_:=sysdate;
  if lsk_ is not null then
    --по данному л.с. (из триггера)
    if utils.get_int_param('VER_METER1') = 0 then
      -- старая версия
      update kart k set k.psch =
         (select max(t.fk_status)
          keep (dense_rank first order by nvl(t.dt1, to_date('01011900','DDMMYYYY')) desc) as fk_status
          from c_states_sch t, params p where
              t.lsk=lsk_
              and last_day(to_date(p.period||'01','YYYYMMDD'))
              between nvl(t.dt1, to_date('01011900','DDMMYYYY'))
              and nvl(t.dt2, to_date('01012900','DDMMYYYY'))
          group by t.lsk)
          where exists
          (select *
          from c_states_sch t, params p where
              t.lsk=k.lsk
              and last_day(to_date(p.period||'01','YYYYMMDD'))
              between nvl(t.dt1, to_date('01011900','DDMMYYYY'))
              and nvl(t.dt2, to_date('01012900','DDMMYYYY'))
          ) and
           k.lsk=lsk_;
     else
     --новая версия
        for c2 in (select k.lsk from kart k where
                        exists (select * from c_states_sch t where t.lsk=k.lsk) and
                        k.lsk=lsk_) loop
          --найти статус счета
          select nvl(max(t.fk_status),-1) into l_psch
            from c_states_sch t, params p where
                t.lsk=c2.lsk
                and last_day(to_date(p.period||'01','YYYYMMDD')) -- на последний день месяца
                between nvl(t.dt1, to_date('01011900','DDMMYYYY'))
                and nvl(t.dt2, to_date('01012900','DDMMYYYY'));
          --установить статусы счетчика
          if l_psch in (8,9) then
            update kart k set k.psch=l_psch
              where k.lsk=c2.lsk and nvl(k.psch,0)<>nvl(l_psch,0);
          elsif l_psch <> -1 then
            --найти признаки счетчика
            l_psch:=p_meter.getpsch(c2.lsk);
            l_pschEl:=p_meter.getElpsch(c2.lsk);
            update kart k set k.psch=l_psch, k.sch_el=l_pschEl
              where k.lsk=c2.lsk and (nvl(k.psch,0)<>nvl(l_psch,0) or nvl(k.sch_el,0)<>nvl(l_pschEl,0));
          else
            null; --ничего не делать со статусом, если не найден статус в c_states_sch
          end if;
        end loop;
     end if;
  else
    --по всем л.с. (после перехода)
    if utils.get_int_param('VER_METER1') = 0 then
      -- старая версия
      update kart k set k.psch =
         (select max(t.fk_status)
          keep (dense_rank first order by nvl(t.dt1, to_date('01011900','DDMMYYYY')) desc) as fk_status
          from c_states_sch t, params p where
              t.lsk=k.lsk
              and last_day(to_date(p.period||'01','YYYYMMDD'))
              between nvl(t.dt1, to_date('01011900','DDMMYYYY'))
              and nvl(t.dt2, to_date('01012900','DDMMYYYY'))
          group by t.lsk)
          where exists
          (select *
          from c_states_sch t, params p where
              t.lsk=k.lsk
              and last_day(to_date(p.period||'01','YYYYMMDD'))
              between nvl(t.dt1, to_date('01011900','DDMMYYYY'))
              and nvl(t.dt2, to_date('01012900','DDMMYYYY')));
     else
     --новая версия
        for c2 in (select k.lsk from kart k where exists (select * from c_states_sch t where t.lsk=k.lsk)) loop
          --найти статус счета
          select nvl(max(t.fk_status),-1) into l_psch
            from c_states_sch t, params p where
                t.lsk=c2.lsk
                and last_day(to_date(p.period||'01','YYYYMMDD')) -- на последний день месяца
                between nvl(t.dt1, to_date('01011900','DDMMYYYY'))
                and nvl(t.dt2, to_date('01012900','DDMMYYYY'));
          --установить статусы счетчика
          if l_psch in (8,9) then
            update kart k set k.psch=l_psch
              where k.lsk=c2.lsk and nvl(k.psch,0)<>nvl(l_psch,0);
          elsif l_psch <> -1 then
            --найти признаки счетчика
            l_psch:=p_meter.getpsch(c2.lsk);
            l_pschEl:=p_meter.getElpsch(c2.lsk);
            update kart k set k.psch=l_psch
              where k.lsk=c2.lsk and (nvl(k.psch,0)<>nvl(l_psch,0) or nvl(k.sch_el,0)<>nvl(l_pschEl,0));
          else
            null; --ничего не делать со статусом, если не найден статус в c_states_sch
          end if;
        end loop;
     end if;
     logger.log_(time_, 'gen.upd_krt_sch_state');
  end if;
  end;

 --функция используется в карточке для определения даты договора Э+
 function set_krt_psch (dat_ in c_states_sch.dt1%type,
   fk_status_ in c_states_sch.fk_status%type, lsk_ in kart.lsk%type) return integer
   is
 cnt_ number;
 set_ number;
 cursor cur1 is
   select c.fk_status, c.dt1, c.rowid as rd from c_states_sch c
    where c.lsk=lsk_ and c.dt2 is null;
 rec1_ cur1%rowtype;
 cursor cur2 is
   select c.dt1, c.dt2, c.rowid as rd from c_states_sch c
    where c.lsk=lsk_
    and c.dt2 is not null;
 rec2_ cur2%rowtype;

 cursor cur_krt is
   select k.psch from kart k
    where k.lsk=lsk_;
 rec_krt_ cur_krt%rowtype;

 cursor cur_dt is
  select nvl(count(*),0) as cnt from
   c_states_sch c where dat_ between c.dt1 and c.dt2
   and c.lsk=lsk_
   and c.dt1 <> dat_ and c.dt2<> dat_;
 rec_dt_ cur_dt%rowtype;
 --------
 begin
 --изменение статуса л.с. с добавлением в историю нового статуса
 set_:=0;
 open cur_krt;
 fetch cur_krt into rec_krt_;
 close cur_krt;

 open cur_dt;
 fetch cur_dt into rec_dt_;
 close cur_dt;

 if to_char(dat_,'YYYYMM') = to_char(init.get_date,'YYYYMM') then
   if fk_status_ <> rec_krt_.psch and rec_dt_.cnt = 0 then
  --   dat_:=init.get_date;
     open cur1;
     fetch cur1 into rec1_;
     close cur1;
     open cur2;
     fetch cur2 into rec2_;
     close cur2;

     if rec1_.rd is null then
      --нет открытого периода
      if nvl(rec2_.dt1,to_date('19000101', 'YYYYMMDD')) <= trunc(dat_)-1 then
        --закрываем имеющуюся строчку (датой на день раньше)
        update c_states_sch t set t.dt2=trunc(dat_)-1
        where t.rowid=rec2_.rd;
      end if;
      insert into c_states_sch
       (lsk, fk_status, dt1, dt2)
       values
       (lsk_, fk_status_, dat_, null);
     else
      --есть открытый период
      if nvl(rec1_.dt1,to_date('19000101', 'YYYYMMDD')) <= trunc(dat_)-1 then
        --закрываем имеющуюся строчку (датой на день раньше)
        update c_states_sch t set t.dt2=trunc(dat_)-1
        where t.rowid=rec1_.rd;
        insert into c_states_sch
         (lsk, fk_status, dt1, dt2)
         values
         (lsk_, fk_status_, dat_, null);
      else
        --меняем имеющуюся строчку (статус)
        update c_states_sch t set t.fk_status=fk_status_
        where t.rowid=rec1_.rd;
      end if;
     end if;
     set_:=1;
   end if;
 else
  --ошибка, период не соответствует текущему
  set_:=2;
 end if;
 return set_;
 end;

/*
 --заменено на функцию в ext_pkg.is_lst, ред.27.08.14

function is_lst_day(p_days in number) return number is
  l_mg params.period%type;
begin
  --проверяет последний ли день месяца и соответствует ли период в базе текущему периоду
  --p_days --сменить на N дней, конец месяца))
  select p.period into l_mg from params p;
  if trunc(sysdate) >= last_day(to_date(l_mg||'01','YYYYMMDD'))-nvl(p_days,0) then
    --да, последний день месяца
    return 1;
  elsif trunc(sysdate) < last_day(to_date(l_mg||'01','YYYYMMDD'))-nvl(p_days,0)
   and to_char(sysdate,'YYYYMM')=l_mg then --добавил проверку, на случай, если дата в компе не корректная совсем (даже не тот месяц)
    --нет, не последний день месяца
    return 0;
  end if;
end; */

function set_base_state_gen(l_set in number) return number is
l_status number;
l_handle varchar2(128);
begin
--Использовать в другой сессии, для исключения запуска повторных процессов формирования
--чего-либо из Директа

--найти/разместить идентификатор блокировки
DBMS_LOCK.ALLOCATE_UNIQUE
    ('Direct_gen'
    ,l_handle
    ,86400);

if l_set=1 then
  --попытка выполнить блокировку
  l_status := dbms_lock.request(l_handle, dbms_lock.X_MODE,
                                  timeout => 1);

  IF l_status = 0 THEN
   --заблокировано
   return 0;
  ELSE
   --отказ в блокировке
   return 1;
  END IF;
else
  --попытка снять блокировку (либо снимется по завершении сессии)
  l_status := DBMS_LOCK.RELEASE
                     (lockhandle => l_handle);
  return l_status;
end if;

/*if l_set=1 then
  --выполнить блокировку
  begin
--    delete from c_dummy;
--    insert into c_dummy (n1) values (1);
    for c in (select t.rowid as rd, t.n1
          from c_dummy t
          for update of t.n1 nowait )
    loop
        update c_dummy t set t.n1=1 where t.rowid = c.rd;
    end loop;
  exception
    when others then
      if SQLCODE = -54 then
        return 1;
      else
        raise;
      end if;
  end;

  return 0;
else
  --просто выполнить коммит в этой сесии
  commit;
  return 0;
end if; */

end;

--проверка справочника redir_pay
function check_redir_pay return number is
  l_cnt number;
begin
  --1 проверка оплаты и пени
  select nvl(count(*), 0)
    into l_cnt
    from (select t.fk_usl_src, t.fk_org_dst, t.tp, t.fk_usl_dst, t.fk_org_src, t.reu,
                  count(*)
             from redir_pay t
            where t.tp in (0, 1)
            group by t.fk_usl_src, t.fk_org_dst, t.tp, t.fk_usl_dst, t.fk_org_src, t.reu
           having count(*) > 1);

  if l_cnt > 0 then
    --не прошла проверку настройка оплаты или пени
    return 1;
  end if;

  --2 проверка справочника для статистики
  select nvl(count(*), 0)
    into l_cnt
    from (select t.fk_org_dst, t.fk_org_src, t.mg1, t.mg2, count(*)
             from redir_pay t
            where t.tp in (2)
            group by t.fk_org_dst, t.fk_org_src, t.mg1, t.mg2
           having count(*) > 1);

  if l_cnt > 0 then
    --не прошла проверку настройка справочника для статистики
    return 2;
  end if;

--всё ок!
return 0;
end;

end utils;
/

