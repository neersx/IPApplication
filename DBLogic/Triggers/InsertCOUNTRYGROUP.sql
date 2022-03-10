	/******************************************************************************************************************/
	/*** 10038 Create Insert COUNTRYGROUP trigger									***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'InsertCOUNTRYGROUP')
		begin
	    	 PRINT 'Refreshing trigger InsertCOUNTRYGROUP...'
	    	 DROP TRIGGER InsertCOUNTRYGROUP
	   	end
	go

	create trigger InsertCOUNTRYGROUP on COUNTRYGROUP for INSERT NOT FOR REPLICATION as
		begin
	  		declare @numrows int,
	           		@nullcnt int,
	           		@validcnt int,
	           		@errno   int,
	           		@errmsg  varchar(255)
	
	  		select	@numrows = @@rowcount
	
	  	/* COUNTRY has members COUNTRYGROUP ON CHILD INSERT RESTRICT */
	  	if update(TREATYCODE)
	  		begin
	    		 select @nullcnt = 0
	    		 select @validcnt = count(*)
	      		 from 	inserted,COUNTRY
	        	 where	inserted.TREATYCODE = COUNTRY.COUNTRYCODE
	    		 if @validcnt + @nullcnt != @numrows
	    		 	begin
	      				select @errno  = 30002,
	             			@errmsg = 'Error %d Cannot INSERT COUNTRYGROUP because COUNTRY does not exist.'
	      				goto error
	    			end
	  		end
	
	  	/* COUNTRY is part of COUNTRYGROUP ON CHILD INSERT RESTRICT */
	  	if update(MEMBERCOUNTRY)
	  		begin
	    		 select @nullcnt = 0
	    		 select @validcnt = count(*)
	      		 from 	inserted,COUNTRY
	        	 where	inserted.MEMBERCOUNTRY = COUNTRY.COUNTRYCODE
	    		 if @validcnt + @nullcnt != @numrows
	    		 	begin
	      				select @errno  = 30002,
	             			@errmsg = 'Error %d Cannot INSERT COUNTRYGROUP because COUNTRY does not exist.'
	      				goto error
	    			end
	  		end
	
	  		return
			error:
    			Raiserror  (@errmsg, 16,1, @errno)	    		
	    		rollback transaction
		end
	go

