create or replace function scott.getdt(p_day in number, p_month in number, p_year in number) return date is
 l_dt date;
begin

if not (length(p_day) between 1 and 2 and
    length(p_month) between 1 and 2 and
    length(p_year) between 1 and 4) then
  Raise_application_error(-20000, '—правка по вызову: utils.gdt(dd,mm,yyyy)');
elsif nvl(p_day,0)=0 and nvl(p_month,0)=0 and nvl(p_year,0)=0 then
  --по текущему текущему дню по sysdate
  select trunc(sysdate) into l_dt
  from dual;
elsif nvl(p_day,0)<>0 and nvl(p_month,0)=0 and nvl(p_year,0)=0 then
  --по текущему периоду, по дню
  --если задано превышающее максимальное значение дн€ - исправить на последний день мес€ца
  select case when p_day > to_char( last_day(to_date(p.period||'01','YYYYMMDD')),'DD')
         then last_day(to_date(p.period||'01','YYYYMMDD'))
         else to_date(p.period||lpad(p_day,2,'0'),'YYYYMMDD') end
   into l_dt
  from params p;
elsif nvl(p_day,0)<>0 and p_month is not null and nvl(p_year,0)=0 then
  --по периоду текущего года, по дню и є мес€ца
  select to_date(substr(p.period,1,4)||lpad(p_month,2,'0')||lpad(p_day,2,'0'),'YYYYMMDD') into l_dt
  from params p;
elsif nvl(p_day,0)<>0 and p_month is not null and p_year is not null then
  --по периоду указанного года, по дню и є мес€ца
  if length(p_year) between 1 and 2 then
    select to_date('20'||lpad(p_year,2,'0')||lpad(p_month,2,'0')||lpad(p_day,2,'0'),'YYYYMMDD') into l_dt
    from params p;
  else
    select to_date(to_char(p_year)||lpad(p_month,2,'0')||lpad(p_day,2,'0'),'YYYYMMDD') into l_dt
    from params p;
  end if;

else
  Raise_application_error(-20000, '—правка по вызову: utils.gdt(dd,mm,yy)');
end if;

return l_dt;

end getdt;
/

