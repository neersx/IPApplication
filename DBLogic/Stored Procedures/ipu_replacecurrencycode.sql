-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_ReplaceCurrencyCode
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipu_ReplaceCurrencyCode]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipu_ReplaceCurrencyCode.'
	drop procedure dbo.ipu_ReplaceCurrencyCode
end
print '**** Creating procedure dbo.ipu_ReplaceCurrencyCode...'
print ''
go

Create Procedure dbo.ipu_ReplaceCurrencyCode
			@psCurrencyCodeOld	nvarchar(3),
			@psCurrencyCodeNew	nvarchar(3),
			@pnDebugFlag		tinyint	=0
as 
-- PROCEDURE :	ipu_ReplaceCurrencyCode
-- VERSION :	5
-- DESCRIPTION:	Replaces an existing Currency Code for a new one and changes all existing
--		references to the old code to point to the new code.
-- CALLED BY :	

-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05/08/2002	MF		1	Procedure created	
-- 07/10/2003	AB		2	Formatting for Clear Case auto generation
-- 21/02/2008	CR	10105	3	Updated Trust Accounting References.
--					Also add the following missing references:
--					CREDITOR, CREDITORHISTORY, CREDITORITEM,
--					EXCHRATEVARIATION, LEDGERJOURNALLINE, MARGIN, 
--					SPECIALNAME, STANDINGTEMPLT, STANDINGTEMPLTLINE,
--					TRUSTITEM	
-- 11 Dec 2008	MF	17136	4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 23 Oct 2009	MF	RFC8260	5	New table CASECHARGESCACHE				


-- disable row counts
set nocount on
	
declare	@ErrorCode	int
declare @RowCount	int
declare	@TranCountStart	int

Set @ErrorCode=0
Set @RowCount =0

-- If the new Code does not currently exist then copy it from the old Currency

If @ErrorCode=0
and not exists (Select * from CURRENCY where CURRENCY=@psCurrencyCodeNew)
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	insert into CURRENCY (CURRENCY, DESCRIPTION, BUYFACTOR, SELLFACTOR, BANKRATE, BUYRATE, SELLRATE, DATECHANGED, ROUNDBILLEDVALUES)
	select @psCurrencyCodeNew, DESCRIPTION, BUYFACTOR, SELLFACTOR, BANKRATE, BUYRATE, SELLRATE, DATECHANGED, ROUNDBILLEDVALUES
	from CURRENCY
	where CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- If no rows were copied then set the ErrorCode to -1 to indicate
	-- that the old Currency does not exist
	
	If @RowCount=0
	Begin
		set @ErrorCode=-1
	End

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'New Currency inserted '+@psCurrencyCodeNew
			end
		end
		Else begin
			ROLLBACK TRANSACTION
		End
	End
End

-- Now update each reference to the old Currency and point it to the new
-- currency.  Each update should be treated as its own transaction.

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update BANKACCOUNT
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'BANKACCOUNT Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update ACTIVITYREQUEST
	set    DISBCURRENCY=@psCurrencyCodeNew
	where  DISBCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'ACTIVITYREQUEST DisbCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update ACTIVITYREQUEST
	set    SERVICECURRENCY=@psCurrencyCodeNew
	where  SERVICECURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'ACTIVITYREQUEST ServiceCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update ACTIVITYREQUEST
	set    BILLCURRENCY=@psCurrencyCodeNew
	where  BILLCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'ACTIVITYREQUEST BillCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update ACTIVITYHISTORY
	set    DISBCURRENCY=@psCurrencyCodeNew
	where  DISBCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'ACTIVITYHISTORY DisbCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update ACTIVITYHISTORY
	set    SERVICECURRENCY=@psCurrencyCodeNew
	where  SERVICECURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'ACTIVITYHISTORY ServiceCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update ACTIVITYHISTORY
	set    BILLCURRENCY=@psCurrencyCodeNew
	where  BILLCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'ACTIVITYHISTORY BillCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update BANKHISTORY
	set    PAYMENTCURRENCY=@psCurrencyCodeNew
	where  PAYMENTCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'BANKHISTORY PaymentCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update BILLLINE
	set    PRINTCHARGECURRNCY=@psCurrencyCodeNew
	where  PRINTCHARGECURRNCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'BILLLINE PrintChargeCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update CASECHARGESCACHE
	set    BILLCURRENCY=@psCurrencyCodeNew
	where  BILLCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'CASECHARGESCACHE BILLCURRENCY updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update CASHHISTORY
	set    DISSECTIONCURRENCY=@psCurrencyCodeNew
	where  DISSECTIONCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'CASHHISTORY DissectionCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update CASHITEM
	set    DISSECTIONCURRENCY=@psCurrencyCodeNew
	where  DISSECTIONCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'CASHITEM DissectionCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update CASHITEM
	set    PAYMENTCURRENCY=@psCurrencyCodeNew
	where  PAYMENTCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'CASHITEM PaymentCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update COUNTRY
	set    DEFAULTCURRENCY=@psCurrencyCodeNew
	where  DEFAULTCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'COUNTRY DefaultCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update CREDITOR
	set    PURCHASECURRENCY=@psCurrencyCodeNew
	where  PURCHASECURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'CREDITOR PurchaseCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update CREDITORHISTORY
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'CREDITORHISTORY Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update CREDITORITEM
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'CREDITORITEM Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End


