-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceCloseActions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceCloseActions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceCloseActions.'
	drop procedure dbo.ip_PoliceCloseActions
end
print '**** Creating procedure dbo.ip_PoliceCloseActions...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceCloseActions
			@pnDebugFlag		tinyint
as
-- PROCEDURE :	ip_PoliceCloseActions
-- VERSION :	17
-- DESCRIPTION:	A procedure to identify all Actions that are to be closed.

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 29/05/2001	MF			Procedure created
-- 16/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 07/02/2003	MF	8412		Action doesn't close if the Status of the Case is such that the Action will 
--					be ignored in Policing.
-- 19/02/2003	MF	8438		Revisit of 8412.  If multiple Events are trying to close the same Action/Cycle
--					the procedure was giving a SQL Error on the insert into #TEMPOPENACTION
-- 28 Jul 2003	MF	8673	10	Get the OFFICE associated with the Case so it can be used to determine the
--					best CriteriaNo for an Action.
-- 08 Mar 2005	MF	11122	11	The #TEMPOPENACTION row inserted should be updated with the USERID and IDENTITYID
-- 07 Jun 2006	MF	12417	12	Change order of columns returned in debug mode to make it easier to review
-- 31 May 2007	MF	14812	13	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	14	Reserve word [STATE]
-- 11 Apr 2016	MF	R60302	15	When closing an action, carry the criteriano/eventno that is requesting the action to close.  
--					This information will eventually be carried into the OPENACTION table (in a different RFC)
--					to provide more audit information.
-- 04 May 2016	MF	R61219	16	Correction to merge error from RFC 60302.
-- 14 Nov 2018  AV  75198/DR-45358	17   Date conversion errors when creating cases and opening names in Chinese DB
--		

set nocount on

DECLARE		@ErrorCode	int,
		@sSQLString	nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

-- Close the required OPENACTION rows.  Note that we know that all of the OPENACTION rows for a case
-- have been loaded into the #TEMPOPENACTION table at the commencement of processing.

if @ErrorCode=0
Begin
	Set @sSQLString="
	Update	T
	set	POLICEEVENTS=0,
		[STATE]='C1',
		CLOSINGCRITERIANO=TC.CRITERIANO,
		CLOSINGEVENTNO   =TC.EVENTNO, 
		CLOSINGCYCLE     =TC.CYCLE
	from	#TEMPCASEEVENT  TC
	join	#TEMPOPENACTION T on (T.CASEID=TC.CASEID
				  and T.ACTION=TC.CLOSEACTION
				  and T.POLICEEVENTS=1)
	
	where	TC.[STATE]	= 'I'
	
	and   ((TC.RELATIVECYCLE<=5
	   and	T.CYCLE		=CASE TC.RELATIVECYCLE	WHEN (0) THEN TC.CYCLE
							WHEN (1) THEN TC.CYCLE-1
							WHEN (2) THEN TC.CYCLE+1
							WHEN (3) THEN 1
							WHEN (4) THEN (	select max(CYCLE)
									from	#TEMPOPENACTION T1
									where	T1.CASEID=T.CASEID
									and 	T1.ACTION=T.ACTION)
							WHEN (5) THEN T.CYCLE	-- all cycles 
				 END)

	   or  (TC.RELATIVECYCLE=6
	   and	T.CYCLE 	<TC.CYCLE)

	   or  (TC.RELATIVECYCLE=7
	   and	T.CYCLE		>TC.CYCLE))"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- We need to load the OPENACTION rows that are to be closed that were not previously loaded into
-- the TEMPOPENACTION table because the status/renewal status against the Case indicated that it
-- was not required to be police.

if @ErrorCode=0
Begin	
	set @sSQLString="
	insert #TEMPOPENACTION 
		(CASEID, ACTION, CYCLE, LASTEVENT, CRITERIANO, DATEFORACT, NEXTDUEDATE, POLICEEVENTS,
		 STATUSCODE, STATUSDESC, DATEENTERED, DATEUPDATED, CASETYPE, PROPERTYTYPE, COUNTRYCODE,
		 CASECATEGORY, SUBTYPE, BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE, RENEWALTYPE,
		 CASEOFFICEID,NEWCRITERIANO, [STATE],USERID,IDENTITYID, CLOSINGCRITERIANO, CLOSINGEVENTNO, CLOSINGCYCLE)
	select	distinct
		OA.CASEID,
		OA.ACTION,
		OA.CYCLE,
		OA.LASTEVENT,
		OA.CRITERIANO,
		OA.DATEFORACT,
		OA.NEXTDUEDATE,
		0, -- Closes the Action
		OA.STATUSCODE,
		OA.STATUSDESC,
		OA.DATEENTERED,
		OA.DATEUPDATED,
		C.CASETYPE,
		C.PROPERTYTYPE,
		C.COUNTRYCODE,
		C.CASECATEGORY,
		C.SUBTYPE,
		P.BASIS,
		P.REGISTEREDUSERS,
		C.LOCALCLIENTFLAG,
		P.EXAMTYPE,
		P.RENEWALTYPE,
		C.OFFICEID,
		OA.CRITERIANO,
		'C1',
		TC.USERID,
		TC.IDENTITYID,
		TC.CRITERIANO, 
		TC.EVENTNO,
		TC.CYCLE
	from	#TEMPCASEEVENT  TC
	     join OPENACTION OA		on (OA.CASEID=TC.CASEID
					and OA.ACTION=TC.CLOSEACTION
					and OA.POLICEEVENTS=1)
	     join CASES C		on (C.CASEID=TC.CASEID)
	left join PROPERTY P		on (P.CASEID=TC.CASEID)
	left join #TEMPOPENACTION TOA	on (TOA.CASEID=OA.CASEID
					and TOA.ACTION=OA.ACTION)
	where	TC.[STATE]	= 'I'
	and	TOA.CASEID is NULL -- don't bother continuing if TEMPOPENACTION exists
	and   ((TC.RELATIVECYCLE<=5
	   and	OA.CYCLE	=CASE TC.RELATIVECYCLE	WHEN (0) THEN TC.CYCLE
							WHEN (1) THEN TC.CYCLE-1
							WHEN (2) THEN TC.CYCLE+1
							WHEN (3) THEN 1
							WHEN (4) THEN (	select max(CYCLE)
									from	OPENACTION OA1
									where	OA1.CASEID=OA.CASEID
									and 	OA1.ACTION=OA.ACTION)
							WHEN (5) THEN OA.CYCLE	-- all cycles 
				 END)

	   or  (TC.RELATIVECYCLE=6
	   and	OA.CYCLE 	<TC.CYCLE)

	   or  (TC.RELATIVECYCLE=7
	   and	OA.CYCLE	>TC.CYCLE))"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceCloseActions',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	T.[STATE], * from #TEMPOPENACTION T
		order by T.[STATE], T.CASEID, T.ACTION"

		Exec @ErrorCode=sp_executesql @sSQLString
	End
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceCloseActions  to public
go
