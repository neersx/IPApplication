-----------------------------------------------------------------------------------------------------------------------------
-- Creation of rpt_ListARWIPCollections
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[rpt_ListARWIPCollections]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.rpt_ListARWIPCollections.'
	Drop procedure [dbo].[rpt_ListARWIPCollections]
End
Print '**** Creating Stored Procedure dbo.rpt_ListARWIPCollections...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[rpt_ListARWIPCollections]
				@psFromPeriodID	Varchar(254),
				@psToPeriodID	Varchar(254),
				@psClientCode	Varchar(254),
				@psFromDate	Varchar(254),
				@psToDate	Varchar(254)
as 
-- PROCEDURE :	rpt_ListARWIPCollections
-- VERSION :	13
-- DESCRIPTION:	Display the WIP that has been collected in a period range.
--		Include remittance; credit allocation; AR/AP offset
-- CALLED BY :	MS Excel

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12/9/2014	MAF			Procedure created
-- 24/12/2014	AGK			Added parameter Clientcode and Fields for Clientcode, ClientName, Changed Par Name @psDebtorCode to @psClientCode(For Consistency)
-- 29/12/2014	AGK			Added Field Profit Center for TimeKeeper and State of the Debtor Address
-- 30/12/2014	AGK			Added Field Billing Attorney, Docket Responsible names, Owner, Assignee and Division/Location
-- 20/01/2015	MAF			Add Prepayments and Unallocated Cash as these represent revenue
-- 27/02/2015	MAF			Add the invoice address to see the State; Add Local Client Flag
-- 16/03/2015	MAF			Add Post Period and exclude Debtor Write Offs
-- 30/04/2014	MAF			Change the sign of WIPPAYMENT LOCALTRANSVALUE field
-- 19/05/2015	MAF			Add Debtor Country and Invoice Country
-- 11/02/2016	MAF			Add SABIC attribute fields
-- 02/03/2016	MAF			Change the Client Code parameter so that it works on Debtor Code as well
-- 09/08/2016	MAF			Include From and To Date in Parameter for the remittance date
--					Include Remittance Date
--					Allow Periods to be WildCard
-- 10/08/2016	MAF			Add Case Category
-- 12/08/2016	MAF			Add Case Profit Centre
-- 10/10/2016	MAF			Fix joins for Table Attributes where there is more than one attribute against a case
-- 11/12/2017	MAF			Include Item Date
-- 01 Feb 2017	MF	73362	13	Bring this client specific stored procedure into the main product.

-- set server options
set NOCOUNT on
SET CONCAT_NULL_YIELDS_NULL OFF

declare @nErrorCode		int
declare @nFromPeriodID		int
declare @nToPeriodID		int
declare @dFromDate		datetime
declare @dToDate		datetime
declare	@sSQLString		nvarchar(max)
declare @sWhere1		varchar(max)	-- Deliberately using VARCHAR to avoid a truncation issue after concatenation with @sSQLString
declare @sWhere2		varchar(max)	-- Deliberately using VARCHAR to avoid a truncation issue after concatenation with @sSQLString

Set @nErrorCode	= 0
Set @sWhere1	= ''
Set @sWhere2	= ''

----------------------------------
-- If an explicit Client Code
-- has been provided, then 
-- filter the results accordingly.
---------------------------------- 
If  @psClientCode is not null
and @psClientCode <> '%'
Begin
	Set @sWhere1 = "
	AND (NI.NAMECODE = @psClientCode 
		or  N.NAMECODE = @psClientCode )"
		  
	Set @sWhere2 = "
	AND  N.NAMECODE = @psClientCode"
End

----------------------------------
-- If an explicit Period range 
-- has been provided, then 
-- filter the results accordingly.
---------------------------------- 
if  @psFromPeriodID is not null
and @psFromPeriodID <> '%'
Begin
	Set @sSQLString="
		select @nFromPeriodID = PERIODID 
		from PERIOD 
		where LABEL = @psFromPeriodID"

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@nFromPeriodID	int		OUTPUT,
					  @psFromPeriodID	nvarchar(254)',
					  @nFromPeriodID =@nFromPeriodID	OUTPUT,
					  @psFromPeriodID=@psFromPeriodID

	If @nFromPeriodID is not null
	Begin
		Set @sWhere1 = @sWhere1 + char(10)+ "	AND TH.TRANPOSTPERIOD >= @nFromPeriodID"

		Set @sWhere2 = @sWhere2 + char(10)+ "	AND DH.POSTPERIOD >= @nFromPeriodID"
	End
