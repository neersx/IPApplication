if exists (select * from sysobjects where type='TR' and name = 'UpdateCOUNTRY')
begin
	PRINT 'Refreshing trigger UpdateCOUNTRY...'
	DROP TRIGGER UpdateCOUNTRY
end
go

CREATE TRIGGER UpdateCOUNTRY on COUNTRY for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateCOUNTRY  
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
           	 @insCOUNTRYCODE nvarchar(3),
           	 @errno   int,
           	 @errmsg  varchar(255)

	  /* COUNTRY has members COUNTRYGROUP ON PARENT UPDATE RESTRICT */
	 if update(COUNTRYCODE)
	 	begin
		 if exists (select * from deleted, COUNTRYGROUP
			    where COUNTRYGROUP.TREATYCODE = deleted.COUNTRYCODE)
		 	 begin
		      	 	select @errno  = 30005,
		             	@errmsg = 'Error %d Cannot UPDATE COUNTRY because COUNTRYGROUP exists.'
		      		goto error
			 end
		end

	/* COUNTRY is part of COUNTRYGROUP ON PARENT UPDATE RESTRICT */
	if update(COUNTRYCODE)
		begin
		 if exists (select * from deleted,COUNTRYGROUP
			    where COUNTRYGROUP.MEMBERCOUNTRY = deleted.COUNTRYCODE)
		 	begin
				select @errno  = 30005,
     				@errmsg = 'Error %d Cannot UPDATE COUNTRY because COUNTRYGROUP exists.'
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

