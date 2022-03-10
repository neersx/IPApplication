-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_GetWipCostingRates
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_GetWipCostingRates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_GetWipCostingRates.'
	Drop procedure [dbo].[wp_GetWipCostingRates]
End
Print '**** Creating Stored Procedure dbo.wp_GetWipCostingRates...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.wp_GetWipCostingRates
(
	@pnUserIdentityId		int,		-- Mandatory
	@pbCalledFromCentura		bit		= 0,
	@pbDebug			bit		= null,
	-- Wip criteria
	@pdtTransactionDate		datetime	= null,
	@pnEntityKey			int		= null,
	@pnStaffKey			int		= null,
	@pnNameKey			int		= null,	-- Only required if CaseKey not provided
	@pnCaseKey			int		= null,
	@psDebtorNameTypeKey		nvarchar(3)	= 'D',
	@psWipCode			nvarchar(6)	= null,
	@pnProductKey			int		= null,

	@psWipCategoryKey		nvarchar(2)	= null output,
	-- Charge Out Rates
	@pbExtractChargeOut		bit		= null,	-- Request charge out rates calculation
	@pnChargeRatePerHour		decimal(10,2)	= null output,
	@psChargeCurrencyCode		nvarchar(3)	= null output, -- Null for local currency
	-- Margins
	@pbExtractMargin		bit		= null, -- Request margin calculation
	@pnMarginPercent		decimal(6,2)	= null output, -- 10% returned as value 10
	@pnMarginAmount			decimal(10,2)	= null output, -- Either Percent or Amount is returned
	@psMarginCurrencyCode		nvarchar(3)	= null output, -- Null for local currency
	-- Discounts
	@pbExtractDiscount		bit		= null, -- Request discount calculation
	@pnDiscountPercent		decimal(6,3)	= null output, -- 10% returned as value 10
	@pbIsDiscountBasedOnAmount	bit		= null output, -- True if before margin calculation required
	-- Cost Rates
	@pbExtractCost			bit		= null, -- Request cost calculation
	@pnCostPercent1			decimal(6,2)	= null output, -- 10% returned as value 10
	@pnCostPercent2			decimal(6,2)	= null output, -- 10% returned as value 10
	@pnCostRatePerHour1		decimal(10,2)	= null output,
	@pnCostRatePerHour2		decimal(10,2)	= null output,
	-- additional input parameters
	@pnStaffClassKey		int		= null,	-- option to provide the staff class rather than the staff
	@psActionKey			nvarchar(2)	= null,
	@prnMarginNo			int		= null output,
	@prnMarginCap			decimal(10,2)	= null output,	-- SQA18298
	@prsWIPTypeKey			nvarchar(6)	= null output,
	@pnMarginDiscountPercent	decimal(6,3)	= null output -- 10% returned as value 10
)
as
-- PROCEDURE:	wp_GetWipCostingRates
-- VERSION:	34
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Retrieves the rates, percentages and amounts for costing
--		Work In Progress from the various rules

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Jun 2005	JEK	RFC2629	1	Procedure created
-- 27 Jun 2005	JEK	RFC2629	2	Not choosing the most recent effective date for
--					charge out rates or cost rates.
-- 30 Jun 2005	TM	RFC2766	3	Choose action in a similar manner to client/server.
-- 06 Jul 2005	JEK	RFC2805 4	No discounts are returning a percentage of 0 rather than null.
-- 07 Jul 2005	JEK	RFC2808	5	Default Entity for use with Margins.
-- 03 Nov 2005	TM	RFC2809	6	Include debtor billing currency in margin best fit.
-- 13 Mar 2006	AB	12285	7	GENERICKEY being implicitly converted to an integer. Use CAST syntax.
-- 13 Mar 2006	JB	12285	8	Bug (missing CAST): (GENERICKEY = @pnStaffKey AS nvarchar(20)))
-- 12 Apr 2006	JEK	12555	9	Extract case debtor type even if case does not have a debtor.
-- 08 Jun 2006	Dw	12351	13	Passed new parameter @nOwnerKey to pt_GetDiscountRate
--					Also adjusted code to ensure that owner was always retrieved.	
-- 29 Jun 2006	Dw	12903	14	When currency code had less than 3 chars a trailing space was being included
-- 23 Oct 2006	Dw	13126	15	Added new parameter @pnStaffClassKey for use by budget calculator
-- 03 Feb 2007	MF	14239	16	Debtor Type held against a Case is to take precedence over charges 
--					defined against Names
-- 16 Mar 2007	MF	14574	17	Allow Action to be passed as a parameter so that the WIP Costing considers this
--					explicit Action if it is passed rather than defaulting.
-- 07 May 2007	CR	14311	18	Updated @sAction parameter to be @psAction.
-- 18 May 2007	CR	14311	19	Remove logic default the Action Parameter.
-- 05 Jul 2007	CR	14995	20	Fixed CaseDebtorType/NameDebtorType bug
-- 19 Aug 2008  Dw	16151	21	Extended Charge Rate best fit to include case office
-- 03 Oct 2008	Dw	16917	22	Add new parameter to return the margin identifier

