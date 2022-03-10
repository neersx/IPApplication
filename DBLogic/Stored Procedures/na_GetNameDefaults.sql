-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_GetNameDefaults
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_GetNameDefaults]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_GetNameDefaults.'
	Drop procedure [dbo].[na_GetNameDefaults]
End
Print '**** Creating Stored Procedure dbo.na_GetNameDefaults...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.na_GetNameDefaults
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbIsIndividual		bit,
	@pbIsStaff		bit,
	@psName			nvarchar(254)	= null,
	@psFirstName		nvarchar(50)	= null,
	@psMiddleName		nvarchar(50)	= null,
	@psSuffix		nvarchar(20)	= null,
	@psTitle		nvarchar(20)	= null	OUTPUT, -- The title; e.g 'Mr' may be input.  If not provided, returne based on @psGenderCode
	@psCountryCode		nvarchar(3)	= null	OUTPUT, -- can be an input.
	@pnOrganisationKey	int		= null,
	@psNationalityCode	nvarchar(3)	= null	OUTPUT,
	@psNationality		nvarchar(60)	= null	OUTPUT, -- Nationality set based on NationalityCode
	@pnNameStyle		int		= null	OUTPUT,
	@psGenderCode		nchar(1)	= null	OUTPUT, -- The gender; e.g 'M' 'F' may be input.  If not provided, returne based on @psTitle
	@psSearchKey1		nvarchar(20)	= null	OUTPUT,
	@psSearchKey2		nvarchar(20)	= null	OUTPUT,
	@psInitials		nvarchar(10)	= null	OUTPUT,
	@psFormalSalutation	nvarchar(50)	= null	OUTPUT,
	@psInformalSalutation	nvarchar(50)	= null	OUTPUT,
	@psSignOffName		nvarchar(50)	= null	OUTPUT,
	@psFormattedName	nvarchar(500)	= null	OUTPUT,
	@pnScreenCriteriaKey	int			= null OUTPUT,
	@pbIsClient			bit				= null,
	@pbIsSupplier		bit				= null,
	@pbIsCRM			bit				= null
)
as
-- PROCEDURE:	na_GetNameDefaults
-- VERSION:	16
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns default values for supplied name information

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	---	-------		-------	----------------------------------------------- 
-- 07 Apr 2006	SW	RFC3503		1	Procedure created
-- 31 May 2006	SW	RFC3880		2	Don’t extract country for staff.
-- 02 Jun 2006	SW	RFC3938		3	The first name for an individual become optional
-- 09 Jun 2006	AU	RFC3918		4	Return formatted name
-- 23 Jun 2006	SW	RFC4032		5	Allow @psName, @psFirstName, @psTitle to be null.
--									Defaulting for @psFormalSalutation and @psInformalSalutation when @pbIsStaff = 1
-- 27 Jun 2006	SW	RFC4050		6	Return @psGenderCode of null if it has been defaulted from a Title with GenderFlag='B'
-- 09 May 2008	Dw	SQA16326	7	Extended salutation columns
-- 11 Dec 2008	MF	17136		8	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 04 Feb 2009	AS	RFC6723		9	Nationality field is required for Staff Names. 	
-- 14 Jul 2009	KR	RFC6946		10	Add ScreenCriteriaKey. 
-- 29 Jul 2009	MS	RFC7085		11	Added parameter for RelationshipKey in fn_GetCriteriaNameRows call
-- 17 Sep 2009	LP	RFC8047		12	Added parameter for ProfileKey in fn_GetCriteriaNameRows call
-- 02 Oct 2009	KR	RFC100080	13	Added parameter @pbIsClient and @pbIsSupplier so that correct ScreenCriteriaKey is picked up
-- 08 Oct 2009	AT	RFC100080	14	Added @pbIsCRM parameter for CRM names. Return default if no criteria key found.
-- 27 Oct 2015	vql	R53909		15	Add middle name and suffix when generating search key (DR-15542).
-- 02 Nov 2015	vql	R53910		16	Adjust formatted names logic (DR-15543).


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)


