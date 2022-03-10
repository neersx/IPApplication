-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceGetEventsForTempTable
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceGetEventsForTempTable]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceGetEventsForTempTable.'
	drop procedure dbo.ip_PoliceGetEventsForTempTable
end
print '**** Creating procedure dbo.ip_PoliceGetEventsForTempTable...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceGetEventsForTempTable 
			@pnDebugFlag		tinyint


as
-- PROCEDURE :	ip_PoliceGetEventsForTempTable
-- VERSION :	8
-- DESCRIPTION:	Get all of the CASEEVENT for the Cases being processed and load them into the #TEMPCASEEVENT
--		table if they are not already loaded.  This will then allow simplification of much of the 
--		SQL where we access both #TEMPCASEEVENT and CASEEVENT as we can then be assured that
--		#TEMPCASEEVENT will contain all data.

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 23 May 2007	MF	14812	1	Procedure created
-- 30 Aug 2007	MF	14425	2	Reserve word [STATE]
-- 29 Oct 2007	MF	15518	3	Insert LIVEFLAG on #TEMPCASEEVENT
-- 07 Jan 2008	MF	15586	3	Allow a specific Name or NameType to be associated with a CaseEvent due date.
-- 24 Jan 2008	MF	15864	4	Ensure IDENTITYID and USERID are initialised
-- 16 Apr 2008	MF	16249	5	Revisit 14812 to better handle Events under multiple Actions.
-- 06 Jun 2012	MF	S19025	6	Cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 06 Jun 2013	MF	S21404	7	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 14 Nov 2018  AV  75198/DR-45358	8   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on

DECLARE		@ErrorCode		int,
		@sSQLString		nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode   = 0

-- Load #TEMPCASEEVENT with the details of the CASEEVENT rows that exist

If @ErrorCode=0
Begin
	set @sSQLString="
	insert into #TEMPCASEEVENT
		(CASEID, EVENTNO, CYCLE,
		LOOPCOUNT, OLDEVENTDATE, OLDEVENTDUEDATE, DATEDUESAVED, OCCURREDFLAG,
		CREATEDBYACTION, CREATEDBYCRITERIA,
		ENTEREDDEADLINE, PERIODTYPE, DOCUMENTNO, DOCSREQUIRED, DOCSRECEIVED,
		USEMESSAGE2FLAG, GOVERNINGEVENTNO,
		[STATE],
		COUNTRYCODE, USERID,
		NEWEVENTDATE, NEWEVENTDUEDATE,
		DATEREMIND, CRITERIANO, ACTION, IDENTITYID,
		RESPNAMENO, RESPNAMETYPE, SAVEDUEDATE, RECALCEVENTDATE,SUPPRESSCALCULATION)
	SELECT	CE.CASEID, CE.EVENTNO, CE.CYCLE,
		0, CE.EVENTDATE, CE.EVENTDUEDATE, isnull(CE.DATEDUESAVED,0), isnull(CE.OCCURREDFLAG,0),
		CE.CREATEDBYACTION, CE.CREATEDBYCRITERIA,
		CE.ENTEREDDEADLINE, CE.PERIODTYPE, CE.DOCUMENTNO, CE.DOCSREQUIRED, CE.DOCSRECEIVED,
		CE.USEMESSAGE2FLAG, CE.GOVERNINGEVENTNO,
		'X',
		C.COUNTRYCODE, C.USERID,
		CE.EVENTDATE, CE.EVENTDUEDATE,
		CE.DATEREMIND, CE.CREATEDBYCRITERIA, CE.CREATEDBYACTION,C.IDENTITYID,
		CE.EMPLOYEENO,CE.DUEDATERESPNAMETYPE,E.SAVEDUEDATE,
		coalesce(E.RECALCEVENTDATE, 0), E.SUPPRESSCALCULATION
	from CASEEVENT CE
	join #TEMPCASES C	on (C.CASEID=CE.CASEID)
	left join #TEMPCASEEVENT T	on (T.CASEID =CE.CASEID
					and T.EVENTNO=CE.EVENTNO
					and T.CYCLE  =CE.CYCLE)
	left join EVENTCONTROL E	on (E.CRITERIANO=CE.CREATEDBYCRITERIA
					and E.EVENTNO   =CE.EVENTNO)
	Where T.CASEID is null"

	Execute @ErrorCode = sp_executesql @sSQLString
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceGetEventsForTempTable',0,1,@sTimeStamp ) with NOWAIT
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceGetEventsForTempTable  to public
go
