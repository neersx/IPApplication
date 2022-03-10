-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetBudgetInfo
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[csw_GetBudgetInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.csw_GetBudgetInfo.'
	drop procedure dbo.csw_GetBudgetInfo
end
print '**** Creating procedure dbo.csw_GetBudgetInfo...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.csw_GetBudgetInfo
(
	@pnUserIdentityId		int,
	@psCulture			nvarchar(10) 	= null,
	@pnCaseId			int, 
	@pnBudgetAmount			decimal(11, 2)	= null,
	@pnRevisedBudgetAmount	        decimal(11, 2)	= null,
        @pdtStartDate                   datetime        = null,
        @pdtEndDate                     datetime        = null
	
)
AS
-- PROCEDURE :	csw_GetBudgetInfo
-- DESCRIPTION:	Returns Budget details to be used on the maintain budget info.
-- VERSION:	1
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 04 Sep 2017	R71976  AK	1	Procedure created

Set nocount on
Set concat_null_yields_null off

-- A temporary table to hold results for multiple cases is required.
-- A table variable could not be used because dynamic SQL to load the rows is required.
Create table #TempCaseBudget(
		CASEID				int		not null,
		BilledToDate			decimal(11, 2) 	null,
		UsedTotal			decimal(11, 2) 	null,
		BudgetAmount			decimal(11, 2)	null,
		BudgetUsed			decimal(11, 2)	null,
                BudgetBilled                    decimal(11, 2)  null,
		RevisedBudgetAmount		decimal(11, 2)	null,
		RevisedBudgetUsed		decimal(11, 2)	null,
		RevisedBudgetBilled		decimal(11, 2) 	null,
		BudgetStartDate			datetime	null,
		BudgetEndDate			datetime        null
		)

Declare @ErrorCode 		int
Declare @sSQLString		nvarchar(max)
Declare @sWhereString           nvarchar(4000)
Declare @sLocalCurrencyCode     nvarchar(3)
Declare @nLocalDecimalPlaces    smallint

Declare @dtToday		datetime
Set	@dtToday		= getdate()

Set @ErrorCode = 0

exec @ErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= 0


If  @ErrorCode=0 and @pnBudgetAmount is null and @pnRevisedBudgetAmount is null
Begin
	Set @sSQLString="
	Select  @pnBudgetAmount 	= C.BUDGETAMOUNT,
		@pnRevisedBudgetAmount  = C.BUDGETREVISEDAMT,
		@pdtStartDate           = C.BUDGETSTARTDATE,
		@pdtEndDate             = C.BUDGETENDDATE
	from CASES C
	left join WORKHISTORY WH	on (WH.CASEID = C.CASEID
					and WH.MOVEMENTCLASS = 2) 
	where C.CASEID = @pnCaseId"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBudgetAmount	        decimal(11, 2)		OUTPUT,
					  @pnRevisedBudgetAmount	decimal(11, 2)		OUTPUT,
					  @pdtStartDate		        datetime	        OUTPUT,
					  @pdtEndDate		        datetime	        OUTPUT,
					  @pnCaseId		        int',
					  @pnBudgetAmount	        = @pnBudgetAmount		OUTPUT,
					  @pnRevisedBudgetAmount 	= @pnRevisedBudgetAmount 	OUTPUT,
					  @pdtStartDate		        = @pdtStartDate		OUTPUT,
					  @pdtEndDate		        = @pdtEndDate		OUTPUT,
					  @pnCaseId		        = @pnCaseId
