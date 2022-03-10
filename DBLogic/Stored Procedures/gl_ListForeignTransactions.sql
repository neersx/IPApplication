

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListForeignTransactions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_ListForeignTransactions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_ListForeignTransactions.'
	Drop procedure [dbo].[gl_ListForeignTransactions]
End
Print '**** Creating Stored Procedure dbo.gl_ListForeignTransactions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.gl_ListForeignTransactions
(
	@psSubLedger			nvarchar(80),		-- Value: ‘BANK’, ‘AP’, ‘AR’ or ‘WIP’		
	@pnEntityNo			int, 
	@pnPostPeriod			int,
	@psCurrency			nvarchar(6),
	@pnExchangeRate			decimal(11,4),
	@psBankAccount			nvarchar(4000),		-- list of bank accounts separated by comma.
	@psWipCategory			nvarchar(30),		-- list of wip category comma separated. e.g. "'cat1', 'cat2', ..."
	@psWipTypeId			nvarchar(12),
	@psWipCode			nvarchar(4000)		-- list of wip code comma separated. e.g. "'wipcode1', 'wipcode2'..."
)
as
-- PROCEDURE:	gl_ListForeignTransactions
-- VERSION:	7
-- SCOPE:	Inprotech
-- DESCRIPTION:	List balance values of foreign transactions for a Bank or Creditors (AP) or Debtors (AR) or WIP
-- COPYRIGHT:	Copyright 2009 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------- -------	----------------------------------------------- 
-- 27/07/2009	DL	11964	1	Procedure created.
-- 03/09/2009	DL	17952	2	Handling multiple currencies and banks
-- 16/03/2010	DL	18542	3	Include Bank reversed transactions in the revaluation
-- 03/05/2012	CR	20506	4	Change Entity Filter to refer to ENTITYNO instead of REFENTITYNO
-- 06/03/2013	CR	21178	5	Expanded AP and AR to also check for SUM(LOCALVALUE) <> 0
-- 15 Apr 2013	DV	R13270	6	Increase the length of nvarchar to 11 when casting or declaring integer
-- 20 Oct 2015  MS      R53933  7       Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


declare @sSql				nvarchar(4000)
declare @sSqlWhere			nvarchar(4000)
declare @sSqlWhereCommon		nvarchar(4000)
declare @sSqlFrom			nvarchar(4000)
declare @sSqlGroupBy 			nvarchar(2000)
declare	@nErrorCode			int
declare @sDefaultCurrency		nvarchar(30)

-- Get the default currency
Select @sDefaultCurrency = COLCHARACTER 
from SITECONTROL 
where CONTROLID = 'CURRENCY'



If @psSubLedger = 'BANK'
Begin
	Select Case when BA.IBAN is null then BA.ACCOUNTNO
			else BA.IBAN end + CHAR(32) + BA.DESCRIPTION AS bank_account,
	SUM( B.BANKNET) as foreign_balance, 
	SUM( B.LOCALNET) as local_balance, 
	SUM( B.BANKNET)/ isnull(@pnExchangeRate, min(C.BANKRATE)) as new_local, 
	(SUM( B.BANKNET)/ isnull(@pnExchangeRate, min(C.BANKRATE))) - SUM( B.LOCALNET) as  difference,
	BA.CURRENCY,
	isnull(min(BA.CABPROFITCENTRE), min(DA.PROFITCENTRECODE)) ProfitCentreCode,
	isnull(min(BA.CABACCOUNTID), min(DA.ACCOUNTID)) AccountId


	From  BANKHISTORY B
	Join BANKACCOUNT BA on (BA.ACCOUNTOWNER = B.ENTITYNO 
				and BA.BANKNAMENO = B.BANKNAMENO 
				and BA.SEQUENCENO = B.SEQUENCENO )
	Join CURRENCY C on (C.CURRENCY = BA.CURRENCY)
	left join DEFAULTACCOUNT DA  ON (DA.ENTITYNO= BA.ACCOUNTOWNER and DA.CONTROLACCTYPEID = 8701 )

	Where B.ENTITYNO = @pnEntityNo
	and B.POSTPERIOD <= @pnPostPeriod
	and CAST(BA.ACCOUNTOWNER as NVARCHAR(11)) + '^' + CAST(BA.BANKNAMENO as NVARCHAR(11)) + '^' + CAST(BA.SEQUENCENO as NVARCHAR(10))  
			in (Select Parameter from dbo.fn_Tokenise(@psBankAccount, NULL))
	and BA.CURRENCY = isnull(@psCurrency, BA.CURRENCY)
	and B.STATUS <> 0	-- exclude draft transactions
	-- ignore default currency transactions if currency filter is not specified.
	and 1 = (case when (@psCurrency is null and BA.CURRENCY = @sDefaultCurrency) then 0 else 1 end)

	Group by Case when BA.IBAN is null then BA.ACCOUNTNO
			else BA.IBAN end + CHAR(32) + BA.DESCRIPTION, BA.CURRENCY
	Having SUM(B.BANKNET) <> 0
	Order by Case when BA.IBAN is null then BA.ACCOUNTNO
			else BA.IBAN end + CHAR(32) + BA.DESCRIPTION, BA.CURRENCY

	Set @nErrorCode = @@ERROR
