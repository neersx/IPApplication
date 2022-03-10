-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceUpdateCaseStatus
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceUpdateCaseStatus]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceUpdateCaseStatus.'
	drop procedure dbo.ip_PoliceUpdateCaseStatus
end
print '**** Creating procedure dbo.ip_PoliceUpdateCaseStatus...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceUpdateCaseStatus
			@pnDebugFlag	tinyint
as
-- PROCEDURE :	ip_PoliceUpdateCaseStatus
-- VERSION :	20
-- DESCRIPTION:	The STATUSCODE and RENEWALSTATUS for the case is to be updated when an Event occurs
--              that has a Status attached.  There is the possibility that more than one Event for a 
--		case could occur at the one time.  If this happens then the Event that should have been
--		processed last is to be used to update the Case.  
--		Also the #TEMPOPENACTION table is to be updated with the last Status and Event updated.
-- 		If an Event has occurred that sets REPORTTOTHIRDPARTY on then it should be updated at
--		this time.
-- CALLED BY :	ipu_Policing

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	========
--  5/10/2000	MF			Procedure created
-- 15/08/2001	MF			When the STATUS of the CASE is being updated as a result of an EVENT occurring, 
--					the update will be handled differently depending on whether the EVENT was 
--					updated prior to Policing being called or updated within the Policing procedure.
-- 					If EVENTUPDATEDMANUALLY column is set ON then only update the Status if the the 
--					EVENTDATE is greater than or equal to the highest EventDate associated with the 
--					Case. 
--					If the EVENTUPDATEDMANUALLY column is not set ON then the Status may be updated 
--					irrespective of the EVENTDATE however in a predefined order of priority if more 
--					than one Event is attempting to update the Case.
-- 23/10/2001	MF	7139		When comparing the EVENTDATE before allowing the STATUSCODE to be updated strip
--					off the time component.
-- 19/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles 
-- 11/04/2002	MF	7565		When the Status of an Event is being updated as a result of an Event being 
--					manually entered then only apply the update if there are no other Events with 
--					a later date that also have a Status associated with it.
-- 28/06/2002	MF	7782		It is possible for the number of digits in DISPLAYSEQUENCE to exceed 3 which
--					was causing an error.
-- 14 JUL 03	MF	8975	10	Save the Eventno and Cycle of that is updating the Renewal Status.
-- 09 Feb 05	MF		11	Remove the update of the LASTEVENT.  This has been moved into its own
--					stored procedure because it may occur even if the Status is not being updated.
-- 30 May 2007	MF	14812	12	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 15 Jun 07	MF	14932	13	Warning message appearing when MAX returned nulls.  Change go to stop warning.
-- 30 Aug 2007	MF	14425	14	Reserve word [STATE]
-- 11 May 2009	MF	17672	15	If the Status has changed then check if any more #TEMPOPENACTION rows can be loaded
--					as Policing may now be possible on certain Actions.
-- 11 May 2010	MF	18736	16	Status change of a Case that now allows Policing should trigger recalculation of open Actions.
-- 21 May 2010	MF	18736	16	Revisit. If status is missing then treat as if the flag is on.
-- 01 Oct 2010	MF	18652	17	Revisit. On change of status call ip_PoliceGetActions to loade #TEMPOPENACTION with those 
--					Actions that were previously blocked by the status.
-- 07 Jun 2011	MF	19682	18	Correction of merge error where code in 18652 appears twice.
-- 15 Mar 2017	MF	70049	19	Allow Renewal Status to be separately specified to be updated by an Event.  We have to continue to support the current abilty
--					for the STATUSCODE to also hold the Renewal Status, in case the firm has not move to the Workflow Designer in Apps.
-- 14 Nov 2018  AV  75198/DR-45358	20   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on

DECLARE		@ErrorCode	int,
		@nRowCount	int,
		@sSQLString	nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0
Set @nRowCount = 0

-- Update the STATUSCODE of the Case with what would be the last EVENTNO with a Status to have been updated.
-- This is determined by the EVENTDATE and the DISPLAYSEQUENCE on the theory that Events are logically supposed to be processed
-- in that order. Do not update the Status if there are any Events with greater date if the Event was updated prior to
-- Policing being called.  This will stop the Status being changed back to an earlier Status if a missing or 
-- incorrectly entered event is updated.

