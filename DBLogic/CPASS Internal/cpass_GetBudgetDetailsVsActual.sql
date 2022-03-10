use cpalive
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cpass_GetBudgetDetailsVsActual]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[cpass_GetBudgetDetailsVsActual]
GO

set concat_null_yields_null off
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE     PROCEDURE dbo.cpass_GetBudgetDetailsVsActual
(
	@psEntryPoint		nvarchar(20)
	,@pdtFromDate		datetime	= null
	,@pdtToDate			datetime	= null
	,@pnUserIdentityId	int	    	= null
	,@psCulture			nvarchar(10)= null
	,@pnCaseId			int			= null -- optional 
	,@psFamily			nvarchar(20)= null  -- the Family of Cases to be reported on
	,@pnCostCalculation				int		= 0
)
AS
-- PROCEDURE :	cpass_GetBudgetDetailsVsActual
-- DESCRIPTION:	Returns a budget information for a faily of cases
-- NOTES:	
-- VERSION:	2
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 02 Nov 2004	MF		1	Procedure created
-- 05 Nov 2004	MF	RFC1976	2	Extend the Property Types to be reported on.
-- 04 Aug 2006	JD			Removed insert...exec statment. Added property type to the result set.


Set nocount on
Set concat_null_yields_null off

--cs_getbudget

-- The Cases to report on if no temporary table with the Cases
-- has been supplied
Create table #TempCasesToList(
		CASEID			int		not null
		)

-- A temporary table to hold results for multiple cases is required.
-- A table variable could not be used because dynamic SQL to load the rows is required.
Create table #TempCaseBudget(
		CASEID				int		not null,
		BilledToDate			decimal(11, 2) 	null,
		UnbilledWIP			decimal(11, 2) 	null,
		WriteUpDown			decimal(11, 2) 	null,
		UsedTotal			decimal(11, 2) 	null,
		Services			decimal(11, 2) 	null,
		Disbursements			decimal(11, 2) 	null,
		Overheads			decimal(11, 2) 	null,
		BudgetBilled			decimal(11, 2) 	null,
		UnpostedWIP			decimal(11, 2) 	null,
		TotalTimeAsMinutes		int            	null,
		UnpostedTimeAsMinutes		int            	null,
		ProfitAmount1			decimal(11, 2) 	null,
		ProfitPercent1			decimal(11, 2) 	null,
		ProfitAmount2			decimal(11, 2) 	null,
		ProfitPercent2			decimal(11, 2) 	null,
		WorkHistoryCost1		decimal(11, 2)	null,
		WorkHistoryCost2		decimal(11, 2)	null,
		BudgetAmount			decimal(11, 2)	null,
		BudgetHours			smallint	null,
		BudgetUsed			decimal(11, 2)	null,
		RevisedBudgetAmount		decimal(11, 2)	null,
		RevisedBudgetHours		smallint	null,
		RevisedBudgetUsed		decimal(11, 2)	null,
		BudgetProfitAmount1		decimal(11, 2)	null,
		BudgetProfitPercent1		decimal(11, 2)	null,
		RevisedBudgetProfitAmount1	decimal(11, 2)	null,
		RevisedBudgetProfitPercent1	decimal(11, 2)	null,
		BudgetProfitAmount2		decimal(11, 2)  null,
		BudgetProfitPercent2		decimal(11, 2)	null,
		RevisedProfitAmount2		decimal(11, 2)	null,
		RevisedProfitPercent2		decimal(11, 2)	null,
		RevisedBudgetBilled		decimal(11, 2) 	null,
		TotalWorked			decimal(11, 2) 	null,
		BudgetedTimeAsMinutes		int		null,
		RevisedBudgetedTimeAsMinutes	int		null
		)

declare @TempTotals table (
		FamilyTitle			nvarchar(254)	collate database_default null,
		PropertyName			nvarchar(50)	collate database_default null,
		PropertyType			nchar(1)	collate database_default null,
		BudgetDays			decimal(11, 2)	null,
		BudgetFees			decimal(11, 2)	null,
		BudgetMargin			decimal(11, 2)	null,
		ActualDays			decimal(11, 2)	null,
		ActualFees			decimal(11, 2)	null,
		ActualMargin			decimal(11, 2)	null,
		Variance			decimal(11, 2)	null,
		SortSequence			nvarchar(2)	collate database_default null
		)

