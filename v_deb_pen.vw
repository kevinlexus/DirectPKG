create or replace force view scott.v_deb_pen as
select nvl(d.lsk,p.lsk) as lsk,
       nvl(d.usl, p.usl) as usl,
       nvl(d.org, p.org) as org,
       d.debin,
       d.debrolled,
       d.chrg,
       d.chng,
       d.debpay,
       d.paycorr,
       d.debout,
       p.penin,
       p.penout,
       p.penchrg,
       p.pencorr,
       p.penpay,
       nvl(d.mg, p.mg) as mg
        from
scott.deb d
full join scott.pen p on d.lsk=p.lsk and d.usl=p.usl and d.org=p.org
and d.mg=p.mg and '201404' between p.mgfrom and p.mgto
 and '201404' between d.mgfrom and d.mgto;

