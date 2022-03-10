-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ListToXML
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ListToXML') and xtype='FN')
begin
	print '**** Drop function dbo.fn_ListToXML.'
	drop function dbo.fn_ListToXML
end
Print '**** Creating function dbo.fn_ListToXML...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET CONCAT_NULL_YIELDS_NULL OFF
GO

CREATE FUNCTION dbo.fn_ListToXML
(
	@psAttribute	nvarchar(254) = NULL,
	@psDelimitedList nvarchar(3000),
	@psDelimiter	 nvarchar(5),
	@pbSingleQuoted  bit
)
RETURNS nvarchar(max)
AS
-- FUNCTION:	fn_ListToXML
-- VERSION :	3
-- SCOPE:	Inproma
-- DESCRIPTION:	Receive a delimited list and convert it into XML.
--
-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ---------	---	-------	-------	----------------------------------------------- 
-- 08/01/2004		SFOO	1	Created
-- 06/08/2004		CR	2	Changed so the xml attribute used may be 
--					configured. The default will be 'Value'
-- 14 Apr 2011	MF	RFC10475 3	Change nvarchar(4000) to nvarchar(max)
Begin
	Declare @sXML  nvarchar(max)
	
	If @psAttribute IS NULL
	Begin
		Set @psAttribute = 'Value'
	End

	/* If the list elements are quoted with single quote
	   i.e. '1','2','3', then remove the single quote */
	If @pbSingleQuoted = 1
	Begin
		Set @psDelimitedList = REPLACE( @psDelimitedList, '''', '' )	
	End

	Set @sXML = '<ROOT><Worktable ' + @psAttribute + '="' +
			REPLACE(@psDelimitedList, @psDelimiter,	'"/><Worktable '+ @psAttribute+ '="') +
		    '"/></ROOT>'
	Return @sXML
End
GO

grant execute on dbo.fn_ListToXML to public
GO