use cpalive
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cpass_ProjectMarginReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[cpass_ProjectMarginReport]
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE     PROCEDURE dbo.cpass_ProjectMarginReport
(
	@pdtFromDate	datetime	= null
	,@pdtToDate		datetime	= null
	,@psCaseType		nchar(1)	= null
	,@psCaseFamily	nvarchar(20)	= null
	,@pnProjectLeader
					int		= null
	,@pnIncludeClosedProjects		int		= 0
	,@pnIncludeProjectsNotStarted	int		= 0
	,@pnCostCalculation				int		= 0
)

AS
-- PROCEDURE :	cpass_ProjectMarginReport
-- DESCRIPTION:	Gets the report set for the Project Status Report
-- NOTES:	
-- VERSION:	1
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 02 Sep 2006	JD		1	Procedure created

--IDC_MOVEMENT_GENERATE = 1
--IDC_MOVEMENT_CONSUME = 2
--IDC_MOVEMENT_DISPOSE = 3
--IDC_MOVEMENT_ADJUSTUP = 4
--IDC_MOVEMENT_ADJUSTDOWN = 5
--IDC_MOVEMENT_EQUALISE = 9


Set nocount on
Set concat_null_yields_null off

Declare	@ErrorCode	int
		,@nMax		int
		,@nIndex	int
Declare	@sCompanyName
					nvarchar(254)
		,@sEntryPoint 
					nvarchar(254)
Declare	@sFamily	nvarchar(254)  
Declare	@nRowCount	int
Declare	@dtFromDate	datetime
		,@dtToDate	datetime

Declare	@ReportSetTemp	table
(
	[PROJECTLEADER]
			nvarchar(254) collate database_default
	,[FAMILY]
			nvarchar(254) collate database_default
	,[COMPANYNAME]
			nvarchar(254) collate database_default
	,[CLIENTNAME]
			nvarchar(254) collate database_default
	,[STARTDATE]
			datetime
	,[CLOSEDDATE]
			datetime
	,[INDEX]	
			int identity(1,1)
)

Declare	@ReportSet	table
(
	[PROJECTLEADER]
			nvarchar(254) collate database_default
	,[FAMILY]
			nvarchar(254) collate database_default
	,[COMPANYNAME]
			nvarchar(254) collate database_default
	,[CLIENTNAME]
			nvarchar(254) collate database_default
	,[STARTDATE]
			datetime
	,[CLOSEDDATE]
			datetime
	,[PROPERTYTYPE]
			nchar(1) collate database_default
	,PROPERTYNAME
			nvarchar(50) collate database_default
	,FEESACTUAL
			decimal(12,2)
	,DAYSACTUAL
			decimal(5,1)
	,MARGINACTUAL
			decimal(12,2)
	,FEESBUDGET
			decimal(12,2)
	,DAYSBUDGET
			decimal(5,1)
	,MARGINBUDGET
			decimal(12,2)
	,FEESVARIANCE
			decimal(12,2)
	,MARGINVARIANCE
			decimal(12,2)
	,PROFITABILITYBUDGET
			decimal(12,2)
	,PROFITABILITYACTUAL
			decimal(12,2)
)

create table #TempTotals (
		FAMILYTITLE			NVARCHAR(254)	COLLATE DATABASE_DEFAULT NULL
		,PROPERTYNAME			NVARCHAR(50)	COLLATE DATABASE_DEFAULT NULL
		,PROPERTYTYPE			NCHAR(1)	COLLATE DATABASE_DEFAULT NULL
		,BUDGETDAYS			DECIMAL(11, 2)	NULL
		,BUDGETFEES			DECIMAL(11, 2)	NULL
		,BUDGETMARGIN			DECIMAL(11, 2)	NULL
		,ACTUALDAYS			DECIMAL(11, 2)	NULL
		,ACTUALFEES			DECIMAL(11, 2)	NULL
		,ACTUALMARGIN			DECIMAL(11, 2)	NULL
		,VARIANCE			DECIMAL(11, 2)	NULL
		,[FAMILY]
			nvarchar(254) collate database_default
		)

Set @ErrorCode=0

SELECT	@sCompanyName = CASE WHEN NL.FIRSTNAME IS NOT NULL THEN NL.FIRSTNAME + ' ' END
	+ NL.NAME
FROM 	[SITECONTROL] SC
join	NAME NL on ( NL.NAMENO = SC.COLINTEGER and CONTROLID = 'HOMENAMENO' )

