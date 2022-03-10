-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_StringListDedupeAndSort
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_StringListDedupeAndSort') and xtype='FN')
begin
	print '**** Drop function dbo.fn_StringListDedupeAndSort.'
	drop function dbo.fn_StringListDedupeAndSort
	print '**** Creating function dbo.fn_StringListDedupeAndSort...'
	print ''
end
go


SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_StringListDedupeAndSort
	(
		@psInStringList		nvarchar(max),
		@psDelimiter		nvarchar(10)
	)
Returns nvarchar(max)

-- FUNCTION :	fn_StringListDedupeAndSort
-- VERSION :	4
-- DESCRIPTION:	This function accepts a delimited string and returns the 
--		sorted string with any duplicates removed.

-- MODIFICTIONS :
-- Date         Who	Version	Change	Description
-- ------------ ----	-------	------	-------------------------------------
-- 16 Jul 2002	JB			Function created (from MF code)
-- 17 Jul 2002	MF			Fix to correctly sort numeric values
-- 14 Apr 2011	MF	4	10475	Change nvarchar(4000) to nvarchar(max)

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
			Select @sListItem=min(T.Parameter)
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

grant execute on dbo.fn_StringListDedupeAndSort to public
GO
