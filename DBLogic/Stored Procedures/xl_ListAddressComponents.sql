-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xl_ListAddressComponents
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[xl_ListAddressComponents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.xl_ListAddressComponents.'
	Drop procedure [dbo].[xl_ListAddressComponents]
End
Print '**** Creating Stored Procedure dbo.xl_ListAddressComponents...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.xl_ListAddressComponents
(
	@pnUserIdentityId	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 1,
	@pnAddressKey		int		--Mandatory
)
as
-- PROCEDURE:	xl_ListAddressComponents
-- VERSION:	2
-- DESCRIPTION:	Returns a list of the translations currently available for an address 
--		in a form suitable to perform maintenance on the translations.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Sep 2004	TM	RFC1806	1	Procedure created
-- 06 Oct 2004	TM	RFC1695	2	Add the following to the join on the TABLECODES table: "and TC.TABLETYPE = 47".


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- Populate the Address Components data
If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select TT.CULTURE 		as Culture,"+CHAR(10)+
		CASE WHEN @pbCalledFromCentura = 1 
		     THEN -- When called from Centura, this should be obtained from
			  -- the client/server Language (TableCodes):
			  "TC.DESCRIPTION	as 'LanguageDescription',"
		     ELSE "CL.DESCRIPTION	as 'LanguageDescription'," 	
		END+CHAR(10)+
		"TTS1.SHORTTEXT 	as Street1,
		A.STREET1_TID		as Street1_TID,
		TTCITY.SHORTTEXT 	as City,
		A.CITY_TID		as City_TID, 
		TTSTATE.SHORTTEXT 	as StateName,
		TT.SHORTTEXT 		as Country, 
		A.POSTCODE		as Postcode		
	from ADDRESS A
	join COUNTRY C  		on (C.COUNTRYCODE = A.COUNTRYCODE)
	join TRANSLATEDTEXT TT 		on (TT.TID = C.POSTALNAME_TID)"+char(10)+
	CASE WHEN @pbCalledFromCentura = 1 
	     THEN -- When called from Centura, this should be obtained from
		  -- the client/server Language (TableCodes):
		  "join TABLECODES TC 	on (UPPER(TC.USERCODE) = TT.CULTURE"+CHAR(10)+
		  "			and TC.TABLETYPE = 47)"
		  -- Otherwise, obtain from Culture.Description:
	     ELSE "join CULTURE CL		on (CL.CULTURE = TT.CULTURE)" 	
	END+CHAR(10)+
	"left join STATE S		on (S.COUNTRYCODE = A.COUNTRYCODE
					and S.STATE = A.STATE)
	left join TRANSLATEDTEXT TTS1 	on (TTS1.CULTURE = TT.CULTURE
					and TTS1.TID = A.STREET1_TID)
	left join TRANSLATEDTEXT TTCITY on (TTCITY.CULTURE = TT.CULTURE
					and TTCITY.TID = A.CITY_TID)
	left join TRANSLATEDTEXT TTSTATE on (TTSTATE.CULTURE = TT.CULTURE
					and  TTSTATE.TID = S.STATENAME_TID)
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
				N'@pnAddressKey	int',
				  @pnAddressKey = @pnAddressKey	
End
	

Return @nErrorCode
GO

Grant execute on dbo.xl_ListAddressComponents to public
GO
