/**********************************************************************************************************/
/*** Creation of trigger tU_SEARCHRESULTS 								***/
/**********************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'tU_SEARCHRESULTS')
begin
	PRINT 'Refreshing trigger tU_SEARCHRESULTS...'
	DROP TRIGGER tU_SEARCHRESULTS
end
go



CREATE TRIGGER [tU_SEARCHRESULTS] ON [dbo].SEARCHRESULTS FOR UPDATE NOT FOR REPLICATION as

-- TRIGGER :	tU_SEARCHRESULTS
-- VERSION :	2
-- DESCRIPTION:	Whenever a row is updated in the SEARCHRESULTS, if any of the dates changed
--				then re-generate CASEEVENTS for the new dates.
-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 Mar 2008	DL	11964 	 1	Trigger Created
-- 17 Mar 2009	MF	SQA17490 2	Ignore if trigger is being fired as a result of the audit details being updated

If NOT UPDATE(LOGDATETIMESTAMP)
Begin
	Declare @nChangeFlag int
	Declare @nErrorCode int
	Declare @pnPriorArtId int

	set @nChangeFlag = 0

	Select	@nChangeFlag= case when(i.ISSUEDDATE is not null and i.ISSUEDDATE <> d.ISSUEDDATE) then 1 else 0 end +
			case when(i.RECEIVEDDATE is not null and i.RECEIVEDDATE <> d.RECEIVEDDATE) then 1 else 0 end +
			case when(i.PUBLICATIONDATE is not null and i.PUBLICATIONDATE <> d.PUBLICATIONDATE) then 1 else 0 end +
			case when(i.GRANTEDDATE is not null and i.GRANTEDDATE <> d.GRANTEDDATE) then 1 else 0 end +
			case when(i.PRIORITYDATE is not null and i.PRIORITYDATE <> d.PRIORITYDATE) then 1 else 0 end,
			@pnPriorArtId = i.PRIORARTID
		
	from inserted i 
	join deleted d on (d.PRIORARTID = i.PRIORARTID)

	If @nChangeFlag > 0
			exec @nErrorCode=dbo.cs_CreatePriorArtCaseEvent
						@pnUserIdentityId = null,
						@pnPriorArtId	= @pnPriorArtId
End

GO