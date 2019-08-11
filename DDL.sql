WHENEVER SQLERROR CONTINUE; --чтобы продолжать выполнение, если таблица существует
--drop table  apps.xx_t_import

--это таблица пула
-- создавать таблицы в схеме APPS не следует, однако для данного задачия мы опустим это правило
CREATE TABLE APPS.XX_T_IMPORT
(
    TRX_ID NUMBER(21),
    TRX_DATE DATE,
    TRX_AMOUNT NUMBER,
    EVENT_DATE DATE DEFAULT SYSDATE
)
INITRANS 15
/


--drop table  apps.xx_t_import_standard
--это имитация стандартной таблицы

create table apps.xx_t_import_standard
(
    trx_id number(21),
    trx_date date,
    trx_amount number,
    creation_date date default sysdate,
    last_update_date date default sysdate
)
/



--таблица для некоторых результатов тестирования
create table apps.xx_upload_test_results
(
    test_code varchar2(30) primary key,
    pool_amount number,
    report_html clob
)
/

--таблица для некоторых результатов тестирования
create table apps.xx_upload_test_monitor
(
    test_code varchar2(30) ,
    creation_date date,
    pool_lines_count number
)
/


WHENEVER SQLERROR EXIT 1;