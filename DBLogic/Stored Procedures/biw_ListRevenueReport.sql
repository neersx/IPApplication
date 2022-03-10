---------------------------------------------------------------------------------------------
-- Creation of dbo.biw_ListRevenueReport
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_ListRevenueReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_ListRevenueReport.'
	drop procedure [dbo].[biw_ListRevenueReport]
	Print '**** Creating Stored Procedure dbo.biw_ListRevenueReport...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_ListRevenueReport
(	
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	-- The language in which output is to be expressed.
	@pnEntityKey                    int             = null, -- The key for Entity Name 
	@pnPostPeriod                   int             = null, -- restricts report to specified period
	@pnDebtorKey			int		= null, -- The key of the bill debtor
	@pdtFromDate			datetime	= null,	-- The start of the date range for the report.
	@pdtToDate			datetime	= null,	-- The end of the date range for the report.
	@psWIPCode                      nvarchar(6)     = null, -- restricts report to specified WIP
	@pbCalledFromCentura	        bit		= 0
)
AS
-- PROCEDURE:	biw_ListRevenueReport
-- VERSION:	4
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates the Revenue Analysis dataset.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 19 Oct 2011  TM	R100259	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).
-- 24 Aug 2017	MF	71721	3	Ethical Walls rules applied for logged on user.
-- 21 Sep 2017	MF	71712	4	Also included Row Level Security for Cases.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(max)
Declare	@bRowLevelSecurity	bit
Declare @bCaseOffice		bit
Declare	@bBlockCaseAccess	bit

Set	@nErrorCode      	= 0

If  @nErrorCode=0
Begin
	---------------------------------------
	-- Check to see if the user is impacted
	-- by Row Level Security
	---------------------------------------
	Select @bRowLevelSecurity = 1
	from IDENTITYROWACCESS U 
	join ROWACCESSDETAIL R on (R.ACCESSNAME = U.ACCESSNAME) 
	where R.RECORDTYPE = 'C'
	and U.IDENTITYID = @pnUserIdentityId

	Set @nErrorCode=@@ERROR
End

If @nErrorCode=0
Begin
	If @bRowLevelSecurity=1
	Begin
		---------------------------------------------
		-- If Row Level Security is in use for user,
		-- determine how/if Office is stored against 
		-- Cases.  It is possible to store the office
		-- directly in the CASES table or if a Case 
		-- is to have multiple offices then it is
		-- stored in TABLEATTRIBUTES.
		---------------------------------------------
		Select  @bCaseOffice = COLBOOLEAN
		from SITECONTROL
		where CONTROLID = 'Row Security Uses Case Office'

		Set @nErrorCode=@@ERROR
				
	
		---------------------------------------------
		-- Check to see if there are any Offices 
		-- held as TABLEATRRIBUTES of the Case. If
		-- not then treat as if Office is stored 
		-- directly in the CASES table.
		---------------------------------------------
		If(@bCaseOffice=0 or @bCaseOffice is null)
		and not exists (select 1 from TABLEATTRIBUTES where PARENTTABLE='CASES' and TABLETYPE=44)
			Set @bCaseOffice=1
	End
	Else Begin
		---------------------------------------------
		-- If Row Level Security is NOT in use for
		-- the current user, then check if any other 
		-- users are configured.  If they are, then 
		-- internal users that have no configuration 
		-- will be blocked from ALL cases.
		---------------------------------------------
		
		Select @bBlockCaseAccess = 1
		from IDENTITYROWACCESS U
		join USERIDENTITY UI	on (U.IDENTITYID = UI.IDENTITYID) 
		join ROWACCESSDETAIL R	on (R.ACCESSNAME = U.ACCESSNAME) 
		where R.RECORDTYPE = 'C' 
		and isnull(UI.ISEXTERNALUSER,0) = 0

		Set @nErrorCode=@@ERROR
	End
End

