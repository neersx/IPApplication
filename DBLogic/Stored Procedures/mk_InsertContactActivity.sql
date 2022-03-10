-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mk_InsertContactActivity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.mk_InsertContactActivity.'
	Drop procedure [dbo].[mk_InsertContactActivity]
End
Print '**** Creating Stored Procedure dbo.mk_InsertContactActivity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.mk_InsertContactActivity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnActivityKey		int		 = null		OUTPUT,
	@pnContactKey		int		= null,
	@pdtActivityDate	datetime	= null,
	@pnStaffKey		int		= null,
	@pnCallerKey		int		= null,
	@pnRegardingKey		int		= null,
	@pnCaseKey		int		= null,
	@pnReferredToKey	int		= null,
	@pbIsIncomplete		bit		= null,
	@psSummary		nvarchar(254)	= null,
	@pbIsOutgoing		bit		= null,
	@pnCallStatusCode	smallint	= null,
	@pnActivityCategoryKey	int		= null,
	@pnActivityTypeKey	int		= null,
	@psReferenceNo		nvarchar(20)	= null,
	@ptNotes		ntext		= null,
	@psClientReference	nvarchar(50)	= null,
	@pnPriorArtKey		int		= null,
	@pnEventKey		int		= null,
	@pnEventCycle		int		= null
)
-- PROCEDURE:	mk_InsertContactActivity
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Create a new Contact Activity.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14 Feb 2005  TM	RFC1743	1	Procedure created. 
-- 15 Feb 2005	TM	RFC1743	2	Set the 'ANSI_NULLS' to 'ON' instead of 'OFF'. Rename the 
--					@bIsIncomplete from @bIsIncomplete to @pbIsIncomplete.
-- 30 May 2006	SW	RFC2985	3	Insert USERIDENTITYID, CLIENTREFERENCE
-- 23 Feb 2011	JC	RFC6563	4	Insert PRIORARTNO
-- 12 Oct 2011	LP	RFC6896	5	Insert EVENTNO, CYCLE
-- 27 May 2015  MS      R47576  6       Increased size of @psSummary from 100 to 254

AS

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON


Declare @nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @nLongFlag	decimal(1,0)

-- Initialise variables
Set @nErrorCode 	= 0

-- Is the Notes long text?
If (datalength(@ptNotes) <= 508)
or datalength(@ptNotes) is null
Begin
	Set @nLongFlag = 0
End
Else
Begin
	Set @nLongFlag = 1
End

-- Generate Key
If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.ip_GetLastInternalCode
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @psCulture,
					@psTable 		= 'ACTIVITY',
					@pnLastInternalCode 	= @pnActivityKey	OUTPUT
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	insert into ACTIVITY (
		ACTIVITYNO,
		NAMENO,
		ACTIVITYDATE,
		EMPLOYEENO,
		CALLER,
		RELATEDNAME,
		CASEID,
		REFERREDTO,
		INCOMPLETE,
		SUMMARY,
		CALLTYPE,
		CALLSTATUS,
		ACTIVITYCATEGORY,
		ACTIVITYTYPE,
		LONGFLAG,	
		REFERENCENO,
		NOTES,
		LONGNOTES,
		USERIDENTITYID,
		CLIENTREFERENCE,
		PRIORARTID,
		EVENTNO,
		CYCLE)
	values (
		@pnActivityKey,
		@pnContactKey,
		@pdtActivityDate,
		@pnStaffKey,
		@pnCallerKey,
		@pnRegardingKey,
		@pnCaseKey,
		@pnReferredToKey,
		CAST(@pbIsIncomplete as decimal(1,0)),
		@psSummary,
		CAST(@pbIsOutgoing as decimal(1,0)),
		@pnCallStatusCode,
		@pnActivityCategoryKey,
		@pnActivityTypeKey,
		@nLongFlag,
		@psReferenceNo,
		CASE WHEN @nLongFlag = 1 THEN NULL 	ELSE CAST(@ptNotes as nvarchar(254)) END,
		CASE WHEN @nLongFlag = 1 THEN @ptNotes	ELSE NULL END,			
		@pnUserIdentityId,
		@psClientReference,
		@pnPriorArtKey,
		@pnEventKey,
		@pnEventCycle)
		"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnActivityKey	int,
					  @pnContactKey		int,
					  @pdtActivityDate	datetime,
					  @pnStaffKey		int,
					  @pnCallerKey		int,
					  @pnRegardingKey	int,
					  @pnCaseKey		int,
					  @pnReferredToKey	int,
					  @pbIsIncomplete	bit,
					  @psSummary		nvarchar(254),
					  @pbIsOutgoing		bit,
					  @pnCallStatusCode	smallint,
					  @pnActivityCategoryKey int,
					  @pnActivityTypeKey	int,
					  @nLongFlag		decimal(1,0),
					  @psReferenceNo	nvarchar(20),
					  @ptNotes		ntext,
					  @pnUserIdentityId	int,
					  @psClientReference	nvarchar(50),
					  @pnPriorArtKey	int,
					  @pnEventKey		int,
					  @pnEventCycle		int',					  
					  @pnActivityKey	= @pnActivityKey,
					  @pnContactKey		= @pnContactKey,
					  @pdtActivityDate	= @pdtActivityDate,
					  @pnStaffKey		= @pnStaffKey,
					  @pnCallerKey		= @pnCallerKey,
					  @pnRegardingKey	= @pnRegardingKey,
					  @pnCaseKey		= @pnCaseKey,
					  @pnReferredToKey	= @pnReferredToKey,
					  @pbIsIncomplete	= @pbIsIncomplete,
					  @psSummary		= @psSummary,
					  @pbIsOutgoing		= @pbIsOutgoing,
					  @pnCallStatusCode 	= @pnCallStatusCode,
					  @pnActivityCategoryKey = @pnActivityCategoryKey,
					  @pnActivityTypeKey	= @pnActivityTypeKey,
					  @nLongFlag		= @nLongFlag,
					  @psReferenceNo	= @psReferenceNo,
					  @ptNotes		= @ptNotes,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @psClientReference	= @psClientReference,
					  @pnPriorArtKey	= @pnPriorArtKey,
					  @pnEventKey		= @pnEventKey,
					  @pnEventCycle		= @pnEventCycle

	-- Publish generated ActivityNo 
	Select @pnActivityKey as ActivityKey
End


Return @nErrorCode
GO

Grant execute on dbo.mk_InsertContactActivity to public
GO

