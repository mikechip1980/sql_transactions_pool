set serveroutput on;
truncate  table APPS.XX_T_IMPORT;
truncate table APPS.XX_T_IMPORT_STANDARD;

prompt "������������� �����"
begin
xx_upload_service_test.init_test('t1');
end;

prompt "������ ���������� ����"
begin
xx_upload_service_test.fill_pool_simple('t1');
xx_upload_service_test.submit_producer_job('t1',&&MINUTES_COUNT); -- �� ��� ��������� ������� �� 1 ��� ������� ����, ������� -1
end;

prompt "������ 10 ������������"
begin
xx_upload_service_test.submit_consumer_jobs;
end;

prompt "������ ��������"
begin
    XX_UPLOAD_SERVICE_TEST.submit_monitor_job('t1',&&MINUTES_COUNT+2);
end;


prompt "�������� ������ � ������"

SELECT j.state,j.job_name FROM dba_SCHEDULER_JOBS j where lower(job_name) like 'xx%'
order by 2;