-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertCaseName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertCaseName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertCaseName.'
	Drop procedure [dbo].[csw_InsertCaseName]
End
Print '**** Creating Stored Procedure dbo.csw_InsertCaseName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_InsertCaseName
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory.
	@psNameTypeCode			nvarchar(3),	-- Mandatory.
	@pnNameKey			int,		-- Mandatory.
	@pnSequence			smallint,	-- Mandatory.
	@pnAttentionNameKey		int		= null,
	@pnAddressKey			int		= null,
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
	@pbIsAttentionNameKeyInUse	bit		= 0,
	@pbIsAddressKeyInUse		bit	 	= 0,
	@pbIsReferenceNoInUse		bit	 	= 0,
	@pbIsAssignmentDateInUse	bit	 	= 0,
	@pbIsDateCommencedInUse		bit	 	= 0,
	@pbIsDateCeasedInUse		bit	 	= 0,
	@pbIsBillPercentInUse		bit	 	= 0,
	@pbIsIsInheritedInUse		bit	 	= 0,
	@pbIsInheritedNameKeyInUse	bit	 	= 0,
	@pbIsInheritedRelationshipCodeInUse bit	 	= 0,
	@pbIsInheritedSequenceInUse	bit	 	= 0,
	@pbIsNameVariantKeyInUse	bit	 	= 0,
	@pbIsRemarksInUse		bit		= 0,
	@pbIsCorrespSentInUse		bit		= 0,
	@pbIsCorrespReceivedInUse	bit		= 0
)
as
-- PROCEDURE:	csw_InsertCaseName
-- VERSION:	13
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert CaseName.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 15 Nov 2005	TM	RFC3202	1	Procedure created
-- 03 May 2006	SW	RFC3202 2	Implement new properties 
-- 30 May 2006	IB	RFC3299 3	Store derived attention information against new case names. 
-- 09 Jun 2006	IB	RFC3720 4	Add @pnPolicingBatchNo parameter.
--					Fire change event.
-- 26 Apr 2007	JS	14323	5	Pass new parameter NameType to fn_GetDerivedAttnNameNo.
-- 18 Jul 2008	AT	RFC5749	6	Added Remarks.
-- 28 Aug 2008  LP      RFC6911 7       Insert/Update NAMETYPECLASSIFICATION for new CRM Case Names
-- 29 Aug 2008	AT	R5712	8	Added Correspondence Sent/Received.
-- 23 Jun 2011	LP	R10896	9	Only save street address against CASENAME if the current NAMETYPE.KEEPSTREETFLAG = 1
-- 01 Aug 2011	MF	R11051	10	A change of Name for a given NameType may also impact on the standing instructions for 
--					the Case. Call the procedure ip_RecalculateInstructionType to trigger an CaseEvent recalculations.
-- 17 Jan 2012  MS	R11637  11	CORRESPONDNAME column value will be derived based on Contact checkbox value of Name Type 
-- 11 Apr 2013	DV	R13270	12	Increase the length of nvarchar to 11 when casting or declaring integer
-- 18-Jul-2013	MF	R13663	13	Recalculate Events that require the existence of a Document Case for a given Name Type. The
--					change of Name against the Case for the given Name Type could now mean an Event can occur.
-- 11 Nov 2016 AV	RFC33328	A name/attention combination' error message when adding new Inventor

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare	@nChangeEventNo		int
Declare @dtEventDate		datetime
Declare @sNameKey               nvarchar(11)
Declare @bIsCRMName             bit
Declare @nDerivedAttention      int           
Declare @sAlertXML 		nvarchar(400)

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount  = 0
Set @sNameKey = cast(@pnNameKey as nvarchar(11))
Set @sValuesString = CHAR(10)+" values ("
Set @bIsCRMName = 0

