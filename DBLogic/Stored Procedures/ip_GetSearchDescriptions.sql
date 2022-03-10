-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_GetSearchDescriptions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_GetSearchDescriptions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_GetSearchDescriptions.'
	Drop procedure [dbo].[ip_GetSearchDescriptions]
End
Print '**** Creating Stored Procedure dbo.ip_GetSearchDescriptions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_GetSearchDescriptions
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10)	= null, 	-- the language in which output is to be expressed
	@psCategoryIdList	nvarchar(4000)	= null,		-- e.g. 'Abstract^Claims^CountryKey^Division'
	@psValue1List		nvarchar(4000)	= null,		-- e.g. '^^AD'
	@psCategoryList		nvarchar(4000)	= null,		
	@pbBasicSearch 		bit		= null		-- indicates whether the search is a Basic one
)
AS
-- PROCEDURE:	ip_GetSearchDescriptions
-- VERSION:	8
-- SCOPE:	CPA.net
-- DESCRIPTION:	Takes in 3 lists delimted by Carots (^) which contain the definition of the requested information
--		and returns a recordset containing the required text.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 06 Nov 2002	JB		1	Procedure created
-- 08 Nov 2002	JB		2	Now using the actual parameter names
-- 06 DEC 2002	SF		3	Do not show Acorn when NameKeys is null in Value1.
-- 12 Aug 2003  TM		4 	RFC224 Office level rules. Publish the office description 
--					if the @pnOfficeKey is present in @psCategoryIdList. 
--					Return the OFFICE.DESCRIPTION for the OFFICE.OFFICEID
--					found in the @psValueList.								
-- 29 Aug 2003	AB		5	Add 'dbo.' to create procedure
-- 18 Sep 2003  TM		6	RFC421 Field Names in Search Screens not consistent. 
--					Return the descriptions for IP Site (@pnAttributeKey4)
--					and Business Unit (@pnAttributeKey5).
-- 07 Jul 2011	DL	R10830	7	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 02 Nov 2015	vql	R53910	8	Adjust formatted names logic (DR-15543).

SET CONCAT_NULL_YIELDS_NULL OFF

-- Local variables
Declare @sCurrentCategoryId nvarchar(50)
Declare @sCurrentValue1 nvarchar(254)
Declare @sCurrentCategory nvarchar(254)
Declare @tResultSet table 
	(	CategoryID 	nvarchar(50) collate database_default, 
		CategoryDisplay	nvarchar(254) collate database_default,
		Value1Display	nvarchar(254) collate database_default 
	)


Declare @nErrorCode int
Declare @sDelimiter nchar(1)
Declare @nCurrentPos int

Set @sDelimiter = '^'
Set @nErrorCode = 0
Set @nCurrentPos = 1

