-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetTranslationAddressStyle
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetTranslationAddressStyle') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetTranslationAddressStyle'
	Drop function [dbo].[fn_GetTranslationAddressStyle]
End
Print '**** Creating Function dbo.fn_GetTranslationAddressStyle...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetTranslationAddressStyle
(
	@psCulture nvarchar(10)	
) 
RETURNS int
AS
-- Function :	fn_GetTranslationAddressStyle
-- VERSION :	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This function returnes an 'Address Style' sitecontrol value
--		for the supplied culture.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 09 2004	TM	RFC1806	1	Function created
-- 15 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

Begin
	Declare @pnAddressStyle int
	
	Select @pnAddressStyle = COLINTEGER
	from SITECONTROL 	
	where CONTROLID = 'Address Style '+@psCulture
		
	return @pnAddressStyle
End
GO

grant execute on dbo.fn_GetTranslationAddressStyle to public
go