Declare @ErrorCode 		int
Declare @sSQLString		nvarchar(4000)
Declare @sOrderBy		nvarchar(100)

Declare @nBudgetAmount		decimal(11, 2)
Declare @nBudgetRevisedAmt	decimal(11, 2)
Declare @bCaseBudgetExists 	bit
Declare @bIsBillingPerformed	bit,

		@pnBudgetAmount			decimal(11, 2)	,
		@psGlobalTempTable		nvarchar(32)	, -- optional name of temporary table of CASEIDs to be reported on.
		-- The following parameters will be made redundant when the stored procedure is able to report on the
		-- temporary table created on the Case Summary screen.
		@psCaseType			nchar(1)	, -- the CaseType of Cases to be reported on
		@psPropertyType			nchar(1)	, -- the PropertyType of Cases to be reported on
		@pnInstructor			int		, -- the Instructors nameno for Cases to be reported on
		@pnOrderBy			tinyint,	-- 1-IRN; 2-BilledToDate DESC; 3-UnBilledWIP DESC; 4-UsedTotal DESC; 5-ProfitAmount1 DESC; 6-ProfitPercent1
		@pbCalledFromCentura		bit,
		@pbTotalsFromCase 		bit,	-- if @pbTotalsFromCase = 1 then obtain BudgetAmount and RevisedBudgetAmount from the Cases table.
		@pbHasBillingHistorySubject	bit		

Set @ErrorCode = 0
Set @pnBudgetAmount = null
Set @psGlobalTempTable = null
Set @psCaseType = null
Set @psPropertyType = null
Set @pnInstructor = null
Set @pnOrderBy = 1
--Set @pbCalledFromCentura = 1
Set @pbTotalsFromCase = 0
Set @pbHasBillingHistorySubject = null
set @psFamily = @psEntryPoint

--If @ErrorCode=0
--and @pbHasBillingHistorySubject is null
--Begin
--	Set @sSQLString="
--	Select	@pbHasBillingHistorySubject=TS.IsAvailable 
--	from dbo.fn_GetTopicSecurity(@pnUserIdentityId, 101, default) TS
--	where TS.IsAvailable=1"
--
--	exec @ErrorCode=sp_executesql @sSQLString,
--				N'@pbHasBillingHistorySubject	bit				OUTPUT,
--				  @pnUserIdentityId		int',
--				  @pbHasBillingHistorySubject	=@pbHasBillingHistorySubject 	OUTPUT,
--				  @pnUserIdentityId		=@pnUserIdentityId
--End

If  @ErrorCode=0 
and @pbTotalsFromCase = 1
Begin
	Set @sSQLString="
	Select  @nBudgetAmount 		= C.BUDGETAMOUNT,
		@nBudgetRevisedAmt 	= C.BUDGETREVISEDAMT,
		@bCaseBudgetExists	= CASE  WHEN CB.CASEID is null
					 	THEN 0  
						ELSE 1
					  END,
		@bIsBillingPerformed	= CASE  WHEN WH.CASEID is null
					 	THEN 0  
						ELSE 1
					  END
	from CASES C
	left join CASEBUDGET CB		on (CB.CASEID = C.CASEID)
	left join WORKHISTORY WH	on (WH.CASEID = C.CASEID
					and WH.MOVEMENTCLASS = 2) 
	where C.CASEID = @pnCaseId"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@nBudgetAmount	decimal(11, 2)		OUTPUT,
					  @nBudgetRevisedAmt	decimal(11, 2)		OUTPUT,
					  @bCaseBudgetExists	bit			OUTPUT,
					  @bIsBillingPerformed	bit			OUTPUT,
					  @pnCaseId		int',
					  @nBudgetAmount	=@nBudgetAmount		OUTPUT,
					  @nBudgetRevisedAmt	=@nBudgetRevisedAmt 	OUTPUT,
					  @bCaseBudgetExists	=@bCaseBudgetExists	OUTPUT,
					  @bIsBillingPerformed	=@bIsBillingPerformed	OUTPUT,
					  @pnCaseId		=@pnCaseId
