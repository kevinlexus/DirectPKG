create or replace package body scott.dbase_pkg
as
--пакет для загрузки DBF в ORACLE

-- Might have to change on your platform!!!
-- Controls the byte order of binary integers read in
-- from the dbase file
BIG_ENDIAN      constant boolean default TRUE;

type dbf_header is RECORD
(
    version    varchar2(25), -- dBASE version number
    year       int,          -- 1 byte int year, add to 1900
    month      int,          -- 1 byte month
    day        int,             -- 1 byte day
    no_records int,             -- number of records in file,
                             -- 4 byte int
    hdr_len    int,             -- length of header, 2 byte int
    rec_len    int,             -- number of bytes in record,
                             -- 2 byte int
    no_fields  int           -- number of fields
);


type field_descriptor is RECORD
(
    name     varchar2(11),
    type     char(1),
    length   int,   -- 1 byte length
    decimals int    -- 1 byte scale
);

type field_descriptor_array
is table of
field_descriptor index by binary_integer;


type rowArray
is table of
varchar2(4000) index by binary_integer;


g_cursor binary_integer default dbms_sql.open_cursor;




-- Function to convert a binary unsigned integer
-- into a PLSQL number

function to_int( p_data in varchar2 ) return number
is
    l_number number default 0;
    l_bytes  number default length(p_data);
begin
    if (big_endian)
    then
        for i in 1 .. l_bytes loop
            l_number := l_number +
                              ascii(substr(p_data,i,1)) *
                                           power(2,8*(i-1));
        end loop;
    else
        for i in 1 .. l_bytes loop
            l_number := l_number +
                         ascii(substr(p_data,l_bytes-i+1,1)) *
                         power(2,8*(i-1));
        end loop;
    end if;

    return l_number;
end;


function mytrim(p_str in varchar2) return varchar2 is
i number;
j number;
v_res varchar2(100);
begin
  for i in 1 .. 11 loop
    if ascii(substr(p_str,i,1)) = 0 then
     j:= i;
     exit;
    end if;
  end loop;
  v_res := substr(p_str,1,j-1);
  return v_res;
end mytrim;


-- Routine to parse the DBASE header record, can get
-- all of the details of the contents of a dbase file from
-- this header

procedure get_header
(p_bfile        in bfile,
 p_bfile_offset in out NUMBER,
 p_hdr          in out dbf_header,
 p_flds         in out field_descriptor_array )
is
    l_data            varchar2(100);
    l_hdr_size        number default 32;
    l_field_desc_size number default 32;
    l_flds            field_descriptor_array;
begin
    p_flds := l_flds;

    l_data := utl_raw.cast_to_varchar2(
                       dbms_lob.substr( p_bfile,
                                        l_hdr_size,
                                        p_bfile_offset ) );
    p_bfile_offset := p_bfile_offset + l_hdr_size;

    p_hdr.version    := ascii( substr( l_data, 1, 1 ) );
    p_hdr.year       := 1900 + ascii( substr( l_data, 2, 1 ) );
    p_hdr.month      := ascii( substr( l_data, 3, 1 ) );
    p_hdr.day        := ascii( substr( l_data, 4, 1 ) );
    p_hdr.no_records := to_int( substr( l_data,  5, 4 ) );
--    p_hdr.hdr_len    := to_int( substr( l_data,  9, 2 ) );
    p_hdr.hdr_len    := to_int( substr( l_data,  9, 2 ) );
    p_hdr.rec_len    := to_int( substr( l_data, 11, 2 ) );
    p_hdr.no_fields  := trunc( (p_hdr.hdr_len - l_hdr_size)/
                                           l_field_desc_size );


    for i in 1 .. p_hdr.no_fields
    loop
        l_data := utl_raw.cast_to_varchar2(
                         dbms_lob.substr( p_bfile,
                                          l_field_desc_size,
                                          p_bfile_offset ));
        p_bfile_offset := p_bfile_offset + l_field_desc_size;

