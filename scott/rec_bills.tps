CREATE OR REPLACE TYPE SCOTT."REC_BILLS"                                                                          as object(
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
    name_org    varchar2(100), --
    phone       varchar2(50), --
    phone2      varchar2(50), --
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
    org         number)
/

