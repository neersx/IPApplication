-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ConvertToInputItemString
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ConvertToInputItemString') and xtype='FN')
begin
	print '**** Drop function dbo.fn_ConvertToInputItemString.'
	drop function dbo.fn_ConvertToInputItemString
end
print '**** Creating function dbo.fn_ConvertToInputItemString...'
print ''
go

CREATE FUNCTION dbo.fn_ConvertToInputItemString 
	(
		@psDirtyString	nvarchar(max)
	)
Returns nvarchar(max)
as 

-- FUNCTION :	fn_ConvertToInputItemString
-- VERSION :	2
-- DESCRIPTION:	This function accepts a string of mixed characters and returns only those
--		characters that are valid as input items for for Centura Reports
--		Thats is a..z, A..Z, 0..9 and the underscore (_).  
--		Note: Also converts spaces to underscores.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22/03/2004	JB	9279		Function created
-- 14 Apr 2011	MF	10475	2	Change nvarchar(4000) to nvarchar(max)

Begin

	Declare @nCharPos int
	Set @nCharPos = 1
	
	Declare @sCleanString nvarchar(max)
	Set @sCleanString = ''
	
	Declare @cCurrentChar char(1)
	
	While @nCharPos <= len(@psDirtyString)
	Begin
		Set @cCurrentChar = SUBSTRING(@psDirtyString, @nCharPos, 1)
	
		if @cCurrentChar = ' ' or @cCurrentChar = '_'
			Set @sCleanString = @sCleanString + '_'
		else if ASCII(@cCurrentChar) BETWEEN 97 and 122  -- a-z
			Set @sCleanString = @sCleanString + @cCurrentChar
		else if ASCII(@cCurrentChar) BETWEEN 65 and 90   -- A-Z
			Set @sCleanString = @sCleanString + @cCurrentChar
		else if ASCII(@cCurrentChar) BETWEEN 48 and 57   -- 0-9
			Set @sCleanString = @sCleanString + @cCurrentChar

		Set @nCharPos = @nCharPos + 1
	End

	Return @sCleanString

End
go

grant execute on dbo.fn_ConvertToInputItemString to public
GO
