---------------------------------------------------------------------------------------------
-- Creation of dbo.ipn_ListValidSubTypes
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListValidSubTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_ListValidSubTypes.'
	drop procedure [dbo].[ipn_ListValidSubTypes]
	Print '**** Creating Stored Procedure dbo.ipn_ListValidSubTypes...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipn_ListValidSubTypes
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null
)
-- VERSION:	3
-- DESCRIPTION:	List Valid Sub Types 
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 15 NOV 2002 	SF	3	Update Version Number
-- 13 FEB 2003	SF	4	RFC5 - Implement Valid Sub Types
as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Select 	SUBTYPE			as 'SubTypeKey',
		SUBTYPEDESC 		as 'SubTypeDescription',
		COUNTRYCODE 		as 'CountryKey',
		Case 	COUNTRYCODE 
			when 'ZZZ' then 1
			else 0 
		end 			as 'IsDefaultCountry',
		PROPERTYTYPE 		as 'PropertyTypeKey',
		CASETYPE		as 'CaseTypeKey',
		CASECATEGORY		as 'CaseCategoryKey'
	from	VALIDSUBTYPE
	order by SUBTYPEDESC

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

grant exec on dbo.ipn_ListValidSubTypes to public
go