If @ErrorCode=0
Begin
	insert into	@ReportSetTemp

	SELECT 	DISTINCT 
		-- Project Leader
		substring(  CASE WHEN NL.FIRSTNAME IS NOT NULL THEN NL.FIRSTNAME + ' ' END
		+ NL.NAME,0,254 ) as [PROJECTLEADER]
		,C.FAMILY
		,@sCompanyName
		-- Instructor reference
		,CNCLIENT.REFERENCENO  as [CLIENTNAME]
		-- Start Date
		,( select	ESTARTDT.EVENTDATE
		FROM  		CASEEVENT ESTARTDT
		WHERE		ESTARTDT.CASEID = C.CASEID 
					and	ESTARTDT.EVENTNO = -4 
					and 	ESTARTDT.CYCLE = ( 
							SELECT 	MAX(CYCLE)
							FROM  	CASEEVENT 
							WHERE 	CASEID = C.CASEID
							AND	EVENTNO = ESTARTDT.EVENTNO )
					)  as [STARTDATE]
		-- Closed date
		,( select	ELIVEDT.EVENTDATE
		FROM  		CASEEVENT ELIVEDT 
		WHERE		ELIVEDT.CASEID = C.CASEID 
					and	ELIVEDT.EVENTNO = -12 
					and 	ELIVEDT.CYCLE = ( 
							SELECT 	MAX(CYCLE)
							FROM  	CASEEVENT 
							WHERE 	CASEID = C.CASEID
							AND	EVENTNO = ELIVEDT.EVENTNO )
					)	as [CLOSEDDATE]
	FROM  	CASES C	
	left JOIN CASENAME CNL on ( CNL.CASEID = C.CASEID and CNL.NAMETYPE = 'EMP'  )
	left JOIN NAME NL on ( NL.NAMENO = CNL.NAMENO )
	-- Instructor reference
	left join	CASENAME CNCLIENT on ( CNCLIENT.CASEID=C.CASEID 
					and	CNCLIENT.NAMETYPE  = 'I' 
					AND	CNCLIENT.SEQUENCE = ( 	SELECT 	MIN(CN2.SEQUENCE) 
									FROM 	CASENAME CN2 
									WHERE 	CN2.NAMETYPE  = 'I' 
									AND	CN2.CASEID=C.CASEID )
						)

	WHERE 	C.PROPERTYTYPE = 'B' 
	and	( @psCaseType is NULL OR C.CASETYPE = @psCaseType )
	AND	( @psCaseFamily is NULL OR C.FAMILY = @psCaseFamily ) 
	AND	( @pnProjectLeader is NULL OR (
		( @pnProjectLeader is NOT NULL AND EXISTS 	(
							SELECT 	*
							FROM  	CASENAME CN 
							WHERE 	CN.CASEID = C.CASEID
							AND	CN.NAMETYPE = 'EMP'
							AND	CN.NAMENO = @pnProjectLeader
								)
 						)
		)
		)	AND	( @pnIncludeClosedProjects = 1 OR
		( @pnIncludeClosedProjects = 0
		AND		NOT EXISTS	(
							SELECT 	EVENTDATE
							FROM  	CASEEVENT E
							WHERE 	E.CASEID = C.CASEID
							AND	E.EVENTNO = -12 )
		)
		)
	AND	( @pnIncludeProjectsNotStarted = 1 OR
		( @pnIncludeProjectsNotStarted = 0
		AND		EXISTS	(
							SELECT 	EVENTDATE
							FROM  	CASEEVENT E
							WHERE 	E.CASEID = C.CASEID
							AND	E.EVENTNO = -4 )
		AND		getdate() >=	(
					SELECT 	EVENTDATE
					FROM  	CASEEVENT E
					WHERE 	E.CASEID = C.CASEID
					AND		E.EVENTNO = -4					
					and 	E.CYCLE = ( 
							SELECT 	MAX(CYCLE)
							FROM  	CASEEVENT 
							WHERE 	CASEID = E.CASEID
							AND		EVENTNO = E.EVENTNO ) )
		)
		)
	AND		C.FAMILY is not null 

	update	@ReportSetTemp
	set		[STARTDATE] = case when	[STARTDATE] < @pdtFromDate or [STARTDATE] is null then @pdtFromDate else [STARTDATE] end,
			[CLOSEDDATE] = case when	[CLOSEDDATE] > @pdtToDate or [CLOSEDDATE] is null then @pdtToDate else [CLOSEDDATE] end

	set	@ErrorCode = @@Error
End