End

--If   (@pbCalledFromCentura = 0 and
--      @ErrorCode = 0 and
--      @nBudgetAmount is null and
--      @nBudgetRevisedAmt is null and
--      @bCaseBudgetExists = 0 and
--      @bIsBillingPerformed = 0)
--or   (@pbCalledFromCentura = 0 and
--      @ErrorCode = 0 and
--      @pnCaseId is null) 	 
--or   (@pbCalledFromCentura = 0 and
--      @ErrorCode = 0 and
--     (@pbHasBillingHistorySubject is null or
--      @pbHasBillingHistorySubject = 0))
--Begin
--	Select	null	as CaseKey,
--		null	as BudgetAmount,
--		null	as BudgetedTimeAsMinutes,
--		null	as BudgetProfitAmount1,
--		null	as BudgetProfitPercent1,
--		null	as BudgetProfitAmount2,
--		null  	as BudgetProfitPercent2,
--		null	as BudgetUsed,
--		null	as BudgetBilled,
--		null	as RevisedBudgetAmount,
--		null	as RevisedBudgetedTimeAsMinutes,
--		null	as RevisedProfitAmount1,
--		null	as RevisedProfitPercent1,
--		null	as RevisedProfitAmount2,
--		null	as RevisedProfitPercent2,
--		null	as RevisedBudgetUsed,
--		null	as RevisedBudgetBilled,
--		null	as TotalTimeAsMinutes,
--		null	as Services,
--		null	as Disbursements,
--		null	as Overheads,
--		null	as UsedTotal,
--		null	as BilledToDate,
--		null	as WriteUpDown,
--		null	as UnbilledWIP,
--		null	as TotalWorked,
--		null	as UnpostedWIP,
--		null	as UnpostedTimeAsMinutes,
--		null	as ProfitAmount1,
--		null	as ProfitPercent1,
--		null	as ProfitAmount2,
--		null	as ProfitPercent2
--	where 1=0
--End
--Else
if	1=1
Begin

	-- For ease of coding, load the Cases to be reported on into a temporary
	-- table if a specific temporary table has not been provided.
	If @ErrorCode=0
	and @psGlobalTempTable is null
	Begin
		Set @psGlobalTempTable='#TempCasesToList'
		
		If @pnCaseId is not null
		Begin
			Set @sSQLString="
			insert into #TempCasesToList(CASEID)
			values(@pnCaseId)"
		
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnCaseId	int',
							  @pnCaseId=@pnCaseId
		End
		Else Begin
			Set @sSQLString="
			insert into #TempCasesToList(CASEID)
			Select distinct C.CASEID
			from CASES C
			left join CASENAME CN	on (CN.CASEID=C.CASEID
						and CN.NAMETYPE='I'
						and CN.EXPIRYDATE is null)
			where (C.FAMILY      =@psFamily       OR @psFamily       is null)
			and   (C.CASETYPE    =@psCaseType     OR @psCaseType     is null)
			and   (C.PROPERTYTYPE=@psPropertyType OR @psPropertyType is null)
			and   (CN.NAMENO     =@pnInstructor   OR @pnInstructor   is null)
			-- If all of the parameters are null then only return Cases that
			-- have a family
			and   (C.FAMILY is not null OR @psCaseType is not null OR @psPropertyType is not null OR @pnInstructor is not null)"
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@psFamily		nvarchar(32),
							  @psCaseType		nchar(1),
							  @psPropertyType	nchar(1),
							  @pnInstructor		int',
							  @psFamily      =@psFamily,
							  @psCaseType    =@psCaseType,
							  @psPropertyType=@psPropertyType,
							  @pnInstructor  =@pnInstructor
		End
	End
	
	-- Load the Cases to be reported into the temporary table along with 
	-- a breakdown of the posted WIP for each CASEID and the total time recorded.
	If  @ErrorCode =  0
	Begin 
		Set @sSQLString="
		Insert into #TempCaseBudget(CASEID, UsedTotal, Services, Disbursements, Overheads, TotalTimeAsMinutes)
		Select T.CASEID,
		sum(isnull(WH.LOCALTRANSVALUE,0)),
		-- Get Service Charges
		isnull(sum(CASE WHEN(WT.CATEGORYCODE='SC') THEN isnull(WH.LOCALTRANSVALUE,0) ELSE 0 END),0),
		-- Get Paid Disbursements
		isnull(sum(CASE WHEN(WT.CATEGORYCODE='PD') THEN isnull(WH.LOCALTRANSVALUE,0) ELSE 0 END),0),
		-- Get Overhead Recoveries
		isnull(sum(CASE WHEN(WT.CATEGORYCODE='OR') THEN isnull(WH.LOCALTRANSVALUE,0) ELSE 0 END),0),
		-- Get the total number of minutes of Service Charge time
		isnull(sum(CASE WHEN(WT.CATEGORYCODE='SC') THEN  isnull(datepart(hour, TOTALTIME)*60,0)+isnull(datepart(minute,TOTALTIME),0) ELSE 0 END),0)
		from "+@psGlobalTempTable+" T
		left join WORKHISTORY WH	on (WH.CASEID= T.CASEID
						and WH.STATUS<>0
						and WH.MOVEMENTCLASS in (1,4,5)
						and ( 	@pdtFromDate is null or WH.TRANSDATE >= @pdtFromDate
								and	@pdtToDate is null or WH.TRANSDATE < @pdtToDate
							)
						)
		left join WIPTEMPLATE WTP	on (WTP.WIPCODE = WH.WIPCODE)
		left join WIPTYPE WT		on (WT.WIPTYPEID= WTP.WIPTYPEID)
		group by T.CASEID"
	
		Exec @ErrorCode = sp_executesql @sSQLString,
						N'@pdtFromDate	datetime,
						@pdtToDate		datetime',
						@pdtFromDate	= @pdtFromDate,
						@pdtToDate	= @pdtToDate
	End
		
	If @ErrorCode =  0
	Begin 
		Set @sSQLString="
		Update #TempCaseBudget 
	
			-- Get the Billed to Date amount for each Case. 
		Set BilledToDate = (	select isnull(sum(-WH.LOCALTRANSVALUE),0)
					from WORKHISTORY WH	
					where WH.CASEID = T.CASEID
					and   WH.STATUS <> 0
					and   WH.MOVEMENTCLASS=2						
					and ( 	@pdtFromDate is null or WH.TRANSDATE >= @pdtFromDate
								and	@pdtToDate is null or WH.TRANSDATE < @pdtToDate
							)
					),
	
			-- Get a breakdown of the WIP adjustments (Write Up/Down)
		    WriteUpDown=(	select isnull(sum(-WH.LOCALTRANSVALUE),0)
					from WORKHISTORY WH
					Where WH.CASEID=T.CASEID
					and   WH.STATUS <> 0
					and   WH.MOVEMENTCLASS in (3,9)						
					and ( 	@pdtFromDate is null or WH.TRANSDATE >= @pdtFromDate
								and	@pdtToDate is null or WH.TRANSDATE < @pdtToDate
							)
					),
	
			-- Get the total costs for all Work including all adjustments
		    WorkHistoryCost1=(	select isnull(sum(isnull(WH.COSTCALCULATION1,0)),0)
					from WORKHISTORY WH
					Where WH.CASEID=T.CASEID
					and   WH.COSTCALCULATION1 is not null),
	
		    WorkHistoryCost2=(	select isnull(sum(isnull(WH.COSTCALCULATION2,0)),0)
					from WORKHISTORY WH
					Where WH.CASEID=T.CASEID
					and   WH.COSTCALCULATION2 is not null),
	
			-- Get the outstanding WIP Balance
		    UnbilledWIP=(	select isnull(sum(isnull(BALANCE,0)),0)
					from  WORKINPROGRESS W 
					where W.CASEID = T.CASEID
					and   W.STATUS<>0),
	
			-- Get the value of any un-posted diary times and associated costs
		    UnpostedWIP=(	select isnull(sum(isnull(TIMEVALUE,0)),0)
					from DIARY D
					where D.CASEID=T.CASEID
					and   D.TRANSNO is null
					and   D.ISTIMER=0),
	
		    UnpostedTimeAsMinutes=(
					select isnull(sum(isnull(datepart(hour, TOTALTIME)*60,0)+isnull(datepart(minute,TOTALTIME),0)),0)
					from DIARY D
					where D.CASEID=T.CASEID
					and   D.TRANSNO is null
					and   D.ISTIMER=0),
	
			-- Get the saved budget amount if it has not been supplied as a parameter
		    BudgetAmount=CASE WHEN(@pnBudgetAmount is not null)
				   THEN @pnBudgetAmount
				   WHEN @pbTotalsFromCase=1
				   THEN @nBudgetAmount			   
				   ELSE(select isnull(sum(isnull(VALUE,0)),0)
					from CASEBUDGET C
					where C.CASEID=T.CASEID
					and C.REVISEDFLAG=0)
				 END,
	
			-- Get the saved budget hours
		    BudgetHours=(	select isnull(sum(isnull(HOURS,0)),0)
					from CASEBUDGET C
					where C.CASEID=T.CASEID
					and C.REVISEDFLAG=0),
	
			-- Get the saved budget hours without truncating the decimal points
		    BudgetedTimeAsMinutes=(	
					select CAST(ROUND(isnull(sum(isnull(HOURS,0)),0)*60, 0) as int)
					from CASEBUDGET C
					where C.CASEID=T.CASEID
					and C.REVISEDFLAG=0),
	
			-- Get the revised budget amount
		    RevisedBudgetAmount=CASE WHEN @pbTotalsFromCase=1
				   	  THEN @nBudgetRevisedAmt 	
					  ELSE (select isnull(sum(isnull(VALUE,0)),0)
						from CASEBUDGET C
						where C.CASEID=T.CASEID
						and C.REVISEDFLAG=1)
					END,
	
			-- Get the revised budget hours
		    RevisedBudgetHours=(select isnull(sum(isnull(HOURS,0)),0)
					from CASEBUDGET C
					where C.CASEID=T.CASEID
					and C.REVISEDFLAG=1),
	
			-- Get the revised budget hours without truncating the decimal points
		    RevisedBudgetedTimeAsMinutes=
					(select CAST(ROUND(isnull(sum(isnull(HOURS,0)),0)*60, 0) as int)
					from CASEBUDGET C
					where C.CASEID=T.CASEID
					and C.REVISEDFLAG=1),
	
			-- Get the Budget Profit Amount
		    BudgetProfitAmount1=(
					select isnull(sum(isnull(PROFIT1,0)),0)
					from CASEBUDGET C
					where C.CASEID=T.CASEID
					and C.REVISEDFLAG=0),
	
			-- Get the Revised Budget Profit Amount
		    RevisedBudgetProfitAmount1=(
					select isnull(sum(isnull(PROFIT1,0)),0)
					from CASEBUDGET C
					where C.CASEID=T.CASEID
					and C.REVISEDFLAG=1)"+
		CASE 	WHEN @pbCalledFromCentura = 0 
			THEN ","+CHAR(10)+
			-- Get the Budget Profit Amount2
	"	    BudgetProfitAmount2=(
					select isnull(sum(isnull(PROFIT2,0)),0)
					from CASEBUDGET C
					where C.CASEID=T.CASEID
					and C.REVISEDFLAG=0),
			-- Get the Revised Budget Profit Amount
		    RevisedProfitAmount2=(
					select isnull(sum(isnull(PROFIT2,0)),0)
					from CASEBUDGET C
					where C.CASEID=T.CASEID
					and C.REVISEDFLAG=1)"
		END+CHAR(10)+			
		"from #TempCaseBudget T"
	
		Exec @ErrorCode = sp_executesql @sSQLString,
						N'@pnBudgetAmount	decimal(11,2),
						@pbTotalsFromCase	bit,
						@nBudgetAmount	decimal(11,2),
						@nBudgetRevisedAmt	decimal(11,2),
						@pdtFromDate	datetime,
						@pdtToDate		datetime',
						@pnBudgetAmount	=@pnBudgetAmount,
						@pbTotalsFromCase	=@pbTotalsFromCase,
						@nBudgetAmount	=@nBudgetAmount,
						@nBudgetRevisedAmt	=@nBudgetRevisedAmt,
						@pdtFromDate	= @pdtFromDate,
						@pdtToDate	= @pdtToDate
	End
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Update #TempCaseBudget
		Set BudgetUsed		= CASE WHEN(BudgetAmount       <>0) THEN (UsedTotal    * 100)/ BudgetAmount END,
		    RevisedBudgetUsed  	= CASE WHEN(RevisedBudgetAmount<>0) THEN (UsedTotal    * 100)/ RevisedBudgetAmount END,
		    BudgetBilled	= CASE WHEN(BudgetAmount       <>0) THEN (BilledToDate * 100)/ BudgetAmount END,
		    ProfitAmount1	=UsedTotal-WorkHistoryCost1,
		    ProfitAmount2	=UsedTotal-WorkHistoryCost2,
		    ProfitPercent1	=CASE WHEN(UsedTotal<>0) THEN ((UsedTotal-WorkHistoryCost1) * 100) / UsedTotal END,
		    ProfitPercent2	=CASE WHEN(UsedTotal<>0) THEN ((UsedTotal-WorkHistoryCost2) * 100) / UsedTotal END,
		    BudgetProfitPercent1=CASE WHEN(BudgetAmount<>0) THEN (BudgetProfitAmount1*100)/ BudgetAmount END,
		    RevisedBudgetProfitPercent1=CASE WHEN(RevisedBudgetAmount<>0) THEN (RevisedBudgetProfitAmount1*100)/ RevisedBudgetAmount END"
		    +CASE WHEN @pbCalledFromCentura = 0 
			  THEN ","+CHAR(10)+
	"	    BudgetProfitPercent2 =CASE WHEN(BudgetAmount<>0) THEN (BudgetProfitAmount2*100)/ BudgetAmount END,
		    RevisedProfitPercent2=CASE WHEN(RevisedBudgetAmount<>0) THEN (RevisedProfitAmount2*100)/ RevisedBudgetAmount END,
	 	    RevisedBudgetBilled  =CASE WHEN(RevisedBudgetAmount<>0) THEN (BilledToDate * 100)/ RevisedBudgetAmount END,
		    TotalWorked		 =ISNULL((BilledToDate+WriteUpDown+UnbilledWIP),0)"
		    END
		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBudgetAmount	decimal(11,2)',
						  @pnBudgetAmount=@pnBudgetAmount
	End
	
	-- Return the results.
	If  @ErrorCode=0
	and @pnCaseId is not null
	Begin
		If @pbCalledFromCentura = 1
		Begin
			-- A reduced result set is required for a single Case
		
			Set @sSQLString="
			Select	C.IRN		as 'Case Ref.',
				C.TITLE		as 'Title',
				BilledToDate,
				UnbilledWIP,
				WriteUpDown,
				UsedTotal,
				BudgetUsed,
				Services,
				Disbursements,
				Overheads,
				BudgetBilled,
				UnpostedWIP,
				TotalTimeAsMinutes,
				UnpostedTimeAsMinutes,
				ProfitAmount1,
				ProfitPercent1,
				ProfitAmount2,
				ProfitPercent2
			from #TempCaseBudget T
			join CASES C	on (C.CASEID=T.CASEID)"
		
			Exec @ErrorCode=sp_executesql @sSQLString
		End
		Else Begin
			Set @sSQLString="
			Select	T.CASEID		as CaseKey,
				T.BudgetAmount		as BudgetAmount,
				CASE	WHEN (T.BudgetAmount IS NULL or @bCaseBudgetExists = 0)
					THEN NULL
					ELSE T.BudgetedTimeAsMinutes		
				END			as BudgetedTimeAsMinutes,
				CASE	WHEN (T.BudgetAmount IS NULL or @bCaseBudgetExists = 0)
					THEN NULL
					ELSE T.BudgetProfitAmount1
				END			as BudgetProfitAmount1,
				CASE	WHEN (T.BudgetAmount IS NULL or @bCaseBudgetExists = 0)
					THEN NULL
					ELSE T.BudgetProfitPercent1
				END			as BudgetProfitPercent1,
				CASE	WHEN (T.BudgetAmount IS NULL or @bCaseBudgetExists = 0)
					THEN NULL
					ELSE T.BudgetProfitAmount2
				END			as BudgetProfitAmount2,
				CASE	WHEN (T.BudgetAmount IS NULL or @bCaseBudgetExists = 0)
					THEN NULL
					ELSE T.BudgetProfitPercent2
				END			as BudgetProfitPercent2,
				CASE	WHEN T.BudgetAmount IS NULL
					THEN NULL
					ELSE T.BudgetUsed
				END			as BudgetUsed,
				CASE	WHEN T.BudgetAmount IS NULL
					THEN NULL
					ELSE T.BudgetBilled
				END			as BudgetBilled,
				T.RevisedBudgetAmount	as RevisedBudgetAmount,
				CASE 	WHEN (T.RevisedBudgetAmount IS NULL or @bCaseBudgetExists = 0)
					THEN NULL
					ELSE T.RevisedBudgetedTimeAsMinutes
				END			as RevisedBudgetedTimeAsMinutes,
				CASE 	WHEN (T.RevisedBudgetAmount IS NULL or @bCaseBudgetExists = 0)
					THEN NULL
					ELSE T.RevisedBudgetProfitAmount1
				END			as RevisedProfitAmount1,
				CASE 	WHEN (T.RevisedBudgetAmount IS NULL or @bCaseBudgetExists = 0)
					THEN NULL
					ELSE T.RevisedBudgetProfitPercent1
				END			as RevisedProfitPercent1,
				CASE 	WHEN (T.RevisedBudgetAmount IS NULL or @bCaseBudgetExists = 0)
					THEN NULL
					ELSE T.RevisedProfitAmount2
				END			as RevisedProfitAmount2,
				CASE 	WHEN (T.RevisedBudgetAmount IS NULL or @bCaseBudgetExists = 0)
					THEN NULL
					ELSE T.RevisedProfitPercent2
				END			as RevisedProfitPercent2,
				CASE 	WHEN T.RevisedBudgetAmount IS NULL
					THEN NULL
					ELSE T.RevisedBudgetUsed
				END			as RevisedBudgetUsed,
				CASE 	WHEN T.RevisedBudgetAmount IS NULL
					THEN NULL
					ELSE T.RevisedBudgetBilled
				END			as RevisedBudgetBilled,
				CASE 	WHEN @bIsBillingPerformed = 0
					THEN NULL
					ELSE T.TotalTimeAsMinutes
				END			as TotalTimeAsMinutes,
				CASE 	WHEN @bIsBillingPerformed = 0
					THEN NULL
					ELSE T.Services	
				END			as Services,
				CASE 	WHEN @bIsBillingPerformed = 0
					THEN NULL
					ELSE T.Disbursements
				END			as Disbursements,
				CASE 	WHEN @bIsBillingPerformed = 0
					THEN NULL
					ELSE T.Overheads
				END			as Overheads,
				CASE 	WHEN @bIsBillingPerformed = 0
					THEN NULL 
					ELSE T.UsedTotal
				END			as UsedTotal,
				CASE 	WHEN @bIsBillingPerformed = 0
					THEN NULL 
					ELSE T.BilledToDate
				END			as BilledToDate,
				CASE 	WHEN @bIsBillingPerformed = 0
					THEN NULL 
					ELSE T.WriteUpDown
				END			as WriteUpDown,
				CASE 	WHEN @bIsBillingPerformed = 0
					THEN NULL 
					ELSE T.UnbilledWIP
				END			as UnbilledWIP,
				CASE 	WHEN @bIsBillingPerformed = 0
					THEN NULL 
					ELSE T.TotalWorked
				END			as TotalWorked,
				CASE 	WHEN @bIsBillingPerformed = 0
					THEN NULL 
					ELSE T.UnpostedWIP
				END			as UnpostedWIP,
				CASE 	WHEN @bIsBillingPerformed = 0
					THEN NULL 
					ELSE T.UnpostedTimeAsMinutes
				END			as UnpostedTimeAsMinutes,
				CASE 	WHEN @bCaseBudgetExists = 0
					THEN NULL
					ELSE T.ProfitAmount1
				END			as ProfitAmount1,
				CASE 	WHEN @bCaseBudgetExists = 0
					THEN NULL
					ELSE T.ProfitPercent1
				END			as ProfitPercent1,
				CASE 	WHEN @bCaseBudgetExists = 0
					THEN NULL
					ELSE T.ProfitAmount2
				END			as ProfitAmount2,
				CASE 	WHEN @bCaseBudgetExists = 0
					THEN NULL
					ELSE T.ProfitPercent2
				END			as ProfitPercent2			
			from #TempCaseBudget T"
	
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@bCaseBudgetExists	bit,
							  @bIsBillingPerformed	bit',
							  @bCaseBudgetExists	= @bCaseBudgetExists,
							  @bIsBillingPerformed	= @bIsBillingPerformed		
		End
	End