End

-- Debtors
If @psSubLedger = 'AR'
Begin
	Select convert( nvarchar(254), N.NAME 
		+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' END 
		+ N.FIRSTNAME+SPACE(1)
		+ CASE WHEN N.NAMECODE IS NOT NULL THEN '{' END 
		+ N.NAMECODE
		+ CASE WHEN N.NAMECODE IS NOT NULL THEN '}' END ) as debtor, 
	SUM(DH.FOREIGNTRANVALUE) AS foreign_balance,
	SUM(DH.LOCALVALUE) AS local_balance, 
	SUM( DH.FOREIGNTRANVALUE)/ isnull(@pnExchangeRate, min(C.SELLRATE)) as new_local, 
	(SUM( DH.FOREIGNTRANVALUE)/ isnull(@pnExchangeRate, min(C.SELLRATE))) - SUM( DH.LOCALVALUE) as  difference,
	DH.CURRENCY, null ProfitCentre, null LedgerAccount

	From DEBTORHISTORY  DH
	Join NAME N ON (N.NAMENO = DH.ACCTDEBTORNO)  
	Join CURRENCY C on (C.CURRENCY = DH.CURRENCY)

	Where DH.ITEMENTITYNO = @pnEntityNo
	and DH.POSTPERIOD <= @pnPostPeriod
	and DH.CURRENCY = isnull(@psCurrency, DH.CURRENCY)
	and DH.STATUS != 0  	-- exclude draft transactions
	and DH.MOVEMENTCLASS != 9 
	-- ignore default currency transactions if currency filter is not specified.
	and 1 = (case when (@psCurrency is null and DH.CURRENCY = @sDefaultCurrency) then 0 else 1 end)

	GROUP BY convert( nvarchar(254), N.NAME 
		+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' END 
		+ N.FIRSTNAME+SPACE(1)
		+ CASE WHEN N.NAMECODE IS NOT NULL THEN '{' END 
		+ N.NAMECODE
		+ CASE WHEN N.NAMECODE IS NOT NULL THEN '}' END ), DH.CURRENCY

	HAVING SUM(DH.FOREIGNTRANVALUE) <> 0 OR SUM(DH.LOCALVALUE) <> 0

	ORDER BY convert( nvarchar(254), N.NAME 
		+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' END 
		+ N.FIRSTNAME+SPACE(1)
		+ CASE WHEN N.NAMECODE IS NOT NULL THEN '{' END 
		+ N.NAMECODE
		+ CASE WHEN N.NAMECODE IS NOT NULL THEN '}' END )

	Set @nErrorCode = @@ERROR
End

