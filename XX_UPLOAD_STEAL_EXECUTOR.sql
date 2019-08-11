CREATE OR REPLACE PACKAGE APPS.XX_UPLOAD_STEAL_EXECUTOR AS
    procedure process_chunk(p_chunk_size number, p_empty_chunk out boolean);
END;
/


CREATE OR REPLACE PACKAGE BODY APPS.XX_UPLOAD_STEAL_EXECUTOR AS

      procedure process_chunk(p_chunk_size number, p_empty_chunk out boolean) is
        cursor getChunkRows is
        select rowid from apps.xx_t_import
       -- where rowid between p_low and p_high
        for update skip locked;
        type t_rowid_tab is table of rowid index by pls_integer;
        l_chunk_tab t_rowid_tab;
        begin
         --   if p_chunk_size is null then return; end if;
            open getChunkRows;
                    -- забираем p_chunk_size строк, запускаем АПИ, удаляем строки и уходим
                    fetch getChunkRows  bulk collect into l_chunk_tab limit p_chunk_size;
                    if l_chunk_tab.count>0 then
                        for ind in 1..l_chunk_tab.last loop
                            XX_UPLOAD_API_EXECUTOR.execute_api_unlocked(l_chunk_tab(ind));
                        end loop;
                    forall i in 1..l_chunk_tab.count 
                        delete from apps.xx_t_import where rowid=l_chunk_tab(i);
                    end if;
                    
            close getChunkRows;
            p_empty_chunk:=(l_chunk_tab.count=0);
        end;
        
END;	
/