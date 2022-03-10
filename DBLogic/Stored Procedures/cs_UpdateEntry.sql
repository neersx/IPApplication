-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateEntry
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateEntry]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_UpdateEntry.'
	drop procedure [dbo].[cs_UpdateEntry]
	print '**** Creating Stored Procedure dbo.cs_UpdateEntry...'
	print ''
end
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cs_UpdateEntry
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCriteriaKey		int,
	@pnEntryNumber		smallint,
	@psActionKey		nvarchar(2),
	@pnCycle		smallint,
	@psCaseKey		nvarchar(11),
	@psNumberTypeKey	nvarchar(3)	= null,
	@psOfficialNumber	nvarchar(36)	= null,	
	@psOldOfficialNumber 	nvarchar(36)	= null

)
-- PROCEDURE:	cs_UpdateEntry
-- VERSION:	5
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Update Case for an Entry rule.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 21-Mar-2003  JEK	1	Procedure created.  RFC03 Case Workflow.
-- 21-Mar-2003  JEK	2	Change to ip_InsertActivityRequest.
-- 12-Mar-2003	JEK	3	Only update file location if it has changed.
-- 15 Apr 2013	DV	4	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
-- 19 May 2020	DL	5	DR-58943	Ability to enter up to 3 characters for Number type code via client server	


as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @nCaseKey int
Declare @nCaseStatus smallint
Declare @nRenewalStatus smallint
Declare @sFileLocationKey nvarchar(11)
Declare @sOldFileLocationKey nvarchar(11)
Declare @nRowCount int
Declare @nCounter int
Declare @tDocument table
	(IDENT		int identity(1,1),
	LETTERNO 	smallint,
	COVERINGLETTER 	smallint,
	DELIVERYID 	smallint,
	HOLDFLAG	bit)
Declare @nLetterKey smallint
Declare @nCoveringLetterKey smallint
Declare @nDeliveryID smallint
Declare @bHoldFlag bit
Declare @dtLetterDate datetime

Set @nErrorCode = 0
Set @nCaseKey = cast(@psCaseKey as int)

-- Update official number
If (@nErrorCode = 0)
and (@psNumberTypeKey is not null)
Begin
	exec @nErrorCode = cs_MaintainOfficialNumber
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnCaseKey		= @nCaseKey, 
		@psNumberTypeKey	= @psNumberTypeKey,
		@psOfficialNumber	= @psOfficialNumber,
		@psOldOfficialNumber 	= @psOldOfficialNumber
End

-- Exclude special Ad Hoc Reminder row
If (@nErrorCode = 0)
and (@psActionKey != '__')
Begin
	-- Get entry rule information
	Select	@nCaseStatus = STATUSCODE,
		@nRenewalStatus = RENEWALSTATUS,
		@sFileLocationKey = cast(FILELOCATION as nvarchar(11))
	from	DETAILCONTROL
	where	CRITERIANO = @pnCriteriaKey
	and	ENTRYNUMBER = @pnEntryNumber

	Set @nErrorCode = @@ERROR

	-- Update Case and Renewal Status
	If (@nErrorCode = 0)
	and (	(@nCaseStatus is not null) OR
		(@nRenewalStatus is not null))
	Begin
		exec @nErrorCode = cs_UpdateStatuses
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psProgramID		= 'CPAStart',
			@pnCaseKey		= @nCaseKey,
			@pnCaseStatus		= @nCaseStatus,
			@pnRenewalStatus	= @nRenewalStatus,
			@psActionKey		= @psActionKey,
			@pnCycle		= @pnCycle
	End

	-- Get current File Location
	If (@nErrorCode = 0)
	and (@sFileLocationKey is not null)
	Begin

		Select @sOldFileLocationKey =CL.FILELOCATION
		from 	CASELOCATION CL
		where 	CL.CASEID = @nCaseKey
		and 	CL.WHENMOVED = (select max(CL.WHENMOVED)
				   	FROM CASELOCATION CL
					where CL.CASEID = @nCaseKey)

		Set @nErrorCode = @@ERROR
	End

	-- Update File Location
	If (@nErrorCode = 0)
	and (@sFileLocationKey is not null)
	and (@sFileLocationKey != @sOldFileLocationKey)
	Begin

		exec @nErrorCode = cs_InsertFileLocation
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psCaseKey		= @psCaseKey,
			@psFileLocationKey	= @sFileLocationKey
	End

	-- Produce Letters
	If (@nErrorCode = 0)
	Begin
		Insert into @tDocument
			(LETTERNO,
			COVERINGLETTER,
			DELIVERYID,
			HOLDFLAG)
		Select 	L.LETTERNO,
			L.COVERINGLETTER,
			L.DELIVERYID,
			L.HOLDFLAG
		from	DETAILLETTERS D
		join	LETTER L ON	(L.LETTERNO = D.LETTERNO)
		where	D.CRITERIANO = @pnCriteriaKey
		and	D.ENTRYNUMBER = @pnEntryNumber
		and	D.MANDATORYFLAG = 1

		Select @nRowCount = @@ROWCOUNT, @nErrorCode = @@ERROR
	End

	-- Request Entry Documents
	If (@nErrorCode = 0)
	and (@nRowCount > 0)
	Begin
		Set @nCounter = 1
		While @nCounter <= @nRowCount and @nErrorCode = 0
		Begin
			
			Select 	@nLetterKey 		= LETTERNO,
				@nCoveringLetterKey 	= COVERINGLETTER,
				@nDeliveryID		= DELIVERYID,
				@bHoldFlag		= HOLDFLAG
			from @tDocument
			where IDENT = @nCounter

			Set @dtLetterDate = GetDate()

			exec @nErrorCode = ip_InsertActivityRequest
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@psProgramID		= 'CPAStart',
				@pnCaseKey		= @nCaseKey,
				@pnActivityType		= 32,
				@pnActivityCode		= 3204,	-- Letter
				@psActionKey		= @psActionKey,
				@pnCycle		= @pnCycle,
				@pnLetterKey		= @nLetterKey,
				@pnCoveringLetterKey	= @nCoveringLetterKey,
				@pbHoldFlag		= @bHoldFlag,
				@pdtLetterDate		= @dtLetterDate,
				@pnDeliveryID		= @nDeliveryID

			Set @nCounter = @nCounter + 1
		End

	End
End

Return @nErrorCode
GO

Grant execute on dbo.cs_UpdateEntry to public
GO

