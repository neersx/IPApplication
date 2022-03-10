-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_ListWipWarnings
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_ListWipWarnings]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_ListWipWarnings.'
	Drop procedure [dbo].[wp_ListWipWarnings]
End
Print '**** Creating Stored Procedure dbo.wp_ListWipWarnings...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.wp_ListWipWarnings
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnStaffKey		int		= null,
	@pnEntityKey		int		= null,
	@pnNameKey		int		= null,	-- Provide either NameKey or CaseKey, not both
	@pnCaseKey		int		= null,
	@pnApplicationID	smallint,	-- The accounting application performing the processing. Mandatory.
						--1 - Billing
						--2 - WIP
						--4 - Timesheet
						--8 - Accounts Payable
						--16 - Accounts Receivable
						--32 - Cases
	@pdTransactionDate	datetime	= null,
	@pbDebug		bit		= 0

)
as
-- PROCEDURE:	wp_ListWipWarnings
-- VERSION:	15
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This procedure returns information and warning messages for a new
--		Work In Progress (WIP) item.  This information is returned as a series
--		of result sets with the intention that it is added to a dataset.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Jun 2005	JEK	RFC2739	1	Procedure created
-- 12 Jul 2005	JEK	RFC2739	2	Correct RestrictionActionKey column name.
-- 14 Jul 2005	JEK	RFC2883	3	Timer warning should not have case/name in where clause.
--					Make prepayment total null for a name level request.
-- 12 Dec 2005	LP	RFC1017	4	Return @nLocalDecimalPlaces in Additional Information result set
-- 15 Dec 2008	MF	17136	5	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 04 Feb 2010  MS	RFC7274	6	Returns warning message for Billing Cap
-- 25 Jul 2012	KR	R12488	7	Ignore Restrict on WIP site control if called from Cases
-- 02 Nov 2015	vql	R53910	8	Adjust formatted names logic (DR-15543).
-- 01 May 2017	LP	R70423	9	Check against Revised Budget Amount where available, otherwise use Budget Amount.
-- 07 Sep 2017  AK      R71978  10      Added Budget StartDate and EndDate checks in budget warning.
-- 08 Sep 2017  MS      R71835  11      Added Budget percentage check in budget warning.
-- 24 Oct 2017	AK		R72645	12	Make compatible with case sensitive server with case insensitive database.
-- 17 Apr 2018	MS	R60894	13	used debtor of the case for credit limit warnings.
-- 07 Sep 2018	AV	74738	14	Set isolation level to read uncommited.
-- 31 Oct 2018	DL	DR-45102	15	Replace control character (word hyphen) with normal sql editor hyphen


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare	@nErrorCode		int
declare @sSQLString		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Constants for severity values
declare @nInformation		tinyint
declare @nWarning		tinyint
declare @nUserError		tinyint
Set @nInformation = 0
Set @nWarning = 1
Set @nUserError = 2

declare @nMaximumSeverity	smallint
declare @sRequiredPassword	nvarchar(10)
declare @sLocalCurrencyCode	nvarchar(3)
declare @nReceivableBalance	decimal(11,2)
declare @nCreditLimit		decimal(11,2)
declare @nBudgetAmount		decimal(11,2)
declare @nBilledToDate		decimal(11,2)
declare @nUnbilledWip		decimal(11,2)
declare @nUsedTotal		decimal(11,2)
declare @nPrepaymentsForCase	decimal(11,2)
declare @nPrepaymentsForDebtor	decimal(11,2)
declare @nPrepaymentsTotal	decimal(11,2)
declare @nTotalWipAndTime	decimal(11,2)

declare @sTimerWarning		nvarchar(400)

declare @bRestrictOnWip		bit
declare @bPrepaymentWarnOver	bit
declare @bHasOustandingTimers	bit

declare @nLocalDecimalPlaces	tinyint

declare @nCreditLimitNameKey	int
declare @nBillingCap		decimal(11,2)
declare @nBillingCapPeriod	int
declare @sBillingCapPeriodTypeDesc nvarchar(20)
declare @dBillingCapStartDate	datetime
declare @bBillingCapResetFlag	bit
declare @sBillingCapPeriodType	nvarchar(1)
declare @nBillingCapNameKey	int
declare @nAmountBilled		decimal(11,2)
declare @dBillingCapDate	datetime
declare @nThresholdPercent	int

declare @nNameRestictionSeverity tinyint

declare @nAllWip		decimal(11,2)
declare @nTotalTime		decimal(11,2)
declare @dtBudgetStartDate      datetime
declare @dtBudgetEndDate        datetime
Declare @nBudgetPercentage      int

-- Initialise variables
Set @nErrorCode = 0
Set @nMaximumSeverity = -1
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Determine which tests are required
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select 	@bRestrictOnWip = isnull(W.COLBOOLEAN,0), 
		@bPrepaymentWarnOver = isnull(P.COLBOOLEAN,0)
	from SITECONTROL W
	cross join SITECONTROL P	
	where W.CONTROLID = 'Restrict On WIP'
	and P.CONTROLID = 'Prepayment Warn Over'"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@bRestrictOnWip	bit			OUTPUT,
			  @bPrepaymentWarnOver  bit			OUTPUT',
			  @bRestrictOnWip	= @bRestrictOnWip	OUTPUT,
			  @bPrepaymentWarnOver 	= @bPrepaymentWarnOver	OUTPUT

	If @nErrorCode = 0
	and @pbDebug = 1
	Begin
		print '@bRestrictOnWip = ' + cast(@bRestrictOnWip as nvarchar)
		print '@bPrepaymentWarnOver = ' + cast(@bPrepaymentWarnOver as nvarchar)
	End
End

