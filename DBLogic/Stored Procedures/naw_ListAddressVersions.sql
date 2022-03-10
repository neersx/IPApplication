-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListAddressVersions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListAddressVersions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListAddressVersions.'
	Drop procedure [dbo].[naw_ListAddressVersions]
End
Print '**** Creating Stored Procedure dbo.naw_ListAddressVersions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListAddressVersions
(
	@pnUserIdentityId	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 1,
	@pnAddressKey		int,		--Mandatory
	@pbIncludeOriginal	bit		= 1
)
as
-- PROCEDURE:	naw_ListAddressVersions
-- VERSION:	8
-- DESCRIPTION:	A stored procedure to return the different versions of a 
--		particular address.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Apr 2006	JEK	RFC3301	1	Procedure created
-- 11 Apr 2006	JEK	RFC3301	2	Add RowKey.
-- 29 May 2006	JEK	RFC3301	3	Cater for a call for a null AddressKey.
-- 28 Feb 2007	PY	SQA14425 4 	Reserved word [language]
-- 11 Dec 2008	MF	17136	5	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 06 Aug 2012	vql	12442	6	Only do translation if the translation all in same language.
-- 12 Sep 2012	vql	12442	7	Fix bug with state translation.
-- 11 Apr 2013	DV	R13270	8	Increase the length of nvarchar to 11 when casting or declaring integer


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
and @pnAddressKey is not null
Begin
	-- Are addresses translated?
	If @nErrorCode = 0
	and (	dbo.fn_GetTranslatedTIDColumn('ADDRESS','STREET1') is not null or
		dbo.fn_GetTranslatedTIDColumn('ADDRESS','CITY') is not null or
		dbo.fn_GetTranslatedTIDColumn('STATE','STATENAME') is not null
	    )
	Begin
		If @pbIncludeOriginal = 1
		Begin
			Set @sSQLString =
			"Select CAST(@pnAddressKey as nvarchar(11))
						as RowKey,
				dbo.fn_GetFormattedAddress(@pnAddressKey, null, null, null, @pbCalledFromCentura)
						as Address,
				null		as [Language]
			Union"
		End
	
		Set @sSQLString = @sSQLString+CHAR(10)+
		"Select CAST(A.ADDRESSCODE as nvarchar(11))+'^'+CU.CULTURE
					as RowKey,
			dbo.fn_FormatAddress(
				dbo.fn_GetTranslation(A.STREET1,null,A.STREET1_TID,CU.CULTURE),
				A.STREET2, 
				dbo.fn_GetTranslation(A.CITY,null,A.CITY_TID,CU.CULTURE),
				dbo.fn_GetTranslation(A.STATE,null,A.STATE_TID,CU.CULTURE),
				dbo.fn_GetTranslation(S.STATENAME,null,S.STATENAME_TID,CU.CULTURE),
				A.POSTCODE, 
				-- The country name is included in the formatted address 
				-- if the address in not in the home country
				CASE WHEN HC.COLCHARACTER = C.COUNTRYCODE
				     THEN NULL
				     ELSE dbo.fn_GetTranslation(C.POSTALNAME,null,C.POSTALNAME_TID,CU.CULTURE) END,
				C.POSTCODEFIRST, 
				C.STATEABBREVIATED, 
				dbo.fn_GetTranslation(C.POSTCODELITERAL,null,C.POSTCODELITERAL_TID,CU.CULTURE), 
				isnull(SC.COLINTEGER, C.ADDRESSSTYLE)
				)	as Address,"+CHAR(10)+
			CASE WHEN @pbCalledFromCentura = 1 
			     THEN -- When called from Centura, this should be obtained from
				  -- the client/server Language (TableCodes):
				  "TC.DESCRIPTION	as [Language]"
			     ELSE "CU.DESCRIPTION	as [Language]" 	
			END+CHAR(10)+	
		"from CULTURE CU
		join ADDRESS A			on (A.ADDRESSCODE = @pnAddressKey)
		join COUNTRY C  		on (C.COUNTRYCODE = A.COUNTRYCODE)
		join TRANSLATEDTEXT TT 		on (TT.CULTURE = CU.CULTURE
						and TT.TID = C.POSTALNAME_TID)"+char(10)+
		CASE WHEN @pbCalledFromCentura = 1 
		     THEN -- When called from Centura, this should be obtained from
			  -- the client/server Language (TableCodes):
			  "join TABLECODES TC 	on (TC.USERCODE = CU.CULTURE"+CHAR(10)+
			  "			and TC.TABLETYPE = 47)"
		END+CHAR(10)+
		"left join STATE S		on (S.COUNTRYCODE = A.COUNTRYCODE
						and S.STATE = A.STATE)
		left join TRANSLATEDTEXT TTS1 	on (TTS1.CULTURE = CU.CULTURE
						and TTS1.TID = A.STREET1_TID)
		left join TRANSLATEDTEXT TTCITY on (TTCITY.CULTURE = CU.CULTURE
						and TTCITY.TID = A.CITY_TID)
		left join TRANSLATEDTEXT TTSTATE on (TTSTATE.CULTURE = CU.CULTURE
						and  TTSTATE.TID = S.STATENAME_TID)
		left join SITECONTROL SC	on (SC.CONTROLID = 'Address Style '+CU.CULTURE)
		left join SITECONTROL HC	on (HC.CONTROLID = 'HOMECOUNTRY')
		-- Only return the translation if the translation is all in same language.
		where (	TTS1.CULTURE = TTCITY.CULTURE and  TTCITY.CULTURE = TTSTATE.CULTURE )
		     "+char(10)+
		CASE WHEN @pbCalledFromCentura = 1 THEN
		-- Centura may only view languages valid for the code page of the database
		"and exists(	Select 1 
				from 	CULTURECODEPAGE CP
				where 	(CP.CULTURE=CU.CULTURE
				or 	CP.CULTURE=dbo.fn_GetParentCulture(CU.CULTURE))
				-- Compare the culture's collation code to the collation code
				-- of the current database:
				and	CP.CODEPAGE = 	CAST(
								COLLATIONPROPERTY( 
									CONVERT(nvarchar(50), 
										DATABASEPROPERTYEX(db_name(),'collation')),
							 		'codepage') 
							 as smallint))"
		END+char(10)+
		"order by Language"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnAddressKey	int,
					  @pbCalledFromCentura	bit',
					  @pnAddressKey = @pnAddressKey,
					  @pbCalledFromCentura = @pbCalledFromCentura
	
	End
	Else
	Begin
		If @pbIncludeOriginal = 1
		Begin
			Set @sSQLString =
			"Select CAST(@pnAddressKey as nvarchar(11))
						as RowKey,
				dbo.fn_GetFormattedAddress(@pnAddressKey, null, null, null, @pbCalledFromCentura)
						as Address,
				null		as [Language]"
		End
		Else
		Begin
			-- Force an empty result set
			Set @sSQLString =
			"Select null		as RowKey
			where 1=0"
	
		End
	

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnAddressKey	int,
					  @pbCalledFromCentura	bit',
					  @pnAddressKey = @pnAddressKey,
					  @pbCalledFromCentura = @pbCalledFromCentura
	
	End
End
Else
Begin
	-- Force an empty result set
	Set @sSQLString =
	"Select null		as RowKey
	where 1=0"

	exec @nErrorCode=sp_executesql @sSQLString

End
	

Return @nErrorCode
GO

Grant execute on dbo.naw_ListAddressVersions to public
GO
