-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceSatisfyEvents
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceSatisfyEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceSatisfyEvents.'
	drop procedure dbo.ip_PoliceSatisfyEvents
end
print '**** Creating procedure dbo.ip_PoliceSatisfyEvents...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceSatisfyEvents
				@pnCountStateC		int	OUTPUT,
				@pnCountStateI		int	OUTPUT,
				@pnCountStateR		int	OUTPUT,
				@pnCountStateD		int	OUTPUT,
				@pnDebugFlag		tinyint
as
-- PROCEDURE :	ip_PoliceSatisfyEvents
-- VERSION :	23
-- DESCRIPTION:	A procedure that identifies CASEEVENT rows that have been satisfied by another Event
--              that has just occurred.
-- CALLED BY :	ipu_Policing

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 22/09/2000	MF			Procedure created	 
-- 15/11/2001	MF	7195		When an Event being satisfied had previously had its Event Due date manually
--					saved the procedure was incorrectly setting the NEWEVENTDATE to be the date
--					of the satifying event.
-- 18/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 01/03/2002	MF	7367 		Get ESTIMATEFLAG from the EventControl table for later charges raising.
-- 24/06/2002	MF	7765		Make certain that the USERID that triggered the policing request carrys
--					through to any other TEMPCASEEVENT rows.
-- 21/08/2002	MF	7532		Allow a new facility that causes the Due Date of an Event to be advanced by
--					a defined amount whenever the due date matches or exceeds the system date.
-- 21/08/2002	MF	7627		Allow a second Fee to be requested when an Event is updated.
-- 24 Jul 2003	MF	8260	10	Get the PTADELAY from EventControl table for calculation of the Patent Term Adjustment.
-- 12 Nov 2003	MF	9450	11	Set the CRITERIANO on the #TEMPCASEEVENT table when inserting rows.
-- 26 Feb 2004	MF	RFC709	12	Get IDENTITYID to identify workbench users
-- 03 Nov 2004	MF	10385	13	New EventControl column SETTHIRDPARTYOFF to turn off the ReportToThirdParty
--					flag against Cases when an Event occurs
-- 08 Mar 2005	MF	11126	14	When looking for Events that have been satisfied, consider all of the current
--					openactions against the case and not just the Action that originally 
--					created the CaseEvent.
-- 16 Feb 2006	MF	12333	15	Use the CriteriaNo of the RelatedEvent rule to identify the EventControl row
--					instead of the CreatedByCriteria against the CaseEvent.  This is because the
--					CreatedByCriteria is not always set for converted data.
-- 15 May 2006	MF	12315	16	New EventControl columns to update CASENAME when Event occurs.
-- 07 Jun 2006	MF	12417	17	Change order of columns returned in debug mode to make it easier to review
-- 21 Aug 2006	MF	13089	18	Get the DIRECTPAYFLAG from EventControl for later raising of charges.
-- 31 May 2007	MF	14812	19	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	20	Reserve word [STATE]
-- 06 Jun 2012	MF	S19025	21	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 15 Mar 2017	MF	70049	22	Allow Renewal Status to be separately specified to be updated by an Event.
-- 14 Nov 2018  AV  75198/DR-45358	23   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on
DECLARE		@ErrorCode	int,
		@sSQLString	nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

-- Now update the TEMPCASEEVENT table to set the STATE to indicate that these rows have now been satisfied
-- by another Event and are to be deleted.
-- Note that the STATE will be set to 'DX' so as to not confuse it with the original "D" rows which will be
-- updated to "D1" to indicate they have been processed.

-- Do this Update for each different STATE so that we can keep the various counts up to date. (States 'I' and
-- 'D' are not updated as they do not need to be Satisfied)

If  @ErrorCode=0
and @pnCountStateI>0
Begin
	Set @sSQLString="
	update	#TEMPCASEEVENT
	set 	@pnCountStateC = @pnCountStateC - CASE WHEN(TC.[STATE] like 'C%') THEN 1 ELSE 0 END,
		@pnCountStateR = @pnCountStateR - CASE WHEN(TC.[STATE] =    'R%') THEN 1 ELSE 0 END,
		[STATE]	       ='DX',	
				-- if the DateDueSaved flag is set to 1 then	
				-- set the OccurredFlag to 9 to indicate that	
				-- row will not be deleted completely.		
		OCCURREDFLAG   =CASE WHEN TC.DATEDUESAVED=1
					THEN 9
					ELSE TC.OCCURREDFLAG
				END
	from 	#TEMPCASEEVENT TC
		-- Use a derived table to determine the satisfied events.
		-- The derived table avoids an ambiguous table error.
	join (	select	distinct T.CASEID, T.EVENTNO, T.CYCLE
		from	#TEMPCASEEVENT	T
		join	#TEMPOPENACTION OA on ( OA.CASEID=T.CASEID
					   and  OA.POLICEEVENTS=1)
		join	RELATEDEVENTS	RE on ( RE.CRITERIANO  =OA.NEWCRITERIANO
					   and  RE.EVENTNO     =T.EVENTNO
					   and  RE.SATISFYEVENT=1)
		join	#TEMPCASEEVENT	T1 on ( T1.CASEID =T.CASEID
					   and  T1.EVENTNO=RE.RELATEDEVENT
					   and  T1.[STATE]='I'
					   and  T1.CYCLE  =CASE RE.RELATIVECYCLE WHEN (0) THEN T.CYCLE
										 WHEN (1) THEN T.CYCLE-1
										 WHEN (2) THEN T.CYCLE+1
										 WHEN (3) THEN 1
										 WHEN (4) THEN (select max(CYCLE)
												from #TEMPCASEEVENT T2
												where T2.CASEID =T1.CASEID
												and   T2.EVENTNO=T1.EVENTNO)
							   END)
		where	T.[STATE] not in ('I','D','D1','DX')
		and	T.NEWEVENTDATE is null) TU	
					on (TU.CASEID = TC.CASEID
				        and TU.EVENTNO= TC.EVENTNO
				        and TU.CYCLE  = TC.CYCLE)"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCountStateC	int	OUTPUT,
					  @pnCountStateR	int	OUTPUT',
					  @pnCountStateC=@pnCountStateC	OUTPUT,
					  @pnCountStateR=@pnCountStateR	OUTPUT
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceSatisfyEvents',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, @pnCountStateC as 'CountStateC', @pnCountStateI as 'CountStateI', @pnCountStateR as 'CountStateR', @pnCountStateD as 'CountStateD' 
		from	#TEMPCASEEVENT T
		where	T.[STATE]<>'X'
		order by 4,1,2,3"

		Exec @ErrorCode = sp_executesql @sSQLString,
						N'@pnCountStateC	int,
						  @pnCountStateI	int,
						  @pnCountStateR	int,
						  @pnCountStateD	int',
						  @pnCountStateC,
						  @pnCountStateI,
						  @pnCountStateR,
						  @pnCountStateD
	End
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceSatisfyEvents  to public
go