-- Is there a Budget?
If @nErrorCode = 0
and @pnCaseKey is not null
Begin
	Set @sSQLString = "
	select @nBudgetAmount = ISNULL(NULLIF(C.BUDGETREVISEDAMT, 0), C.BUDGETAMOUNT),
        @dtBudgetStartDate    = C.BUDGETSTARTDATE,
        @dtBudgetEndDate      = C.BUDGETENDDATE,
        @nBudgetPercentage    = S.COLINTEGER
	from CASES C
        join SITECONTROL s on (S.CONTROLID = 'Budget Percentage Used Warning')
	where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nBudgetAmount	decimal(11,2)		OUTPUT,
                          @dtBudgetStartDate    datetime                OUTPUT,
                          @dtBudgetEndDate      datetime                OUTPUT,
                          @nBudgetPercentage    int                     OUTPUT,
			  @pnCaseKey		int',
			  @nBudgetAmount	= @nBudgetAmount	OUTPUT,
                          @dtBudgetStartDate    = @dtBudgetStartDate    OUTPUT,
                          @dtBudgetEndDate      = @dtBudgetEndDate      OUTPUT,
                          @nBudgetPercentage    = @nBudgetPercentage    OUTPUT,
			  @pnCaseKey		= @pnCaseKey


        If @nErrorCode = 0 and @nBudgetAmount is not null
        Begin
             If(ISNULL(@nBudgetPercentage,0) <= 0) 
             Begin
                Set  @nBudgetPercentage = 100
             END
        End
End

If @nErrorCode = 0
and @pbDebug = 1
Begin
	print '@nBudgetAmount = ' + cast(@nBudgetAmount as nvarchar(20))
        print '@dtBudgetStartDate = ' + cast(@dtBudgetStartDate as nvarchar(20))
        print '@dtBudgetEndDate = ' + cast(@dtBudgetEndDate as nvarchar(20))
        print '@nBudgetPercentage = ' + cast(@nBudgetPercentage as nvarchar(11))
End

-- Is there a Credit Limit?
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select	@nCreditLimit = N.CREDITLIMIT,
		@nCreditLimitNameKey = N.NAMENO
	from	IPNAME N
	-- Check the debtor if the WIP was recorded against a case
	left join CASENAME CN	on (CN.CASEID = @pnCaseKey
				and CN.NAMETYPE = 'D'
				and (CN.EXPIRYDATE>getdate() or CN.EXPIRYDATE IS NULL)
				and CN.SEQUENCE =
					(select min(SEQUENCE) 
					from CASENAME CN1
			                where CN1.CASEID=CN.CASEID
			          	and CN1.NAMETYPE=CN.NAMETYPE
					and(CN1.EXPIRYDATE is null or CN1.EXPIRYDATE>getdate())))
	WHERE 	((N.NAMENO = @pnNameKey and @pnCaseKey is null) 
	OR 	 (@pnCaseKey is not null and N.NAMENO = CN.NAMENO))"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nCreditLimit		decimal(11,2)		OUTPUT,
			  @nCreditLimitNameKey	int			OUTPUT,
			  @pnNameKey		int,
			  @pnCaseKey		int',
			  @nCreditLimit		= @nCreditLimit		OUTPUT,
			  @nCreditLimitNameKey	= @nCreditLimitNameKey	OUTPUT,
			  @pnNameKey		= @pnNameKey,
			  @pnCaseKey		= @pnCaseKey

	If @nErrorCode = 0
	and @pbDebug = 1
	Begin
		print '@nCreditLimit = ' + cast(@nCreditLimit as nvarchar(20))
		print '@nCreditLimitNameKey = ' + cast(@nCreditLimitNameKey as nvarchar(20))
	End
End

-- Is there a Billing Cap?
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select	@nBillingCap = N.BILLINGCAP,
		@nBillingCapPeriod = N.BILLINGCAPPERIOD,
		@sBillingCapPeriodTypeDesc = CASE WHEN N.BILLINGCAPPERIODTYPE is not null 
						THEN " + dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'PT',
							@sLookupCulture,@pbCalledFromCentura) + "
						ELSE NULL
						END,
		@sBillingCapPeriodType	= N.BILLINGCAPPERIODTYPE,
		@nBillingCapNameKey = N.NAMENO,
		@dBillingCapStartDate	= N.BILLINGCAPSTARTDATE,
		@bBillingCapResetFlag	= N.BILLINGCAPRESETFLAG		
	from	IPNAME N
	left join TABLECODES PT	on (PT.USERCODE	= N.BILLINGCAPPERIODTYPE and PT.TABLETYPE = 127)
	-- Check the instructor if the WIP was recorded against a case
	left join CASENAME CN	on (CN.CASEID = @pnCaseKey
				and CN.NAMETYPE = 'I'
				and (CN.EXPIRYDATE>getdate() or CN.EXPIRYDATE IS NULL)
				and CN.SEQUENCE =
					(select min(SEQUENCE) 
					from CASENAME CN1
			                where CN1.CASEID=CN.CASEID
			          	and CN1.NAMETYPE=CN.NAMETYPE
					and(CN1.EXPIRYDATE is null or CN1.EXPIRYDATE>getdate())))
	WHERE 	((N.NAMENO = @pnNameKey) 
	OR 	 (@pnNameKey is null and N.NAMENO = CN.NAMENO))"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nBillingCap			decimal(11,2)		OUTPUT,
			  @nBillingCapPeriod		int			OUTPUT,
			  @sBillingCapPeriodTypeDesc	nvarchar(20)		OUTPUT,
			  @nBillingCapNameKey		int			OUTPUT,
			  @dBillingCapStartDate		datetime		OUTPUT,
			  @bBillingCapResetFlag		bit			OUTPUT,
			  @sBillingCapPeriodType	nvarchar(1)		OUTPUT,
			  @pnNameKey			int,
			  @pnCaseKey			int',
			  @nBillingCap			= @nBillingCap			OUTPUT,
			  @nBillingCapPeriod		= @nBillingCapPeriod		OUTPUT,
			  @sBillingCapPeriodTypeDesc	= @sBillingCapPeriodTypeDesc	OUTPUT,
			  @nBillingCapNameKey		= @nBillingCapNameKey		OUTPUT,
			  @dBillingCapStartDate		= @dBillingCapStartDate		OUTPUT,
			  @bBillingCapResetFlag		= @bBillingCapResetFlag		OUTPUT,
			  @sBillingCapPeriodType	= @sBillingCapPeriodType	OUTPUT,
			  @pnNameKey			= @pnNameKey,
			  @pnCaseKey			= @pnCaseKey

	If @nErrorCode = 0
	and @pbDebug = 1
	Begin
		print '@nBillingCap = ' + cast(@nBillingCap as nvarchar(20))
		print '@nBillingCapNameKey = ' + cast(@nBillingCapNameKey as nvarchar(20))
		print '@nBillingCapPeriod = ' + @sBillingCapPeriodTypeDesc
		print '@dBillingCapStartDate = ' + cast(@dBillingCapStartDate as nvarchar(20))
		print '@bBillingCapResetFlag = ' + cast(@bBillingCapResetFlag as nvarchar(5))
	End
