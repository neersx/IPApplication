if exists (select * from sysobjects where type='TR' and name = 'UpdateQUERY')
begin
	PRINT 'Refreshing trigger UpdateQUERY...'
	DROP TRIGGER UpdateQUERY
end
go

CREATE TRIGGER UpdateQUERY on QUERY for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateQUERY  
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
   		  @insQUERYID int,
   		  @errno   int,
   		  @errmsg  varchar(255)

	 /* QUERY R/1171 QUERYDEFAULT ON PARENT UPDATE RESTRICT */
	 if update(QUERYID)
	 	begin
	    	 if exists (select * from deleted,QUERYDEFAULT
	      		    where QUERYDEFAULT.QUERYID = deleted.QUERYID)
	    	 	begin
	      		 select @errno  = 30005,
	             		@errmsg = 'Error %d Cannot UPDATE QUERY because QUERYDEFAULT exists.'
	      		 goto error
	    		end
	  	end
	 return
	 error:
	 Raiserror  (@errmsg, 16,1, @errno)
	 rollback transaction
end
go