-- Creditors
If @psSubLedger = 'AP'
Begin
	Select convert( nvarchar(254), N.NAME 
		+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' END 
		+ N.FIRSTNAME+SPACE(1)
		+ CASE WHEN N.NAMECODE IS NOT NULL THEN '{' END 
		+ N.NAMECODE
		+ CASE WHEN N.NAMECODE IS NOT NULL THEN '}' END ) as creditor, 
	SUM(CH.FOREIGNTRANVALUE) AS foreign_balance,
	SUM(CH.LOCALVALUE) AS local_balance, 
	SUM( CH.FOREIGNTRANVALUE)/ isnull(@pnExchangeRate, min(C.BUYRATE)) as new_local, 
	(SUM( CH.FOREIGNTRANVALUE)/ isnull(@pnExchangeRate, min(C.BUYRATE))) - SUM( CH.LOCALVALUE) as  difference,
	CH.CURRENCY, null ProfitCentre, null LedgerAccount

	From CREDITORHISTORY  CH
	Join NAME N ON (N.NAMENO = CH.ACCTCREDITORNO)  
	Join CURRENCY C on (C.CURRENCY = CH.CURRENCY)

	Where CH.ITEMENTITYNO = @pnEntityNo
	and CH.POSTPERIOD <= @pnPostPeriod
	and CH.CURRENCY = isnull(@psCurrency, CH.CURRENCY)
	and CH.STATUS != 0  	-- exclude draft transactions
	and CH.MOVEMENTCLASS != 9 
	-- ignore default currency transactions if currency filter is not specified.
	and 1 = (case when (@psCurrency is null and CH.CURRENCY = @sDefaultCurrency) then 0 else 1 end)

	Group By convert( nvarchar(254), N.NAME 
		+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' END 
		+ N.FIRSTNAME+SPACE(1)
		+ CASE WHEN N.NAMECODE IS NOT NULL THEN '{' END 
		+ N.NAMECODE
		+ CASE WHEN N.NAMECODE IS NOT NULL THEN '}' END ), CH.CURRENCY

	HAVING SUM(CH.FOREIGNTRANVALUE) <> 0 OR SUM(CH.LOCALVALUE) <> 0

	ORDER BY convert( nvarchar(254), N.NAME 
		+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' END 
		+ N.FIRSTNAME+SPACE(1)
		+ CASE WHEN N.NAMECODE IS NOT NULL THEN '{' END 
		+ N.NAMECODE
		+ CASE WHEN N.NAMECODE IS NOT NULL THEN '}' END ), CH.CURRENCY

	Set @nErrorCode = @@ERROR
End

