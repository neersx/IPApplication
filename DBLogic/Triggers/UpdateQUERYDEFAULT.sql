if exists (select * from sysobjects where type='TR' and name = 'UpdateQUERYDEFAULT')
begin
	PRINT 'Refreshing trigger UpdateQUERYDEFAULT...'
	DROP TRIGGER UpdateQUERYDEFAULT
end
go

CREATE TRIGGER UpdateQUERYDEFAULT on QUERYDEFAULT for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateQUERYDEFAULT  
-- VERSION:	4
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2009	MF	17490	2	Ignore if trigger is being fired as a result of the audit details being updated
-- 15 Jul 2009	MF	17869	3	Get @rowcount as first thing in trigger to avoid it getting reset
-- 28 Sep 2012	vql	RFC7887	4	Fix raiserror syntax.

declare @numrows int

set @numrows = @@rowcount

If NOT UPDATE(LOGDATETIMESTAMP)
begin
	 declare  @nullcnt int,
	          @validcnt int,
	          @insDEFAULTID int,
	          @errno   int,
	          @errmsg  varchar(255)

	 /* QUERY R/1171 QUERYDEFAULT ON CHILD UPDATE RESTRICT */
	 if update(QUERYID)
	 	begin
	    	 select @nullcnt = 0
	    	 select @validcnt = count(*)
	      	 from 	inserted,QUERY
	         where	inserted.QUERYID = QUERY.QUERYID

		 if @validcnt + @nullcnt != @numrows
	    	 	begin
	      		 select @errno  = 30007,
	             		@errmsg = 'Error %d Cannot UPDATE QUERYDEFAULT because QUERY does not exist.'
	      		 goto error
	    		end
	  	end
	
	 /* USERIDENTITY R/1170 QUERYDEFAULT ON CHILD UPDATE RESTRICT */
	 if update(IDENTITYID)
	 	begin
	    	 select @nullcnt = 0
	    	 select @validcnt = count(*)
	      	 from 	inserted,USERIDENTITY
	         where	inserted.IDENTITYID = USERIDENTITY.IDENTITYID

		 select @nullcnt = count(*) 
		 from 	inserted 
		 where	inserted.IDENTITYID is null
	    
		 if @validcnt + @nullcnt != @numrows
	    	 	begin
	      		 select @errno  = 30007,
	             		@errmsg = 'Error %d Cannot UPDATE QUERYDEFAULT because USERIDENTITY does not exist.'
	      		 goto error
	    		end
	  	end
	 return
	 error:
	 Raiserror  (@errmsg, 16,1, @errno)
	 rollback transaction
end
go

