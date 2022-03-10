---------------------------------------------------------------------------------------------
-- Creation of dbo.mk_ListContactInformation
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mk_ListContactInformation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.mk_ListContactInformation.'
	drop procedure [dbo].[mk_ListContactInformation]
	Print '**** Creating Stored Procedure dbo.mk_ListContactInformation...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.mk_ListContactInformation
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey 		int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	mk_ListContactInformation
-- VERSION:	5
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates a ContactInformationData dataset.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 10 Feb 2005  TM		1	Procedure created
-- 15 May 2005	JEK		2	RFC2508	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 15 Oct 2007	SF		3	RFC5429/RFC5053 - add Debtor Restrictions and formatted names.
-- 11 Dec 2008	MF	17136	4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 02 Nov 2015	vql	R53910	5	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

-- Populating the ContactDetails result set
If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select	 N.NAMENO 	as 'NameKey',		 
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'Name',
		N.NAMECODE	as 'NameCode',
		"+dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura)
			     +" as 'Restriction',		 
		DS.ACTIONFLAG	as 'RestrictionActionKey',"
		 + dbo.fn_SqlTranslatedColumn('ASSOCIATEDNAME','POSITION',null,'EMP',@sLookupCulture,@pbCalledFromCentura)+"	
				as 'Position',		
		 dbo.fn_FormatAddress(SA.STREET1, SA.STREET2, SA.CITY, SA.STATE, SS.STATENAME, SA.POSTCODE, SC.POSTALNAME, SC.POSTCODEFIRST, SC.STATEABBREVIATED, SC.POSTCODELITERAL, SC.ADDRESSSTYLE)
				as 'StreetAddress',
		 dbo.fn_FormatAddress(PA.STREET1, PA.STREET2, PA.CITY, PA.STATE, PS.STATENAME, PA.POSTCODE, PC.POSTALNAME, PC.POSTCODEFIRST, PC.STATEABBREVIATED, SC.POSTCODELITERAL, PC.ADDRESSSTYLE)
				as 'PostalAddress'
	from NAME N
	left join IPNAME IP		on (IP.NAMENO = N.NAMENO)
	left join DEBTORSTATUS DS	on (DS.BADDEBTOR = IP.BADDEBTOR)
	-- Street Address details
	-- Only show the street address when its different to the postal address
	left join ADDRESS SA 		on (SA.ADDRESSCODE = N.STREETADDRESS
					and N.STREETADDRESS <> N.POSTALADDRESS)	
	left join COUNTRY SC		on (SC.COUNTRYCODE = SA.COUNTRYCODE)
	left Join STATE SS		on (SS.COUNTRYCODE = SA.COUNTRYCODE
	 	           	 	and SS.STATE = SA.STATE)
	-- Postal Address details 
	left join ADDRESS PA 		on (PA.ADDRESSCODE = N.POSTALADDRESS)
	left join COUNTRY PC		on (PC.COUNTRYCODE = PA.COUNTRYCODE)
	left Join STATE PS		on (PS.COUNTRYCODE = PA.COUNTRYCODE
	 	           	 	and PS.STATE = PA.STATE)
     	-- For 'OrganisationName' for the employed by relationship on AssociatedName.
	left join ASSOCIATEDNAME EMP	on (EMP.RELATEDNAME = N.NAMENO
					and EMP.RELATIONSHIP = 'EMP')
	where N.NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey	int',
					  @pnNameKey	= @pnNameKey
End

-- Populating ContactTelecommunication result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  N.NAMENO	as 'NameKey',"+CHAR(10)+
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'DeviceType',"+CHAR(10)+
	"	dbo.fn_FormatTelecom(T.TELECOMTYPE, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION)"+CHAR(10)+
	"			as 'TelecomNumber',"+CHAR(10)+
	"	case when T.TELECOMTYPE = 1903 THEN 1 ELSE 0 END"+CHAR(10)+
	"			as 'IsEmailAddress',"+CHAR(10)+
	"	CASE WHEN N.MAINPHONE = T.TELECODE THEN CAST(1 as bit) ELSE CAST(0 as bit) END as 'IsMainPhone',"+CHAR(10)+
	"	CASE WHEN N.FAX = T.TELECODE THEN CAST(1 as bit) ELSE CAST(0 as bit) END as 'IsMainFax',"+CHAR(10)+
	"	CASE WHEN N.MAINEMAIL = T.TELECODE THEN CAST(1 as bit) ELSE CAST(0 as bit) END as 'IsMainEmail',"+CHAR(10)+
	"	CASE WHEN SC.COLINTEGER = T.TELECOMTYPE THEN CAST(1 as bit) ELSE CAST(0 as bit) END as 'IsHomePage',"+CHAR(10)+
	"	convert(nvarchar(11),NT.NAMENO)+'^'+convert(nvarchar(11),NT.TELECODE) as 'RowKey'"+CHAR(10)+
	"from NAME N"+CHAR(10)+
	"join NAMETELECOM NT	 	on (NT.NAMENO = N.NAMENO)"+CHAR(10)+
	"join TELECOMMUNICATION T 	on (T.TELECODE = NT.TELECODE)"+CHAR(10)+
	"join TABLECODES TT		on (TT.TABLECODE = T.TELECOMTYPE)"+CHAR(10)+ 
	"left join SITECONTROL SC	on (SC.CONTROLID = 'Telecom Type - Home Page')"+CHAR(10)+ 
	"where N.NAMENO = @pnNameKey"+CHAR(10)+
	"and   (T.TELECODE IN (N.MAINPHONE,N.FAX, N.MAINEMAIL)"+CHAR(10)+
	" or    SC.COLINTEGER = T.TELECOMTYPE)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey	int',
					  @pnNameKey	= @pnNameKey
	
End

Return @nErrorCode
GO

Grant exec on dbo.mk_ListContactInformation to public
GO
