-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchName.'
	Drop procedure [dbo].[naw_FetchName]
End
Print '**** Creating Stored Procedure dbo.naw_FetchName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_FetchName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int, 		-- Mandatory
	@psLogicalProgramId	nvarchar(16)	= null
)
as
-- PROCEDURE:	naw_FetchName
-- VERSION:		16
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Name business entity.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	------	-------	-----------------------------------------------
-- 12 Apr 2006	SW	RFC3503		1	Procedure created
-- 18 Dec 2007	SW	RFC5740		2	Add new columns SOURCE, ESTIMATEDREV, STATUS
-- 02 Jan 2008	SW	RFC5740		3	Change column STATUS to NAMESTATUS, add new column CRMONLY
-- 11 Jan 2008	SW	RFC5740		4	Change column SOURCE to NAMESOURCE
-- 21 Feb 2008	vql	RFC5741		5	NameSource and Status column names are wrong. 
--						Change to SourceKey and StatusKey and return descriptions.
-- 25 Jun 2008	SF	RFC6508		6	Remove NameSource and Status column. Retrieve IsLead.
-- 08 Jul 2009	KR	RFC6546		7	Add ScreenCriteriaKey to the select list.
-- 08 Sep 2009	MS	RFC8828		8	Add Locality and LocalityCode to the select list.
-- 21 Sep 2009  LP	RFC8047		9	Pass ProfileKey parameter to fn_GetCriteriaNoForName
-- 09 Oct 2009	AT	RFC100080	10	Use NAMECRM name program if the name is lead only.
-- 07 Jan 2010	LP	RFC8450		11	Add LogicalProgramId parameter to fetch the correct screen criteria key
-- 07 Jan 2010	LP	RFC8525		12	Get Default CRM Name program from PROFILEATTRIBUTES then SITECONTROL
-- 10 May 2010	PA	RFC9097 	13	Get the TAXNO from the NAME table rather than VATNO from ORGANIZATION table.
-- 11 Apr 2013	DV	R13270		14	Increase the length of nvarchar to 11 when casting or declaring integer 
-- 26 Oct 2015	vql	R53905		15	Allow maintenance of new name fields (DR-15538).
-- 02 Nov 2015	vql	R53910		16	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @nProfileKey    int
Declare @sDefaultProgram   nvarchar(508)
Declare @nAttributeId	int		-- The identifier for the profile attribute
Declare @sSiteControl	nvarchar(120)	-- The name of the site control related to screen control

-- Initialise variables
Set @nErrorCode = 0

-- Get the ProfileKey of the current user
If @nErrorCode = 0
Begin
	Select @nProfileKey = PROFILEID
	from USERIDENTITY
	where IDENTITYID = @pnUserIdentityId

	Set @nErrorCode = @@ERROR
End

---- Get the Default Name Program of the user's profile
If @nErrorCode = 0
and @sDefaultProgram is null
and @psLogicalProgramId is not null
Begin
	Set @sDefaultProgram = @psLogicalProgramId
End

