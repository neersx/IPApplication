-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertName.'
	Drop procedure [dbo].[naw_InsertName]
End
Print '**** Creating Stored Procedure dbo.naw_InsertName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertName
(
	@pnUserIdentityId		int,		 -- Mandatory
	@psCulture			nvarchar(10) 	 = null,
	@pbCalledFromCentura		bit		 = 0,
	@pnNameKey			int		 = null output,	
	@psNameCode			nvarchar(20)	 = null,	-- can be input
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
	@psSuffix			nvarchar(20)	 = null,
	@psExtendedName			nvarchar(max)	 = null,
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
        @psSelectedNameTypes            nvarchar(1000)   = null,

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
-- PROCEDURE:	naw_InsertName
-- VERSION:	20
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Name.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 12 Apr 2006	SW	R3503	1	Procedure created
-- 04 May 2006	PG	R3503	2	Output NameKey
-- 15 May 2006	SW	R3503	3	Add @pdtDateCeased and @psRemarks
-- 18 Dec 2007	SW	R5740	4	Add new columns @pnSource, @pdEstimatedRev and @pnStatus
-- 02 Jan 2008	SW	R5740	5	Change column STATUS to NAMESTATUS, add new column CRMONLY
-- 11 Jan 2008	SW	R5740	6	Change column SOURCE to NAMESOURCE
-- 25 Mar 2008	Ash	R5438	7	Maintain data in different culture
-- 15 Apr 2008	SF	R6454	8	Backout changes made in RFC5438 temporarily
-- 18 Jun 2008  PS	R6672	9	when inserting a new name, insert a row into the NAMETYPECLASSIFICATION table, with NameType = '~~~', Allow =’1’
-- 07 Jul 2008	SF	R6508	10	Remove references to CRM related columns that have been relocated.
-- 11 Dec 2008	MF	17136	11	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 09 Sep 2009	MS	R8288	12	Add @pbIsAirportCodeInUse and @pnAirportCode
-- 18 nov 2009	LP	R6712	13	Check row access security
-- 10 May 2010	PA	R9097	14	Insert the TAXNO for the Organisation as well as for Individual name
-- 07 Dec 2011	MF	R11664	15	Row level security on Names does not need to check if the Office is held directly against the Case. It
--					should just get the Office from the Attributes assigned to the Name.
-- 18 Jan 2012	vql	R10930	15	Increase the length of the Name Code column in the Name table from its current 10 char.
-- 06 Jun 2013	MF	R13561	16	Use a (R.SECURITYFLAG & 4) to check if the user has INSERT privileges and change the ORDER BY to ASC in
--					the check if a user has insert rights. Thanks to Adri Koopman (Novagraaf).
-- 29 Apr 2014	KR	R13937	17	If others have row access security assigned and not the logged in user, he should have no insert access
-- 27 Oct 2015	vql	R54041	18	Extend New Name window to allow middle name entry (DR-15641)
-- 28 Feb 2016  MS      R40847  19      Added @psSelectedNameTypes parameter for row security check access
-- 28 Jul 2017	MF	72053	20	If there are no name types passed in @psSelectNameTypes then the row level security does not need to check for them.
SET CONCAT_NULL_YIELDS_NULL OFF				    	
-- Row counts required by the data adapter 
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(max)
Declare @sInsertString 		nvarchar(max)
Declare @sValuesString		nvarchar(max)
Declare @sComma			nchar(1)

Declare @nNameCodeLength	int
Declare @nUsedAsFlag		smallint
Declare @nRowCount		int
Declare @sAlertXML		nvarchar(400)
Declare @dtCurrentDate		datetime
Declare @sDBCulture		nvarchar(10)

declare	@bHasRowAccessSecurity	bit
declare @nSecurityFlag		int
declare @bExternalUser		bit

-- Initialise variables
Set @nErrorCode = 0
Set @sInsertString = "Insert into NAME ("
Set @sValuesString = CHAR(10)+" values ("
Set @bHasRowAccessSecurity = 0
Set @nSecurityFlag	= 15
select @bExternalUser = ISEXTERNALUSER from USERIDENTITY where IDENTITYID = @pnUserIdentityId

-- Check if internal user has been assigned row access security
If @nErrorCode = 0 and @bExternalUser = 0
Begin
	Set @sSQLString = 
	"Select @bHasRowAccessSecurity = 1
	from IDENTITYROWACCESS U WITH (NOLOCK) 
	join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME)
	where R.RECORDTYPE = 'N'
	and U.IDENTITYID = @pnUserIdentityId"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				      N'@bHasRowAccessSecurity		bit	OUTPUT,
				      @pnUserIdentityId			int',
				      @bHasRowAccessSecurity	= @bHasRowAccessSecurity	OUTPUT,
				      @pnUserIdentityId		= @pnUserIdentityId
End

