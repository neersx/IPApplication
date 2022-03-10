
Declare @nErr int
Declare @sCostKey nvarchar(10)
Declare @nSequence int
Declare @dtToday datetime
Set @dtToday = GETDATE()

Select * from COSTTRACK

exec @nErr  = dbo.cs_InsertExpense
	@pnUserIdentityId		= 1,
	@psCulture			= default,  	-- the language in which output is to be expressed
	@psCaseKey			= '-484', 
	@psCostKey			= @sCostKey output,
	@pnSequence			= @nSequence output,
	@psExpenseTypeKey		= default,
	@psExpenseCategoryKey		= '12',
	@psSupplierKey			= '-283847782',	-- Mand
	@psSupplierDisplayName		= default,
	@pdtExpenseDate			= @dtToday,	-- Mand
	@psSupplierInvoiceNo		= '12',
	@psCurrencyCode			= default,
	@pnLocalAmount			= 12.12,
	@psNotes			= default


Select * from COSTTRACK
Select @nErr