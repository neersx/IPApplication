-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateCaseName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateCaseName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateCaseName.'
	Drop procedure [dbo].[csw_UpdateCaseName]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateCaseName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_UpdateCaseName
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@psNameTypeCode			nvarchar(3),	-- Mandatory
	@pnNameKey			int,		-- Mandatory
	@pnSequence			smallint,	-- Mandatory
	@pnAttentionNameKey		int		 = null,
	@pnAddressKey			int		 = null,
	@psReferenceNo			nvarchar(80)	= null,
	@pdtAssignmentDate		datetime	= null,
	@pdtDateCommenced		datetime	= null,
	@pdtDateCeased			datetime	= null,
	@pnBillPercent			decimal(5,2)	= null,
	@pbIsInherited			bit		= null,
	@pnInheritedNameKey		int		= null,
	@psInheritedRelationshipCode	nvarchar(3)	= null,
	@pnInheritedSequence		smallint	= null,
	@pnNameVariantKey		int		= null,
	@pnPolicingBatchNo 		int		= null,
	@psRemarks			nvarchar(254)	= null,
	@pbCorrespSent			bit		= null,
	@pnCorrespReceived		int		= null,
	@pdtLastModifiedDate		datetime	= null,
	-- Since this database table has a composite key made up of 
	-- modifiable data, the standard parameters include both old
	-- and current versions of NameTypeCode, NameKey and Sequence.
	@pnOldNameKey			int		= null,
	@pdtOldDateCommenced		datetime	= null
)
as
-- PROCEDURE:	csw_UpdateCaseName
-- VERSION:	17
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update CaseName if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 15 Nov 2005	TM	RFC3202	1	Procedure created
-- 09 Dec 2005	TM	RFC3202	2	Changed inheritance handling.
-- 03 May 2006	SW	RFC3202 3	Implement new properties. Remove clearing of Inherited columns
-- 06 Jun 2006	IB	RFC3299 4	Default attention
-- 14 Jun 2006	IB	RFC3720 5	Add @pnPolicingBatchNo parameter.
--					Fire change event.
-- 26 Apr 2007	JS	14323	6	Pass new parameter NameType to fn_GetDerivedAttnNameNo.
-- 18 Jul 2008	AT	R5749	7	Added Remarks.
-- 29 Aug 2008	AT	R5712	8	Added Correspondence Sent/Received
-- 07 Oct 2008	AT	R6895	9	Synchronise Instructor/Owner for CRM cases
-- 17 Aug 2010	SF	R9570	10	Bug in derived attentioname concurrency check
-- 10 Feb 2011	DV	R100453	11	Case Names not getting updated due to concurrency issue with attentionname 
-- 23 Jun 2011	LP	R10896	12	Only save street address against CASENAME if the current NAMETYPE.KEEPSTREETFLAG = 1
-- 01 Aug 2011	MF	R11051	13	A change of Name for a given NameType may also impact on the standing instructions for 
--					the Case. Call the procedure ip_RecalculateInstructionType to trigger any CaseEvent recalculations.
-- 13 Aug 2012	DV	R12600	14	Use LastModifiedDate for concurrency check
-- 19 Nov 2012	vql	R12600	15	Add GO statement.
-- 18 Jul 2013	MF	R13663	16	Recalculate Events that require the existence of a Document Case for a given Name Type. The
--					change of Name against the Case for the given Name Type could now mean an Event can occur.
-- 21 May 2015	MF	47581	17	Revisit of RFC11051. Only if the NameNo or the DateCommenced is being changed do we need to consider the 
--					impact of standing instruction changes.
-- 11 Nov 2016 AV	RFC33328	A name/attention combination' error message when adding new Inventor

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)
Declare	@nChangeEventNo		int
Declare @dtEventDate		datetime
Declare @sCaseType		nchar(1)
Declare @sAlertXML 		nvarchar(400)

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount  = 0
Set @sWhereString = CHAR(10)+" where "