If exists (Select 1 From CASENAME Where CORRESPONDNAME = dbo.fn_GetDerivedAttnNameNo(@pnNameKey, @pnCaseKey, @psNameTypeCode) and CASEID = @pnCaseKey and NAMETYPE = @psNameTypeCode and NAMENO = @pnNameKey and @pnAttentionNameKey is null)
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('CS116','A name-attention combination with the default attention can exist only once. Enter a different case attention to proceed.',
				null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR
		End

If @nErrorCode = 0
Begin
	-- Default street address
	If @pnAddressKey is null
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

If @nErrorCode = 0 and @pbIsAttentionNameKeyInUse = 1 and @pnAttentionNameKey is null
Begin
        Set @sSQLString = "Select @nDerivedAttention = 
                CASE WHEN (convert(bit,NT.COLUMNFLAGS&1)=1 or NT.NAMETYPE in ('I','A')) 
                        THEN dbo.fn_GetDerivedAttnNameNo(@pnNameKey,@pnCaseKey,NT.NAMETYPE) 
                        ELSE NULL END               
	From NAMETYPE NT 
	where NT.NAMETYPE = @psNameTypeCode"
	
	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@nDerivedAttention	int		OUTPUT,
			@pnNameKey		int,
			@pnCaseKey              int,
			@psNameTypeCode		nvarchar(3)',
			@nDerivedAttention	= @nDerivedAttention	OUTPUT,
			@pnNameKey		= @pnNameKey,
			@pnCaseKey              = @pnCaseKey,
			@psNameTypeCode		= @psNameTypeCode
	 
End

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into CASENAME
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"	CASEID,NAMETYPE,NAMENO,SEQUENCE"
	Set @sValuesString = @sValuesString+CHAR(10)+"	@pnCaseKey,@psNameTypeCode,@pnNameKey,@pnSequence"

	If @pbIsAttentionNameKeyInUse = 1
	and @pnAttentionNameKey is not null
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CORRESPONDNAME,DERIVEDCORRNAME"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnAttentionNameKey,0"
	End
	Else
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DERIVEDCORRNAME"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"1"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CORRESPONDNAME"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@nDerivedAttention"		
	End

	If @pbIsAddressKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ADDRESSCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnAddressKey"
		Set @sComma = ","
	End

	If @pbIsReferenceNoInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"REFERENCENO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psReferenceNo"
		Set @sComma = ","
	End

	If @pbIsAssignmentDateInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ASSIGNMENTDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtAssignmentDate"
		Set @sComma = ","
	End

	If @pbIsDateCommencedInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"COMMENCEDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtDateCommenced"
		Set @sComma = ","
	End

	If @pbIsDateCeasedInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EXPIRYDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtDateCeased"
		Set @sComma = ","
	End

	If @pbIsBillPercentInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BILLPERCENTAGE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnBillPercent"
		Set @sComma = ","
	End

	If @pbIsIsInheritedInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"INHERITED"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbIsInherited"
		Set @sComma = ","
	End

	If @pbIsInheritedNameKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"INHERITEDNAMENO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnInheritedNameKey"
		Set @sComma = ","
	End

	If @pbIsInheritedRelationshipCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"INHERITEDRELATIONS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psInheritedRelationshipCode"
		Set @sComma = ","
	End

	If @pbIsInheritedSequenceInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"INHERITEDSEQUENCE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnInheritedSequence"
		Set @sComma = ","
	End

	If @pbIsNameVariantKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"NAMEVARIANTNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnNameVariantKey"
		Set @sComma = ","
	End

	If @pbIsRemarksInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"REMARKS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psRemarks"
		Set @sComma = ","
	End

	If @pbIsCorrespSentInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CORRESPSENT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbCorrespSent"
		Set @sComma = ","
	End

	If @pbIsCorrespReceivedInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CORRESPRECEIVED"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCorrespReceived"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

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
			@nDerivedAttention      int',
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
			@pbCorrespSent 		= @pbCorrespSent,
			@pnCorrespReceived 	= @pnCorrespReceived,
			@nDerivedAttention      = @nDerivedAttention
	Set @nRowCount=@@Rowcount
End

---------------------------------------------
-- RFC11051
-- If the CASENAME has been inserted then
-- check for changes to Standing Instructions
---------------------------------------------
If  @nRowCount>0
and @nErrorCode=0
Begin
	------------------------------------------
	-- If the Name Type inserted is referenced
	-- by any Instruction Type then call a 
	-- procedure to generate any CaseEvent
	-- Policing recalculations.
	------------------------------------------
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
	------------------------------------------
	-- Also reminders may now be able to
	-- be sent as a result of a name type 
	-- being inserted.
	------------------------------------------
	Else If exists (select 1 
			from OPENACTION OA 
			join REMINDERS R	on (R.CRITERIANO=OA.CRITERIANO)
			join CASEEVENT CE	on (CE.CASEID=OA.CASEID
						and CE.EVENTNO=R.EVENTNO
						and CE.OCCURREDFLAG=0)
			where OA.CASEID=@pnCaseKey
			and   OA.POLICEEVENTS=1
			and ((R.EMPLOYEEFLAG =1 and @psNameTypeCode='EMP')
			 or  (R.SIGNATORYFLAG=1 and @psNameTypeCode='SIG')
			 or  (R.NAMETYPE     =@psNameTypeCode)))
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

-- Set Name Type Classification of this Case Name
If @nErrorCode = 0
and exists (SELECT 1 FROM NAMETYPE 
                WHERE PICKLISTFLAGS & 32 = 32
                AND NAMETYPE = @psNameTypeCode)
Begin
        
        exec @nErrorCode = dbo.naw_ToggleNameTypes	@pnUserIdentityId	= @pnUserIdentityId,	
						        @psCulture		= @psCulture,	
						        @pbCalledFromCentura    = @pbCalledFromCentura,
						        @psNameKeys             = @sNameKey,
						        @psNameTypeKeys         = @psNameTypeCode,
						        @pbIsAllowed	        = 1			        
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertCaseName to public
GO