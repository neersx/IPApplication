-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetOpenItem] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetOpenItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetOpenItem].'
	drop procedure dbo.[biw_GetOpenItem]
end
print '**** Creating procedure dbo.[biw_GetOpenItem]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetOpenItem]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnItemEntityNo		int = null,
				@pnItemTransNo		int = null,
				@psOpenItemNo		nvarchar(2000) = null,
				@pnItemType	int = null	-- the debtor item type
as
-- PROCEDURE :	biw_GetOpenItem
-- VERSION :	25
-- DESCRIPTION:	A procedure that returns all of the details required on a formatted
--		open item such as a Debit or Credit Note.
--
-- COPYRIGHT:	Copyright 1993 - 2013 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 21/10/2009	AT	RFC3605		1	Procedure created.
-- 11/03/2010	KR	RFC8299		2	Added @pnItemTransNo and TH.LOGDATETIMESTAMP to the select
-- 24/05/2010	KR	RFC8300		3	Added PaidPercentage and RaisedBy to the select list.
-- 22/06/2010	AT	RFC8291		4	Return Credit Reason.
-- 10/08/2010	AT	RFC9403		5	Return Renewal Debtor Flag site control.
-- 16/08/2010	KR	RFC9080		6	Modified the Raise error code from AC13 to AC136
-- 06/09/2010	AT	RFC9740		7	Fixed return of write up/down values.
-- 22/10/2010	AT	RFC8354		8	Amend return of Local Decimal places.
-- 29/10/2010   MS	RFC7275		9	Corrected Errors
-- 20/01/2011	AT	RFC8983		10	Return Change Reminder Active.
-- 17/02/2011	AT	RFC8983		11	Corrected syntax error.
-- 29/03/2011	KR	RFC7956		12	Modified stored procedure to handle multiple draft bill merge.
-- 28/04/2011	AT	RFC7956		13	Changed Open Item list delimiter.
-- 23/05/2011	AT	RFC100527	14	Fixed bug with multi-debtor bills.
-- 14/06/2011	AT	RFC10814	15	Added missing collation default.
-- 12/10/2011	KR	RFC10774	16	Added code to get multi debtor bills into the #SELECTEDOPENITEMS temp table
-- 27/10/2011	AT	RFC10168	17	Return null as acct entity if inter-entity billing.
-- 30/11/2011	AT	RFC11649	18	Fix Open Item retrieval to filter by Entity Key for duplicate Open Item numbers from different entities.
-- 23/03/2012	AT	RFC12102	19	Fixed return of reason code locking bills.
-- 13/06/2012	AT	RFC11594	20	Return MainCaseId for loading of stamp fees.
-- 14/06/2012	AT	RFC12395	21	Moved bill settings to Billing Settings.
-- 22/06/2012	AT	RFC12180	22	Fixed divide by zero error for zero dollar bills.
-- 21/01/2013	AT	RFC11614	23	Return profit centre description.
-- 08/11/2013	vql	RFC27441	24	Return the correct language.
-- 02 Nov 2015	vql	R53910		25	Adjust formatted names logic (DR-15543).

set nocount on

Declare		@ErrorCode				int
Declare		@nRowCount				int
Declare		@sSQLString				nvarchar(max)
declare		@sAlertXML              nvarchar(400)
declare		@sWhereString           nvarchar(4000)
declare		@sItemTypeDescription	nvarchar(50)
declare		@sLookupCulture         nvarchar(10)
declare		@nStatus				int
declare		@bMultipleDraftOpenItem		bit

CREATE TABLE #SELECTEDOPENITEMS 
(
  ITEMSEQ INT IDENTITY(1,1),
  ITEMENTITYNO int, 
  ITEMTRANSNO int,
  OPENITEMNO nvarchar(12) collate database_default
)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @ErrorCode = 0

If (@psOpenItemNo is not null)
Begin
	--set @psOpenItemNo = replace(@psOpenItemNo, ',', ''',''')

	set @sSQLString = "Insert into #SELECTEDOPENITEMS
	Select ITEMENTITYNO, ITEMTRANSNO, OPENITEMNO
	From OPENITEM
	JOIN dbo.fn_Tokenise(@psOpenItemNo,'|') T
	ON (T.Parameter = OPENITEM.OPENITEMNO)"
	
	If @pnItemEntityNo is not null
	Begin	
		Set @sSQLString = @sSQLString + char(10) + "WHERE ITEMENTITYNO = @pnItemEntityNo"
	End

	exec @ErrorCode=sp_executesql @sSQLString, 
				N'@psOpenItemNo nvarchar(1000),
				@pnItemEntityNo int', 
				@psOpenItemNo = @psOpenItemNo,
				@pnItemEntityNo = @pnItemEntityNo
