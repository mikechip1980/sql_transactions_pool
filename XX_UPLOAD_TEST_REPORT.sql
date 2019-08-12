set define off;

CREATE OR REPLACE PACKAGE APPS.XX_UPLOAD_TEST_REPORT AS
    procedure generate_report;
END;
/

CREATE OR REPLACE PACKAGE body APPS.XX_UPLOAD_TEST_REPORT AS
 c_xsl xmltype:=xmltype('<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xdb="http://xmlns.oracle.com/xdb" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <xsl:template match="/ROWSET/ROW">
	<html>
	<head>
	  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
	  	  <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.8.0/Chart.min.js"></script>
          <link rel="stylesheet" href="https://unpkg.com/purecss@1.0.1/build/pure-min.css" integrity="sha384-oAOxQR6DkCoMliIh8yFnu25d7Eq/PHS21PClpwjOTeU2jRSq11vu66rf90/cZr47" crossorigin="anonymous"/>
		<title>Pool processing test report</title>
	</head>
	<body>
	<h1>Pool processing test report</h1>
	<p>Parallel sessions count: 10</p>
	<p>Standard API imitation sleep time: 0,05сек </p>
	<p>Test execution time -  <xsl:value-of select="DATES/DATES_ROW/START_DATE"/> -  <xsl:value-of select="DATES/DATES_ROW/END_DATE"/></p>
	<p>Sum of Amount field of the data inserted to the pool:  <xsl:value-of select="TRX_AMOUNT_SUM"/>	</p>
	<p>Sum of Amount field in the Standard imitation table: <xsl:value-of select="POOL_AMOUNT"/></p>
	<i>*Sum must be equal. It means that there are no messages lost and processed twice</i>
	<h2>Results</h2>
	<p>
	<i>*Count of the processed messages will be about 200.  200 is maximum possible amount, 
	 because of the sleep time of the Standard API immitation (dbms_lock.sleep 0.05 sec).
	This is 20 messages per sec for one session and 200 for 10 sessions. 
	For example, 190 means that 10 sessions spent 0,5% of time for reading the message from the pool</i>
	</p><p>	<i>*Digits in the Pool count column are multiple 100 due to  fetch collect array size</i></p>
	<canvas id="myChart" width="300" height="200"></canvas>
    <table class="pure-table pure-table-bordered">
	 <tr>
		<th>Date and Time</th>
		<th>Count of processed messages per second</th>
		<th>Count of rows in the pool, logged every 5 sec</th>
	   </tr>
	   <xsl:for-each select="RESULTS/RESULTS_ROW">
	   <tr> 
		<td class="cr_date"> <xsl:value-of select="CREATION_DATE"/></td>
		<td class="amt_per_sec"> <xsl:value-of select="CNT_PER_SEC"/></td>
		<td class="pool_lines"> <xsl:value-of select="POOL_LINES_COUNT"/></td>
	  </tr>
	   </xsl:for-each>
	</table>
	</body>
	<script>
	  var ctx = document.getElementById("myChart");
  function getValues(class_name) {
	  var d_list=document.querySelectorAll(class_name);
	  var data=[];
	  for (i = 0;i!=d_list.length; ++i) {
	  data[i]=d_list[i].textContent;
	}
	return data;
  }
	var dates=getValues(".cr_date");
	var cnt_per_sec=getValues(".amt_per_sec");
var myChart = new Chart(ctx, {
  type: "line",
  data: {
    labels: dates,
    datasets: [
      { 
      	label:"Count of processed messages per second",
        data: cnt_per_sec
      }
    ]
  },
    options: {
    responsive: true,
    maintainAspectRatio: false,
    scales: {
        yAxes: [{
            ticks: {
                beginAtZero:true
            }
        }]
    }
    }
});
 </script>
	</html>
  </xsl:template>	
  </xsl:stylesheet>');
  procedure print_clob(v_xml clob) is
  l_offset pls_integer:=1;
  l_line varchar2(32767);
  l_cut  pls_integer;
  begin
     dbms_output.enable(NULL); 
       loop exit when l_offset > dbms_lob.getlength(v_xml);
       l_line:=replace(replace(dbms_lob.substr( v_xml, 255,l_offset),'&quot;','"'),'<tr>','<tr>'||chr(10));
       DBMS_OUTPUT.PUT(l_line);
       l_offset := l_offset + 255;
        end loop;
       -- DBMS_OUTPUT.NEW_LINE;
  end;
  
    procedure generate_report is
    l_output xmltype;
    l_xml xmltype;
    l_cursor sys_refcursor;
     qryCtx DBMS_XMLGEN.ctxHandle;
     
    begin
    
    open l_cursor for
            select 
        (select sum(trx_amount) from xx_t_import_standard ) TRX_AMOUNT_SUM,
        (select pool_amount from xx_upload_test_results where test_code='t1') POOL_AMOUNT,
        cursor(select to_char(min(creation_date),'dd.mm.yyyy hh24:mi:ss') start_date,
                to_char(max(creation_date),'dd.mm.yyyy hh24:mi:ss') end_date, 
                (max(creation_date)-min(creation_date))*24*60*60 duration_sec from xx_t_import_standard) DATES,
        cursor(    select to_char(st.creation_date,'dd.mm.yyyy hh24:mi:ss') creation_date,  st.cnt cnt_per_sec,
                m.pool_lines_count from 
                (select creation_date,count(1) cnt from xx_t_import_standard
                where creation_date<sysdate-1/24/60/60
                group by creation_date
                ) st,
                xx_upload_test_monitor m
            where st.creation_date=m.creation_date(+)
            order by st.creation_date desc) RESULTS
            from dual;
          qryCtx := DBMS_XMLGEN.newContext(l_cursor);
          l_xml := DBMS_XMLGEN.getXMLType(qryCtx);
          l_output:=l_xml.transform(c_xsl);
              

   --     print_clob(l_output. getclobval());
         update xx_upload_test_results set report_html=l_output.getclobval()
         where test_code='t1';
       
    --    l_output:= DBMS_XMLGEN.GETXML(l_cursor)
        commit;
    end;
END;
/