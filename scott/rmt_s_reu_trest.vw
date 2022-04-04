create or replace force view scott.rmt_s_reu_trest as
select "REU","TREST","NAME_TR","TR_FORPLAN","FOR_DEBITS","FOR_SCHET","INK","FOR_PLAT" from scott.s_reu_trest@hotora;

