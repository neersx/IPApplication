if exists (select * from sysobjects where type='TR' and name = 'UpdateACCESSACCOUNT')
begin
	PRINT 'Refreshing trigger UpdateACCESSACCOUNT...'
	DROP TRIGGER UpdateACCESSACCOUNT
end
go

CREATE TRIGGER UpdateACCESSACCOUNT on ACCESSACCOUNT for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateACCESSACCOUNT  
-- VERSION:	3
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2009	MF	17490	2	Ignore if trigger is being fired as a result of the audit details being updated
-- 15 Jul 2009	MF	17869	3	Get @rowcount as first thing in trigger to avoid it getting reset
   

declare @numrows int

set @numrows = @@rowcount

If NOT UPDATE(LOGDATETIMESTAMP)
begin
	 declare  @nullcnt int,
	          @validcnt int,
	          @insACCOUNTID int,
	          @errno   int,
	          @errmsg  varchar(255)
	          
	 /* ACCESSACCOUNT R/1030 USERIDENTITY ON PARENT UPDATE RESTRICT */
	 if update(ACCOUNTID)
	 	begin
	    	 if exists (select * from deleted,USERIDENTITY
	      		    where USERIDENTITY.ACCOUNTID = deleted.ACCOUNTID)
	    	 	begin
	      		 select @errno  = 30005,
	             		@errmsg = 'Error %d Cannot UPDATE ACCESSACCOUNT because USERIDENTITY exists.'
	      		 goto error
	    		end
		end
	 return
	 error:
	 Raiserror  (@errmsg, 16,1, @errno)
	 rollback transaction
end
go