End

-- Local currency details
If @nErrorCode = 0
and (@bPrepaymentWarnOver = 1 or
     @nBudgetAmount is not null or
     @nCreditLimit is not null or 
     @nBillingCap is not null)
Begin
	exec @nErrorCode=ac_GetLocalCurrencyDetails
		@psCurrencyCode		= @sLocalCurrencyCode	output,
		@pnDecimalPlaces	= @nLocalDecimalPlaces	output,
		@pnUserIdentityId	= @pnUserIdentityId,
		@pbCalledFromCentura	= @pbCalledFromCentura

	If @nErrorCode = 0
	and @pbDebug = 1
	Begin
		print '@nLocalDecimalPlaces = ' + cast(@nLocalDecimalPlaces as nvarchar(20))
	End
End

-- Is there a name restriction for the @pnCaseKey?
If @nErrorCode = 0
and @pnCaseKey is not null
Begin
	Set @sSQLString = "
	select  @nNameRestictionSeverity =
		case D.ACTIONFLAG
			when 0 then 2 	-- Display Error => User Error
			when 1 then 1 	-- Display Warning => Warning
			when 2 then 2 	-- Password => User Error
			else 1		-- Warning by default
		end,
		@sRequiredPassword = D.CLEARPASSWORD
	from	DEBTORSTATUS D
	where	D.BADDEBTOR =
		(select	substring(
			max(cast(case D.ACTIONFLAG
				when 0 then 2 	-- Display Error => User Error
				when 1 then 1 	-- Display Warning => Warning
				when 2 then 2 	-- Password => User Error
				else 1		-- Warning by default
				end as char(1))+
			    cast(D.BADDEBTOR as char(8))
			   ),2,8)
		from	NAMETYPE NT
		join 	CASENAME CN	on (CN.CASEID = @pnCaseKey
					and CN.NAMETYPE = NT.NAMETYPE
					and (CN.EXPIRYDATE>getdate() or CN.EXPIRYDATE IS NULL))
		join	IPNAME IP	on (IP.NAMENO = CN.NAMENO)
		join	DEBTORSTATUS D	on (D.BADDEBTOR = IP.BADDEBTOR)
		where 	NT.NAMERESTRICTFLAG=1
		--	Exclude No Action
		and	D.ACTIONFLAG <> 3)"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nNameRestictionSeverity	tinyint			OUTPUT,
			  @sRequiredPassword		nvarchar(10)		OUTPUT,
			  @pnCaseKey			int',
			  @nNameRestictionSeverity	= @nNameRestictionSeverity	OUTPUT,
			  @sRequiredPassword		= @sRequiredPassword		OUTPUT,
			  @pnCaseKey			= @pnCaseKey
End

-- Is there a name restriction for the @pnNameKey?
If @nErrorCode = 0
and @pnNameKey is not null
Begin
	Set @sSQLString = "
	select  @nNameRestictionSeverity =
		case D.ACTIONFLAG
			when 0 then 2 	-- Display Error => User Error
			when 1 then 1 	-- Display Warning => Warning
			when 2 then 2 	-- Password => User Error
			else 1		-- Warning by default
		end,
		@sRequiredPassword = D.CLEARPASSWORD
	from	DEBTORSTATUS D
	where	D.BADDEBTOR =
		(select	substring(
			max(cast(case D.ACTIONFLAG
				when 0 then 2 	-- Display Error => User Error
				when 1 then 1 	-- Display Warning => Warning
				when 2 then 2 	-- Password => User Error
				else 1		-- Warning by default
				end as char(1))+
			    cast(D.BADDEBTOR as char(8))
			   ),2,8)
		from	IPNAME IP
		join	DEBTORSTATUS D	on (D.BADDEBTOR = IP.BADDEBTOR)
		where 	IP.NAMENO = @pnNameKey
		--	Exclude No Action
		and	D.ACTIONFLAG <> 3)"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nNameRestictionSeverity	tinyint			OUTPUT,
			  @sRequiredPassword		nvarchar(10)		OUTPUT,
			  @pnNameKey			int',
			  @nNameRestictionSeverity	= @nNameRestictionSeverity	OUTPUT,
			  @sRequiredPassword		= @sRequiredPassword		OUTPUT,
			  @pnNameKey			= @pnNameKey
End

If @nErrorCode = 0
and @bRestrictOnWip = 0
and @nNameRestictionSeverity is not null
and @pnApplicationID != 32
Begin
	-- Always warning unless the Restrict on WIP site control is turned on
	Set @nNameRestictionSeverity = @nWarning
	Set @sRequiredPassword = null
End

If @nErrorCode = 0
and @pbDebug = 1
Begin
	print '@nNameRestictionSeverity = ' + cast(@nNameRestictionSeverity as nvarchar)
	print '@sRequiredPassword = ' + @sRequiredPassword