Declare @sNameProgram nvarchar(8)
Declare @nUsedAsFlag int
Declare @nDataUnknown int

-- Initialise variables
Set @nErrorCode = 0

-- set @psCountryCode as ADDRESS COUNTRYCODE or SITECONTROL if @psCountryCode not provided by user
-- otherwise keep the value. Only set the value for non-staff
If  @nErrorCode = 0
and @psCountryCode is null 
Begin

	Set @sSQLString = '
		select		@psCountryCode = coalesce(A.COUNTRYCODE, SC.COLCHARACTER)
		from		(select 1 as TXT) DUMMY
		left join	SITECONTROL SC	on (SC.CONTROLID = ''HOMECOUNTRY'')
		left join	[NAME] N 	on (N.NAMENO = @pnOrganisationKey)
		left join	ADDRESS A 	on (A.ADDRESSCODE = N.POSTALADDRESS)'
	
	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@psCountryCode	nvarchar(3)		OUTPUT,
				  @pnOrganisationKey	int,
				  @pbIsStaff		bit',
				  @psCountryCode	= @psCountryCode	OUTPUT,
				  @pnOrganisationKey	= @pnOrganisationKey,
				  @pbIsStaff		= @pbIsStaff
	
End

-- set @psNationalityCode and @psNationality iff @psCountryCode not null and NationalityUsePostal = 1
If   @nErrorCode = 0
Begin
	Set @sSQLString = '
		Select		@psNationalityCode 	= @psCountryCode,
				@psNationality		= C.COUNTRYADJECTIVE
		from		SITECONTROL SC
		left join 	COUNTRY C	on (C.COUNTRYCODE = @psCountryCode)
		where		(SC.CONTROLID = ''NationalityUsePostal''
				 and SC.COLBOOLEAN = 1)'

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@psNationalityCode	nvarchar(3)		OUTPUT,
				  @psNationality	nvarchar(60)		OUTPUT,
				  @psCountryCode	nvarchar(3),
				  @pbIsStaff		bit',
				  @psNationalityCode	= @psNationalityCode	OUTPUT,
				  @psNationality	= @psNationality	OUTPUT,
				  @psCountryCode	= @psCountryCode,
				  @pbIsStaff		= @pbIsStaff
End


-- Set @pnNameStyle by @psCountryCode, if no match default to 7101(surname last)
If @nErrorCode = 0 and @pnNameStyle is null
Begin
	Set @sSQLString = '
		Select	@pnNameStyle = isnull(NAMESTYLE, 7101)
		from	COUNTRY
		where	COUNTRYCODE = @psCountryCode'

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnNameStyle		int			OUTPUT,
				  @psCountryCode	nvarchar(3)',
				  @pnNameStyle		= @pnNameStyle		OUTPUT,
				  @psCountryCode	= @psCountryCode
End

-- Set @psTitle by @psGenderCode if it is null
If @nErrorCode = 0 and @psTitle is null and @psGenderCode is not null
Begin
	Set @sSQLString = '
		Select	@psTitle = TITLE
		from	TITLES
		where	GENDERFLAG = @psGenderCode
		and	DEFAULTFLAG = 1'

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@psTitle		nvarchar(20)		OUTPUT,
				  @psGenderCode		nchar(1)',
				  @psTitle		= @psTitle		OUTPUT,
				  @psGenderCode		= @psGenderCode
End

