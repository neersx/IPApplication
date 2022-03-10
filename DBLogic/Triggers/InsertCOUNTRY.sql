	/******************************************************************************************************************/
	/*** 10042 Create InsertCOUNTRY trigger										***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'InsertCOUNTRY')
   		begin
    		 PRINT 'Refreshing trigger InsertCOUNTRY...'
    		 DROP TRIGGER InsertCOUNTRY
   		end
  	go

	create trigger InsertCOUNTRY on COUNTRY for INSERT NOT FOR REPLICATION as
		begin
  		 declare @numrows int,
           		 @nullcnt int,
           		 @validcnt int,
           		 @errno   int,
           		 @errmsg  varchar(255)
  		 select  @numrows = @@rowcount

  		 /* COUNTRY R/35 MARGIN ON PARENT UPDATE RESTRICT */
  		 if update(COUNTRYCODE)
  			begin
    			 if exists (select * from deleted,MARGIN
      				    where MARGIN.DEBTORCOUNTRY = deleted.COUNTRYCODE)
    				begin
      				 select @errno  = 30005,
             			 @errmsg = 'Error %d Cannot UPDATE COUNTRY because MARGIN exists.'
      				 goto error
    				end
  			end
  		 return
		 error:
    		 Raiserror  (@errmsg, 16,1, @errno)
    		 rollback transaction
		end
	go
