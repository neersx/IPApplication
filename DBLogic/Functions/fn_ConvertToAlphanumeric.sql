-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ConvertToAlphanumeric 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ConvertToAlphanumeric ') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_ConvertToAlphanumeric'
	Drop function [dbo].[fn_ConvertToAlphanumeric ]
End
Print '**** Creating Function dbo.fn_ConvertToAlphanumeric ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_ConvertToAlphanumeric 
(
	@psString nvarchar(max)
) 
RETURNS nvarchar(max)
AS
-- Function :	fn_ConvertToAlphanumeric 
-- VERSION :	2
-- DESCRIPTION:	Replaces any non alphanumeric characters in the supplied @psString parameter
--		with their corresponding unicode values. 
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Jul 2004	TM	RFC1230	1	Function created
-- 14 Apr 2011	MF	RFC10475 2	Change nvarchar(4000) to nvarchar(max)

Begin
	
	-- Declare variables
	Declare @sOutputString nvarchar(max)
	Declare @nCharacter int
	Declare @nStringLength int 

	-- Initialise variables	
	
	Set @sOutputString = ''
	Set @nCharacter = 1
	set @nStringLength = len(@psString)		
		
	-- Convert the @psString to a string made up of the concatenation of
	-- each individual character converted to UNICODE
	While @nCharacter <= @nStringLength
	Begin		
		Set @sOutputString = @sOutputString + 					   
					       	      -- Check if the character is numeric
					  CASE WHEN ( (UNICODE(substring(@psString, @nCharacter, 1 )) not between 48 and 57) and
						      -- Check if the character is the capital letter between from 'A' to 'Z'
						      (UNICODE(substring(@psString, @nCharacter, 1 )) not between 65 and 90) and
						      -- Check if the character is the small letter between from 'a' to 'z'
						      (UNICODE(substring(@psString, @nCharacter, 1 )) not between 97 and 122) ) 
					       -- If none of the above is true, convert the character to the 
					       -- corresponding unicode value.
					       THEN convert(varchar,UNICODE(substring(@psString, @nCharacter, 1 ))) 
					       -- If any of the above is true, concatenate the actual character to
					       -- the supplied string without converting it to the unicode.
					       ELSE substring(@psString, @nCharacter, 1 )
					  END

		-- Increment the @nCharacter by 1 so it points 
		-- to the next character in the Qualifier.		
		Set @nCharacter = @nCharacter + 1
	End
	
	Return @sOutputString
End
GO

Grant execute on dbo.fn_ConvertToAlphanumeric  to public
GO
