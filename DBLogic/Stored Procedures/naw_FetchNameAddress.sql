-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchNameAddress									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchNameAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchNameAddress.'
	Drop procedure [dbo].[naw_FetchNameAddress]
End
Print '**** Creating Stored Procedure dbo.naw_FetchNameAddress...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_FetchNameAddress
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,			-- Mandatory
	@pbNewRow		bit		= 0,	-- If to create template row
	@pbMainAddresses	bit		= 0,	-- If only return main
	@pnAddressTypeKey	int		= null, -- The address type to return for new row
	@pnCopyFromNameKey	int		= null,	-- They key of a name that a main address maybe copied from
	@psCountryCode		nvarchar(3)	= null	-- The country in which the address applies
)
as
-- PROCEDURE:	naw_FetchNameAddress
-- VERSION:	12
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the NameAddress business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 05 Jun 2006	SW	RFC3787	1	Procedure created
-- 19 Jun 2006	PG	RFC3787 2 	Return RowKey when @pnNewRow=1
-- 27 Jun 2006	SW	RFC4036 3 	Suppress duplicate rows
-- 29 Jun 2006	SW	RFC4036 4 	Suppress duplicate rows for new row + bug fixes.
-- 29 Jun 2006	SW	RFC4077 5 	Fixed join on STATE that will return redudant row,
--					return IsLinked regardless USEPOSTALADDRESS 0 or 1, + bug fixes.
-- 30 Nov 2007	PG	RFC3501 6 	Return telecommunication details
-- 11 Dec 2008	MF	17136	7	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 26 Jul 2010	SF	RFC9563	8	Ensure IsOwner flag is returned as either a 0 or a 1.
-- 11 Apr 2013	DV	R13270	9	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	10	Adjust formatted names logic (DR-15543).
-- 17 Mar 2017	MF	70924	11	Postal address is not taking the users culture into consideration.
-- 05 Sep 2019	AK	DR-15204	12	Return all Postal address from @pnCopyFromNameKey.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sLookupCulture		nvarchar(10)
Declare @sSQLString 		nvarchar(max)
Declare @sSelect		nvarchar(max)
Declare @sFrom			nvarchar(max)
Declare @sOrder			nvarchar(max)
Declare @sRowKey	nvarchar(200)


-- Initialise variables
Set @nErrorCode = 0

If @psCulture is not null
Begin
	Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
End 

If @pbNewRow <> 1 or 
   (@pnCopyFromNameKey is not null and @pnAddressTypeKey is null)
