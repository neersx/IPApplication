-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_ListExpenseTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListExpenseTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipn_ListExpenseTypes.'
	drop procedure [dbo].[ipn_ListExpenseTypes]
	print '**** Creating Stored Procedure dbo.ipn_ListExpenseTypes...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

create procedure dbo.ipn_ListExpenseTypes
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null
)
-- VERSION:	5
-- DESCRIPTION:	List Expense Types
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 18 Jul 2002	SF		procedure created
-- 15 Nov 2002 	SF	5	Update Version Number
as
begin
	set nocount on

	select 	WIPTYPEID 	as 'ExpenseTypeKey',
		DESCRIPTION	as 'ExpenseTypeDescription'
	from 	WIPTYPE		as ExpenseType
	order by DESCRIPTION

	return @@error
end
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ipn_ListExpenseTypes to public
go
