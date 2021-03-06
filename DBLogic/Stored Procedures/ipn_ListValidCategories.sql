-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_ListValidCategories
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListValidCategories]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipn_ListValidCategories.'
	drop procedure [dbo].[ipn_ListValidCategories]
	print '**** Creating Stored Procedure dbo.ipn_ListValidCategories...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipn_ListValidCategories
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null
)
-- VERSION:	4
-- DESCRIPTION:	List Valid Categories
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 15 Nov 2002 	SF	4	Update Version Number
as
	-- set server options
	set NOCOUNT on
	select 	CASECATEGORY as CaseCategoryKey,
			CASECATEGORYDESC as CaseCategoryDescription,
			COUNTRYCODE as CountryKey,
			Case 	COUNTRYCODE 
				when 'ZZZ' then 1
				else 0 
			end as IsDefaultCountry,
			PROPERTYTYPE as PropertyTypeKey,
			CASETYPE as CaseTypeKey
	from	VALIDCATEGORY
	order by CASECATEGORYDESC
	return @@Error
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.ipn_ListValidCategories to public
go
