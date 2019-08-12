prompt "Duplicates filter creation"
create or replace view apps.XX_T_IMPORT_FILTER_V 
as 
select * from apps.XX_T_IMPORT
/

--drop index apps.XX_T_IMPORT_N1 

create index apps.XX_T_IMPORT_N1 on apps.XX_T_IMPORT(trx_id) initrans 12
/

CREATE OR REPLACE TRIGGER XX_T_IMPORT_FILTER_V_BI
  INSTEAD OF INSERT ON XX_T_IMPORT_FILTER_V  FOR EACH ROW
DECLARE        
 l_var pls_integer;
BEGIN
    select 1 into l_var from apps.XX_T_IMPORT
    where trx_id=:new.trx_id  -- мы не будем рассматривать сообщения с пустым trx_id
    and ((trx_date=:new.trx_date) or (trx_date is null and :new.trx_date is null))
    and ((trx_amount=:new.trx_amount) or (trx_amount is null and :new.trx_amount is null))
    and ((event_date=:new.event_date) or (event_date is null and :new.event_date is null ))
    and rownum=1;
        --данные уже есть в пуле, значит это дубликат. Не добавляем в пул 
EXCEPTION
    when no_data_found then
        insert into apps.XX_T_IMPORT values(:new.trx_id,:new.trx_date,:new.trx_amount,:new.event_date);
END;
/