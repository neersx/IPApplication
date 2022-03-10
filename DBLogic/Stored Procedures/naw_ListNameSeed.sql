-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameSeed
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameSeed]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameSeed.'
	Drop procedure [dbo].[naw_ListNameSeed]
	Print '**** Creating Stored Procedure dbo.naw_ListNameSeed...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.naw_ListNameSeed
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null, 
	@pnOrganisationKey	int 		= null, -- The key of the employing organisation.
	@pnAccessAccountKey	int	 	= null	-- The key of the account the name uses to access the system.
							-- Either @pnOrganisationKey or @pnAccessAccountKey 
							-- should be provided, but not both.
)
AS
-- PROCEDURE:	naw_ListNameSeed
-- VERSION:	5
-- DESCRIPTION:	Returns default values for the Name Seed class 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 23-Mar-2006	IB	RFC3708	1	Procedure created
-- 23-Jun-2008	SF	RFC6508	2	Add StaffResponsibleNameKey,StaffResponsibleNameCode and StaffResponsibleDisplayName 
--						if called without OrganisationKey and AccessAccountKey
-- 11 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 04-Jun-2009  LP      RFC8077 4       Modify to return IsNameCodeGenerated as false if GENERATENAMECODE is 3
-- 02 Nov 2015	vql	R53910	5	Adjust formatted names logic (DR-15543).

-- set server options
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare	@nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)

-- Populating Name Seed result set
	
If @nErrorCode = 0
and @pnOrganisationKey is null
and @pnAccessAccountKey is null
Begin
	Set @sSQLString = 
	"Select null		as 'AccessAccountKey',"+char(10)+   
	"null			as 'OrganisationKey',"+char(10)+  
	"null			as 'OrganisationName',"+char(10)+
	"null			as 'OrganisationCode',"+char(10)+ 
	"cast(0 as bit)		as 'UseOrganisationAddress',"+char(10)+ 
	"cast(0 as bit)		as 'UseOrganisationTelecom',"+char(10)+ 
	"cast(0 as bit)		as 'IsIndividual',"+char(10)+ 	
	"cast(1 as bit)		as 'IsOrganisation',"+char(10)+  	
	"SCHC.COLCHARACTER	as 'CountryCode',"+char(10)+  
	+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'HC',@sLookupCulture,0)+
	"		as 'CountryName',"+char(10)+ 
	"CASE WHEN SCGNC.COLINTEGER between 1 AND 2"+char(10)+ 
	"			THEN cast(1 as bit)"+char(10)+  
	"			ELSE cast(0 as bit)"+char(10)+  
	"			END"+char(10)+ 
	"			as 'IsNameCodeGenerated',"+char(10)+ 	
	"N.NAMENO		as	'StaffResponsibleNameKey',"+char(10)+
	"N.NAMECODE		as	'StaffResponsibleNameCode',"+char(10)+	
	"dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)"+char(10)+
	"			as 'StaffResponsibleDisplayName'"+char(10)+
     	"from SITECONTROL SCHC"+char(10)+  
	"left join COUNTRY HC		on (HC.COUNTRYCODE = SCHC.COLCHARACTER)"+char(10)+ 
	"left join SITECONTROL SCGNC	on (SCGNC.CONTROLID = 'GENERATENAMECODE')"+char(10)+ 
	"left join USERIDENTITY UI on (UI.IDENTITYID = @pnUserIdentityId)"+char(10)+
	"left join NAME N on (N.NAMENO = UI.NAMENO)"+char(10)+
	"where SCHC.CONTROLID = 'HOMECOUNTRY'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int',
					  @pnUserIdentityId	= @pnUserIdentityId
End
	
If @nErrorCode = 0
and (@pnOrganisationKey is not null or @pnAccessAccountKey is not null)
Begin
	If @pnAccessAccountKey is not null
	Begin
		Set @sSQLString = 
		"Select @pnOrganisationKey 	= AAN.NAMENO"+char(10)+
		"from ACCESSACCOUNT AA"+char(10)+
		"join ACCESSACCOUNTNAMES AAN 	on (AAN.ACCOUNTID = AA.ACCOUNTID)"+char(10)+
		"join NAME N 			on (N.NAMENO = AAN.NAMENO"+char(10)+
		"				    and N.USEDASFLAG&1 = 0)"+char(10)+
		"where AA.ACCOUNTID = @pnAccessAccountKey"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnOrganisationKey	int output,
						  @pnAccessAccountKey	int',
						  @pnOrganisationKey	= @pnOrganisationKey output,
						  @pnAccessAccountKey	= @pnAccessAccountKey
		Set @nRowCount = @@RowCount

		-- @nRowCount = 1 means there is only one ACCESSACCOUNTNAME that is an organisation (NAME.USEDASFLAG&1=0)
		If @nRowCount != 1
		Begin
			Set @pnOrganisationKey = null
		End
	End

	Set @sSQLString = 
	"Select " +
	"@pnAccessAccountKey	as 'AccessAccountKey',"+char(10)+   
	"@pnOrganisationKey	as 'OrganisationKey',"+char(10)+ 
	"dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)"+char(10)+
	"			as 'OrganisationName',"+char(10)+
	"N.NAMECODE		as 'OrganisationCode',"+char(10)+ 
	"CASE WHEN @pnOrganisationKey is null"+char(10)+ 
	"			THEN cast(0 as bit)"+char(10)+  
	"			ELSE cast(1 as bit)"+char(10)+  
	"			END"+char(10)+ 			
	"			as 'UseOrganisationAddress',"+char(10)+ 
	"CASE WHEN @pnOrganisationKey is null"+char(10)+ 
	"			THEN cast(0 as bit)"+char(10)+  
	"			ELSE cast(1 as bit)"+char(10)+  
	"			END"+char(10)+ 		
	"			as 'UseOrganisationTelecom',"+char(10)+ 
	"cast(1 as bit)		as 'IsIndividual',"+char(10)+ 	
	"cast(0 as bit)		as 'IsOrganisation',"+char(10)+  	
	"AC.COUNTRYCODE		as 'CountryCode',"+char(10)+  
	+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'AC',@sLookupCulture,0)+
	" 			as 'CountryName',"+char(10)+ 
	"CASE WHEN SCGNC.COLINTEGER between 1 AND 2"+char(10)+ 
	"			THEN cast(1 as bit)"+char(10)+  
	"			ELSE cast(0 as bit)"+char(10)+  
	"			END"+char(10)+ 
	"			as 'IsNameCodeGenerated'"+char(10)+ 	
     	"from SITECONTROL SCHC"+char(10)+  
     	"left join NAME N		on (N.NAMENO = @pnOrganisationKey)"+char(10)+   	
	"left join ADDRESS A		on (A.ADDRESSCODE = N.POSTALADDRESS)"+char(10)+ 
	"left join COUNTRY AC		on (AC.COUNTRYCODE = isnull(A.COUNTRYCODE, SCHC.COLCHARACTER))"+char(10)+ 
	"left join SITECONTROL SCGNC	on (SCGNC.CONTROLID = 'GENERATENAMECODE')"+char(10)+ 
	"where SCHC.CONTROLID = 'HOMECOUNTRY'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnOrganisationKey	int,
					  @pnAccessAccountKey	int',
					  @pnOrganisationKey	= @pnOrganisationKey,
					  @pnAccessAccountKey	= @pnAccessAccountKey
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameSeed to public
GO
