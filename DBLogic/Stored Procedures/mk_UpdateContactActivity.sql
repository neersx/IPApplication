-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mk_UpdateContactActivity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.mk_UpdateContactActivity.'
	Drop procedure [dbo].[mk_UpdateContactActivity]
End
Print '**** Creating Stored Procedure dbo.mk_UpdateContactActivity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.mk_UpdateContactActivity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnActivityKey		int,		-- Mandatory		
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
	@pdtLogDateTimeStamp	datetime	= null
)
-- PROCEDURE:	mk_UpdateContactActivity
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update a Contact Activity if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 15 Feb 2005  TM	RFC1743	1	Procedure created. 
-- 23 Feb 2005	TM	RFC1743	2	If Activity.LongFlag is null use Activity.Notes column.
-- 31 May 2006	SW	RFC2985	3	Implement new column ClientReference
-- 10 Oct 2014	DV	R26412	4	Use LogDateTimeStamp for concurency check
-- 27 May 2015  MS      R47576  5       Increased size of @psSummary from 100 to 254
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

-- Update the Activity
If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	Update ACTIVITY 
	set	NAMENO			= @pnContactKey,
		ACTIVITYDATE		= @pdtActivityDate,
		EMPLOYEENO		= @pnStaffKey,
		CALLER			= @pnCallerKey,
		RELATEDNAME		= @pnRegardingKey,
		CASEID			= @pnCaseKey,
		REFERREDTO		= @pnReferredToKey,
		INCOMPLETE		= CAST(@pbIsIncomplete as decimal(1,0)),
		SUMMARY			= @psSummary,
		CALLTYPE		= CAST(@pbIsOutgoing as decimal(1,0)),
		CALLSTATUS		= @pnCallStatusCode,
		ACTIVITYCATEGORY	= @pnActivityCategoryKey,
		ACTIVITYTYPE		= @pnActivityTypeKey,
		LONGFLAG		= @nLongFlag,	
		REFERENCENO		= @psReferenceNo,
		NOTES			= CASE WHEN @nLongFlag = 1 THEN NULL ELSE CAST(@ptNotes as nvarchar(254)) END,
		LONGNOTES		= CASE WHEN @nLongFlag = 1 THEN @ptNotes ELSE NULL END,
		CLIENTREFERENCE		= @psClientReference	
	where   ACTIVITYNO		= @pnActivityKey
	and	(LOGDATETIMESTAMP	= @pdtLogDateTimeStamp or @pdtLogDateTimeStamp is null)"

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
					  @psClientReference	nvarchar(50),
					  @pdtLogDateTimeStamp	datetime',					  
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
					  @psClientReference	= @psClientReference,
					  @pdtLogDateTimeStamp	= @pdtLogDateTimeStamp
End


Return @nErrorCode
GO

Grant execute on dbo.mk_UpdateContactActivity to public
GO

