-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceRemoveSatisfiedEvents
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceRemoveSatisfiedEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceRemoveSatisfiedEvents.'
	drop procedure dbo.ip_PoliceRemoveSatisfiedEvents
end
print '**** Creating procedure dbo.ip_PoliceRemoveSatisfiedEvents...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceRemoveSatisfiedEvents
				@pnCountStateC		int	OUTPUT,
				@pnCountStateI		int	OUTPUT,
				@pnCountStateR		int	OUTPUT,
				@pnCountStateR1		int	OUTPUT,
				@pnCountStateRX		int	OUTPUT,
				@pnCountStateD		int	OUTPUT,
			 	@pnDebugFlag		tinyint

as
-- PROCEDURE :	ip_PoliceRemoveSatisfiedEvents
-- VERSION :	22
-- DESCRIPTION:	Identify rows that have been satisfied by the existence of another Event and either
--              remove them or mark for deletion.

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 07/09/2001	MF			Procedure created
-- 15/10/2001	MF	7117		Events that have a manually entered due date are to have their OCCURREDFLAG
--					set to 9 if another Event satisfies it.
-- 14/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 06/12/2001	MF	7270		When recalculating an action, any event with a manually entered due date that 
--					is now satisfied by another event is not correctly being marked as satisfied.
--					Modify the program to also satisfy TEMPCASEEVENT rows where STATE='R' and
--					the due date has been manually saved.
-- 03/06/2002	MF	7708		An Event that was previously satisfied by another event is not being 
--					recalculated when the satisfying Event is cleared out by the occurrence of 
--					another Event.  This is because the satisfying Event is still showing on
--					on the CaseEvent table as having occurred even though it has now been cleared
--					on the TEMPCASEEVENT table.
-- 28 Jul 2003	MF		10	Standardise version number
-- 10 Mar 2005	MF	11126	11	When looking for Events that have been satisfied, consider all of the current
--					openactions against the case and not just the Action that originally 
--					created the CaseEvent.
-- 07 Jun 2006	MF	12417	12	Change order of columns returned in debug mode to make it easier to review
-- 31 May 2007	MF	14812	13	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	14	Reserve word [STATE]
-- 27 Oct 2011	MF	R11457	15	Extend to include satisfying of CaseEvents with STATE of R1 or RX.
-- 04 Nov 2011	MF	R11457	16	Revisit after failed testing. Can only satisfy and Event if it has not occurred.
-- 08 Nov 2011	MF	R11457	17	Revisit after failed testing. If there are multiple #TEMPCASEEVENT rows because the Event 
--					is referenced by more than one Action, then make sure all rows are updated. 
-- 06 Jun 2012	MF	S19025	18	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 19 Apr 2013	MF	R13416	19	Note this is just adding a Comment to explain why related event rules do not require 
--					the OPENACTION row to have POLICEEVENTS=1.
-- 13 Sep 2013	MF	R13755	19	Satisfying event rules currently consider all Actions for the case even if they are closed. This is correct however of the Action is cyclic
--					and there are open cycles available then the closed cycles will be ignored. This is because it is possible for the CRITERIANO to be different
--					for the open cycles compared to the older closed cycles.
-- 15 Mar 2017	MF	70049	20	Allow Renewal Status to be separately specified to be updated by an Event.
-- 14 Nov 2018  AV	DR-45358 21	Date conversion errors when creating cases and opening names in Chinese DB
-- 05 Nov 2019	MF	DR-53790 22	Correction to code incrementing @pnCountStateC variable.

set nocount on

DECLARE		@ErrorCode	int,
		@sSQLString	nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

-- Remove any rows to be calculated where the Event is satisfied by the existence of another event and the row did not 
-- already exist on the CASEEVENT table

If  @ErrorCode=0
and @pnCountStateC>0
Begin
	set @sSQLString="
	delete #TEMPCASEEVENT
	from #TEMPCASEEVENT T
	where T.[STATE]='C'
	and  T.OLDEVENTDUEDATE is null
	and  T.NEWEVENTDUEDATE is null
	and  T.OLDEVENTDATE    is null
	and  T.NEWEVENTDATE    is null
	and isnull(T.USEDINCALCULATION,'N')='N'
	---------------------------------------
	-- RFC 13416
	-- Note: The #TEMPOPENACTION row does 
	--       NOT require POLICEEVENTS=1.
	--       This is deliberate.
	---------------------------------------
	and exists
	(Select 1
	 from #TEMPOPENACTION OA
	 -- If the OpenAction row is closed then check to see if an open row exists
	 -- for the same Action with a different cycle
	 left join #TEMPOPENACTION OA1
				on (OA1.CASEID=OA.CASEID
				and OA1.ACTION=OA.ACTION
				and OA1.CYCLE<>OA.CYCLE
				and OA1.POLICEEVENTS=1
				and  OA.POLICEEVENTS=0)
	 join RELATEDEVENTS RE	on (RE.CRITERIANO=OA.NEWCRITERIANO
				and RE.EVENTNO=T.EVENTNO
				and RE.SATISFYEVENT=1)
	 join #TEMPCASEEVENT TC2	
				on (TC2.CASEID =T.CASEID 
				and TC2.EVENTNO=RE.RELATEDEVENT
				and TC2.CYCLE =	CASE RE.RELATIVECYCLE	WHEN (0) Then T.CYCLE
									WHEN (1) Then T.CYCLE-1
									WHEN (2) Then T.CYCLE+1
									WHEN (3) Then 1
										 Else (	select max(CYCLE) 
											from #TEMPCASEEVENT TC3
											where TC3.CASEID=T.CASEID
											and   TC3.EVENTNO=TC2.EVENTNO)
						END)
	 where OA.CASEID=T.CASEID
	 and  OA1.CASEID is null -- ignore closed actions if an open version exists for the same Action
	 and   TC2.[STATE] not like 'D%'
	 and   TC2.OCCURREDFLAG between 1 and 8 )"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @pnCountStateC=@pnCountStateC-@@Rowcount
