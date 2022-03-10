use cpalive
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

drop procedure dbo.cpass_GetTimeReportingDetails
go

CREATE  PROCEDURE dbo.cpass_GetTimeReportingDetails
(
	@psEntryPoint   nvarchar(254),
	@pbSummary	int = 0
)
AS

Set nocount on
Set concat_null_yields_null off


Create table #TempTimeDetails
 (Caseid   int  null,
  Title   varchar(254) collate database_default null ,
  Initial_Estimate int  null,
  Revised_Estimate int  null,
  Actual   int  null,
  Remaining  int  null,
  BudgetedFees  decimal(11,2)  null,
  ActualFees  decimal(11,2)  null,
  Forecast decimal(11,2)  null,
  Property_Type  varchar(2) collate database_default null )

Create table #TempTimeDetailsFees
 ([ID]		int identity(1,1),
  Caseid   int  null,
  BudgetedFees  decimal(11,2)  null)

Declare @ErrorCode int
Declare @nMax int
Declare @nIndex int
Declare @nCaseId int
Declare @nBudgetAmount decimal(11, 2)
Declare @nAcutalFees decimal(11, 2)

Set @ErrorCode=0

If @ErrorCode=0
Begin
 -- Load the temporary table.
 insert into #TempTimeDetails
 select distinct c.caseid, c.title, 0, 0, 0, 0, isnull( isnull( BUDGETREVISEDAMT, BUDGETAMOUNT ), 0),0,0, c.propertytype+'1'
 from cases c
 left join caseevent ce1 on (ce1.caseid = c.caseid and ce1.eventno = -4)  -- start date
 left join caseevent ce2 on (ce2.caseid = c.caseid and ce2.eventno = -8)  -- finish date
 where c.family = @psEntryPoint
 and c.propertytype in ('C','D')

 Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
 -- Update the temporary table with estimate figures.

 update #TempTimeDetails
 set Initial_Estimate = (select sum(cb1.hours) from casebudget cb1 where cb1.caseid = t.caseid and cb1.revisedflag = 0), -- initial estimates
       Revised_Estimate = (select sum(cb2.hours) from casebudget cb2 where cb2.caseid = t.caseid and cb2.revisedflag = 1) -- revised estimates
 from #TempTimeDetails t

 Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
 -- Update the temporary table with actual figure.

 update #TempTimeDetails
 set Actual = (select sum(isnull(datepart(hour, totaltime)*60,0)+isnull(datepart(minute,totaltime),0))/480.0
    from workhistory wh, wiptemplate wtp, wiptype wt
    where wh.caseid = #TempTimeDetails.caseid
    and wh.status <> 0
    and wh.movementclass in (1,4,5)
    and wtp.wipcode = wh.wipcode
    and wt.wiptypeid = wtp.wiptypeid
    and wt.categorycode = 'SC')

 
 Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
 -- Update the temporary table - replace null values with zeros

 update #TempTimeDetails
 set Initial_Estimate = 0
 where Initial_Estimate is null

 update #TempTimeDetails
 set Revised_Estimate = 0
 where Revised_Estimate is null

 update #TempTimeDetails
 set Actual = 0
 where Actual is null
 
 Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
 -- Update the temporary table with time remaining.

 update #TempTimeDetails
 set Remaining = case when Revised_Estimate > 0
        then ((Revised_Estimate/8.00) - Actual)
   else ((Initial_Estimate/8.00) - Actual)
   end
 
 Set @ErrorCode=@@Error
End


If @ErrorCode=0
Begin
 -- Update the temporary table with the actual fees.

	--insert into #TempCaseBudget exec [dbo].[cs_GetBudgetDetails] @psFamily = @psEntryPoint
	update 	#TempTimeDetails
	set 	ActualFees = (	select isnull(sum(-WH.LOCALTRANSVALUE),0)
					from WORKHISTORY WH	
					where WH.CASEID = #TempTimeDetails.CASEID
					and   WH.STATUS <> 0
					and   WH.MOVEMENTCLASS=2)
