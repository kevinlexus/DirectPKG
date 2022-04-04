create or replace force view scott.rmt_sprorg as
select "KODM","KOD","NAME" from scott.sprorg@hotora;

