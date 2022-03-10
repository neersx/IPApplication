-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetBudgetDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_GetBudgetDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_GetBudgetDetails.'
	drop procedure dbo.cs_GetBudgetDetails
end
print '**** Creating procedure dbo.cs_GetBudgetDetails...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.cs_GetBudgetDetails
(
	@pnUserIdentityId		int	    	= null,
	@psCulture			nvarchar(10) 	= null,
	@pnCaseId			int		= null, -- optional 
	@pnBudgetAmount			decimal(11, 2)	= null,
	@psGlobalTempTable		nvarchar(32)	= null, -- optional name of temporary table of CASEIDs to be reported on.
	-- The following parameters will be made redundant when the stored procedure is able to report on the
	-- temporary table created on the Case Summary screen.
	@psFamily			nvarchar(20)	= null, -- the Family of Cases to be reported on
	@psCaseType			nchar(1)	= null, -- the CaseType of Cases to be reported on
	@psPropertyType			nchar(1)	= null, -- the PropertyType of Cases to be reported on
	@pnInstructor			int		= null, -- the Instructors nameno for Cases to be reported on
	@pnOrderBy			tinyint		= 1,	-- 1-IRN; 2-BilledToDate DESC; 3-UnBilledWIP DESC; 4-UsedTotal DESC; 5-ProfitAmount1 DESC; 6-ProfitPercent1
	@pbCalledFromCentura		bit		= 1,
	@pbTotalsFromCase 		bit 		= 0,	-- if @pbTotalsFromCase = 1 then obtain BudgetAmount and RevisedBudgetAmount from the Cases table.
	@pbHasBillingHistorySubject	bit		= null
)
AS
-- PROCEDURE :	cs_GetBudgetDetails
-- DESCRIPTION:	Returns Budget details to be used on the Budget tab.
-- VERSION:	25
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 08 Mar 2003	vql		1	Procedure created
-- 19 Mar 2003	vql		2	Modified billed to date
-- 12 Jan 2004	mf	9415	3	Add output parameters to report on profit figures and simplify coding
-- 22 Jan 2004	mf	9415	4	Coding error.
-- 30 Jan 2004	mf	9415	5	Coding error.
-- 16 Feb 2004	mf	9707	6	Allow a result set for multiple Cases to be inserted.
-- 17 Feb 2004	mf	9707	7	Additional output columns and correction to case sensitive variable problem.
-- 20 Feb 2004	MF	9707	8	Correction of typo
-- 05 Aug 2004	AB	8035	9	Add collate database_default to temp table definitions
-- 20 Oct 2004	TM	RFC1156	10	Pass new optional parameter:@pbCalledFromCentura bit 1 and extend the existing 
--					logic to return additional data when the @pbCalledFromCentura = 0.
-- 08 Dec 2004	TM	RFC1156	11	Ensure only appropriate information is returned.
-- 15 Dec 2004	TM	RFC1156	12 	Add two new columns to the #TempCaseBudget: BudgetedTimeAsMinutes and RevisedBudgettedTimeAsMinutes. 
--					When @pbCalledFromCentura = 0, return  new BudgetedTimeAsMinutes int and 
--					RevisedBudgettedTimeAsMinutes int columns
--					instead of the BudgetHours and RevisedBudgetHours columns.
-- 15 Dec 2004	TM	RFC1156 13	Multiply the RevisedBudgetedTimeAsMinutes by 60.
-- 20 Dec 2004	TM	RFC2142	14	If no billing has been performed, eturn null for billing related figures. Suppress the result 
--					set when @pbCalledFromCentura = 0 and no budget or billing information available.
-- 21 Dec 2004	TM	RFC2142	15	Place the "CaseKey is null" check together with the following: "If @pbCalledFromCentura = 0 and  
--					(@nBudgetAmount is null and @nBudgetRevisedAmt is null and @bCaseBudgetExists = 0 and 
--					@bIsBillingPerformed = 0)".
-- 23 May 2005	TM	RFC2594	16	Add a new optional parameter @pbHasBillingHistorySubject. If null, look it up.
-- 20 Jun 2005	TM	RFC1100	17	Exclude all timer rows from their processing of unposted time; i.e. AND ISTIMER=0.
--					Fix the UnBilledWIP column to be an UnbilledWIP in the 'order by' clause.
-- 26 Jun 2006	SW	RFC4038	18	Return rowkey when @pbCalledFromCentura = 0
-- 14 Jul 2006	SW	RFC3828	19	Pass getdate() to fn_Permission..
-- 16 Jul 2009	Dw	SQA17604 20	Continued time was not being included
-- 10 Feb 2011	AT	RFC10207 21	Optimised total billed SQL.
-- 24 Oct 2011	ASH	R11460  22	Cast integer columns as nvarchar(11) data type.
-- 03 May 2017	vql	R61470	23	Ignore @bIsBillingPerformed for web result set.
-- 04 Sep 2017	MS	R71826	24	Included BudgetStartDate and BudgetEndDate.
-- 06 Sep 2017	MS	R71977	25	Included BudgetWorkPerformed and BudgetWorkBilled.

