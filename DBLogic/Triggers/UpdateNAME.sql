if exists (select * from sysobjects where type='TR' and name = 'UpdateNAME')
begin
	PRINT 'Refreshing trigger UpdateNAME...'
	DROP TRIGGER UpdateNAME
end
go

CREATE TRIGGER UpdateNAME on NAME for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateNAME  
-- VERSION:	4
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2009	MF	17490	2	Ignore if trigger is being fired as a result of the audit details being updated
-- 15 Jul 2009	MF	17869	3	Get @rowcount as first thing in trigger to avoid it getting reset
-- 28 Sep 2012 DL	12795	4	Correct syntax error for SQL Server 2012
   
declare @numrows int

set @numrows = @@rowcount

If NOT UPDATE(LOGDATETIMESTAMP)
begin
	 declare @nullcnt int,
	         @validcnt int,
	         @insNAMENO int,
	         @errno   int,
	         @errmsg  varchar(255)

	 /* NAME in relation to ACTIVITY ON PARENT UPDATE RESTRICT */
	 if update(NAMENO)
	 	begin
		 if exists (select * from deleted,ACTIVITY
				where ACTIVITY.RELATEDNAME = deleted.NAMENO)
		 	begin
			 select @errno  = 30005,
     			 @errmsg = 'Error %d Cannot UPDATE NAME because ACTIVITY exists.'
			 goto error
			end
		end

	 if update(NAMENO)
	 	begin
	 	 if exists (select * from deleted,BILLFORMAT
			    where BILLFORMAT.EMPLOYEENO = deleted.NAMENO)
			begin
			 select @errno  = 30005,
     			 @errmsg = 'Error %d Cannot UPDATE NAME because BILLFORMAT exists.'
			 goto error
			end
		end

	 /* NAME R/60 DISCOUNT ON PARENT UPDATE RESTRICT */
	 if update(NAMENO)
	 	begin
		 if exists (select * from deleted,DISCOUNT
			    where DISCOUNT.EMPLOYEENO = deleted.NAMENO)
		 	begin
			 select @errno  = 30005,
     			 @errmsg = 'Error %d Cannot UPDATE NAME because DISCOUNT exists.'
			 goto error
			end
		end

	 /* NAME R/170 MARGIN ON PARENT UPDATE RESTRICT */
	 if update(NAMENO)
	 	begin
	 	 if exists (select * from deleted,MARGIN
			    where MARGIN.DEBTOR = deleted.NAMENO)
		 	begin
			 select @errno  = 30005,
     			 @errmsg = 'Error %d Cannot UPDATE NAME because MARGIN exists.'
			 goto error
			end
		end

	 return
	 error:
	 --raiserror @errno @errmsg
	 Raiserror  ( @errmsg, 16,1, @errno)	 
	 rollback transaction
end
go
