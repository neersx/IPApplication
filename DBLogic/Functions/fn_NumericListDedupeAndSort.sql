-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_NumericListDedupeAndSort
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_NumericListDedupeAndSort') and xtype='FN')
begin
	print '**** Drop function dbo.fn_NumericListDedupeAndSort.'
	drop function dbo.fn_NumericListDedupeAndSort
	print '**** Creating function dbo.fn_NumericListDedupeAndSort...'
	print ''
end
go


SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_NumericListDedupeAndSort
	(
		@psInStringList		nvarchar(max),
		@psDelimiter		nvarchar(10)
	)
Returns nvarchar(max)

-- FUNCTION :	fn_NumericListDedupeAndSort
-- VERSION :	2
-- DESCRIPTION:	This function accepts a delimited string and returns the 
--		sorted list as a string in numeric format with any duplicates removed.
--		This allows two lists to be compared on numeric values (e.g. with
--		leading zeroes removed).
--		Based on fn_StringListDedupeAndSort
--		The main difference is numeric tokens are returned with numeric value
--		cast to a string.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Aug 2006	JEK	RFC4024	1	Function created based on fn_StringListDedupeAndSort
-- 14 Apr 2011	MF	RFC10475 2	Change nvarchar(4000) to nvarchar(max)

AS
Begin
	-- Get the Item with the lowest value from the delimited string
	Declare @sOutStringList	nvarchar(max)
	Declare @sListItem	nvarchar(max)
	Declare @nNumericItem	decimal(38,10)

	-- If the tokenised values are numeric they will be sorted as such 
	-- otherwise they will be sorted as alpha-numeric

	Select @nNumericItem=min(NumericParameter)
	From dbo.fn_Tokenise(@psInStringList, @psDelimiter)

	If @nNumericItem is null
		Select @sListItem=min(Parameter)
		From dbo.fn_Tokenise(@psInStringList, @psDelimiter)

	-- Now tokenise the sorted delimited string and reconstruct a delimited string 
	-- to return without duplicates

	While @sListItem    is not null
	OR    @nNumericItem is not null
	Begin
		If @nNumericItem is not null
			Select @sListItem=min(cast(T.NumericParameter as nvarchar(50)))
			From dbo.fn_Tokenise(@psInStringList, @psDelimiter) T
			where T.NumericParameter=@nNumericItem

		If @sOutStringList is null
			Set @sOutStringList=@sListItem
		Else
			Set @sOutStringList=@sOutStringList+isnull(@psDelimiter,',')+@sListItem

		-- Now get the next highest Item from the list.
		-- This has the added benefit of removing duplicates.
		If @nNumericItem is null
		begin
			Select @sListItem=min(Parameter)
			From dbo.fn_Tokenise(@psInStringList, @psDelimiter)
			Where Parameter>@sListItem
		end
		Else begin
			Select @nNumericItem=min(NumericParameter)
			From dbo.fn_Tokenise(@psInStringList, @psDelimiter)
			Where NumericParameter>@nNumericItem

			If @nNumericItem is null
				set @sListItem=null
		end
	End

Return @sOutStringList
End
go

grant execute on dbo.fn_NumericListDedupeAndSort to public
GO