-- The technique for identifying the last EVENTNO with a Status to be processed involves concatenating the
-- EVENTDATE, DISPLAYSEQUENCE, EVENTNO, CYCLE and STATUSCODE so that the MAX function returns the combination with the
-- highest DISPLAYSEQUENCE value.  The concatenated value returned is then able to be joined with the concatenated
-- equivalent columns that provides the STATUSCODE to be used in the update.
-- Also save the EventNo and Action that caused the StatusCode to be updated as this will be used in the 
-- ActivityHistory row inserted when the data is committed to the database.


If @ErrorCode=0
Begin
	set @sSQLString="
	update 	#TEMPCASES
	set	STATUSCODE	=T.STATUSCODE,
		EVENTNO		=T.EVENTNO,
		CYCLE		=T.CYCLE,
		ACTION		=T.CREATEDBYACTION,
		OLDSTATUSCODE	=C.STATUSCODE
	from	#TEMPCASES C
	join	#TEMPCASEEVENT	T on (T.CASEID=C.CASEID
				  and T.[STATE]='I')
	join	STATUS S	  on (S.STATUSCODE=T.STATUSCODE
				  and(S.RENEWALFLAG=0 OR S.RENEWALFLAG is NULL))
	left join (	select T2.CASEID, T2.NEWEVENTDATE
			from #TEMPCASEEVENT T2
			join ACTIONS A	on (A.ACTION        =T2.CREATEDBYACTION
					and(A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))
			join EVENTCONTROL EC	
					on (EC.CRITERIANO   =T2.CREATEDBYCRITERIA
					and EC.EVENTNO      =T2.EVENTNO)
			join STATUS S	on (S.STATUSCODE    =EC.STATUSCODE
					and S.RENEWALFLAG   =0)
			where T2.EVENTNO not in (-16,-14,-13) ) TX
					on (TX.CASEID=T.CASEID
					and TX.NEWEVENTDATE>T.NEWEVENTDATE
					-- only need to check previous Status if Statuscode is not null
					-- and if the Event triggering this has been manually entered
					and C.STATUSCODE is not null
					and T.EVENTUPDATEDMANUALLY=1)
	where	convert(nchar(8),T.NEWEVENTDATE,112)+
		space(5-len(isnull(T.DISPLAYSEQUENCE,0)))+convert(nvarchar(5),isnull(T.DISPLAYSEQUENCE,0))+
		convert(nchar(9),T.EVENTNO)+
		convert(nchar(5),T.CYCLE)  +
		convert(nchar(9),T.STATUSCODE)
			= (select max(	isnull(
					convert(nchar(8),T1.NEWEVENTDATE,112)+
					space(5-len(isnull(T1.DISPLAYSEQUENCE,0)))+convert(nvarchar(5),isnull(T1.DISPLAYSEQUENCE,0))+
					convert(nchar(9),T1.EVENTNO)+
					convert(nchar(5),T1.CYCLE)  +
					convert(nchar(9),T1.STATUSCODE),'') )
			   from #TEMPCASEEVENT T1
			   join STATUS S1 on (S1.STATUSCODE=T1.STATUSCODE)
			   where T1.CASEID=T.CASEID
			   and   T1.[STATE]='I'
			   and   T1.NEWEVENTDATE is not null
			   and  (S1.RENEWALFLAG=0 or S1.RENEWALFLAG is null))
	and TX.CASEID is NULL"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@@ROWCOUNT
End

-- Update the RENEWALSTATUS of the Case with what would be the last EVENTNO with a Renewal Status to have been updated.
-- This is determined by the DISPLAYSEQUENCE on the theory that Events are logically supposed to be processed
-- in that order.

