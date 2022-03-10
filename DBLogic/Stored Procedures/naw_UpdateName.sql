-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateName.'
	Drop procedure [dbo].[naw_UpdateName]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateName
(
	@pnUserIdentityId		int,		 -- Mandatory
	@psCulture			nvarchar(10) 	 = null,
	@pbCalledFromCentura		bit		 = 0,
	@pnNameKey			int,		 -- Mandatory
	@psNameCode			nvarchar(20)	 = null,
	@pbIsIndividual			bit		 = null,
	@pbIsOrganisation		bit		 = null,
	@pbIsStaff			bit		 = null,
	@pbIsClient			bit		 = null,
	@pbIsSupplier			bit		 = null,	
	@psName				nvarchar(254)	 = null,
	@psTitle			nvarchar(20)	 = null,
	@psInitials			nvarchar(10)	 = null,
	@psFirstName			nvarchar(50)	 = null,
	@psMiddleName			nvarchar(50)	 = null,
	@psExtendedName			ntext		 = null,
	@psSuffix			nvarchar(20)	 = null,
	@psSearchKey1			nvarchar(20)	 = null,
	@psSearchKey2			nvarchar(20)	 = null,
	@psNationalityCode		nvarchar(3)	 = null,
	@pdtDateCeased			datetime	 = null,
	@psRemarks			nvarchar(254)	 = null,
	@pnGroupKey			smallint	 = null,
	@pnNameStyleKey			int		 = null,
	@psInstructorPrefix		nvarchar(10)	 = null,
	@pnCaseSequence			smallint	 = null,
	@psAirportCode			nvarchar(5)	 = null,
        @psTaxNo			nvarchar(30)	 = null,

	@psOldNameCode			nvarchar(20)	 = null,
	@pbOldIsIndividual		bit		 = null,
	@pbOldIsOrganisation		bit		 = null,
	@pbOldIsStaff			bit		 = null,
	@pbOldIsClient			bit		 = null,
	@pbOldIsSupplier		bit		 = null,
	@psOldName			nvarchar(254)	 = null,
	@psOldTitle			nvarchar(20)	 = null,
	@psOldInitials			nvarchar(10)	 = null,
	@psOldFirstName			nvarchar(50)	 = null,
	@psOldMiddleName		nvarchar(50)	 = null,
	@psOldSuffix			nvarchar(20)	 = null,
	@psOldExtendedName		ntext		 = null,
	@psOldSearchKey1		nvarchar(20)	 = null,
	@psOldSearchKey2		nvarchar(20)	 = null,
	@psOldNationalityCode		nvarchar(3)	 = null,
	@pdtOldDateCeased		datetime	 = null,
	@psOldRemarks			nvarchar(254)	 = null,
	@pnOldGroupKey			smallint	 = null,
	@pnOldNameStyleKey		int		 = null,
	@psOldInstructorPrefix		nvarchar(10)	 = null,
	@pnOldCaseSequence		smallint	 = null,
	@psOldAirportCode		nvarchar(5)	 = null,
        @psOldTaxNo			nvarchar(30)	 = null,

	@pbIsNameCodeInUse		bit		 = 0,
	@pbIsIndividualInUse		bit		 = 0,
	@pbIsStaffInUse			bit		 = 0,
	@pbIsClientInUse		bit		 = 0,
	@pbIsSupplierInUse		bit		 = 0,
	@pbIsNameInUse			bit		 = 0,
	@pbIsTitleInUse			bit		 = 0,
	@pbIsInitialsInUse		bit		 = 0,
	@pbIsFirstNameInUse		bit		 = 0,
	@pbIsMiddleNameInUse		bit		 = 0,
	@pbIsSuffixInUse		bit		 = 0,
	@pbIsExtendedNameInUse		bit		 = 0,
	@pbIsSearchKey1InUse		bit		 = 0,
	@pbIsSearchKey2InUse		bit		 = 0,
	@pbIsNationalityCodeInUse	bit		 = 0,
	@pbIsDateCeasedInUse		bit		 = 0,
	@pbIsRemarksInUse		bit		 = 0,
	@pbIsGroupKeyInUse		bit		 = 0,
	@pbIsNameStyleKeyInUse		bit		 = 0,
	@pbIsInstructorPrefixInUse	bit		 = 0,
	@pbIsCaseSequenceInUse		bit		 = 0,
	@pbIsAirportCodeInUse		bit		 = 0,
        @pbIsTaxNoInUse			bit		 = 0
)
as
-- PROCEDURE:	naw_UpdateName
-- VERSION:	12
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Name if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 19 Apr 2006	SW	RFC3503	1	Procedure created
-- 15 May 2006	SW	RFC3503	2	Add @pdtDateCeased and @psRemarks
-- 18 Dec 2007	SW	RFC5740	3	Add new columns @pnSource, @pdEstimatedRev and @pnStatus
-- 02 Jan 2008	SW	RFC5740	4	Change column STATUS to NAMESTATUS, add new column CRMONLY
-- 11 Jan 2008	SW	RFC5740	5	Change column SOURCE to NAMESOURCE	
-- 07 Jul 2008	SF	RFC6508	6	Remove references to CRM related columns that have been relocated
-- 11 Dec 2008	MF	17136	7	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID.
-- 28 Aug 2009	MS	RFC8288	8	Add @pnLocalityCode,@pnOldLocalityCode and @pbIsLocalityCodeInUse
-- 10 May 2010	PA	RFC9097	9	Update the TAXNO for a Name
-- 18 Jan 2012	vql	R10930	10	Increase the length of the Name Code column in the Name table from its current 10 char.
-- 26 Oct 2015	vql	R53905	11	Allow maintenance of new name fields (DR-15538).
-- 27 Apr 2018	MF	13571	12	Raise an error if a Name flagged as a client is having that flag removed however the Name has already been
--					used as a client/debtor.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)
Declare @nRowCount		int
Declare @nCount			int
Declare @sAlertXML		nvarchar(400)

