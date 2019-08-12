set serveroutput on;
spool t1_test_report.html;
 SET LINESIZE 32767
 SET LONGCHUNKSIZE 32767
 SET LONG 1000000
 SET TRIMSPOOL ON
 SET AUTOPRINT ON
 SET TERMOUT OFF
 SET FEED OFF
 SET HEADING OFF
 SET VERIFY ON 
 SET TRIMOUT OFF
SET TAB ON
begin
XX_UPLOAD_TEST_REPORT.generate_report;
end;
/
select report_html from xx_upload_test_results
where test_code='t1';
 SET TERMOUT ON
 SET FEED ON
 spool off