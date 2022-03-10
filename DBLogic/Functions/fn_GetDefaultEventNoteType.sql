-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetDefaultEventNoteType
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_GetDefaultEventNoteType]') and xtype in (N'FN', N'IF', N'TF'))
Begin
	Print '**** Drop Function dbo.fn_GetDefaultEventNoteType'
	Drop function [dbo].[fn_GetDefaultEventNoteType]
End
Print '**** Creating Function dbo.fn_GetDefaultEventNoteType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetDefaultEventNoteType
(
	@pnUserIdentityId	int		-- Mandatory
) 
RETURNS int
AS
-- Function :	fn_GetDefaultEventNoteType
-- VERSION :	2
-- DESCRIPTION:	Return default value fo event note type from user preferences
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	----------------------------------------------- 
-- 02 Mar 2015	MS	R43203		1	Function created
-- 23 Mar 2020	BS	DR-57435 	2	DB public role missing execute permission on some stored procedures and functions
Begin
	Declare @nDefaultEventNoteType 		int

	Set @nDefaultEventNoteType = null

	Select	@nDefaultEventNoteType = SV.COLINTEGER								
	from	SETTINGVALUES SV
	Join EVENTTEXTTYPE ET on (SV.COLINTEGER = ET.EVENTTEXTTYPEID)
	where	SV.SETTINGID = 25
	and	SV.IDENTITYID = @pnUserIdentityId	

	If @nDefaultEventNoteType is null
	Begin
		Select	@nDefaultEventNoteType = SV.COLINTEGER								
		from	SETTINGVALUES SV
		Join EVENTTEXTTYPE ET on (SV.COLINTEGER = ET.EVENTTEXTTYPEID)
		where	SV.SETTINGID = 25
		and	SV.IDENTITYID is null
	End

Return @nDefaultEventNoteType
End
GO

grant execute on dbo.fn_GetDefaultEventNoteType to public
GO