end

If  @nErrorCode=0
and @psToPeriodID is not null
and @psToPeriodID <> '%'
Begin
	Set @sSQLString="
		select @nToPeriodID = PERIODID 
		from PERIOD 
		where LABEL = @psToPeriodID"

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@nToPeriodID		int		OUTPUT,
					  @psToPeriodID		nvarchar(254)',
					  @nToPeriodID =@nToPeriodID		OUTPUT,
					  @psToPeriodID=@psToPeriodID

	If @nToPeriodID is not null
	Begin
		Set @sWhere1 = @sWhere1 + char(10)+ "	AND TH.TRANPOSTPERIOD <= @nToPeriodID"

		Set @sWhere2 = @sWhere2 + char(10)+ "	AND DH.POSTPERIOD <= @nToPeriodID"
	End
End
	

----------------------------------
-- If an explicit Date range 
-- has been provided, then 
-- filter the results accordingly.
---------------------------------- 
If  @nErrorCode=0
and @psFromDate is not null
and @psFromDate <> ''
Begin
	Set @sSQLString="
		select @dFromDate = convert(datetime, @psFromDate, 101)"

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@dFromDate		datetime	OUTPUT,
					  @psFromDate		nvarchar(254)',
					  @dFromDate =@dFromDate		OUTPUT,
					  @psFromDate=@psFromDate

	If @dFromDate is not null
	Begin
		Set @sWhere1 = @sWhere1 + char(10)+ "	AND TH.TRANSDATE >= @dFromDate"

		Set @sWhere2 = @sWhere2 + char(10)+ "	AND DH.TRANSDATE >= @dFromDate"
	End
End

If  @nErrorCode=0
and @psToDate is not null
and @psToDate <> ''
Begin
	Set @sSQLString="
		select @dToDate = dateadd(day, 1, convert(datetime, @psToDate, 101))"

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@dToDate		datetime	OUTPUT,
					  @psToDate		nvarchar(254)',
					  @dToDate =@dToDate			OUTPUT,
					  @psToDate=@psToDate

	If @dToDate is not null
	Begin
		Set @sWhere1 = @sWhere1 + char(10)+ "	AND TH.TRANSDATE < @dToDate"

		Set @sWhere2 = @sWhere2 + char(10)+ "	AND DH.TRANSDATE < @dToDate"
	End
End

