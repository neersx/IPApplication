-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListAccountTransactions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_ListAccountTransactions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_ListAccountTransactions.'
	drop procedure dbo.gl_ListAccountTransactions
end
print '**** Creating procedure dbo.gl_ListAccountTransactions...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

create procedure dbo.gl_ListAccountTransactions
(
	@pnRowCount			int output,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnAcctEntity 			int, 
	@psProfitCentreCodes		ntext		= null,
	@psAccountIds 			ntext, 			-- 10821 changed from nvarchar(3000) passed as XML 
	@psAccounts 			ntext		= null, -- 10821 additional to cater for simplier 
								-- account enquiries
	@pnPeriodFrom 			int, 
	@pnPeriodTo 			int,
	@pnAnalysisTypeId		int 		= null,
	@psAnalysisCodeIds		ntext	 	= null,

	@pdDateFrom			datetime	= null,		-- SQA16565
	@pdDateTo			datetime	= null,		-- SQA16565
	@psDescription			nvarchar(508)	= null,		-- SQA16565
	@psCurrency			nvarchar(6)	= null,		-- SQA16565
	@pnAmountFrom			Decimal (11,2)	= null,		-- SQA16565	
	@pnAmountTo			Decimal (11,2)	= null		-- SQA16565
)
AS
-- PROCEDURE :	gl_ListAccountTransactions
-- VERSION :	21
-- DESCRIPTION:	List ledger entries in the specified criteria
-- CALLED BY :	FCDBLedgerJournalLineX (Centura)
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 2.5.03	MB			Created
-- 2.5.03	MB 	8385		Excluded clearing transactions (812)
-- 6.6.03	MB 			Included type 812 for Assets, Equity and Liability
-- 26.6.03	MB 	8806
-- 01.9.03	SFOO			Include Profit Centre Analysis Rules for sorting result.
-- 08/10/2003	AB			Replace ALTER PROC with DROP PROC and CREATE PROC. 
--					Necessary for automated allstandardprocs.sql. Add grant execute rights.
-- 13/01/2004	SFOO			Allow large number of ledger account ids by using XML to temp table
-- 04/02/2004	SS	8856 		Modified to include foreign amount and currency.
-- 11/02/2004	SFOO	9614		Change the way gl_TraverseAccount is called so that an unique global temp table 
--			8851		is kept at this level. To prevent one or more user assessing the same global temp
--					table. Also removed the CURSOR for looping distinct periodids. 
-- 06 Aug 2004	AB	8035	10	Add collate database_default to temp table definitions
-- 04 Feb 2005	CR	10821	11	Changed the Account Id list received from comma separted list to XML
-- 23 Feb 2005	MB	10821	12	Now may be used with either a comma separated list or an XML document of Account Ids.
--					So that this is backwards compatible with the other stored procedures that call it.
-- 18 Mar 2005	MB	11113	13	Imroved NULL testing for @psAccountIds variable
-- 19 Sep 2007	CR	14722	14	Change @psProfitCentreCodes, @psAccounts and @psAnalysisCodeIds to ntext and added code 
--					to convert back to nvarchar before subsequently using.
-- 19 Sep 2007	CR	15233		Extended to return EntityNo also to better cater for inter-entity transactions.					
-- 23 Sep 2009	DL	16565	15	Added new filter: Date Range, Amount Range, Description, Currency 
-- 30 Jan 2013	DL	12263	16	Retrieve the Journal Line Notes for display on the Account enquiry screen	
-- 08 Apr 2013	DL	21300	17	The Year End Rollover transaction are not showing in the Retained Earnings account
-- 27 Feb 2014	DL	S21508	18	Change variables and temp table columns that reference namecode to 20 characters
-- 15 May 2015	MF	47592	19	GL Account enquiry is duplicating the transactions returned.
-- 02 Oct 2015	DL	53416	20	Missing General Ledger Transaction when running account enquiry
-- 05 Mar 2019	DL	DR-46506 21	Account Enquiry response is slow when more than one account selected


