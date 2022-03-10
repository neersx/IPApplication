-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.cs_RemoveInvalidXMLChar
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_RemoveInvalidXMLChar]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_RemoveInvalidXMLChar.'
	Drop procedure [dbo].[cs_RemoveInvalidXMLChar]
	Print '**** Creating Stored Procedure dbo.cs_RemoveInvalidXMLChar...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_RemoveInvalidXMLChar
(
	@psNvarcharField	nvarchar(max),
	@pbCalledFromCentura	bit		= 0,
	@psValidText		nvarchar(max)	= null output
)
AS
-- PROCEDURE:	cs_RemoveInvalidXMLChar
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global
-- DESCRIPTION:	Remove invalid XML characters from a given string
--				VALID XML is defined as 
--				http://www.w3.org/TR/2000/REC-xml-20001006#NT-Char
--				Unicode code points in the following ranges are valid in XML
--				#x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF] 
--
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 13 Feb 2014  DL	21907	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @x nvarchar(max)
Declare @NewX nvarchar(max)
Declare @sChar nchar
Declare	@nUnicode int

set @psValidText = ''
Set @x = rtrim(@psNvarcharField)

While len(@x) > 0 
begin
	set @sChar = substring(@x,1,1)
	set @nUnicode= unicode( @sChar)

	-- Skip invalid XML character to remove them from the string
	if (@nUnicode = 0x9) or (@nUnicode = 0xA) or (@nUnicode = 0xD) or 
			 ((@nUnicode >= 0x20) and (@nUnicode <= 0xD7FF)) or
			 ((@nUnicode >= 0xE000) and (@nUnicode <= 0xFFFD)) or
			 ((@nUnicode >= 0x10000) and (@nUnicode <= 0x10FFFF)) 		
		set @psValidText = @psValidText + @sChar
		
	set @x = substring(@x,2,LEN(@x))
end


if @pbCalledFromCentura = 1
	select @psValidText 

return 0
GO

Grant execute on dbo.cs_RemoveInvalidXMLChar to public
GO
