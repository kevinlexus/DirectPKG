create or replace package scott.utils_ext is


-- получить фио сокращенно "Фамилия И.О."
function get_short_fio(p_fam in varchar2, p_im in varchar2, p_ot in varchar2) return varchar2;


end utils_ext;
/

create or replace package body scott.utils_ext is


-- получить фио сокращенно "Фамилия И.О."
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


end utils_ext;
/

