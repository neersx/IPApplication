-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetBillingSettings] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetBillingSettings]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetBillingSettings].'
	drop procedure dbo.[biw_GetBillingSettings]
end
print '**** Creating procedure dbo.[biw_GetBillingSettings]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetBillingSettings]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0
as
-- PROCEDURE :	biw_GetBillingSettings
-- VERSION :	6
-- DESCRIPTION:	A procedure that returns all of the generic settings required by billing
--
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 12/08/2011	AT	RFC10241	1	Procedure created.
-- 01/09/2011	AT	RFC11235	2	Added Bill Date Change site control.
-- 24/10/2011	AT	RFC10168	3	Added Inter-Entity billing site control.
-- 01/12/2011	AT	RFC10458	4	Added Bill Lines Grouped by Tax Code site control.
-- 14/05/2012	AT	RFC12149	5	Fixed performance issue with fn_DateOnly function call.
-- 27/06/2012	KR	RFC12362	6	Added PreserveConsolidate.

set nocount on

Declare		@ErrorCode		int
Declare		@sSQLString		nvarchar(max)
declare		@sLookupCulture         nvarchar(10)

declare		@bChangeReminderActive		bit
declare		@sHomeCurrency			nvarchar(3)
declare		@nLocalDecimalPlaces		int
declare		@nHomeNameNo			int
declare		@bBillRenewalDebtor		bit
declare		@dtLastFinalisedDate		datetime
declare		@bBillDateChange		bit
declare		@bInterEntityBilling		bit
declare		@nPreserveConsolidate		int
declare		@bBillLinesGroupedByTaxCode	bit

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @ErrorCode = 0

if (@ErrorCode = 0
	and exists(SELECT * from NAME N
		join SITECONTROL SC on N.NAMENO = SC.COLINTEGER
		WHERE SC.CONTROLID = 'DN Change Administrator')
	and exists(SELECT * FROM ALERTTEMPLATE AT
		join SITECONTROL SC on (AT.ALERTTEMPLATECODE = SC.COLCHARACTER)
		WHERE SC.CONTROLID = 'DN Change Reminder Template'))
Begin
	set @bChangeReminderActive = 1
End
Else
Begin
	set @bChangeReminderActive = 0	
End

if (@ErrorCode = 0)
Begin
	Set @sSQLString = "select @sHomeCurrency = S.COLCHARACTER,
			@nLocalDecimalPlaces = CASE WHEN CWU.COLBOOLEAN = 1 THEN 0 ELSE ISNULL(C.DECIMALPLACES,2) END
			FROM SITECONTROL S 
			join CURRENCY C on (S.COLCHARACTER = C.CURRENCY),
			SITECONTROL CWU
			WHERE S.CONTROLID = 'CURRENCY'
			AND CWU.CONTROLID = 'Currency Whole Units'"			

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sHomeCurrency	nvarchar(3)	OUTPUT,
				  @nLocalDecimalPlaces	int		OUTPUT',
				  @sHomeCurrency=@sHomeCurrency		OUTPUT,
				  @nLocalDecimalPlaces=@nLocalDecimalPlaces OUTPUT
End

if (@ErrorCode = 0)
Begin
	Set @sSQLString = "select @nHomeNameNo = COLINTEGER
	FROM SITECONTROL HNN
	WHERE HNN.CONTROLID = 'HOMENAMENO'"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nHomeNameNo	int	OUTPUT',
				  @nHomeNameNo=@nHomeNameNo OUTPUT
End


If (@ErrorCode = 0)
	and exists (select * from SITECONTROL WHERE CONTROLID = 'Bill Renewal Debtor' AND COLBOOLEAN = 1)
Begin
	Set @bBillRenewalDebtor = 1
End
Else
Begin
	Set @bBillRenewalDebtor = 0
End

If exists (select * from SITECONTROL WHERE CONTROLID = 'BillDatesForwardOnly' and COLBOOLEAN = 1)
Begin
	-- Note the same code exists in biw_GetBillingSettings
	Set @sSQLString = "select @dtLastFinalisedDate = dbo.fn_DateOnly(MAX(ITEMDATE))
			from OPENITEM 
			WHERE STATUS = 1
			AND ITEMTYPE IN (510, 511, 513, 514)"
			
	exec @ErrorCode = sp_executesql @sSQLString,
				N'@dtLastFinalisedDate datetime output',
				@dtLastFinalisedDate = @dtLastFinalisedDate output
End


If (@ErrorCode = 0)
	and exists (select * from SITECONTROL WHERE CONTROLID = 'Bill Date Change' AND COLBOOLEAN = 1)
Begin
	Set @bBillDateChange = 1
End
Else
Begin
	Set @bBillDateChange = 0
End

If exists (select * from SITECONTROL WHERE CONTROLID = 'Inter-Entity Billing')
Begin
	Set @sSQLString = "select @bInterEntityBilling = isnull(COLBOOLEAN,0)
	FROM SITECONTROL
	WHERE CONTROLID = 'Inter-Entity Billing'"
			
	exec @ErrorCode = sp_executesql @sSQLString,
				N'@bInterEntityBilling bit output',
				@bInterEntityBilling = @bInterEntityBilling output
End

If exists (select * from SITECONTROL WHERE CONTROLID = 'Bill Lines Grouped by Tax Code')
Begin
	Set @sSQLString = "select @bBillLinesGroupedByTaxCode = isnull(COLBOOLEAN,0)
	FROM SITECONTROL
	WHERE CONTROLID = 'Bill Lines Grouped by Tax Code'"
			
	exec @ErrorCode = sp_executesql @sSQLString,
				N'@bBillLinesGroupedByTaxCode bit output',
				@bBillLinesGroupedByTaxCode = @bBillLinesGroupedByTaxCode output
End

if @ErrorCode = 0
Begin
	Select 
	@nHomeNameNo			as HomeNameNo,
	@sHomeCurrency			as HomeCurrency,
	@nLocalDecimalPlaces		as LocalDecimalPlaces,
	@bBillRenewalDebtor		as BillRenewalDebtor,
	@bChangeReminderActive		as ChangeReminderActive,
	@dtLastFinalisedDate		as LastFinalisedDate,
	@bBillDateChange		as BillDateChange,
	@bInterEntityBilling		as InterEntityBilling,
	isnull(@bBillLinesGroupedByTaxCode,0)	as BillLinesGroupedByTaxCode
End

return @ErrorCode
go

grant execute on dbo.[biw_GetBillingSettings]  to public
go