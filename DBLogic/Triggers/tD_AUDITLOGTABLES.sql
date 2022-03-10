/**********************************************************************************************************/
/*** Creation of trigger tD_AUDITLOGTABLES 								***/
/**********************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'tD_AUDITLOGTABLES')
begin
	PRINT 'Refreshing trigger tD_AUDITLOGTABLES...'
	DROP TRIGGER tD_AUDITLOGTABLES
end
go

CREATE TRIGGER tD_AUDITLOGTABLES on AUDITLOGTABLES INSTEAD OF  DELETE NOT FOR REPLICATION as
-- TRIGGER :	tD_AUDITLOGTABLES
-- VERSION :	2
-- DESCRIPTION:	Whenever a row is deleted from the AUDITLOGTABLES, a procedure is
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

	-- DR-46488 perform delete as trigger is of type INSTEAD OF.
	delete AU
	from AUDITLOGTABLES AU
	join deleted d on d.TABLENAME = AU.TABLENAME

	-- Get the first row just deleted
	Select @sTableName=min(TABLENAME)
	from deleted

	Set @ErrorCode=@@Error

	-- Process each table just deleted. 
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
			from deleted
			where TABLENAME>@sTableName

			Set @ErrorCode=@@Error
		End
	End
End
go
