/**********************************************************************************************************/
/*** Creation of trigger tI_AUDITLOGTABLES 								***/
/**********************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'tI_AUDITLOGTABLES')
begin
	PRINT 'Refreshing trigger tI_AUDITLOGTABLES...'
	DROP TRIGGER tI_AUDITLOGTABLES
end
go

CREATE TRIGGER tI_AUDITLOGTABLES on AUDITLOGTABLES INSTEAD OF  INSERT NOT FOR REPLICATION as
-- TRIGGER :	tI_AUDITLOGTABLES
-- VERSION :	2
-- DESCRIPTION:	Whenever a new row is inserted into the AUDITLOGTABLES, a procedure is
--		to be generated that will create an appropriate trigger for the table
--		specified in the row inserted.  That trigger will control the capture
--		of audit information for the table itself, log changes if required and
--		assign a key to allow translations to be recorded.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Dec 2007	MF	15192 	1	Trigger Created
-- 01 Mar 2019	DL	DR-46488 2	Change trigger to INSTEAD OF to enable audit trigger generation for AUDITLOGTABLES

Begin
	Declare @ErrorCode	int
	Declare @sTableName	varchar(50)

	-- DR-46488 perform insert as trigger is of type INSTEAD OF.
	insert into AUDITLOGTABLES (TABLENAME, LOGFLAG, REPLICATEFLAG)
	select TABLENAME, LOGFLAG, REPLICATEFLAG from inserted  
	
	-- Get the first row just inserted
	Select @sTableName=min(TABLENAME)
	from inserted

	Set @ErrorCode=@@Error

	-- Process each table just inserted. 
	While @sTableName is not null
	and @ErrorCode=0
	Begin
		exec @ErrorCode=dbo.ipu_UtilGenerateAuditTriggers
						@psTable=@sTableName,
						@pbPrintLog=0

		If @ErrorCode=0
		Begin
			-- Now get the next Table to process

			Select @sTableName=min(TABLENAME)
			from inserted
			where TABLENAME>@sTableName

			Set @ErrorCode=@@Error
		End
	End
End
go