/*
        p_flds(i).name := rtrim(substr(l_data,1,11),chr(0));
        p_flds(i).type := substr( l_data, 12, 1 );
        p_flds(i).length  := ascii( substr( l_data, 17, 1 ) );
        p_flds(i).decimals := ascii(substr(l_data,18,1) );
*/
        p_flds(i).name := mytrim(substr(l_data,1,11));
        p_flds(i).type := substr( l_data, 12, 1 );
        p_flds(i).length  := ascii( substr( l_data, 17, 1 ) );
        p_flds(i).decimals := ascii(substr(l_data,18,1) );
    end loop;

    p_bfile_offset := p_bfile_offset +
                          mod( p_hdr.hdr_len - l_hdr_size,
                               l_field_desc_size );
end;



function build_insert
( p_tname in varchar2,
  p_cnames in varchar2,
  p_flds in field_descriptor_array ) return varchar2
is
    l_insert_statement long;
begin
    l_insert_statement := 'insert into ' || p_tname || '(';
    if ( p_cnames is NOT NULL )
    then
        l_insert_statement := l_insert_statement ||
                              p_cnames || ') values (';
    else
        for i in 1 .. p_flds.count
        loop
            if ( i <> 1 )
            then
               l_insert_statement := l_insert_statement||',';
            end if;
            l_insert_statement := l_insert_statement ||
                            '"'||  p_flds(i).name || '"';
        end loop;
        l_insert_statement := l_insert_statement ||
                                           ') values (';
    end if;
    for i in 1 .. p_flds.count
    loop
        if ( i <> 1 )
        then
           l_insert_statement := l_insert_statement || ',';
        end if;
        if ( p_flds(i).type = 'D' )
        then

            l_insert_statement := l_insert_statement ||
                     'to_date(:bv' || i || ',''yyyymmdd'' )';
        else
            l_insert_statement := l_insert_statement ||
                                                ':bv' || i;
        end if;
    end loop;
    l_insert_statement := l_insert_statement || ')';

    return l_insert_statement;
end;


function get_row
( p_bfile in bfile,
  p_bfile_offset in out number,
  p_hdr in dbf_header,
  p_flds in field_descriptor_array ) return rowArray
is
    l_data     varchar2(4000);
    l_row   rowArray;
    l_n     number default 2;
begin
    l_data := utl_raw.cast_to_varchar2(
                   dbms_lob.substr( p_bfile,
                                    p_hdr.rec_len,
                                    p_bfile_offset ) );
    p_bfile_offset := p_bfile_offset + p_hdr.rec_len;

    l_row(0) := substr( l_data, 1, 1 );

    for i in 1 .. p_hdr.no_fields loop
        l_row(i) := rtrim(ltrim(substr( l_data,
                                        l_n,
                                        p_flds(i).length ) ));
        if ( p_flds(i).type = 'F' and l_row(i) = '.' )
        then
            l_row(i) := NULL;
        end if;
        l_n := l_n + p_flds(i).length;
    end loop;
    return l_row;
end get_row;


procedure show( p_hdr    in dbf_header,
                p_flds   in field_descriptor_array,
                p_tname  in varchar2,
                p_cnames in varchar2,
                p_bfile  in bfile )
is
    l_sep varchar2(1) default ',';

    procedure p(p_str in varchar2)
    is
        l_str long default p_str;
    begin
        while( l_str is not null )
        loop
            dbms_output.put_line( substr(l_str,1,250) );
            l_str := substr( l_str, 251 );
        end loop;
    end;
begin
    p( 'Sizeof DBASE File: ' || dbms_lob.getlength(p_bfile) );

    p( 'DBASE Header Information: ' );
    p( chr(9)||'Version = ' || p_hdr.version );
    p( chr(9)||'Year    = ' || p_hdr.year   );
    p( chr(9)||'Month   = ' || p_hdr.month   );
    p( chr(9)||'Day     = ' || p_hdr.day   );
    p( chr(9)||'#Recs   = ' || p_hdr.no_records);
    p( chr(9)||'Hdr Len = ' || p_hdr.hdr_len  );
    p( chr(9)||'Rec Len = ' || p_hdr.rec_len  );
    p( chr(9)||'#Fields = ' || p_hdr.no_fields );

    p( chr(10)||'Data Fields:' );
    for i in 1 .. p_hdr.no_fields
    loop
        p( 'Field(' || i || ') '
             || 'Name = "' || p_flds(i).name || '", '
             || 'Type = ' || p_flds(i).Type || ', '
             || 'Len  = ' || p_flds(i).length || ', '
             || 'Scale= ' || p_flds(i).decimals );
    end loop;

    p( chr(10) || 'Insert We would use:' );
    p( build_insert( p_tname, p_cnames, p_flds ) );

    p( chr(10) || 'Table that could be created to hold data:');
    p( 'create table ' || p_tname );
    p( '(' );

    for i in 1 .. p_hdr.no_fields
    loop
        if ( i = p_hdr.no_fields ) then l_sep := ')'; end if;
        dbms_output.put
        ( chr(9) || '"' || p_flds(i).name || '"   ');

        if ( p_flds(i).type = 'D' ) then
            p( 'date' || l_sep );
        elsif ( p_flds(i).type = 'F' ) then
            p( 'float' || l_sep );
        elsif ( p_flds(i).type = 'N' ) then
            if ( p_flds(i).decimals > 0 )
            then
                p( 'number('||p_flds(i).length||','||
                              p_flds(i).decimals || ')' ||
                              l_sep );
            else
                p( 'number('||p_flds(i).length||')'||l_sep );
            end if;
        else
            p( 'varchar2(' || p_flds(i).length || ')'||l_sep);
        end if;
    end loop;
    p( '/' );