While @nErrorCode = 0 -- loop till Break
Begin
	-- Reset
	Set @sCurrentCategoryId = null
	Set @sCurrentValue1 = null
	Set @sCurrentCategory = null

	-- ----------
	-- Loop through getting the current values from the parameters

	Select	@sCurrentCategoryId = [Parameter]
		From	dbo.fn_Tokenise(@psCategoryIdList, @sDelimiter)
		Where	[InsertOrder]=@nCurrentPos
	Set @nErrorCode = @@ERROR

	If @sCurrentCategoryId is null or @nErrorCode != 0
		Break

	If @nErrorCode = 0
	Begin
		Select	@sCurrentValue1 = [Parameter]
			From	dbo.fn_Tokenise(@psValue1List, @sDelimiter)
			Where	[InsertOrder]=@nCurrentPos
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		Select	@sCurrentCategory = [Parameter]
			From	dbo.fn_Tokenise(@psCategoryList, @sDelimiter)
			Where	[InsertOrder]=@nCurrentPos
		Set @nErrorCode = @@ERROR
	End

	-- ------------------------
	-- Analyse the parameters and populate results

	-- Abstract
	If @sCurrentCategoryId = '@psText3' and @nErrorCode = 0
	Begin
		Insert into @tResultSet (CategoryID, CategoryDisplay)
			Select '@psText3', TEXTDESCRIPTION
			from TEXTTYPE 
			where TEXTTYPE = 'A'
		Set @nErrorCode = @@ERROR
	End
	
	-- Claims
	Else if @sCurrentCategoryId = '@psText2' and @nErrorCode = 0
	Begin
		Insert into @tResultSet (CategoryID, CategoryDisplay)
			Select '@psText2', TEXTDESCRIPTION
			from TEXTTYPE 
			where TEXTTYPE = 'CL'
		Set @nErrorCode = @@ERROR
	End
	
	-- CountryKey
	Else if @sCurrentCategoryId = '@psCountryCodes' and @nErrorCode = 0
	Begin
		If @sCurrentValue1 is null 
		Begin
			-- Put in a place holder
			Insert into @tResultSet (CategoryID)
				values ('@psCountryCodes')
			Set @nErrorCode = @@ERROR

		End
		Else 
		Begin
			Insert into @tResultSet (CategoryID, Value1Display)
				Select '@psCountryCodes', [COUNTRY]
				from COUNTRY 
				where COUNTRYCODE = @sCurrentValue1
			Set @nErrorCode = @@ERROR
		End
	End
	
	-- CaseOfficeDescription
	Else if @sCurrentCategoryId = '@pnOfficeKey' and @nErrorCode = 0
	Begin
		If @sCurrentValue1 is null 
		Begin
			Insert into @tResultSet (CategoryID)
				values ('@pnOfficeKey')
			Set @nErrorCode = @@ERROR

		End
		Else 
		Begin
			Insert into @tResultSet (CategoryID, Value1Display)
				Select '@pnOfficeKey', [DESCRIPTION]
				from OFFICE 
				where OFFICEID = @sCurrentValue1
			Set @nErrorCode = @@ERROR
		End
	End	

	-- Division
	Else if @sCurrentCategoryId = '@pnAttributeKey2' and @nErrorCode = 0
	Begin
		Insert into @tResultSet (CategoryID, CategoryDisplay, Value1Display)
			Select '@pnAttributeKey2', TT.TABLENAME, TC.[DESCRIPTION]
			from TABLETYPE TT 
			left join TABLECODES TC on (TC.TABLECODE = @sCurrentValue1) and @sCurrentValue1 is not null
			where TT.TABLETYPE = -5
		Set @nErrorCode = @@ERROR
	End
	
	-- Product
	Else if @sCurrentCategoryId = '@pnAttributeKey3' and @nErrorCode = 0
	Begin
		Insert into @tResultSet (CategoryID, CategoryDisplay, Value1Display)
			Select '@pnAttributeKey3', TT.TABLENAME, TC.[DESCRIPTION]
			from TABLETYPE TT 
			left join TABLECODES TC on TC.TABLECODE = @sCurrentValue1 and @sCurrentValue1 is not null
			where TT.TABLETYPE = -6
		Set @nErrorCode = @@ERROR
	End
	
	-- PropertyTypeKey
	Else if @sCurrentCategoryId = '@psPropertyTypeKey' and @nErrorCode = 0
	Begin
		If @sCurrentValue1 is null
		Begin
			Insert into @tResultSet (CategoryID)
				values ('@psPropertyTypeKey')
			Set @nErrorCode = @@ERROR
		End
		Else
		Begin
			Insert into @tResultSet (CategoryID, Value1Display)
				Select '@psPropertyTypeKey', PROPERTYNAME
				from PROPERTYTYPE
				where PROPERTYTYPE = @sCurrentValue1
			Set @nErrorCode = @@ERROR
		End
	End
	
	-- CategoryKey
	Else if @sCurrentCategoryId = '@psCategoryKey' and @nErrorCode = 0
	Begin
		If @sCurrentValue1 is null
		Begin
			Insert into @tResultSet (CategoryID)
				values ('@psCategoryKey')
			Set @nErrorCode = @@ERROR
		End
		Else
		Begin
			Insert into @tResultSet (CategoryID, Value1Display)
				Select '@psCategoryKey', CASECATEGORYDESC
				from CASECATEGORY
				where CASECATEGORY = @sCurrentValue1
			Set @nErrorCode = @@ERROR
		End
	End

	-- Remarks	
	If @sCurrentCategoryId = '@psText1' and @nErrorCode = 0
	Begin
		Insert into @tResultSet (CategoryID, CategoryDisplay)
			Select '@psText1', TEXTDESCRIPTION
			from TEXTTYPE 
			where TEXTTYPE = 'R'
		Set @nErrorCode = @@ERROR
	End
	
	-- StatusKey
	Else if @sCurrentCategoryId = '@pnStatusKey' and @nErrorCode = 0
	Begin
		If @sCurrentValue1 is null
		Begin
			Insert into @tResultSet (CategoryID)
				values ('@pnStatusKey')
			Set @nErrorCode = @@ERROR
		End
		Else
		Begin
			Insert into @tResultSet (CategoryID, Value1Display)
				Select '@pnStatusKey', INTERNALDESC
				from STATUS
				where STATUSCODE = @sCurrentValue1
			Set @nErrorCode = @@ERROR
		End
	End
	
	-- Technology
	Else if @sCurrentCategoryId = '@pnAttributeKey1' and @nErrorCode = 0
	Begin
		Insert into @tResultSet (CategoryID, CategoryDisplay, Value1Display)
			Select '@pnAttributeKey1', TT.TABLENAME, TC.[DESCRIPTION]
			from TABLETYPE TT 
			left join TABLECODES TC on TC.TABLECODE = @sCurrentValue1 and @sCurrentValue1 is not null
			where TT.TABLETYPE = -498
		Set @nErrorCode = @@ERROR
	End
	
	-- IP Site
	Else if @sCurrentCategoryId = '@pnAttributeKey4' and @nErrorCode = 0
	Begin
		Insert into @tResultSet (CategoryID, CategoryDisplay, Value1Display)
			Select '@pnAttributeKey4', TT.TABLENAME, TC.[DESCRIPTION]
			from TABLETYPE TT 
			left join TABLECODES TC on TC.TABLECODE = @sCurrentValue1 and @sCurrentValue1 is not null
			where TT.TABLETYPE = -3
		Set @nErrorCode = @@ERROR
	End

	-- Business Unit
	Else if @sCurrentCategoryId = '@pnAttributeKey5' and @nErrorCode = 0
	Begin
		Insert into @tResultSet (CategoryID, CategoryDisplay, Value1Display)
			Select '@pnAttributeKey5', TT.TABLENAME, TC.[DESCRIPTION]
			from TABLETYPE TT 
			left join TABLECODES TC on TC.TABLECODE = @sCurrentValue1 and @sCurrentValue1 is not null
			where TT.TABLETYPE = -4
		Set @nErrorCode = @@ERROR
	End

	-- Text
	Else if @sCurrentCategoryId = '@psText1' and @nErrorCode = 0
	Begin
		Insert into @tResultSet (CategoryID, CategoryDisplay)
			Select left(@sCurrentCategoryId,5), TEXTDESCRIPTION 
			from TEXTTYPE 
			where TEXTTYPE = 'T' + SUBSTRING(@sCurrentCategoryId, 5, 1)
		Set @nErrorCode = @@ERROR
	End

	-- EventKey / DeadlineEventKey
	-- Rolled up 2 almost identical queries
	Else if @nErrorCode = 0 
		and (@sCurrentCategoryId = '@pnEventKey' 
		or @sCurrentCategoryId = '@pnDeadlineEventKey')
	Begin
		Insert into @tResultSet (CategoryID, CategoryDisplay)
			Select @sCurrentCategoryId, 
			EVENTDESCRIPTION
			from EVENTS
			where EVENTNO = @sCurrentCategory
		Set @nErrorCode = @@ERROR
	End
	
	-- NameTypeKey / NameKey
	-- This one is used by both Basic and Advance searches
	Else if @nErrorCode = 0 
		and (@sCurrentCategoryId = '@psNameTypeKey' 
		or @sCurrentCategoryId = '@psNameKeys')
	Begin
		If @pbBasicSearch = 1
		Begin
			If @sCurrentCategoryId = '@psNameTypeKey' 
			Begin
				If @sCurrentValue1 is null 
				Begin
					Insert into @tResultSet (CategoryID)
						values ('@psNameTypeKey')
					Set @nErrorCode = @@ERROR
				End 
				Else 
				Begin
					Insert into @tResultSet (CategoryID, Value1Display)
						Select '@psNameTypeKey', [DESCRIPTION]
						from NAMETYPE 
							where NAMETYPE = @sCurrentValue1
					Set @nErrorCode = @@ERROR
				End
			End			
			If @sCurrentCategoryId = '@psNameKeys' 
			Begin
				If @sCurrentValue1 is null
				Begin
					Insert into @tResultSet (CategoryID)
						values ('@psNameKeys')
					Set @nErrorCode = @@ERROR
				End
				Else
				Begin
					Insert into @tResultSet (CategoryID, Value1Display)
						Select '@psNameKeys', dbo.fn_FormatNameUsingNameNo(@sCurrentValue1, null)
					Set @nErrorCode = @@ERROR
				End
			End
		End
		Else
		Begin
			If @sCurrentValue1 is null or @sCurrentValue1 = ''
			Begin
				Insert into @tResultSet (CategoryID, CategoryDisplay)
					Select '@psNameTypeKey', NT.[DESCRIPTION]
					from NAMETYPE NT
					where NT.NAMETYPE= @sCurrentCategory
				Set @nErrorCode = @@ERROR
			End
			Else
			Begin
				Insert into @tResultSet (CategoryID, CategoryDisplay, Value1Display)
					Select '@psNameTypeKey', NT.[DESCRIPTION], 
						dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					from NAMETYPE NT
					join [NAME] N on N.NAMENO = @sCurrentValue1
					where NT.NAMETYPE= @sCurrentCategory
				Set @nErrorCode = @@ERROR
			End
		End
	End
	
	-- CaseTypeKey
	-- This one is only used by Basic Search
	Else if @sCurrentCategoryId = '@psCaseTypeKey' and @nErrorCode = 0 
	Begin
		If @sCurrentValue1 is null
		Begin
			Insert into @tResultSet (CategoryID)
				values ('@psCaseTypeKey')
			Set @nErrorCode = @@ERROR
		End
		Else
		Begin
			Insert into @tResultSet (CategoryID, Value1Display)
				Select '@psCaseTypeKey', CASETYPEDESC
				from CASETYPE
				where CASETYPE = @sCurrentValue1
			Set @nErrorCode = @@ERROR
		End
	End
	Set @nCurrentPos = @nCurrentPos + 1
End -- While

If @nErrorCode = 0
Begin
	-- Kick back the results
	Select * from @tResultSet
End

Return @nErrorCode
GO

Grant execute on dbo.ip_GetSearchDescriptions to public
GO
