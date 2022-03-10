	/******************************************************************************************************************/
	/*** 10045 Create InsertNARRATIVESUBSTITUT trigger								***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'InsertNARRATIVESUBSTITUT')
   		begin
    		 PRINT 'Refreshing trigger InsertNARRATIVESUBSTITUT...'
    		 DROP TRIGGER InsertNARRATIVESUBSTITUT
   		end
  	go

	create trigger InsertNARRATIVESUBSTITUT on NARRATIVESUBSTITUT for INSERT NOT FOR REPLICATION as
		begin
  		 declare @numrows int,
           		 @nullcnt int,
           		 @validcnt int,
           		 @errno   int,
           		 @errmsg  varchar(255)
  		 select  @numrows = @@rowcount

  		 /* NARRATIVE changed to NARRATIVESUBSTITUT ON CHILD INSERT RESTRICT */
  		 if update(ALTERNATENARRATIVE)
  		 	begin
    			 select @nullcnt = 0
    			 select @validcnt = count(*)
      			 from 	inserted,NARRATIVE
        		 where	inserted.ALTERNATENARRATIVE = NARRATIVE.NARRATIVENO
    			 select @nullcnt = count(*) from inserted where inserted.ALTERNATENARRATIVE is null
    			 if @validcnt + @nullcnt != @numrows
    				begin
      				 select @errno  = 30002,
             			 @errmsg = 'Error %d Cannot INSERT NARRATIVESUBSTITUT because NARRATIVE does not exist.'
      				 goto error
    				end
  			end

  		 return
		 error:
    		 Raiserror  (@errmsg, 16,1, @errno)
    		 rollback transaction
		end
	go