end;

function parse_row_txt(txt_ in varchar2, at_ in number, ch in varchar2 default '|')
 return varchar2
is
  i number;
  i2 number;
begin
  --парсинг строки
  --начало строки
  if at_ - 1 = 0 then
    --ищем с начала файла
    i:=1;
    else
      if instr(txt_,ch, 1, at_-1) = 0 then
      --не найден лидирующий символ (некорректный запрос)
        return null;
      end if;
    i:= instr(txt_,ch, 1, at_-1)+1;
  end if;

  --конец строки
  i2:= instr(txt_,ch, 1, at_);
  if i2 = 0 then
    i2:=length(txt_)+1;
  end if;
  return substr(txt_, i, i2-i);
end;


--загрузка таблицы долгов от Организации fk_org
procedure load_e(p_org in t_org.id%type) is
l_adr varchar2(4000);
begin
--из таблицы load_tmp_bulk
--regexp_instr('1,1,67,2,3,7,2,4,8', '(,|^)67(,|$){1,}')
--расшифровывается:
--найти цифру (67)
--один раз {1}
delete from load_tmp_e;

for c in (
         with a as (select rownum as rn, replace(regexp_substr(t.s1, '[^|].+?(\||$)', 1, 1),'|','') as lsk_ext,
         replace(regexp_substr(t.s1, '[^|].+?(\||$)', 1, 2),'|','') as fio,
         replace(regexp_substr(t.s1, '[^|].+?(\||$)', 1, 3),'|','') as adr,
         replace(regexp_substr(t.s1, '[^|].+?(\||$)', 1, 4),'|','') as usl_cd,
         replace(regexp_substr(t.s1, '[^|].+?(\||$)', 1, 5),'|','') as usl_name,
         replace(regexp_substr(t.s1, '[^|].+?(\||$)', 1, 6),'|','') as period,
         to_number(replace(regexp_substr(t.s1, '[^|][[:digit:]]{0,}(\||$)', 1, 7),'|','')) as mel,
         replace(regexp_substr(t.s1, '[^|][[:digit:]]{0,}(\||$)', 1, 8),'|','')/100 as sal
 from load_tmp_bulk t)
  select a.rn, a.lsk_ext, a.fio, a.adr, a.usl_cd, a.usl_name,
    substr(a.period,3,4)||substr(a.period,1,2) as period, a.mel, a.sal from a
 )
loop
  begin
    insert into load_tmp_e
      (lsk_ext, fio, adr, usl_cd, usl_name, period, mel, sal, fk_org)
      values
      (c.lsk_ext, c.fio, c.adr, c.usl_cd, c.usl_name, c.period, c.mel, c.sal, p_org);
    exception when value_error then
              Raise_application_error(-20000, 'Ошибка значения в строке файла:'||c.rn||' '||SQLCODE||' -ERRmsg- '||SQLERRM);
              when others then
              Raise;
  end;
end loop;
commit;
end;

--получить кол-во лицевых счетов, для загрузки в kart
function get_cnt_to_load(p_org in t_org.id%type) return number is
l_cnt number;
begin
select count(*) into l_cnt from load_tmp_e t
 where not exists (select * from kart k, t_org o
   where k.lsk_ext=t.lsk_ext and t.fk_org=o.id
         and o.reu=k.reu);

