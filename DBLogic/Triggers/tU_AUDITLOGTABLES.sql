/**********************************************************************************************************/
/*** Creation of trigger tU_AUDITLOGTABLES 								***/
/**********************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'tU_AUDITLOGTABLES')
begin
	PRINT 'Refreshing trigger tU_AUDITLOGTABLES...'
	DROP TRIGGER tU_AUDITLOGTABLES
end
go

CREATE TRIGGER tU_AUDITLOGTABLES on AUDITLOGTABLES INSTEAD OF  UPDATE NOT FOR REPLICATION as
-- TRIGGER :	tU_AUDITLOGTABLES
-- VERSION :	2
-- DESCRIPTION:	Whenever a row is updated in the AUDITLOGTABLES, a procedure is
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

	-- DR-46488 perform update as trigger is of type INSTEAD OF.
	update AU
	set AU.LOGFLAG = i.LOGFLAG
	from AUDITLOGTABLES AU
	join inserted i	on (i.TABLENAME=AU.TABLENAME)

	-- Get the first row just updated

	Select @sTableName=min(i.TABLENAME)
	from inserted i
	join deleted d	on (d.TABLENAME=i.TABLENAME)
	where isnull(i.LOGFLAG,0)<>isnull(d.LOGFLAG,0)

	Set @ErrorCode=@@Error

	-- Process each table just updated. 
	While @sTableName is not null
	and @ErrorCode=0
	Begin
		exec @ErrorCode=dbo.ipu_UtilGenerateAuditTriggers
						@psTable=@sTableName,
						@pbPrintLog=0
		If @ErrorCode=0
		Begin
			-- Now get the next Table to process

			Select @sTableName=min(i.TABLENAME)
			from inserted i
			join deleted d	on (d.TABLENAME=i.TABLENAME)
			where isnull(i.LOGFLAG,0)<>isnull(d.LOGFLAG,0)
			and i.TABLENAME>@sTableName

			Set @ErrorCode=@@Error
		End
	End
End
go
