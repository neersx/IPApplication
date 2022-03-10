-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListPotentialDuplicate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListPotentialDuplicate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListPotentialDuplicate.'
	Drop procedure [dbo].[naw_ListPotentialDuplicate]
End
Print '**** Creating Stored Procedure dbo.naw_ListPotentialDuplicate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListPotentialDuplicate
(
	@pnUserIdentityId	int,				-- Mandatory
	@psCulture		    nvarchar(10) 		= null,
	@pbIsIndividual	    bit,				-- Mandatory
	@pbIsClient		    bit,				-- Mandatory
	@pbIsStaff		    bit,				-- Mandatory
	@psFirstName	    nvarchar(50) 		= null,
	@psName			    nvarchar(254), 		-- Mandatory, the name of organisation or last name of individual
	@psOrgOrProspectName	nvarchar(254)	= null,	-- organisation if created along with name of individual
	@pbIsProspectIndividual	bit				= 0,
	@psProspectFirstName	nvarchar(50)	= null,
	@pnRowCount				int				= 0         output
	
)
as
-- PROCEDURE:	naw_ListPotentialDuplicate
-- VERSION:	8
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	A wrapper sproc that call na_ListPotentialDuplicate

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 May 2006	SW	RFC3492	1	Procedure created
-- 27 Oct 2008  LP      RFC5778 2       Return RowCount as output parameter.
-- 11 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 02 Apr 2009	NG	RFC4026	4	Passed @pbCalledFromCentura=0 for WorkBenches, added access account key 
--									and allow the user to pass two names.
-- 13 May 2009	NG	RFC7849	5	Fixed to implement Duplicate Name Check for External Users.
-- 22 Jul 2009	KR	RFC8109 6	Added SearchKey1 and SearchKey2
-- 07 Jul 2011	DL	R10830	7	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 27 Oct 2015	vql	R54041	8	Extend New Name window to allow middle name entry (DR-15641).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @nSCIndividualCheck	int	-- SITECONTROL Duplicate Individual Check
Declare @bSCOrganisationCheck	bit	-- SITECONTROL Duplicate Organisation Check
Declare @nOffice		int	-- office of the current user
Declare @nOfficeCurrent	int -- contain different values while different names in process
Declare @bIsExternalUser	bit
Declare @pnAccessAccountKey		int

CREATE TABLE #tmpTableDuplicates
(
	RowKey			nvarchar(50) collate database_default,
	Name			nvarchar(254) collate database_default,
	GivenName		nvarchar(50) collate database_default,
	MiddleName		nvarchar(50) collate database_default,
	UsedAs			smallint,
	Allow			int,
	PostalAddress		nvarchar(400) collate database_default,
	StreetAddress		nvarchar(400) collate database_default,
	City			nvarchar(150) collate database_default,
	UsedAsOwner		int,
	UsedAsInstructor	int,
	UsedAsDebtor		int,
	MainContact		nvarchar(200) collate database_default,
	Telephone		nvarchar(400) collate database_default,
	WebSite			nvarchar(400) collate database_default,
	Fax			nvarchar(400) collate database_default,
	Email			nvarchar(400) collate database_default,
	Remarks			nvarchar(500) collate database_default,
	SearchKey1		nvarchar(20) collate database_default,
	SearchKey2		nvarchar(20) collate database_default
)

-- Initialise variables
Set @nErrorCode = 0
Set @pnAccessAccountKey = 0

-- Extract the @pbIsExternalUser from UserIdentity if it has not been supplied.
If @nErrorCode=0
and @bIsExternalUser is null
Begin		
	Set @sSQLString='
	Select @bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

If @nErrorCode = 0 and @bIsExternalUser = 1
Begin
	Set @sSQLString='
	Select @pnAccessAccountKey=ACCOUNTID
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnAccessAccountKey	int	OUTPUT,
				  @pnUserIdentityId	int',
				  @pnAccessAccountKey	=@pnAccessAccountKey	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

