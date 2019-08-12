SET SERVEROUTPUT ON;
SET VERIFY OFF; 
set lines 256
set trimout on
set tab off

accept l_iterations number format '9999' prompt 'Number of data generator job executions : ' default '2'
SET FEEDBACK OFF

prompt "Pool population jobs start"
begin
xx_upload_service_test.fill_pool_simple('t1');
xx_upload_service_test.submit_producer_job('t1',to_number('&&l_iterations')); 
end;
/