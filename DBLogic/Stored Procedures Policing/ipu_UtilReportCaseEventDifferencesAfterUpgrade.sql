-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_UtilReportCaseEventDifferencesAfterUpgrade
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipu_UtilReportCaseEventDifferencesAfterUpgrade]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipu_UtilReportCaseEventDifferencesAfterUpgrade.'
	Drop procedure [dbo].[ipu_UtilReportCaseEventDifferencesAfterUpgrade]
	Print '**** Creating Stored Procedure dbo.ipu_UtilReportCaseEventDifferencesAfterUpgrade...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipu_UtilReportCaseEventDifferencesAfterUpgrade
(
	@psOldDatabase		nvarchar(100),	-- Provide the name of the database before the upgrade
	@psNewDatabase		nvarchar(100),	-- Provide the name of the upgraded database	
	@psPolicingName		nvarchar(40),	-- Parameter name of Policing run on both database e.g. "Daily Policing"
	@pdtPolicingDate	datetime	-- The date for which Policing was run
)
as
-- PROCEDURE:	ipu_UtilReportCaseEventDifferencesAfterUpgrade
-- VERSION:	1
-- DESCRIPTION:	Used for parallel testing Inprotech release upgrades.
--		Will report differences found in CASEEVENT rows between 2 databases
--		for a specific Policing execution on a given date.
--		=========================================================================
-- INSTRUCTIONS:
--		1. Create 2 copies of your starting database (backup and restore).
--		2. Ensure CASEEVENT table is being logged within each of the 2 databases.
--		3. Run Policing (e.g. Daily Policing) on both databases.
--		4. Use this stored procedure to report on any differences discovered
--		   E.g. exec ipu_UtilReportCaseEventDifferencesAfterUpgrade
--					@psOldDatabase  = 'Inpro_Before',
--					@psNewDatabase  = 'Inpro_After',
--					@psPolicingName = 'Daily Policing',
--					@pdtPolicingDate= '24-May-2015'
--		=========================================================================
--
-- COPYRIGHT:	Copyright 1993 - 2015 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 28-May-2015  MF	48132	1	Procedure created


SET NOCOUNT ON

Declare @ErrorCode 	int
Declare @dtUntilDate	datetime

Declare @sSQLString	nvarchar(max)

Set @ErrorCode = 0
Set @dtUntilDate= @pdtPolicingDate+1

Set @sSQLString="
------------------------------------------------------------------------
-- Find all of the CASEEVENT rows that were Inserted, Updated or Deleted
-- during Daily Policing on each of the two databases.
------------------------------------------------------------------------
With PolicedCaseEvents AS
(	--------------------------------------------------------------
	-- Get the CASEEVENTS changed from the 'Before Upgrade' database
	--------------------------------------------------------------
	select CE.CASEID, CE.EVENTNO, CE.CYCLE
	from "+@psOldDatabase+"..POLICINGLOG POL
	join "+@psOldDatabase+"..CASEEVENT_iLOG CE on CE.LOGDATETIMESTAMP between POL.STARTDATETIME and POL.FINISHDATETIME

	where POL.POLICINGNAME = @psPolicingName
	and POL.STARTDATETIME between @pdtPolicingDate and @dtUntilDate
	and POL.FINISHDATETIME is not NULL

	union
	--------------------------------------------------------------
	-- Get the CASEEVENTS change from the 'After Upgrade' database
	--------------------------------------------------------------
	select CE.CASEID, CE.EVENTNO, CE.CYCLE
	from "+@psNewDatabase+"..POLICINGLOG POL
	join "+@psNewDatabase+"..CASEEVENT_iLOG CE on CE.LOGDATETIMESTAMP between POL.STARTDATETIME and POL.FINISHDATETIME

	where POL.POLICINGNAME = @psPolicingName
	and POL.STARTDATETIME between @pdtPolicingDate and @dtUntilDate
	and POL.FINISHDATETIME is not NULL
)
------------------------------------------------------------------------
-- Using the list of CASEEVENTS that either database has changed during
-- Daily Policing, now report the details of those CASEEVENT rows that
-- are actually different between the two databases.
------------------------------------------------------------------------
select CE.CASEID, CE.EVENTNO, CE.CYCLE
from PolicedCaseEvents CE
left join "+@psOldDatabase+"..CASEEVENT CE1	
					on (CE1.CASEID =CE.CASEID
					and CE1.EVENTNO=CE.EVENTNO
					and CE1.CYCLE  =CE.CYCLE)
					
left join "+@psNewDatabase+"..CASEEVENT CE2	
					on (CE2.CASEID =CE.CASEID
					and CE2.EVENTNO=CE.EVENTNO
					and CE2.CYCLE  =CE.CYCLE)

where checksum(CE1.EVENTDATE,CE1.EVENTDUEDATE,CE1.DATEREMIND,CE1.DATEDUESAVED,CE1.OCCURREDFLAG,CE1.USEMESSAGE2FLAG,CE1.GOVERNINGEVENTNO,CE1.FROMCASEID, CE1.EMPLOYEENO, CE1.DUEDATERESPNAMETYPE)
    <>checksum(CE2.EVENTDATE,CE2.EVENTDUEDATE,CE2.DATEREMIND,CE2.DATEDUESAVED,CE2.OCCURREDFLAG,CE2.USEMESSAGE2FLAG,CE2.GOVERNINGEVENTNO,CE2.FROMCASEID, CE2.EMPLOYEENO, CE2.DUEDATERESPNAMETYPE)
Order by CE.EVENTNO, CE.CASEID, CE.CYCLE"


exec @ErrorCode=sp_executesql @sSQLString,
			N'@pdtPolicingDate	datetime,
			  @dtUntilDate		datetime,
			  @psPolicingName	nvarchar(40)',
			  @pdtPolicingDate=@pdtPolicingDate,
			  @dtUntilDate	  =@dtUntilDate,
			  @psPolicingName =@psPolicingName


Return @ErrorCode
GO

Grant execute on dbo.ipu_UtilReportCaseEventDifferencesAfterUpgrade to public
GO
