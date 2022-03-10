	/******************************************************************************************************************/
	/*** 10040 Create InsertLETTERSUBSTITUTE trigger								***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'InsertLETTERSUBSTITUTE')
   		begin
    		 PRINT 'Refreshing trigger InsertLETTERSUBSTITUTE...'
    		 DROP TRIGGER InsertLETTERSUBSTITUTE
   		end
  	go

	create trigger InsertLETTERSUBSTITUTE on LETTERSUBSTITUTE for INSERT NOT FOR REPLICATION as
		begin
  		 declare @numrows int,
           		 @nullcnt int,
           		 @validcnt int,
           		 @errno   int,
           		 @errmsg  varchar(255)
  		 select  @numrows = @@rowcount

  		 /* LETTER changed to LETTERSUBSTITUTE ON CHILD INSERT RESTRICT */
  		 if update(ALTERNATELETTER)
  			begin
    			 select @nullcnt = 0
    			 select @validcnt = count(*)
      			 from 	inserted,LETTER
        		 where	inserted.ALTERNATELETTER = LETTER.LETTERNO
    			 select @nullcnt = count(*) from inserted where inserted.ALTERNATELETTER is null
    			 if @validcnt + @nullcnt != @numrows
    				begin
      				 select @errno  = 30002,
             			 @errmsg = 'Error %d Cannot INSERT LETTERSUBSTITUTE because LETTER does not exist.'
      				 goto error
    				end
  			end

  		 return
		 error:
    		 Raiserror  (@errmsg, 16,1, @errno)
    		 rollback transaction
		end
	go