If @nErrorCode = 0
Begin
	-- Find out from SITECONTROL if check required.
	Set @sSQLString = "
		Select	@nSCIndividualCheck = ISNULL(SC1.COLINTEGER, 0),
			@bSCOrganisationCheck = ISNULL(SC2.COLBOOLEAN, 0)
		from	(select 1 as DUMMYCOLUMN) DUMMYTABLE
		left join SITECONTROL SC1 on (SC1.CONTROLID = 'Duplicate Individual Check')
		left join SITECONTROL SC2 on (SC2.CONTROLID = 'Duplicate Organisation Check')
	"

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@nSCIndividualCheck	int			OUTPUT,
				  @bSCOrganisationCheck	bit			OUTPUT',
				  @nSCIndividualCheck	= @nSCIndividualCheck	OUTPUT,
				  @bSCOrganisationCheck	= @bSCOrganisationCheck	OUTPUT
End

-- Find out if need to pass office in as param
If @nErrorCode = 0
Begin
		If (@pbIsIndividual = 1 or @pbIsProspectIndividual = 1) and @nSCIndividualCheck = 2
		Begin

			Set @sSQLString = "
				Select	@nOffice = min(TABLECODE)	 
				from 	TABLEATTRIBUTES	
				join 	USERIDENTITY U on (U.IDENTITYID = @pnUserIdentityId)
				where 	PARENTTABLE = 'NAME'	 
				and 	TABLETYPE = 44	 
				and 	GENERICKEY = CAST(U.NAMENO AS nvarchar(20))
			"
	
			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@nOffice		int		OUTPUT,
						  @pnUserIdentityId	int',
						  @nOffice		= @nOffice	OUTPUT,
						  @pnUserIdentityId	= @pnUserIdentityId
		End
End

If @nErrorCode = 0
Begin
	If (@pbIsIndividual = 1 and @nSCIndividualCheck > 0)
	or (@pbIsIndividual = 0 and @bSCOrganisationCheck = 1)
	Begin

		If @pbIsIndividual = 1 and @pbIsClient = 0 and @pbIsStaff = 0
		Begin
			Set @nOfficeCurrent = @nOffice
		End

		If @nErrorCode = 0
		Begin
			Exec @nErrorCode = na_ListPotentialDuplicate			            
						@pnUserIdentityId   = @pnUserIdentityId,
						@psName			    = @psName,
						@psGivenName		= @psFirstName,
						@pnRestrictToOffice	= @nOfficeCurrent,
						@pbCalledFromCentura = 0,
						@pnAccessAccountKey	= @pnAccessAccountKey,
						@pnRowCount         = @pnRowCount OUTPUT
		End
		Set @nOfficeCurrent = null
	End
	If (@pbIsProspectIndividual = 1 and @nSCIndividualCheck > 0)
	or (@pbIsProspectIndividual = 0 and @bSCOrganisationCheck = 1)
	Begin
		If @pbIsProspectIndividual = 1
		Begin
			Set @nOfficeCurrent = @nOffice
		End
			
		If @nErrorCode = 0 
		Begin
			If (@psOrgOrProspectName is not null) and 
				not(@pbIsProspectIndividual = 0 and @psFirstName is null and @psName = @psOrgOrProspectName) and
				not(@pbIsProspectIndividual = 1 and @psFirstName = @psProspectFirstName and @psOrgOrProspectName = @psName)
			Begin
				Exec @nErrorCode = na_ListPotentialDuplicate			            
						@pnUserIdentityId   = @pnUserIdentityId,
						@psName			    = @psOrgOrProspectName,
						@psGivenName		= @psProspectFirstName,
						@pnRestrictToOffice	= @nOfficeCurrent,
						@pbCalledFromCentura = 0,
						@pnAccessAccountKey	= @pnAccessAccountKey,
						@pnRowCount         = @pnRowCount OUTPUT
			End
		End
	End
--	Else
--	Begin
--		Select Null as NAMENO where 1 = 2
--	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "select RowKey, Name, GivenName, MiddleName, UsedAs, Allow, PostalAddress, StreetAddress, City, 
					UsedAsOwner, UsedAsInstructor, UsedAsDebtor, MainContact, Telephone, WebSite, Fax, 
					Email, Remarks, SearchKey1, SearchKey2	
					from #tmpTableDuplicates"

	Exec @nErrorCode = sp_executesql @sSQLString

	drop table #tmpTableDuplicates
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListPotentialDuplicate to public
GO
