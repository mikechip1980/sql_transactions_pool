SET SERVEROUTPUT ON;
SET VERIFY OFF; 
set lines 256
set trimout on
set tab off

truncate  table APPS.XX_T_IMPORT;
truncate table APPS.XX_T_IMPORT_STANDARD;

accept l_iterations number format '9999' prompt 'Number of data generator job executions : ' default '2'
SET FEEDBACK OFF
prompt "Test initialization"
begin
xx_upload_service_test.init_test('t1');
end;
/


prompt "Pool population jobs start"
begin
xx_upload_service_test.fill_pool_simple('t1');
xx_upload_service_test.submit_producer_job('t1',to_number('&l_iterations')); 
end;
/

prompt "10 Consumer jobs start"
begin
xx_upload_service_test.submit_consumer_jobs;
end;
/

prompt "Monitor process start"
begin
    XX_UPLOAD_SERVICE_TEST.submit_monitor_job('t1',to_number('&l_iterations')+2); -- монитор с запасом
end;
/

prompt "Active tasks in progress"

COLUMN STATE HEADING "Job State" 
COLUMN JOB_NAME HEADING "Job Name"
SELECT j.state,j.job_name FROM dba_SCHEDULER_JOBS j where lower(job_name) like 'xx%'
order by 2;

SET FEEDBACK ON
SET VERIFY ON 