If @psSubLedger = 'WIP'
Begin 
	-- Get WIP for Cases
	Set @sSql= "
		Select C.IRN, 
		SUM(WH.FOREIGNTRANVALUE)AS foreign_balance, 
		SUM(WH.LOCALTRANSVALUE) AS local_balance, 
		SUM( WH.FOREIGNTRANVALUE)/ isnull(@pnExchangeRate, min(CUR.SELLRATE)) as new_local, 
		(SUM( WH.FOREIGNTRANVALUE)/ isnull(@pnExchangeRate, min(CUR.SELLRATE))) - SUM( WH.LOCALTRANSVALUE) as  difference, 
		WH.FOREIGNCURRENCY,
		null ProfitCentre, null LedgerAccount

		From WORKHISTORY WH
		join CASES C  on C.CASEID = WH.CASEID
		Join CURRENCY CUR on (CUR.CURRENCY = WH.FOREIGNCURRENCY)
		"

	Set @sSqlWhere= "
		where WH.ENTITYNO = @pnEntityNo  
		and WH.POSTPERIOD <= @pnPostPeriod 
		and WH.FOREIGNCURRENCY = isnull(@psCurrency, WH.FOREIGNCURRENCY)
		and WH.STATUS <> 0	-- Exclude Draft WIPs
		and C.CASETYPE <> 'Y'	-- Exclude internal cases
		-- ignore default currency transactions if currency filter is not specified.
		and 1 = (case when (@psCurrency is null and WH.FOREIGNCURRENCY = @sDefaultCurrency) then 0 else 1 end)
		"

	If @psWipCode is not null
	Begin
		Set @sSqlWhereCommon = @sSqlWhereCommon + " and WH.WIPCODE in 
		(Select Parameter from dbo.fn_Tokenise('" + @psWipCode + "', NULL))"
	End
	Else 
	Begin
		If @psWipTypeId is not null
		Begin
			Set @sSqlWhereCommon = @sSqlWhereCommon + " and WTEMP.WIPTYPEID =  @psWipTypeId "
			Set @sSqlFrom = @sSqlFrom + char(10) + " left join WIPTEMPLATE WTEMP ON WTEMP.WIPCODE = WH.WIPCODE "
		End

		If @psWipCategory is not null
		Begin
			Set @sSqlWhereCommon = @sSqlWhereCommon + " and WTYPE.CATEGORYCODE in 
			(Select Parameter from dbo.fn_Tokenise('" + @psWipCategory + "', NULL))"

			If @psWipTypeId is not null
				Set @sSqlFrom = @sSqlFrom + char(10) + " left join WIPTYPE WTYPE ON WTYPE.WIPTYPEID = WTEMP.WIPTYPEID "
			Else
			Begin
				Set @sSqlFrom = @sSqlFrom + char(10) + " left join WIPTEMPLATE WTEMP ON WTEMP.WIPCODE = WH.WIPCODE "
				Set @sSqlFrom = @sSqlFrom + char(10) + " left join WIPTYPE WTYPE ON WTYPE.WIPTYPEID = WTEMP.WIPTYPEID "
			End
		End
	End

	set @sSqlGroupBy = " 
		Group By C.IRN, WH.FOREIGNCURRENCY 
		Having SUM(WH.FOREIGNTRANVALUE) <> 0"

	Set @sSql = @sSql + @sSqlFrom + @sSqlWhere + @sSqlWhereCommon +  @sSqlGroupBy

	-- Get WIP for Names
	Set @sSql= @sSql + char(10) + char(10) + "
		Union all 
	
		Select convert( nvarchar(254), N.NAME 
			+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' END 
			+ N.FIRSTNAME+SPACE(1)
			+ CASE WHEN N.NAMECODE IS NOT NULL THEN '{' END 
			+ N.NAMECODE
			+ CASE WHEN N.NAMECODE IS NOT NULL THEN '}' END ) as Name, 
		SUM(WH.FOREIGNTRANVALUE)AS foreign_balance, 
		SUM(WH.LOCALTRANSVALUE) AS local_balance, 
		SUM( WH.FOREIGNTRANVALUE)/ isnull(@pnExchangeRate, min(CUR.SELLRATE)) as new_local, 
		(SUM( WH.FOREIGNTRANVALUE)/ isnull(@pnExchangeRate, min(CUR.SELLRATE))) - SUM( WH.LOCALTRANSVALUE) as  difference,
		WH.FOREIGNCURRENCY,
		null ProfitCentre, null LedgerAccount

		From WORKHISTORY WH
		join NAME N  on N.NAMENO =WH.ACCTCLIENTNO
		Join CURRENCY CUR on (CUR.CURRENCY = WH.FOREIGNCURRENCY)
		"

	Set @sSqlWhere= "
		where WH.ENTITYNO = @pnEntityNo  
		and WH.POSTPERIOD <= @pnPostPeriod 
		and WH.FOREIGNCURRENCY = isnull(@psCurrency, WH.FOREIGNCURRENCY)
		and WH.STATUS <> 0	-- Exclude Draft WIPs
		-- ignore default currency transactions if currency filter is not specified.
		and 1 = (case when (@psCurrency is null and WH.FOREIGNCURRENCY = @sDefaultCurrency) then 0 else 1 end)
		"

	set @sSqlGroupBy = " 
		Group By convert( nvarchar(254), N.NAME 
			+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' END 
			+ N.FIRSTNAME+SPACE(1)
			+ CASE WHEN N.NAMECODE IS NOT NULL THEN '{' END 
			+ N.NAMECODE
			+ CASE WHEN N.NAMECODE IS NOT NULL THEN '}' END ), WH.FOREIGNCURRENCY 
		Having SUM(WH.FOREIGNTRANVALUE) <> 0
		Order by 1"

	Set @sSql = @sSql +  @sSqlFrom + @sSqlWhere + @sSqlWhereCommon + @sSqlGroupBy



	Exec @nErrorCode=sp_executesql @sSql, 
			N'@pnExchangeRate	decimal(11,4),
			@pnEntityNo		int,
			@pnPostPeriod		int,
			@psCurrency		nvarchar(6),
			@psWipCategory		nvarchar(30),
			@psWipTypeId		nvarchar(12),
			@psWipCode		nvarchar(4000),
			@sDefaultCurrency	nvarchar(30)',
			@pnExchangeRate		= @pnExchangeRate,
			@pnEntityNo		= @pnEntityNo,
			@pnPostPeriod		= @pnPostPeriod,
			@psCurrency		= @psCurrency,
			@psWipCategory		= @psWipCategory,
			@psWipTypeId		= @psWipTypeId,
			@psWipCode		= @psWipCode,
			@sDefaultCurrency	= @sDefaultCurrency
End


Return @nErrorCode


GO

Grant execute on dbo.gl_ListForeignTransactions to public
GO
