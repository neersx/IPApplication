-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_IsModuleLicensed
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_IsModuleLicensed') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_IsModuleLicensed'
	Drop function [dbo].[fn_IsModuleLicensed]
End
Print '**** Creating Function dbo.fn_IsModuleLicensed...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_IsModuleLicensed
(
	@pnUserIdentityId	int,
	@pnModuleId		int
) 
RETURNS bit
With ENCRYPTION
AS
-- Function :	fn_IsModuleLicensed
-- VERSION :	3
-- DESCRIPTION:	The function returns true if module is licensed, otherwise it returns false.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Aug 2004	TM	RFC1516	1	Function created
-- 01 Sep 2004	TM	RFC1516	2	Remove the date check.
-- 28 Sep 2004	TM	RFC1516	3	Return bit instead of the nvarchar(13)

Begin
	Declare @bIsModuleLicensed bit

	Set @bIsModuleLicensed = 0	

	Select @bIsModuleLicensed = 1
	from dbo.fn_LicenseData()
	where MODULEID = @pnModuleId
	-- The firm is licensed if: @nPricingModel = 1 (unlimited users) 
	-- OR	@nModuleUsers > 0
	and  (PRICINGMODEL = 1
	or    MODULEUSERS > 0)				
		
	return @bIsModuleLicensed
End
GO

grant execute on dbo.fn_IsModuleLicensed to public
go
