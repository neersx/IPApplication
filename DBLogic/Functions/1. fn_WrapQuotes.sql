-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_WrapQuotes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_WrapQuotes') and xtype='FN')
begin
	print '**** Drop function dbo.fn_WrapQuotes.'
	drop function dbo.fn_WrapQuotes
end
print '**** Creating function dbo.fn_WrapQuotes...'
print ''
go

set QUOTED_IDENTIFIER off
go
set CONCAT_NULL_YIELDS_NULL off
go


Create Function dbo.fn_WrapQuotes
			(
			@psInputString		nvarchar(max),
			@pbIsCommaDelimited	bit,	-- Set to 1 if list is comma separated
			@pbCenturaRunsSql 	bit	= 0
			)
Returns nvarchar(max)

-- FUNCTION :	fn_WrapQuotes
-- VERSION :	8
-- DESCRIPTION:	This function accepts a string of comma separated values and if no quotes
--		are wrapping the values will add quotes and remove any embedded spaces.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 17 JUN 2002	MF			Function created
-- 05 SEP 2002	MF			Spaces are being incorrectly removed.  Change the approach from using
--					the REPLACE function to tokenising with the comma separator and then
--					reconstruct the list
-- 06 NOV 2003	MF	RFC586	5	Cater for embedded quotes and double byte variables
-- 03 May 2004	JEK	RFC1376	6	Centura code produces syntax errors for SQL with embedded double byte
--					strings.  Remove the 'N' prefix temporarily; i.e. only cater for single byte.
-- 03 Sep 2004	TM	RFC1377	7	Add new @pbCenturaRunsSql parameter and attach 'N' prefix to the output string 
--					where applicable.
-- 14 Apr 2011	MF	RFC10475 8	Change nvarchar(4000) to nvarchar(max)

as
Begin
	declare @psOutputString	nvarchar(max)
	declare @sComma		nchar(1)	-- leave as Null to start with
	declare @sNPrefix	nchar(1)	

	If @pbCenturaRunsSql = 0
	Begin
		Set @sNPrefix = 'N'
	End

	-- Any occurrence of a single Quote is to be replace with two single Quotes
	Set @psInputString=Replace(@psInputString, char(39), char(39)+char(39) )

	-- If the input string is flagged as being a comma separated list then return it
	-- each item surrounded by quotes but still comma separated.
	If @pbIsCommaDelimited=1
	Begin
		Select @psOutputString=ISNULL(NULLIF(@psOutputString + ',', ','),'')  +@sNPrefix+char(39)+Parameter+char(39)
		from dbo.fn_Tokenise(@psInputString, ',')
	End
	Else If @psInputString is not null
	Begin
		-- Cater for double byte variables by prefixing with N
		Set @psOutputString=@sNPrefix+char(39)+@psInputString+char(39)
	End

	Return @psOutputString
End
go

grant execute on dbo.fn_WrapQuotes to public
GO
