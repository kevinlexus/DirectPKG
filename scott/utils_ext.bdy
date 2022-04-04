create or replace package body scott.utils_ext is


-- получить фио сокращенно "‘амили€ ».ќ."
function get_short_fio(p_fam in varchar2, p_im in varchar2, p_ot in varchar2) return varchar2  is
  l_fam varchar2(1000);
  l_im varchar2(1000);
  l_ot varchar2(1000);
begin
  l_fam:=initcap(trim(p_fam));
  if l_fam is not null and length(l_fam)>0 then
    l_im:=upper(substr(trim(p_im),1,1));
    if l_im is not null and length(l_im)>0 then
       l_fam:=l_fam||' '||l_im||'.';
       l_ot:=upper(substr(trim(p_ot),1,1));
       if l_ot is not null and length(l_ot)>0 then
         l_fam:=l_fam||l_ot||'.';
       end if;
    end if;
  end if;
  return l_fam;
end;


-- получить код ”  основного лиц.счета (используетс€ в Delphi, Form_get_pay_nal)
-- приоритет - основной счет, не закрытый
function get_main_reu(p_lsk in kart.lsk%type) return kart.reu%type is
  l_reu kart.reu%type;
begin
  select reu
    into l_reu
    from (select t.reu
             from kart k
             join kart t
               on k.k_lsk_id = t.k_lsk_id
              and k.lsk = p_lsk
             join v_lsk_tp tp
               on t.fk_tp = tp.id
            order by decode(t.psch, 8, 1, 9, 1, 0), tp.npp, t.reu)
   where rownum = 1;
  return l_reu;
end;

function get_type_of_kart(p_lsk in kart.lsk%type) return number is
  l_ret number;
begin
  -- типа битова€ маска:
  -- 0  - закрытый и не основной
  -- 1  - открытый и не основной
  -- 10 - закрытый и основной
  -- 11 - открытый и основной
  begin
    select decode(tp.cd, 'LSK_TP_MAIN', 10,0)+
           decode(k.psch, 8,0,9,0,1) into l_ret
     from kart k join v_lsk_tp tp on k.lsk=p_lsk and k.fk_tp=tp.id;
    return l_ret;

  exception
    when no_data_found then
      return 0;
  end;
end;


end utils_ext;
/

