-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.naw_ListNameSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameSummary.'
	Drop procedure [dbo].[naw_ListNameSummary]
End
Print '**** Creating Stored Procedure dbo.naw_ListNameSummary...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.naw_ListNameSummary
(
	@pnRowCount			int		= null	output, 
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnNameKey			int, 		-- Mandatory
	@pbCalledFromCentura		bit		= 0
)
AS
-- PROCEDURE:	naw_ListNameSummary
-- VERSION:	13

-- DESCRIPTION:	Populates NameSummaryInternalData dataset. Returns full details regarding a
--		single name. 

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 26 Oct 2004  TM	RFC626	1	Procedure created
-- 27 Oct 2004	TM	RFC626	2	The site control has the Telecom Type in it, not the TeleCode.
-- 12 Nov 2004	TM	RFC626	3	Correct the Home Page site control spelling.
-- 15 May 2005	JEK	RFC2508	4	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 24 Mar 2006	SF	RFC3264	5	Add RowKey to Telecom result set, sort it in order of Phone,Fax,Email,HomePage,TelecomNumber
-- 24 Apr 2006	SW	RFC3301	6	Populate Telecom result set by calling naw_ListImportantTelecom 
-- 30 Jun 2008	SF	RFC6535	7	Populate Lead Details result set by calling crm_GetLeadDetails
-- 02 Apr 2009	Ash	RFC6312	8	Add New Column OrganisationCode to Name Result Set.
-- 13 Jul 2009	KR	RFC8109	9	Add SearchKey1 and SearchKey2 to the name result set.
-- 23 Mar 2010	JCLG	RFC8481	10	Add EndDate, SignOffName, SignOffTitle, AbbreviatedName, CapacityToSign 
--									NationalityCode, Nationality, TaxNo, GenderCode, CasualSalutation,
--									FormalSalutation, CompanyNo, Incorporated, ParentEntityName,
--									IsIndividual, IsOrganisation, IsStaff and IsClient to the name result set
-- 10 May 2010	SF	RFC8479	11	Fix SQL Error when returning results for non-neutral cultures.
-- 02 Nov 2015	vql	R53910	12	Adjust formatted names logic (DR-15543).
-- 30 Mar 2016  MS  R57289  13      Added PostalAddressKey in the name result set

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString1 		nvarchar(4000)
Declare @sSQLString2 		nvarchar(4000)
Declare @nErrorCode		int
Declare @nRowCount		int

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set 	@nErrorCode 		 = 0
Set	@nRowCount		 = 0

-- Populating Name Result Set
	