-- Set the Default Program if not specified via input parameters
If @nErrorCode = 0 
AND (@sDefaultProgram is null or @sDefaultProgram = '')
Begin
	-- No non-crm name types selected
	If not exists (SELECT 1 from NAME XN
				left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO=XN.NAMENO
									and NTC.NAMETYPE <> '~~~'
									and NTC.ALLOW=1)
				left join NAMETYPE NTP on (NTP.NAMETYPE=NTC.NAMETYPE and NTP.PICKLISTFLAGS&32<>32)
				where XN.NAMENO = @pnNameKey
				and NTP.NAMETYPE is not null)
	-- and at least 1 CRM Name type selected.
	and exists (SELECT 1 
				from NAME XN
				left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO=XN.NAMENO
									and NTC.NAMETYPE <> '~~~'
									and NTC.ALLOW=1)
				left join NAMETYPE NTP on (NTP.NAMETYPE=NTC.NAMETYPE and NTP.PICKLISTFLAGS&32=32)
				where XN.NAMENO = @pnNameKey
				and NTP.NAMETYPE is not null)
	Begin
		Set @nAttributeId = 4
		Set @sSiteControl = 'CRM Name Screen Program'			
	End
	Else
	Begin
		Set @nAttributeId = 3
		Set @sSiteControl = 'Name Screen Default Program'		
	End
	If @nErrorCode = 0
	and @nProfileKey is not null
	Begin
		Select @sDefaultProgram = P.ATTRIBUTEVALUE
		from PROFILEATTRIBUTES P
		where P.PROFILEID = @nProfileKey
		and P.ATTRIBUTEID = @nAttributeId

		Set @nErrorCode = @@ERROR
	End
	
	If @nErrorCode = 0
	and (@sDefaultProgram is null or @sDefaultProgram = '')
	Begin 
		Select @sDefaultProgram = SC.COLCHARACTER
		from SITECONTROL SC
		where SC.CONTROLID = @sSiteControl
	
		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
		cast(N.NAMENO as nvarchar(11))			as RowKey,
		N.NAMENO					as NameKey,
		N.NAMECODE					as NameCode,
		cast((isnull(N.USEDASFLAG, 0) & 1) as bit)	as IsIndividual,
		~cast((isnull(N.USEDASFLAG, 0) & 1) as bit)	as IsOrganisation,
		cast((isnull(N.USEDASFLAG, 0) & 2) as bit)	as IsStaff,
		cast((isnull(N.USEDASFLAG, 0) & 4) as bit)	as IsClient,
		cast(isnull(N.SUPPLIERFLAG, 0) as bit) 		as IsSupplier,
		cast(isnull(FI.IsAgent, 0) as bit) 		as IsAgent,
		cast(isnull(NTC.IsLead, 0) as bit) 		as IsLead,
		N.[NAME]					as [Name],
		N.TITLE						as Title,
		N.INITIALS					as Initials,
		N.FIRSTNAME					as FirstName,
		N.MIDDLENAME					as MiddleName,
		N.SUFFIX					as Suffix,
		NT.[TEXT]					as ExtendedName,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, C.NAMESTYLE, 7101))
								as FormattedName, 
		N.SEARCHKEY1					as SearchKey1,
		N.SEARCHKEY2					as SearchKey2,
		N.NATIONALITY					as NationalityCode,
		C.COUNTRYADJECTIVE				as Nationality,
		N.REMARKS					as Remarks,
		N.DATECEASED					as DateCeased,
		N.FAMILYNO					as GroupKey,
		NF.FAMILYTITLE					as GroupTitle,
		N.NAMESTYLE					as NameStyleKey,
		T.[DESCRIPTION]					as NameStyle,
		N.INSTRUCTORPREFIX				as InstructorPrefix,
		N.CASESEQUENCE					as CaseSequence,
		dbo.fn_GetCriteriaNoForName(@pnNameKey, 'W', ISNULL(@sDefaultProgram,'NAMENTRY'),@nProfileKey) as ScreenCriteriaKey,
		N.AIRPORTCODE					as AirportCode,
		A.AIRPORTNAME					as AirportName,
		N.TAXNO						as TaxNo
		from 		[NAME] N
		left join	NAMETEXT NT			on (NT.NAMENO = N.NAMENO and NT.TEXTTYPE = 'N')
		left join	COUNTRY C			on (C.COUNTRYCODE = N.NATIONALITY)
		left join	NAMEFAMILY NF			on (NF.FAMILYNO = N.FAMILYNO)
		left join	TABLECODES T			on (T.TABLECODE = N.NAMESTYLE)
		left join	(select	FILESIN.NAMENO, 1 as IsAgent
				 from	FILESIN
				) FI				on (FI.NAMENO = N.NAMENO)
		left join	(select NAMETYPECLASSIFICATION.NAMENO, NAMETYPECLASSIFICATION.ALLOW as IsLead
				from	NAMETYPECLASSIFICATION
				where	NAMETYPECLASSIFICATION.NAMETYPE = '~LD'
				) NTC				on (NTC.NAMENO = N.NAMENO)
		left join	AIRPORT A			on (A.AIRPORTCODE = N.AIRPORTCODE)
		where 		N.NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey		int,
			@nProfileKey            int,
			@sDefaultProgram        nvarchar(508)',
			@pnNameKey	 = @pnNameKey,
			@nProfileKey     = @nProfileKey,
			@sDefaultProgram = @sDefaultProgram
End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchName to public
GO