End

If @nErrorCode = 0
and @nNameRestictionSeverity > @nMaximumSeverity
Begin
	Set @nMaximumSeverity = @nNameRestictionSeverity
End

-- Check Credit Limit
If @nErrorCode = 0
and @nCreditLimit is not null
Begin
	Set @sSQLString = "
	select	@nReceivableBalance = sum(BALANCE)
	from	ACCOUNT
	where	NAMENO = @nCreditLimitNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nReceivableBalance	decimal(11,2)		OUTPUT,
			  @nCreditLimitNameKey	int',
			  @nReceivableBalance	= @nReceivableBalance 	OUTPUT,
			  @nCreditLimitNameKey	= @nCreditLimitNameKey

	If @nErrorCode = 0
	and @pbDebug = 1
	Begin
		print '@nReceivableBalance = ' + cast(@nReceivableBalance as nvarchar(20))
	End

	If @nErrorCode = 0
	and @nCreditLimit < @nReceivableBalance
	Begin
		If @nMaximumSeverity < @nWarning
		Begin
			Set @nMaximumSeverity = @nWarning
		End
	End
	Else
	Begin
		-- No warning to report
		Set @nCreditLimit = null
		Set @nReceivableBalance = null
	End
End

-- Check Billing Cap
If @nErrorCode = 0
and @nBillingCap is not null
Begin

	Set @sSQLString = "
	Select @nThresholdPercent = ISNULL(COLINTEGER,0)
	from SITECONTROL
	where CONTROLID = 'Billing Cap Threshold Percent'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nThresholdPercent	int			OUTPUT',
				  @nThresholdPercent	= @nThresholdPercent 	OUTPUT

	If @nBillingCapPeriod is not null and @nErrorCode = 0
	Begin		
		SET @dBillingCapDate = case when @sBillingCapPeriodType = 'D' then DATEADD(d,@nBillingCapPeriod, @dBillingCapStartDate)
					when @sBillingCapPeriodType = 'W' then DATEADD(ww,@nBillingCapPeriod, @dBillingCapStartDate)
					when @sBillingCapPeriodType = 'M' then DATEADD(mm,@nBillingCapPeriod, @dBillingCapStartDate)
					when @sBillingCapPeriodType= 'Y' then DATEADD(yy,@nBillingCapPeriod, @dBillingCapStartDate)
					end
		
		If @dBillingCapDate < @pdTransactionDate
		Begin
			If @bBillingCapResetFlag = 1
			Begin
				WHILE (@dBillingCapDate < @pdTransactionDate)
				BEGIN	
					SET @dBillingCapStartDate = @dBillingCapDate
								
					SET @dBillingCapDate = case when @sBillingCapPeriodType = 'D' then DATEADD(d,@nBillingCapPeriod, @dBillingCapDate)
						when @sBillingCapPeriodType = 'W' then DATEADD(ww,@nBillingCapPeriod, @dBillingCapDate)
						when @sBillingCapPeriodType = 'M' then DATEADD(mm,@nBillingCapPeriod, @dBillingCapDate)
						when @sBillingCapPeriodType= 'Y' then DATEADD(yy,@nBillingCapPeriod, @dBillingCapDate)
						end
				END
			End
		End 
		
		If @dBillingCapDate >= @pdTransactionDate
		Begin
		
			Set @sSQLString = "
			select	@nAmountBilled = sum(CASE WHEN OIC.CASEID IS NULL THEN OI.LOCALVALUE ELSE OIC.LOCALVALUE END)
			FROM OPENITEM OI  
			LEFT JOIN OPENITEMCASE OIC ON  	
				( OI.ITEMENTITYNO = OIC.ITEMENTITYNO 
				AND OI.ITEMTRANSNO = OIC.ITEMTRANSNO 
				AND OI.ACCTENTITYNO = OIC.ACCTENTITYNO 
				AND OI.ACCTDEBTORNO = OIC.ACCTDEBTORNO)
			WHERE  OI.STATUS = 1  
			AND  OI.ITEMTYPE = 510 
			AND OI.ACCTDEBTORNO = @nBillingCapNameKey
			AND (OIC.CASEID IS NULL OR (OIC.STATUS IN (0,1, 2, 9)) )  
			AND OI.POSTDATE >= @dBillingCapStartDate"			 

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nAmountBilled		decimal(11,2)		OUTPUT,
					  @pnEntityKey			int,
					  @dBillingCapStartDate		datetime,
					  @nBillingCapNameKey		int',
					  @nAmountBilled		= @nAmountBilled 	OUTPUT,
					  @pnEntityKey			= @pnEntityKey,
					  @dBillingCapStartDate		= @dBillingCapStartDate,
					  @nBillingCapNameKey		= @nBillingCapNameKey
	

			If @nErrorCode = 0
			and @pbDebug = 1
			Begin
				print '@nAmountBilled = ' + cast(@nAmountBilled as nvarchar(20))
			End			

			If @nErrorCode = 0
			and (@nBillingCap - (@nBillingCap * ISNULL(@nThresholdPercent,0)/100)) < @nAmountBilled 
			Begin
				If @nMaximumSeverity < @nWarning
				Begin
					Set @nMaximumSeverity = @nWarning
				End
			End
			Else
			Begin
				-- No warning to report
				Set @nBillingCap = null
				Set @nBillingCapPeriod = null
				Set @sBillingCapPeriodType = null
				Set @sBillingCapPeriodTypeDesc = null
				Set @dBillingCapDate = null
				Set @dBillingCapStartDate = null
				Set @bBillingCapResetFlag = null
				Set @nAmountBilled = null
			End
		End	
		Else
		Begin
			-- No warning to report
			Set @nBillingCap = null
			Set @nBillingCapPeriod = null
			Set @sBillingCapPeriodType = null
			Set @sBillingCapPeriodTypeDesc = null
			Set @dBillingCapDate = null
			Set @dBillingCapStartDate = null
			Set @bBillingCapResetFlag = null
			Set @nAmountBilled = null
		End			  
	End		
	
