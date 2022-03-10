-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertExpense
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_InsertExpense]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_InsertExpense.'
	drop procedure [dbo].[cs_InsertExpense]
	print '**** Creating Stored Procedure dbo.cs_InsertExpense...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_InsertExpense
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,  	-- the language in which output is to be expressed
	@psCaseKey			nvarchar(11), 	-- Mandatory (DB enforces it)
	@psCostKey			nvarchar(11) 	= null output,
	@pnSequence			int 		= null output,
	@psExpenseTypeKey		nvarchar(6) 	= null,
	@psExpenseTypeDescription	nvarchar(50) 	= null,
	@psExpenseCategoryKey		nvarchar(10) 	= null,
	@psExpenseCategoryDescription	nvarchar(50) 	= null,
	@psSupplierKey			nvarchar(11)      = null,
	@psSupplierDisplayName		nvarchar(254) 	= null,
	@pdtExpenseDate			datetime = null,
	@psSupplierInvoiceNo		nvarchar(12) = null,
	@psCurrencyCode			nvarchar(3) 	= null,
	@pnLocalAmount			decimal(11, 2) 	= null,
	@psNotes			ntext		= null
)
-- PROCEDURE :	cs_InsertExpense
-- VERSION :	8
-- DESCRIPTION:	See CaseData.doc 
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 12/07/2002	JB	Procedure created
-- 25/07/2002	JB	Corrected error handling
-- 26/07/2002	JB	Notes no longer mandatory, was using some varchars 
-- 08/08/2002	SF	1. Insert Short/Long Narrative
--			2. decimal(11, 2)
-- 15/04/2013	DV	8 R13270 Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
	Declare @nErrorId int
	Set @nErrorId = 0
	
	-- --------------
	-- Sort out Data
	-- Minimum data:
	If 	@psExpenseCategoryKey is null
		or @pnLocalAmount is null
		Set @nErrorId = -1
	
	If @nErrorId = 0
	Begin
	
		-- -----------------
		-- Generate CostId
		Declare @nCostId int
		Exec @nErrorId = ip_GetLastInternalCode 1, NULL, 'COSTTRACK', @nCostId output
		Set @psCostKey = CAST(@nCostId as nvarchar(11))
	End
	
	-- ------------------
	-- Create header row
	If @nErrorId = 0
	Begin
		Insert into COSTTRACK
			(	[COSTID],
				[AGENTNO],
				[ENTRYDATE],
				[INVOICEDATE],
				[INVOICEREF],
				[INVOICEAMT]
			)
		values
			(
				@nCostId,
				CAST(@psSupplierKey as int),
				GETDATE(),
				@pdtExpenseDate, 
				@psSupplierInvoiceNo,
				@pnLocalAmount
			)
		Set @nErrorId = @@ERROR
	End
	
	If @nErrorId = 0
	Begin
		-- -------------------
		-- Get the next sequence number
		Select Max([COSTLINENO]) From COSTTRACKLINE
	
		-- -------------------
		-- Create Detail Row
		Declare @bLongNotes bit
		IF LEN(CAST(@psNotes as nvarchar(300))) > 254
			Set @bLongNotes = 1
		Else
			Set @bLongNotes = 0
	
		Set @pnSequence = 0			-- The spec says it can be 0 so why not!
	
		Insert Into COSTTRACKLINE
			(	
				COSTID,
				COSTLINENO,
				CASEID,
				WIPCODE,
				LOCALAMT,
				SHORTNARRATIVE,
				LONGNARRATIVE
			)
			values
			(	@nCostId,
				@pnSequence,
				CAST(@psCaseKey as int),
				@psExpenseCategoryKey,
				@pnLocalAmount,
				case when @bLongNotes = 1 then null else cast(@psNotes as nvarchar(254)) end,
				case when @bLongNotes = 1 then @psNotes else null end
			)
		Set @nErrorId = @@ERROR
	End
	RETURN @nErrorId
	
end
go

grant execute on dbo.cs_InsertExpense to public
go
