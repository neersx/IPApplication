-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceOpenNewActions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceOpenNewActions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceOpenNewActions.'
	drop procedure dbo.ip_PoliceOpenNewActions
end
print '**** Creating procedure dbo.ip_PoliceOpenNewActions...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceOpenNewActions
			@pnDebugFlag	tinyint
as
-- PROCEDURE :	ip_PoliceOpenNewActions
-- VERSION :	19
-- DESCRIPTION:	A procedure to load the temporary table #TEMPOPENACTION with Actions that are being opened
--		as a result of an Event having occurred.  It is also possible for existing rows in the 
--		#TEMPOPENACTION table to be reopened.

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 25/09/2000	MF			Procedure created
-- 18/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 24/06/2002	MF	7765		Make certain that the USERID that triggered the policing request carrys
--					through to any other TEMPCASEEVENT rows.
-- 28 Jul 2003	MF	8673	10	Get the OFFICE associated with the Case so it can be used to determine the
--					best CriteriaNo for an Action.
-- 26 Feb 2004	MF	RFC709	11	Get IDENTITYID to identify the workbench user
-- 15 Mar 2005	MF	S11150	12	If the Action already exists in the OpenAction table then mark it for
--					recalculation.
-- 07 Jun 2006	MF	12417	13	Change order of columns returned in debug mode to make it easier to review
-- 31 May 2007	MF	14812	14	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	15	Reserve word [STATE]
-- 27 Mar 2014	MF	22024	16	An ACTION may only be opened for the Case if it is valid for the case's characteristics.
-- 11 Apr 2016	MF	R60302	17	When opening an action, carry the criteriano/eventno that is requesting the action to open.  
--					This can then be used in reporting an error if a criteriano cannot be found for the Action.
-- 17 Aug 2016	MF	65417	18	When multiple Events for a Case are attempting to open the Action we need to ensure only one
--					row is inserted into #TEMPOPENACTION by arbitrarily choosing the lowest EventNo.
-- 14 Nov 2018  AV  75198/DR-45358	19   Date conversion errors when creating cases and opening names in Chinese DB
--		

set nocount on

DECLARE		@ErrorCode	int,
		@sSQLString	nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

