CREATE OR REPLACE PACKAGE APPS.XX_UPLOAD_SERVICE AS
   --procedure run_chunks;
    procedure run_steal;
END;
/

CREATE OR REPLACE PACKAGE BODY APPS.XX_UPLOAD_SERVICE AS
  
  
--    procedure run_chunks is
--   l_chunk apps.xx_upload_chunks%rowtype;
--   begin
--   loop
--	--try to get chunk
--	l_chunk:=XX_UPLOAD_CHUNK_EXECUTOR.get_next_chunk;
--	put_log('running chunk '||l_chunk.chunk_num);
--	exit when l_chunk.low is null;
--	XX_UPLOAD_CHUNK_EXECUTOR.process_chunk(l_chunk.low,l_chunk.high);
--    delete from xx_upload_chunks where chunk_num=l_chunk.chunk_num;
--    commit;
--	end loop;
--   end;
--   
     procedure run_steal is
        p_done boolean:=false;
     begin
            loop
              --  put_log('running another chunk ');
                XX_UPLOAD_STEAL_EXECUTOR.process_chunk(100,p_done);
                commit;
                exit when p_done;
            end loop;
     end;

END;
/