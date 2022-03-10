-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_ListAddressTranslations
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListAddressTranslations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_ListAddressTranslations.'
	Drop procedure [dbo].[na_ListAddressTranslations]
End
Print '**** Creating Stored Procedure dbo.na_ListAddressTranslations...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.na_ListAddressTranslations
(
	@pnUserIdentityId	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 1,
	@pnAddressKey		int,		--Mandatory
	@pnAddressStyle		int		= null		-- The address style to use when formatting the address.  If not provided, it will be defaulted appropriately.	
)
as
-- PROCEDURE:	na_ListAddressTranslations
-- VERSION:	3
-- DESCRIPTION:	Returns a list of the translations currently available for an address, formatted for presentation.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Sep 2004	TM	RFC1806	1	Procedure created
-- 06 Oct 2004	TM	RFC1695	2	Add the following to the join on the TABLECODES table: "and TC.TABLETYPE = 47".
-- 11 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  TT.CULTURE 		as Culture,"+CHAR(10)+
		CASE WHEN @pbCalledFromCentura = 1 
		     THEN -- When called from Centura, this should be obtained from
			  -- the client/server Language (TableCodes):
			  "TC.DESCRIPTION	as 'LanguageDescription',"
		     ELSE "CL.DESCRIPTION	as 'LanguageDescription'," 	
		END+CHAR(10)+		 
		"dbo.fn_FormatAddress(
		dbo.fn_GetTranslation(A.STREET1,null,A.STREET1_TID,TT.CULTURE),
		A.STREET2, 
		dbo.fn_GetTranslation(A.CITY,null,A.CITY_TID,TT.CULTURE),
		A.STATE, 
		dbo.fn_GetTranslation(S.STATENAME,null,S.STATENAME_TID,TT.CULTURE),
		A.POSTCODE, 
		-- The country name is included in the formatted address 
		-- if the address in not in the home country
		CASE WHEN HC.COLCHARACTER = C.COUNTRYCODE
		     THEN NULL
		     ELSE dbo.fn_GetTranslation(C.POSTALNAME,null,C.POSTALNAME_TID,TT.CULTURE) END, 
		C.POSTCODEFIRST, 
		C.STATEABBREVIATED, 
		dbo.fn_GetTranslation(C.POSTCODELITERAL,null,C.POSTCODELITERAL_TID,TT.CULTURE), 
		coalesce(@pnAddressStyle, dbo.fn_GetTranslationAddressStyle(TT.CULTURE), C.ADDRESSSTYLE))
			as FormattedAddress
		from ADDRESS A
		join COUNTRY C  		on (C.COUNTRYCODE = A.COUNTRYCODE)
		join TRANSLATEDTEXT TT 		on (TT.TID = C.POSTALNAME_TID)"+char(10)+
		CASE WHEN @pbCalledFromCentura = 1 
		     THEN -- When called from Centura, this should be obtained from
			  -- the client/server Language (TableCodes):
			  "join TABLECODES TC 	on (TC.USERCODE = TT.CULTURE"+CHAR(10)+
		  	  "			and TC.TABLETYPE = 47)"			
			  -- Otherwise, obtain from Culture.Description:
		     ELSE "join CULTURE CL		on (CL.CULTURE = TT.CULTURE)" 	
		END+CHAR(10)+
		"left join STATE S		on (S.COUNTRYCODE = A.COUNTRYCODE
						and S.STATE = A.STATE)
		left join SITECONTROL HC	on (HC.CONTROLID = 'HOMECOUNTRY')
	where A.ADDRESSCODE = @pnAddressKey"+char(10)+
	CASE WHEN @pbCalledFromCentura = 1 THEN
	-- Centura may only view languages valid for the code page of the database
	"and exists(	Select 1 
			from 	CULTURECODEPAGE CP
			where 	(CP.CULTURE=TT.CULTURE
			or 	CP.CULTURE=dbo.fn_GetParentCulture(TT.CULTURE))
			-- Compare the culture's collation code to the collation code
			-- of the current database:
			and	CP.CODEPAGE = 	CAST(
							COLLATIONPROPERTY( 
								CONVERT(nvarchar(50), 
									DATABASEPROPERTYEX(db_name(),'collation')),
						 		'codepage') 
						 as smallint))"
	END	

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnAddressKey		int,
				  @pbCalledFromCentura	int,
				  @pnAddressStyle	int',
				  @pnAddressKey 	= @pnAddressKey,
				  @pbCalledFromCentura	= @pbCalledFromCentura,
				  @pnAddressStyle	= @pnAddressStyle
	
End
	

Return @nErrorCode
GO

Grant execute on dbo.na_ListAddressTranslations to public
GO
