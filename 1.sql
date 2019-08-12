set lines 256
set trimout on
set tab off
accept l_iterations number format '9999' prompt 'Number of data generator job executions : '

prompt "Active tasks in progress"

COLUMN STATE HEADING "Job State"
COLUMN JOB_NAME HEADING "Job Name"
SELECT j.state,j.job_name FROM dba_SCHEDULER_JOBS j
order by 2;