	/******************************************************************************************************************/
	/*** 10041 Create InsertMARGIN trigger										***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'InsertMARGIN')
   		begin
    		 PRINT 'Refreshing trigger InsertMARGIN...'
    		 DROP TRIGGER InsertMARGIN
   		end
  	go

	create trigger InsertMARGIN on MARGIN for INSERT NOT FOR REPLICATION as
		begin
  		 declare @numrows int,
           		 @nullcnt int,
           		 @validcnt int,
           		 @errno   int,
           		 @errmsg  varchar(255)
  		 select  @numrows = @@rowcount

  		 /* NAME R/170 MARGIN ON CHILD INSERT RESTRICT */
  		 if update(DEBTOR)
  		 	begin
    		 	 select @nullcnt = 0
    			 select @validcnt = count(*)
      			 from inserted,NAME
        		 where inserted.DEBTOR = NAME.NAMENO
   			 select @nullcnt = count(*) from inserted where inserted.DEBTOR is null
    			 if @validcnt + @nullcnt != @numrows
    				begin
      				 select @errno  = 30002,
             			 @errmsg = 'Cannot INSERT MARGIN because NAME does not exist.'
      				 goto error
    				end
  			end

  		 /* COUNTRY R/35 MARGIN ON CHILD INSERT RESTRICT */
  		 if update(DEBTORCOUNTRY)
  			begin
    			 select @nullcnt = 0
    			 select @validcnt = count(*)
      			 from 	inserted,COUNTRY
        		 where  inserted.DEBTORCOUNTRY = COUNTRY.COUNTRYCODE
    			 select @nullcnt = count(*) from inserted where inserted.DEBTORCOUNTRY is null
    			 if @validcnt + @nullcnt != @numrows
    				begin
      				 select @errno  = 30002,
             			 @errmsg = 'Error %d Cannot INSERT MARGIN because COUNTRY does not exist.'
      			 	 goto error
    				end
  			end

  		 return
		 error:
    		 Raiserror  (@errmsg, 16,1, @errno)
    		 rollback transaction
		end
	go

