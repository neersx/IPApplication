	/**********************************************************************************************************/
	/*** 7921 Create InsertUSERIDENTITY trigger								***/
	/**********************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'InsertUSERIDENTITY')
   		begin
    		 PRINT 'Refreshing trigger InsertUSERIDENTITY...'
    		 DROP TRIGGER InsertUSERIDENTITY
   		end
  	go

	create trigger InsertUSERIDENTITY on USERIDENTITY for INSERT NOT FOR REPLICATION as
		begin
		 declare  @numrows int,
		          @nullcnt int,
		          @validcnt int,
		          @errno   int,
		          @errmsg  varchar(255)
		 select @numrows = @@rowcount
		
		 /* ACCESSACCOUNT R/1030 USERIDENTITY ON CHILD INSERT RESTRICT */
		 if update(ACCOUNTID)
		 	begin
		    	 select @nullcnt = 0
		    	 select @validcnt = count(*)
		      	 from 	inserted,ACCESSACCOUNT
		         where	inserted.ACCOUNTID = ACCESSACCOUNT.ACCOUNTID

			 select @nullcnt = count(*) 
			 from 	inserted 
			 where  inserted.ACCOUNTID is null

			 if @validcnt + @nullcnt != @numrows
		    	 	begin
		      		 select @errno  = 30002,
		             		@errmsg = 'Error %d Cannot INSERT USERIDENTITY because ACCESSACCOUNT does not exist.'
		      		 goto error
		    		end
		  	end
		 return
		 error:
		 Raiserror  (@errmsg, 16,1, @errno)
		 rollback transaction
		end
	go

