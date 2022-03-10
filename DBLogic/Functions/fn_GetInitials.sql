-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetInitials
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetInitials') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetInitials'
	Drop function [dbo].[fn_GetInitials]
End
Print '**** Creating Function dbo.fn_GetInitials...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetInitials
(
	@psText	nvarchar(254)
) 
RETURNS nvarchar(10)
AS
-- Function :	fn_GetInitials
-- VERSION :	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the first character of each word in the supplied text where
--		the first character is in upper case.
--		'ABC, BBc, ccc' will return 'AB'

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Apr 2006	SW	RFC3503	1	Function created
-- 31 May 2006	SW	RFC3880	2	Separate initials by spaces; e.g. "A B C".
-- 26 Oct 2015	vql	R53909	3	Do not return empty strings (DR-15542).


Begin
	Declare @sResult nvarchar(10)
	set @sResult = N''
	
	set @psText = ltrim(@psText)
	
	Select @sResult = @sResult+left(Parameter,1)+' '
	from dbo.fn_Tokenise(@psText, ' ')
	where binary_checksum(upper(left(Parameter,1))) = binary_checksum(left(Parameter,1))
	
	return rtrim(nullif(@sResult, ''))
End
GO

grant execute on dbo.fn_GetInitials to public
go
