---------------------------------------------------------------------------------------------
-- Creation of dbo.ipn_ListCaseCategories
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListCaseCategories]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_ListCaseCategories.'
	drop procedure [dbo].[ipn_ListCaseCategories]
	Print '**** Creating Stored Procedure dbo.ipn_ListCaseCategories...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipn_ListCaseCategories
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null
)
-- VERSION:	4
-- DESCRIPTION:	List Case Categories
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 15 Nov 2002	SF	4	Update Version Number
as
	-- set server options
	set NOCOUNT on

	select 	distinct
		CASECATEGORY as CaseCategoryKey,
		CASECATEGORYDESC as CaseCategoryDescription,
		CASECATEGORY as CaseCategoryCode
	from 	CASECATEGORY
	order by CASECATEGORYDESC

	return @@Error
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.ipn_ListCaseCategories to public
go