-- 15 Dec 2008	MF	17136	23	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 08 Apr 2009	MF	17577	24	Check if there is a DEFAULTENTITYNO against @pnStaffKey from EMPLOYEE table before dropping
--					back to use the HOMENAMENO.
-- 23 Feb 2010	MS	RFC7268	25	Added ENDEFFECTIVEDATE in bestfit logic for applicable charge rate
-- 24 Feb 2010	Dw	18298	26	Added new parameter to return the margin cap
-- 06 Jul 2010	Dw	SQA11749 27	Passed new parameter WIP Code to pt_GetMargin
-- 04 Jan 2011	MF	19309	28	Revisit RFC7268 to correct SQL around ENDEFFECTIVEDATE. Brackets should have been used to enclose boolean OR.
-- 22 Dec 2011	AT	R9160	29	Return WIP Type key for exch rate calculation
-- 19 Jun 2012	KR	R12005	30	Add WIPCODE and CASETYPE to the Discount calculation
-- 04 jul 2013	Dw	R12904	31	Allow both Debtor and Case to be provided as parameters. 
-- 01 Jun 2015	MS	R35907	32	Added COUNTRYCODE to the Discount calculation
-- 14 Dec 2015	Dw	R56172	33	Added new output parameter @pnMarginDiscountPercent for use when 'WIP as Separate Margin' site control is set.
-- 24 Oct 2017	AK	R72645	34	Make compatible with case sensitive server with case insensitive database.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @sSQLString		nvarchar(4000)

declare @nInstructorKey		int
declare @nLocalInstructorFlag	dec(1,0)
declare @sInstructorCountryKey	nvarchar(3)

declare @nOwnerKey		int
declare @nLocalOwnerFlag	dec(1,0)

declare @nDebtorKey		int
declare @nLocalDebtorFlag	dec(1,0)
declare @sDebtorCountryKey	nvarchar(3)
declare @nCaseDebtorTypeKey	int
declare @nNameDebtorTypeKey	int
declare @sDebtorCurrency	nvarchar(3)

declare @nStaffClassKey		int
declare @nStaffOfficeKey	int

declare @sPropertyTypeKey	nchar(1)

declare @sCostRateKey		nchar(8)
declare	@sCurrencyAndRate	nchar(15)
declare @nCaseOfficeKey		int
declare @sCaseType		nchar(2)
declare @sCountryCode		nvarchar(3)
-- 12904
declare @bWIPSplitMultiDebtor	bit
-- R56172
declare @bMarginAsSeparateWip	bit
declare @bRenewalFlag		bit
declare @sMarginWipCode		nvarchar(6)
declare @sMarginRenewalWipCode	nvarchar(6)
declare @sMarginWipTypeKey	nvarchar(6)
declare @sMarginWipCategoryKey	nvarchar(6)
declare @bIsMarginDiscountBasedOnAmount decimal(1,0)

-- Initialise variables
Set @nErrorCode = 0

-- Is the 'Margin as Separate WIP' site control applicable?
-- R56172
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select  @bMarginAsSeparateWip = isnull(S.COLBOOLEAN,0 )
	from	SITECONTROL S
	WHERE 	S.CONTROLID = 'Margin as Separate WIP'"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@bMarginAsSeparateWip	bit		OUTPUT',
			  @bMarginAsSeparateWip	= @bMarginAsSeparateWip	OUTPUT
			  
	If (@nErrorCode = 0) AND (@bMarginAsSeparateWip = 1)
	Begin
		Set @sSQLString = "
		select  @sMarginWipCode = S.COLCHARACTER
		from	SITECONTROL S
		WHERE 	S.CONTROLID = 'Margin WIP Code'"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@sMarginWipCode	nvarchar(6)	OUTPUT',
				  @sMarginWipCode	= @sMarginWipCode OUTPUT
	End
	
	If (@nErrorCode = 0) AND (@bMarginAsSeparateWip = 1)
	Begin
		Set @sSQLString = "
		select  @sMarginRenewalWipCode = S.COLCHARACTER
		from	SITECONTROL S
		WHERE 	S.CONTROLID = 'Margin Renewal WIP Code'"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@sMarginRenewalWipCode	nvarchar(6)	OUTPUT',
				  @sMarginRenewalWipCode	= @sMarginRenewalWipCode OUTPUT
	End
End

-- Is the 'WIP Split Multi Debtor' site control applicable?
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select  @bWIPSplitMultiDebtor = isnull(S.COLBOOLEAN,0 )
	from	SITECONTROL S
	WHERE 	S.CONTROLID = 'WIP Split Multi Debtor'"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@bWIPSplitMultiDebtor	bit		OUTPUT',
			  @bWIPSplitMultiDebtor	= @bWIPSplitMultiDebtor	OUTPUT
