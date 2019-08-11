WHENEVER SQLERROR CONTINUE; --����� ���������� ����������, ���� ������� ����������
--drop table  apps.xx_t_import

--��� ������� ����
-- ��������� ������� � ����� APPS �� �������, ������ ��� ������� ������� �� ������� ��� �������
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
--��� �������� ����������� �������

create table apps.xx_t_import_standard
(
    trx_id number(21),
    trx_date date,
    trx_amount number,
    creation_date date default sysdate,
    last_update_date date default sysdate
)
/



--������� ��� ��������� ����������� ������������
create table apps.xx_upload_test_results
(
    test_code varchar2(30) primary key,
    pool_amount number,
    report_html clob
)
/

--������� ��� ��������� ����������� ������������
create table apps.xx_upload_test_monitor
(
    test_code varchar2(30) ,
    creation_date date,
    pool_lines_count number
)
/


WHENEVER SQLERROR EXIT 1;