return l_cnt;
end;

--выполнить загрузку лицевых счетов в kart (09.11.2018 - временно закомментировал, как не нужное)
/*procedure ins_to_kart(p_org in t_org.id%type) is
 l_lsk_smpl kart.lsk%type;
 l_lsk_new kart.lsk%type;
 a number;
 l_reu t_org.reu%type;
begin

select t.reu into l_reu
  from t_org t where t.id=p_org;
--загрузить лиц.счета
select k.lsk into l_lsk_smpl from kart k
  where k.reu=l_reu and rownum=1;
for c in (select t.* from load_tmp_e t
   where not exists (select * from kart k where k.lsk_ext=t.lsk_ext))
loop
  l_lsk_new:=utils.get_new_lsk_by_reu(p_reu => l_reu);
  a:=utils.CREATE_LSK(l_lsk_smpl, l_lsk_new, c.lsk_ext, c.fio);
end loop;

--загрузить суммы задолжности



commit;
end;*/

procedure load_file_txt_bulk(p_dir in varchar2,
                      p_file in varchar2)
is
  buffer varchar2(4000);
  l_fname varchar2(100);
  i number;
  pos number;
  ft  utl_file.file_type;
begin
--загрузка текстового файла, без разбора формата
  i:=1;
  while instr(p_file, '\',  1, i) <> 0
  loop
   pos:=instr(p_file, '\', 1, i);
   i:=i+1;
  end loop;
  l_fname:=substr(p_file,pos+1, length(p_file)-pos);
  ft:=utl_file.fopen(p_dir, l_fname, 'r');
  execute immediate 'truncate table load_tmp_bulk';

  loop
    begin
      utl_file.get_line(ft, buffer, 4000);
    exception
       when NO_DATA_FOUND then
         --конец файла
         exit;
       when OTHERS then
         Raise;
    end;
    insert into load_tmp_bulk(s1)
      values (buffer);
  end loop;
  utl_file.fCLOSE(ft);
  commit;

end;

procedure load_file_txt(p_dir in varchar2,
                      p_file in varchar2)
is
  l_bfile      bfile;
  ft  utl_file.file_type;
  buffer varchar2(4000);
  cnt_ number;
  summa_ number;
  fname_ varchar2(100);
  i number;
  pos number;
begin
  --получение текстового файла оплаты из банка
  select nvl(count(*),0) into cnt_ from c_comps c, t_org o
    where c.nkom=init.get_nkom and c.fk_org=o.id;
    --and o.cd in ('Сбербанк', 'Почта', 'ЖКХ-1', 'Сбербанк-2') -- убрал ограничение 25.11.2018
  if cnt_ = 0 then
    raise_application_error( -20001,
     '№ Компьютера не соответствует данному типу файлов');
  end if;
  --выделяем имя файла из полного пути
  i:=1;
  pos:=1;
  while instr(p_file, '\',  1, i) <> 0
  loop
   pos:=instr(p_file, '\', 1, i);
   i:=i+1;
  end loop;
  fname_:=substr(p_file,pos+1, length(p_file)-pos);
  --
  delete from load_bank t where t.nkom=init.get_nkom;
  ft:=utl_file.fopen(p_dir, fname_, 'r');
  summa_:=0;
  --проверить, установлен ли параметр
  cnt_:=utils.get_int_param('REJECT_PERIOD_BANK');

  cnt_:=0;

begin
  loop
    utl_file.get_line(ft, buffer, 2000);
    if parse_row_txt(buffer, 1) <> '=' then
    cnt_:=cnt_+1;
    summa_:=summa_+nvl(to_number(parse_row_txt(buffer, 4)/100),0);
    begin
    insert into load_bank(nkom, dtek, lsk, lsk2, code, summa, dopl, dn, nkvit)
      values (init.get_nkom, trunc(to_date(parse_row_txt(buffer, 1),'DDMMYYYY')),
              parse_row_txt(buffer, 2),
              parse_row_txt(buffer, 2),
              lpad(parse_row_txt(buffer, 3),2,'0'),
              to_number(parse_row_txt(buffer, 4)/100),
              case when utils.get_int_param('REJECT_PERIOD_BANK') = 0
                  and instr(parse_row_txt(buffer, 5),'.') > 0 then
                   substr(parse_row_txt(buffer, 5),4,4)||substr(parse_row_txt(buffer, 5),1,2)
                when utils.get_int_param('REJECT_PERIOD_BANK') = 0
                  and instr(parse_row_txt(buffer, 5),'.') = 0 then
                   substr(parse_row_txt(buffer, 5),3,4)||substr(parse_row_txt(buffer, 5),1,2)
                when utils.get_int_param('REJECT_PERIOD_BANK') = 1 then
                   init.get_period
                end
              ,
              parse_row_txt(buffer, 6),
              regexp_replace(parse_row_txt(buffer, 7), '[^0-9]', '')
                );
     exception
       when others then
          raise_application_error( -20001,
           'ОШИБКА В СТРОКЕ № '||cnt_||' ПРИНИМАЕМОГО ФАЙЛА');
     end;
     else
     --найден итог по файлу
       if parse_row_txt(buffer, 2) <> cnt_  then
          raise_application_error( -20001,
           'кол-во строк не корректное, найдено ' || cnt_ || ', в файле указано '||parse_row_txt(buffer, 2));
       end if;
       if to_number(parse_row_txt(buffer, 3))/100 <> summa_  then
          raise_application_error( -20001,
           'сумма не корректная, найдено ' || summa_ || ', в файле указано '||parse_row_txt(buffer, 3)/100);
       end if;
       --выход, больше не ищем строк, если нашли итог
       exit;
     end if;
  end loop;
exception
  when no_data_found then
    null;
end;
  utl_file.fCLOSE(ft);
  commit;
end;

-- для Своб.
procedure load_file_txt2(p_dir in varchar2,
                      p_file in varchar2)
is
  l_bfile      bfile;
  ft  utl_file.file_type;
  buffer varchar2(4000);
  cnt_ number;
  summa_ number;
  fname_ varchar2(100);
  i number;
  pos number;
  l_mg params.period%type;
begin
  --получение текстового файла оплаты из банка
  begin
    select 1, p.period into cnt_, l_mg from c_comps c, t_org o, params p
      where c.nkom=init.get_nkom and c.fk_org=o.id
      and o.cd in ('Сбербанк', 'Сбербанк-2');
  exception when NO_DATA_FOUND then
    raise_application_error( -20001,
     '№ Компьютера не соответствует данному типу файлов');
  end;
  --выделяем имя файла из полного пути
  i:=1;
  pos:=1;
  while instr(p_file, '\',  1, i) <> 0
  loop
   pos:=instr(p_file, '\', 1, i);
   i:=i+1;
  end loop;
  fname_:=substr(p_file,pos+1, length(p_file)-pos);
  --
  delete from load_bank t where t.nkom=init.get_nkom;
  ft:=utl_file.fopen(p_dir, fname_, 'r');
  summa_:=0;
  cnt_:=0;

begin
  --dbms_output.enable(20000);
  loop
    utl_file.get_line(ft, buffer, 2000);
    --dbms_output.put_line('--'||parse_row_txt(buffer, 1, ';'));
    if substr(parse_row_txt(buffer, 1, ';'),2,1) <> '=' then
    cnt_:=cnt_+1;
    summa_:=summa_+nvl(to_number(parse_row_txt(buffer, 8, ';'),'999999999.99')/100,0);
    /*dbms_output.put_line('cnt='||cnt_);
    dbms_output.put_line(trunc(to_date(substr(parse_row_txt(buffer, 1,';'),2,10))));
    dbms_output.put_line(parse_row_txt(buffer, 6, ';'));
    dbms_output.put_line(parse_row_txt(buffer, 6, ';'));
    dbms_output.put_line(to_number(parse_row_txt(buffer, 8, ';'),'999999999.99')/100);
    */
    begin
    insert into load_bank(nkom, dtek, lsk, lsk2, code, summa, dopl, dn, nkvit)
      values (init.get_nkom, trunc(to_date(substr(parse_row_txt(buffer, 1,';'),2,10))),
              parse_row_txt(buffer, 6, ';'),
              parse_row_txt(buffer, 6, ';'),
              '01',
              to_number(parse_row_txt(buffer, 8, ';'),'999999999.99')/100,
              l_mg,
              null,
              parse_row_txt(buffer, 5, ';') -- уникальный код операции (№ квит. Сбер?)
                );
     exception
       when others then
          raise_application_error( -20001,
           'ОШИБКА В СТРОКЕ № '||cnt_||' ПРИНИМАЕМОГО ФАЙЛА');
     end;
     end if;
  end loop;
exception
  when no_data_found then
    null;
end;
  utl_file.fCLOSE(ft);
  commit;
end;

procedure load_file_dbf(p_dir in varchar2,
                      p_file in varchar2)
is
  p_show boolean;
  cnt_ number;
  i number;
  pos number;
  fname_ varchar2(100);
begin
  --получение dbf файла оплаты из Почты
  select nvl(count(*),0) into cnt_ from c_comps c, t_org o
    where c.nkom=init.get_nkom and c.fk_org=o.id
    and o.cd in ('Почта');
  if cnt_ = 0 then
    raise_application_error( -20001,
     '№ Компьютера не соответствует данному типу файлов');
  end if;

  --выделяем имя файла из полного пути
  i:=1;
  pos:=1;
  while instr(p_file, '\',  1, i) <> 0
  loop
   pos:=instr(p_file, '\', 1, i);
   i:=i+1;
  end loop;
  fname_:=substr(p_file,pos+1, length(p_file)-pos);

  delete from load_tmp_post;
  p_show:=sys.diutil.int_to_bool(0);
  load_Table(p_dir, fname_, 'load_tmp_post', null, p_show);

  delete from load_bank t where t.nkom=init.get_nkom;
  insert into load_bank
   (dtek, lsk, lsk2, code, summa, dopl, dn, nkvit, nkom)
  select t.getd, lpad(trim(t.lc),8,'0'), trim(t.lc), decode(t.typep, 1, '01', '02'),
   t.summa,
   case when  utils.get_int_param('REJECT_PERIOD_BANK') = 0 then
        t.year||lpad(trim(t.month),2,'0')
      else
        init.get_period
      end
   , null, null, init.get_nkom
    from load_tmp_post t;
    commit;
end;

procedure load_file_dbf2(p_dir in varchar2,
                      p_file in varchar2)
is
  p_show boolean;
  cnt_ number;
  i number;
  pos number;
  fname_ varchar2(100);
begin
  --получение dbf файла оплаты из Сбербанка
  select nvl(count(*),0) into cnt_ from c_comps c, t_org o
    where c.nkom=init.get_nkom and c.fk_org=o.id
    and o.cd in ('Сбербанк', 'Сбербанк-2');
  if cnt_ = 0 then
    raise_application_error( -20001,
     '№ Компьютера не соответствует данному типу файлов');
  end if;

  --выделяем имя файла из полного пути
  i:=1;
  pos:=1;
  while instr(p_file, '\',  1, i) <> 0
  loop
   pos:=instr(p_file, '\', 1, i);
   i:=i+1;
  end loop;
  fname_:=substr(p_file,pos+1, length(p_file)-pos);

  delete from load_tmp_post2;
  p_show:=sys.diutil.int_to_bool(0);
  load_Table(p_dir, fname_, 'load_tmp_post2', null, p_show);

  delete from load_bank t where t.nkom=init.get_nkom;
  insert into load_bank
   (dtek, lsk, lsk2, code, summa, dopl, dn, nkvit, nkom)
  select t.dtek, lpad(trim(t.lsk),8,'0'), trim(t.lsk), '01',
   t.ska,
   case when  utils.get_int_param('REJECT_PERIOD_BANK') = 0 then
        substr(t.dopl,3,4)||substr(t.dopl,1,2)
      else
        init.get_period
      end,
   null, null, init.get_nkom
    from load_tmp_post2 t where nvl(t.ska,0) <> 0
   union all
  select t.dtek, lpad(trim(t.lsk),8,'0'), trim(t.lsk), '02',
   t.pn,
   case when  utils.get_int_param('REJECT_PERIOD_BANK') = 0 then
        substr(t.dopl,3,4)||substr(t.dopl,1,2)
      else
        init.get_period
      end,
   null, null, init.get_nkom
    from load_tmp_post2 t where nvl(t.pn,0) <> 0 ;
    commit;
end;

procedure load_other_file_dbf(p_dir in varchar2,
                      p_file in varchar2)
is
  p_show boolean;
  cnt_ number;
  i number;
  pos number;
  fname_ varchar2(100);
  tname_ varchar2(100);
begin
  --загрузка прочих dbf-ок
  --выделяем имя файла из полного пути
  i:=1;
  pos:=1;
  while instr(p_file, '\',  1, i) <> 0
  loop
   pos:=instr(p_file, '\', 1, i);
   i:=i+1;
  end loop;
  fname_:=substr(p_file,pos+1, length(p_file)-pos);
  tname_:=substr(p_file,pos+1, length(p_file)-pos-4); --4- кол-во символов расширения

  p_show:=sys.diutil.int_to_bool(0);
  execute immediate 'delete from '||tname_;
  load_Table(p_dir, fname_, tname_, null, p_show);

  commit;
end;


--обертка
procedure load_db(p_dir in varchar2,
                      isdel_ in number,
                      fname_ in varchar2,
                      tname_ in varchar2
                      ) is
begin
  --вызвать новую процедуру
  load_db(p_dir => p_dir, isdel_ => isdel_, fname_ => fname_, tname_ => tname_, p_is_comm => 1);

end;

--загрузка dbf
procedure load_db(p_dir in varchar2,
                      isdel_ in number,
                      fname_ in varchar2,
                      tname_ in varchar2,
                      p_is_comm in number --0-без коммита, 1-коммит
                      )
is
  p_show boolean;
  cnt_ number;
  i number;
  pos number;

begin
  p_show:=sys.diutil.int_to_bool(0);

  if nvl(isdel_,0) = 1 then --удаление записей из таблицы перед загрузкой
    execute immediate 'delete from '||tname_;
  elsif nvl(isdel_,0) = 2 then --truncate записей из таблицы перед загрузкой
    execute immediate 'truncate table '||tname_;
  end if;

  load_Table(p_dir, fname_, tname_, null, p_show);
  if nvl(p_is_comm,0) =1 then
    commit;
  end if;
end;

procedure load_Table( p_dir in varchar2, --директория Oracle, в которой искать файл
                      p_file in varchar2, --имя файла, с расширением
                      p_tname in varchar2, --в какую таблицу грузить
                      p_cnames in varchar2 default NULL,
                      p_show in boolean default false --1-просто показать запрос в OUTPUT, 0 - загрузить
                       )
is
    l_bfile      bfile;
    l_offset  number default 1;
    l_hdr     dbf_header;
    l_flds    field_descriptor_array;
    l_row      rowArray;
    ii number;
begin
    l_bfile := bfilename( p_dir, p_file );
    dbms_lob.fileopen( l_bfile );

    get_header( l_bfile, l_offset, l_hdr, l_flds );

    if ( p_show )
    then
        show( l_hdr, l_flds, p_tname, p_cnames, l_bfile );
    else
        dbms_sql.parse( g_cursor,
                        build_insert(p_tname,p_cnames,l_flds),
                        dbms_sql.native );

        for i in 1 .. l_hdr.no_records loop
            ii:=i;
            l_row := get_row( l_bfile,
                              l_offset,
                              l_hdr,
                              l_flds );

            if ( l_row(0) <> '*' ) -- deleted record
            then
                for i in 1..l_hdr.no_fields loop
                    dbms_sql.bind_variable( g_cursor,
                                            ':bv'||i,
                                            convert(l_row(i),'CL8MSWIN1251','RU8PC866'),
                                            4000 );
                end loop;
                if ( dbms_sql.execute( g_cursor ) <> 1 )
                then
                    raise_application_error( -20001,
                                 'Insert failed ' || sqlerrm );
                end if;
            end if;
        end loop;
    end if;

    dbms_lob.fileclose( l_bfile );
exception
    when others then
        if ( dbms_lob.isopen( l_bfile ) > 0 ) then
            dbms_lob.fileclose( l_bfile );
        end if;
        if sqlcode in (-1722, -1438) then
          raise_application_error( -20001,
              'Таблица '||p_file||', в строке №' || ii ||',- ошибка');
        end if;
        RAISE;
end;

PROCEDURE save_txt_to_file(p_dir in varchar2, p_file_name in varchar2, p_txt in varchar2)
IS
   l_file        UTL_FILE.file_type;
BEGIN
   l_file := UTL_FILE.fopen (p_dir, p_file_name, 'w');

   UTL_FILE.putf (l_file, p_txt);
   UTL_FILE.fclose (l_file);
END save_txt_to_file;

end;
/