Begin
	SET CONCAT_NULL_YIELDS_NULL OFF

	declare @sRelAcctTempTable 	nvarchar(128)
	declare @sSql 			nvarchar(4000)
	declare @sProfitCentreCodes 	nvarchar(2000)
	declare @sAccounts 		nvarchar(3000)
	declare @sAnalysisCodeIds	nvarchar(1000)
	declare	@ErrorCode int
	declare	@sJournalFilter nvarchar(4000)
	declare @sLocalCurrency	nvarchar(3)


	Set @sSql = ''
	Set	@ErrorCode = 0


	CREATE TABLE #LEDGERACCOUNTIDTOQUERY (
		Value int )
	set @ErrorCode = @@Error

	Set @sProfitCentreCodes = CAST(@psProfitCentreCodes AS nvarchar(2000))
	If @sProfitCentreCodes = ''
		Set @sProfitCentreCodes = NULL

	Set @sAccounts = CAST(@psAccounts AS nvarchar(3000))
	If @sAccounts = ''
		Set @sAccounts = NULL


	Set @sAnalysisCodeIds = CAST(@psAnalysisCodeIds AS nvarchar(1000))
	If @sAnalysisCodeIds = ''
		Set @sAnalysisCodeIds = NULL

	-- SQA16565  build where clause for journal filter
	If @ErrorCode = 0
	Begin
		Set @sJournalFilter = ''
		-- Get Local currency
		Select @sLocalCurrency = UPPER(COLCHARACTER)
		from 	SITECONTROL 
		where   CONTROLID = 'CURRENCY'

		If @pdDateFrom is not null
			Set @sJournalFilter = @sJournalFilter + " And dbo.fn_DateOnly(tr.TRANSDATE)  >= '" + convert(nvarchar(11), @pdDateFrom) + "' "    

		If @pdDateTo is not null
			Set @sJournalFilter = @sJournalFilter + " And dbo.fn_DateOnly(tr.TRANSDATE)  <= '" + convert(nvarchar(11), @pdDateTo) + "' "  

		-- journal description
		If @psDescription is not null
		Begin
			If CHARINDEX('%', @psDescription) > 0
				Set @sJournalFilter = @sJournalFilter + " And lj.DESCRIPTION like '" + @psDescription + "'"  
			Else
				Set @sJournalFilter = @sJournalFilter + " And lj.DESCRIPTION = '" + @psDescription + "'"  
		End
		
		-- foreign currency
		If @psCurrency is not null and @psCurrency <> @sLocalCurrency
		Begin
			Set @sJournalFilter = @sJournalFilter + " And  jl.CURRENCY = '" + @psCurrency + "'"  
			If @pnAmountFrom is not null
				Set @sJournalFilter = @sJournalFilter + " And  jl.FOREIGNAMOUNT  >= " + cast(@pnAmountFrom as nvarchar(20))  
			If @pnAmountTo is not null
				Set @sJournalFilter = @sJournalFilter + " And  jl.FOREIGNAMOUNT  <= " + cast(@pnAmountTo as nvarchar(20))
		End
		-- local currency
		Else Begin
			If @pnAmountFrom is not null
				Set @sJournalFilter = @sJournalFilter + " And  jl.LOCALAMOUNT  >= " + cast(@pnAmountFrom as nvarchar(20))    
			If @pnAmountTo is not null
				Set @sJournalFilter = @sJournalFilter + " And  jl.LOCALAMOUNT  <= " + cast(@pnAmountTo as nvarchar(20))  
		End
	End	
	
	if @ErrorCode = 0
	Begin
		CREATE TABLE #TEMPACCOUNTS ( 
			NAMENO 			Int, 
			NAMECODE 		varchar(20) collate database_default, 
			NAME 			varchar(254) collate database_default,
			PROFITCENTRECODE 	varchar(6) collate database_default, 
			PROFITCENTREDESC 	varchar(50) collate database_default,
			ACCOUNTID 		Int, 
			CHARTOFACCOUNTSCODE	nvarchar(20) collate database_default, 
			CHARTOFACCOUNTSDESC 	nvarchar(100) collate database_default
			)
		set @ErrorCode = @@Error
	End

	if @ErrorCode = 0
	begin
		CREATE INDEX ind_TEMPACCOUNTSID
		ON #TEMPACCOUNTS ( ACCOUNTID ) 
		Set @ErrorCode = @@ERROR
	end

	If @ErrorCode = 0
	Begin
		If  (datalength(@psAccountIds) = 0
		 or  datalength(@psAccountIds) is null)
			Exec @ErrorCode = gl_ListToLedgerAcctTempTable @psLedgerAccountIds=@sAccounts, 
						@psTempTableName=N'#LEDGERACCOUNTIDTOQUERY'
		Else
			Exec @ErrorCode = gl_XMLToLedgerAcctTempTable @psLedgerAccountIds=@psAccountIds, 
						@psTempTableName=N'#LEDGERACCOUNTIDTOQUERY'
	End

	If @ErrorCode = 0
	Begin
		If (@sProfitCentreCodes IS NULL) or (@sProfitCentreCodes = '')
			Set @sSql = '
					INSERT 
						INTO #TEMPACCOUNTS 
					SELECT 	N.NAMENO, N.NAMECODE, N.NAME,
	 					PC.PROFITCENTRECODE, PC.DESCRIPTION,
						LA.ACCOUNTID, LA.ACCOUNTCODE, LA.DESCRIPTION 
					FROM 
						NAME N
							CROSS JOIN
						PROFITCENTRE PC
							CROSS JOIN
						#LEDGERACCOUNTIDTOQUERY LATQ
							INNER JOIN
						LEDGERACCOUNT LA ON (LA.ACCOUNTID = LATQ.Value)
					WHERE 
						N.NAMENO = ' + CONVERT(nvarchar(12), @pnAcctEntity) + ' AND 
						PC.ENTITYNO = ' + CONVERT(nvarchar(12), @pnAcctEntity)
		Else
			Set @sSql = '
					INSERT 
						INTO #TEMPACCOUNTS 
					SELECT 	N.NAMENO, N.NAMECODE, N.NAME,
	 					PC.PROFITCENTRECODE, PC.DESCRIPTION,
						LA.ACCOUNTID, LA.ACCOUNTCODE, LA.DESCRIPTION 
					FROM 
						NAME N
							CROSS JOIN
						PROFITCENTRE PC
							CROSS JOIN
						#LEDGERACCOUNTIDTOQUERY LATQ
							INNER JOIN
						LEDGERACCOUNT LA ON (LA.ACCOUNTID = LATQ.Value)
					WHERE 
						N.NAMENO = ' + CONVERT(nvarchar(12), @pnAcctEntity) + ' AND
						PC.PROFITCENTRECODE in (' + @sProfitCentreCodes + ') '

		
		exec sp_executesql @sSql
		set @ErrorCode=@@Error
		
		if @ErrorCode = 0
			exec @ErrorCode = gl_TraverseAccount '#TEMPACCOUNTS', @sRelAcctTempTable Output
		
		if @ErrorCode = 0
			set @sSql = '
				     SELECT ' + 
					dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentreCodes,
										   @pnAnalysisTypeId,
										   @sAnalysisCodeIds,
										   'SELECT',
										   NULL) +
					  ' dt.NAMENO, dt.NAME, dt.NAMECODE,
				     	    dt.PROFITCENTRECODE, dt.PROFITCENTREDESC,
				     	    dt.ACCOUNTID, dt.ACCOUNTCODE,
				     	    dt.LEDGERACCOUNTDESC,
				     	    dt.TRANSTYPEDESC,
				     	    dt.TRANSDATE,
				     	    dt.LEDGERJOURNALDESC,
					    dt.ENTITYNO,
				     	    dt.TRANSNO,
				     	    dt.LOCALAMOUNT,
					    dt.FOREIGNAMOUNT,
					    dt.CURRENCY,
					    dt.NOTES 
				     FROM 
					(SELECT DISTINCT
						a.NAMENO 		as NAMENO,
						a.NAME 			as NAME, 
						a.NAMECODE 		as NAMECODE, 
						a.PROFITCENTRECODE 	as PROFITCENTRECODE,
						a.PROFITCENTREDESC 	as PROFITCENTREDESC,
						la.ACCOUNTID 		as ACCOUNTID, 
						la.ACCOUNTCODE 		as ACCOUNTCODE,
						la.DESCRIPTION 		as LEDGERACCOUNTDESC,
						att.DESCRIPTION 	as TRANSTYPEDESC,
						tr.TRANSDATE 		as TRANSDATE,
						lj.DESCRIPTION 		as LEDGERJOURNALDESC,
						tr.ENTITYNO		as ENTITYNO,
						tr.TRANSNO 		as TRANSNO,
						LOCALAMOUNT 		as LOCALAMOUNT,
						FOREIGNAMOUNT		as FOREIGNAMOUNT,
						CURRENCY		as CURRENCY,
						jl.NOTES as NOTES,
						jl.SEQNO			
					FROM 
						#TEMPACCOUNTS a
					join	'+ @sRelAcctTempTable + ' b on (b.PARENTID=a.ACCOUNTID)
					join LEDGERACCOUNT la		on (la.ACCOUNTID=b.CHILDID)  
					join TRANSACTIONHEADER tr	on (tr.ENTITYNO=a.NAMENO)
					join LEDGERJOURNAL lj		on (lj.ENTITYNO=tr.ENTITYNO
												and lj.TRANSNO =tr.TRANSNO)
					join LEDGERJOURNALLINE jl	on (jl.ENTITYNO = lj.ENTITYNO
											and jl.TRANSNO = lj.TRANSNO
									and jl.ACCTENTITYNO    =a.NAMENO
									and jl.PROFITCENTRECODE=a.PROFITCENTRECODE
									and jl.ACCOUNTID       =b.CHILDID)
					join ACCT_TRANS_TYPE att	on (att.TRANS_TYPE_ID=tr.TRANSTYPE)
		 			WHERE
						tr.TRANPOSTPERIOD BETWEEN ' + CONVERT(nvarchar(12), @pnPeriodFrom) + 
						' AND ' + CONVERT(nvarchar(12), @pnPeriodTo) + ' AND
						-- sqa21300 Exclude clearing transactions (812) except the default control account - Retained Earnings
						--tr.TRANSTYPE <> 812 AND 
						 not exists 
							(SELECT *
							FROM LEDGERJOURNALLINE LJL 
							LEFT JOIN DEFAULTACCOUNT DA  ON (DA.ACCOUNTID = LJL.ACCOUNTID AND DA.PROFITCENTRECODE = LJL.PROFITCENTRECODE)  
							WHERE LJL.TRANSNO = jl.TRANSNO
							and LJL.ENTITYNO = jl.ENTITYNO 
							and LJL.SEQNO = jl.SEQNO 
							and tr.TRANSTYPE = 812							-- clearing transactions (812)
							AND isnull(DA.CONTROLACCTYPEID, '''') <> 8707)	-- default control account - Retained Earnings						
						and 

						tr.TRANSTATUS = 1 
						'+  @sJournalFilter + ' ) dt ' + 
						
						dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentreCodes,
										   @pnAnalysisTypeId,
										   @sAnalysisCodeIds,
										   'FROM',
										   'dt.PROFITCENTRECODE') +
					' ORDER BY ' +
						dbo.fn_IncludeProfitCentreAnalysis(@sProfitCentreCodes,
										   @pnAnalysisTypeId,
										   @sAnalysisCodeIds,
										   'ORDER',
										   NULL) +
					' dt.PROFITCENTREDESC, dt.LEDGERACCOUNTDESC, dt.TRANSDATE'

		exec sp_executesql @sSql
		Set @pnRowCount = @@Rowcount
		set @ErrorCode=@@Error
	end
	
	If @ErrorCode=0
	Begin
		drop table #TEMPACCOUNTS
		drop table #LEDGERACCOUNTIDTOQUERY

		Set @sSql = 'drop table ' + @sRelAcctTempTable
		Exec sp_executesql @sSql
	End

	return @ErrorCode
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.gl_ListAccountTransactions to public
go