-- Populate the Time result set
If  @nErrorCode = 0
Begin	
	Set @sSQLString = "
	SELECT
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, N.NAMESTYLE) AS DEBTOR,
	ISNULL(N.NAMECODE,'000000') AS DEBTORCODE,
	CO1.COUNTRY AS DEBTORCOUNTRY,
	A.CITY AS DEBTORCITY,
	A.STATE AS DEBTORSTATE,
	A.POSTCODE AS DEBTORPOSTCODE,
	TB.DESCRIPTION	AS DEBTORCATEGORY,
	IP.CURRENCY AS DEBTORCURRENCY,
	TB1.DESCRIPTION AS DEBTORTYPE,
	C.IRN AS CASEIRN,
	CT.CASETYPEDESC AS CASETYPE,
	PT.PROPERTYNAME AS PROPERTYTYPE,
	CO.COUNTRY AS COUNTRYCODE,
	convert( nvarchar(254), N1.NAME+ CASE WHEN N1.FIRSTNAME IS NOT NULL THEN ', ' END +N1.FIRSTNAME) AS WIPSTAFF,
	PC.PROFITCENTRECODE AS PROFITCENTRECODE,
	PC.DESCRIPTION AS PROFITCENTRE, 
	WC.DESCRIPTION AS WIPCATEGORY,
	WY.DESCRIPTION AS WIPTYPE,
	WT.DESCRIPTION AS WIPTEMPLATE,
	O.OPENITEMNO AS ITEMNUMBER,
	O.ITEMDATE AS ITEMDATE,
	O.LOCALTAXAMT AS ITEMTAXAMT,
	WH.LOCALTRANSVALUE * O.BILLPERCENTAGE/100 * -1 AS REVENUE,
	WH.FOREIGNTRANVALUE * O.BILLPERCENTAGE/100 * -1 AS FOREIGNREVENUE,
	WH.POSTPERIOD AS POSTPERIOD
	FROM	WORKHISTORY WH
	JOIN WIPTEMPLATE WT ON (WH.WIPCODE = WT.WIPCODE)
	JOIN WIPTYPE WY ON (WT.WIPTYPEID = WY.WIPTYPEID)
	JOIN WIPCATEGORY WC ON (WY.CATEGORYCODE = WC.CATEGORYCODE)
	JOIN dbo.fn_CasesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") C ON (WH.CASEID = C.CASEID)"+ 
		
	CASE WHEN(@bRowLevelSecurity = 1 AND @bCaseOffice = 1)
			THEN char(10)+"	join dbo.fn_CasesRowSecurity("+cast(@pnUserIdentityId as nvarchar)+") R on (R.CASEID=C.CASEID AND R.READALLOWED=1)"
		WHEN(@bRowLevelSecurity = 1)
			THEN char(10)+"	join dbo.fn_CasesRowSecurityMultiOffice("+cast(@pnUserIdentityId as nvarchar)+") R on (R.CASEID=C.CASEID AND R.READALLOWED=1)"
		ELSE ""
	END + "
	JOIN NAME N1 ON (WH.EMPLOYEENO = N1.NAMENO)
	JOIN CASETYPE CT ON (C.CASETYPE = CT.CASETYPE)
	JOIN PROPERTYTYPE PT ON (C.PROPERTYTYPE = PT.PROPERTYTYPE)
	JOIN COUNTRY CO ON (C.COUNTRYCODE = CO.COUNTRYCODE)
	JOIN DEBTORHISTORY DH ON (DH.REFENTITYNO = WH.REFENTITYNO
				  AND DH.REFTRANSNO = WH.REFTRANSNO
				  AND DH.MOVEMENTCLASS = 1)
	JOIN OPENITEM O ON (DH.ITEMENTITYNO = O.ITEMENTITYNO
			    AND DH.ITEMTRANSNO = O.ITEMTRANSNO
			    AND DH.ACCTENTITYNO = O.ACCTENTITYNO
			    AND DH.ACCTDEBTORNO = O.ACCTDEBTORNO
			    AND O.ITEMTYPE NOT IN (513,514))
	JOIN dbo.fn_NamesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") N ON (DH.ACCTDEBTORNO = N.NAMENO)
	LEFT JOIN ADDRESS A ON (N.POSTALADDRESS = A.ADDRESSCODE)
	LEFT JOIN COUNTRY CO1 ON (A.COUNTRYCODE = CO1.COUNTRYCODE)
	LEFT JOIN IPNAME IP ON (N.NAMENO = IP.NAMENO)
	LEFT JOIN TABLECODES TB ON (IP.CATEGORY = TB.TABLECODE
				   AND TB.TABLETYPE = 6)	
	LEFT JOIN TABLECODES TB1 ON (IP.DEBTORTYPE = TB1.TABLECODE
				    AND TB1.TABLETYPE = 7)
	LEFT JOIN EMPLOYEE E ON (WH.EMPLOYEENO = E.EMPLOYEENO)
	LEFT JOIN PROFITCENTRE PC ON (E.PROFITCENTRECODE = PC.PROFITCENTRECODE)
	WHERE  WH.STATUS <> 0 
	AND WH.MOVEMENTCLASS = 2"+ 

	CASE WHEN(@bBlockCaseAccess=1)
		THEN char(10)+"	and 1=0"
		ELSE ""
	END + "

        AND (O.ITEMENTITYNO = @pnEntityKey or @pnEntityKey IS NULL)
	AND (WH.POSTPERIOD >= convert(int,@pnPostPeriod) or @pnPostPeriod IS NULL)
	AND (WH.POSTPERIOD <= convert(int,@pnPostPeriod) or @pnPostPeriod IS NULL)
        AND (WH.TRANSDATE >= @pdtFromDate or @pdtFromDate IS NULL)
        AND (WH.TRANSDATE <= @pdtToDate or @pdtToDate IS NULL)
	AND (N.NAMENO = @pnDebtorKey or @pnDebtorKey IS NULL)
	AND (WH.WIPCODE = @psWIPCode or @psWIPCode IS NULL)
	ORDER BY 2, 1
	OPTION (MAXDOP 1)"


	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnEntityKey          int,
			  @pnPostPeriod         int,
			  @pnDebtorKey		int,
			  @psWIPCode            nvarchar(6),
			  @pdtFromDate		datetime,
			  @pdtToDate		datetime',
			  @pnEntityKey          = @pnEntityKey,
			  @pnPostPeriod         = @pnPostPeriod,
			  @pnDebtorKey		= @pnDebtorKey,
			  @psWIPCode            = @psWIPCode,
			  @pdtFromDate		= @pdtFromDate,
			  @pdtToDate		= @pdtToDate 
End


Return @nErrorCode
GO

Grant exec on dbo.biw_ListRevenueReport to public
GO
