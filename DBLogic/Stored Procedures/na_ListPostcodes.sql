-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_ListPostcodes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListPostcodes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_ListPostcodes.'
	Drop procedure [dbo].[na_ListPostcodes]
End
Print '**** Creating Stored Procedure dbo.na_ListPostcodes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.na_ListPostcodes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psCountryCode		nvarchar(3),	-- Mandatory
	@psState		nvarchar(20)	= null,
	@psCity			nvarchar(30)	= null,
	@psPostcode		nvarchar(10)	= null,
	@psSortOrder		nvarchar(10) 	= null
)
as
-- PROCEDURE:	na_ListPostcodes
-- VERSION:	3
-- SCOPE:	InProma
-- DESCRIPTION:	Returns data from the POSTCODE table (with joined data)
--		- If the city is provided then matching postcodes will be returned if 
--		that country has that option (POSTCODEAUTOFLAG) is set.
--		- If postcode is provided then matching cities will be returned depending 
-- 		on the setting of POSTCODESEARCHCODE
--		- Otherwise will return a result set matching the passed state and/or city
--
-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 18-AUG-2003  JB	1	Procedure created
-- 29-AUG-2003	JB	2	Enhancement to cover the situation where both the city and
--				postcode are passed - now tries to return a recordset if both specified
-- 21-JUN-2006	Dw	3	11923 adjusted SQL to handle apostrophe in city field.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Set @nErrorCode = 0

-- Declare @sOfficeCulture	nvarchar(10)
-- Set @sOfficeCulture = dbo.fn_GetOfficeCulture()

Declare @nPostcodeMatchMethod int
Declare @sPostcodeToMatch nvarchar(10)
Declare @sSelect nvarchar(4000)
Declare @sWhere nvarchar(4000)
Declare @sOrder nvarchar(4000)
Declare @sSQL nvarchar(4000)
Declare @bOK bit

-- Initialise
Set @pnRowCount = null
Set @bOK = 1


Set @sSelect = "
	Select 	P.POSTCODE, P.CITY, S.STATE, S.STATENAME, C.COUNTRYCODE, C.COUNTRY
	from 	POSTCODE P
		left join STATE S on S.STATE = P.STATE 
			and S.COUNTRYCODE = P.COUNTRYCODE
		left join COUNTRY C on C.COUNTRYCODE = P.COUNTRYCODE "

Set @sWhere = "	where P.COUNTRYCODE = '" + @psCountryCode + "'"

-- Matching ----------------------------------------
-- They are trying to match on postcode (to find city)
If @psPostcode is not null
Begin
	-- Find out the method to use to match on addresses

	Select @nPostcodeMatchMethod = POSTCODESEARCHCODE
		from COUNTRY 
		where COUNTRYCODE = @psCountryCode

	If @nPostcodeMatchMethod = 9002  -- Full Postcode match
		Set @sWhere = @sWhere + " and UPPER(P.POSTCODE) = '" + UPPER(@psPostcode) + "'" --  and P.CITY is not null"

	If @nPostcodeMatchMethod = 9001 -- First part of postcode
	Begin
		Set @sPostcodeToMatch = rtrim(LEFT(@psPostcode, CHARINDEX(' ', @psPostcode)))
		if LEN(@sPostcodeToMatch) = 0
			Set @sPostcodeToMatch = @psPostcode  -- Use whole as no first part could be found
		Set @sWhere = @sWhere + " and UPPER(P.POSTCODE) LIKE '" + UPPER(@sPostcodeToMatch) + "%'" -- and P.CITY is not null"
	End

	-- If they are trying to match on postcode but no method is found the abort
	If @nPostcodeMatchMethod is null and @psCity is null
		Set @bOK = 0
End

-- The are trying to find the postcode from the city
If @psCity is not null
Begin
	If exists(Select * from COUNTRY where COUNTRYCODE = @psCountryCode and POSTCODEAUTOFLAG = 1)
		--Set @sWhere = @sWhere + " and UPPER(P.CITY) = '" + UPPER(@psCity) + "'" 
		Set @sWhere = @sWhere + " and UPPER(P.CITY) = UPPER(@psCity) " 
	Else
		If @psPostcode is null
			Set @bOK = 0  
End

-- State
If @psState is not null
	Set @sWhere = @sWhere + " and ( P.STATE = '" + @psState + "' or P.STATE is null) "

If upper(@psSortOrder) = 'POSTCODE'
	Set @sOrder = " order by P.POSTCODE"

If upper(@psSortOrder) = 'CITY'
	Set @sOrder = " order by P.CITY"

Set @sSQL = @sSelect + @sWhere + @sOrder


-- Execute the SQL
Print 'Debugging Information Follows:'
If (@bOK = 0)
	Print '- Country does not allow that type of matching'
Else
Begin
	Print @sSQL

	-- Now run the actual SQL!
	exec @nErrorCode=sp_executesql @sSQL,
					N'@psCity	nvarchar(30)',
					@psCity
	
	Select @pnRowCount = @@ROWCOUNT, @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.na_ListPostcodes to public
GO
