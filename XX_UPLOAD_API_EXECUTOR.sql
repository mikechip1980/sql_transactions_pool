CREATE OR REPLACE PACKAGE APPS.XX_UPLOAD_API_EXECUTOR AS
   procedure execute_api_locked(p_rowid rowid);
   procedure execute_api_unlocked(p_rowid rowid);
END;
/

CREATE OR REPLACE PACKAGE BODY APPS.XX_UPLOAD_API_EXECUTOR AS
    x_locked exception;
    pragma exception_init(x_locked, -54);
     
	procedure standard_api(p_trx_id number, p_trx_date date, p_trx_amount number,p_event_date date) is
	pragma autonomous_transaction;-- для отделения от транзакций загрузчика
	l_sysdate date:=sysdate;
	begin
        null;-- Вызов стандартного АПИ или обертки здесь!
    --    put_log('API executed p_trx_id='||p_trx_id||' p_trx_date='||p_trx_date||' p_trx_amount='||p_trx_amount);
        insert into xx_t_import_standard values (p_trx_id,p_trx_date,p_trx_amount,l_sysdate,l_sysdate);
        dbms_lock.sleep(0.05);--имитация выполнения АПИ, к сожалению точность только сотые доли
        commit;
    exception
        when others then
            rollback;
	end;    

procedure execute_api_unlocked(p_rowid rowid) is
	l_data_rec apps.xx_t_import%rowtype;
	begin
		select * into l_data_rec 
		from apps.xx_t_import 
        where rowid=p_rowid;
        standard_api(l_data_rec.trx_id, l_data_rec.trx_date, l_data_rec.trx_amount,l_data_rec.event_date);
		--delete from apps.xx_t_import where rowid=p_rowid;
	exception
        when no_data_found then
            null;   -- кто-то уже удалил сообщение
	end;	


procedure execute_api_locked(p_rowid rowid) is
	l_data_rec apps.xx_t_import%rowtype;
	begin
		select * into l_data_rec 
		from apps.xx_t_import 
        where rowid=p_rowid
        for update nowait;
        standard_api(l_data_rec.trx_id, l_data_rec.trx_date, l_data_rec.trx_amount, l_data_rec.event_date);
		delete from apps.xx_t_import where rowid=p_rowid;
	exception
		when x_locked then
			null;	-- кто-то уже работает над сообщением
        when no_data_found then
            null;   -- кто-то уже удалил сообщение
	end;	


	
END;
/
