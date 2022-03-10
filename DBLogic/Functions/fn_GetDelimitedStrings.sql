-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetDelimitedStrings
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_GetDelimitedStrings]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop Function dbo.fn_GetDelimitedStrings.'
	drop function [dbo].[fn_GetDelimitedStrings]
	print '**** Creating Function dbo.fn_GetDelimitedStrings...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetDelimitedStrings  
	(	
		@psSearchString		nvarchar(max), 
		@psDelimiter		nchar(1)
	)

RETURNS  @tbDelimitedString  TABLE 
	(
		CharacterString		nvarchar(max)	collate database_default not null
	)
-- FUNCTION :	fn_GetDelimitedStrings
-- VERSION :	3
-- DESCRIPTION:	Returns all strings of characters that are delimited before
--		and after by a specific single character.
--
--		Example:
--		@psSearchString='The reminder is due on ~DD101~ and the governing event occurred on ~EV-202~ and some more text '
--		@psDelimiter  = ~
--		Result returned will be :
--			DD101
--			EV-202
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 98 Jan 2010	MF	18145	1	Function created
-- 27 Jan 2010	DL	18145	2	Added collate database_default to the return table to allow database's collation to be alterred.
-- 18 Oct 2016	MF	69608	3	Change variables from nvarchar(4000) to nvarchar(max).

begin
	declare	@nPtr				smallint, 
		@nEndString			smallint, 
		@nStartOfCharacterString	smallint
		
	Set @nPtr         = 1
	Set @nStartOfCharacterString = 1
	Set @nEndString   = len(@psSearchString) + 1

	while @nEndString > @nPtr
	begin
		-----------------------------
		-- Find the opening delimiter
		-----------------------------
		Set @nPtr=charindex(@psDelimiter, @psSearchString,@nPtr)
		
		If @nPtr=0
		Begin
			Set @nPtr=@nEndString
		End
		Else Begin
			Set @nStartOfCharacterString=@nPtr+1
					
			-----------------------------
			-- Find the closing delimiter
			-----------------------------
			Set @nPtr=charindex(@psDelimiter, @psSearchString,@nStartOfCharacterString)
			
			If @nPtr=0
			Begin	
				Set @nPtr=@nEndString
			End
			Else Begin
				insert into @tbDelimitedString(CharacterString)
				select substring(@psSearchString, @nStartOfCharacterString, @nPtr-@nStartOfCharacterString) 
				
				set @nPtr=@nPtr+1
			End
		End
			
	end 
	return 
end
go

grant REFERENCES, SELECT on dbo.fn_GetDelimitedStrings to public
GO