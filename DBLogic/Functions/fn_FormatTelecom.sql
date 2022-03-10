-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FormatTelecom
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_FormatTelecom]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop function dbo.fn_FormatTelecom.'
	drop function [dbo].[fn_FormatTelecom]
	print '**** Creating function dbo.fn_FormatTelecom...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create Function dbo.fn_FormatTelecom
			(
			@pnTelecomType		int,
			@psISD 			nvarchar(5),
			@psAreaCode		nvarchar(5),
			@psTelecomNumber	nvarchar(100),
			@psExtension		nvarchar(5)
			)
Returns nvarchar(400)

-- FUNCTION :	fn_FormatTelecom
-- VERSION :	5
-- DESCRIPTION:	This function accepts the components of a Telecommunication device and returns
--		it as a formatted text string. 
--		@pnTelecomType is not current used but has been included for possible future use.

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 11/09/2002	MF			Function created
-- 30 JUL 2008	MF	16761	4	Handle when components of Telecom are null.
-- 06 OCT 2009	NG	RFC100017	5	Increased the max length of @psTelecomNumber from 50 to 100.

as
Begin
	declare @sFormattedTelecom	nvarchar(400)

	Select @sFormattedTelecom=CASE WHEN(@psISD       is not null) THEN '+'+replace(@psISD,'+','')+' ' ELSE '' END
				+ CASE WHEN(@psAreaCode  is not null) THEN @psAreaCode+' ' ELSE '' END
				+ isnull(@psTelecomNumber,'')
				+ CASE WHEN(@psExtension is not null) THEN ' x'+@psExtension ELSE '' END
	
	Return ltrim(rtrim(@sFormattedTelecom))
End
go

grant execute on dbo.fn_FormatTelecom to public
GO
