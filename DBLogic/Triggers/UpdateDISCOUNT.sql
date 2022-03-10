if exists (select * from sysobjects where type='TR' and name = 'UpdateDISCOUNT')
begin
	PRINT 'Refreshing trigger UpdateDISCOUNT...'
	DROP TRIGGER UpdateDISCOUNT
end
go

CREATE TRIGGER UpdateDISCOUNT on DISCOUNT for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateDISCOUNT  
-- VERSION:	4
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2009	MF	17490	2	Ignore if trigger is being fired as a result of the audit details being updated
-- 14 Apr 2009	MF	17591	3	Revisit of 17490 as @numrows was not being initialised correctly.
-- 28 Sep 2012 DL	12795	4	Correct syntax error for SQL Server 2012

 declare @numrows int,
	 @nullcnt int,
	 @validcnt int,
	 @insNAMENO int, 
	 @insSEQUENCE smallint,
	 @errno   int,
	 @errmsg  varchar(255)
 select  @numrows = @@rowcount
	 
If NOT UPDATE(LOGDATETIMESTAMP)
begin

	 /* NAME R/60 DISCOUNT ON CHILD UPDATE RESTRICT */
	 if update(EMPLOYEENO)
		begin
		 select @nullcnt = 0
		 select @validcnt = count(*)
		 from inserted,NAME
		 where inserted.EMPLOYEENO = NAME.NAMENO
		 select @nullcnt = count(*) from inserted where inserted.EMPLOYEENO is null
		 if @validcnt + @nullcnt != @numrows
			begin
			 select @errno  = 30007,
     			 @errmsg = 'Error %d Cannot UPDATE DISCOUNT because NAME does not exist.'
			 goto error
			end
		end

	 return
	 error:
--	 raiserror @errno @errmsg
	 Raiserror  ( @errmsg, 16,1, @errno)
	 rollback transaction
end
go
