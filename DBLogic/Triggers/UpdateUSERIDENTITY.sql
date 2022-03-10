if exists (select * from sysobjects where type='TR' and name = 'UpdateUSERIDENTITY')
begin
	PRINT 'Refreshing trigger UpdateUSERIDENTITY...'
	DROP TRIGGER UpdateUSERIDENTITY
end
go

CREATE TRIGGER UpdateUSERIDENTITY on USERIDENTITY for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateUSERIDENTITY  
-- VERSION:	4
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2009	MF	17490	2	Ignore if trigger is being fired as a result of the audit details being updated
-- 15 Apr 2009	AT	RFC7887	3	Move setting of @numrows to avoid @@rowcount being reset by IF statement
-- 28 Sep 2012	vql	RFC7887	4	Fix raiserror syntax.
   
declare  @numrows int
Set @numrows = @@rowcount

If NOT UPDATE(LOGDATETIMESTAMP)
begin
	 declare  @nullcnt int,
	          @validcnt int,
	          @insIDENTITYID int,
	          @errno   int,
	          @errmsg  varchar(255)


	 /* USERIDENTITY R/1170 QUERYDEFAULT ON PARENT UPDATE RESTRICT */
	 if update(IDENTITYID)
	 	begin
	    	 if exists (select * from deleted,QUERYDEFAULT
	      		    where QUERYDEFAULT.IDENTITYID = deleted.IDENTITYID)
	    	 	begin
	      		 select @errno  = 30005,
	             		@errmsg = 'Error %d Cannot UPDATE USERIDENTITY because QUERYDEFAULT exists.'
	      		 goto error
	    		end
	  	end

	 /* ACCESSACCOUNT R/1030 USERIDENTITY ON CHILD UPDATE RESTRICT */
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
			 select @errno  = 30007,
     				@errmsg = 'Error %d Cannot UPDATE USERIDENTITY because ACCESSACCOUNT does not exist.'
			 goto error
			end
		 end

	 return
	 error:
	 Raiserror  (@errmsg, 16,1, @errno)
	 rollback transaction
end
go
