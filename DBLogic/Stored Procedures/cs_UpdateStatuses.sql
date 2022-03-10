SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateStatuses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_UpdateStatuses.'
	Drop procedure [dbo].[cs_UpdateStatuses]
End
Print '**** Creating Stored Procedure dbo.cs_UpdateStatuses...'
Print ''
GO

CREATE PROCEDURE dbo.cs_UpdateStatuses
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psProgramID		nvarchar(8),
	@pnCaseKey		int,
	@pnCaseStatus		smallint	= null,
	@pnRenewalStatus	smallint	= null,
	@psActionKey		nvarchar(2)	= null,
	@pnCycle		smallint	= null

)
-- PROCEDURE:	cs_UpdateStatuses
-- VERSION:	5
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Updates the Status and/or Renewal Status for a case.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 21-Mar-2003  JEK		 1	Procedure created.  RFC03 Case Workflow.
-- 21-Mar-2003	JEK		 2	Changed to ip_InsertActivityHistory.
-- 11-Nov-2008	SF		 3	Update field length
-- 12-Nov-2008	SF		 4	Backout field length change
-- 27 Jun 2019	MF	DR-49984 5	STOPPAYREASON should be set if there is one associated with the Case Status change.
as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @sStopPayReason nchar(1)

Set @nErrorCode = 0

-- Case Status change required
If (@nErrorCode = 0)
and (@pnCaseStatus is not null)
and not exists (Select 1 from CASES C
			where	C.STATUSCODE = @pnCaseStatus
			and	C.CASEID = @pnCaseKey)
Begin
	-- Update stop pay reason
	Select @sStopPayReason = STOPPAYREASON
	from STATUS
	where STATUSCODE = @pnCaseStatus

	Set @nErrorCode = @@ERROR

	If @nErrorCode=0
	Begin
		-- Update Case Status and Stop Pay Reason if mapped to Status
		Update	CASES
			set STATUSCODE = @pnCaseStatus,
			    STOPPAYREASON = isnull(@sStopPayReason, STOPPAYREASON)
			where CASEID = @pnCaseKey

		Set @nErrorCode = @@ERROR
	End
	
	-- Record on ActivityHistory
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = ip_InsertActivityHistory
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psProgramID		= @psProgramID,	
			@pnCaseKey		= @pnCaseKey,
			@pnStatusCode		= @pnCaseStatus,
			@psActionKey		= @psActionKey,
			@pnCycle		= @pnCycle

	End
End

-- Renewal Status change required
If (@nErrorCode = 0)
and (@pnRenewalStatus is not null)
and not exists (Select 1 from PROPERTY P
			where	P.RENEWALSTATUS = @pnRenewalStatus
			and	P.CASEID = @pnCaseKey)
Begin
	-- Update stop pay reason
	Select @sStopPayReason = STOPPAYREASON
	from STATUS
	where STATUSCODE = @pnRenewalStatus

	Set @nErrorCode = @@ERROR

	If ( @nErrorCode = 0)
	and (@sStopPayReason is not null)
	Begin
		Update	CASES
			set STOPPAYREASON = @sStopPayReason
			where CASEID = @pnCaseKey
	
		Set @nErrorCode = @@ERROR		
	End

	If exists(Select 1 from PROPERTY where CASEID = @pnCaseKey)
	Begin
		-- Update Property
		Update	PROPERTY
			set RENEWALSTATUS = @pnRenewalStatus
			where CASEID = @pnCaseKey
	
		Set @nErrorCode = @@ERROR
	End
	Else
	Begin
		-- Insert Property
		Insert into PROPERTY
			(	CASEID,
				RENEWALSTATUS)
			values	(@pnCaseKey,
				@pnRenewalStatus)
	
		Set @nErrorCode = @@ERROR
	End
End

Return @nErrorCode
GO

Grant execute on dbo.cs_UpdateStatuses to public
GO

