-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dsb_ChartRevenueAnalysis 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dsb_ChartRevenueAnalysis]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dsb_ChartRevenueAnalysis.'
	Drop procedure [dbo].[dsb_ChartRevenueAnalysis]
End
Print '**** Creating Stored Procedure dbo.dsb_ChartRevenueAnalysis...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[dsb_ChartRevenueAnalysis]
(
	@pnUserIdentityKey		int,
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnFromPeriodID			int,
	@pnToPeriodID			int,
	@psEmployeeCode			nvarchar(4000)
)

-- PROCEDURE:	dsb_ChartRevenueAnalysis 
-- VERSION:		3
-- SCOPE:		Dashboard
-- DESCRIPTION:	Display the revenue values for the defined period.
--				The idea is that you run the script for a Period range and for a staff member.
--				It then returns all the WIP items billed for that employee for the period specified.
-- COPYRIGHT:	Copyright 1993 - 2009 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	----------------------------------------------- 
-- 15/10/2009	MAF			Procedure created
-- 02/11/2009	SF	RFC8564	2	Formatted for use.
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).

as 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(max)

Declare @sLookupCulture		nvarchar(10)

Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin	
	--Set @sSQLString = "
	Select
		N.NAMENO												as DebtorKey,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)		as DebtorName,
		N.NAMECODE												as DebtorNameCode,
		CO1.COUNTRY												as DebtorCountry,
		A.CITY													as DebtorCity,
		A.STATE													as DebtorState,
		A.POSTCODE												as DebtorPostCode,
		TB.DESCRIPTION											as DebtorCategory,
		IP.CURRENCY												as DebtorCurrency,
		TB1.DESCRIPTION											as DebtorType,
		C.IRN													as CaseReference,
		ISNULL (C.TITLE, '')									as CaseShortTitle,
		CT.CASETYPEDESC											as CaseTypeDescription,
		PT.PROPERTYNAME											as PropertyTypeDescription,
		CO.COUNTRY												as CountryCode,
		N1.NAMENO												as WipStaffNameKey,
		dbo.fn_FormatNameUsingNameNo(N1.NAMENO, null)		as WipStaffName,
		N1.NAMECODE												as WipStaffNameCode,
		PC.PROFITCENTRECODE										as ProfitCentreCode,
		PC.DESCRIPTION											as ProfitCentre,
		WC.DESCRIPTION											as WipCategory,
		WY.DESCRIPTION											as WipType,
		WT.DESCRIPTION											as WipTemplate,
		O.OPENITEMNO											as ItemNumber,
		O.ITEMDATE												as ItemDate,
		O.LOCALTAXAMT											as ItemTaxAmount,
		WH.LOCALTRANSVALUE * O.BILLPERCENTAGE/100 * -1			as Revenue,
		WH.POSTPERIOD											as PostPeriod
	from	WORKHISTORY WH
	join WIPTEMPLATE WT		on (WH.WIPCODE = WT.WIPCODE)
	join WIPTYPE WY			on (WT.WIPTYPEID = WY.WIPTYPEID)
	join WIPCATEGORY WC		on (WY.CATEGORYCODE = WC.CATEGORYCODE)
	join CASES C			on (WH.CASEID = C.CASEID)
	left join NAME N1		on (WH.EMPLOYEENO = N1.NAMENO)
	join CASETYPE CT		on (C.CASETYPE = CT.CASETYPE)
	join PROPERTYTYPE PT	on (C.PROPERTYTYPE = PT.PROPERTYTYPE)
	join COUNTRY CO			on (C.COUNTRYCODE = CO.COUNTRYCODE)
	join DEBTORHISTORY DH	on (DH.REFENTITYNO = WH.REFENTITYNO
							and DH.REFTRANSNO = WH.REFTRANSNO
							and DH.MOVEMENTCLASS = 1)
	join OPENITEM O			on (DH.ITEMENTITYNO = O.ITEMENTITYNO
							and DH.ITEMTRANSNO = O.ITEMTRANSNO
							and DH.ACCTENTITYNO = O.ACCTENTITYNO
							and DH.ACCTDEBTORNO = O.ACCTDEBTORNO
							and O.ITEMTYPE NOT IN (513,514))
	join NAME N				on (DH.ACCTDEBTORNO = N.NAMENO)
	join dbo.fn_Tokenise(@psEmployeeCode, ',') NAMECODES on (N1.NAMECODE = NAMECODES.Parameter)
	left join ADDRESS A		on (N.POSTALADDRESS = A.ADDRESSCODE)
	left join COUNTRY CO1	on (A.COUNTRYCODE = CO1.COUNTRYCODE)
	left join IPNAME IP		on (N.NAMENO = IP.NAMENO)  
	left join TABLECODES TB on (IP.CATEGORY = TB.TABLECODE	
							and TB.TABLETYPE = 6)	/* client category */
	left join TABLECODES TB1 on (IP.DEBTORTYPE = TB1.TABLECODE
							and TB1.TABLETYPE = 7) /* debtor type */
	left join EMPLOYEE E	on (WH.EMPLOYEENO = E.EMPLOYEENO)
	left join PROFITCENTRE PC on (E.PROFITCENTRECODE = PC.PROFITCENTRECODE)
	where	WH.STATUS <> 0 
	and		WH.POSTPERIOD >= @pnFromPeriodID
	and		WH.POSTPERIOD <= @pnToPeriodID
	and		WH.MOVEMENTCLASS = 2
		order by 2, 1
	OPTION (MAXDOP 1)
	
	--print @sSQLString
	--Exec @nErrorCode = sp_executesql @sSQLString,
	--				N'	@pnFromPeriodID		int,
	--					@pnToPeriodID		int',
	--					@pnFromPeriodID		= @pnFromPeriodID,
	--					@pnToPeriodID		= @pnToPeriodID
	
End


Return @nErrorCode
GO

Grant execute on dbo.dsb_ChartRevenueAnalysis to public
GO