End

Else If (@psOpenItemNo is null and exists (Select 1 from OPENITEM where ITEMENTITYNO = @pnItemEntityNo and ITEMTRANSNO = @pnItemTransNo))
Begin 
	set @sSQLString = "Insert into #SELECTEDOPENITEMS
	Select ITEMENTITYNO, ITEMTRANSNO, OPENITEMNO
	From OPENITEM
	where ITEMENTITYNO = @pnItemEntityNo and ITEMTRANSNO = @pnItemTransNo"
	
	exec @ErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo int,
				@pnItemTransNo int', 
				@pnItemEntityNo = @pnItemEntityNo,
				@pnItemTransNo = @pnItemTransNo
End

--check if it is multiple draft bill merge process is on
If ((Select count(*) from #SELECTEDOPENITEMS) > 1)
Begin
	Set @bMultipleDraftOpenItem = 1
End

--select * from #SELECTEDOPENITEMS

if (not exists (Select * from #SELECTEDOPENITEMS)  and @psOpenItemNo is not null )
Begin
	-- Draft OpenItem not found
		Set @sAlertXML = dbo.fn_GetAlertXML('AC136', 'Open Item could not be found. Item has been modified or is already finalised.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @ErrorCode = @@ERROR
End

If (@ErrorCode = 0 and (@pnItemTransNo is not null or exists (Select * from #SELECTEDOPENITEMS)))
Begin
	
	Set @sSQLString = "Select @nStatus = STATUS 
				FROM OPENITEM O
				JOIN #SELECTEDOPENITEMS S ON S.ITEMENTITYNO = O.ITEMENTITYNO
							AND S.ITEMTRANSNO = O.ITEMTRANSNO
				ORDER BY S.ITEMSEQ"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nStatus	        int OUTPUT,
				  @pnItemEntityNo	int,
				  @pnItemTransNo        int',
				  @nStatus              =@nStatus OUTPUT,
				  @pnItemEntityNo       =@pnItemEntityNo,
				  @pnItemTransNo        =@pnItemTransNo

End

if (@ErrorCode = 0 and (@pnItemTransNo is not null or exists (Select * from #SELECTEDOPENITEMS)))
Begin
	Set @sSQLString = "SELECT cast(OI.ITEMENTITYNO as nvarchar(50))+'^'+cast(OI.ITEMTRANSNO as nvarchar(30))+'^'+
		cast(OI.ACCTENTITYNO as nvarchar(50))+'^'+cast(OI.ACCTDEBTORNO as nvarchar(30)) as RowKey,
		OI.ITEMENTITYNO as ItemEntityNo,
		dbo.fn_FormatNameUsingNameNo(EN1.NAMENO, null) as EntityName,
		OI.ITEMTRANSNO as ItemTransNo,
		OI.ACCTENTITYNO as AcctEntityNo,
		OI.ACCTDEBTORNO as AcctDebtorNo,
		dbo.fn_FormatNameUsingNameNo(DN.NAMENO, null) as AcctDebtorName,
		OI.ACTION as Action,
		OI.OPENITEMNO as OpenItemNo,
		OI.ITEMDATE as ItemDate,
		OI.POSTDATE as PostDate,
		OI.POSTPERIOD as PostPeriod,
		OI.CLOSEPOSTDATE as ClosePostDate,
		OI.CLOSEPOSTPERIOD as ClosePostPeriod,
		OI.STATUS as Status,
		OI.ITEMTYPE as ItemType,
		OI.BILLPERCENTAGE as BillPercentage,
		dbo.fn_FormatNameUsingNameNo(EN.NAMENO, null) as EmployeeName,
		dbo.fn_FormatNameUsingNameNo(EN.NAMENO, null) as RaisedBy,
		OI.EMPLOYEENO as EmployeeNo,
		OI.EMPPROFITCENTRE as EmpProfitCentre,
		PC.DESCRIPTION as EmpProfitCentreDescription,
		OI.CURRENCY as Currency,
		OI.EXCHRATE as ExchRate,
		OI.ITEMPRETAXVALUE as ItemPreTaxValue,
		case when ISNULL(OI.LOCALVALUE,0) = 0 THEN 100 ELSE
		cast(( OI.LOCALVALUE - OI.LOCALBALANCE ) / OI.LOCALVALUE * 100 as decimal(6,2))
		END as PaidPercentage,		
		OI.LOCALTAXAMT as LocalTaxAmt,
		OI.LOCALVALUE as LocalValue,
		OI.FOREIGNTAXAMT as ForeignTaxAmt,
		OI.FOREIGNVALUE as ForeignValue,
		OI.LOCALBALANCE as LocalBalance,
		OI.LOCALVALUE - OI.LOCALBALANCE as CreditAmount,
		OI.FOREIGNBALANCE as ForeignBalance,
		OI.EXCHVARIANCE as ExchVariance,
		
		LTRIM(RTRIM(OI.STATEMENTREF)) as 'StatementRef',
		" + dbo.fn_SqlTranslatedColumn('OPENITEM','REFERENCETEXT','LONGREFTEXT','OI',@sLookupCulture,@pbCalledFromCentura) + " as 'ReferenceText',
		
		OI.NAMESNAPNO as NameSnapNo,
		OI.BILLFORMATID as BillFormatId,
		OI.BILLPRINTEDFLAG as BillPrintedFlag,		
		
		" + dbo.fn_SqlTranslatedColumn('OPENITEM','REGARDING','LONGREGARDING','OI',@sLookupCulture,@pbCalledFromCentura) + " as 'Regarding',
		" + dbo.fn_SqlTranslatedColumn('OPENITEM','SCOPE',null,'OI',@sLookupCulture,@pbCalledFromCentura) + " as 'Scope',
		
		OI.LANGUAGE as LanguageKey,
		L.DESCRIPTION as LanguageDescription,
		OI.ASSOCOPENITEMNO as AssocOpenItemNo,
		OI.IMAGEID as ImageId,
		OI.FOREIGNEQUIVCURRCY as ForeignEquivCurrcy,
		OI.FOREIGNEQUIVEXRATE as ForeignEquivExRate,
		OI.ITEMDUEDATE as ItemDueDate,
		OI.PENALTYINTEREST as PenaltyInterest,
		OISUM.LOCALORIGTAKENUP as LocalOrigTakenUp,
		OI.FOREIGNORIGTAKENUP as ForeignOrigTakenUp,
		OI.INCLUDEONLYWIP as IncludeOnlyWIP,
		OI.PAYFORWIP as PayForWIP,
		OI.PAYPROPERTYTYPE as PayPropertyType,
		isnull(OI.RENEWALDEBTORFLAG,0) as 'RenewalDebtorFlag',
		RDS.COLBOOLEAN as 'CanUseRenewalDebtor',
		OI.CASEPROFITCENTRE as CaseProfitCentre,
		OI.LOCKIDENTITYID as LockIdentityId,
		OISUM.BILLTOTAL as 'BillTotal',
		isnull(W.WRITEDOWN, cast(0 as decimal(11,2))) as 'WriteDown',
		isnull(W.WRITEUP, cast(0 as decimal(11,2))) as 'WriteUp',
		TH.LOGDATETIMESTAMP as 'LogDateTimeStamp',
		C.CURRENCY as 'LocalCurrencyCode',
		CASE WHEN CWU.COLBOOLEAN = 1 THEN 0 ELSE ISNULL(C.DECIMALPLACES,2) END as 'LocalDecimalPlaces',
		ISNULL(FC.DECIMALPLACES,2) as 'ForeignDecimalPlaces',
		FC.ROUNDBILLEDVALUES AS 'RoundBillValues',
		DH.REASONCODE AS 'CreditReason',
		case when DH.REASONCODE is not null and isnull(DWWD.REASONCODE, WWD.REASONCODE) is null then 0 else 1 end as 'WriteDownWIP',
		isnull(DWWD.REASONCODE, WWD.REASONCODE) as 'WriteDownReason',"
		+ char(10) + dbo.fn_SqlTranslatedColumn('DEBTOR_ITEM_TYPE','DESCRIPTION',null,'DIT',@sLookupCulture,@pbCalledFromCentura)
		+ char(10) + " as 'ItemTypeDescription',
		OI.MAINCASEID AS 'MainCaseKey'"

        	Set @sSQLString = @sSQLString + nchar(10) +
		" from OPENITEM OI
		Join TRANSACTIONHEADER TH on (TH.ENTITYNO = OI.ITEMENTITYNO and TH.TRANSNO = OI.ITEMTRANSNO)
		Join DEBTOR_ITEM_TYPE DIT on (DIT.ITEM_TYPE_ID = OI.ITEMTYPE)
		Join (Select SUM(ISNULL(ITEMPRETAXVALUE, LOCALVALUE)) AS BILLTOTAL, SUM(LOCALORIGTAKENUP) AS LOCALORIGTAKENUP, O.ITEMTRANSNO, O.ITEMENTITYNO
				From OPENITEM O
				JOIN #SELECTEDOPENITEMS SOI on (O.ITEMENTITYNO = SOI.ITEMENTITYNO and O.ITEMTRANSNO = SOI.ITEMTRANSNO)
				GROUP BY O.ITEMTRANSNO, O.ITEMENTITYNO)
			as OISUM on (OISUM.ITEMTRANSNO = OI.ITEMTRANSNO
				and OISUM.ITEMENTITYNO = OI.ITEMENTITYNO)
		left join NAME EN ON (OI.EMPLOYEENO = EN.NAMENO)
		join NAME EN1 ON (OI.ITEMENTITYNO = EN1.NAMENO)
		join NAME DN ON (OI.ACCTDEBTORNO = DN.NAMENO)
		Join SITECONTROL S on (S.CONTROLID = 'CURRENCY')
		join CURRENCY C on (S.COLCHARACTER = C.CURRENCY)
		left join CURRENCY FC on (OI.CURRENCY = FC.CURRENCY)
		join SITECONTROL RDS on (RDS.CONTROLID = 'Bill Renewal Debtor')
		join SITECONTROL CWU on (CWU.CONTROLID = 'Currency Whole Units')
		Join #SELECTEDOPENITEMS SOI on (OI.ITEMENTITYNO = SOI.ITEMENTITYNO
							and OI.ITEMTRANSNO = SOI.ITEMTRANSNO
							and OI.OPENITEMNO = SOI.OPENITEMNO)
		left join PROFITCENTRE PC ON PC.PROFITCENTRECODE = OI.EMPPROFITCENTRE"

		if (@nStatus = 0 or @bMultipleDraftOpenItem=1)
		Begin
			Set @sSQLString = @sSQLString + char(10) +
				"left join (select ENTITYNO, TRANSNO, 
					sum(CASE WHEN ADJUSTEDVALUE < 0 THEN ADJUSTEDVALUE ELSE 0 END) as WRITEDOWN,
					sum(CASE WHEN ADJUSTEDVALUE > 0 THEN ADJUSTEDVALUE ELSE 0 END) as WRITEUP
					from BILLEDITEM
					GROUP BY ENTITYNO, TRANSNO) as W on (W.ENTITYNO = OI.ITEMENTITYNO 
									AND W.TRANSNO = OI.ITEMTRANSNO)"
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + char(10) +
				"left join (SELECT REFENTITYNO AS ENTITYNO, REFTRANSNO AS TRANSNO,
					sum(CASE WHEN MOVEMENTCLASS = 3 AND COMMANDID = 4 AND LOCALTRANSVALUE < 0 THEN LOCALTRANSVALUE * -1 ELSE 0 END) as WRITEDOWN,
					sum(CASE WHEN MOVEMENTCLASS = 9 AND COMMANDID = 7 AND LOCALTRANSVALUE > 0 THEN LOCALTRANSVALUE ELSE 0 END) as WRITEUP
					FROM WORKHISTORY
					GROUP BY REFENTITYNO, REFTRANSNO) as W on (W.ENTITYNO = OI.ITEMENTITYNO 
									AND W.TRANSNO = OI.ITEMTRANSNO)"
		End
		
		Set @sSQLString = @sSQLString + char(10) +
		"left join TABLECODES L on (L.TABLECODE = OI.LANGUAGE)
		left join DEBTORHISTORY DH on (DH.ITEMTRANSNO = OI.ITEMTRANSNO 
					AND DH.ITEMENTITYNO = OI.ITEMENTITYNO 
					AND DH.ACCTENTITYNO = OI.ACCTENTITYNO 
					AND DH.ACCTDEBTORNO = OI.ACCTDEBTORNO
					and DH.MOVEMENTCLASS = 1
					AND DH.COMMANDID = 1
					AND DH.ITEMIMPACT = 1)
		
		-- WIP raised under the bill (Draft WIP Write Down)
		left join (SELECT DISTINCT BI.REASONCODE, BI.ITEMENTITYNO, BI.ITEMTRANSNO
			FROM BILLEDITEM BI
			JOIN WORKHISTORY WH ON 
				(WH.ENTITYNO = WH.REFENTITYNO
				AND WH.TRANSNO = WH.REFTRANSNO
				AND WH.ENTITYNO = BI.WIPTRANSNO
				AND WH.TRANSNO = BI.WIPTRANSNO
				AND WH.WIPSEQNO = BI.WIPSEQNO)
			JOIN #SELECTEDOPENITEMS SBI on (BI.ITEMENTITYNO = SBI.ITEMENTITYNO and BI.ITEMTRANSNO = SBI.ITEMTRANSNO)
			) as DWWD on (DWWD.ITEMENTITYNO = OI.ITEMENTITYNO AND DWWD.ITEMTRANSNO = OI.ITEMTRANSNO)

		left join (SELECT distinct REASONCODE, ENTITYNO, TRANSNO FROM WORKHISTORY WH
			JOIN #SELECTEDOPENITEMS SWH on (WH.ENTITYNO = SWH.ITEMENTITYNO
							AND WH.TRANSNO = SWH.ITEMTRANSNO)
			WHERE WH.MOVEMENTCLASS = 3 AND WH.COMMANDID = 4) as WWD on (WWD.ENTITYNO = OI.ITEMENTITYNO AND WWD.TRANSNO = OI.ITEMTRANSNO)
		ORDER BY SOI.ITEMSEQ"
		

		--print @sSQLString

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOpenItemNo	nvarchar(12),
					  @pnItemEntityNo	int,
					  @pnItemTransNo int',
					  @psOpenItemNo=@psOpenItemNo,
					  @pnItemEntityNo=@pnItemEntityNo,
					  @pnItemTransNo=@pnItemTransNo
					  
End
Else If (@ErrorCode = 0 and @psOpenItemNo is null and @pnItemTransNo is null )
Begin
	If (@ErrorCode = 0)
	Begin
		Set @sSQLString = "select @sItemTypeDescription = " +
			dbo.fn_SqlTranslatedColumn('DEBTOR_ITEM_TYPE','DESCRIPTION',null,null,@sLookupCulture,@pbCalledFromCentura) + 
			char(10) + "from DEBTOR_ITEM_TYPE
				where ITEM_TYPE_ID = @pnItemType"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sItemTypeDescription nvarchar(50) output,
					  @pnItemType	int',
					  @sItemTypeDescription = @sItemTypeDescription output,
					  @pnItemType = @pnItemType
	End

	If (@ErrorCode = 0)
	Begin
			Set @sSQLString = "SELECT TOP 1
				case when ISNULL(IEB.COLBOOLEAN,0) = 0 THEN SCENTITY.COLINTEGER ELSE NULL END as ItemEntityNo,
				null as ItemTransNo,
				case when ISNULL(IEB.COLBOOLEAN,0) = 0 THEN SCENTITY.COLINTEGER ELSE NULL END as AcctEntityNo,
				null as AcctDebtorNo,
				null as Action,
				null as OpenItemNo,
				GETDATE() as ItemDate,
				null as PostDate,
				null as PostPeriod,
				null as ClosePostDate,
				null as ClosePostPeriod,
				0 as Status,
				null as ItemType,
				null as BillPercentage,
				dbo.fn_FormatNameUsingNameNo(EN.NAMENO, null) as EmployeeName,
				EN.NAMENO as EmployeeNo,
				EM.PROFITCENTRECODE as EmpProfitCentre,
				PC.DESCRIPTION as EmpProfitCentreDescription,
				null as Currency,
				null as ExchRate,
				null as ItemPreTaxValue,
				null as LocalTaxAmt,
				null as LocalValue,
				null as ForeignTaxAmt,
				null as ForeignValue,
				null as LocalBalance,
				null as ForeignBalance,
				null as ExchVariance,
				null as StatementRef,
				null as ReferenceText,
				null as NameSnapNo,
				null as BillFormatId,
				null as BillPrintedFlag,
				null as Regarding,
				null as Scope,
				null as LanguageKey,
				null as LanguageDescription,
				null as AssocOpenItemNo,
				null as ImageId,
				null as ForeignEquivCurrcy,
				null as ForeignEquivExRate,
				null as ItemDueDate,
				null as PenaltyInterest,
				null as LocalOrigTakenUp,
				null as ForeignOrigTakenUp,
				null as IncludeOnlyWIP,
				null as PayForWIP,
				null as PayPropertyType,
				0 as 'RenewalDebtorFlag',
				RDS.COLBOOLEAN as 'CanUseRenewalDebtor',
				null as CaseProfitCentre,
				null as LockIdentityId,
				null  as 'BillTotal',
				cast(0 as decimal(11,2)) as 'WriteDown',
				cast(0 as decimal(11,2)) as 'WriteUp',
				null as 'LogDateTimeStamp',
				C.CURRENCY as 'LocalCurrencyCode',
				CASE WHEN CWU.COLBOOLEAN = 1 THEN 0 ELSE ISNULL(C.DECIMALPLACES,2) END as 'LocalDecimalPlaces',
				null as 'ForeignDecimalPlaces',
				null as 'RoundBillValues',
				null as 'CreditReason',
				0 as 'WriteDownWIP',
				null as 'WriteDownReason',
				@sItemTypeDescription as 'ItemTypeDescription',
				null AS 'MainCaseKey'
				FROM USERIDENTITY UI
				join NAME EN ON (UI.NAMENO = EN.NAMENO)
				join EMPLOYEE EM ON (EM.EMPLOYEENO = EN.NAMENO)
				Join SITECONTROL S on (S.CONTROLID = 'CURRENCY')
				join CURRENCY C on (S.COLCHARACTER = C.CURRENCY)
				left join PROFITCENTRE PC ON PC.PROFITCENTRECODE = EM.PROFITCENTRECODE,
				SITECONTROL SCENTITY,
				SITECONTROL RDS,
				SITECONTROL CWU,
				SITECONTROL IEB
				Where SCENTITY.CONTROLID = 'HOMENAMENO'
				and UI.IDENTITYID = @pnUserIdentityId
				and RDS.CONTROLID = 'Bill Renewal Debtor'
				AND CWU.CONTROLID = 'Currency Whole Units'
				AND IEB.CONTROLID = 'Inter-Entity Billing'"

				exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnUserIdentityId	int,
							@sItemTypeDescription nvarchar(50)',
							  @pnUserIdentityId=@pnUserIdentityId,
							  @sItemTypeDescription=@sItemTypeDescription
	End
End

-- Get potential XML data
-- For merged items, only get the XML data when the bill formats are the same.
If (@ErrorCode = 0 and exists(Select * from #SELECTEDOPENITEMS))
Begin
	Set @sSQLString = "Select O.ITEMENTITYNO AS 'ItemEntityNo', O.ITEMTRANSNO as 'ItemTransNo', 
				XMLTYPE as 'XMLType', OPENITEMXML as 'OpenItemXML' 
			From OPENITEMXML O
			JOIN #SELECTEDOPENITEMS S on (O.ITEMENTITYNO = S.ITEMENTITYNO
						and O.ITEMTRANSNO = S.ITEMTRANSNO)
			JOIN OPENITEM OI ON (OI.ITEMENTITYNO = O.ITEMENTITYNO
					AND OI.ITEMTRANSNO = O.ITEMTRANSNO)
			WHERE OI.BILLFORMATID = (SELECT OIX.BILLFORMATID FROM OPENITEM OIX
						JOIN #SELECTEDOPENITEMS SX ON (SX.ITEMENTITYNO = OIX.ITEMENTITYNO
									and SX.ITEMTRANSNO = OIX.ITEMTRANSNO
									and SX.OPENITEMNO = OIX.OPENITEMNO)
						WHERE SX.ITEMSEQ = 1)
			order by XMLTYPE"

	exec @ErrorCode=sp_executesql @sSQLString
End

DROP TABLE #SELECTEDOPENITEMS

return @ErrorCode
go

grant execute on dbo.[biw_GetOpenItem]  to public
go