End

If @ErrorCode=0
Begin

	-- Populate another temp table with totals for each 'Property type'

	insert into @TempTotals
	select	
		CF.FAMILYTITLE,
		VP.PROPERTYNAME,
		VP.PROPERTYTYPE,
		sum(cast(BudgetHours/8.0 as decimal(5,1))) as 'Budget Days', 
		round(sum(isnull( isnull( C.BUDGETREVISEDAMT, C.BUDGETAMOUNT ), 0)),0,1) as 'Budget Fees', 
		round(sum(case when @pnCostCalculation = 1 then BudgetProfitAmount1 else BudgetProfitAmount2 end ),0,1) as 'Budget Margin',
		sum(cast(round((TotalTimeAsMinutes/480),0,1) as decimal(5,1))) as 'Actual Days',
		sum(UsedTotal) as 'Actual Fees',
		sum(round(case when @pnCostCalculation = 1 then ProfitAmount1 else ProfitAmount2 end,0,1)) as 'Actual Margin',
		case when ((sum(round(T.BudgetAmount,0,1))) > 0)
		     then case when (sum(round(UsedTotal,0,1))) > 0
			       then ((sum(round(T.BudgetAmount,0,1)) - sum(round(UsedTotal,0,1)))/sum(round(T.BudgetAmount,0,1)))*100
			  else 0
			  end
		else case when (sum(round(UsedTotal,0,1))) > 0
			  then 100 
		     else 0
		     end
		end as 'Variance',
		case when VP.PropertyType in ('B','C','D','I') then '1'+VP.PropertyType else '2'+VP.PropertyType end
	from #TempCaseBudget T
	join CASES C			on (C.CASEID=T.CASEID)
	left join CASEFAMILY CF		on (CF.FAMILY=C.FAMILY)
	left join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
					and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)
							from VALIDPROPERTY VP1
							where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
							and VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
	group by
			FamilyTitle, PropertyName, VP.PropertyType

	Set @ErrorCode=@@Error



