SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_InsertActivityRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_InsertActivityRequest.'
	Drop procedure [dbo].[ip_InsertActivityRequest]
End
Print '**** Creating Stored Procedure dbo.ip_InsertActivityRequest...'
Print ''
GO

CREATE PROCEDURE dbo.ip_InsertActivityRequest
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psProgramID		nvarchar(8),
	@pnCaseKey		int,
	@pnActivityType		smallint,
	@pnActivityCode		int,
	@psActionKey		nvarchar(2)	= null,
	@pnEventKey		int		= null,
	@pnCycle		smallint	= null,
	@pnLetterKey		smallint	= null,
	@pnCoveringLetterKey	smallint	= null,
	@pbHoldFlag		bit		= null,
	@pdtLetterDate		datetime	= null,
	@pnDeliveryID		smallint	= null,
	@psEmailOverride	nvarchar(50) 	= null

)
-- PROCEDURE:	ip_InsertActivityRequest
-- VERSION:	4
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Insert ActivityRequest for a case.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21-Mar-2003  JEK		1	Procedure created.  RFC03 Case Workflow.
-- 21-Mar-2003  JEK		2	Implement @psEmailOverride.
-- 24-Feb-2004	TM	RFC709	3	Instead of inserting the USERIDENTITY.LOGINID into the ACTIVITYREQUEST. SQLUSER insert 
--					USER. Also, insert the @pnUserIdentityId value into new ACTIVITYREQUEST.IDENTITYID column.
-- 04-Feb-2009	SF		4		RFC7602 Instead of using USER, use SYSTEM_USER to bring it inline with policing calls.

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare	@dtWhenRequested datetime

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	-- Since DateTime is part of the key it is possible to
	-- get a duplicate key.  Keep trying until a unique DateTime
	-- is extracted.
	set @dtWhenRequested = getdate()

	While exists
		(Select 1 from ACTIVITYREQUEST
		where	CASEID = @pnCaseKey
		and	WHENREQUESTED = @dtWhenRequested
		and	SQLUSER = SYSTEM_USER)
	Begin
		-- millisecond are held to equivalent to 3.33, so need to add 3
		Set @dtWhenRequested = DateAdd(millisecond,3,@dtWhenRequested)
--		print convert(nvarchar(25), @dtWhenRequested, 121)
	End

	Insert into ACTIVITYREQUEST
	(	CASEID,
		WHENREQUESTED,
		SQLUSER,
		PROGRAMID,
		ACTION,
		EVENTNO,
		CYCLE,
		LETTERNO,
		COVERINGLETTERNO,
		HOLDFLAG,
		LETTERDATE,
		DELIVERYID,
		ACTIVITYTYPE,
		ACTIVITYCODE,
		PROCESSED,
		EMAILOVERRIDE,
		IDENTITYID)
	Values	(@pnCaseKey,
		@dtWhenRequested,
		SYSTEM_USER,
		@psProgramID,
		@psActionKey,
		@pnEventKey,
		@pnCycle,
		@pnLetterKey,
		@pnCoveringLetterKey,
		@pbHoldFlag,
		@pdtLetterDate,
		@pnDeliveryID,
		@pnActivityType,
		@pnActivityCode,
		0,
		@psEmailOverride,
		@pnUserIdentityId)

	Set @nErrorCode = @@ERROR

End

Return @nErrorCode
GO

Grant execute on dbo.ip_InsertActivityRequest to public
GO

