-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.cs_GetInvalidXMLChar
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GetInvalidXMLChar]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GetInvalidXMLChar.'
	Drop procedure [dbo].[cs_GetInvalidXMLChar]
	Print '**** Creating Stored Procedure dbo.cs_GetInvalidXMLChar...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_GetInvalidXMLChar
(
	@psNvarcharField	nvarchar(max),
	@pbCalledFromCentura	bit		= 0,
	@psInvalidXMLChar	nvarchar(max)	= null	output
)
AS
-- PROCEDURE:	cs_GetInvalidXMLChar
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global
-- DESCRIPTION:	Returns a list of invalid XML characters from a given string
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
Declare	@nUnicode int
Declare	@nIndex int

set @psInvalidXMLChar = ''
Set @x = rtrim(@psNvarcharField)
set @nIndex = 0

While len(@x) > 0 
begin
	set @nUnicode= unicode(substring(@x,1,1))
	set @nIndex = @nIndex + 1

	-- Collect all invalid XML char and its position to return to the caller function
	if	NOT( (@nUnicode = 0x9) or (@nUnicode = 0xA) or (@nUnicode = 0xD) or 
			 ((@nUnicode >= 0x20) and (@nUnicode <= 0xD7FF)) or
			 ((@nUnicode >= 0xE000) and (@nUnicode <= 0xFFFD)) or
			 ((@nUnicode >= 0x10000) and (@nUnicode <= 0x10FFFF)) 
		)
		set @psInvalidXMLChar = @psInvalidXMLChar + 'Invalid XML char [' + substring(@x,1,1) + '] found at position: ' + CAST(@nIndex as varchar(10)) + CHAR(13) + CHAR(10)
	set @x = substring(@x,2,LEN(@x))
end


if @pbCalledFromCentura = 1
	select @psInvalidXMLChar 

return 0
GO

Grant execute on dbo.cs_GetInvalidXMLChar to public
GO