Declare @nUsedAsFlag		int
Declare @nUsedBit		int
Declare @nNameCodeLength	int

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "
Set @sAnd = " and "
Set @nRowCount = 1

Set @nUsedAsFlag = 0
Set @nUsedBit = 0

If @nErrorCode = 0
Begin
	--------------------------------------------------------------------------------
	-- Validate that Name that is about to be changed from a Client to a Non Client
	-- has not already been used as a client in the system  If so then raise an
	-- error
	--------------------------------------------------------------------------------
	if (@pbOldIsClient = 1 and @pbIsClient = 0 and @pbIsClientInUse=1
		and (
			   exists(select * from CASENAME      WHERE NAMENO       = @pnNameKey and NAMETYPE in('D','Z') )
			or exists(select * from OPENITEM      WHERE ACCTDEBTORNO = @pnNameKey)
			or exists(select * from DEBTORHISTORY WHERE ACCTDEBTORNO = @pnNameKey)
			or exists(select * from WORKHISTORY   WHERE ACCTCLIENTNO = @pnNameKey)
			or exists(select * from DIARY         WHERE NAMENO       = @pnNameKey)
		))
	Begin			
		Set @sAlertXML = dbo.fn_GetAlertXML('NA999', 'Cannot make this name a non-client as they are a debtor on at least one case or are associated with at least one Time and Billing transaction.', 
					null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update NAME"+CHAR(10)+" set "

	Set @sWhereString = @sWhereString+CHAR(10)+" NAMENO = @pnNameKey"

	If @pbIsNameCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NAMECODE = @psNameCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NAMECODE = @psOldNameCode"
		Set @sComma = ","

		If @psNameCode <> @psOldNameCode and @psNameCode is not null
		Begin

			-- If @psNameCode is numeric, try to pad zeros at the front if necessary
			If isnumeric(@psNameCode) = 1
			Begin
				-- Pad zeros at the front up to the NAMECODELENGTH size.
				Set @sSQLString = '
					select	@nNameCodeLength = COLINTEGER
					from	SITECONTROL
					where	CONTROLID = ''NAMECODELENGTH'''
			
				Exec @nErrorCode = sp_executesql @sSQLString,
					N'
					@nNameCodeLength	int			OUTPUT',
					@nNameCodeLength 	= @nNameCodeLength	OUTPUT
			
				-- Only pad zeros if length of @psNameCode shorter than @nNameCodeLength
				If len(@psNameCode) < @nNameCodeLength
				Begin
					Set @psNameCode = replicate('0', @nNameCodeLength - len(@psNameCode)) + @psNameCode
				End
			End
			Else -- If not numeric, make it uppercase.
			Begin
				Set @psNameCode = upper(@psNameCode)
			End

			If @nErrorCode = 0 
			Begin	
				-- Check if NAMECODE exists
				Set @sSQLString = '
					select	@nCount = count(NAMECODE)
					from	NAME
					where	NAMECODE = @psNameCode'
			
				Exec @nErrorCode = sp_executesql @sSQLString,
					N'
					@nCount		int		OUTPUT,
					@psNameCode	nvarchar(20)',
					@nCount 	= @nCount	OUTPUT,
					@psNameCode	= @psNameCode
			
			End
		
			-- raise error if NAMECODE exists
			If @nErrorCode = 0 and @nCount > 0
			Begin
				Set @sAlertXML = dbo.fn_GetAlertXML('NA1', 'Name Code {0} is already in use.', 
							@psNameCode, null, null, null, null)
				RAISERROR(@sAlertXML, 14, 1)
				Set @nErrorCode = @@ERROR
			End
		End
	End
End

If @nErrorCode = 0
Begin

	-- assumption, if xxxInUse = 1, then we assume xxx flag always there, and use isnull(xxx, 0)
	-- @nUsedBit defines the bits that are used for @nUsedAsFlag
	-- @nUsedAsFlag is an aggregation of all the flags that are used in the update.
	If (@pbIsIndividualInUse = 1 or @pbIsStaffInUse = 1 or @pbIsClientInUse = 1)
	Begin
		If @pbIsIndividualInUse = 1
		Begin
			Set @nUsedBit = @nUsedBit | 1
			Set @nUsedAsFlag = @nUsedAsFlag | coalesce(@pbIsIndividual, ~@pbIsOrganisation, 0) * 1
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"isnull(USEDASFLAG, 0) & 1 = coalesce(@pbOldIsIndividual, ~@pbOldIsOrganisation, 0) * 1"
		End
	
		If @pbIsStaffInUse = 1
		Begin
			Set @nUsedBit = @nUsedBit | 2
			Set @nUsedAsFlag = @nUsedAsFlag | isnull(@pbIsStaff, 0) * 2
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"isnull(USEDASFLAG, 0) & 2 = isnull(@pbOldIsStaff, 0) * 2"
		End
	
		If @pbIsClientInUse = 1
		Begin
			Set @nUsedBit = @nUsedBit | 4
			Set @nUsedAsFlag = @nUsedAsFlag | isnull(@pbIsClient, 0) * 4
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"isnull(USEDASFLAG, 0) & 4 = isnull(@pbOldIsClient, 0) * 4"
		End

		-- (USEDASFLAG & ~@nUsedBit) will reset the bits that are used in the update
		-- (@nUsedBit & @pnUsedAsFlag) will set the bits that are used in the update, and skip bits that are not used in update
		
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"USEDASFLAG = (isnull(USEDASFLAG, 0) & ~@nUsedBit) | (@nUsedBit & @pnUsedAsFlag)"
		Set @sComma = ","
	End

	If @pbIsSupplierInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SUPPLIERFLAG = @pbIsSupplier"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"isnull(SUPPLIERFLAG, 0) = isnull(@pbOldIsSupplier, 0)"
	End

	If @pbIsNameInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NAME = @psName"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NAME = @psOldName"
		Set @sComma = ","

		-- Work out SOUNDEX if needed
		If @psName <> @psOldName
		Begin
			Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SOUNDEX = dbo.fn_SoundsLike(@psName)"
		End
	End

	If @pbIsTitleInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TITLE = @psTitle"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"TITLE = @psOldTitle"
		Set @sComma = ","
		
	End

	If @pbIsInitialsInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"INITIALS = @psInitials"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"INITIALS = @psOldInitials"
		Set @sComma = ","
		
	End

	If @pbIsFirstNameInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FIRSTNAME = @psFirstName"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"FIRSTNAME = @psOldFirstName"
		Set @sComma = ","
		
	End

	If @pbIsMiddleNameInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"MIDDLENAME = @psMiddleName"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"MIDDLENAME = @psOldMiddleName"
		Set @sComma = ","
		
	End

	If @pbIsSuffixInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SUFFIX = @psSuffix"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"SUFFIX = @psOldSuffix"
		Set @sComma = ","
		
	End

	-- Maintain ExtendedName
	If @pbIsExtendedNameInUse = 1 and dbo.fn_IsNtextEqual(@psOldExtendedName, @psExtendedName) = 0 
	Begin

		If @nRowCount > 0 and @psOldExtendedName is null
		Begin
			Exec @nErrorCode = dbo.naw_InsertNameText
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture = @psCulture,
						@pnNameKey = @pnNameKey,
						@psTextTypeKey = 'N',
						@ptText = @psExtendedName

			Set @nRowCount = @@rowcount

		End
		
		If @nRowCount > 0 and @psExtendedName is null
		Begin
			Exec @nErrorCode = dbo.naw_DeleteNameText
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture = @psCulture,
						@pnNameKey = @pnNameKey,
						@psTextTypeKey = 'N'

			Set @nRowCount = @@rowcount
		End

		If (@nRowCount > 0
		and @psExtendedName is not null
		and @psOldExtendedName is not null)
		Begin
			Exec @nErrorCode = dbo.naw_UpdateNameText
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture = @psCulture,
						@pnNameKey = @pnNameKey,
						@psTextTypeKey = 'N',
						@ptOldText = @psOldExtendedName,
						@ptText = @psExtendedName

			Set @nRowCount = @@rowcount
		End

	End
End

If @nRowCount > 0 and @nErrorCode = 0
Begin
	If @pbIsSearchKey1InUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SEARCHKEY1 = @psSearchKey1"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"SEARCHKEY1 = @psOldSearchKey1"
		Set @sComma = ","
		
	End

	If @pbIsSearchKey2InUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SEARCHKEY2 = @psSearchKey2"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"SEARCHKEY2 = @psOldSearchKey2"
		Set @sComma = ","
		
	End

	If @pbIsNationalityCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NATIONALITY = @psNationalityCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NATIONALITY = @psOldNationalityCode"
		Set @sComma = ","
		
	End

	If @pbIsDateCeasedInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DATECEASED = @pdtDateCeased"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"DATECEASED = @pdtOldDateCeased"
		Set @sComma = ","
	End

	If @pbIsRemarksInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"REMARKS = @psRemarks"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"REMARKS = @psOldRemarks"
		Set @sComma = ","
	End

	If @pbIsGroupKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FAMILYNO = @pnGroupKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"FAMILYNO = @pnOldGroupKey"
		Set @sComma = ","
		
	End

	If @pbIsNameStyleKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NAMESTYLE = @pnNameStyleKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NAMESTYLE = @pnOldNameStyleKey"
		Set @sComma = ","
		
	End

	If @pbIsInstructorPrefixInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"INSTRUCTORPREFIX = @psInstructorPrefix"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"INSTRUCTORPREFIX = @psOldInstructorPrefix"
		Set @sComma = ","
		
	End

	If @pbIsCaseSequenceInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CASESEQUENCE = @pnCaseSequence"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CASESEQUENCE = @pnOldCaseSequence"
		Set @sComma = ","
		
	End

	If @pbIsAirportCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"AIRPORTCODE = @psAirportCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"AIRPORTCODE = @psOldAirportCode"
		Set @sComma = ","
	End
        
        If @pbIsTaxNoInUse = 1 and @psTaxNo <> @psOldTaxNo
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TAXNO = @psTaxNo"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"TAXNO = @psOldTaxNo"
	Set @sComma = ","
	End

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey		int,
			@psNameCode		nvarchar(20),
			@pnUsedAsFlag		smallint,
			@nUsedBit		int,
			@pbIsSupplier		bit,
			@psName			nvarchar(254),
			@psTitle		nvarchar(20),
			@psInitials		nvarchar(10),
			@psFirstName		nvarchar(50),
			@psMiddleName		nvarchar(50),
			@psSuffix		nvarchar(20),
			@psSearchKey1		nvarchar(20),
			@psSearchKey2		nvarchar(20),
			@psNationalityCode	nvarchar(3),
			@pdtDateCeased		datetime,
			@psRemarks		nvarchar(254),
			@pnGroupKey		smallint,
			@pnNameStyleKey		int,
			@psInstructorPrefix	nvarchar(10),
			@pnCaseSequence		smallint,
			@psAirportCode		nvarchar(5),
                        @psTaxNo		nvarchar(30),
			@psOldNameCode		nvarchar(20),
			@pbOldIsIndividual	bit,
			@pbOldIsOrganisation	bit,
			@pbOldIsStaff		bit,
			@pbOldIsClient		bit,
			@pbOldIsSupplier	bit,
			@psOldName		nvarchar(254),
			@psOldTitle		nvarchar(20),
			@psOldInitials		nvarchar(10),
			@psOldFirstName		nvarchar(50),
			@psOldMiddleName	nvarchar(50),
			@psOldSuffix		nvarchar(20),
			@psOldSearchKey1	nvarchar(20),
			@psOldSearchKey2	nvarchar(20),
			@psOldNationalityCode	nvarchar(3),
			@pdtOldDateCeased	datetime,
			@psOldRemarks		nvarchar(254),
			@pnOldGroupKey		smallint,
			@pnOldNameStyleKey	int,
			@psOldInstructorPrefix	nvarchar(10),
			@pnOldCaseSequence	smallint,
			@psOldAirportCode	nvarchar(5),
                        @psOldTaxNo		nvarchar(30)',

			@pnNameKey		= @pnNameKey,
			@psNameCode		= @psNameCode,
			@pnUsedAsFlag		= @nUsedAsFlag,
			@nUsedBit		= @nUsedBit,
			@pbIsSupplier		= @pbIsSupplier,
			@psName			= @psName,
			@psTitle		= @psTitle,
			@psInitials		= @psInitials,
			@psFirstName		= @psFirstName,
			@psMiddleName		= @psMiddleName,
			@psSuffix		= @psSuffix,			
			@psSearchKey1		= @psSearchKey1,
			@psSearchKey2		= @psSearchKey2,
			@psNationalityCode	= @psNationalityCode,
			@pdtDateCeased		= @pdtDateCeased,
			@psRemarks		= @psRemarks,
			@pnGroupKey		= @pnGroupKey,
			@pnNameStyleKey		= @pnNameStyleKey,
			@psInstructorPrefix	= @psInstructorPrefix,
			@pnCaseSequence		= @pnCaseSequence,
			@psAirportCode		= @psAirportCode,
                        @psTaxNo	 	= @psTaxNo,
			@psOldNameCode		= @psOldNameCode,
			@pbOldIsIndividual	= @pbOldIsIndividual,
			@pbOldIsOrganisation	= @pbOldIsOrganisation,
			@pbOldIsStaff		= @pbOldIsStaff,
			@pbOldIsClient		= @pbOldIsClient,
			@pbOldIsSupplier	= @pbOldIsSupplier,
			@psOldName		= @psOldName,
			@psOldTitle		= @psOldTitle,
			@psOldInitials		= @psOldInitials,
			@psOldFirstName		= @psOldFirstName,
			@psOldMiddleName	= @psOldMiddleName,
			@psOldSuffix		= @psOldSuffix,
			@psOldSearchKey1	= @psOldSearchKey1,
			@psOldSearchKey2	= @psOldSearchKey2,
			@psOldNationalityCode	= @psOldNationalityCode,
			@pdtOldDateCeased	= @pdtOldDateCeased,
			@psOldRemarks		= @psOldRemarks,
			@pnOldGroupKey		= @pnOldGroupKey,
			@pnOldNameStyleKey	= @pnOldNameStyleKey,
			@psOldInstructorPrefix	= @psOldInstructorPrefix,
			@pnOldCaseSequence	= @pnOldCaseSequence,
			@psOldAirportCode	= @psOldAirportCode,
                        @psOldTaxNo	 	= @psOldTaxNo

End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateName to public
GO