Set nocount on
Set concat_null_yields_null off

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
		RevisedBudgetedTimeAsMinutes	int		null,
		BudgetStartDate			datetime	null,
		BudgetEndDate			datetime        null,
                BudgetWorkPerformed             decimal(11, 2) 	null,
                BudgetWorkBilled                decimal(11, 2) 	null
		)

Declare @ErrorCode 		int
Declare @sSQLString		nvarchar(max)
Declare @sOrderBy		nvarchar(100)
Declare @sWhereString           nvarchar(4000)

Declare @nBudgetAmount		decimal(11, 2)
Declare @nBudgetRevisedAmt	decimal(11, 2)
Declare @bCaseBudgetExists 	bit
Declare @bIsBillingPerformed	bit
Declare @dBudgetStartDate	datetime
Declare @dBudgetEndDate	        datetime

Declare @dtToday		datetime

Set	@dtToday		= getdate()

Set @ErrorCode = 0
-- If @pbHasBillingHistorySubject was notsupplied, look it up.

If @ErrorCode=0
and @pbHasBillingHistorySubject is null
Begin
	Set @sSQLString="
	Select	@pbHasBillingHistorySubject=TS.IsAvailable 
	from dbo.fn_GetTopicSecurity(@pnUserIdentityId, 101, default, @dtToday) TS
	where TS.IsAvailable=1"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pbHasBillingHistorySubject	bit				OUTPUT,
				  @pnUserIdentityId		int,
				  @dtToday			datetime',
				  @pbHasBillingHistorySubject	=@pbHasBillingHistorySubject 	OUTPUT,
				  @pnUserIdentityId		=@pnUserIdentityId,	
				  @dtToday			=@dtToday
End

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
					  END,
		@dBudgetStartDate = C.BUDGETSTARTDATE,
		@dBudgetEndDate	= C.BUDGETENDDATE
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
					  @dBudgetStartDate		datetime	OUTPUT,
					  @dBudgetEndDate		datetime	OUTPUT,
					  @pnCaseId		int',
					  @nBudgetAmount	=@nBudgetAmount		OUTPUT,
					  @nBudgetRevisedAmt	=@nBudgetRevisedAmt 	OUTPUT,
					  @bCaseBudgetExists	=@bCaseBudgetExists	OUTPUT,
					  @bIsBillingPerformed	=@bIsBillingPerformed	OUTPUT,
					  @dBudgetStartDate		=@dBudgetStartDate		OUTPUT,
					  @dBudgetEndDate		= @dBudgetEndDate		OUTPUT,
					  @pnCaseId		=@pnCaseId