/*			+ (	select isnull(sum(-WH.LOCALTRANSVALUE),0)
					from WORKHISTORY WH
					Where WH.CASEID=#TempTimeDetails.CASEID
					and   WH.STATUS <> 0
					and   WH.MOVEMENTCLASS in (3,9)) 
			+ (	select isnull(sum(isnull(BALANCE,0)),0)
					from  WORKINPROGRESS W 
					where W.CASEID = #TempTimeDetails.CASEID
					and   W.STATUS<>0)
*/
	Set @ErrorCode=@@Error
End


If @ErrorCode=0
Begin
 -- Update the temporary table with the actual fees.

	update 	#TempTimeDetails
	set 	Forecast = case when BudgetedFees > ActualFees then BudgetedFees else ActualFees end
	
	Set @ErrorCode=@@Error
End

-- Sub total for 'Project/Implementation Work'

If @ErrorCode=0
Begin
 -- Update with totals

 insert into #TempTimeDetails
 select null,
	'Project/Implementation Work', 
	sum(t.Initial_Estimate),
  	sum(t.Revised_Estimate),
	sum(t.Actual),
	sum(t.Remaining),
	sum(t.BudgetedFees),
  	sum(t.ActualFees),
  	sum(t.Forecast),
  	'C2'
 from 	#TempTimeDetails t
 where 	Property_Type = 'C1'
 
 Set @ErrorCode=@@Error
End

-- Sub totals for 'Additional Implementation Work'

If @ErrorCode=0
Begin
 -- Update with totals

 insert into #TempTimeDetails
 select null,
	'Additional Implementation Work', 
	sum(t.Initial_Estimate),
  	sum(t.Revised_Estimate),
	sum(t.Actual),
	sum(t.Remaining),
  	sum(t.BudgetedFees),
  	sum(t.ActualFees),
  	sum(t.Forecast),
	'D2'
 from #TempTimeDetails t
 where Property_Type = 'D1'

 Set @ErrorCode=@@Error
End

-- Totals for 'Time Reporting' section

If @ErrorCode=0
Begin
 -- Update with totals

 insert into #TempTimeDetails
 select 	null,
	'Total', 
	sum(t.Initial_Estimate),
	sum(t.Revised_Estimate),
	sum(t.Actual),
	sum(t.Remaining),
	sum(t.BudgetedFees),
	sum(t.ActualFees),
  	sum(t.Forecast),
	'Z9'
 from 	#TempTimeDetails t
 where 	Property_Type in ('C1','D1')
 
 Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
 -- Return the restricted result set and order by a specific hardcoded sequence

if @pbSummary = 1
begin
	select Title,
	cast(Initial_Estimate/8.0 as decimal(5,0)) as 'Initial_Estimate',
	cast(Revised_Estimate/8.0 as decimal(5,0)) as 'Revised_Estimate',
	cast(Actual as decimal(5,0)) as 'Actual',
	cast(Remaining as decimal(5,0)) as 'Remaining',
	BudgetedFees,
	ActualFees,
  	Forecast
	from #TempTimeDetails
	where Title = 'Total'
end
else
begin
	select T.Title,
	cast(Initial_Estimate/8.0 as decimal(5,0)) as 'Initial_Estimate',
	cast(Revised_Estimate/8.0 as decimal(5,0)) as 'Revised_Estimate',
	cast(Actual as decimal(5,0)) as 'Actual',
	cast(Remaining as decimal(5,0)) as 'Remaining',
	BudgetedFees,
	ActualFees,
  	Forecast
	from	#TempTimeDetails T
	left join	CASES C on ( C.CASEID = T.CASEID )
	order by 
			Property_Type,
			C.IRN
end

 Set @ErrorCode=@@Error

End


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on [dbo].[cpass_GetTimeReportingDetails] to public
go