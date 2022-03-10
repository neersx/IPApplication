-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCorrelationSuffix
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetCorrelationSuffix') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetCorrelationSuffix'
	Drop function [dbo].[fn_GetCorrelationSuffix]
End
Print '**** Creating Function dbo.fn_GetCorrelationSuffix...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetCorrelationSuffix
(
	@psQualifier nvarchar(20)
) 
RETURNS nvarchar(50)
AS
-- Function :	fn_GetCorrelationSuffix
-- VERSION :	3
-- DESCRIPTION:	Produces the correlation suffix based on the supplied @psQualifier parameter. 
--		This function will also replace any non-alphanumeric characters within @psQualifier
--		with their corresponding unicode values.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Apr 2004	TM	RFC1246	1	Function created
-- 19 Apr 2004	TM	RFC1246	2	Convert "-" to "_" instead of unicode.
-- 19 Apr 2004	TM	RFC1246	3	Leave any existing "_" unconverted to unicode. Convert " " 
--					to "_" instead of unicode.

Begin
	
	-- Declare variables
	Declare @sCorrelationSuffix nvarchar(50)
	Declare @nCharacter int
	Declare @nStringLength int 

	-- Initialise variables	
	
	Set @sCorrelationSuffix = ''
	Set @nCharacter = 1
	set @nStringLength = len(@psQualifier)		
		
	-- Convert the @psQualifier to a string made up of the concatenation of
	-- each individual character converted to UNICODE
	While @nCharacter <= @nStringLength
	Begin		
		Set @sCorrelationSuffix = @sCorrelationSuffix + 
					  -- Convert '-' and ' ' to '_'. Leave '_' as '_'. 					  	      
					  CASE WHEN    substring(@psQualifier, @nCharacter, 1) in ('-', ' ', '_')
					       THEN    '_'	
						      -- Check if the character is numeric
					       WHEN ( (UNICODE(substring(@psQualifier, @nCharacter, 1 )) not between 48 and 57) and
						      -- Check if the character is the capital letter between from 'A' to 'Z'
						      (UNICODE(substring(@psQualifier, @nCharacter, 1 )) not between 65 and 90) and
						      -- Check if the character is the small letter between from 'a' to 'z'
						      (UNICODE(substring(@psQualifier, @nCharacter, 1 )) not between 97 and 122) ) 
					       -- If none of the above is true, convert the character to the 
					       -- corresponding unicode value.
					       THEN convert(varchar,UNICODE(substring(@psQualifier, @nCharacter, 1 ))) 
					       -- If any of the above is true, concatenate the actual character to
					       -- the Correlation suffix without converting it to the unicode.
					       ELSE substring(@psQualifier, @nCharacter, 1 )
					  END

		-- Increment the @nCharacter by 1 so it points 
		-- to the next character in the Qualifier.		
		Set @nCharacter = @nCharacter + 1
	End
	
	-- Concatenate '_' at the end of the correlation suffix so the various joins distinguished 
	-- (e.g. the join for Alias 'A' will be created even though this search is matching on the join 
	-- already present for 'AA').
	Set @sCorrelationSuffix='_'+@sCorrelationSuffix+'_'
		
	Return @sCorrelationSuffix
End
GO

Grant execute on dbo.fn_GetCorrelationSuffix to public
GO
