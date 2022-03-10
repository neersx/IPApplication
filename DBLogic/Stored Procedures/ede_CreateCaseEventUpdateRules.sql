-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_CreateCaseEventUpdateRules
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_CreateCaseEventUpdateRules]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_CreateCaseEventUpdateRules.'
	Drop procedure [dbo].[ede_CreateCaseEventUpdateRules]
End
Print '**** Creating Stored Procedure dbo.ede_CreateCaseEventUpdateRules...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ede_CreateCaseEventUpdateRules
(
	@psEventNoList		nvarchar(1000)
)
as
-- PROCEDURE:	ede_CreateCaseEventUpdateRules
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Create CASEEVENT update rules to allow automatic update of events when 
--						importing EDE batch associates with renewal.

-- MODIFICATIONS:
-- Date				Who		Change	Version	Description
-- -----------		-------	-------	-------	-----------------------------------------------
-- 10 May 2007		DL			12320		1			Procedure created.
-- 23 May 2007 	DL			12320		2			Added EVENTDUEDATE to update rule


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @sSQLString nvarchar(4000)
Declare @nCriteriaNo int
Declare @nCount int
Declare @nRowUpdated int

Set @nErrorCode = 0

Begin TRANSACTION

-- first check the specified events exist in the EVENTS table
If @nErrorCode = 0
Begin
	Select @nCount = COUNT(TEMP.Parameter)
	from dbo.fn_Tokenise(@psEventNoList, ',') TEMP
	where not exists (select EVENTNO from EVENTS where EVENTNO = TEMP.Parameter)

	If @nCount > 0
	Begin
		print "Cannot create update rules for the following events as they don't exist in Inprotech." 
		print "Please create the events first then try again." 

		Select TEMP.Parameter as 'Invalid event'
		from dbo.fn_Tokenise(@psEventNoList, ',') TEMP
		where not exists (select EVENTNO from EVENTS where EVENTNO = TEMP.Parameter)
		set @nErrorCode = -1
	End
End

-- Is the update rule exist in the criteria table for request type 'Agent Response'?
If @nErrorCode = 0
Begin
	Set @sSQLString ="Select TOP 1 @nCriteriaNo = CR.CRITERIANO 
							From CRITERIA CR
							Where CR.PURPOSECODE = 'U'
							and CR.CASETYPE = 'A'
							and CR.PROPERTYTYPE = 'T'
							and CR.RULEINUSE = '1'
							and CR.USERDEFINEDRULE = 0
							and CR.ISPUBLIC = 0
							and CR.RULETYPE = 10305
							and upper(CR.REQUESTTYPE) = 'AGENT RESPONSE'
							"

	
	Exec @nErrorCode = sp_executesql @sSQLString,
				      N'@nCriteriaNo		int  OUTPUT',
						  @nCriteriaNo		OUTPUT
End



-- If rule does not exist then create the update rule criteria for request type 'Agent Response'
If @nErrorCode = 0 and @nCriteriaNo is null
Begin
	-- Get the next criteriano
	Exec @nErrorCode = dbo.ip_GetLastInternalCode @pnUserIdentityId=0, @psTable='CRITERIA', @pnLastInternalCode=@nCriteriaNo output

	If @nErrorCode = 0 
	Begin
		Set @sSQLString ="Insert into CRITERIA 
								(CRITERIANO, PURPOSECODE, CASETYPE, PROPERTYTYPE, RULEINUSE, USERDEFINEDRULE,
								 ISPUBLIC, RULETYPE, REQUESTTYPE, DESCRIPTION)		
								Values (@nCriteriaNo, 'U', 'A', 'T', '1', 0, 0, 10305, 'Agent Response',
											'Auto update rule for Trade Marks cases associated with request type Agent Response.')
								"
		Exec @nErrorCode = sp_executesql @sSQLString,
								N'@nCriteriaNo 	int OUTPUT',
								  @nCriteriaNo		OUTPUT
	End
End


-- Add events to the update rules 
If @nErrorCode = 0 and @nCriteriaNo IS NOT null 
Begin
	Set @sSQLString ="Insert into EDERULECASEEVENT
							(CRITERIANO, EVENTNO, EVENTDATE, EVENTDUEDATE)		
							Select @nCriteriaNo, TEMP.Parameter, 1, 1
							from dbo.fn_Tokenise(@psEventNoList, ',') TEMP
							where not exists  (select EVENTNO from EDERULECASEEVENT 
															where CRITERIANO = @nCriteriaNo 
															and EVENTNO = TEMP.Parameter )
							"
	Exec @nErrorCode = sp_executesql @sSQLString,
								N'@nCriteriaNo 	int,
								  @psEventNoList  nvarchar(1000)',
								  @nCriteriaNo		= @nCriteriaNo,
								  @psEventNoList 	= @psEventNoList

	Select @nRowUpdated = @@rowcount
End


If @nErrorCode = 0
	COMMIT
else
	ROLLBACK


If @nErrorCode = 0
Begin
	if @nRowUpdated > 0
			print 'Update rules have been created successfully for the specified events under criteria no : ' + cast (@nCriteriaNo as nvarchar(30))
	else if @nRowUpdated = 0
			print 'Update rules already exist for the specified events under criteria no : ' + cast (@nCriteriaNo as nvarchar(30))
End
Else
	print 'Failed to create update rules for the specified events.'

Return @nErrorCode
GO

Grant execute on dbo.ede_CreateCaseEventUpdateRules to public
GO
