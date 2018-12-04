create or replace package scott.rep_bills is
  type ccur is ref cursor;
  type rec_bills is record(
    mg1         char(6),
    mg          char(6),
    k_lsk_id    number,
    lsk         char(8),
    streetname  varchar2(42), --
    fio         varchar2(50),
    monthyear   varchar2(30), --
    status      number(1),
    psch        number(1),
    phw         number,
    pgw         number,
    pel         number,
    kul         char(4),
    opl         number(7, 2),
    pldop       number(7, 2),
    kpr         number(3),
    kpr_ot      number(3),
    kpr_wr      number(3),
    kpr_wrp     number(3),
    name_org    t_org.name%type, --
    phone       t_org.phone%type, --
    phone2      t_org.phone2%type, --
    ki          number(2),
    subs_inf    number,
    npp         number,
    usl         char(3),
    nm          varchar2(38),
    lg_mains    number,
    lg_ids      varchar2(300), --
    itg_pen     number,
    itg_pay     number,
    itg_pen_pay number,
    tarif       number,
    pl_svnorm   number,
    vol         number, --
    charges     number, --
    privs       number, --
    changes0    number, --
    ch_proc0    number, --
    changes1    number, --
    changes2    number, --
    sl          number, --сальдо исх.ред.01.10.12
    subs        number, --
    sub_el      number, --
    itog        number, --
    itog_uszn   number, --
    lgname      char(25), --
    lg_id       number,
    cnt         number,
    lg_koef     number,
    fname_sch   varchar2(25), --вынести в параметры
    prev_chrg   number,
    prev_pay    number,
    payment     number,
    penya       number,
    monthpenya  number,
    monthpenya2 number,
    dolg        number,
    old_dolg    number,
    itog_dolg   number,
    ovrpaymnt   number,
    sal_in      number,
    dolg2       number,
    org         number,
    bill_brake  number
    );
  type tbl_bills is table of rec_bills;


  procedure get_breaks(p_reu in kart.reu%type,
                       p_cnt number,
                       p_mg in params.period%type,
                       p_recset OUT SYS_REFCURSOR);

  function pipe_bills(lsk_  in kart.lsk%type,
                      lsk1_ in kart.lsk%type,
                      var_  in number,
                      var2_ in number,
                      kul_  in kart.kul%type,
                      nd_   in kart.nd%type,
                      kw_   in kart.kw%type,
                      mg1_  in params.period%type,
                      mg2_  in params.period%type) return tbl_bills
    pipelined;

procedure main(p_sel_obj in number,
               p_reu in kart.reu%type,
               p_kul in kart.kul%type,
               p_nd in kart.nd%type,
               p_kw in kart.kw%type,
               p_lsk in kart.lsk%type,
               p_lsk1 in kart.lsk%type,
               p_firstrec in number,
               p_lastrec in number,
               p_var2 in number,
               p_var3 in number,
               p_cntrec in number,
               p_mg in params.period%type,
               p_rfcur out ccur
  );
--детализаци€ счета
procedure detail(p_lsk  IN KART.lsk%TYPE,
                 p_mg   IN PARAMS.period%type,
                 p_rfcur out ccur);  
procedure detail2(p_lsk IN KART.lsk%TYPE,
                 p_mg   IN PARAMS.period%type,
                 p_bill_var in number,
                 p_tp in number, --признак услуги, подлежащей расшифровке
                 p_rfcur out ccur
  );        
procedure org(p_mg   IN PARAMS.period%type,
              p_var in number, --тип счета
              p_rfcur out ccur
  );           
procedure deb(p_k_lsk_id in number,
              p_lsk in kart.lsk%type,
              p_rfcur out ccur
  );  
--архивна€ справка, основной запрос
procedure arch(p_k_lsk in number, p_adr in number, p_lsk in kart.lsk%type, 
               p_mg1 in params.period%type, p_mg2 in params.period%type,
               p_rfcur out ccur);
--архивна€ справка, вспомогательный запрос
procedure arch_supp(p_k_lsk in number, p_adr in number, p_lsk in kart.lsk%type, 
               p_mg1 in params.period%type, p_mg2 in params.period%type,
               p_rfcur out ccur);               
end rep_bills;
/

