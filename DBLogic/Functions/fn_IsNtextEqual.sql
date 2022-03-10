-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_IsNtextEqual
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_IsNtextEqual') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_IsNtextEqual'
	Drop function [dbo].[fn_IsNtextEqual]
End
Print '**** Creating Function dbo.fn_IsNtextEqual...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_IsNtextEqual
(
	@ptText1 ntext,
  	@ptText2 ntext
) 
RETURNS bit
AS
-- Function :	fn_IsNtextEqual
-- VERSION :	3
-- DESCRIPTION:	Returns 1 if the @ptText1 equals to @ptText2 and 0 otherwise.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Apr 2004	TM	RFC917	1	Function created
-- 15 Apr 2004 	TM	RFC917	2	If both @ptText1 and @ptText2 parameters are null return 1.
-- 07 Oct 2009	SF	RFC8493	3	The like operator fails if either texts contains escaped characters

Begin
	Declare @bEqual 	bit	-- Set to 1 if the @ptText1 equals to @ptText2 and 0 otherwise. 
	Declare @nStartAt 	int	-- Start position of the 4000 characters substrings to be compared.

	Set @bEqual 		= 0
	Set @nStartAt 		= 0
	
	-- If the datalengths of the strings are different return false. 
	If datalength(@ptText1) <> datalength(@ptText2)
	Begin
		Set @bEqual = 0 
	End	
	Else Begin
		-- If both strings are shorter or equal to that 4000 characters (datalength <= 8000) 
		-- then compare them as normal strings (using 'like').
		If datalength(@ptText1) = datalength(@ptText2) 
		and datalength(@ptText1) <=8000
		and cast(@ptText1 as nvarchar(4000)) = cast(@ptText2 as nvarchar(4000))			
		-- and @ptText1 like @ptText2
		-- If both @ptText1 and @ptText2 parameters are null return then return 1.
		or (@ptText1 is null and @ptText2 is null)
		Begin
			Set @bEqual = 1
		End
		Else Begin
			-- Compare the 4000 characters long substrings of two long strings starting from 0 position
			-- and return false if they are different otherwise keep comparing substrings up to the end
			-- of the strings.  
			While datalength(@ptText1) >= @nStartAt + 4000 
			and @bEqual = 0 
			Begin
				If substring(@ptText1,@nStartAt,4000) <> substring(@ptText2,@nStartAt,4000)
				Begin
					Set @bEqual = 0
				End
				Else Begin
					Set @bEqual = 1
				End	
		
				-- Set the starting position of the substring to point to the 
				-- next 4000 characters to be compared.
				Set @nStartAt = @nStartAt + 4000	      
			End
		End
	End  
	
	Return @bEqual
End
GO

Grant execute on dbo.fn_IsNtextEqual to public
GO