end

-- Mark rows to  be deleted where the Event is satisfied by the existence of another event and the row actually
-- exists on the CASEEVENT table

If  @ErrorCode=0
and @pnCountStateC+@pnCountStateR>0
Begin
	set @sSQLString="
	update #TEMPCASEEVENT
	set 	@pnCountStateC  = @pnCountStateC - CASE WHEN(T.[STATE] LIKE 'C%') THEN 1 ELSE 0 END,
		@pnCountStateR  = @pnCountStateR - CASE WHEN(T.[STATE] =    'R' ) THEN 1 ELSE 0 END,
		@pnCountStateR1 = @pnCountStateR1- CASE WHEN(T.[STATE] =    'R1') THEN 1 ELSE 0 END,
		@pnCountStateRX = @pnCountStateRX- CASE WHEN(T.[STATE] =    'RX') THEN 1 ELSE 0 END,
		[STATE]='D',
		OCCURREDFLAG=	CASE WHEN(T.DATEDUESAVED=1) THEN 9 ELSE T.OCCURREDFLAG END
	from #TEMPCASEEVENT T
	where   T.[STATE] in ('X','C','C1','CX','R', 'R1','RX')
	and T.NEWEVENTDATE is null
	and isnull(T.OCCURREDFLAG,0)=0
	---------------------------------------
	-- RFC 13416
	-- Note: The #TEMPOPENACTION row does 
	--       NOT require POLICEEVENTS=1.
	--       This is deliberate.
	---------------------------------------
	and exists
	(Select 1
	 from #TEMPOPENACTION OA
	 -- If the OpenAction row is closed then check to see if an open row exists
	 -- for the same Action with a different cycle
	 left join #TEMPOPENACTION OA1
				on (OA1.CASEID=OA.CASEID
				and OA1.ACTION=OA.ACTION
				and OA1.CYCLE<>OA.CYCLE
				and OA1.POLICEEVENTS=1
				and  OA.POLICEEVENTS=0)
	 join RELATEDEVENTS RE	on (RE.CRITERIANO=OA.NEWCRITERIANO
				and RE.EVENTNO=T.EVENTNO
				and RE.SATISFYEVENT=1)
	 join #TEMPCASEEVENT TC2	
				on (TC2.CASEID =T.CASEID 
				and TC2.EVENTNO=RE.RELATEDEVENT
				and TC2.CYCLE =	CASE RE.RELATIVECYCLE	WHEN (0) Then T.CYCLE
									WHEN (1) Then T.CYCLE-1
									WHEN (2) Then T.CYCLE+1
									WHEN (3) Then 1
										 Else (	select max(CYCLE) 
											from #TEMPCASEEVENT TC3
											where TC3.CASEID=T.CASEID
											and   TC3.EVENTNO=TC2.EVENTNO)
						END)
	 where OA.CASEID=T.CASEID
	 and  OA1.CASEID is null -- ignore closed actions if an open version exists for the same Action
	 and   TC2.[STATE] not like 'D%'
	 and   TC2.OCCURREDFLAG between 1 and 8 )"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCountStateC	int		OUTPUT,
					  @pnCountStateR	int		OUTPUT,
					  @pnCountStateR1	int		OUTPUT,
					  @pnCountStateRX	int		OUTPUT',
					  @pnCountStateC=@pnCountStateC		OUTPUT,
					  @pnCountStateR=@pnCountStateR		OUTPUT,
					  @pnCountStateR1=@pnCountStateR1	OUTPUT,
					  @pnCountStateRX=@pnCountStateRX	OUTPUT
	Set @pnCountStateD=@pnCountStateD+@@Rowcount
end

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceRemoveSatisfiedEvents',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	begin
		set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*, @pnCountStateC as 'CountStateC', @pnCountStateI as 'CountStateI', @pnCountStateR as 'CountStateR', @pnCountStateD as 'CountStateD' , @pnCountStateR1 as 'CountStateR1', @pnCountStateRX as 'CountStateRX'
		from	#TEMPCASEEVENT T
		where	T.[STATE]<>'X'
		order by 4,1,2,3"

		Exec @ErrorCode = sp_executesql @sSQLString,
						N'@pnCountStateC	int,
						  @pnCountStateI	int,
						  @pnCountStateR	int,
						  @pnCountStateR1	int,
						  @pnCountStateRX	int,
						  @pnCountStateD	int',
						  @pnCountStateC,
						  @pnCountStateI,
						  @pnCountStateR,
						  @pnCountStateR1,
						  @pnCountStateRX,
						  @pnCountStateD
	end
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceRemoveSatisfiedEvents  to public
go
