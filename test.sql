set serveroutput on;
truncate  table APPS.XX_T_IMPORT;
truncate table APPS.XX_T_IMPORT_STANDARD;

prompt "Инициализация теста"
begin
xx_upload_service_test.init_test('t1');
end;

prompt "Запуск заполнения пула"
begin
xx_upload_service_test.fill_pool_simple('t1');
xx_upload_service_test.submit_producer_job('t1',&&MINUTES_COUNT); -- мы уже заполнили записей на 1 мин строкой выше, поэтому -1
end;

prompt "Запуск 10 обработчиков"
begin
xx_upload_service_test.submit_consumer_jobs;
end;

prompt "Запуск монитора"
begin
    XX_UPLOAD_SERVICE_TEST.submit_monitor_job('t1',&&MINUTES_COUNT+2);
end;


prompt "Активные задачи в работе"

SELECT j.state,j.job_name FROM dba_SCHEDULER_JOBS j where lower(job_name) like 'xx%'
order by 2;