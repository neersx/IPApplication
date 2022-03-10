use cpalive
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cpass_SoftwareMaintReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[cpass_SoftwareMaintReport]
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE     PROCEDURE dbo.cpass_SoftwareMaintReport
(
	@pdtFromDate	datetime	= null
	,@pdtToDate		datetime	= null
	,@psCaseType		nchar(1)	= null
	,@pnIncludeClosedProjects		int		= 0
	,@pnIncludeProjectsNotStarted	int		= 0
	,@pnCostCalculation				int		= 0
)

AS
-- PROCEDURE :	cpass_SoftwareMaintReport
-- DESCRIPTION:	Gets the report set for the Project Status Report
-- NOTES:	
-- VERSION:	1
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 02 Sep 2006	JD		1	Procedure created


Set nocount on
Set concat_null_yields_null off

Declare	@ErrorCode	int
Declare	@sCompanyName	nvarchar(254)  
Declare	@nRowCount	int

Declare	@ReportSet	table
(
	[FAMILY]
			nvarchar(254) collate database_default
	,CASEID
			int
	,IRN
			nvarchar(30) collate database_default
	,[COUNTRY]
			nvarchar(254) collate database_default
	,[COMPANY NAME]
			nvarchar(254) collate database_default
	,[CLIENT NAME]
			nvarchar(254) collate database_default
	,[PROJECT LEADER]
			nvarchar(254) collate database_default
	,[START DATE]
			datetime
	,[CLOSED DATE]
			datetime
	,[IMPLEMENTATION STATUS]
			int
	,FEES	decimal(12,2)
	,[FOREIGN CURRENCY]
			nvarchar(3) collate database_default
	,[CLIENT CURRENCY]	
			decimal(12,2)
	,DAYS	decimal(5,1)
	,[COST]	decimal(12,2)
)

Set @ErrorCode=0

SELECT	@sCompanyName = CASE WHEN NL.FIRSTNAME IS NOT NULL THEN NL.FIRSTNAME + ' ' END
	+ NL.NAME
FROM 	[SITECONTROL] SC
join	NAME NL on ( NL.NAMENO = SC.COLINTEGER and CONTROLID = 'HOMENAMENO' )