If @nErrorCode = 0
Begin
	Set @sSQLString1 = 
	"Select N.NAMENO 	as 'NameKey',"+CHAR(10)+ 
	-- If Name.NameStyle is not null then pass the @pnNameStyle = Name.NameStyle to the
	-- fn_FormatNameUsingNameNo, else use Country.NameStyle. If still null, use 7101 NameStyle (Name Last)   
	"dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+CHAR(10)+  	
	"			as 'Name',"+CHAR(10)+  
	"N.NAMECODE		as 'NameCode',"+CHAR(10)+ 	
	"dbo.fn_FormatNameUsingNameNo(ORG.NAMENO, null)"+CHAR(10)+
	"			as 'OrganisationName',"+CHAR(10)+
	"ORG.NAMENO		as 'OrganisationKey',"+CHAR(10)+ 
	"ORG.NAMECODE		as 'OrganisationCode',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('ASSOCIATEDNAME','POSITION',null,'EMP',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Position',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('NAME','REMARKS',null,'N',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Remarks',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Restriction',"+CHAR(10)+ 
	"DS.ACTIONFLAG		as 'RestrictionActionKey',"+CHAR(10)+ 
	"N.DATECEASED		as 'DateCeased',"+CHAR(10)+ 
	"I.IMAGEID		as 'ImageKey',"+CHAR(10)+ 	
	"N1.NAMENO		as 'MainContactKey',"+CHAR(10)+ 
	"dbo.fn_FormatNameUsingNameNo(N1.NAMENO, COALESCE(N1.NAMESTYLE, NN1.NAMESTYLE, 7101))"+CHAR(10)+ 	
	"			as 'MainContactName',"+CHAR(10)+ 
	"dbo.fn_FormatTelecom(M.TELECOMTYPE, M.ISD, M.AREACODE, M.TELECOMNUMBER, M.EXTENSION)"+CHAR(10)+ 
	"     			as 'MainContactEmail',"+CHAR(10)+ 
	"dbo.fn_FormatAddress(SA.STREET1, SA.STREET2, SA.CITY, SA.STATE, SS.STATENAME, SA.POSTCODE, SC.POSTALNAME, SC.POSTCODEFIRST, SC.STATEABBREVIATED, SC.POSTCODELITERAL, SC.ADDRESSSTYLE)"+CHAR(10)+ 
	"			as 'StreetAddress',"+CHAR(10)+ 	
	"dbo.fn_FormatAddress(PA.STREET1, PA.STREET2, PA.CITY, PA.STATE, PS.STATENAME, PA.POSTCODE, PC.POSTALNAME, PC.POSTCODEFIRST, PC.STATEABBREVIATED, SC.POSTCODELITERAL, PC.ADDRESSSTYLE)"+CHAR(10)+ 
	"			as 'PostalAddress',"+CHAR(10)+ 
	dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'CAT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Category',"+CHAR(10)+ 
	dbo.fn_SqlTranslatedColumn('NAMEFAMILY','FAMILYTITLE',null,'GRP',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Group',"+CHAR(10)+ 
	dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'StaffClassification',"+CHAR(10)+
	"E.PROFITCENTRECODE	as 'ProfitCentreCode',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('PROFITCENTRE','DESCRIPTION',null,'PFC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ProfitCentre',"+CHAR(10)+	
	"E.STARTDATE		as 'StartDate',"+CHAR(10)+
	"E.ENDDATE			as 'EndDate',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('EMPLOYEE','SIGNOFFNAME',null,'E',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'SignOffName',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('EMPLOYEE','SIGNOFFTITLE',null,'E',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'SignOffTitle',"+CHAR(10)+
	"E.ABBREVIATEDNAME	as 'AbbreviatedName',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'CS',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'CapacityToSign',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'NN',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Nationality',"+CHAR(10)+
	"NN.COUNTRYCODE		as 'NationalityCode',"+CHAR(10)+
	"N.TAXNO			as 'TaxNo',"+CHAR(10)+
	"N.SEARCHKEY1		as 'SearchKey1',"+CHAR(10)+
	"N.SEARCHKEY2		as 'SearchKey2',"+CHAR(10)+
	"IND.SEX				as 'GenderCode',"+CHAR(10)+
	"IND.CASUALSALUTATION	as 'CasualSalutation',"+CHAR(10)+
	"IND.FORMALSALUTATION	as 'FormalSalutation',"+CHAR(10)+
	"O.REGISTRATIONNO		as 'CompanyNo',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('ORGANISATION','INCORPORATED',null,'O',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
	"			as 'Incorporated',"+CHAR(10)+ 
	"dbo.fn_FormatNameUsingNameNo(N3.NAMENO, null)"+CHAR(10)+
	"			as 'ParentEntityName',"+CHAR(10)+ 	
	"cast((isnull(N.USEDASFLAG, 0) & 1) as bit)		as IsIndividual,"+CHAR(10)+ 
	"~cast((isnull(N.USEDASFLAG, 0) & 1) as bit)	as IsOrganisation,"+CHAR(10)+ 
	"cast((isnull(N.USEDASFLAG, 0) & 2) as bit)		as IsStaff,"+CHAR(10)+ 
	"cast((isnull(N.USEDASFLAG, 0) & 4) as bit)		as IsClient,"+CHAR(10)+
	"PA.ADDRESSCODE         as 'PostalAddressKey'"+CHAR(10)	
	
	Set @sSQLString2 = 
     	"from NAME N"+CHAR(10)+   	
	"left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY)"+CHAR(10)+ 
	-- For 'MainContactName' use Name.MainContact
	"left join NAME N1		on (N1.NAMENO  = N.MAINCONTACT)"+CHAR(10)+ 
	"left join TELECOMMUNICATION M  on (M.TELECODE = N1.MAINEMAIL)"+CHAR(10)+
	"left join COUNTRY NN1		on (NN1.COUNTRYCODE = N1.NATIONALITY)"+CHAR(10)+ 
	-- For 'OrganisationName' for the employed by relationship on AssociatedName.
	"left join ASSOCIATEDNAME EMP	on (EMP.RELATEDNAME = N.NAMENO"+CHAR(10)+ 
	"				and EMP.RELATIONSHIP = 'EMP')"+CHAR(10)+ 
	"left join NAME ORG		on (ORG.NAMENO = EMP.NAMENO)"+CHAR(10)+ 
	-- For Restriction
	"left join IPNAME IP		on (IP.NAMENO = N.NAMENO)"+CHAR(10)+ 
	"left join DEBTORSTATUS DS	on (DS.BADDEBTOR = IP.BADDEBTOR)"+CHAR(10)+ 
	-- For Category
	"left join TABLECODES CAT	on (CAT.TABLECODE = IP.CATEGORY)"+CHAR(10)+ 
	-- For Group
	"left join NAMEFAMILY GRP	on (GRP.FAMILYNO = N.FAMILYNO)"+CHAR(10)+  
	"left join NAMEIMAGE I		on (I.IMAGEID = (select min(NI.IMAGEID)"+CHAR(10)+ 
	"					         from  NAMEIMAGE NI"+CHAR(10)+ 
	"					         where NI.NAMENO = N.NAMENO))"+CHAR(10)+ 
	"left join EMPLOYEE E		on (E.EMPLOYEENO = N.NAMENO)"+CHAR(10)+ 
	"left join TABLECODES TC	on (TC.TABLECODE = E.STAFFCLASS)"+CHAR(10)+
	"left join TABLECODES CS	on (CS.TABLECODE = E.CAPACITYTOSIGN)"+CHAR(10)+
	"left join PROFITCENTRE PFC	on (PFC.PROFITCENTRECODE = E.PROFITCENTRECODE)"+CHAR(10)+
	-- Street Address details
	-- Only show the street address when its different to the postal address
	"left join ADDRESS SA 		on (SA.ADDRESSCODE = N.STREETADDRESS"+CHAR(10)+ 
	"				and N.STREETADDRESS <> N.POSTALADDRESS)"+CHAR(10)+ 	
	"left join COUNTRY SC		on (SC.COUNTRYCODE = SA.COUNTRYCODE)"+CHAR(10)+ 
	"left Join STATE SS		on (SS.COUNTRYCODE = SA.COUNTRYCODE"+CHAR(10)+ 
	" 	           	 	and SS.STATE = SA.STATE)"+CHAR(10)+ 
	-- Postal Address details 
	"left join ADDRESS PA 		on (PA.ADDRESSCODE = N.POSTALADDRESS)"+CHAR(10)+ 
	"left join COUNTRY PC		on (PC.COUNTRYCODE = PA.COUNTRYCODE)"+CHAR(10)+ 
	"left Join STATE PS		on (PS.COUNTRYCODE = PA.COUNTRYCODE"+CHAR(10)+ 
	" 	           	 	and PS.STATE = PA.STATE)"+CHAR(10)+ 
	-- Individual
	"left join INDIVIDUAL IND	on (IND.NAMENO = N.NAMENO)"+CHAR(10)+ 
	-- Organisation
	"left join ORGANISATION O	on (O.NAMENO = N.NAMENO)"+CHAR(10)+ 
	"left join NAME N3			on (N3.NAMENO = O.PARENT)"+CHAR(10)+ 	
	"where N.NAMENO = " + cast(@pnNameKey as nvarchar(15))

	exec (@sSQLString1 + @sSQLString2)
	Set @nErrorCode = @@Error
End

-- Populating Telecommunications result set
If @nErrorCode = 0
Begin
	Exec @nErrorCode = naw_ListImportantTelecom
				@pnRowCount		= @pnRowCount	OUTPUT,
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pnNameKey		= @pnNameKey,
				@pbCalledFromCentura	= @pbCalledFromCentura

End

-- Populating Lead Details result set
If @nErrorCode = 0
Begin
	Exec @nErrorCode = crm_GetLeadDetails
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pnNameKey		= @pnNameKey,
				@pbCalledFromCentura	= @pbCalledFromCentura
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameSummary to public
GO


