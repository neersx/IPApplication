-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_IsInvalidForXML
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_IsInvalidForXML') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_IsInvalidForXML'
	Drop function [dbo].[fn_IsInvalidForXML]
End
Print '**** Creating Function dbo.fn_IsInvalidForXML...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_IsInvalidForXML
(
	@psNvarcharField	nvarchar(max)
) 
RETURNS int
AS
-- Function :	fn_IsInvalidForXML
-- VERSION :	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return index of bad characters if found; 0 otherwise.
--				INVALID XML is defined as 
--				http://www.w3.org/TR/2004/REC-xml11-20040204/#NT-Char
--				[2a]    RestrictedChar    ::=   [#x1-#x8] | [#xB-#xC] |
--												[#xE-#x1F] | [#x7F-#x84] | [#x86-#x9F] 
--
--				VALID XML is defined as 
--				http://www.w3.org/TR/2000/REC-xml-20001006#NT-Char
--				Character Range
--				[2]    Char    ::=    #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF] 
--
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	------	------	-------	----------------------------------------------- 
-- 03 APR 2008	SF	RFC6276	1	Function created
-- 11 Sep 2008  DL	RFC7041	2	Change logic to use VALID XML character ranges instead of INVALID character ranges.
-- 14 Apr 2011	MF	RFC10475 3	Change nvarchar(4000) to nvarchar(max)
-- 14 Feb 2014  DL	21907	4	Use unicode instead of ascii function to handle double byte characters


Begin
	Declare @x nvarchar(max)
	Declare	@nUnicodeY int
	Declare	@nIndex int

	Set @x = rtrim(@psNvarcharField)
	set @nIndex = 0

	
--	While len(@x) > 0 
--	and not(
--		(substring(@x, 1, 1) between cast(0x1 as nvarchar(1)) and cast(0x8 as nvarchar(1))) OR
--		(substring(@x, 1, 1) between cast(0xB as nvarchar(1)) and cast(0xC as nvarchar(1)))	OR
--		(substring(@x, 1, 1) between cast(0xE as nvarchar(1)) and cast(0x1F as nvarchar(1))) OR
--		(substring(@x, 1, 1) between cast(0x7F as nvarchar(1)) and cast(0x84 as nvarchar(1))) OR
--		(substring(@x, 1, 1) between cast(0x86 as nvarchar(1)) and cast(0x9F as nvarchar(1))))
--	begin
--		set @x = substring(@x,2,LEN(@x))
--	end
--	
--	If len(@x) > 0
--		Set @nReturn = len(@psNvarcharField) - len(@x)
--	Return @nReturn

	While len(@x) > 0 
	begin
		set @nUnicodeY= unicode(substring(@x,1,1))
		set @nIndex = @nIndex + 1

		-- if char not in VALID XML characters set then report the first invalid character position in the string.
		if	NOT( (@nUnicodeY = 0x9) or (@nUnicodeY = 0xA) or (@nUnicodeY = 0xD) or 
				 ((@nUnicodeY >= 0x20) and (@nUnicodeY <= 0xD7FF)) or
				 ((@nUnicodeY >= 0xE000) and (@nUnicodeY <= 0xFFFD)) or
				 ((@nUnicodeY >= 0x10000) and (@nUnicodeY <= 0x10FFFF)) 
			)
			return @nIndex
		set @x = substring(@x,2,LEN(@x))
	end
	return 0

End
GO

grant execute on dbo.fn_IsInvalidForXML to public
go