-- Set @psGenderCode by @psTitle if it is null
-- RFC4050 Set @psGenderCode of null if it has been defaulted from a Title with GenderFlag='B'
If @nErrorCode = 0 and @psTitle is not null and @psGenderCode is null
Begin
	Set @sSQLString = '
		Select	@psGenderCode = GENDERFLAG
		from	TITLES
		where	TITLE = @psTitle
		and	GENDERFLAG <> ''B'''

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@psGenderCode		nchar(1)		OUTPUT,
				  @psTitle		nvarchar(20)',
				  @psGenderCode		= @psGenderCode		OUTPUT,
				  @psTitle		= @psTitle
End

-- Set @psInitials, , @psInformalSalutation
If @nErrorCode = 0 and @psFirstName is not null
Begin
	Set @psInitials = dbo.fn_GetInitials(rtrim(ltrim(@psFirstName)) + ' ' + rtrim(ltrim(@psMiddleName)))
	Set @nErrorCode = @@ERROR

	If @nErrorCode = 0 and @pbIsStaff = 0
	Begin
		Set @psInformalSalutation = dbo.fn_PrepareName(@psName,@psFirstName,@psTitle,@pnNameStyle,'I')
		Set @nErrorCode = @@ERROR
	End

End

-- Set @psFormalSalutation
If @nErrorCode = 0 and @pbIsIndividual = 1 and @pbIsStaff = 0
Begin
	Set @psFormalSalutation = dbo.fn_PrepareName(@psName,@psFirstName,@psTitle,@pnNameStyle,'F')
	Set @nErrorCode = @@ERROR
End

-- Set @psSignOffName
If @nErrorCode = 0 and @pbIsStaff = 1
Begin
	Set @psSignOffName = dbo.fn_PrepareName(@psName,@psFirstName,@psTitle,@pnNameStyle,'S')
	Set @nErrorCode = @@ERROR
End

-- Set @psSearchKey1 & 2 by calling na_GenerateSearchKey
If @nErrorCode = 0
Begin
	Exec @nErrorCode = dbo.na_GenerateSearchKey 
		@psSearchKey1		=@psSearchKey1		OUTPUT,
		@psSearchKey2		=@psSearchKey2		OUTPUT,
		@pnUserIdentityId	=@pnUserIdentityId,
		@psCulture		=@psCulture,
		@psName			=@psName,
		@psGivenNames		=@psFirstName,
		@psInitials		=@psInitials,
		@psMiddleName		=@psMiddleName,
		@psSuffix		=@psSuffix

End

-- Set @psFormattedName
If @nErrorCode = 0
Begin

	Set @psFormattedName = dbo.fn_FormatFullName(@psName,@psFirstName,@psMiddleName,@psSuffix,@psTitle,@pnNameStyle)
	Set @nErrorCode = @@ERROR
End

-- Set @pnScreenCriteriaKey
If @nErrorCode = 0
Begin
	Set @nDataUnknown = 0
	
	if (@pbIsIndividual = 1)
	Begin
		Set @nUsedAsFlag = 1
		if (@pbIsStaff = 1)
			Set @nUsedAsFlag = 3
		else if (@pbIsClient = 1)
			Set @nUsedAsFlag = 5
	End
	else if (@pbIsStaff = 1)
		set @nUsedAsFlag = 2
	else
	Begin	
		set @nUsedAsFlag = 0
		if (@pbIsClient = 1)
			set @nUsedAsFlag = 4
	End

	Set @sNameProgram = Case when @pbIsCRM = 1 then 'NAMECRM' else 'NAMENTRY' End

	Select TOP 1 @pnScreenCriteriaKey = NAMECRITERIANO From dbo.fn_GetCriteriaNameRows(
			'W', @sNameProgram, null, @nUsedAsFlag,@pbIsSupplier,@psCountryCode, null, null,null,null,1,@nDataUnknown,0,null)

	If ( @pnScreenCriteriaKey is null )
	Begin
		-- Try to get the default criteria key
		Set @nDataUnknown = 1

		Select TOP 1 @pnScreenCriteriaKey = NAMECRITERIANO From dbo.fn_GetCriteriaNameRows(
			'W', @sNameProgram, null, @nUsedAsFlag,@pbIsSupplier,@psCountryCode, null, null,null,null,1,@nDataUnknown,0,null)
	End

	Set @nErrorCode = @@ERROR
End

	
Return @nErrorCode
GO

Grant execute on dbo.na_GetNameDefaults to public
GO