If @nErrorCode=0
Begin
	Set @sSQLString="
	with CTE_CaseNameSequence (CASEID, NAMETYPE, SEQUENCE)
	as (	select CASEID, NAMETYPE, MIN(SEQUENCE)
		from CASENAME with (NOLOCK)
		where EXPIRYDATE is null
		group by CASEID, NAMETYPE)

	SELECT	convert( nvarchar(254), N.NAME+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' END +N.FIRSTNAME) AS DEBTORNAME, 
		convert( nvarchar(254), N2.NAME + CASE WHEN N2.FIRSTNAME IS NOT NULL THEN ', ' END + N2.FIRSTNAME +SPACE(1) + CASE WHEN N2.NAMECODE IS NOT NULL THEN '{' END +N2.NAMECODE+ CASE WHEN N2.NAMECODE IS NOT NULL THEN '}' END ) WIPSTAFF,  
		ISNULL(EP.PROFITCENTRECODE, '') AS EMPPROFITCENTRECODE,
		ISNULL(EP.DESCRIPTION, '') AS EMPPROFITCENTRE,
		ISNULL(CP.PROFITCENTRECODE, '') AS CASEPROFITCENTRECODE,
		ISNULL(CP.DESCRIPTION, '') AS CASEPROFITCENTRE,
		ISNULL(N.NAMECODE,'') AS DEBTORCODE,
		CASE WHEN IP.LOCALCLIENTFLAG = 1 THEN 'Local' ELSE 'Foreign' END AS LOCALCLIENT,  
		ISNULL(A.STATE, '') as DEBTORSTATE,
		ISNULL(CO1.COUNTRY, '') as DEBTORCOUNTRY,
		ISNULL(A1.STATE, '') as INVOICESTATE,
		--NAS.FORMATTEDNAME AS FORMATTEDNAME,
		--NAS.FORMATTEDATTENTION AS FORMATTEDATTENTION,
		--NAS.FORMATTEDADDRESS AS FORMATTEDADDRESS,
		ISNULL(CO2.COUNTRY, '') as INVOICECOUNTRY,
		convert( nvarchar(254), NI.NAME + CASE WHEN NI.FIRSTNAME IS NOT NULL THEN ', ' END + NI.FIRSTNAME +SPACE(1) + CASE WHEN NI.NAMECODE IS NOT NULL THEN '{' END +NI.NAMECODE+ CASE WHEN NI.NAMECODE IS NOT NULL THEN '}' END ) CLIENTNAME,  
		ISNULL(NI.NAMECODE,'') AS CLIENTCODE,
		convert( nvarchar(254), NEMP.NAME+ CASE WHEN NEMP.FIRSTNAME IS NOT NULL THEN ', ' END + NEMP.FIRSTNAME) AS DOCKETRESPONSIBLE, 
		convert( nvarchar(254), NSIG.NAME+ CASE WHEN NSIG.FIRSTNAME IS NOT NULL THEN ', ' END + NSIG.FIRSTNAME) AS BILLINGATTORNEY, 
		dbo.fn_GetConcatenatedNames(c.caseid,'O',CHAR(10),Getdate(),NULL) AS OWNER,
		dbo.fn_GetConcatenatedNames(c.caseid,'K',CHAR(10),Getdate(),NULL) AS ASSIGNEE,
		--ISNULL(TB2.DESCRIPTION, '') AS DIV_LOC,
		--ISNULL(TB3.DESCRIPTION, '') AS SABIC_SBU,
		--ISNULL(TB4.DESCRIPTION, '') AS SABIC_BU,
		--ISNULL(TB5.DESCRIPTION, '') AS SABIC_BL,
		C.IRN AS CASEIRN,
		C.TITLE AS CASETITLE,
		CT.CASETYPEDESC AS CASETYPE,
		PT.PROPERTYNAME AS PROPERTYTYPE,
		CO.COUNTRY AS COUNTRYCODE,
		ISNULL(CC.CASECATEGORYDESC, '') AS CASECATEGORY,
		WY.CATEGORYCODE AS WIPCATEGORY,
		WY.DESCRIPTION AS WIPTYPE,
		WT.DESCRIPTION AS WIPTEMPLATE,
		WH.WIPCODE AS WIPCODE,
		WH.TRANSDATE AS WIPDATE,
		ISNULL(convert( nvarchar(254), N3.NAME+ CASE WHEN N3.FIRSTNAME IS NOT NULL THEN ', ' END +N3.FIRSTNAME),'') AS AGENT,
		ISNULL(WH.INVOICENUMBER,'') AS AGENTINVOICENO,	
		WP.LOCALTRANSVALUE * -1 as LOCALTRANSVALUE,
		WP.TRANSNO AS WIPTRANSACTIONNO,
		O.OPENITEMNO AS OPENITEMNO,
		DT.DESCRIPTION AS ITEM_TYPE,
		TH.TRANPOSTPERIOD as POSTPERIOD,
		TH.TRANSDATE as REMITTANCEDATE,
		O.ITEMDATE AS INVOICEDATE
	FROM TRANSACTIONHEADER TH
	JOIN WIPPAYMENT WP	on (WP.REFENTITYNO = TH.ENTITYNO
				and WP.REFTRANSNO  = TH.TRANSNO)

	JOIN WORKHISTORY WH	ON (WH.ENTITYNO      = WP.ENTITYNO
				AND WH.TRANSNO       = WP.TRANSNO
				AND WH.WIPSEQNO      = WP.WIPSEQNO
				AND WH.HISTORYLINENO = WP.HISTORYLINENO)

	JOIN WIPTEMPLATE WT	ON (WT.WIPCODE   = WH.WIPCODE)
	JOIN WIPTYPE WY		ON (WY.WIPTYPEID = WT.WIPTYPEID)
	JOIN CASES C		ON (C.CASEID     = WH.CASEID)

	-- Client
	JOIN CASENAME CN	ON (CN.CASEID = C.CASEID 
				and CN.NAMETYPE = 'I'
				and CN.SEQUENCE=(select SEQUENCE
						 from CTE_CaseNameSequence CTE
						 where CTE.CASEID=CN.CASEID
						 and CTE.NAMETYPE=CN.NAMETYPE))

	join NAME NI		on (NI.NAMENO = CN.NAMENO)

	-- Docket Responsible
	LEFT JOIN CASENAME CN2	ON (CN2.CASEID = C.CASEID 
				and CN2.NAMETYPE = 'EMP'
				and CN2.SEQUENCE=(select SEQUENCE
						 from CTE_CaseNameSequence CTE
						 where CTE.CASEID=CN2.CASEID
						 and CTE.NAMETYPE=CN2.NAMETYPE))

	LEFT join NAME NEMP on (NEMP.NAMENO = CN2.NAMENO)

	-- Billing Attorney	
	LEFT JOIN CASENAME CN3	ON (CN3.CASEID = C.CASEID 
				and CN3.NAMETYPE = 'SIG'
				and CN3.SEQUENCE=(select SEQUENCE
						 from CTE_CaseNameSequence CTE
						 where CTE.CASEID=CN3.CASEID
						 and CTE.NAMETYPE=CN3.NAMETYPE))

	LEFT join NAME NSIG	on (NSIG.NAMENO = CN3.NAMENO)

	JOIN CASETYPE CT	ON (C.CASETYPE     = CT.CASETYPE)
	JOIN PROPERTYTYPE PT	ON (C.PROPERTYTYPE = PT.PROPERTYTYPE)
	JOIN COUNTRY CO		ON (C.COUNTRYCODE  = CO.COUNTRYCODE)
	LEFT JOIN CASECATEGORY CC 
				ON (C.CASETYPE = CC.CASETYPE
				AND C.CASECATEGORY = CC.CASECATEGORY)

	JOIN OPENITEM O		ON (O.ITEMENTITYNO = WH.REFENTITYNO
				AND O.ITEMTRANSNO  = WH.REFTRANSNO
				AND O.ACCTENTITYNO = WH.REFENTITYNO
				AND O.ACCTDEBTORNO = WP.ACCTDEBTORNO
				AND O.ITEMTYPE NOT IN (513,514))

	JOIN NAME N		ON (N.NAMENO = O.ACCTDEBTORNO)
	JOIN DEBTOR_ITEM_TYPE DT 
				ON (DT.ITEM_TYPE_ID = O.ITEMTYPE)
	LEFT JOIN IPNAME IP	ON (IP.NAMENO       = O.ACCTDEBTORNO)

	-- WIP Staff
	LEFT JOIN NAME N2	ON (N2.NAMENO = WH.EMPLOYEENO)

	-- WIP Staff Profit Centre 
	LEFT JOIN EMPLOYEE E	ON (E.EMPLOYEENO = WH.EMPLOYEENO)
	LEFT JOIN PROFITCENTRE EP 
				ON (EP.PROFITCENTRECODE = E.PROFITCENTRECODE)

	-- Case Profit Centre 
	LEFT JOIN PROFITCENTRE CP 
				ON (CP.PROFITCENTRECODE = C.PROFITCENTRECODE)

	-- Debtor State
	LEFT JOIN ADDRESS A	ON (A.ADDRESSCODE = N.POSTALADDRESS)
	LEFT JOIN COUNTRY CO1	ON (A.COUNTRYCODE = CO1.COUNTRYCODE)

	-- Invoice Address State
	LEFT JOIN NAMEADDRESSSNAP NAS 
				ON (NAS.NAMESNAPNO   = O.NAMESNAPNO)
	LEFT JOIN ADDRESS A1	ON (A1.ADDRESSCODE   = NAS.ADDRESSCODE)
	LEFT JOIN COUNTRY CO2	ON (CO2.COUNTRYCODE  = A1.COUNTRYCODE)

	-- Supplier
	LEFT JOIN NAME N3	ON (N3.NAMENO = WH.ASSOCIATENO)

	WHERE WP.LOCALTRANSVALUE <> 0
	AND   TH.TRANSTATUS      <> 0
	AND   TH.TRANSTYPE NOT IN (528, 529)
	"+@sWhere1+"

	--
	-- Also include Unallocated Cash as they are entered and then allocated. Prepayments are treated as generic service revenue
	-- 
	UNION ALL
	SELECT
		convert( nvarchar(254), N.NAME+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' END +N.FIRSTNAME) AS DEBTORNAME, 
		CASE WHEN O.ITEMTYPE = 520 THEN 'UNALLOCATED CASH' ELSE 'PREPAYMENT' END AS WIPSTAFF,  
		'' AS EMPPROFITCENTRECODE,
		'' AS EMPPROFITCENTRE,
		'' AS CASEPROFITCENTRECODE,
		'' AS CASEPROFITCENTRE,
		ISNULL(N.NAMECODE,'') AS DEBTORCODE,
		CASE WHEN IP.LOCALCLIENTFLAG = 1 THEN 'Local' ELSE 'Foreign' END AS LOCALCLIENT,  
		ISNULL(A.STATE, '') as DEBTORSTATE,
		ISNULL(CO1.COUNTRY, '') as DEBTORCOUNTRY,
		ISNULL(A.STATE, '') as INVOICESTATE,
		--'' AS FORMATTEDNAME,
		--'' AS FORMATTEDATTENTION,
		--'' AS FORMATTEDADDRESS,
		ISNULL(CO1.COUNTRY, '') as INVOICECOUNTRY,
		convert( nvarchar(254), N.NAME + CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' END + N.FIRSTNAME +SPACE(1) + CASE WHEN N.NAMECODE IS NOT NULL THEN '{' END +N.NAMECODE+ CASE WHEN N.NAMECODE IS NOT NULL THEN '}' END ) CLIENTNAME,  	  
		ISNULL(N.NAMECODE, '') AS CLIENTCODE,
		'' AS DOCKETRESPONSIBLE, 
		'' AS BILLINGATTORNEY, 
		'' AS OWNER,
		'' AS ASSIGNEE,
		--'' AS DIV_LOC,
		--'' AS SABIC_SBU,
		--'' AS SABIC_BU,
		--'' AS SABIC_BL,
		'' AS CASEIRN,
		'' AS CASETITLE,
		'' AS CASETYPE,
		'' AS PROPERTYTYPE,
		'' AS COUNTRYCODE,
		'' AS CASECATEGORY,
		'SC' AS WIPCATEGORY,
		'SERCHG' AS WIPTYPE,
		'Services' AS WIPTEMPLATE,
		'SERV' AS WIPCODE,
		DH.TRANSDATE AS WIPDATE,
		'' AS AGENT,
		'' AS AGENTINVOICENO,	
		DH.LOCALVALUE * -1 AS LOCALTRANSVALUE,
		DH.REFTRANSNO AS WIPTRANSACTIONNO,
		O.OPENITEMNO AS OPENITEMNO,
		DT.DESCRIPTION AS ITEM_TYPE,
		DH.POSTPERIOD AS POSTPERIOD,
		DH.TRANSDATE AS REMITTANCEDATE,
		O.ITEMDATE AS INVOICEDATE
	FROM DEBTORHISTORY DH
	JOIN OPENITEM O ON (O.ITEMENTITYNO = DH.ITEMENTITYNO
				AND O.ITEMTRANSNO = DH.ITEMTRANSNO
				AND O.ACCTENTITYNO = DH.ACCTENTITYNO
				AND O.ACCTDEBTORNO = DH.ACCTDEBTORNO)
	JOIN DEBTOR_ITEM_TYPE DT ON (O.ITEMTYPE = DT.ITEM_TYPE_ID)
	JOIN NAME N ON (N.NAMENO = DH.ACCTDEBTORNO)
	LEFT JOIN IPNAME IP ON (O.ACCTDEBTORNO = IP.NAMENO)
	---- Debtor State
	LEFT JOIN ADDRESS A ON (A.ADDRESSCODE= N.POSTALADDRESS)
	LEFT JOIN COUNTRY CO1 ON (A.COUNTRYCODE = CO1.COUNTRYCODE)
	WHERE DH.STATUS <> 0
	AND O.ITEMTYPE in (520, 523)
	"+@sWhere2

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psClientCode		nvarchar(254),
					  @nFromPeriodID	int,
					  @nToPeriodID		int,
					  @dFromDate		datetime,
					  @dToDate		datetime',
					  @psClientCode		=@psClientCode,
					  @nFromPeriodID	=@nFromPeriodID,
					  @nToPeriodID		=@nToPeriodID,
					  @dFromDate		=@dFromDate,
					  @dToDate		=@dToDate
End

Return @nErrorCode
GO

Grant execute on dbo.rpt_ListARWIPCollections to public
GO
