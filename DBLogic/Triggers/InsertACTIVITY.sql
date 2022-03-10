	/******************************************************************************************************************/
	/*** 10036 Create InsertACTIVITY trigger									***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'InsertACTIVITY')
		begin
    		 PRINT 'Refreshing trigger InsertACTIVITY...'
    		 DROP TRIGGER InsertACTIVITY
   		end
  	go

	create trigger InsertACTIVITY on ACTIVITY for INSERT NOT FOR REPLICATION as
		begin
  		 declare @numrows int,
           		 @nullcnt int,
           		 @validcnt int,
           		 @errno   int,
           		 @errmsg  varchar(255)
  		 select	 @numrows = @@rowcount

  		 /* NAME in relation to ACTIVITY ON CHILD INSERT RESTRICT */
  		 if update(RELATEDNAME)
  		 	begin
    			 select @nullcnt = 0
    			 select @validcnt = count(*)
      			 from 	inserted,NAME
        		 where 	inserted.RELATEDNAME = NAME.NAMENO
    			 select @nullcnt = count(*) from inserted where inserted.RELATEDNAME is null
    			 if @validcnt + @nullcnt != @numrows
    				begin
      				 select @errno  = 30002,
             			 @errmsg = 'Error %d Cannot INSERT ACTIVITY because NAME does not exist.'
      				 goto error
    				end
  			end

  		 return
		 error:
    		 Raiserror  (@errmsg, 16,1, @errno)
    		 rollback transaction
		end
	go

