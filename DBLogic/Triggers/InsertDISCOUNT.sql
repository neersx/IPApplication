	/******************************************************************************************************************/
	/*** 10039 Create InsertDISCOUNT trigger									***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'InsertDISCOUNT')
   		begin
    		 PRINT 'Refreshing trigger InsertDISCOUNT...'
    		 DROP TRIGGER InsertDISCOUNT
   		end
  	go

	create trigger InsertDISCOUNT on DISCOUNT for INSERT NOT FOR REPLICATION as
		begin
  		 declare @numrows int,
           		 @nullcnt int,
           		 @validcnt int,
           		 @errno   int,
           		 @errmsg  varchar(255)
  		 select  @numrows = @@rowcount

  		 /* NAME R/60 DISCOUNT ON CHILD INSERT RESTRICT */
  		 if update(EMPLOYEENO)
  		 	begin
    		 	 select @nullcnt = 0
    			 select @validcnt = count(*)
      			 from inserted,NAME
        		 where inserted.EMPLOYEENO = NAME.NAMENO
    			 select @nullcnt = count(*) from inserted where inserted.EMPLOYEENO is null
    			 if @validcnt + @nullcnt != @numrows
    				begin
      				 select @errno  = 30002,
             			 @errmsg = 'Error %d Cannot INSERT DISCOUNT because NAME does not exist.'
      				 goto error
    				end
  			end
  		 return
		 error:
    		 Raiserror  (@errmsg, 16,1, @errno)
    		 rollback transaction
		end
	go