If exists (Select 1 From CASENAME Where CORRESPONDNAME = dbo.fn_GetDerivedAttnNameNo(@pnNameKey, @pnCaseKey, @psNameTypeCode) and CASEID = @pnCaseKey and NAMETYPE = @psNameTypeCode 
			and NAMENO = @pnNameKey and @pnAttentionNameKey is null and @pdtLastModifiedDate <> LOGDATETIMESTAMP)
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('CS116','A name-attention combination with the default attention can exist only once. Enter a different case attention to proceed.',
				null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR
		End

If @nErrorCode = 0
Begin
	-- Default street address
	If  @pnAddressKey is null
	Begin
		Set @sSQLString = "
		Select @pnAddressKey = N.STREETADDRESS
		from NAMETYPE NT
		join NAME N 	on (N.NAMENO = @pnNameKey)
		where NT.KEEPSTREETFLAG = 1
		and NT.NAMETYPE = @psNameTypeCode"

		exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnAddressKey		int		OUTPUT,
			@pnNameKey		int,
			@psNameTypeCode		nvarchar(3)',
			@pnAddressKey		= @pnAddressKey	OUTPUT,
			@pnNameKey		= @pnNameKey,
			@psNameTypeCode		= @psNameTypeCode
	End
End

If @nErrorCode = 0
Begin
	-- Fire change event	
	Set @sSQLString = "
		Select @pnChangeEventNo = NT.CHANGEEVENTNO
		from NAMETYPE NT
		where NT.NAMETYPE = @psNameTypeCode"

	exec @nErrorCode=sp_executesql @sSQLString,
	      N'@pnChangeEventNo	int			OUTPUT,
		@psNameTypeCode		nvarchar(3)',
		@pnChangeEventNo	= @nChangeEventNo	OUTPUT,
		@psNameTypeCode		= @psNameTypeCode

	If @nErrorCode = 0
	and (@pnNameKey <> @pnOldNameKey or @pdtDateCommenced <> @pdtOldDateCommenced) 
	and @nChangeEventNo is not null
	Begin
		If @pdtDateCommenced is not null
		Begin
			Set @dtEventDate = @pdtDateCommenced
		End
		Else
		Begin
			exec @nErrorCode = dbo.ip_GetCurrentDate
				@pdtCurrentDate		= @dtEventDate	OUTPUT,
				@pnUserIdentityId	= @pnUserIdentityId,
				@psDateType		= 'A', 	-- 'A'- Application Date; 'U'  User Date
				@pbIncludeTime		= 0 	
		End
		
		If @nErrorCode = 0
		Begin
			exec @nErrorCode = dbo.csw_MaintainEventDate
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@pnCaseKey		= @pnCaseKey,
				@pnEventKey		= @nChangeEventNo,
				@pnCycle		= 1,
				@pdtEventDate		= @dtEventDate,
				@psCreatedByActionKey	= null,
				@pnCreatedByCriteriaKey	= null,
				@pnPolicingBatchNo	= @pnPolicingBatchNo,
				@pbIsPolicedEvent	= 1,
				@pbOnHold		= null
		End	
	End
End

If @nErrorCode = 0
Begin
	
	Set @sUpdateString = "Update CASENAME
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
				CASEID = @pnCaseKey and "+CHAR(10)+
				"(LOGDATETIMESTAMP = @pdtLastModifiedDate or @pdtLastModifiedDate is null) and "+CHAR(10)+
				"NAMETYPE = @psNameTypeCode and SEQUENCE = @pnSequence"
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NAMETYPE = @psNameTypeCode"		
	Set @sComma = ","
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NAMENO = @pnNameKey"
	Set @sComma = ","

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SEQUENCE = @pnSequence"
	Set @sComma = ","

		
	-- Attention has not been defaulted
	If @pnAttentionNameKey is not null
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CORRESPONDNAME = @pnAttentionNameKey"
		Set @sComma = ","
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DERIVEDCORRNAME = 0"
	End
	Else 
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CORRESPONDNAME = "+
			"dbo.fn_GetDerivedAttnNameNo(@pnNameKey, @pnCaseKey, @psNameTypeCode)"
		Set @sComma = ","
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DERIVEDCORRNAME = 1"
		Set @sComma = ","
	End		
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ADDRESSCODE = @pnAddressKey"
	Set @sComma = ","

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"REFERENCENO = @psReferenceNo"
	Set @sComma = ","

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ASSIGNMENTDATE = @pdtAssignmentDate"
	Set @sComma = ","

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"COMMENCEDATE = @pdtDateCommenced"
	Set @sComma = ","

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EXPIRYDATE = @pdtDateCeased"
	Set @sComma = ","

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"BILLPERCENTAGE = @pnBillPercent"
	Set @sComma = ","
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"INHERITED = @pbIsInherited"
	Set @sComma = ","
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"INHERITEDNAMENO = @pnInheritedNameKey"
	Set @sComma = ","

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"INHERITEDRELATIONS = @psInheritedRelationshipCode"
	Set @sComma = ","
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"INHERITEDSEQUENCE = @pnInheritedSequence"
	Set @sComma = ","	

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NAMEVARIANTNO = @pnNameVariantKey"
	Set @sComma = ","

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"REMARKS = @psRemarks"
	Set @sComma = ","

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CORRESPSENT = @pbCorrespSent"
	Set @sComma = ","

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CORRESPRECEIVED = @pnCorrespReceived"
	Set @sComma = ","

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnCaseKey		int,
			@psNameTypeCode		nvarchar(3),
			@pnNameKey		int,
			@pnSequence		smallint,
			@pnAttentionNameKey	int,
			@pnAddressKey		int,
			@psReferenceNo		nvarchar(80),
			@pdtAssignmentDate	datetime,
			@pdtDateCommenced	datetime,
			@pdtDateCeased		datetime,
			@pnBillPercent		decimal(5,2),
			@pbIsInherited		bit,
			@pnInheritedNameKey	int,
			@psInheritedRelationshipCode nvarchar(3),
			@pnInheritedSequence	smallint,
			@pnNameVariantKey	int,
			@psRemarks		nvarchar(254),
			@pbCorrespSent		bit,
			@pnCorrespReceived	int,
			@pnOldNameKey		int,
			@pdtOldDateCommenced	datetime,
			@pdtLastModifiedDate	datetime',
			@pnCaseKey	 	= @pnCaseKey,
			@psNameTypeCode	 	= @psNameTypeCode,
			@pnNameKey	 	= @pnNameKey,
			@pnSequence	 	= @pnSequence,
			@pnAttentionNameKey	= @pnAttentionNameKey,
			@pnAddressKey	 	= @pnAddressKey,
			@psReferenceNo	 	= @psReferenceNo,
			@pdtAssignmentDate	= @pdtAssignmentDate,
			@pdtDateCommenced	= @pdtDateCommenced,
			@pdtDateCeased	 	= @pdtDateCeased,
			@pnBillPercent	 	= @pnBillPercent,
			@pbIsInherited	 	= @pbIsInherited,
			@pnInheritedNameKey	= @pnInheritedNameKey,
			@psInheritedRelationshipCode = @psInheritedRelationshipCode,
			@pnInheritedSequence	= @pnInheritedSequence,
			@pnNameVariantKey	= @pnNameVariantKey,
			@psRemarks		= @psRemarks,
			@pbCorrespSent		= @pbCorrespSent,
			@pnCorrespReceived	= @pnCorrespReceived,
			@pnOldNameKey		= @pnOldNameKey,
			@pdtOldDateCommenced	= @pdtOldDateCommenced,
			@pdtLastModifiedDate	= @pdtLastModifiedDate

	Set @nRowCount=@@Rowcount
End

-----------------------------------
-- RFC11051
-- If the NameNo has been updated
-- on the CaseName then check for
-- changes to Standing Instructions
-----------------------------------
If  @nRowCount  > 0
and(@pnNameKey <> @pnOldNameKey or isnull(@pdtDateCommenced,'') <> isnull(@pdtOldDateCommenced,'')) 
and @nErrorCode = 0
Begin
	-----------------------------------------
	-- If the Name Type updated is referenced
	-- by any Instruction Type then call a 
	-- procedure to generate any CaseEvent
	-- Policing recalculations.
	-----------------------------------------
	If exists (select 1 from INSTRUCTIONTYPE where NAMETYPE=@psNameTypeCode OR RESTRICTEDBYTYPE=@psNameTypeCode)
	Begin
		Exec @nErrorCode=dbo.ip_RecalculateInstructionType
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @psCulture,
					@pbCalledFromCentura	= 0,
					@psInstructionType 	= null, 
					@pnPolicingBatchNo 	= @pnPolicingBatchNo,
					@pnCaseKey 		= @pnCaseKey,
					@pnNameKey 		= null,
					@pnInternalSequence	= null,
					@pbExistingEventsOnly	= 0,
					@pbCountryNotChanged	= 0,
					@pbPropertyNotChanged	= 0,
					@pbNameNotChanged	= 0,
					@pbRecalculateReminders	= 1,
					@psNameTypeCode		= @psNameTypeCode
	End
	------------------------------------------------
	-- RFC13663
	-- Recalculate Events that require the existence
	-- of a Document Case for a given Name Type
	------------------------------------------------
	Else If exists (select 1 
			From OPENACTION OA
			join ACTIONS A		on (A.ACTION=OA.ACTION)
			join EVENTCONTROLNAMEMAP EC
						on (EC.CRITERIANO=OA.CRITERIANO
						and @psNameTypeCode=isnull(EC.SUBSTITUTENAMETYPE,EC.APPLICABLENAMETYPE))
			join CASEEVENT CE2	on (CE2.CASEID =OA.CASEID
						and CE2.EVENTNO=EC.EVENTNO
						and CE2.CYCLE  =CASE WHEN(A.NUMCYCLESALLOWED>1) 
									THEN OA.CYCLE 
									ELSE CE2.CYCLE
								END)
			where OA.CASEID=@pnCaseKey
			and OA.POLICEEVENTS=1
			and isnull(CE2.OCCURREDFLAG,0)=0)
	Begin
		Exec @nErrorCode=dbo.ip_RecalculateInstructionType
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @psCulture,
					@pbCalledFromCentura	= 0,
					@psInstructionType 	= null, 
					@pnPolicingBatchNo 	= @pnPolicingBatchNo,
					@pnCaseKey 		= @pnCaseKey,
					@pnNameKey 		= null,
					@pnInternalSequence	= null,
					@pbExistingEventsOnly	= 0,
					@pbCountryNotChanged	= 0,
					@pbPropertyNotChanged	= 0,
					@pbNameNotChanged	= 0,
					@pbRecalculateReminders	= 0,
					@psNameTypeCode		= @psNameTypeCode
	End
End

If @nErrorCode = 0
Begin
	Select @sCaseType = C.CASETYPE
	FROM CASES C
	where C.CASEID = @pnCaseKey

	--  For Opportunities, synchronise the Prospect with the Instructor
	If @sCaseType = 'O' and @psNameTypeCode = '~PR'
	Begin
		update CASENAME
		set NAMENO = @pnNameKey
		where CASEID = @pnCaseKey
		and NAMETYPE = 'I'
	End
	Else If @sCaseType = 'M' and @psNameTypeCode = 'EMP'
	Begin
		--  For Marketing Activities, synchronise the Employee with the Owner/Instructor
		update CASENAME
		set NAMENO = @pnNameKey
		where CASEID = @pnCaseKey
		and NAMETYPE in ('I','O')
	End

End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateCaseName to public
GO