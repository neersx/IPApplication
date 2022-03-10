-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_MaintainCaseEvent									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_MaintainCaseEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_MaintainCaseEvent.'
	Drop procedure [dbo].[csw_MaintainCaseEvent]
End
Print '**** Creating Stored Procedure dbo.csw_MaintainCaseEvent...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_MaintainCaseEvent
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnEventKey			int,		-- Mandatory
	@pnEventCycle			smallint,	-- Mandatory
	@pdtEventDate			datetime	= null,
	@pdtEventDueDate		datetime	= null,
	@pnEventTextType		smallint	= null,
	@ptEventText			nvarchar(max)	= null,
	@psCreatedByActionCode		nvarchar(2)	= null,
	@pnCreatedByCriteriaKey		int		= null,
	@pnStaffKey			int		= null,
	@pnPolicingBatchNo		int		= null,
	@psResponsibleNameTypeKey	nvarchar(6)	= null,
	@pbIsStopPolicing		bit		= null,
	@pdtLastModifiedDate		datetime	= null OUTPUT
)
as
-- PROCEDURE:	csw_MaintainCaseEvent
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update CaseEvent using the LastModifiedDate for concurrency.
--		Used in the Actions topic in Web version.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	-----------------------------------------------
-- 28 Sep 2011	LP	RFC10812	1	Procedure created.
-- 18 Apr 2013	LP	RFC13415	2	Event Text should be stored as EVENTLONGTEXT
-- 14 Jan 2014  MS      R100839         3       Remove extra parameters which are not updated from web
-- 02 Mar 2015	MS	R43203		4	Update event text in EVENTTEXT and CASEEVENTTEXT tables
-- 06 May 2016	MF	R61329		5	DATEDUESAVED incorrectly being set to 1 when EVENTDUEDATE is not changed.
--						Removed all references to @bLongFlag variable. 
-- 08 May 2016	MF	R61400		6	TYPEOFREQUEST is incorrectly being determined if EVENTDATE has changed then it
--						should be 3, else if EVENTDUEDATE has change then it should be 2, if EVENTDUEDATE has
--						been cleared out and the Event has not occurred then it should be 6 (to trigger its recalculation).
-- 15 Jun 2017	DV	R70952		7	Insert the policing row only when insert/update to CASEEVENT is successful.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(max)
Declare @sUpdateString 	nvarchar(max)
Declare @sWhereString	nvarchar(max)
Declare @sComma		nchar(1)
Declare @sAnd		nchar(5)
Declare @nOccurredFlag 	decimal(1,0)
Declare @nTypeOfRequest tinyint
Declare @nRowCount	int
Declare @nRowCountEventText int

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update CASEEVENT
			   	set "

	Set @sWhereString = @sWhereString+CHAR(10)+"	CASEID 	= @pnCaseKey
						and 	EVENTNO = @pnEventKey
						and 	CYCLE 	= @pnEventCycle
						and	LOGDATETIMESTAMP = @pdtLastModifiedDate"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EVENTNO = @pnEventKey"
	Set @sComma = ","

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CYCLE = @pnEventCycle"
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"@nTypeOfRequest= CASE WHEN(EVENTDATE<>@pdtEventDate)                        THEN 3" -- EventDate has changed
					   +CHAR(10)        +"                      WHEN(EVENTDATE is null and @pdtEventDate is not null) THEN 3"
					   +CHAR(10)        +"                      WHEN(EVENTDATE is not null and @pdtEventDate is null) THEN 3"
					   +CHAR(10)        +"                      WHEN(@nOccurredFlag=1)                                THEN 3"
					   +CHAR(10)        +"                      WHEN(@nOccurredFlag=0 and  @pdtEventDueDate is null)  THEN 6" -- Recalcultate the Due Date
					   +CHAR(10)        +"                                                                            ELSE 2" -- EventDueDate has changed
					   +CHAR(10)        +"                   END"
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EVENTDATE = @pdtEventDate"
	
	-- if stop policing checkbox ticked then raise event as occurred.
	If @pbIsStopPolicing = 1
	Begin
		Set @nOccurredFlag = 1
	End
	Else 
	Begin
	        Set @nOccurredFlag = CASE WHEN @pdtEventDate is not null then 1 else 0 end
	End
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"OCCURREDFLAG = @nOccurredFlag"			
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EVENTDUEDATE = @pdtEventDueDate"
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DATEDUESAVED = CASE WHEN(EVENTDUEDATE=@pdtEventDueDate) THEN DATEDUESAVED"
					   +CHAR(10)        +"                    WHEN(@pdtEventDueDate is null)      THEN 0"
					   +CHAR(10)        +"                                                        ELSE 1"
					   +CHAR(10)        +"               END"

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EMPLOYEENO = @pnStaffKey"
	
	If (datalength(@psResponsibleNameTypeKey) > 0 or @psResponsibleNameTypeKey is null)
	begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DUEDATERESPNAMETYPE = @psResponsibleNameTypeKey"
	end
	
	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@nTypeOfRequest			tinyint	OUTPUT,
			@pnCaseKey			int,
			@pnEventKey			int,
			@pnEventCycle			smallint,
			@pdtEventDate			datetime,
			@nOccurredFlag			decimal(1,0),
			@pdtEventDueDate		datetime,
			@pnStaffKey			int,
			@psResponsibleNameTypeKey nvarchar(6),
			@pdtLastModifiedDate		datetime',
			@nTypeOfRequest			= @nTypeOfRequest	OUTPUT,
			@pnCaseKey	 		= @pnCaseKey,
			@pnEventKey	 		= @pnEventKey,
			@pnEventCycle	 		= @pnEventCycle,
			@pdtEventDate	 		= @pdtEventDate,
			@nOccurredFlag			= @nOccurredFlag,
			@pdtEventDueDate	 	= @pdtEventDueDate,
			@pnStaffKey			= @pnStaffKey,
			@psResponsibleNameTypeKey	= @psResponsibleNameTypeKey,
			@pdtLastModifiedDate		= @pdtLastModifiedDate

	Set @nRowCount = @@RowCount
	
	Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
		from	CASEEVENT
		where	CASEID	        = @pnCaseKey
		and	EVENTNO		= @pnEventKey
		and	CYCLE		= @pnEventCycle

	If @nErrorCode = 0
	Begin
		exec @nErrorCode = csw_UpdateEventText
			@nRowCount		= @nRowCountEventText	output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture 		= @psCulture,
			@pnCaseKey 		= @pnCaseKey,
			@pnEventKey		= @pnEventKey,
			@pnEventCycle		= @pnEventCycle,
			@pnEventTextType	= @pnEventTextType,
			@ptEventText		= @ptEventText
	End

	If @nErrorCode = 0 and @nRowCount > 0
	Begin		
		exec @nErrorCode = ipw_InsertPolicing
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture 		= @psCulture,
			@pnCaseKey 		= @pnCaseKey,
			@pnEventKey		= @pnEventKey,
			@pnCycle		= @pnEventCycle,
			@psAction		= @psCreatedByActionCode,
			@pnCriteriaNo		= @pnCreatedByCriteriaKey,
			@pnTypeOfRequest	= @nTypeOfRequest,
			@pnPolicingBatchNo	= @pnPolicingBatchNo
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_MaintainCaseEvent to public
GO