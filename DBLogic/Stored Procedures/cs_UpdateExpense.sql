-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateExpense
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateExpense]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_UpdateExpense.'
	drop procedure [dbo].[cs_UpdateExpense]
	print '**** Creating Stored Procedure dbo.cs_UpdateExpense...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_UpdateExpense
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey			varchar(11) = null, 

	@psCostKey			varchar(11) = null output,
	@pnSequence			int = null output,
	@psExpenseTypeKey		varchar(6) = null,
	@psExpenseTypeDescription	varchar(50) = null,
	@psExpenseCategoryKey		nvarchar(10) = null,
	@psExpenseCategoryDescription	nvarchar(50) = null,
	@psSupplierKey			nvarchar(11) = null,
	@psSupplierDisplayName		nvarchar(254) = null,
	@pdtExpenseDate			datetime = null,
	@psSupplierInvoiceNo		nvarchar(12) = null,
	@psCurrencyCode			nvarchar(3) = null,
	@pnLocalAmount			decimal(11, 2) = null,
	@psNotes			ntext = null,

	@pbCaseKeyModified			bit = null,
	@pbCostKeyModified			bit = null,
	@pbSequenceModified			bit = null,
	@pbExpenseTypeKeyModified		bit = null,
	@pbExpenseTypeDescriptionModified	bit = null,
	@pbExpenseCategoryKeyModified		bit = null,
	@pbExpenseCategoryDescriptionModified 	bit = null,
	@pbSupplierKeyModified			bit = null,
	@pbSupplierDisplayNameModified		bit = null,
	@pbExpenseDateModified			bit = null,
	@pbSupplierInvoiceNoModified		bit = null,
	@pbCurrencyCodeModified			bit = null,
	@pbLocalAmountModified			bit = null,
	@pbNotesModified			bit = null

)

-- PROCEDURE :	cs_UpdateExpense
-- VERSION :	7
-- DESCRIPTION:	updates a row 

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 17/07/2002	SF	Stub created
-- 07/08/2002	SF	1. Procedure Created
--			2. Added @psCaseKeyModified  (unlikely to be used by current ui)
--			3. Changed @psNotes from varchar(10) to ntext.
-- 08/08/2002	SF	decimal(11, 2)
-- 15/04/2013	DV	7 R13270 Increase the length of nvarchar to 11 when casting or declaring integer

as
begin
	declare @nErrorCode int
	declare @nCostId int
	
	if @psExpenseCategoryKey is null 
	and @pnLocalAmount is null
	begin
		exec @nErrorCode = dbo.cs_DeleteExpense
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture =  @psCulture,
					@psCostKey = @psCostKey
	end
	else
	begin
		set @nCostId = cast(@psCostKey as int)
		set @nErrorCode = @@error

		if @nErrorCode = 0
		and    (@pbSupplierKeyModified = 1
		or	@pbExpenseDateModified = 1
		or	@pbSupplierInvoiceNoModified = 1
		or	@pbLocalAmountModified = 1)
		begin
			-- update to the header

			update 	COSTTRACK
			set	AGENTNO = 	case when (@pbSupplierKeyModified=1) 	then cast(@psSupplierKey as int) else AGENTNO end,
				INVOICEDATE = 	case when (@pbExpenseDateModified=1) 	then @pdtExpenseDate else INVOICEDATE end,
				INVOICEREF = 	case when (@pbSupplierInvoiceNoModified=1) 	then @psSupplierInvoiceNo else INVOICEREF end,
				INVOICEAMT = case when (@pbLocalAmountModified=1) 	then @pnLocalAmount else INVOICEAMT end
			where	COSTID = @nCostId

			set @nErrorCode = @@error
		end

		if @nErrorCode = 0
		and    (@pbCaseKeyModified = 1
		or	@pbExpenseCategoryKeyModified = 1
		or	@pbLocalAmountModified = 1
		or	@pbNotesModified = 1)		
		begin
			-- update to the child

			declare @bLongFlag bit
			if len(cast(@psNotes as nvarchar(300))) <= 254
				set @bLongFlag = 0
			else
				set @bLongFlag = 1
			
			update 	COSTTRACKLINE
			set	CASEID = 	case when (@pbCaseKeyModified=1) 	then cast(@psCaseKey as int) else CASEID end,
				WIPCODE = 	case when (@pbExpenseCategoryKeyModified=1) 	then @psExpenseCategoryKey else WIPCODE end,
				LOCALAMT = 	case when (@pbLocalAmountModified=1) 	then @pnLocalAmount else LOCALAMT end,
				SHORTNARRATIVE = case when @bLongFlag = 1 		then null else cast(@psNotes as nvarchar(254)) end,
				LONGNARRATIVE = case when @bLongFlag = 1 		then @psNotes else null end
			where	COSTID = @nCostId
			and	COSTLINENO = @pnSequence
			
			set @nErrorCode = @@error
	
		end
	end


	return @nErrorCode
end
go

grant execute on dbo.cs_UpdateExpense to public
go
