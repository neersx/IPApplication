-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetMainTelecom
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetMainTelecom') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetMainTelecom'
	Drop function [dbo].[fn_GetMainTelecom]
End
Print '**** Creating Function dbo.fn_GetMainTelecom...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetMainTelecom
(
	@pnNameKey		int,
	@pnTelecomType	int
) 
RETURNS nvarchar(400)
AS
-- Function :	fn_GetMainTelecom
-- VERSION :	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns formatted telecom number based on details entered.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Feb 2009	NG	RFC4026		1	Function created
-- 31 Oct 2018	vql	DR-45102	2	remove control characters from functions.

Begin	
	declare @sFormattedTelecom nvarchar(400)
	set @sFormattedTelecom = null
	If (@pnTelecomType = 1901 or @pnTelecomType = 1902 or @pnTelecomType = 1903 or 
			exists(select * 
				from NAMETELECOM NT
				left join SITECONTROL SC on (CONTROLID = 'Telecom Type - Home Page')
				left join TELECOMMUNICATION T on (T.TELECOMTYPE = SC.COLINTEGER)
				where NT.TELECODE = T.TELECODE
				and NT.NAMENO = @pnNameKey))
	Begin
		Select  @sFormattedTelecom = dbo.fn_FormatTelecom   (T.TELECOMTYPE,
						T.ISD,
						T.AREACODE,
						T.TELECOMNUMBER,
						T.EXTENSION) 	
			from [NAME] N
			join NAMETELECOM NT 		on (NT.NAMENO = N.NAMENO)
			join TELECOMMUNICATION T 	on (T.TELECODE = NT.TELECODE)
			where N.NAMENO = @pnNameKey and T.TELECOMTYPE=@pnTelecomType
			and ((T.TELECOMTYPE = 1901 and NT.TELECODE = N.MAINPHONE)
				or (T.TELECOMTYPE = 1902 and NT.TELECODE = N.FAX)
				or (T.TELECOMTYPE = 1903 and NT.TELECODE = N.MAINEMAIL))		
	End
	
	return @sFormattedTelecom
End
GO

grant execute on dbo.fn_GetMainTelecom to public
go
