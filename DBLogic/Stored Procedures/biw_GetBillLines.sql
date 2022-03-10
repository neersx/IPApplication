-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetBillLines] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetBillLines]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetBillLines].'
	drop procedure dbo.[biw_GetBillLines]
end
print '**** Creating procedure dbo.[biw_GetBillLines]...'
print ''
go

set QUOTED_IDENTIFIER on
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetBillLines]
			@pnUserIdentityId	int,		-- Mandatory
			@psCulture		nvarchar(10) = null,
			@pbCalledFromCentura	bit = 0,
			@pnItemEntityNo		int = null,
			@pnItemTransNo		int = null,
			@psMergeXMLKeys		nvarchar(max) = null
				
as
-- PROCEDURE :	biw_GetBillLines
-- VERSION :	7
-- DESCRIPTION:	A procedure that returns all of the bill lines associated to an OpenItem
--
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 14-Oct-2009	AT	RFC3605		1	Procedure created
-- 11-Nov-2010	AT	RFC9919		2	Add order by
-- 31 Mar 2011  LP      RFC8412         		3       Return GeneratedFromTaxCode and IsHiddenForDraft columns.
-- 29-Apr-2011	AT	RFC7956		4	Process merge bill.
-- 11-Jan-2012	AT	RFC10458		5	Return Tax Code.
-- 14-Jun-2012	AT	RFC12395		6	Suppress return of stamp fee rows for merged bills.
-- 26-Jun-2012	KR	RFC12430		7	Made to select distinct from the merged XML keys passed to avoid duplicate rows being returned.


set nocount on
set concat_null_yields_null on

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
Declare		@XMLKeys	XML

Set @ErrorCode = 0

If @ErrorCode = 0
Begin
	-- RETURN BILL LINES
	Set @sSQLString = '
		select BL.ITEMENTITYNO as ''ItemEntityNo'',
		BL.ITEMTRANSNO as ''ItemTransNo'',
		ITEMLINENO as ''ItemLineNo'',
		WIPCODE as ''WIPCode'',
		WIPTYPEID as ''WIPTypeId'',
		CATEGORYCODE as ''CategoryCode'',
		IRN as ''IRN'',
		VALUE as ''Value'',
		DISPLAYSEQUENCE as ''DisplaySequence'',
		PRINTDATE as ''PrintDate'',
		PRINTNAME as ''PrintName'',
		PRINTCHARGEOUTRATE as ''PrintChargeOutRate'',
		PRINTTOTALUNITS as ''PrintTotalUnits'',
		UNITSPERHOUR as ''UnitsPerHour'',
		NARRATIVENO as ''NarrativeNo'',
		isnull(LONGNARRATIVE, SHORTNARRATIVE) as ''Narrative'',
		FOREIGNVALUE as ''ForeignValue'',
		PRINTCHARGECURRNCY as ''PrintChargeCurrncy'',
		PRINTTIME as ''PrintTime'',
		LOCALTAX as ''LocalTax'',
		GENERATEDFROMTAXCODE as ''GeneratedFromTaxCode'',
		ISHIDDENFORDRAFT as ''IsHiddenForDraft'',
		TAXCODE as ''TaxCode''
		from BILLLINE BL'
		
		if (@psMergeXMLKeys is not null)
		Begin
		
		Set @XMLKeys = cast(@psMergeXMLKeys as XML)
		
		Set @sSQLString = + @sSQLString + char(10) + 'JOIN (
			select	distinct K.value(N''ItemEntityNo[1]'',N''int'') as ItemEntityNo,
				K.value(N''ItemTransNo[1]'',N''int'') as ItemTransNo
			from @XMLKeys.nodes(N''/Keys/Key'') KEYS(K)
				) as XM on (XM.ItemEntityNo = BL.ITEMENTITYNO
					and XM.ItemTransNo = BL.ITEMTRANSNO)
			Where BL.GENERATEDFROMTAXCODE IS NULL'
		End
		else
		Begin
		Set @sSQLString = + @sSQLString + char(10) +
			'Where BL.ITEMTRANSNO = @pnItemTransNo
			and BL.ITEMENTITYNO= @pnItemEntityNo'
		End
		
		Set @sSQLString = + @sSQLString + char(10) + 'ORDER BY ITEMTRANSNO, DISPLAYSEQUENCE'
		
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnItemTransNo	int,
				  @pnItemEntityNo	int,
				  @XMLKeys		XML',
				  @pnItemTransNo=@pnItemTransNo,
				  @pnItemEntityNo=@pnItemEntityNo,
				  @XMLKeys=@XMLKeys

End

return @ErrorCode
go

grant execute on dbo.[biw_GetBillLines]  to public
go