End

If @nErrorCode = 0
and (@pnCaseKey is not null)
and (@bWIPSplitMultiDebtor = 0)
Begin
	Set @pnNameKey = null
End


-- Strip out any time portion from the date
If @nErrorCode = 0
Begin
	Set @pdtTransactionDate =
		cast(convert(nvarchar, isnull(@pdtTransactionDate,getdate()), 112)
		as datetime)

	If @pbDebug = 1
	Begin
		Print '@pdtTransactionDate = ' + cast(@pdtTransactionDate as nvarchar(20))
	End
End


-- Get Instructor information
If @nErrorCode = 0
and @pnCaseKey is not null
and (@pbExtractChargeOut = 1 or
     @pbExtractMargin = 1)
Begin
	Set @sSQLString = "
	select 	@nInstructorKey = CN.NAMENO,
		@sInstructorCountryKey = A.COUNTRYCODE,
		@nLocalInstructorFlag = IP.LOCALCLIENTFLAG
	from	CASENAME CN
	left join NAME N		on (N.NAMENO=CN.NAMENO)
	left join ADDRESS A 		on (A.ADDRESSCODE=N.POSTALADDRESS)
	left join IPNAME IP		on (IP.NAMENO=CN.NAMENO)
	where	CN.NAMETYPE='I'
	and	(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
	and	CN.SEQUENCE =
			(select min(SEQUENCE) 
			from CASENAME CN1
	                where CN1.CASEID=CN.CASEID
	          	and CN1.NAMETYPE=CN.NAMETYPE
			and(CN1.EXPIRYDATE is null or CN1.EXPIRYDATE>getdate()))
	and	CN.CASEID=@pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCaseKey			int,
		  @nInstructorKey		int			OUTPUT,
		  @nLocalInstructorFlag 	dec(1,0)		OUTPUT,
		  @sInstructorCountryKey 	nvarchar(3)		OUTPUT',
		  @pnCaseKey			= @pnCaseKey,
		  @nInstructorKey		= @nInstructorKey	OUTPUT,
		  @nLocalInstructorFlag		= @nLocalInstructorFlag OUTPUT,
		  @sInstructorCountryKey	= @sInstructorCountryKey OUTPUT
End

If @pbDebug = 1
Begin
	Print '@nInstructorKey = ' + cast(@nInstructorKey as nvarchar(20))
	Print '@nLocalInstructorFlag = ' + cast(@nLocalInstructorFlag as nvarchar(20))
	Print '@sInstructorCountryKey = ' + cast(@sInstructorCountryKey as nvarchar(20))
End

-- Get Owner Information
If @nErrorCode = 0
and @pnCaseKey is not null
Begin
	Set @sSQLString = "
	select 	@nOwnerKey = CN.NAMENO,
		@nLocalOwnerFlag = IP.LOCALCLIENTFLAG
	from	CASENAME CN
	left join IPNAME IP		on (IP.NAMENO=CN.NAMENO)
	where	CN.NAMETYPE='O'
	and	(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
	and	CN.SEQUENCE =
			(select min(SEQUENCE) 
			from CASENAME CN1
	                where CN1.CASEID=CN.CASEID
	          	and CN1.NAMETYPE=CN.NAMETYPE
			and(CN1.EXPIRYDATE is null or CN1.EXPIRYDATE>getdate()))
	and	CN.CASEID=@pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCaseKey		int,
		  @nOwnerKey		int			OUTPUT,
		  @nLocalOwnerFlag 	dec(1,0)		OUTPUT',
		  @pnCaseKey		= @pnCaseKey,
		  @nOwnerKey		= @nOwnerKey		OUTPUT,
		  @nLocalOwnerFlag	= @nLocalOwnerFlag 	OUTPUT
End

If @pbDebug = 1
Begin
	Print '@nOwnerKey = ' + cast(@nOwnerKey as nvarchar(20))
	Print '@nLocalOwnerFlag = ' + cast(@nLocalOwnerFlag as nvarchar(20))
End


-- Get Debtor Information
If @nErrorCode = 0 
and @pnCaseKey is not null 
and (@pbExtractChargeOut = 1 or 
     @pbExtractMargin = 1 or 
     @pbExtractDiscount = 1) 
Begin 
        -- If debtor already provided
        if @pnNameKey is not null 
	Begin
	Set @psDebtorNameTypeKey = isnull(@psDebtorNameTypeKey, 'D')

	Set @sSQLString = "
	select 	@sDebtorCountryKey = A.COUNTRYCODE
	from NAME N
	left join ADDRESS A 		on (A.ADDRESSCODE=N.POSTALADDRESS)
	where	N.NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnNameKey			int,
		  @sDebtorCountryKey 		nvarchar(3)		OUTPUT',
		  @pnNameKey			= @pnNameKey,
		  @sDebtorCountryKey		= @sDebtorCountryKey OUTPUT
	End
	-- else derive debtor from the Case
        Else 
        Begin
	Set @psDebtorNameTypeKey = isnull(@psDebtorNameTypeKey, 'D')

	Set @sSQLString = "
	select 	@nDebtorKey = CN.NAMENO,
		@sDebtorCountryKey = A.COUNTRYCODE
	from CASENAME CN
	left join NAME N		on (N.NAMENO=CN.NAMENO)
	left join ADDRESS A 		on (A.ADDRESSCODE=N.POSTALADDRESS)
	where	CN.NAMETYPE = @psDebtorNameTypeKey
	and	(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
	and	CN.SEQUENCE =
			(select min(SEQUENCE) 
			from CASENAME CN1
	                where CN1.CASEID=CN.CASEID
	          	and CN1.NAMETYPE=CN.NAMETYPE
			and(CN1.EXPIRYDATE is null or CN1.EXPIRYDATE>getdate()))
	AND CN.CASEID=@pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCaseKey			int,
		  @psDebtorNameTypeKey		nvarchar(3),
		  @nDebtorKey			int			OUTPUT,
		  @sDebtorCountryKey 		nvarchar(3)		OUTPUT',
		  @pnCaseKey			= @pnCaseKey,
		  @psDebtorNameTypeKey		= @psDebtorNameTypeKey,
		  @nDebtorKey			= @nDebtorKey	OUTPUT,
		  @sDebtorCountryKey		= @sDebtorCountryKey OUTPUT
	End
End 

If @nErrorCode = 0
and @pnNameKey is not null
Begin
	Set @nDebtorKey = @pnNameKey
End


-- Get Debtor Information for name
If @nErrorCode = 0
and @pnNameKey is not null
and (@pbExtractChargeOut = 1 or
     @pbExtractMargin = 1)
Begin
	Set @sSQLString = "
	select 	@sDebtorCountryKey = A.COUNTRYCODE
	from NAME N
	left join ADDRESS A 		on (A.ADDRESSCODE=N.POSTALADDRESS)
	where	N.NAMENO = @nDebtorKey"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@nDebtorKey			int,
		  @sDebtorCountryKey 		nvarchar(3)		OUTPUT',
		  @nDebtorKey			= @nDebtorKey,
		  @sDebtorCountryKey		= @sDebtorCountryKey 	OUTPUT
End

If @pbDebug = 1
Begin
	Print '@nDebtorKey = ' + cast(@nDebtorKey as nvarchar(20))
	Print '@sDebtorCountryKey = ' + cast(@sDebtorCountryKey as nvarchar(20))
End

-- Get information for DebtorKey
If @nErrorCode = 0
and @nDebtorKey is not null
and (@pbExtractChargeOut = 1 or
     @pbExtractMargin = 1)
Begin

	Set @sSQLString = "
	select 	@nNameDebtorTypeKey = IP.DEBTORTYPE,
		@nLocalDebtorFlag = IP.LOCALCLIENTFLAG,
		@sDebtorCurrency = IP.CURRENCY
	from	IPNAME IP
	where	IP.NAMENO = @nDebtorKey"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@nDebtorKey			int,
		  @nNameDebtorTypeKey 	int			OUTPUT,
		  @nLocalDebtorFlag		int			OUTPUT,
		  @sDebtorCurrency		nvarchar(3)		OUTPUT',
		  @nDebtorKey			= @nDebtorKey,
		  @nNameDebtorTypeKey	= @nNameDebtorTypeKey 	OUTPUT,
		  @nLocalDebtorFlag		= @nLocalDebtorFlag		OUTPUT,
		  @sDebtorCurrency		= @sDebtorCurrency		OUTPUT
End

If @pbDebug = 1
Begin
	Print '@nNameDebtorTypeKey = ' + cast(@nNameDebtorTypeKey as nvarchar(20))
	Print '@nLocalDebtorFlag = ' + cast(@nLocalDebtorFlag as nvarchar(1))
	Print '@sDebtorCurrency = ' + cast(@sDebtorCurrency as nvarchar(3))
End

-- Get Case DebtorTypeKey
If @nErrorCode = 0
and @pnCaseKey is not null
and (@pbExtractChargeOut = 1 or
     @pbExtractMargin = 1)
Begin
	Set @sSQLString = "
	select @nCaseDebtorTypeKey = min(TABLECODE)
	from TABLEATTRIBUTES
	where PARENTTABLE = 'CASES'
	and TABLETYPE = 7
	and GENERICKEY = CAST(@pnCaseKey AS nvarchar(20))"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCaseKey			int,
		  @nCaseDebtorTypeKey	int			OUTPUT',
		  @pnCaseKey			= @pnCaseKey,
		  @nCaseDebtorTypeKey	= @nCaseDebtorTypeKey 	OUTPUT
End

If @pbDebug = 1
Begin
	Print '@nCaseDebtorTypeKey = ' + cast(@nCaseDebtorTypeKey as nvarchar(20))
	Print '@nLocalDebtorFlag = ' + cast(@nLocalDebtorFlag as nvarchar(20))
End

-- Get Staff information
If @nErrorCode = 0
and (@pbExtractChargeOut = 1 or
     @pbExtractCost = 1)
Begin
	If @pnStaffKey is null
	Begin
		-- 13126 if the staff class is provided then set the value from here
		Set @nStaffClassKey = @pnStaffClassKey
	End
	Else
	Begin
		Set @sSQLString = "
		select @nStaffOfficeKey =
				(select min(TABLECODE)
				 from TABLEATTRIBUTES
				 where PARENTTABLE = 'NAME'
				 and TABLETYPE = 44
				 and (GENERICKEY = CAST(@pnStaffKey AS nvarchar(20)))),
			@nStaffClassKey = E.STAFFCLASS
		from	EMPLOYEE E
		where	E.EMPLOYEENO = @pnStaffKey"
	
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnStaffKey			int,
			  @nStaffClassKey		int			OUTPUT,
			  @nStaffOfficeKey 		int			OUTPUT',
			  @pnStaffKey			= @pnStaffKey,
			  @nStaffClassKey		= @nStaffClassKey	OUTPUT,
			  @nStaffOfficeKey		= @nStaffOfficeKey 	OUTPUT
	End
End

If @pbDebug = 1
Begin
	Print '@nStaffClassKey = ' + cast(@nStaffClassKey as nvarchar(20))
	Print '@nStaffOfficeKey = ' + cast(@nStaffOfficeKey as nvarchar(20))
End

-- Get Case attributes
If (@nErrorCode = 0
and @pnCaseKey is not null)
Begin
	Set @sSQLString = 
	"Select @sPropertyTypeKey = C.PROPERTYTYPE,
		  @nCaseOfficeKey = C.OFFICEID
	 from CASES C
	 where C.CASEID = @pnCaseKey"			

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@sPropertyTypeKey	nvarchar(2)		OUTPUT,
		  @nCaseOfficeKey       int			OUTPUT,
		  @pnCaseKey		int',
		  @sPropertyTypeKey	= @sPropertyTypeKey	OUTPUT,
		  @nCaseOfficeKey       = @nCaseOfficeKey       OUTPUT,
		  @pnCaseKey		= @pnCaseKey 
End

If @pbDebug = 1
Begin
	Print '@sPropertyTypeKey = ' + @sPropertyTypeKey
	Print '@nCaseOfficeKey = ' + @nCaseOfficeKey
End

-- Get EntityKey
If @nErrorCode = 0
and @pnEntityKey is null
and @pbExtractMargin = 1
Begin

	Set @sSQLString = 
		"Select @pnEntityKey = isnull(E.DEFAULTENTITYNO,COLINTEGER )
		from SITECONTROL
		left join EMPLOYEE E on (E.EMPLOYEENO=@pnStaffKey)
		where CONTROLID = 'HOMENAMENO'"			
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnEntityKey	int		OUTPUT,
						  @pnStaffKey	int',
						  @pnEntityKey	= @pnEntityKey	OUTPUT,
						  @pnStaffKey	= @pnStaffKey
End

If @pbDebug = 1
Begin
	Print '@pnEntityKey = ' + cast(@pnEntityKey as nvarchar)
End

-- Get WipCode information
If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"select @prsWIPTypeKey = T.WIPTYPEID, 
		@psWipCategoryKey = T.CATEGORYCODE,
		@bRenewalFlag = W.RENEWALFLAG
	from WIPTEMPLATE W
	left join WIPTYPE T 	on (T.WIPTYPEID = W.WIPTYPEID)
	where W.WIPCODE = @psWipCode"			

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@psWipCategoryKey	nvarchar(2)	OUTPUT,
		  @prsWIPTypeKey	nvarchar(6)	OUTPUT,
		  @bRenewalFlag		bit		OUTPUT,
		  @psWipCode		nvarchar(6)',
		  @psWipCategoryKey	= @psWipCategoryKey	OUTPUT,
		  @prsWIPTypeKey	= @prsWIPTypeKey	OUTPUT,
		  @bRenewalFlag		= @bRenewalFlag		OUTPUT,
		  @psWipCode		= @psWipCode

End

If @pbDebug = 1
Begin
	Print '@prsWIPTypeKey = ' + @prsWIPTypeKey
End

-- Charge out rates
If @nErrorCode=0
and @pbExtractChargeOut = 1
Begin
	Set @sSQLString = 
	"SELECT	@sCurrencyAndRate=
		Substring(
			max (	CASE WHEN ACTIVITY		is NULL THEN '0' ELSE '1' END+
				CASE WHEN CASEID   		is NULL THEN '0' ELSE '1' END+
				CASE WHEN CASEOFFICE   		is NULL THEN '0' ELSE '1' END+
				CASE WHEN @nCaseDebtorTypeKey	is NULL THEN '0'
				     ELSE CASE WHEN DEBTORTYPE	is NULL THEN '0' ELSE '1' END END +
				CASE WHEN INSTRUCTOR   		is NULL THEN '0' ELSE '1' END+
				CASE WHEN OWNER   		is NULL THEN '0' ELSE '1' END+
	 			CASE WHEN NAMENO		is NULL THEN '0' ELSE '1' END+
				CASE WHEN @nNameDebtorTypeKey	is NULL THEN '0'
				     ELSE CASE WHEN DEBTORTYPE	is NULL THEN '0' ELSE '1' END END +
				CASE WHEN LOCALINSTRUCTORFLG	is NULL THEN '0' ELSE '1' END+
				CASE WHEN LOCALOWNERFLAG	is NULL THEN '0' ELSE '1' END+
				CASE WHEN LOCALCLIENTFLAG	is NULL THEN '0' ELSE '1' END+
				CASE WHEN EMPLOYEENO		is NULL THEN '0' ELSE '1' END+
				CASE WHEN STAFFCLASS		is NULL THEN '0' ELSE '1' END+
				CASE WHEN OFFICE		is NULL THEN '0' ELSE '1' END+
				isnull(convert(char(8), EFFECTIVEDATE,112),'00000000') + 
				convert(nchar(3),isnull(FOREIGNCURRENCY,'   '))+
				convert(nchar(12),CHARGEUNITRATE)), 23,15)
	FROM  TIMECOSTING
	WHERE EFFECTIVEDATE <= @pdtTransactionDate
	AND ( ENDEFFECTIVEDATE >= @pdtTransactionDate   OR ENDEFFECTIVEDATE	IS NULL)
	AND ( ACTIVITY		= @psWipCode		OR ACTIVITY		IS NULL)
	AND ( CASEID		= @pnCaseKey		OR CASEID		IS NULL)
	AND ( INSTRUCTOR	= @nInstructorKey	OR INSTRUCTOR		IS NULL)
	AND ( OWNER		= @nOwnerKey		OR OWNER		IS NULL)
	AND ( NAMENO		= @nDebtorKey		OR NAMENO		IS NULL)
	AND ( DEBTORTYPE	= isnull(@nCaseDebtorTypeKey,@nNameDebtorTypeKey)	
							OR DEBTORTYPE   	IS NULL)
	AND ( LOCALINSTRUCTORFLG= @nLocalInstructorFlag	OR LOCALINSTRUCTORFLG   IS NULL)
	AND ( LOCALOWNERFLAG	= @nLocalOwnerFlag	OR LOCALOWNERFLAG	IS NULL)
	AND ( LOCALCLIENTFLAG	= @nLocalDebtorFlag	OR LOCALCLIENTFLAG	IS NULL)
	AND ( EMPLOYEENO	= @pnStaffKey		OR EMPLOYEENO		IS NULL)
	AND ( STAFFCLASS	= @nStaffClassKey	OR STAFFCLASS		IS NULL)
	AND ( OFFICE		= @nStaffOfficeKey	OR OFFICE		IS NULL)
	AND ( CASEOFFICE	= @nCaseOfficeKey	OR CASEOFFICE		IS NULL)"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@sCurrencyAndRate	nchar(15)		OUTPUT,
		  @pdtTransactionDate	datetime,
		  @psWipCode		nvarchar(6),
		  @pnCaseKey		int,
		  @nInstructorKey	int,
		  @nOwnerKey		int,
		  @nDebtorKey		int,
		  @nCaseDebtorTypeKey	int,
		  @nNameDebtorTypeKey	int,
		  @nLocalInstructorFlag	dec(1,0),
		  @nLocalOwnerFlag	dec(1,0),
		  @nLocalDebtorFlag	dec(1,0),
		  @pnStaffKey		int,
		  @nStaffClassKey	int,
		  @nStaffOfficeKey	int,
		  @nCaseOfficeKey	int',
		  @sCurrencyAndRate	= @sCurrencyAndRate		OUTPUT,
		  @pdtTransactionDate	= @pdtTransactionDate,
		  @psWipCode		= @psWipCode,
		  @pnCaseKey		= @pnCaseKey,
		  @nInstructorKey	= @nInstructorKey,
		  @nOwnerKey		= @nOwnerKey,
		  @nDebtorKey		= @nDebtorKey,
		  @nCaseDebtorTypeKey	= @nCaseDebtorTypeKey,
		  @nNameDebtorTypeKey	= @nNameDebtorTypeKey,
		  @nLocalInstructorFlag	= @nLocalInstructorFlag,
		  @nLocalOwnerFlag	= @nLocalOwnerFlag,
		  @nLocalDebtorFlag	= @nLocalDebtorFlag,
		  @pnStaffKey		= @pnStaffKey,
		  @nStaffClassKey	= @nStaffClassKey,
		  @nStaffOfficeKey	= @nStaffOfficeKey,
		  @nCaseOfficeKey	= @nCaseOfficeKey

	If @pbDebug = 1
	Begin
		Print 'Charge @sCurrencyAndRate = ' + @sCurrencyAndRate
	End

	If @nErrorCode = 0
	Begin
		-- 12903
		--Set @psChargeCurrencyCode = substring(@sCurrencyAndRate, 1,3)
		Set @psChargeCurrencyCode = rtrim(substring(@sCurrencyAndRate, 1,3))
		If @psChargeCurrencyCode = '   '
		Begin
			Set @psChargeCurrencyCode = null
		End
		Set @pnChargeRatePerHour = substring(@sCurrencyAndRate,4,12)
	End
End

-- Margins
If @nErrorCode=0
and @pbExtractMargin = 1
Begin
	exec @nErrorCode=dbo.pt_GetMargin 
		@prnMarginPercentage 	= @pnMarginPercent	output,
		@prnMarginAmount	= @pnMarginAmount	output, 	
		@prsMarginCurrency 	= @psMarginCurrencyCode	output,
		@psWIPCategory 		= @psWipCategoryKey,
		@pnEntityNo		= @pnEntityKey,
		@psWIPType		= @prsWIPTypeKey,
		@pnCaseId		= @pnCaseKey,
		@pnInstructor		= @nInstructorKey,
		@pnDebtor		= @nDebtorKey,
		@psInstructorCountry	= @sInstructorCountryKey,
		@psDebtorCountry	= @sDebtorCountryKey,
		@psPropertyType		= @sPropertyTypeKey,
		@psAction		= @psActionKey,
		@pdtEffectiveDate	= @pdtTransactionDate,
		@psDebtorCurrency	= @sDebtorCurrency,
		@prnMarginNo		= @prnMarginNo output,
		@prnMarginCap		= @prnMarginCap output,
		@psWIPCode			= @psWipCode
End

-- Discounts
If @nErrorCode=0
and @pbExtractDiscount = 1
Begin
	
	if (@pnCaseKey is not null)
	Begin
		Set @sSQLString = "Select @sCaseType = CASETYPE, @sCountryCode = COUNTRYCODE from CASES where CASEID = @pnCaseKey"
		
		
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@sCaseType	nchar(2)	OUTPUT,
                                @sCountryCode   nvarchar(3)     OUTPUT,
				@pnCaseKey	int',
				@sCaseType	= @sCaseType	OUTPUT,
                                @sCountryCode   = @sCountryCode OUTPUT,
				@pnCaseKey	= @pnCaseKey
	End
	
	exec @nErrorCode=dbo.pt_GetDiscountRate 
		@pnBillToNo		= @nDebtorKey, 
		@psWIPType		= @prsWIPTypeKey,
		@psWIPCategory		= @psWipCategoryKey,
		@psPropertyType		= @sPropertyTypeKey, 
		@psAction		= @psActionKey,
		@pnEmployeeNo		= @pnStaffKey,
		@pnProductCode		= @pnProductKey,
		@prnDiscountRate 	= @pnDiscountPercent output,
		@prnBaseOnAmount	= @pbIsDiscountBasedOnAmount output,
		@pnOwner		= @nOwnerKey,
		@psWIPCode		= @psWipCode,
		@psCaseType		= @sCaseType,
                @psCountryCode          = @sCountryCode
	
	-- R56172 initialise the discount for the margin to be the same as the discount for the main item
	If (@nErrorCode = 0)
	Begin
		Set @pnMarginDiscountPercent = @pnDiscountPercent
	End
		
	-- R56172 check if a different discount applies to the margin item	
	if (@nErrorCode=0) AND (@bMarginAsSeparateWip = 1) 
	Begin
		If (@bRenewalFlag = 1)
		Begin	
			Set @sMarginWipCode = @sMarginRenewalWipCode
		End
		
		If (@nErrorCode = 0) and (@sMarginWipCode is not null)
		Begin
			Set @sSQLString = 
			"select @sMarginWipTypeKey = T.WIPTYPEID, 
				@sMarginWipCategoryKey = T.CATEGORYCODE
			from WIPTEMPLATE W
			left join WIPTYPE T 	on (T.WIPTYPEID = W.WIPTYPEID)
			where W.WIPCODE = @sMarginWipCode"			

			exec @nErrorCode=sp_executesql @sSQLString,
				N'@sMarginWipCategoryKey	nvarchar(2)		OUTPUT,
				  @sMarginWipTypeKey		nvarchar(6)		OUTPUT,
				  @sMarginWipCode		nvarchar(6)',
				  @sMarginWipCategoryKey= @sMarginWipCategoryKey	OUTPUT,
				  @sMarginWipTypeKey	= @sMarginWipTypeKey		OUTPUT,
				  @sMarginWipCode	= @sMarginWipCode
		End
		
		-- R56172 only derive the margin discount if the margin WIP Code is valid and of a different type	
		If (@sMarginWipCode is not null) and (@sMarginWipTypeKey is not null)
		and (@sMarginWipCode != @psWipCode)
		Begin				
			exec @nErrorCode=dbo.pt_GetDiscountRate 
				@pnBillToNo		= @nDebtorKey, 
				@psWIPType		= @sMarginWipTypeKey,
				@psWIPCategory		= @sMarginWipCategoryKey,
				@psPropertyType		= @sPropertyTypeKey, 
				@psAction		= @psActionKey,
				@pnEmployeeNo		= @pnStaffKey,
				@pnProductCode		= @pnProductKey,
				@prnDiscountRate 	= @pnMarginDiscountPercent output,
				@prnBaseOnAmount	= @bIsMarginDiscountBasedOnAmount output,
				@pnOwner		= @nOwnerKey,
				@psWIPCode		= @sMarginWipCode,
				@psCaseType		= @sCaseType
		End
	End

	-- This procedure returns 0 if there are no discounts found
	If @nErrorCode = 0
	and @pnDiscountPercent = 0
	Begin
		Set @pnDiscountPercent = null
		Set @pbIsDiscountBasedOnAmount = null
	End
	
	If @nErrorCode = 0
	and @pnMarginDiscountPercent = 0
	Begin
		Set @pnMarginDiscountPercent = null
	End
End

-- Cost Rates
If @nErrorCode = 0
and @pbExtractCost = 1
Begin
	Set @sSQLString = 
	"SELECT	@sCostRateKey=
		Substring(
			max (	CASE WHEN WIPCODE     	is NULL THEN '0' ELSE '1' END+
				CASE WHEN WIPTYPE   	is NULL THEN '0' ELSE '1' END+
				CASE WHEN WIPCATEGORY   is NULL THEN '0' ELSE '1' END+
	 			CASE WHEN EMPLOYEENO	is NULL THEN '0' ELSE '1' END+
				CASE WHEN STAFFCLASS	is NULL THEN '0' ELSE '1' END+
				isnull(convert(char(8), EFFECTIVEDATE,112),'00000000') +
				convert(char(8),COSTRATENO)), 14,8)
	FROM  COSTRATE
	WHERE EFFECTIVEDATE <= @pdtTransactionDate
	AND ( WIPCODE      = @psWipCode         OR WIPCODE      IS NULL)
	AND ( WIPTYPE      = @prsWIPTypeKey       OR WIPTYPE      IS NULL)
	AND ( WIPCATEGORY  = isnull(@psWipCategoryKey, 'SC')
						OR WIPCATEGORY  IS NULL)
	AND ( EMPLOYEENO   = @pnStaffKey	OR EMPLOYEENO   IS NULL)
	AND ( STAFFCLASS   = @nStaffClassKey	OR STAFFCLASS   IS NULL)"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@sCostRateKey		nchar(8)		OUTPUT,
		  @pdtTransactionDate	datetime,
		  @psWipCode		nvarchar(6),
		  @prsWIPTypeKey	nvarchar(6),
		  @psWipCategoryKey	nvarchar(2),
		  @pnStaffKey		int,
		  @nStaffClassKey	int',
		  @sCostRateKey		= @sCostRateKey		OUTPUT,
		  @pdtTransactionDate	= @pdtTransactionDate,
		  @psWipCode		= @psWipCode,
		  @prsWIPTypeKey	= @prsWIPTypeKey,
		  @psWipCategoryKey	= @psWipCategoryKey,
		  @pnStaffKey		= @pnStaffKey,
		  @nStaffClassKey	= @nStaffClassKey

	If @pbDebug = 1
	Begin
		Print '@sCostRateKey = ' + @sCostRateKey
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		select	@pnCostPercent1 = RATEPERCENT1,
			@pnCostPercent2 = RATEPERCENT2,
			@pnCostRatePerHour1 = RATEAMOUNT1,
			@pnCostRatePerHour2 = RATEAMOUNT2
		from	COSTRATE
		where	COSTRATENO = @sCostRateKey"
	
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@sCostRateKey		nchar(8),
			  @pnCostPercent1	decimal(6,2)		OUTPUT,
			  @pnCostPercent2	decimal(6,2)		OUTPUT,
			  @pnCostRatePerHour1	decimal(10,2)		OUTPUT,
			  @pnCostRatePerHour2	decimal(10,2)		OUTPUT',
			  @sCostRateKey		= @sCostRateKey,
			  @pnCostPercent1	= @pnCostPercent1	OUTPUT,
			  @pnCostPercent2	= @pnCostPercent2	OUTPUT,
			  @pnCostRatePerHour1	= @pnCostRatePerHour1	OUTPUT,
			  @pnCostRatePerHour2	= @pnCostRatePerHour2	OUTPUT
	End
End

Return @nErrorCode
GO

Grant execute on dbo.wp_GetWipCostingRates to public
GO