-- Get security flag; Name inserts only check default name rules or unrestricted name types
If  @nErrorCode = 0 
and @bHasRowAccessSecurity = 1
Begin
	Set @nSecurityFlag = 0		-- Set to 0 since we know that Row Access has been applied
	
	-- RFC13561
	-- Need to cater for the possibility of a user having more than one Row Access profile.
	-- Take the best profile (using best fit) where the SecurityFlag allows for insertion of names (SECURITYFLAG & 4).
	-- Order by (SECURITYFLAG & 4) DESC to get any securityflag with the 3rd bit (value 4) turned on.
	-- Thanks to Adri Koopman (Novagraaf)

	Set @sSQLString = "SELECT @nSecurityFlag = S.SECURITYFLAG
		from (SELECT TOP 1 (R.SECURITYFLAG & 4) as SECURITYFLAG,
		   CASE WHEN R.OFFICE       IS NULL THEN 0 ELSE 1 END  * 1000
		+  CASE WHEN R.CASETYPE     IS NULL THEN 0 ELSE 1 END  * 100 
		+  CASE WHEN R.PROPERTYTYPE IS NULL THEN 0 ELSE 1 END  * 10 
		+  CASE WHEN R.NAMETYPE     IS NULL THEN 0 ELSE 1 END  * 1 as BESTFIT
		FROM IDENTITYROWACCESS U
		JOIN ROWACCESSDETAIL R	on (R.ACCESSNAME=U.ACCESSNAME
					and R.RECORDTYPE='N')
		WHERE U.IDENTITYID = @pnUserIdentityId 
		AND (R.NAMETYPE IS NULL or R.NAMETYPE = '~~~'"
		
	if  @psSelectedNameTypes is not null
	and @psSelectedNameTypes<>N''
	Begin
		Set @sSQLString=@sSQLString+" or R.NAMETYPE in (" + dbo.fn_WrapQuotes(@psSelectedNameTypes, 1, 0) + ")"
	End	

	Set @sSQLString=@sSQLString+")
		ORDER BY BESTFIT DESC, (R.SECURITYFLAG & 4) DESC) S"


	exec @nErrorCode=sp_executesql @sSQLString,
				      N'@nSecurityFlag		int	OUTPUT,
				      @pnUserIdentityId		int,
                                      @psSelectedNameTypes      nvarchar(1000)',
				      @nSecurityFlag		= @nSecurityFlag	OUTPUT,
				      @pnUserIdentityId		= @pnUserIdentityId,
                                      @psSelectedNameTypes      = @psSelectedNameTypes
End

Else
Begin
	if (@bExternalUser = 0) and exists (select 1 from IDENTITYROWACCESS U WITH (NOLOCK) 
				join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME)
				where R.RECORDTYPE = 'N')
		Set @nSecurityFlag = 0		-- Set to 0 since someone else has row security applied
		set @bHasRowAccessSecurity = 1
End

