-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_IsModuleLicensedToUser
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_IsModuleLicensedToUser') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_IsModuleLicensedToUser'
	Drop function [dbo].[fn_IsModuleLicensedToUser]
End
Print '**** Creating Function dbo.fn_IsModuleLicensedToUser...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_IsModuleLicensedToUser
(
	@pnUserIdentityId   int,
	@pnModuleId	    int,
	@pdtToday	    datetime
) 
RETURNS bit
With ENCRYPTION
AS
-- Function :	fn_IsModuleLicensedToUser
-- VERSION :	1
-- DESCRIPTION:	The function returns 1 if module is licensed to the user, otherwise it returns 0.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Dec 2008	AT	RFC7365	1	Function created.

Begin
	Declare @bIsModuleLicensed bit
	
	Set @bIsModuleLicensed = 0

	Select @bIsModuleLicensed = 1
	from dbo.fn_LicensedModules(@pnUserIdentityId,@pdtToday) LM
	join USERIDENTITY UID on (UID.IDENTITYID = @pnUserIdentityId
				and ((UID.ISEXTERNALUSER = 0 and LM.INTERNALUSE = 1)
					or (UID.ISEXTERNALUSER = 1 and LM.EXTERNALUSE = 1))
				)
	where LM.MODULEID = @pnModuleId

	return @bIsModuleLicensed
End
GO

grant execute on dbo.fn_IsModuleLicensedToUser to public
go