Begin

	IF (@pnCopyFromNameKey is not null and @pnAddressTypeKey is null)
		Begin
				set @pnNameKey = @pnCopyFromNameKey
				set @sRowKey   = "'-1^'+ CAST(NA.ADDRESSTYPE as nvarchar(11))+'^'+CAST(NA.ADDRESSCODE as nvarchar(11))		as RowKey "+char(10)
		End
	Else
		Begin
			set @sRowKey   = "CAST(NA.NAMENO as nvarchar(11))+'^'+CAST(NA.ADDRESSTYPE as nvarchar(11))+'^'+CAST(NA.ADDRESSCODE as nvarchar(11))		as RowKey"
		End

	Set @sSelect = "Select " + @sRowKey +"	,"+char(10)+
		"NA.NAMENO	as NameKey,"+char(10)+
		"NA.ADDRESSCODE as AddressKey,"+char(10)+
		"NA.ADDRESSTYPE as AddressTypeKey,"+char(10)+
			"dbo.fn_GetTranslation(ATD.[DESCRIPTION],null,ATD.DESCRIPTION_TID,'"+@sLookupCulture+"')"+char(10)+
			"as AddressTypeDescription,"+char(10)+
		"CASE"+char(10)+
			"WHEN ((NA.ADDRESSTYPE = 301 and N.POSTALADDRESS = NA.ADDRESSCODE)"+char(10)+
				"or (NA.ADDRESSTYPE = 302 and N.STREETADDRESS = NA.ADDRESSCODE))"+char(10)+
			"THEN cast(1 as bit)"+char(10)+
			"ELSE cast(0 as bit)"+char(10)+
		"END as IsMain,"+char(10)+
		"cast(ISNULL(NA.OWNEDBY, 0) as bit)	as IsOwner,"+char(10)+
		"CASE WHEN AC.UsedByNameCount > 1 THEN 1 "+char(10)+
				"ELSE 0"+char(10)+
		"END as IsLinked,"+char(10)+
		"ONA.NAMENO as BelongsToKey,"+char(10)+
		"dbo.fn_FormatNameUsingNameNo(O.NAMENO, NULL) as BelongsToName,"+char(10)+
		"O.NAMECODE as BelongsToCode,"+char(10)+
		-- only do isnull if UsePostalAddress = 0
		"CASE"+char(10)+
			"WHEN UP.USEPOSTAL is null"+char(10)+
			"THEN isnull(AC.UsedByNameCount, 0)"+char(10)+
		"END  as UsedByNameCount,"+char(10)+
		"CASE"+char(10)+
			"WHEN UP.USEPOSTAL is null"+char(10)+
			"THEN isnull(CNC.UsedByCaseCount, 0)"+char(10)+
		"END as UsedByCaseCount,"+char(10)+
		"cast(isnull(UP.USEPOSTAL, 0) as bit) as UsePostalAddress,"+char(10)+
		"CASE WHEN UP.USEPOSTAL is null THEN"+char(10)+
			"dbo.fn_FormatAddress(dbo.fn_GetTranslation(A.STREET1,null,A.STREET1_TID,'"+@sLookupCulture+"'), 
						null, 
						dbo.fn_GetTranslation(A.CITY,null,A.CITY_TID,'"+@sLookupCulture+"'),
						dbo.fn_GetTranslation(A.STATE,null,A.STATE_TID,'"+@sLookupCulture+"'),
						dbo.fn_GetTranslation(S.STATENAME,null,S.STATENAME_TID,'"+@sLookupCulture+"'),
						A.POSTCODE, 
						dbo.fn_GetTranslation(C.POSTALNAME,null,C.POSTALNAME_TID,'"+@sLookupCulture+"'),
						C.POSTCODEFIRST, 
						C.STATEABBREVIATED,
						dbo.fn_GetTranslation(C.POSTCODELITERAL,null,C.POSTCODELITERAL_TID,'"+@sLookupCulture+"'),
						C.ADDRESSSTYLE)"+char(10)+
		"END as FormattedAddress,"+char(10)+
		"CASE"+char(10)+
			"WHEN UP.USEPOSTAL is null"+char(10)+
			"THEN dbo.fn_GetTranslation(A.STREET1,null,A.STREET1_TID,'"+@sLookupCulture+"')"+char(10)+
		"END as Street,"+char(10)+
		"CASE"+char(10)+
			"WHEN UP.USEPOSTAL is null"+char(10)+
			"THEN dbo.fn_GetTranslation(A.CITY,null,A.CITY_TID,'"+@sLookupCulture+"')"+char(10)+
		"END as City,"+char(10)+
		"CASE"+char(10)+
			"WHEN UP.USEPOSTAL is null"+char(10)+
			"THEN dbo.fn_GetTranslation(A.STATE,null,A.STATE_TID,'"+@sLookupCulture+"')"+char(10)+
		"END as StateCode,"+char(10)+
		"CASE"+char(10)+
			"WHEN UP.USEPOSTAL is null"+char(10)+
			"THEN dbo.fn_GetTranslation(S.STATENAME,null,S.STATENAME_TID,'"+@sLookupCulture+"')"+char(10)+
		"END as StateName,"+char(10)+
		"CASE"+char(10)+
			"WHEN UP.USEPOSTAL is null"+char(10)+
			"THEN A.POSTCODE"+char(10)+
		"END as PostCode,"+char(10)+
		"CASE"+char(10)+
			"WHEN UP.USEPOSTAL is null"+char(10)+
			"THEN A.COUNTRYCODE"+char(10)+
		"END as CountryCode,"+char(10)+
		"CASE"+char(10)+
			"WHEN UP.USEPOSTAL is null"+char(10)+
			"THEN dbo.fn_GetTranslation(C.POSTALNAME,null,C.POSTALNAME_TID,'"+@sLookupCulture+"')"+char(10)+
		"END as CountryName,"+char(10)+
		"dbo.fn_GetTranslation(C.STATELITERAL,null,C.STATELITERAL_TID,'" + @sLookupCulture + "')"+char(10)+
			"as StateLiteral,"+char(10)+
		"dbo.fn_GetTranslation(C.POSTCODELITERAL,null,C.POSTCODELITERAL_TID,'"+@sLookupCulture+"')"+char(10)+
			"as PostCodeLiteral,"+char(10)+
		"A.TELEPHONE as TelephoneKey,"+char(10)+
		"A.FAX as FaxKey,"+char(10)+
		"NA.ADDRESSSTATUS	as AddressStatusKey,"+char(10)+
		"dbo.fn_GetTranslation(AST.[DESCRIPTION],null,AST.DESCRIPTION_TID,'"+@sLookupCulture+"')"+char(10)+
			"as AddressStatus,"+char(10)+
		"NA.DATECEASED as DateCeased,"+char(10)+
		"T.ISD as TelephoneISD,"+char(10)+
		"T.AREACODE as TelephoneAreaCode,"+char(10)+
		"T.TELECOMNUMBER as TelephoneNumber,"+char(10)+
		"T.EXTENSION as TelephoneExt,"+char(10)+
		"T1.ISD as FaxISD,"+char(10)+
		"T1.AREACODE as FaxAreaCode,"+char(10)+
		"T1.TELECOMNUMBER as FaxNumber"


	Set @sFrom = "	from NAMEADDRESS NA"+char(10)
		
	-- Address Type Description
	Set @sFrom = @sFrom +
		"	left join	TABLECODES ATD on (ATD.TABLECODE = NA.ADDRESSTYPE)"+char(10)

	-- Set USEPOSTAL
	Set @sFrom = @sFrom +
		"	left join	[NAME] N on (N.NAMENO = NA.NAMENO)"+char(10)+
		"	left join (	Select	NAMENO, 1 as USEPOSTAL"+char(10)+
					" from 	[NAME] N2"+char(10)+
					" where	N2.POSTALADDRESS = N2.STREETADDRESS"+char(10)+
					" and	N2.NAMENO = "+ cast(@pnNameKey as nvarchar(11))+char(10)+
					" ) UP on (UP.NAMENO = NA.NAMENO and NA.ADDRESSTYPE = 302 and N.STREETADDRESS = NA.ADDRESSCODE)"+char(10)

	-- AC - ADDRESSCODE count
	Set @sFrom = @sFrom +
		"	left join (	Select	N1.ADDRESSCODE,"+char(10)+
					" COUNT(distinct N1.NAMENO) as UsedByNameCount"+char(10)+
					" from	NAMEADDRESS N1"+char(10)+
					" where	N1.ADDRESSCODE is not null"+char(10)+
					" group by N1.ADDRESSCODE"+char(10)+
					" ) AC on (AC.ADDRESSCODE = NA.ADDRESSCODE)"+char(10)

	-- CNC - CASENAME count
	Set @sFrom = @sFrom +
		"	left join (	 Select	C.ADDRESSCODE,"+char(10)+
					" COUNT(distinct C.CASEID) as UsedByCaseCount"+char(10)+
					"from CASENAME C"+char(10)+
					"where C.ADDRESSCODE is not null"+char(10)+
					"group by C.ADDRESSCODE"+char(10)+
					") CNC on (CNC.ADDRESSCODE = NA.ADDRESSCODE and UP.USEPOSTAL is null)"+char(10)

	-- ONA - Find out 1 and only 1 owner row of the current row
	Set @sFrom = @sFrom +
		"	left join	(select MAX(ONA.NAMENO) NAMENO, ONA.ADDRESSTYPE, ONA.ADDRESSCODE"+char(10)+
					"from NAMEADDRESS ONA"+char(10)+
					"join NAMEADDRESS NA on (    NA.NAMENO = "+ cast(@pnNameKey as nvarchar(11))+char(10)+
								"and NA.ADDRESSTYPE = ONA.ADDRESSTYPE"+char(10)+
								"and NA.ADDRESSCODE = ONA.ADDRESSCODE"+char(10)+
								"and ISNULL(NA.OWNEDBY,0) = 0"+char(10)+
								"and ONA.OWNEDBY = 1)"+char(10)+
					"group by ONA.ADDRESSTYPE, ONA.ADDRESSCODE"+char(10)+
					") ONA on (UP.USEPOSTAL is null"+char(10)+
						        "and ONA.ADDRESSTYPE = NA.ADDRESSTYPE"+char(10)+
						        "and ONA.ADDRESSCODE = NA.ADDRESSCODE)"+char(10)

	-- O - details of owner
	Set @sFrom = @sFrom +
		"	left join	[NAME] O on (O.NAMENO = ONA.NAMENO)"+char(10)+
		"	left join	ADDRESS A on (A.ADDRESSCODE = NA.ADDRESSCODE)"+char(10)+
		"	left join	STATE S on (S.STATE = A.STATE and S.COUNTRYCODE = A.COUNTRYCODE)"+char(10)+
		"	left join	COUNTRY C on (C.COUNTRYCODE = A.COUNTRYCODE)"+char(10)+
		"	left join	TABLECODES AST on (AST.TABLECODE = NA.ADDRESSSTATUS)"+char(10)+
		"	left join	[TELECOMMUNICATION] T on (T.TELECODE = A.TELEPHONE)"+char(10)+
		"	left join	[TELECOMMUNICATION] T1 on (T1.TELECODE = A.FAX)"+char(10)+
		"	where NA.NAMENO = " + cast(@pnNameKey as nvarchar(11))


	Set @sOrder = "	order by NameKey,"+char(10)+ 
			" Case NA.ADDRESSTYPE"+char(10)+
				" When '301' then 1"+char(10)+
				" When '302' then 2"+char(10)+
				" Else 3"+char(10)+
			" End,"+char(10)+
			" IsMain desc,"+char(10)+
			" ATD.[DESCRIPTION],"+char(10)+
			" NA.ADDRESSCODE"

	-- @sSQLString exceeded 4000 char
	--Set @sSQLString = @sSelect + @sFrom + @sOrder
	exec (@sSelect + @sFrom + @sOrder)

	Select 	@nErrorCode =@@ERROR