If @ErrorCode=0
Begin
	Set @sSQLString="
	update 	#TEMPCASES
	set	RENEWALSTATUS	=S.STATUSCODE,
		RENEWALEVENTNO	=T.EVENTNO,
		RENEWALCYCLE	=T.CYCLE,
		RENEWALACTION	=T.CREATEDBYACTION,
		OLDRENEWALSTATUS=C.RENEWALSTATUS
	from	#TEMPCASES C
	join	#TEMPCASEEVENT	T on (T.CASEID=C.CASEID
				  and T.[STATE]='I')
	join    STATUS S	  on (S.STATUSCODE=isnull(T.RENEWALSTATUS,T.STATUSCODE)
				  and S.RENEWALFLAG=1)
	left join (	select T2.CASEID, T2.NEWEVENTDATE
			from #TEMPCASEEVENT T2
			join ACTIONS A	on (A.ACTION        =T2.CREATEDBYACTION
					and A.ACTIONTYPEFLAG=1)
			join EVENTCONTROL EC	
					on (EC.CRITERIANO   =T2.CREATEDBYCRITERIA
					and EC.EVENTNO      =T2.EVENTNO)
			join STATUS S	on (S.STATUSCODE    =isnull(EC.RENEWALSTATUS,EC.STATUSCODE)
					and S.RENEWALFLAG   =1)
			where T2.EVENTNO not in (-16,-14,-13) ) TX
					on (TX.CASEID=T.CASEID
					and TX.NEWEVENTDATE>T.NEWEVENTDATE
					-- only need to check previous Status if Renewal Status is not null
					-- and if the Event triggering this has been manually entered
					and C.RENEWALSTATUS is not null
					and T.EVENTUPDATEDMANUALLY=1)
	where	convert(nchar(8),T.NEWEVENTDATE,112)+
		space(5-len(isnull(T.DISPLAYSEQUENCE,0)))+convert(nvarchar(5),isnull(T.DISPLAYSEQUENCE,0))+
		convert(nchar(9),T.EVENTNO)+
		convert(nchar(5),T.CYCLE)  +
		convert(nchar(9),S.STATUSCODE)
			= (select max(	isnull(
					convert(nchar(8),T1.NEWEVENTDATE,112)+
					space(5-len(isnull(T1.DISPLAYSEQUENCE,0)))+convert(nvarchar(5),isnull(T1.DISPLAYSEQUENCE,0))+
					convert(nchar(9),T1.EVENTNO)+
					convert(nchar(5),T1.CYCLE)  +
					convert(nchar(9),S1.STATUSCODE),'') )
			   from #TEMPCASEEVENT T1
			   join STATUS S1 on (S1.STATUSCODE=isnull(T1.RENEWALSTATUS,T1.STATUSCODE))
			   where T1.CASEID=T.CASEID
			   and   T1.[STATE]='I'
			   and   T1.NEWEVENTDATE is not null
			   and	 S1.RENEWALFLAG=1)
	and TX.CASEID is null"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount+@@Rowcount
End

-- Update the STATUSCODE of the #TEMPOPENACTION with what would be the last EVENTNO with a Status to have been
-- updated for that Action.

If @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	update 	#TEMPOPENACTION
	set	STATUSCODE=T.STATUSCODE,
		STATUSDESC=T.STATUSDESC
	from	#TEMPOPENACTION O
	join	#TEMPCASES C	  on (C.CASEID          =O.CASEID)
	join	#TEMPCASEEVENT	T on (T.CASEID		=O.CASEID
				  and T.CREATEDBYACTION	=O.ACTION)
	where	O.POLICEEVENTS=1
	and	T.[STATE]='I'
	and    (T.STATUSCODE in (C.STATUSCODE, C.RENEWALSTATUS) OR T.RENEWALSTATUS=C.RENEWALSTATUS)
	and	space(5-len(isnull(T.DISPLAYSEQUENCE,0)))+convert(nvarchar(5),isnull(T.DISPLAYSEQUENCE,0))+
		convert(nchar(9),T.EVENTNO)+
		convert(nchar(5),T.CYCLE)  +
		convert(nchar(9),T.STATUSCODE)
			= (select max(	isnull(
					space(5-len(isnull(T1.DISPLAYSEQUENCE,0)))+convert(nvarchar(5),isnull(T1.DISPLAYSEQUENCE,0))+
					convert(nchar(9),T1.EVENTNO)+
					convert(nchar(5),T1.CYCLE)  +
					convert(nchar(9),isnull(T1.STATUSCODE,T1.RENEWALSTATUS)),'') )
			   from #TEMPCASEEVENT T1
			   join ACTIONS A on (A.ACTION=T1.CREATEDBYACTION)
			   where T1.CASEID	   =T.CASEID
			   and   T1.CREATEDBYACTION=T.CREATEDBYACTION
			   and   T1.[STATE]        ='I'
			   and ((T1.CYCLE = O.CYCLE AND A.NUMCYCLESALLOWED>1) OR A.NUMCYCLESALLOWED=1)
			   and	(T1.STATUSCODE =T.STATUSCODE OR T1.RENEWALSTATUS=T.RENEWALSTATUS))"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- If the Status or Renewal Status has changed against the Case
