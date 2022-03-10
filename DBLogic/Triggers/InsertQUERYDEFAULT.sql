	/**********************************************************************************************************/
	/*** 7921 Create InsertQUERYDEFAULT trigger								***/
	/**********************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'InsertQUERYDEFAULT')
   		begin
    		 PRINT 'Refreshing trigger InsertQUERYDEFAULT...'
    		 DROP TRIGGER InsertQUERYDEFAULT
   		end
  	go

	create trigger InsertQUERYDEFAULT on QUERYDEFAULT for INSERT NOT FOR REPLICATION as
		begin
		 declare  @numrows int,
		          @nullcnt int,
		          @validcnt int,
		          @errno   int,
		          @errmsg  varchar(255)
		
		 select @numrows = @@rowcount

		 /* QUERY R/1171 QUERYDEFAULT ON CHILD INSERT RESTRICT */
		 if update(QUERYID)
		 	begin
		    	 select @nullcnt = 0
		    	 select @validcnt = count(*)
		      	 from 	inserted,QUERY
		         where	inserted.QUERYID = QUERY.QUERYID
		    	 if @validcnt + @nullcnt != @numrows
		    	 	begin
		      		 select @errno  = 30002,
		             		@errmsg = 'Error %d Cannot INSERT QUERYDEFAULT because QUERY does not exist.'
		      		 goto error
		    		end
		  	end
		
		 /* USERIDENTITY R/1170 QUERYDEFAULT ON CHILD INSERT RESTRICT */
		 if update(IDENTITYID)
		 	begin
		    	 select @nullcnt = 0
		    	 select @validcnt = count(*)
		      	 from 	inserted,USERIDENTITY
		         where 	inserted.IDENTITYID = USERIDENTITY.IDENTITYID

		    	 select @nullcnt = count(*) 
			 from 	inserted 
			 where	inserted.IDENTITYID is null

		    	 if @validcnt + @nullcnt != @numrows
		    	 	begin
		      		 select @errno  = 30002,
		             		@errmsg = 'Error %d Cannot INSERT QUERYDEFAULT because USERIDENTITY does not exist.'
		      		 goto error
		    		end
		  	end
		
		 return
		 error:
		 Raiserror  (@errmsg, 16,1, @errno)
		 rollback transaction
		end
	go

