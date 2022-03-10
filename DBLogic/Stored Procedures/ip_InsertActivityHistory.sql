SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_InsertActivityHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_InsertActivityHistory.'
	Drop procedure [dbo].[ip_InsertActivityHistory]
End
Print '**** Creating Stored Procedure dbo.ip_InsertActivityHistory...'
Print ''
GO

CREATE PROCEDURE dbo.ip_InsertActivityHistory
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psProgramID		nvarchar(8),
	@pnCaseKey		int,
	@pnStatusCode		smallint	= null,
	@psActionKey		nvarchar(2)	= null,
	@pnEventKey		int		= null,
	@pnCycle		smallint	= null
)
-- PROCEDURE:	ip_InsertActivityHistory
-- VERSION:	3
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Insert ActivityHistory for a case.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21-Mar-2003  JEK		1	Procedure created.  RFC03 Case Workflow.
-- 24-Feb-2004	TM	RFC709	2	Instead of inserting the USERIDENTITY.LOGINID into the ACTIVITYHISTORY.SQLUSER 
--					insert USER. Also, insert the @pnUserIdentityId value into new 
--					ACTIVITYHISTORY.IDENTITYID column.
-- 04-Feb-2009	SF		3		RFC7602 Instead of using USER, use SYSTEM_USER to bring it inline with policing calls.

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
		(Select 1 from ACTIVITYHISTORY
		where	CASEID = @pnCaseKey
		and	WHENREQUESTED = @dtWhenRequested
		and	SQLUSER = SYSTEM_USER)
	Begin
		-- millisecond are held to equivalent to 3.33, so need to add 3
		Set @dtWhenRequested = DateAdd(millisecond,3,@dtWhenRequested)
--		print convert(nvarchar(25), @dtWhenRequested, 121)
	End

	Insert into ACTIVITYHISTORY
	(	CASEID,
		WHENREQUESTED,
		SQLUSER,
		PROGRAMID,
		ACTION,
		EVENTNO,
		CYCLE,
		STATUSCODE,
		IDENTITYID)
	Values	(@pnCaseKey,
		@dtWhenRequested,
		SYSTEM_USER,
		@psProgramID,
		@psActionKey,
		@pnEventKey,
		@pnCycle,
		@pnStatusCode,
		@pnUserIdentityId)

	Set @nErrorCode = @@ERROR

End

Return @nErrorCode
GO

Grant execute on dbo.ip_InsertActivityHistory to public
GO