If @nErrorCode = 0
and ((@bHasRowAccessSecurity = 0) or
     (@bHasRowAccessSecurity = 1 and @nSecurityFlag&4=4)
)
Begin

	If @nErrorCode = 0
	Begin

		Set @sComma = ","
		Set @sInsertString = @sInsertString+CHAR(10)+"NAMENO"

		Set @sValuesString = @sValuesString+CHAR(10)+"@pnNameKey"

		-- Generate NAME primary key
		Exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psTable		= 'NAME',
			@pnLastInternalCode	= @pnNameKey		OUTPUT
	End


	If @pbIsNameCodeInUse = 1
	Begin
		If @nErrorCode = 0
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
		
		End

		If @nErrorCode = 0 
		Begin	
			-- Check if NAMECODE exists
			Set @sSQLString = '
				select	@nRowCount = count(NAMECODE)
				from	NAME
				where	NAMECODE = @psNameCode'
		
			Exec @nErrorCode = sp_executesql @sSQLString,
				N'
				@nRowCount	int		OUTPUT,
				@psNameCode	nvarchar(20)',
				@nRowCount 	= @nRowCount	OUTPUT,
				@psNameCode	= @psNameCode
		
		End

		-- raise error if NAMECODE exists
		If @nErrorCode = 0 and @nRowCount > 0
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('NA1', 'Name Code {0} is already in use.', 
						@psNameCode, null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
			Set @nErrorCode = @@ERROR
		End

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"NAMECODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psNameCode"
	End

	If @nErrorCode = 0 
	Begin

		If (@pbIsIndividualInUse = 1 or @pbIsStaffInUse = 1 or @pbIsClientInUse = 1)
		Begin
			-- Use bitwise or (|) operator to add @pbIsIndividual, @pbIsStaff and @pbIsClient into @nUsedAsFlag
			Set @nUsedAsFlag = coalesce(@pbIsIndividual, ~@pbIsOrganisation, 0) * 1
				| isnull(@pbIsStaff, 0) * 2
				| isnull(@pbIsClient, 0) * 4
			
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"USEDASFLAG"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnUsedAsFlag"
		End

		If @pbIsSupplierInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SUPPLIERFLAG"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"isnull(@pbIsSupplier, 0)"
		End

		If @pbIsNameInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"NAME"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psName"
			
			-- Prepare SOUNDEX by @psName
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SOUNDEX"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"dbo.fn_SoundsLike(@psName)"
		End

		If @pbIsTitleInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TITLE"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psTitle"
		End

		If @pbIsInitialsInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"INITIALS"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psInitials"
		End

		If @pbIsFirstNameInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FIRSTNAME"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psFirstName"
		End

		If @pbIsMiddleNameInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"MIDDLENAME"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psMiddleName"
		End

		If @pbIsSuffixInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SUFFIX"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psSuffix"
		End

		If @pbIsSearchKey1InUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SEARCHKEY1"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psSearchKey1"
		End

		If @pbIsSearchKey2InUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SEARCHKEY2"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psSearchKey2"
		End

		If @pbIsNationalityCodeInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"NATIONALITY"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psNationalityCode"
		End

		If @pbIsDateCeasedInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DATECEASED"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtDateCeased"
		End

		If @pbIsRemarksInUse = 1
		-- Only insert to base table if culture matches
		--and @psCulture = @sDBCulture
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"REMARKS"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psRemarks"
		End

		If @pbIsGroupKeyInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FAMILYNO"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnGroupKey"
		End

		If @pbIsNameStyleKeyInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"NAMESTYLE"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnNameStyleKey"
		End

		If @pbIsInstructorPrefixInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"INSTRUCTORPREFIX"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psInstructorPrefix"
		End

		If @pbIsCaseSequenceInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CASESEQUENCE"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCaseSequence"
		End	

		If @pbIsAirportCodeInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"AIRPORTCODE"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psAirportCode"
		End

                If @pbIsTaxNoInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TAXNO"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psTaxNo"
		End

		-- Set DATEENTERED by ip_GetCurrentDate
		Exec @nErrorCode = ip_GetCurrentDate
					@pdtCurrentDate = @dtCurrentDate OUTPUT,
					@pnUserIdentityId = @pnUserIdentityId,
					@psDateType = 'A',
					@pbIncludeTime = 1

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DATEENTERED"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtCurrentDate"

	End

	If @nErrorCode = 0
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+")"
		Set @sValuesString = @sValuesString+CHAR(10)+")"

		Set @sSQLString = @sInsertString + @sValuesString

		exec @nErrorCode = sp_executesql @sSQLString,
				N'
				@pnNameKey		int,
				@psNameCode		nvarchar(20),
				@pnUsedAsFlag		smallint,
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
				@pdtCurrentDate		datetime',

				@pnNameKey		= @pnNameKey,
				@psNameCode	 	= @psNameCode,
				@pnUsedAsFlag	 	= @nUsedAsFlag,
				@pbIsSupplier		= @pbIsSupplier,
				@psName	 		= @psName,
				@psTitle	 	= @psTitle,
				@psInitials	 	= @psInitials,
				@psFirstName	 	= @psFirstName,
				@psMiddleName		= @psMiddleName,
				@psSuffix		= @psSuffix,
				@psSearchKey1	 	= @psSearchKey1,
				@psSearchKey2	 	= @psSearchKey2,
				@psNationalityCode	= @psNationalityCode,
				@pdtDateCeased		= @pdtDateCeased,
				@psRemarks		= @psRemarks,
				@pnGroupKey	 	= @pnGroupKey,
				@pnNameStyleKey	 	= @pnNameStyleKey,
				@psInstructorPrefix	= @psInstructorPrefix,
				@pnCaseSequence	 	= @pnCaseSequence,
				@psAirportCode		= @psAirportCode,
                                @psTaxNo		= @psTaxNo,
				@pdtCurrentDate		= @dtCurrentDate	
	End

	-- insert @psExtendedName if not null and required
	If @nErrorCode = 0 and @pbIsExtendedNameInUse = 1 and @psExtendedName is not null
	Begin
		Exec @nErrorCode = dbo.naw_InsertNameText
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture = @psCulture,
					@pnNameKey = @pnNameKey,
					@psTextTypeKey = 'N',
					@ptText = @psExtendedName
	End

	-- If culture doesn't match the database main culture, we need to maintain the translated data.
	/*
	If @nErrorCode = 0
	and @psCulture <> @sDBCulture
	Begin

		Set @sSQLString = "
			Insert into TRANSLATEDTEXT (TID, CULTURE, SHORTTEXT)
			select REMARKS_TID, @psCulture, @psRemarks
			from NAME
			where NAMENO=@pnNameKey "

		exec @nErrorCode=sp_executesql @sSQLString,
					N'
					@pnNameKey		int,
					@psCulture		nvarchar(10),
					@psRemarks		nvarchar(254)',
					@pnNameKey		= @pnNameKey,
					@psCulture		= @psCulture,
					@psRemarks= @psRemarks
	End
	*/

	If @nErrorCode = 0
	Begin	
		Select @pnNameKey as NameKey
	End
End
Else
Begin
	-- User does not have row access security for insert
	Set @nErrorCode = 1
	Set @sAlertXML = dbo.fn_GetAlertXML('SF49', 'User has insufficient privileges to create this name. Please contact your system administrator.',
						null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
End
	
Return @nErrorCode
GO

Grant execute on dbo.naw_InsertName to public
GO