If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update DEBTORHISTORY
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'DEBTORHISTORY Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update DIARY
	set    FOREIGNCURRENCY=@psCurrencyCodeNew
	where  FOREIGNCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'DIARY ForeignCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update EXCHANGERATEHIST
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'EXCHANGERATEHIST Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update EXCHRATEVARIATION
	set    CURRENCYCODE=@psCurrencyCodeNew
	where  CURRENCYCODE=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'EXCHRATEVARIATION CurrencyCode updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End


If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update EXPENSEIMPORT
	set    FOREIGNCURRENCY=@psCurrencyCodeNew
	where  FOREIGNCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'EXPENSEIMPORT ForeignCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update FEELIST
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'FEELIST Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update FEELISTCASE
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'FEELISTCASE Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update FEESCALCULATION
	set    SERVICECURRENCY=@psCurrencyCodeNew
	where  SERVICECURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'FEESCALCULATION ServiceCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update FEESCALCULATION
	set    DISBCURRENCY=@psCurrencyCodeNew
	where  DISBCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'FEESCALCULATION DisbCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

-- No need to worry about GLACCOUNTMAPPING as it has ON DELETE CASCADE

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update IPNAME
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'IPNAME Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update LEDGERJOURNALLINE
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'LEDGERJOURNALLINE Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update MARGIN
	set    MARGINCURRENCY=@psCurrencyCodeNew
	where  MARGINCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'MARGIN MarginCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update MARGIN
	set    DEBTORCURRENCY=@psCurrencyCodeNew
	where  DEBTORCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'MARGIN DebtorCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update OPENITEM
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'OPENITEM Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update OPENITEM
	set    FOREIGNEQUIVCURRCY=@psCurrencyCodeNew
	where  FOREIGNEQUIVCURRCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'OPENITEM FOREIGNEQUIVCURRCY updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update QUOTATION
	set    FOREIGNCURRENCY=@psCurrencyCodeNew
	where  FOREIGNCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'QUOTATION ForeignCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update SITECONTROL
	set    COLCHARACTER=@psCurrencyCodeNew
	where  COLCHARACTER=@psCurrencyCodeOld
	and    CONTROLID='CURRENCY'

	select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'SITECONTROL Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update SPECIALNAME
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'SPECIALNAME Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update STANDINGTEMPLT
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'STANDINGTEMPLT Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update STANDINGTEMPLTLINE
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'STANDINGTEMPLTLINE Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update TIMECOSTING
	set    FOREIGNCURRENCY=@psCurrencyCodeNew
	where  FOREIGNCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'TIMECOSTING ForeignCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update TRUSTHISTORY
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'TRUSTHISTORY Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update TRUSTITEM
	set    CURRENCY=@psCurrencyCodeNew
	where  CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'TRUSTITEM Currency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End


If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update WORKHISTORY
	set    VARIABLEFEECURR=@psCurrencyCodeNew
	where  VARIABLEFEECURR=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'WORKHISTORY VariableFeeCurr updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update WORKHISTORY
	set    FOREIGNCURRENCY=@psCurrencyCodeNew
	where  FOREIGNCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'WORKHISTORY ForeignCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update WORKINPROGRESS
	set    FOREIGNCURRENCY=@psCurrencyCodeNew
	where  FOREIGNCURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'WORKINPROGRESS ForeignCurrency updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	update WORKINPROGRESS
	set    VARIABLEFEECURR=@psCurrencyCodeNew
	where  VARIABLEFEECURR=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'WORKINPROGRESS VariableFeeCurr updated from '+@psCurrencyCodeOld+' to '+@psCurrencyCodeNew
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

-- Finally on successful completion of the updates the old
-- currency code can be deleted

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	Delete from CURRENCY
	where CURRENCY=@psCurrencyCodeOld

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
		begin
			COMMIT TRANSACTION
			If @pnDebugFlag=1 and @RowCount>0
			begin
				Select 'Deleted Currency '+@psCurrencyCodeOld
			End
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

Return @ErrorCode
go 

grant execute on dbo.ipu_ReplaceCurrencyCode to public
go