End

	
	-- Load the Cases IDs into the #TempCaseBudget
	If  @ErrorCode =  0
	Begin 
		Set @sSQLString="Insert into #TempCaseBudget(CASEID)
				select @pnCaseId"
		
		Exec @ErrorCode = sp_executesql @sSQLString,
                                        N'@pnCaseId	        int',
                                         @pnCaseId	        = @pnCaseId
                        
	End	
		
	If @ErrorCode =  0
	Begin 
                Set @sWhereString= CASE WHEN @pdtStartDate is not null THEN 
                                CASE WHEN @pdtEndDate is not null THEN " between @pdtStartDate and @pdtEndDate"
                                ELSE " >= @pdtStartDate" 
                                END
                        ELSE CASE WHEN @pdtEndDate is not null THEN " <= @pdtEndDate"
                                ELSE ""
                                END
                        END

		Set @sSQLString="
		Update T
		Set 
                    UsedTotal = isnull(WHSUM.USEDTOTAL,0),
                    BilledToDate = isnull(WHBILL.BilledToDate,0),
		    BudgetAmount = ISNULL(@pnBudgetAmount,CB1.BudgetAmount),
		    RevisedBudgetAmount = ISNULL(@pnRevisedBudgetAmount,CB2.RevisedBudgetAmount),
		    BudgetStartDate=@pdtStartDate,
		    BudgetEndDate=@pdtEndDate
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
		        Set @sSQLString= @sSQLString + char(10) +"group by CASEID) AS WHSUM on (T.CASEID = WHSUM.CASEID)
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
				group by WH1.CASEID) WHBILL on (WHBILL.CASEID=T.CASEID)
		left join (	select	CASEID, 
					sum(isnull(VALUE,0)) as BudgetAmount
				from CASEBUDGET
				where REVISEDFLAG=0
				group by CASEID) CB1 on (CB1.CASEID=T.CASEID)
		left join (	select	CASEID, 
					sum(isnull(VALUE,0)) as RevisedBudgetAmount
				from CASEBUDGET C
				where REVISEDFLAG=1
				group by CASEID) CB2 on (CB2.CASEID=T.CASEID)"
        
		Exec @ErrorCode = sp_executesql @sSQLString,
						N'@pnBudgetAmount	        decimal(11,2),
                                                  @pnRevisedBudgetAmount        decimal(11,2),
						  @pdtStartDate	                datetime,
						  @pdtEndDate	                datetime',
						  @pnBudgetAmount	        =@pnBudgetAmount,
						  @pnRevisedBudgetAmount        =@pnRevisedBudgetAmount,
						  @pdtStartDate	                = @pdtStartDate,
						  @pdtEndDate	                = @pdtEndDate
	End
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Update #TempCaseBudget
		Set BudgetUsed		= CASE WHEN(BudgetAmount       <>0) THEN (UsedTotal    * 100)/ BudgetAmount END,
		    RevisedBudgetUsed  	= CASE WHEN(RevisedBudgetAmount<>0) THEN (UsedTotal    * 100)/ RevisedBudgetAmount END,
		    BudgetBilled	= CASE WHEN(BudgetAmount       <>0) THEN (BilledToDate * 100)/ BudgetAmount END,
		    RevisedBudgetBilled  =CASE WHEN(RevisedBudgetAmount<>0) THEN (BilledToDate * 100)/ RevisedBudgetAmount END"
		    
		Exec @ErrorCode=sp_executesql @sSQLString
	End
	
	-- Return the results.
	If  @ErrorCode=0
	Begin
			Set @sSQLString="
			Select	cast(T.CASEID as nvarchar(11))
							as RowKey,
				T.CASEID		as CaseKey,
				T.BudgetAmount		as BudgetAmount,
				T.BudgetUsed            as BudgetUsed,
				T.BudgetBilled          as BudgetBilled,
				T.RevisedBudgetAmount	as RevisedBudgetAmount,
                                T.RevisedBudgetUsed     as RevisedBudgetUsed,
                                T.RevisedBudgetBilled   as RevisedBudgetBilled,
				T.BudgetStartDate       as BudgetStartDate,
				T.BudgetEndDate         as BudgetEndDate,
                                @sLocalCurrencyCode     as LocalCurrencyCode,
                                @nLocalDecimalPlaces    as LocalDecimalPlaces		
			from #TempCaseBudget T"
	
			Exec @ErrorCode=sp_executesql @sSQLString,
                                N'@sLocalCurrencyCode nvarchar(3),
                                @nLocalDecimalPlaces smallint',
                                @sLocalCurrencyCode = @sLocalCurrencyCode,
                                @nLocalDecimalPlaces = @nLocalDecimalPlaces
		End

Return @ErrorCode
go

grant execute on dbo.csw_GetBudgetInfo to public
go