-- then any Open Action rows that were previously not Policing
-- because of the status are to now be recalculated.
If @ErrorCode=0
and @nRowCount>0
Begin
	-- Get any OpenAction rows that were not previously 
	-- retrieved because the status did not require them
	-- to Police
	Exec @ErrorCode=ip_PoliceGetActions 
				@pnRowCount=@nRowCount	OUTPUT,
				@pnDebugFlag=@pnDebugFlag

	
	If @ErrorCode=0
	Begin	
		Set @sSQLString="
		Update T
		Set [STATE]='C'
		From #TEMPOPENACTION T
		join ACTIONS	 A  on (A.ACTION=T.ACTION)
		join #TEMPCASES  C  on (C.CASEID=T.CASEID)
		join      STATUS S1 on (S1.STATUSCODE=C.STATUSCODE)
		left join STATUS S2 on (S2.STATUSCODE=C.OLDSTATUSCODE)
		left join STATUS R1 on (R1.STATUSCODE=C.RENEWALSTATUS)
		left join STATUS R2 on (R2.STATUSCODE=C.OLDRENEWALSTATUS)
		where T.POLICEEVENTS=1
		and T.[STATE]<>'C'
		and (   (A.ACTIONTYPEFLAG=2 and S1.POLICEEXAM        =1 and S2.POLICEEXAM        =0)
		     or (A.ACTIONTYPEFLAG=0 and S1.POLICEOTHERACTIONS=1 and S2.POLICEOTHERACTIONS=0)
		     or (A.ACTIONTYPEFLAG=1 and R1.POLICERENEWALS    =1 and S1.POLICERENEWALS=1 and (R2.POLICERENEWALS=0 OR S2.POLICERENEWALS=0))
		     )"

		Exec @ErrorCode=sp_executesql @sSQLString
	End
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Update T
		Set OLDSTATUSCODE   =CASE WHEN(T.OLDSTATUSCODE   <>T.STATUSCODE    or (T.OLDSTATUSCODE    is null and T.STATUSCODE    is not null)) THEN T.STATUSCODE    ELSE T.OLDSTATUSCODE    END,
		    OLDRENEWALSTATUS=CASE WHEN(T.OLDRENEWALSTATUS<>T.RENEWALSTATUS or (T.OLDRENEWALSTATUS is null and T.RENEWALSTATUS is not null)) THEN T.RENEWALSTATUS ELSE T.OLDRENEWALSTATUS END
		from (	select distinct CASEID 
			from #TEMPOPENACTION 
			where [STATE]='C') OA
		join #TEMPCASES T on (T.CASEID=OA.CASEID)
		where (T.OLDSTATUSCODE   <>T.STATUSCODE    or (T.OLDSTATUSCODE    is null and T.STATUSCODE    is not null))
		or    (T.OLDRENEWALSTATUS<>T.RENEWALSTATUS or (T.OLDRENEWALSTATUS is null and T.RENEWALSTATUS is not null))"

		Exec @ErrorCode=sp_executesql @sSQLString
	End
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceUpdateCaseStatus',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select * from #TEMPCASES order by CASEID
		Select	T.[STATE], * from #TEMPOPENACTION T order by T.[STATE], CASEID, ACTION"

		Exec @ErrorCode=sp_executesql @sSQLString
	End
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceUpdateCaseStatus  to public
go
