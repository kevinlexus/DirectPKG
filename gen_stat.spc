create or replace package scott.gen_stat is

procedure gen_stat_usl(dat_ in date,
                       p_mg in params.period%type default null);

end gen_stat;
/

