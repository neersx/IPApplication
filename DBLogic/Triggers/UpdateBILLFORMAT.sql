if exists (select * from sysobjects where type='TR' and name = 'UpdateBILLFORMAT')
begin
	PRINT 'Refreshing trigger UpdateBILLFORMAT...'
	DROP TRIGGER UpdateBILLFORMAT
end
go

CREATE TRIGGER UpdateBILLFORMAT on BILLFORMAT for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateBILLFORMAT  
-- VERSION:	4
-- DESCRIPTION:	Referential integrity check of EMPLOYEENO against NAME table

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2009	MF	17490	2	Ignore if trigger is being fired as a result of the audit details being updated
-- 15 Jul 2009	MF	17869	3	Allow for EMPLOYEENO to null
-- 28 Sep 2012 DL	12795	4	Correct syntax error for SQL Server 2012
-- 

declare @numrows int

set @numrows = @@rowcount

If NOT UPDATE(LOGDATETIMESTAMP)
begin
	declare @nullcnt		int,
   		@validcnt		int,
   		@insBILLFORMATID	smallint,
   		@errno			int,
   		@errmsg			varchar(255)
	-----------------------------------
	-- Validate that all of the entered
	-- EMPLOYEENO values exist in the 
	-- NAME table.
	-----------------------------------
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
			@errmsg = 'Error %d Cannot UPDATE BILLFORMAT because EMPLOYEENO does not exist in NAME table.'
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

