-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_DeleteExpense
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_DeleteExpense]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_DeleteExpense.'
	drop procedure [dbo].[cs_DeleteExpense]
end
print '**** Creating Stored Procedure dbo.cs_DeleteExpense...'
print ''
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_DeleteExpense
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey			varchar(10) = null, 
	@psCostKey			varchar(10) = null,
	@pnSequence			int = null,
	@psExpenseTypeKey		varchar(6) = null,
	@psExpenseTypeDescription	varchar(50) = null,
	@psExpenseCategoryKey		nvarchar(10) = null,
	@psExpenseCategoryDescription	nvarchar(50) = null,
	@psSupplierKey			nvarchar(10) = null,
	@psSupplierDisplayName		nvarchar(254) = null,
	@pdtExpenseDate			datetime = null,
	@psSupplierInvoiceNo		nvarchar(12) = null,
	@psCurrencyCode			nvarchar(3) = null,
	@pnLocalAmount			decimal(11, 2) = null,
	@psNotes			nvarchar(10) = null
)
as
-- VERSION:	6
-- DESCRIPTION:	Deletes an expense row from CaseData dataset.
-- SCOPE:	CPA.net
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 05/08/2002	SF			procedure created
-- 06/08/2002	SF			According to spec, this deletes COSTTRACK which has cascade delete to delete all costractlines 
--					belong to it.
-- 08/08/2002	SF			decimal(11, 2)
-- 15/11/2002	SF		6	Updated Version Number

begin
	declare @nErrorCode int
	declare @nCostId int

	set @nCostId = cast(@psCostKey as int)
	set @nErrorCode = @@error


	if @nErrorCode = 0
	and @nCostId is not null
	begin
		delete
		from	COSTTRACK
		where	COSTID = @nCostId

		set @nErrorCode = @@error
	end

	return @nErrorCode
end
GO

grant execute on dbo.cs_DeleteExpense to public
go
