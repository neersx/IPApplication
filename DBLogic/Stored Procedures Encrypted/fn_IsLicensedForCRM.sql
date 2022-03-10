-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_IsLicensedForCRM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_IsLicensedForCRM') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_IsLicensedForCRM'
	Drop function [dbo].[fn_IsLicensedForCRM]
End
Print '**** Creating Function dbo.fn_IsLicensedForCRM...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_IsLicensedForCRM
(
	@pnUserIdentityId   int,
	@pdtToday	    datetime
) 
RETURNS bit
With ENCRYPTION
AS
-- Function :	fn_IsLicensedForCRM
-- VERSION :	2
-- DESCRIPTION:	The function returns 1 if user is licensed for CRM modules, otherwise it returns 0.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 Oct 2014	LP	R9422	1	Function created.
-- 20 Nov 2014	LP	R41712	2	Corrected license number for Marketing Module (Pricing Model 2)

Begin
	
	Declare @bIsLicensed bit
	Declare @CRMWorkBenchLicense int
	Declare @MarketingModuleLicense int
	
	Set @bIsLicensed = 0
	Set @CRMWorkBenchLicense = 25
	Set @MarketingModuleLicense = 32
	
	If (	dbo.fn_IsModuleLicensedToUser(@pnUserIdentityId, @CRMWorkBenchLicense, @pdtToday)= 1 
		OR
		dbo.fn_IsModuleLicensedToUser(@pnUserIdentityId, @MarketingModuleLicense, @pdtToday)= 1)
	Begin
		Set @bIsLicensed = 1
	End
		
	return @bIsLicensed
End
GO

grant execute on dbo.fn_IsLicensedForCRM to public
go