If @ErrorCode=0
Begin
	set	@nIndex = 1

	select	@nMax = max([INDEX])
	from	@ReportSetTemp

	while	@nIndex <= @nMax and @ErrorCode = 0
	begin
		select	@sEntryPoint = FAMILY
				,@dtFromDate = [STARTDATE]
				,@dtToDate = [CLOSEDDATE]
		from	@ReportSetTemp
		where	[INDEX] = @nIndex

		set	@nIndex = @nIndex + 1

		insert into #TempTotals (
			FamilyTitle
			,PropertyName
			,PropertyType
			,BudgetDays
			,BudgetFees
			,BudgetMargin
			,ActualDays
			,ActualFees
			,ActualMargin
			,Variance )
		exec	cpass_GetBudgetDetailsVsActual
			@psEntryPoint		= @sEntryPoint
			,@pdtFromDate		= @dtFromDate
			,@pdtToDate			= @dtToDate
			,@pnCostCalculation	= @pnCostCalculation

		update	#TempTotals
		set		Family = @sEntryPoint

--		select * from #TempTotals

		insert into	@ReportSet 
			(	[FAMILY]
				,[COMPANYNAME]
				,PROJECTLEADER
				,[CLIENTNAME]
				,[STARTDATE]
				,[CLOSEDDATE]
				,[PROPERTYTYPE]
				,PROPERTYNAME
				,FEESACTUAL
				,DAYSACTUAL
				,MARGINACTUAL
				,FEESBUDGET
				,DAYSBUDGET
				,MARGINBUDGET
		)
		select	RTS.[FAMILY]
				,RTS.[COMPANYNAME]
				,RTS.PROJECTLEADER
				,RTS.[CLIENTNAME]
				,RTS.[STARTDATE]
				,RTS.[CLOSEDDATE]
				,TT.PROPERTYTYPE
				,TT.PROPERTYNAME
				,TT.ACTUALFEES
				,TT.ACTUALDAYS
				,TT.ACTUALMARGIN
				,TT.BUDGETFEES
				,TT.BUDGETDAYS
				,TT.BUDGETMARGIN
		from	@ReportSetTemp RTS
		join	#TempTotals TT on TT.Family = RTS.FAMILY
		where	TT.PROPERTYNAME <> 'Total'

		truncate table	#TempTotals

		set	@ErrorCode = @@Error
	end

	set	@ErrorCode = @@Error
End

If @ErrorCode=0
Begin
	update	@ReportSet
	set		FEESVARIANCE = round(
							(	Case when FEESACTUAL > 0 then
									Case when FEESBUDGET > 0 then	( ( FEESACTUAL - FEESBUDGET ) * 100 / FEESBUDGET )
									else null
									end
								else
									Case when FEESBUDGET > 0 then	-100
									else null
									end
								end
							) , 0, 1)
	,MARGINVARIANCE =		round(
							(	Case when MARGINACTUAL > 0 then
									Case when MARGINBUDGET > 0 then	( ( MARGINACTUAL - MARGINBUDGET ) * 100 / MARGINBUDGET )
									else null
									end
								else
									Case when MARGINBUDGET > 0 then	-100
									else null
									end
								end
							) , 0, 1)
	,PROFITABILITYBUDGET =	round(
							(	Case when FEESBUDGET > 0 then	( MARGINBUDGET * 100 / FEESBUDGET )
								else null
								end
							) , 0, 1)
	,PROFITABILITYACTUAL =	round(
							(	Case when FEESACTUAL > 0 then	( MARGINACTUAL * 100 / FEESACTUAL )
								else null
								end
							) , 0, 1)
	from	@ReportSet RS

	set	@ErrorCode = @@Error
End

If @ErrorCode=0
Begin

	select 	@nRowCount = count(*) 
	from 	@ReportSet

	set	@ErrorCode = @@Error
End

If @ErrorCode=0
Begin

	select	@nRowCount as [FAMILY COUNT]
			,COMPANYNAME
			,PROJECTLEADER
			,CLIENTNAME
			,PROPERTYTYPE
			,PROPERTYNAME
			,DAYSBUDGET
			,DAYSACTUAL
			,FEESBUDGET
			,FEESACTUAL
			,FEESVARIANCE
			,MARGINBUDGET
			,MARGINACTUAL
			,MARGINVARIANCE
			,PROFITABILITYBUDGET
			,PROFITABILITYACTUAL
	from 	@ReportSet
	order by
			PROJECTLEADER
			,[CLIENTNAME]
			,[PROPERTYTYPE]

	set	@ErrorCode = @@Error
End

Return @ErrorCode

GO

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO

grant execute on [dbo].[cpass_ProjectMarginReport] to public
go
--
--exec cpass_ProjectMarginReport @psCaseFamily = 'CLA01'
--go