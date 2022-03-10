-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListAgedWIP
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListAgedWIP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListAgedWIP'
	drop procedure [dbo].[wa_ListAgedWIP]
	print '**** Creating procedure dbo.wa_ListAgedWIP...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListAgedWIP]
			@pnCaseId		int

-- PROCEDURE :	wa_ListAgedWIP
-- VERSION :	2.2.0
-- DESCRIPTION:	Display the aged WIP either by Staff Name or for a particular Case 
--		depending on whether the CaseId is passed.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 23/07/2001	MF	Procedure created	
-- 02/08/2001	AF	Rename columns for meaningful names returned
--			Also return CASEID for UI efficiency
-- 05 Jul 2013	vql	R13629(Remove string length restriction and use nvarchar on datetime conversions using 106 format)
-- 14 Nov 2018  AV  75198/DR-45358   Date conversion errors when creating cases and opening names in Chinese DB

as 
	-- set server options
	set NOCOUNT on

	-- declare variables
	declare	@ErrorCode	int

	-- initialise variables
	set @ErrorCode=0

	select WIP.CASEID, WC.CATEGORYCODE, WC.DESCRIPTION, WC.CATEGORYSORT,
	CONVERT(VARCHAR(20), CAST(sum(CASE WHEN (WIP.TRANSDATE > P0.STARTDATE)				THEN WIP.BALANCE ELSE 0 END) as MONEY), 1)
	as 'Current',
	CONVERT(VARCHAR(20), CAST(sum(CASE WHEN (WIP.TRANSDATE between P1.STARTDATE and P1.ENDDATE)	THEN WIP.BALANCE ELSE 0 END) as MONEY), 1)
	as 'Period1',
	CONVERT(VARCHAR(20), CAST(sum(CASE WHEN (WIP.TRANSDATE between P2.STARTDATE and P2.ENDDATE)	THEN WIP.BALANCE ELSE 0 END) as MONEY), 1)
	as 'Period2',
	CONVERT(VARCHAR(20), CAST(sum(CASE WHEN (WIP.TRANSDATE < P2.STARTDATE )				THEN WIP.BALANCE ELSE 0 END) as MONEY), 1)
	as 'Period3',
	CONVERT(VARCHAR(20), CAST(sum(WIP.BALANCE) as MONEY), 1) as 'Total',
	N.NAME, N.NAMENO
	from WORKINPROGRESS WIP
	     join WIPTEMPLATE W		on (W.WIPCODE      =WIP.WIPCODE)
	     join WIPTYPE WT		on (WT.WIPTYPEID   =W.WIPTYPEID)
	     join WIPCATEGORY WC	on (WC.CATEGORYCODE=WT.CATEGORYCODE)
	     join NAME N		on (N.NAMENO       =WIP.ENTITYNO)
								-- get the current period
	     join PERIOD P0		on (P0.STARTDATE<=convert(nvarchar,getdate(),112)
					and P0.ENDDATE  >=convert(nvarchar,getdate(),112))
			
								-- get the period one older than the current period
	left join PERIOD P1		on (P1.PERIODID = 
						substring ((	select max(convert(varchar,ENDDATE, 102) + convert(varchar,PERIODID))
								from PERIOD
								where ENDDATE < P0.STARTDATE ),
								11, 10))
		
								-- get the period two older than the current period
		left join PERIOD P2	on (P2.PERIODID = 
						substring ((	select max(convert(varchar,ENDDATE, 102) + convert(varchar,PERIODID))
								from PERIOD
								where ENDDATE < P1.STARTDATE ),
								11, 10))
	where WIP.STATUS <> 0 
	AND WIP.CASEID = @pnCaseId
	group by WIP.CASEID, N.NAME, N.NAMENO, WC.CATEGORYSORT, WC.CATEGORYCODE, WC.DESCRIPTION 
	ORDER BY N.NAME, WC.CATEGORYSORT, WC.CATEGORYCODE, WC.DESCRIPTION 

	Select @ErrorCode=@@Error

return @ErrorCode

go

grant execute on [dbo].[wa_ListAgedWIP]  to public
go