If @ErrorCode=0
Begin
	insert into	@ReportSet

	SELECT 	DISTINCT 
		C.FAMILY,
		C.CASEID,
		C.IRN,
		CTY.COUNTRY,
		@sCompanyName,
		-- Instructor reference
		substring(  CASE WHEN NCNCLIENT.FIRSTNAME IS NOT NULL THEN NCNCLIENT.FIRSTNAME + ' ' END
		+ NCNCLIENT.NAME,0,254 ) as [CLIENT_NAME],
		-- Project Leader
		substring(  CASE WHEN NL.FIRSTNAME IS NOT NULL THEN NL.FIRSTNAME + ' ' END
		+ NL.NAME,0,254 ) as [PROJECT LEADER],
		-- Start Date
		( select	ESTARTDT.EVENTDATE
		FROM  		CASEEVENT ESTARTDT
		WHERE		ESTARTDT.CASEID = C.CASEID 
					and	ESTARTDT.EVENTNO = -4 
					and 	ESTARTDT.CYCLE = ( 
							SELECT 	MAX(CYCLE)
							FROM  	CASEEVENT 
							WHERE 	CASEID = C.CASEID
							AND	EVENTNO = ESTARTDT.EVENTNO )
					)  as [START DATE],
		-- Closed date
		( select	ELIVEDT.EVENTDATE
		FROM  		CASEEVENT ELIVEDT 
		WHERE		ELIVEDT.CASEID = C.CASEID 
					and	ELIVEDT.EVENTNO = -12 
					and 	ELIVEDT.CYCLE = ( 
							SELECT 	MAX(CYCLE)
							FROM  	CASEEVENT 
							WHERE 	CASEID = C.CASEID
							AND	EVENTNO = ELIVEDT.EVENTNO )
					)	as [CLOSED DATE],
		-- Status
		case when  LIVE.EVENTDATE is not null then 
				case when LIVE.EVENTDATE <= GetDate() then 1 else 0 end  
		else	1 end	as [IMPLEMENTATION STATUS],
		NULL,
		NULL,
		NULL,
		NULL,
		NULL
	FROM  	CASES C
	-- Project Leader
	left JOIN CASENAME CNL on ( CNL.CASEID = C.CASEID and CNL.NAMETYPE = 'EMP'  )
	left JOIN NAME NL on ( NL.NAMENO = CNL.NAMENO )
	left JOIN TELECOMMUNICATION TL on ( TL.TELECODE = NL.MAINEMAIL )
	-- Instructor reference
	left join	CASENAME CNCLIENT on ( CNCLIENT.CASEID=C.CASEID 
					and	CNCLIENT.NAMETYPE  = 'I' 
					AND	CNCLIENT.SEQUENCE = ( 	SELECT 	MIN(CN2.SEQUENCE) 
									FROM 	CASENAME CN2 
									WHERE 	CN2.NAMETYPE  = 'I' 
									AND	CN2.CASEID=C.CASEID )
						)
	left join	COUNTRY CTY	on	CTY.COUNTRYCODE = C.COUNTRYCODE
	left JOIN NAME NCNCLIENT on ( NCNCLIENT.NAMENO = CNCLIENT.NAMENO )
	left join ( SELECT 	EVENTDATE, FAMILY
				FROM  	CASEEVENT E
				join	CASES T on E.CASEID = T.CASEID
				WHERE 	T.PROPERTYTYPE = 'B'
				AND		E.EVENTNO = -8
				) as LIVE on LIVE.FAMILY = C.FAMILY

	WHERE 	C.PROPERTYTYPE = 'E'
	AND	( @psCaseType is NULL OR C.CASETYPE = @psCaseType )
	AND	( @pnIncludeClosedProjects = 1 OR
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
--	AND		C.FAMILY is not null

	update	@ReportSet
	set		[START DATE] = case when	[START DATE] < @pdtFromDate or [START DATE] is null then @pdtFromDate else [START DATE] end,
			[CLOSED DATE] = case when	[CLOSED DATE] > @pdtToDate or [CLOSED DATE] is null then @pdtToDate else [CLOSED DATE] end

	set	@ErrorCode = @@Error
End

If @ErrorCode=0
Begin
	update	@ReportSet
	set		DAYS = cast(
		((
		select 
		isnull(sum(CASE WHEN(WT.CATEGORYCODE='SC' 
				) THEN  isnull(datepart(hour, WH.TOTALTIME)*60,0)+isnull(datepart(minute,WH.TOTALTIME),0) ELSE 0 END),0)
		from	WORKHISTORY WH
		left join	WIPTEMPLATE WTP	on (WTP.WIPCODE = WH.WIPCODE)
		left join	WIPTYPE WT		on (WT.WIPTYPEID= WTP.WIPTYPEID)
		where	(WH.CASEID= RS.CASEID 
						and		WH.STATUS<>0
						and		WH.MOVEMENTCLASS in (1,4,5))
		and		( [START DATE] is null or WH.POSTDATE >= [START DATE] )
		and		( [CLOSED DATE] is null or WH.POSTDATE < [CLOSED DATE] ) 
) /480)  as decimal(5,1)),
			FEES =(
		select	sum(isnull(-WH.LOCALTRANSVALUE,0))
		from	WORKHISTORY WH
		where	(WH.CASEID= RS.CASEID 
						and WH.STATUS<>0
						and WH.MOVEMENTCLASS in (2) )
		and		( [START DATE] is null or WH.POSTDATE >= [START DATE] )
		and		( [CLOSED DATE] is null or WH.POSTDATE < [CLOSED DATE] ) ),
			[FOREIGN CURRENCY] =(
		select	top 1 FOREIGNCURRENCY
		from	WORKHISTORY WH
		where	(WH.CASEID= RS.CASEID 
						and WH.STATUS<>0
						and WH.MOVEMENTCLASS in (2)
						and FOREIGNCURRENCY is not null )
		and		( [START DATE] is null or WH.POSTDATE >= [START DATE] )
		and		( [CLOSED DATE] is null or WH.POSTDATE < [CLOSED DATE] ) ),
			[CLIENT CURRENCY] =(
		select	sum( isnull( isnull(-WH.[FOREIGNTRANVALUE],-WH.LOCALTRANSVALUE) ,0))
		from	WORKHISTORY WH
		where	(WH.CASEID= RS.CASEID 
						and WH.STATUS<>0
						and WH.MOVEMENTCLASS in (2) )
		and		( [START DATE] is null or WH.POSTDATE >= [START DATE] )
		and		( [CLOSED DATE] is null or WH.POSTDATE < [CLOSED DATE] ) ),
			[COST] = (
		select	sum( isnull((case when @pnCostCalculation = 1 then WH.COSTCALCULATION1 else WH.COSTCALCULATION2 end), 0))
		from	WORKHISTORY WH	
		where	(WH.CASEID= RS.CASEID )
		and		( [START DATE] is null or WH.POSTDATE >= [START DATE] )
		and		( [CLOSED DATE] is null or WH.POSTDATE < [CLOSED DATE] )
 )
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
			,[COMPANY NAME]
			,[COUNTRY]
			,[CLIENT NAME]
			,[PROJECT LEADER]
			,IRN
			,[IMPLEMENTATION STATUS]
			,FEES
			,[FOREIGN CURRENCY]
			,[CLIENT CURRENCY]
			,round(DAYS,0,1) as DAYS
			,isnull(FEES, 0 ) - isnull([COST], 0 ) as MARGIN
	from 	@ReportSet
	order by
			[COUNTRY]
			,[CLIENT NAME]
			,[PROJECT LEADER]

	set	@ErrorCode = @@Error
End

Return @ErrorCode

GO

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO

grant execute on [dbo].[cpass_SoftwareMaintReport] to public
go

--exec cpass_SoftwareMaintReport
--	@pnIncludeProjectsNotStarted = 1
--go