End


If @ErrorCode=0
Begin

	-- Add totals line

	insert into @TempTotals
	select null,'Total',null,sum(BudgetDays),sum(BudgetFees),sum(BudgetMargin),sum(ActualDays),sum(ActualFees),
		sum(ActualMargin),
		case when (sum(BudgetFees)) > 0
		     then ((sum(BudgetFees)-sum(ActualFees))/sum(BudgetFees))*100
		else 0 end, '1Z'
	from @TempTotals
	where substring(SortSequence,1,1) = '1'

	Set @ErrorCode=@@Error



End


If @ErrorCode=0
Begin
	-- Return the result set

	select	FamilyTitle,
			PropertyName,
			PropertyType,
			BudgetDays,
			BudgetFees,
			BudgetMargin,
			ActualDays,
			ActualFees,
			ActualMargin,
			Variance
	from @TempTotals
	order by SortSequence

	Set @ErrorCode=@@Error

End

Return @ErrorCode
go



grant execute on dbo.cpass_GetBudgetDetailsVsActual to public
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

--exec cpass_GetBudgetDetailsVsActual @psEntryPoint = 'AAT01', @pnCostCalculation = 1
--go
--exec cpass_GetBudgetDetailsVsActual @psEntryPoint = 'AAT01', @pnCostCalculation = 0
--go