CREATE OR REPLACE PACKAGE APPS.XX_UPLOAD_SERVICE_TEST AS
    procedure fill_pool_simple(p_test_code varchar2, p_row_count number:=13000); --как раз примерно на 1 минуту процессинга
    PROCEDURE init_test(p_test_code varchar2);
    PROCEDURE monitor_test(p_test_code varchar2);
    PROCEDURE submit_monitor_job(p_test_code varchar2,p_minutes_count number);
    PROCEDURE submit_consumer_jobs;
    procedure submit_producer_job(p_test_code varchar2,p_minutes_count number);
END;
/


create or replace package body apps.xx_upload_service_test as
    procedure submit_consumer_jobs is
    l_job_cnt pls_integer;
    begin
        select value into l_job_cnt from v$parameter where name='job_queue_processes';
        if l_job_cnt<10 then
           raise_application_error(-20001,'job_queue_processes has value less then 10, increase it please');
        end if;
         for i in 1..10 loop
        DBMS_SCHEDULER.CREATE_JOB (
           job_name           =>  'xx'||i,
           job_type           =>  'STORED_PROCEDURE',
           job_action         =>  'apps.xx_upload_service.run_steal',
           start_date         =>  sysdate,
           enabled => FALSE);
           end loop;
           DBMS_SCHEDULER.enable('xx1,xx2,xx3,xx4,xx5,xx6,xx7,xx8,xx9,xx10');
    end;
    
     procedure submit_producer_job(p_test_code varchar2,p_minutes_count number)is
    l_job_cnt pls_integer;
    l_start_date date:=sysdate;
    begin
        select value into l_job_cnt from v$parameter where name='job_queue_processes';
        if l_job_cnt<11 then
           raise_application_error(-20001,'job_queue_processes has value less then 11, increase it please');
        end if;
        DBMS_SCHEDULER.CREATE_JOB (
           job_name           =>  'xx_producer',
           job_type           =>  'PLSQL_BLOCK',
           job_action         =>  'begin apps.xx_upload_service_test.fill_pool_simple('''||p_test_code||'''); end;',
           start_date         =>  l_start_date, --стартуем через минуту, тк до старта нужно уже заполнить пул
           --end_date           =>  l_start_date+1/24/60*(p_minutes_count),
           repeat_interval      => 'FREQ=MINUTELY;INTERVAL=1;', 
           enabled => false);
        DBMS_SCHEDULER.SET_ATTRIBUTE (
               name           =>   'xx_producer',
               attribute      =>   'max_runs',
               value          =>   p_minutes_count);
        DBMS_SCHEDULER.enable('xx_producer');
   
    end;

procedure submit_monitor_job(p_test_code varchar2,p_minutes_count number)is
    l_job_cnt pls_integer;
    l_interval pls_integer:=5; --интервал 5 сек
    begin
        select value into l_job_cnt from v$parameter where name='job_queue_processes';
        if l_job_cnt<13 then
           raise_application_error(-20001,'job_queue_processes has value less then 13, increase it please');
        end if;
        DBMS_SCHEDULER.CREATE_JOB (
           job_name           =>  'xx_monitor',
           job_type           =>  'PLSQL_BLOCK',
           job_action         =>  'begin apps.xx_upload_service_test.monitor_test('''||p_test_code||'''); end;',
           start_date         =>  sysdate,
           end_date           =>  sysdate+1/24/60*p_minutes_count,
           repeat_interval      => 'FREQ=SECONDLY;INTERVAL='||l_interval||';', 
           enabled => false);
        DBMS_SCHEDULER.SET_ATTRIBUTE (
               name           =>   'xx_monitor',
               attribute      =>   'max_runs',
               value          =>   p_minutes_count*60/l_interval);
        DBMS_SCHEDULER.enable('xx_monitor');
   
    end;

    procedure fill_pool_simple(p_test_code varchar2, p_row_count number:=13000) is
    cursor get_data is
    select rownum trx_id, sysdate-rownum trx_date, rownum*10 trx_amount
        from all_objects,all_objects
        where rownum<=p_row_count;
        type t_data_tab is table of get_data%rowtype index by pls_integer;
        l_data_tab t_data_tab ;
        l_amount_sum number:=0;
    begin 
        open get_data;
        fetch get_data bulk collect into l_data_tab;
        close get_data;
        
        for i in 1..l_data_tab.count loop
            l_amount_sum:=l_amount_sum+l_data_tab(i).trx_amount;
        end loop;
        
        update xx_upload_test_results set pool_amount=nvl(pool_amount,0)+l_amount_sum
        where test_code=p_test_code;
        
        forall i in 1..l_data_tab.count 
        insert into apps.xx_t_import values (l_data_tab(i).trx_id, l_data_tab(i).trx_date,l_data_tab(i).trx_amount,sysdate);      
        commit;
    end;
   
 PROCEDURE init_test(p_test_code varchar2) is
 begin
    delete from xx_upload_test_results  where test_code=p_test_code;
    delete from xx_upload_test_monitor  where test_code=p_test_code;
    insert into  xx_upload_test_results values (p_test_code,null,null);
    commit;
 end; 


 PROCEDURE monitor_test(p_test_code varchar2) is
  l_cnt number;
 begin
    select count(1) into l_cnt from apps.xx_t_import;
    insert into  apps.xx_upload_test_monitor values (p_test_code,sysdate,l_cnt);
    commit;
 end; 
     
end;
/