If @ErrorCode=0
Begin
	set @sSQLString="
	with CTE_ActionOpeningEvent(CASEID, ACTION, EVENTNO)
	     as(select CASEID, CREATEACTION, min(EVENTNO)
		from #TEMPCASEEVENT
		where [STATE]='I'
		and CREATEACTION is not null
		group by CASEID, CREATEACTION)
		
	update	#TEMPOPENACTION
	set	[STATE]='C',
		POLICEEVENTS=1,
		OPENINGCRITERIANO=TC.CRITERIANO,
		OPENINGEVENTNO   =TC.EVENTNO, 
		OPENINGCYCLE     =TC.CYCLE
	from	#TEMPOPENACTION T
	join	ACTIONS		A  on (A.ACTION		=T.ACTION)
	join	#TEMPCASEEVENT	TC on (TC.CASEID	=T.CASEID
				   and TC.CREATEACTION	=T.ACTION)
	join	  CTE_ActionOpeningEvent E
				   on (E.CASEID		=T.CASEID
				   and E.ACTION		=T.ACTION
				   and E.EVENTNO	=TC.EVENTNO)
	join	#TEMPCASES	C  on (C.CASEID		=T.CASEID)
	-- SQA22024
	join	VALIDACTION	VA on (VA.PROPERTYTYPE	=C.PROPERTYTYPE
				   and VA.CASETYPE	=C.CASETYPE
				   and VA.ACTION	=TC.CREATEACTION
				   and VA.COUNTRYCODE	=(select min(VA1.COUNTRYCODE)
							  from VALIDACTION VA1
							  where VA1.PROPERTYTYPE=C.PROPERTYTYPE
							  and   VA1.CASETYPE    =C.CASETYPE
							  and   VA1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
	left join STATUS	SC on (SC.STATUSCODE	=C.STATUSCODE)
	left join STATUS	SR on (SR.STATUSCODE	=C.RENEWALSTATUS)
	
	where	TC.[STATE]='I'
				-- The Cycle number depends on a number of factors:	
				-- a) If the ACTION is cyclic (NUMCYCLESALLOWED >1)	
				--    then increment the Cycle of the CASEEVENT if the	
				--    Action of the CASEEVENT is the same as the Action	
				--    being opend.					
				-- b) If the ACTION is cyclic but the Action of the	
				--    CASEEVENT is a different Action then open or	
				--    reopen the OPENACTION using the same Cycle as the	
				--    CASEEVENT row.					
				-- c) If the ACTION is non cyclic (NUMCYCLESALLOWED=1)	
				--    then only open the OPENACTION row if the CYCLE of 
				--    the CASEEVENT row is equal to 1			
	and	TC.CYCLE <= A.NUMCYCLESALLOWED
	
	and (  (A.NUMCYCLESALLOWED > 1 AND TC.CREATEDBYACTION =T.ACTION AND T.CYCLE=TC.CYCLE+1)
	     OR(A.NUMCYCLESALLOWED > 1 AND TC.CREATEDBYACTION<>T.ACTION AND T.CYCLE=TC.CYCLE)
	     OR(A.NUMCYCLESALLOWED = 1 AND T.CYCLE=1) )
										-- Only calculate the row if the
										-- appropriate Status allows	
										-- the Action to be policed	
	and    ((A.ACTIONTYPEFLAG  =0 and (SC.POLICEOTHERACTIONS=1 or SC.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =2 and (SC.POLICEEXAM        =1 or SC.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =1 and (SC.POLICERENEWALS    =1 or SC.STATUSCODE  is null) 
	                              and (SR.POLICERENEWALS    =1 or SR.STATUSCODE is null)))"

	Exec @ErrorCode=sp_executesql @sSQLString
End

	-- Load #TEMPOPENACTION with the details of the Cases and Actions to be recalculated. 

If @ErrorCode=0
Begin
	Set @sSQLString="
	with CTE_ActionOpeningEvent(CASEID, ACTION, EVENTNO)
	     as(select CASEID, CREATEACTION, min(EVENTNO)
		from #TEMPCASEEVENT
		where [STATE]='I'
		and CREATEACTION is not null
		group by CASEID, CREATEACTION)
		
	insert #TEMPOPENACTION (CASEID, ACTION, POLICEEVENTS, DATEENTERED, DATEUPDATED, CASETYPE, PROPERTYTYPE, COUNTRYCODE,
		CASECATEGORY, SUBTYPE, BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE, RENEWALTYPE, CASEOFFICEID,
		USERID, [STATE], CYCLE,IDENTITYID, OPENINGCRITERIANO, OPENINGEVENTNO, OPENINGCYCLE)
	select	distinct	
		TC.CASEID,
		TC.CREATEACTION,
		1,
		getdate(),
		getdate(),
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
		TC.USERID,
		'C',
					-- The Cycle number depends on a number of factors:	
					-- a) If the ACTION is cyclic (NUMCYCLESALLOWED >1)	
					--    then increment the Cycle of the CASEEVENT if the	
					--    Action of the CASEEVENT is the same as the Action	
					--    being opend.					

		CASE WHEN (A.NUMCYCLESALLOWED>1 AND TC.CREATEDBYACTION =TC.CREATEACTION) THEN TC.CYCLE +1
					-- b) If the ACTION is cyclic but the Action of the	
					--    CASEEVENT is a different Action then open or	
					--    reopen the OPENACTION using the same Cycle as the	
					--    CASEEVENT row.					
		     WHEN (A.NUMCYCLESALLOWED>1 AND TC.CREATEDBYACTION<>TC.CREATEACTION) THEN TC.CYCLE
					-- c) If the ACTION is non cyclic (NUMCYCLESALLOWED=1)	
					--    then open Cycle 1 of the OPENACTION		
		     ELSE 1
		END, 
		TC.IDENTITYID,
		TC.CRITERIANO,
		TC.EVENTNO,
		TC.CYCLE
	from	  #TEMPCASEEVENT TC
	join	  CTE_ActionOpeningEvent E
				on (E.CASEID =TC.CASEID
				and E.ACTION =TC.CREATEACTION
				and E.EVENTNO=TC.EVENTNO)
	join	  ACTIONS A	on (A.ACTION=TC.CREATEACTION)
	join	  CASES	C	on (C.CASEID=TC.CASEID)
	left join PROPERTY P	on (P.CASEID=TC.CASEID)
	-- SQA22024
	join	VALIDACTION	VA on (VA.PROPERTYTYPE	=C.PROPERTYTYPE
				   and VA.CASETYPE	=C.CASETYPE
				   and VA.ACTION	=TC.CREATEACTION
				   and VA.COUNTRYCODE	=(select min(VA1.COUNTRYCODE)
							  from VALIDACTION VA1
							  where VA1.PROPERTYTYPE=C.PROPERTYTYPE
							  and   VA1.CASETYPE    =C.CASETYPE
							  and   VA1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
	join	  #TEMPCASES C1 on (C1.CASEID	 =C.CASEID)
	left join STATUS SC	on (SC.STATUSCODE=C1.STATUSCODE)
	left join STATUS SR	on (SR.STATUSCODE=C1.RENEWALSTATUS)
	left join #TEMPOPENACTION T
				on (T.CASEID=TC.CASEID
				and T.ACTION=TC.CREATEACTION
				and T.CYCLE =	CASE	WHEN (A.NUMCYCLESALLOWED>1 AND TC.CREATEDBYACTION =TC.CREATEACTION) THEN TC.CYCLE +1
							WHEN (A.NUMCYCLESALLOWED>1 AND TC.CREATEDBYACTION<>TC.CREATEACTION) THEN TC.CYCLE
															    ELSE 1
			  			END)
	where	TC.[STATE]='I'
	and	T.CASEID is null -- the row to be inserted must not exist
	and (  (A.NUMCYCLESALLOWED > 1 AND TC.CREATEDBYACTION =TC.CREATEACTION AND TC.CYCLE <A.NUMCYCLESALLOWED)
	     OR(A.NUMCYCLESALLOWED > 1 AND TC.CREATEDBYACTION<>TC.CREATEACTION AND TC.CYCLE<=A.NUMCYCLESALLOWED)
	     OR(A.NUMCYCLESALLOWED = 1 AND TC.CYCLE=1) )
										-- Only calculate the row if the
										-- appropriate Status allows	
										-- the Action to be policed	
	and    ((A.ACTIONTYPEFLAG  =0 and (SC.POLICEOTHERACTIONS=1 or SC.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =2 and (SC.POLICEEXAM        =1 or SC.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =1 and (SC.POLICERENEWALS    =1 or SC.STATUSCODE  is null) 
        	                      and (SR.POLICERENEWALS    =1 or SR.STATUSCODE is null)))"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceOpenNewActions',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	T.[STATE], * from #TEMPOPENACTION T
		order by T.[STATE], [CASEID], [ACTION]"
	
		Exec @ErrorCode=sp_executesql @sSQLString
	End

End

return @ErrorCode
go

grant execute on dbo.ip_PoliceOpenNewActions  to public
go