End


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
	
	-- Load the Cases IDs into the #TempCaseBudget
	If  @ErrorCode =  0
	Begin 
		Set @sSQLString="Insert into #TempCaseBudget(CASEID)
				select CASEID FROM #TempCasesToList"
		
		Exec @ErrorCode = sp_executesql @sSQLString
	End
	
	-- Update the budget temp table with a breakdown of the posted WIP for each CASEID and the total time recorded.
	If  @ErrorCode =  0
	Begin 
		Set @sSQLString="
		Update T
		Set	UsedTotal = WHSUM.USEDTOTAL,
			[Services] = WHSUM.[SERVICES],
			Disbursements = WHSUM.DISBURSEMENTS,
			Overheads = WHSUM.OVERHEADS,
			TotalTimeAsMinutes = WHSUM.TOTALTIMEINMINUTES
		from #TempCaseBudget T
		join (
			SELECT WH.CASEID,
			sum(isnull(WH.LOCALTRANSVALUE, 0)) AS USEDTOTAL,
			-- Get Service Charges
			sum(CASE WHEN(WT.CATEGORYCODE='SC') THEN isnull(WH.LOCALTRANSVALUE, 0) else 0 END) AS [SERVICES],
			
			-- Get Paid Disbursements
			sum(CASE WHEN(WT.CATEGORYCODE='PD') THEN isnull(WH.LOCALTRANSVALUE, 0) else 0 END) AS DISBURSEMENTS,
			
			-- Get Overhead Recoveries
			sum(CASE WHEN(WT.CATEGORYCODE='OR') THEN isnull(WH.LOCALTRANSVALUE, 0) else 0 END) AS OVERHEADS,

			-- Get the total number of minutes of Service Charge time
			sum(CASE WHEN(WT.CATEGORYCODE='SC') THEN  datepart(hour, isnull(TOTALTIME,0))*60 + datepart(minute,isnull(TOTALTIME,0)) ELSE 0 END) AS TOTALTIMEINMINUTES
			
			from #TempCaseBudget T1
			join WORKHISTORY WH	on (	WH.CASEID= T1.CASEID
							and WH.STATUS<>0
							and WH.MOVEMENTCLASS in (1,4,5))
			join WIPTEMPLATE WTP	on (WTP.WIPCODE = WH.WIPCODE)
			join WIPTYPE WT		on (WT.WIPTYPEID= WTP.WIPTYPEID)
			group by WH.CASEID) AS WHSUM on (T.CASEID = WHSUM.CASEID)"
	
		Exec @ErrorCode = sp_executesql @sSQLString
	End

        If  @ErrorCode =  0
	Begin                 
                Set @sWhereString= CASE WHEN @dBudgetStartDate is not null THEN 
                                CASE WHEN @dBudgetEndDate is not null THEN " between @dBudgetStartDate and @dBudgetEndDate"
                                ELSE " >= @dBudgetStartDate" 
                                END
                        ELSE CASE WHEN @dBudgetEndDate is not null THEN " <= @dBudgetEndDate"
                                ELSE ""
                                END
                   END

		Set @sSQLString="
                Update #TempCaseBudget
		Set 
                    BudgetWorkPerformed = isnull(WHSUM.USEDTOTAL,0),
                    BudgetWorkBilled = isnull(WHBILL.BilledToDate,0)
                from #TempCaseBudget T
                left join (
			SELECT CASEID, sum(isnull(LOCALTRANSVALUE, 0)) AS USEDTOTAL
			from WORKHISTORY 	
                        where STATUS<>0
			and MOVEMENTCLASS in (1,4,5)"
                If @sWhereString <> ""
                Begin
                         Set @sSQLString= @sSQLString + char(10) + "and TRANSDATE"+ @sWhereString + char(10) 
                End
		Set @sSQLString= @sSQLString + char(10) +"	group by CASEID) AS WHSUM on (T.CASEID = WHSUM.CASEID)
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
				group by WH1.CASEID) WHBILL on (WHBILL.CASEID=T.CASEID)"
	
		Exec @ErrorCode = sp_executesql @sSQLString,
                        N'@dBudgetStartDate     datetime,
                        @dBudgetEndDate         datetime',
                        @dBudgetStartDate = @dBudgetStartDate,
                        @dBudgetEndDate = @dBudgetEndDate
	End
		
	If @ErrorCode =  0
	Begin 
		Set @sSQLString="
		Update #TempCaseBudget
		Set BilledToDate = isnull(WH1.BilledToDate,0),
		    WriteUpDown  = isnull(WH2.WriteUpDown,0),
		    WorkHistoryCost1=isnull(WH3.WorkHistoryCost1,0),
		    WorkHistoryCost2=isnull(WH3.WorkHistoryCost2,0),
		    UnbilledWIP=isnull(WP1.UnbilledWIP,0),
		    UnpostedWIP=isnull(D1.UnpostedWIP,0),
		    UnpostedTimeAsMinutes=isnull(D1.UnpostedTimeAsMinutes,0),
	
			-- Get the saved budget amount if it has not been supplied as a parameter
		    BudgetAmount=CASE	WHEN(@pnBudgetAmount is not null) THEN @pnBudgetAmount
					WHEN(@pbTotalsFromCase=1)	  THEN @nBudgetAmount			   
									  ELSE isnull(CB1.BudgetAmount,0)
				 END,
	
		    BudgetHours=isnull(CB1.BudgetHours,0),
		    BudgetedTimeAsMinutes=isnull(CB1.BudgetedTimeAsMinutes,0),
	
			-- Get the revised budget amount
		    RevisedBudgetAmount=CASE WHEN @pbTotalsFromCase=1
				   		  THEN @nBudgetRevisedAmt 	
						  ELSE isnull(CB2.RevisedBudgetAmount,0)
					END,

		    RevisedBudgetHours=isnull(CB2.RevisedBudgetHours,0),
		    RevisedBudgetedTimeAsMinutes=isnull(CB2.RevisedBudgetedTimeAsMinutes,0),
		    BudgetProfitAmount1=isnull(CB1.BudgetProfitAmount1,0),
		    RevisedBudgetProfitAmount1=isnull(CB2.RevisedBudgetProfitAmount1,0)"+
		CASE 	WHEN @pbCalledFromCentura = 0 
			THEN ","+CHAR(10)+
			-- Get the Budget Profit Amount2
	"	    BudgetProfitAmount2=isnull(CB1.BudgetProfitAmount2,0),
			-- Get the Revised Budget Profit Amount
		    RevisedProfitAmount2=isnull(CB2.RevisedBudgetProfitAmount2,0),
			BudgetStartDate=@dBudgetStartDate,
			BudgetEndDate=@dBudgetEndDate"
		END+CHAR(10)+			
		"from #TempCaseBudget T
		left join (	select CASEID, sum(isnull(-LOCALTRANSVALUE,0)) as BilledToDate
				from WORKHISTORY	
				where STATUS <> 0
				and   MOVEMENTCLASS=2
				group by CASEID) WH1 on (WH1.CASEID=T.CASEID)

		left join (	select CASEID, sum(isnull(-LOCALTRANSVALUE,0)) as WriteUpDown
				from WORKHISTORY
				Where STATUS <> 0
				and   MOVEMENTCLASS in (3,9)
				group by CASEID) WH2 on (WH2.CASEID=T.CASEID)

		left join (	select  CASEID, 
					sum(isnull(COSTCALCULATION1,0)) as WorkHistoryCost1,
					sum(isnull(COSTCALCULATION2,0)) as WorkHistoryCost2
				from WORKHISTORY
				Where COSTCALCULATION1 is not null
				group by CASEID) WH3 on (WH3.CASEID=T.CASEID)

		left join (	select CASEID, sum(isnull(BALANCE,0)) as UnbilledWIP
				from  WORKINPROGRESS
				where STATUS<>0
				group by CASEID) WP1 on (WP1.CASEID=T.CASEID)

		left join (	select	CASEID, 
					sum(isnull(TIMEVALUE,0)) as UnpostedWIP,
					sum(isnull(datepart(hour, TOTALTIME)*60,0) 
					+isnull(datepart(minute,TOTALTIME),0) 
					+isnull(datepart(hour,TIMECARRIEDFORWARD)*60,0) 
					+isnull(datepart(minute,TIMECARRIEDFORWARD),0)) as UnpostedTimeAsMinutes
				from DIARY
				where TRANSNO is null
				and   ISTIMER=0
				group by CASEID) D1 on (D1.CASEID=T.CASEID)

		left join (	select	CASEID, 
					sum(isnull(VALUE,0)) as BudgetAmount,
					sum(isnull(HOURS,0)) as BudgetHours,
					CAST(ROUND(sum(isnull(HOURS,0))*60, 0) as int) as BudgetedTimeAsMinutes,
					sum(isnull(PROFIT1,0)) as BudgetProfitAmount1,
					sum(isnull(PROFIT2,0)) as BudgetProfitAmount2
				from CASEBUDGET
				where REVISEDFLAG=0
				group by CASEID) CB1 on (CB1.CASEID=T.CASEID)

			-- Get the revised budget amount
		left join (	select	CASEID, 
					sum(isnull(VALUE,0)) as RevisedBudgetAmount,
					sum(isnull(HOURS,0)) as RevisedBudgetHours,
					CAST(ROUND(sum(isnull(HOURS,0))*60, 0) as int) as RevisedBudgetedTimeAsMinutes,
					sum(isnull(PROFIT1,0)) as RevisedBudgetProfitAmount1,
					sum(isnull(PROFIT2,0)) as RevisedBudgetProfitAmount2
				from CASEBUDGET C
				where REVISEDFLAG=1
				group by CASEID) CB2 on (CB2.CASEID=T.CASEID)"

		Exec @ErrorCode = sp_executesql @sSQLString,
						N'@pnBudgetAmount	decimal(11,2),
						  @pbTotalsFromCase	bit,
						  @nBudgetAmount	decimal(11,2),
						  @nBudgetRevisedAmt	decimal(11,2),
						  @dBudgetStartDate	datetime,
						  @dBudgetEndDate	datetime',
						  @pnBudgetAmount	=@pnBudgetAmount,
						  @pbTotalsFromCase	=@pbTotalsFromCase,
						  @nBudgetAmount	=@nBudgetAmount,
						  @nBudgetRevisedAmt =@nBudgetRevisedAmt,
						  @dBudgetStartDate	= @dBudgetStartDate,
						  @dBudgetEndDate	= @dBudgetEndDate
	End
	
	If @ErrorCode=0
	Begin
                Set @sSQLString="Update #TempCaseBudget Set "

                If @pbCalledFromCentura = 0
		Begin
                        Set @sSQLString= @sSQLString + char(10) + "
                        BudgetUsed		= CASE WHEN(BudgetAmount       <>0) THEN (BudgetWorkPerformed    * 100)/ BudgetAmount END,
		        RevisedBudgetUsed  	= CASE WHEN(RevisedBudgetAmount<>0) THEN (BudgetWorkPerformed    * 100)/ RevisedBudgetAmount END,
		        BudgetBilled	        = CASE WHEN(BudgetAmount       <>0) THEN (BudgetWorkBilled * 100)/ BudgetAmount END,
                        RevisedBudgetBilled     = CASE WHEN(RevisedBudgetAmount<>0) THEN (BudgetWorkBilled * 100)/ RevisedBudgetAmount END,
                        BudgetProfitPercent2    = CASE WHEN(BudgetAmount<>0) THEN (BudgetProfitAmount2*100)/ BudgetAmount END,
		        RevisedProfitPercent2   = CASE WHEN(RevisedBudgetAmount<>0) THEN (RevisedProfitAmount2*100)/ RevisedBudgetAmount END,	 	    
		        TotalWorked		= ISNULL((BilledToDate+WriteUpDown+UnbilledWIP),0),"
                End
                Else
                Begin
                        Set @sSQLString= @sSQLString + char(10) + "
                        BudgetUsed		= CASE WHEN(BudgetAmount       <>0) THEN (UsedTotal    * 100)/ BudgetAmount END,
		        RevisedBudgetUsed  	= CASE WHEN(RevisedBudgetAmount<>0) THEN (UsedTotal    * 100)/ RevisedBudgetAmount END,
		        BudgetBilled	        = CASE WHEN(BudgetAmount       <>0) THEN (BilledToDate * 100)/ BudgetAmount END,
                        RevisedBudgetBilled     = CASE WHEN(RevisedBudgetAmount<>0) THEN (BilledToDate * 100)/ RevisedBudgetAmount END,"
                End 

		Set @sSQLString= @sSQLString + char(10) + "		
		    ProfitAmount1	=UsedTotal-WorkHistoryCost1,
		    ProfitAmount2	=UsedTotal-WorkHistoryCost2,
		    ProfitPercent1	=CASE WHEN(UsedTotal<>0) THEN ((UsedTotal-WorkHistoryCost1) * 100) / UsedTotal END,
		    ProfitPercent2	=CASE WHEN(UsedTotal<>0) THEN ((UsedTotal-WorkHistoryCost2) * 100) / UsedTotal END,
		    BudgetProfitPercent1=CASE WHEN(BudgetAmount<>0) THEN (BudgetProfitAmount1*100)/ BudgetAmount END,
		    RevisedBudgetProfitPercent1=CASE WHEN(RevisedBudgetAmount<>0) THEN (RevisedBudgetProfitAmount1*100)/ RevisedBudgetAmount END"
		    
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
			Select	cast(T.CASEID as nvarchar(11))
							as RowKey,
				T.CASEID		as CaseKey,
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
				T.TotalTimeAsMinutes as TotalTimeAsMinutes,
				T.Services as Services,
				T.Disbursements as Disbursements,
				T.Overheads as Overheads,
				T.UsedTotal as UsedTotal,
				T.BilledToDate as BilledToDate,
				T.WriteUpDown as WriteUpDown,
				T.UnbilledWIP as UnbilledWIP,
				T.TotalWorked as TotalWorked,
				T.UnpostedWIP as UnpostedWIP,
				T.UnpostedTimeAsMinutes as UnpostedTimeAsMinutes,
				T.ProfitAmount1 as ProfitAmount1,
				T.ProfitPercent1 as ProfitPercent1,
				T.ProfitAmount2 as ProfitAmount2,
				T.ProfitPercent2 as ProfitPercent2,
				T.BudgetStartDate as BudgetStartDate,
				T.BudgetEndDate as BudgetEndDate,
                                T.BudgetWorkPerformed as BudgetWorkPerformed,
                                T.BudgetWorkBilled as BudgetWorkBilled		
			from #TempCaseBudget T"
	
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@bCaseBudgetExists	bit,
							  @bIsBillingPerformed	bit',
							  @bCaseBudgetExists	= @bCaseBudgetExists,
							  @bIsBillingPerformed	= @bIsBillingPerformed		
		End
	End
	Else If @ErrorCode=0
	     and @pnCaseId is null
	     and @pbCalledFromCentura = 1	
	Begin
		-- An expanded and sorted result set is required when the procedure is being run for a range
		-- of Cases as it is being used 
	
		-- Set the ORDER BY clause from the requested parameter
		Set @sOrderBy=	CASE @pnOrderBy
					WHEN(1) THEN 'Order By C.IRN'
					WHEN(2) THEN 'Order By T.BilledToDate   DESC, T.UnbilledWIP    DESC, C.IRN ASC'
					WHEN(3) THEN 'Order By T.UnbilledWIP    DESC, T.BilledToDate   DESC, C.IRN ASC'
					WHEN(4) THEN 'Order By T.UsedTotal      DESC, T.BilledToDate   DESC, T.UnbilledWIP DESC, C.IRN ASC'
					WHEN(5) THEN 'Order By T.ProfitAmount1  DESC, T.ProfitPercent1 DESC, C.IRN ASC'
					WHEN(6) THEN 'Order By T.ProfitPercent1 DESC, T.ProfitAmount1  DESC, C.IRN ASC'
					WHEN(7) THEN 'Order By VP.PROPERTYNAME, C.IRN ASC'
				END
	
		
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
			ProfitPercent2,
			BudgetHours,
			BudgetUsed,
			RevisedBudgetAmount,
			RevisedBudgetHours,
			RevisedBudgetUsed,
			BudgetProfitAmount1,
			BudgetProfitPercent1,
			RevisedBudgetProfitAmount1,
			RevisedBudgetProfitPercent1,
			T.BudgetAmount,
			VP.PROPERTYNAME	as PropertyName,
			CF.FAMILYTITLE as 'Case Family'
		from #TempCaseBudget T
		join CASES C			on (C.CASEID=T.CASEID)
		left join CASEFAMILY CF		on (CF.FAMILY=C.FAMILY)
		left join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
						and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)
								from VALIDPROPERTY VP1
								where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
								and VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"
		+char(10)+@sOrderBy

		Exec @ErrorCode=sp_executesql @sSQLString
			
	End	


Return @ErrorCode
go

grant execute on dbo.cs_GetBudgetDetails to public
go