End

-- Check Budget
If @nErrorCode = 0
and @nBudgetAmount is not null
Begin
        Declare @sWhereString nvarchar(4000)

        Set @sWhereString = CASE WHEN @dtBudgetStartDate is not null THEN 
             CASE WHEN @dtBudgetEndDate is not null THEN " between @dtBudgetStartDate and @dtBudgetEndDate"
                  ELSE " >= @dtBudgetStartDate" 
             END
             ELSE CASE WHEN @dtBudgetEndDate is not null THEN " <= @dtBudgetEndDate"
                       ELSE ""
                  END
        END

	Set @sSQLString = "
	        select	@nBilledToDate = isnull(WHBILL.BilledToDate,0), -- Consume/Billing
		        @nUsedTotal = isnull(WHSUM.USEDTOTAL,0) -- Create, Adjust Up, Adjust Down 
	        from CASES C
                left join (
			SELECT CASEID, sum(isnull(LOCALTRANSVALUE, 0)) AS USEDTOTAL
			from WORKHISTORY 	
                        where STATUS<>0
			and MOVEMENTCLASS in (1,4,5)"
                If @sWhereString <> ""
                Begin
                         Set @sSQLString= @sSQLString + char(10) + "and TRANSDATE " +  @sWhereString + char(10) 
                End
		Set @sSQLString= @sSQLString + char(10) +"	group by CASEID) AS WHSUM on (C.CASEID = WHSUM.CASEID)
		left join (SELECT WH1.CASEID, sum(isnull(-WH1.LOCALTRANSVALUE,0)) as BilledToDate
				from WORKHISTORY WH1
                                left join WORKHISTORY WH2 on (WH1.ENTITYNO = WH2.ENTITYNO 
                                                and WH1.TRANSNO = WH2.TRANSNO 
                                                and WH1.WIPSEQNO = WH2.WIPSEQNO 
                                                and WH2.STATUS <> 0 
                                                and WH2.MOVEMENTCLASS in (1,4,5))
                                where WH1.STATUS <> 0
				and   WH1.MOVEMENTCLASS=2"
                If @sWhereString <> ""
                Begin
                        Set @sSQLString= @sSQLString + char(10) +"   
                                and ((WH2.TRANSDATE  " + @sWhereString + ") 
                                or (WH2.TRANSDATE is null and WH1.TRANSDATE  " + @sWhereString + "))" 
                End
                Set @sSQLString= @sSQLString + char(10) +"                                            
				group by WH1.CASEID) WHBILL on (WHBILL.CASEID=C.CASEID)
                where C.CASEID = @pnCaseKey"        
        
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nBilledToDate	decimal(11,2)		OUTPUT,
			  @nUsedTotal		decimal(11,2)		OUTPUT,
                          @dtBudgetStartDate    datetime,
                          @dtBudgetEndDate      datetime,
			  @pnCaseKey		int',
			  @nBilledToDate	= @nBilledToDate 	OUTPUT,
			  @nUsedTotal		= @nUsedTotal 		OUTPUT,
                          @dtBudgetStartDate    = @dtBudgetStartDate,
                          @dtBudgetEndDate      = @dtBudgetEndDate,
			  @pnCaseKey		= @pnCaseKey

	If @nErrorCode = 0
	and @pbDebug = 1
	Begin
		print '@nBilledToDate = ' + cast(@nBilledToDate as nvarchar(20))
		print '@nUsedTotal = ' + cast(@nUsedTotal as nvarchar(20))
	End

	If @nErrorCode = 0
	and @nUsedTotal > (@nBudgetAmount * @nBudgetPercentage/100)
	Begin
		If @nMaximumSeverity < @nWarning
		Begin
			Set @nMaximumSeverity = @nWarning
		End

		Set @sSQLString = "
		select 	@nUnbilledWip = ISNULL(sum(W.BALANCE),0)
		from 	WORKINPROGRESS W
		where	W.CASEID = @pnCaseKey
		and	W.STATUS <> 0 -- Draft"              
	
                If @sWhereString <> ""
                Begin
                        Set @sSQLString= @sSQLString + char(10) +"   
                                 and     W.TRANSDATE " + CHAR(10) + @sWhereString
                End

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nUnbilledWip		decimal(11,2)	OUTPUT,
                                 @dtBudgetStartDate     datetime,
                                 @dtBudgetEndDate       datetime,
				  @pnCaseKey		int',
				  @nUnbilledWip		= @nUnbilledWip OUTPUT,
                                  @dtBudgetStartDate    = @dtBudgetStartDate,
                                  @dtBudgetEndDate      = @dtBudgetEndDate,
				  @pnCaseKey		= @pnCaseKey

		If @nErrorCode = 0
		and @pbDebug = 1
		Begin
			print '@nUnbilledWip = ' + cast(@nUnbilledWip as nvarchar(20))
		End

	End
	Else
	Begin
		-- No warning to report
		Set @nBudgetAmount = null
		Set @nBilledToDate = null
		Set @nUsedTotal = null
                Set @nBudgetPercentage = null
	End
End

-- Check Prepayments
If @nErrorCode = 0
and @bPrepaymentWarnOver = 1
Begin
	If @pnCaseKey is not null
	Begin
		-- Prepayments for case
		Set @sSQLString = "
		SELECT @nPrepaymentsForCase = SUM( round((-OI.ITEMPRETAXVALUE * OIC.LOCALVALUE / OI.LOCALVALUE) * 
			(OIC.LOCALBALANCE / OIC.LOCALVALUE), @nLocalDecimalPlaces) )
		FROM OPENITEMCASE OIC
		JOIN OPENITEM OI	on (OI.ITEMENTITYNO = OIC.ITEMENTITYNO
					and OI.ITEMTRANSNO = OIC.ITEMTRANSNO
					and OI.ACCTENTITYNO = OIC.ACCTENTITYNO
					and OI.ACCTDEBTORNO = OIC.ACCTDEBTORNO)
		WHERE OIC.CASEID = @pnCaseKey
		AND OIC.STATUS <> 0 -- Draft
		AND ((@pnEntityKey is null) or (OIC.ACCTENTITYNO = @pnEntityKey))
		AND OI.ITEMTYPE = 523 -- Prepayment"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nPrepaymentsForCase	decimal(11,2)		OUTPUT,
				  @pnCaseKey		int,
				  @pnEntityKey		int,
				  @nLocalDecimalPlaces	tinyint',
				  @nPrepaymentsForCase	= @nPrepaymentsForCase 	OUTPUT,
				  @pnCaseKey		= @pnCaseKey,
				  @pnEntityKey		= @pnEntityKey,
				  @nLocalDecimalPlaces	= @nLocalDecimalPlaces
		
		If @nErrorCode = 0
		and @pbDebug = 1
		Begin
			print '@nPrepaymentsForCase = ' + cast(@nPrepaymentsForCase as nvarchar(20))
		End

		-- Prepayments for Debtor
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			select 	@nPrepaymentsForDebtor = 
					SUM( round(-OI.ITEMPRETAXVALUE *
					(OI.LOCALBALANCE/OI.LOCALVALUE),
					@nLocalDecimalPlaces) )
			from 	OPENITEM OI
			join 	CASES C		on (C.CASEID = @pnCaseKey)
						-- For all debtors of the case
			join	CASENAME CN	on (CN.CASEID = C.CASEID
						and CN.NAMETYPE = 'D'
						and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
						and CN.NAMENO = OI.ACCTDEBTORNO)
			where 	((@pnEntityKey is null) or (OI.ACCTENTITYNO = @pnEntityKey))
			and	((OI.PAYPROPERTYTYPE = C.PROPERTYTYPE OR OI.PAYPROPERTYTYPE IS NULL))
			and	OI.STATUS <> 0 -- Draft
			and 	OI.ITEMTYPE = 523 -- Prepayment
				-- Exclude anything already included in the case total
			and 	NOT EXISTS
				(select 1
				from 	OPENITEMCASE OIC
				where 	OI.ITEMENTITYNO = OIC.ITEMENTITYNO and
					OI.ITEMTRANSNO = OIC.ITEMTRANSNO and
					OI.ACCTENTITYNO = OIC.ACCTENTITYNO and
					OI.ACCTDEBTORNO = OIC.ACCTDEBTORNO )"
			
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nPrepaymentsForDebtor decimal(11,2)		OUTPUT,
					  @pnCaseKey		int,
					  @pnEntityKey		int,
					  @nLocalDecimalPlaces	tinyint',
					  @nPrepaymentsForDebtor = @nPrepaymentsForDebtor 	OUTPUT,
					  @pnCaseKey		= @pnCaseKey,
					  @pnEntityKey		= @pnEntityKey,
					  @nLocalDecimalPlaces	= @nLocalDecimalPlaces
			
			If @nErrorCode = 0
			and @pbDebug = 1
			Begin
				print '@nPrepaymentsForDebtor = ' + cast(@nPrepaymentsForDebtor as nvarchar(20))
			End
		End

		-- All WIP
		If @nErrorCode = 0
		and (@nPrepaymentsForCase > 0 or
		     @nPrepaymentsForDebtor > 0)
		Begin
			Set @sSQLString = "
			select	@nAllWip = SUM(BALANCE)
			from	WORKINPROGRESS
			where	CASEID = @pnCaseKey"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nAllWip		decimal(11,2)		OUTPUT,
					  @pnCaseKey		int',
					  @nAllWip 		= @nAllWip 	OUTPUT,
					  @pnCaseKey		= @pnCaseKey
			
			If @nErrorCode = 0
			and @pbDebug = 1
			Begin
				print '@nAllWip = ' + cast(@nAllWip as nvarchar(20))
			End
		End

		-- Total Time
		If @nErrorCode = 0
		and (@nPrepaymentsForCase > 0 or
		     @nPrepaymentsForDebtor > 0)
		Begin
			Set @sSQLString = "
			select 	@nTotalTime = SUM(D.TIMEVALUE)
			from	DIARY D
			where	D.CASEID = @pnCaseKey 
			and	D.TRANSNO IS NULL
			and	D.ISTIMER=0
			and	D.TIMEVALUE is not null"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTotalTime		decimal(11,2)		OUTPUT,
					  @pnCaseKey		int',
					  @nTotalTime 		= @nTotalTime 	OUTPUT,
					  @pnCaseKey		= @pnCaseKey
			
			If @nErrorCode = 0
			and @pbDebug = 1
			Begin
				print '@nTotalTime = ' + cast(@nTotalTime as nvarchar(20))
			End
		End
	End

	If @pnNameKey is not null
	Begin
		Set @sSQLString = "
		select @nPrepaymentsForDebtor = 
			SUM( round(-OI.ITEMPRETAXVALUE * 
			          (OI.LOCALBALANCE/OI.LOCALVALUE),@nLocalDecimalPlaces) )
		from OPENITEM OI
		where 	((@pnEntityKey is null) or (OI.ACCTENTITYNO = @pnEntityKey))
		and	OI.ACCTDEBTORNO = @pnNameKey
		and	OI.STATUS <> 0
		and 	OI.ITEMTYPE = 523 -- Prepayment
		-- Exclude anything held at the case level
		and 	NOT EXISTS
			(select 1
			from 	OPENITEMCASE OIC
			where 	OI.ITEMENTITYNO = OIC.ITEMENTITYNO and
				OI.ITEMTRANSNO = OIC.ITEMTRANSNO and
				OI.ACCTENTITYNO = OIC.ACCTENTITYNO and
				OI.ACCTDEBTORNO = OIC.ACCTDEBTORNO )"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nPrepaymentsForDebtor decimal(11,2)		OUTPUT,
				  @pnNameKey		int,
				  @pnEntityKey		int,
				  @nLocalDecimalPlaces	tinyint',
				  @nPrepaymentsForDebtor = @nPrepaymentsForDebtor 	OUTPUT,
				  @pnNameKey		= @pnNameKey,
				  @pnEntityKey		= @pnEntityKey,
				  @nLocalDecimalPlaces	= @nLocalDecimalPlaces
		
		If @nErrorCode = 0
		and @pbDebug = 1
		Begin
			print '@nPrepaymentsForDebtor = ' + cast(@nPrepaymentsForDebtor as nvarchar(20))
		End

		-- All WIP
		If @nErrorCode = 0
		and @nPrepaymentsForDebtor > 0
		Begin
			Set @sSQLString = "
			select	@nAllWip = SUM(BALANCE)
			from	WORKINPROGRESS
			where	ACCTCLIENTNO = @pnNameKey"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nAllWip		decimal(11,2)	OUTPUT,
					  @pnNameKey		int',
					  @nAllWip 		= @nAllWip 	OUTPUT,
					  @pnNameKey		= @pnNameKey
			
			If @nErrorCode = 0
			and @pbDebug = 1
			Begin
				print '@nAllWip = ' + cast(@nAllWip as nvarchar(20))
			End
		End

		-- Total Time
		If @nErrorCode = 0
		and @nPrepaymentsForDebtor > 0
		Begin
			Set @sSQLString = "
			select 	@nTotalTime = SUM(D.TIMEVALUE)
			from	DIARY D
			where	D.NAMENO = @pnNameKey 
			and	D.TRANSNO IS NULL
			and	D.ISTIMER=0
			and	D.TIMEVALUE is not null"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTotalTime		decimal(11,2)		OUTPUT,
					  @pnNameKey		int',
					  @nTotalTime 		= @nTotalTime 	OUTPUT,
					  @pnNameKey		= @pnNameKey
			
			If @nErrorCode = 0
			and @pbDebug = 1
			Begin
				print '@nTotalTime = ' + cast(@nTotalTime as nvarchar(20))
			End
		End
	End

	If @nErrorCode = 0
	Begin
		Set @nPrepaymentsTotal = isnull(@nPrepaymentsForCase,0) + isnull(@nPrepaymentsForDebtor,0)
		Set @nTotalWipAndTime = isnull(@nAllWip,0) + isnull(@nTotalTime,0)

		If @pbDebug = 1
		Begin
			print '@nPrepaymentsTotal = ' + cast(@nPrepaymentsTotal as nvarchar(20))
			print '@nTotalWipAndTime = ' + cast(@nTotalWipAndTime as nvarchar(20))
		End
	End

	If @nErrorCode = 0
	and @nPrepaymentsTotal > 0
	and @nTotalWipAndTime > @nPrepaymentsTotal
	Begin
		If @nMaximumSeverity < @nWarning
		Begin
			Set @nMaximumSeverity = @nWarning
		End

		-- Only show total for case level WIP.
		If @pnCaseKey is null
		Begin
			Set @nPrepaymentsTotal = null
		End
	End
	Else
	Begin
		-- No warning to report
		Set @nTotalWipAndTime = null
		Set @nPrepaymentsTotal = null
		Set @nPrepaymentsForCase = null
		Set @nPrepaymentsForDebtor = null
	End
End

-- Outstanding timers
If @nErrorCode = 0
Begin
	If @pbCalledFromCentura = 0
	and @pnApplicationID = 4
	and @pnStaffKey is not null
	Begin
		Set @sSQLString="
		select	@bHasOustandingTimers = 1
		from	DIARY D
		where	D.ISTIMER = 1
			-- Strip out the time portion from getdate()
		and	D.STARTTIME < cast(convert(nvarchar, getdate(), 112) as datetime)
		and	D.EMPLOYEENO = @pnStaffKey"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@bHasOustandingTimers		bit			OUTPUT,
				  @pnStaffKey			int',
				  @bHasOustandingTimers		= @bHasOustandingTimers	OUTPUT,
				  @pnStaffKey			= @pnStaffKey
	End

	If @nErrorCode = 0
	and @pbDebug = 1
	Begin
		print '@bHasOustandingTimers = ' + cast(@bHasOustandingTimers as nvarchar(20))
	End

	If @nErrorCode = 0
	and @bHasOustandingTimers = 1
	Begin
		If @nMaximumSeverity < @nWarning
		Begin
			Set @nMaximumSeverity = @nWarning
		End

		Set @sTimerWarning = dbo.fn_GetAlertXML('AC15', 'You have one or more timers from previous days.  Please complete your timers.',
						null, null, null, null, null)
	End
End

-- Produce results
If @nErrorCode = 0
and @nMaximumSeverity > -1
Begin
	-- Additional Information result set
	Set @sSQLString="
	select 	@nMaximumSeverity 		as MaximumSeverity,
		@sRequiredPassword 		as RequiredPassword,
		0				as IsConfirmed,
		@sLocalCurrencyCode 		as LocalCurrencyCode,
		@nLocalDecimalPlaces		as LocalDecimalPlaces,
		@nReceivableBalance		as ReceivableBalance,
		@nCreditLimit 			as CreditLimit,
		@nBudgetAmount 			as BudgetAmount,
                CASE WHEN @nBudgetAmount <> 0
                        THEN cast((ISNULL(@nUsedTotal,0) *100 /@nBudgetAmount) as decimal(11,2))
                     ELSE NULL  
                END                             as BudgetPercentageUsed,
		@nBilledToDate 			as BilledToDate,
		@nUnbilledWip 			as UnbilledWip,
		@nUsedTotal 			as UsedTotal,
		@nPrepaymentsForCase 		as PrepaymentsForCase,
		@nPrepaymentsForDebtor 		as PrepaymentsForDebtor,
		@nPrepaymentsTotal		as PrepaymentsTotal,
		@nTotalWipAndTime		as TotalWipAndTime,
		@nBillingCap			as BillingCap,
		@nBillingCapPeriod		as BillingCapPeriod,
		@sBillingCapPeriodType		as BillingCapPeriodType,
		@sBillingCapPeriodTypeDesc	as BillingCapPeriodTypeDesc,
		@nAmountBilled			as AmountBilled,
		@dBillingCapStartDate		as BillingCapStartDate,
		@bBillingCapResetFlag		as BillingCapResetFlag"  

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@nMaximumSeverity		smallint,
	 	  @sRequiredPassword		nvarchar(10),
		  @sLocalCurrencyCode		nvarchar(3),
		  @nLocalDecimalPlaces		tinyint,
		  @nReceivableBalance		decimal(11,2),
		  @nCreditLimit			decimal(11,2),
		  @nBudgetAmount		decimal(11,2),
		  @nBilledToDate		decimal(11,2),
		  @nUnbilledWip			decimal(11,2),
		  @nUsedTotal			decimal(11,2),
		  @nPrepaymentsForCase		decimal(11,2),
		  @nPrepaymentsForDebtor	decimal(11,2),
		  @nPrepaymentsTotal		decimal(11,2),
		  @nTotalWipAndTime		decimal(11,2),
		  @nBillingCap			decimal(11,2),
		  @nBillingCapPeriod		int,
		  @sBillingCapPeriodType	nvarchar(1),
		  @sBillingCapPeriodTypeDesc	nvarchar(20),
		  @nAmountBilled		decimal(11,2),
		  @dBillingCapStartDate		datetime,
		  @bBillingCapResetFlag		bit',
		  @nMaximumSeverity		= @nMaximumSeverity,
	 	  @sRequiredPassword		= @sRequiredPassword,
		  @sLocalCurrencyCode		= @sLocalCurrencyCode,
		  @nLocalDecimalPlaces		= @nLocalDecimalPlaces,
		  @nReceivableBalance		= @nReceivableBalance,
		  @nCreditLimit			= @nCreditLimit,
		  @nBudgetAmount		= @nBudgetAmount,
		  @nBilledToDate		= @nBilledToDate,
		  @nUnbilledWip			= @nUnbilledWip,
		  @nUsedTotal			= @nUsedTotal,
		  @nPrepaymentsForCase		= @nPrepaymentsForCase,
		  @nPrepaymentsForDebtor	= @nPrepaymentsForDebtor,
		  @nPrepaymentsTotal		= @nPrepaymentsTotal,
		  @nTotalWipAndTime		= @nTotalWipAndTime,
		  @nBillingCap			= @nBillingCap,
		  @nBillingCapPeriod		= @nBillingCapPeriod,
		  @sBillingCapPeriodType	= @sBillingCapPeriodType,
		  @sBillingCapPeriodTypeDesc	= @sBillingCapPeriodTypeDesc,
		  @nAmountBilled		= @nAmountBilled,
		  @dBillingCapStartDate		= @dBillingCapStartDate,
		  @bBillingCapResetFlag		= @bBillingCapResetFlag

	-- AINamesRestricted result set
	If @nErrorCode = 0
	and @nNameRestictionSeverity is not null
	Begin
		If @pnCaseKey is not null
		Begin
			Set @sSQLString = "
			select	dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as Name,
				NT.DESCRIPTION as NameType,
				D.ACTIONFLAG as RestrictionActionKey,
				D.DEBTORSTATUS as Restriction
			from	NAMETYPE NT
			join 	CASENAME CN	on (CN.CASEID = @pnCaseKey
						and CN.NAMETYPE = NT.NAMETYPE
						and (CN.EXPIRYDATE>getdate() or CN.EXPIRYDATE IS NULL))
			join	IPNAME IP	on (IP.NAMENO = CN.NAMENO)
			join	DEBTORSTATUS D	on (D.BADDEBTOR = IP.BADDEBTOR)
			join	NAME N		on (N.NAMENO = IP.NAMENO)
			where 	NT.NAMERESTRICTFLAG=1
			--	Exclude No Action
			and	D.ACTIONFLAG <> 3"
		
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey			int',
					  @pnCaseKey			= @pnCaseKey
		End
		Else If @pnNameKey is not null
		Begin
			Set @sSQLString = "
			select	dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as Name,
				NULL as NameType,
				D.ACTIONFLAG as RestrictionActionKey,
				D.DEBTORSTATUS as Restriction
			from	IPNAME IP
			join	DEBTORSTATUS D	on (D.BADDEBTOR = IP.BADDEBTOR)
			join	NAME N		on (N.NAMENO = IP.NAMENO)
			where 	IP.NAMENO = @pnNameKey
			--	Exclude No Action
			and	D.ACTIONFLAG <> 3"
		
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey			int',
					  @pnNameKey			= @pnNameKey
		End
	End
	Else
	Begin
		-- Return an empty result set
		Set @sSQLString = "
		select	NULL as Name,
			NULL as NameType,
			NULL as RestrictionActionKey,
			NULL as Restriction
		where	1=2"
	
		exec @nErrorCode=sp_executesql @sSQLString
	End
	
	-- AIApplicationAlert result set
	If @nErrorCode = 0
	Begin
		-- If more messages are implemented, may need to convert 
		-- to a table variable implementation
		If @sTimerWarning is not null
		Begin
			Set @sSQLString = "
			select 	@nWarning 	as Severity,
				@sTimerWarning 	as AlertXML"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nWarning		tinyint,
					  @sTimerWarning	nvarchar(400)',
					  @nWarning		= @nWarning,
					  @sTimerWarning	= @sTimerWarning
		End
	End
End

Return @nErrorCode
GO

Grant execute on dbo.wp_ListWipWarnings to public
GO
