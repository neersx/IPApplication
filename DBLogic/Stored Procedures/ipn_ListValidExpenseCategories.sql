-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_ListValidExpenseCategories
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListValidExpenseCategories]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipn_ListValidExpenseCategories.'
	drop procedure [dbo].[ipn_ListValidExpenseCategories]
	print '**** Creating Stored Procedure dbo.ipn_ListValidExpenseCategories...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

create procedure dbo.ipn_ListValidExpenseCategories
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null
)
-- VERSION:	5
-- DESCRIPTION:	List Valid Expense Categories
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 18 Jul 2002	SF		procedure created
-- 15 Nov 2002 	SF	5	Update Version Number
as
begin
	set nocount on

	select 	WIPCODE 	as 'ExpenseCategoryKey',
		DESCRIPTION	as 'ExpenseCategoryDescription',
		WIPTYPEID	as 'ExpenseTypeKey'
	from 	WIPTEMPLATE	as ValidExpenseCategory
	order by DESCRIPTION

	return @@error
end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.ipn_ListValidExpenseCategories to public
go