End
Else
-- do defaulting
Begin
	
	Set @sSelect =  "Select"+char(10)+
	--"'-1^'+CAST(@pnAddressTypeKey as nvarchar(10))+'^'++CAST(NA.ADDRESSCODE as nvarchar(10)) as RowKey,"+char(10)+
	"@pnNameKey		as NameKey,"+char(10)+
	"CASE WHEN NA.NAMENO is not null THEN NA.ADDRESSCODE
	     ELSE null
	END 			as AddressKey,
	@pnAddressTypeKey	as AddressTypeKey,
	dbo.fn_GetTranslation(ATD.[DESCRIPTION],null,ATD.DESCRIPTION_TID,@sLookupCulture)
				as AddressTypeDescription,
	CASE WHEN NA.NAMENO is not null or @pbMainAddresses = 1 THEN cast(1 as bit)
	     ELSE cast(0 as bit)		
	END			as IsMain,
	CASE WHEN NA.NAMENO is not null THEN cast(0 as bit)
	     ELSE cast(1 as bit)			
	END			as IsOwner,
	CASE WHEN NA.NAMENO is not null THEN cast(1 as bit)
	     ELSE cast(0 as bit)	
	END			as IsLinked,
	ONA.NAMENO		as BelongsToKey,
	dbo.fn_FormatNameUsingNameNo(O.NAMENO, null) as BelongsToName,
	O.NAMECODE		as BelongsToCode,
	cast(ISNULL(UP.USEPOSTAL, 0) as bit) as UsePostalAddress,
	CASE WHEN UP.USEPOSTAL = 1 THEN null
	     ELSE ISNULL(AC.UsedByNameCount, 1)
	END			as UsedByNameCount,
	CASE WHEN UP.USEPOSTAL = 1 THEN null
	     ELSE ISNULL(CNC.UsedByCaseCount, 0)
	END			as UsedByCaseCount,
	CASE WHEN UP.USEPOSTAL is null
	     THEN 
		dbo.fn_FormatAddress(dbo.fn_GetTranslation(A.STREET1,null,A.STREET1_TID,@sLookupCulture), 
				     null,
				     dbo.fn_GetTranslation(A.CITY,null,A.CITY_TID,@sLookupCulture),
				     dbo.fn_GetTranslation(A.STATE,null,A.STATE_TID,@sLookupCulture),
				     dbo.fn_GetTranslation(S.STATENAME,null,S.STATENAME_TID,@sLookupCulture),
				     A.POSTCODE,
				     dbo.fn_GetTranslation(C.POSTALNAME,null,C.POSTALNAME_TID,@sLookupCulture),
				     C.POSTCODEFIRST,
				     C.STATEABBREVIATED,
				     dbo.fn_GetTranslation(C.POSTCODELITERAL,null,C.POSTCODELITERAL_TID,@sLookupCulture),
				     C.ADDRESSSTYLE)
	END			as FormattedAddress,
	CASE WHEN UP.USEPOSTAL is null
	     THEN dbo.fn_GetTranslation(A.STREET1,null,A.STREET1_TID,@sLookupCulture)
	END			as Street,
	CASE WHEN UP.USEPOSTAL is null
	     THEN dbo.fn_GetTranslation(A.CITY,null,A.CITY_TID,@sLookupCulture)	
	END			as City,
	CASE WHEN UP.USEPOSTAL is null
	     THEN dbo.fn_GetTranslation(A.STATE,null,A.STATE_TID,@sLookupCulture)
	END			as StateCode,
	CASE WHEN UP.USEPOSTAL is null
	     THEN dbo.fn_GetTranslation(S.STATENAME,null,S.STATENAME_TID,@sLookupCulture)
	END			as StateName,
	CASE WHEN UP.USEPOSTAL is null
	     THEN A.POSTCODE
	END			as PostCode,
	CASE WHEN UP.USEPOSTAL is null
	     THEN COALESCE(A.COUNTRYCODE, @psCountryCode, SC.COLCHARACTER)
	END			as CountryCode,
	CASE WHEN UP.USEPOSTAL is null
	     THEN dbo.fn_GetTranslation(C.POSTALNAME,null,C.POSTALNAME_TID,@sLookupCulture)
	END			as CountryName,
	dbo.fn_GetTranslation(C.STATELITERAL,null,C.STATELITERAL_TID,@sLookupCulture)
				as StateLiteral,
	dbo.fn_GetTranslation(C.POSTCODELITERAL,null,C.POSTCODELITERAL_TID,@sLookupCulture)
				as PostCodeLiteral,
	A.TELEPHONE		as TelephoneKey,
	A.FAX			as FaxKey,
	null			as AddressStatusKey,
	null			as AddressStatus,
	null			as DateCeased"

	Set @sFrom = "	from		(select 1 as txt) dum" + char(10)

	-- return the main address column of @pnAddressTypeKey from NAMEADDRESS
	Set @sFrom = @sFrom + 
	"left join	(Select NA.*"+char(10)+
			"from NAMEADDRESS NA"+char(10)+
			"join [NAME] N on ( ( (@pnAddressTypeKey = 301 and N.POSTALADDRESS = NA.ADDRESSCODE)"+char(10)+
				                 "or (@pnAddressTypeKey = 302 and N.STREETADDRESS = NA.ADDRESSCODE))"+char(10)+
			                   "and (NA.NAMENO = N.NAMENO)"+char(10)+
			                   "and (NA.ADDRESSTYPE = @pnAddressTypeKey)"+char(10)+
			                   "and (NA.NAMENO = @pnCopyFromNameKey))"+char(10)+
			") NA on (NA.NAMENO = @pnCopyFromNameKey)"+char(10)+
	"left join	TABLECODES ATD on (ATD.TABLECODE = @pnAddressTypeKey)"+char(10)

	-- Set USEPOSTAL
	Set @sFrom = @sFrom +
		"left join [NAME] N on (N.NAMENO = NA.NAMENO)"+char(10)+
		"left join (Select NAMENO, 1 as USEPOSTAL"+char(10)+
				"from 	[NAME] N2"+char(10)+
				"where	N2.POSTALADDRESS = N2.STREETADDRESS"+char(10)+
				") UP on (UP.NAMENO = NA.NAMENO and NA.ADDRESSTYPE = 302 and N.STREETADDRESS = NA.ADDRESSCODE)" + char(10)

	-- ADDRESSCODE count
	-- add 1 to UsedByNameCount as this is a new row that will be added to the database
	Set @sFrom = @sFrom +
	"left join (Select	N1.ADDRESSCODE,"+char(10)+
				"COUNT(distinct N1.NAMENO) + 1 as UsedByNameCount"+char(10)+
			"from	NAMEADDRESS N1"+char(10)+
			"where	N1.ADDRESSCODE is not null"+char(10)+
			"group by N1.ADDRESSCODE"+char(10)+
			") AC on (AC.ADDRESSCODE = NA.ADDRESSCODE and UP.USEPOSTAL is null)"+char(10)

	-- ONA - Find out the owner row of the current row
	Set @sFrom = @sFrom +
	"left join	NAMEADDRESS ONA  on (ONA.ADDRESSTYPE = NA.ADDRESSTYPE"+ char(10)+
						"and ONA.ADDRESSCODE = NA.ADDRESSCODE"+ char(10)+
						"and ONA.OWNEDBY = 1"+ char(10)+
						"and UP.USEPOSTAL is null)"+ char(10)
	-- CASENAME count
	Set @sFrom = @sFrom +
	"left join (Select	C.ADDRESSCODE,"+ char(10)+
				"COUNT(distinct C.CASEID) as UsedByCaseCount"+ char(10)+
			"from	CASENAME C"+ char(10)+
			"where	C.ADDRESSCODE is not null"+ char(10)+
			"group by C.ADDRESSCODE"+ char(10)+
			") CNC on (CNC.ADDRESSCODE = NA.ADDRESSCODE and UP.USEPOSTAL is null)"+ char(10)

	-- O - details of owner
	Set @sFrom = @sFrom +
	"left join	[NAME] O on (O.NAMENO = ONA.NAMENO)" + char(10) +
	"left join	SITECONTROL SC on (SC.CONTROLID = 'HOMECOUNTRY')" + char(10) +
	"left join	ADDRESS A on (A.ADDRESSCODE = NA.ADDRESSCODE)" + char(10) +
	"left join	STATE S on (S.STATE = A.STATE and S.COUNTRYCODE = COALESCE(A.COUNTRYCODE, @psCountryCode, SC.COLCHARACTER))" + char(10) +
	"left join	COUNTRY C on (C.COUNTRYCODE = COALESCE(A.COUNTRYCODE, @psCountryCode, SC.COLCHARACTER))"

	-- note @sSelect + @sFrom is almost 4000 characters now.
	Set @sSQLString = @sSelect + @sFrom
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@sLookupCulture		nvarchar(10),
			@pnNameKey		int,
			@pnCopyFromNameKey	int,
			@pnAddressTypeKey	int,
			@pbMainAddresses	bit,
			@psCountryCode		nvarchar(3)',
			@sLookupCulture		= @sLookupCulture,
			@pnNameKey		= @pnNameKey,
			@pnCopyFromNameKey	= @pnCopyFromNameKey,
			@pnAddressTypeKey	= @pnAddressTypeKey,
			@pbMainAddresses	= @pbMainAddresses,
			@psCountryCode		= @psCountryCode

	End
	
Return @nErrorCode
GO

Grant execute on dbo.naw_FetchNameAddress to public
GO