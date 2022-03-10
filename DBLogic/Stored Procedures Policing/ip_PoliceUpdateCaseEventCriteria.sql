-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceUpdateCaseEventCriteria
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceUpdateCaseEventCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceUpdateCaseEventCriteria.'
	drop procedure dbo.ip_PoliceUpdateCaseEventCriteria
end
print '**** Creating procedure dbo.ip_PoliceUpdateCaseEventCriteria...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceUpdateCaseEventCriteria
			@pnDebugFlag	Tinyint
as
-- PROCEDURE :	ip_PoliceUpdateCaseEventCriteria
-- VERSION :	24
-- DESCRIPTION:	This procedure resets the CREATEDBYCRITERIA column of CASEEVENTS to reflect  
--		the recalculation of the CRITERIANO.
-- CALLED BY :	ipu_Policing

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	========
-- 20/09/2000	MF			Procedure created
-- 15/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles 
-- 28 Jul 2003	MF		10	Standardise version number
-- 25 Sep 2006	MF	13490	11	Update CreatedByCriteria even if the OpenAction CriteriaNo is null
-- 31 May 2007	MF	14812	12	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	13	Reserve word [STATE]
-- 29 Oct 2007	MF	15348	14	Ensure CREATEDBYACTION is updated along with CREATEDBYCRITERIA
-- 07 Apr 2008	MF	14208	15	Revisit of 14812 to only update the #TEMPCASEEVENT rows.
-- 16 Apr 2008	MF	16249	16	Revisit 14812 to better handle Events under multiple Actions.
-- 15 Jul 2008	MF	16709	17	Only set the CREATEDBYCRITERIA if the existing CriteriaNo is null or
--					the Criteria has due date calculation rules.
-- 21 Oct 2011	MF	11457	18	It is possible that the CREATEDBYACTION may also have changed so this needs to be updated.
-- 18 Jan 2012	MF	11808	19	If there are no due date calculation rules for the new Criteria and no due date calculation rules
--					exist for any other Action for the Case then set the CREATEDBYACTION and CREATEDBYCRITERIA to the
--					Action that references the EventNo.
-- 20 Feb 2012	MF	S21236	20	An Event that has actually occurred under one Criteria is having its Criteria changed as a result of RFC11808.
-- 06 Jun 2012	MF	S19025	21	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 06 Jun 2013	MF	S21404	22	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 15 Mar 2017	MF	70049	23	Allow Renewal Status to be separately specified to be updated by an Event.
-- 14 Nov 2018  AV  75198/DR-45358	24   Date conversion errors when creating cases and opening names in Chinese DB
--		

set nocount on

DECLARE		@ErrorCode	int,
		@sSQLString	nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

-- Now that the CRITERIA of the OPENACTION rows have been recalculated, the procedure will update the 
-- CREATEDBYCRITERIA column of the #TEMPCASEEVENT rows where the CREATEDBYCRITERIA no longer exists as an 
-- OPENACTION against the Case.
-- This is important for the following reasons :
-- 1. When an Event is cleared out the CREATEDBYCRITERIA is used to recalculate Event.
-- 2. A recalculation may be done in order to allow a Criteria to be deleted so it is important
--    to break the referential link.
--

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update CE
	set  CREATEDBYCRITERIA=T.NEWCRITERIANO,
	     CREATEDBYACTION=T.ACTION,
	     ------------------------------------------------------------------------------------
	     -- RFC11808
	     -- If the Event has not occurred and the due date has not been manually entered,
	     -- and no due date calculation rule exists for any of the OpenActions that reference
	     -- the Event then mark the row to be deleted.
	     ------------------------------------------------------------------------------------
	     [STATE]=CASE WHEN (isnull(CE.DATEDUESAVED,0)=0  and isnull(CE.OCCURREDFLAG,0)=0 and DD.CRITERIANO is null) 
			  THEN 'D1'
			  ELSE CE.[STATE]
		     END,
	     NEWEVENTDUEDATE
	            =CASE WHEN (isnull(CE.DATEDUESAVED,0)=0  and isnull(CE.OCCURREDFLAG,0)=0 and DD.CRITERIANO is null) 
			  THEN NULL
			  ELSE CE.NEWEVENTDUEDATE
		     END,
	DISPLAYSEQUENCE	=CASE WHEN(EC1.CRITERIANO is null) THEN E.DISPLAYSEQUENCE  ELSE CE.DISPLAYSEQUENCE  END,
	IMPORTANCELEVEL	=CASE WHEN(EC1.CRITERIANO is null) THEN E.IMPORTANCELEVEL  ELSE CE.IMPORTANCELEVEL  END,
	WHICHDUEDATE	=CASE WHEN( DD.CRITERIANO is null) THEN E.WHICHDUEDATE     ELSE CE.WHICHDUEDATE     END,
	COMPAREBOOLEAN	=CASE WHEN( DD.CRITERIANO is null) THEN E.COMPAREBOOLEAN   ELSE CE.COMPAREBOOLEAN   END,
	CHECKCOUNTRYFLAG=CASE WHEN( DD.CRITERIANO is null) THEN E.CHECKCOUNTRYFLAG ELSE CE.CHECKCOUNTRYFLAG END,
	SAVEDUEDATE	=CASE WHEN( DD.CRITERIANO is null) THEN E.SAVEDUEDATE      ELSE CE.SAVEDUEDATE      END,
	STATUSCODE	=CASE WHEN(EC1.CRITERIANO is null) THEN E.STATUSCODE       ELSE CE.STATUSCODE       END,
	RENEWALSTATUS	=CASE WHEN(EC1.CRITERIANO is null) THEN E.RENEWALSTATUS	   ELSE CE.RENEWALSTATUS    END,
	SPECIALFUNCTION	=CASE WHEN(EC1.CRITERIANO is null) THEN E.SPECIALFUNCTION  ELSE CE.SPECIALFUNCTION  END,
	INITIALFEE	=CASE WHEN(EC1.CRITERIANO is null) THEN E.INITIALFEE       ELSE CE.INITIALFEE       END,
	PAYFEECODE	=CASE WHEN(EC1.CRITERIANO is null) THEN E.PAYFEECODE       ELSE CE.PAYFEECODE       END,
	CREATEACTION	=CASE WHEN(EC1.CRITERIANO is null) THEN E.CREATEACTION     ELSE CE.CREATEACTION     END,
	STATUSDESC	=CASE WHEN(EC1.CRITERIANO is null) THEN E.STATUSDESC       ELSE CE.STATUSDESC       END,
	CLOSEACTION	=CASE WHEN(EC1.CRITERIANO is null) THEN E.CLOSEACTION      ELSE CE.CLOSEACTION      END,
	RELATIVECYCLE	=CASE WHEN(EC1.CRITERIANO is null) THEN E.RELATIVECYCLE    ELSE CE.RELATIVECYCLE    END,
	INSTRUCTIONTYPE	=CASE WHEN( DD.CRITERIANO is null) THEN E.INSTRUCTIONTYPE  ELSE CE.INSTRUCTIONTYPE  END,
	FLAGNUMBER	=CASE WHEN( DD.CRITERIANO is null) THEN E.FLAGNUMBER       ELSE CE.FLAGNUMBER       END,
	SETTHIRDPARTYON	=CASE WHEN(EC1.CRITERIANO is null) THEN E.SETTHIRDPARTYON  ELSE CE.SETTHIRDPARTYON  END,
	ESTIMATEFLAG	=CASE WHEN(EC1.CRITERIANO is null) THEN E.ESTIMATEFLAG     ELSE CE.ESTIMATEFLAG     END,
	EXTENDPERIOD	=CASE WHEN(EC1.CRITERIANO is null) THEN E.EXTENDPERIOD     ELSE CE.EXTENDPERIOD     END,
	EXTENDPERIODTYPE=CASE WHEN(EC1.CRITERIANO is null) THEN E.EXTENDPERIODTYPE ELSE CE.EXTENDPERIODTYPE END,
	INITIALFEE2	=CASE WHEN(EC1.CRITERIANO is null) THEN E.INITIALFEE2      ELSE CE.INITIALFEE2      END,
	PAYFEECODE2	=CASE WHEN(EC1.CRITERIANO is null) THEN E.PAYFEECODE2      ELSE CE.PAYFEECODE2      END,
	ESTIMATEFLAG2	=CASE WHEN(EC1.CRITERIANO is null) THEN E.ESTIMATEFLAG2    ELSE CE.ESTIMATEFLAG2    END,
	PTADELAY	=CASE WHEN(EC1.CRITERIANO is null) THEN E.PTADELAY         ELSE CE.PTADELAY         END,
	SETTHIRDPARTYOFF=CASE WHEN(EC1.CRITERIANO is null) THEN E.SETTHIRDPARTYOFF ELSE CE.SETTHIRDPARTYOFF END,
	CHANGENAMETYPE	=CASE WHEN(EC1.CRITERIANO is null) THEN E.CHANGENAMETYPE   ELSE CE.CHANGENAMETYPE   END,
	COPYFROMNAMETYPE=CASE WHEN(EC1.CRITERIANO is null) THEN E.COPYFROMNAMETYPE ELSE CE.COPYFROMNAMETYPE END,
	COPYTONAMETYPE	=CASE WHEN(EC1.CRITERIANO is null) THEN E.COPYTONAMETYPE   ELSE CE.COPYTONAMETYPE   END,
	DELCOPYFROMNAME	=CASE WHEN(EC1.CRITERIANO is null) THEN E.DELCOPYFROMNAME  ELSE CE.DELCOPYFROMNAME  END,
	DIRECTPAYFLAG	=CASE WHEN(EC1.CRITERIANO is null) THEN E.DIRECTPAYFLAG    ELSE CE.DIRECTPAYFLAG    END,
	DIRECTPAYFLAG2	=CASE WHEN(EC1.CRITERIANO is null) THEN E.DIRECTPAYFLAG2   ELSE CE.DIRECTPAYFLAG2   END,
	RECALCEVENTDATE =E.RECALCEVENTDATE,
	SUPPRESSCALCULATION=E.SUPPRESSCALCULATION,
	LIVEFLAG=1
	from #TEMPCASEEVENT CE
	---------------------------------------------------------
	-- OpenActions where the Event is referenced and should
	-- be used as the CREATEDBYCRITERIA for CaseEvent
	---------------------------------------------------------
	join #TEMPOPENACTION T on (T.CASEID=CE.CASEID)
	join EVENTCONTROL E    on (E.CRITERIANO=T.NEWCRITERIANO
			       and E.EVENTNO   =CE.EVENTNO)
	---------------------------------------------------------
	-- Due Date rule for Event exists against the OpenAction
	---------------------------------------------------------			       
	left join (select distinct CRITERIANO, EVENTNO
		   from DUEDATECALC
		   where OPERATOR is not null) DD
				on (DD.CRITERIANO=T.NEWCRITERIANO
				and DD.EVENTNO=CE.EVENTNO)
	---------------------------------------------------------
	-- OpenAction currently referenced by CaseEvent but only
	-- returned when it is different to the above OpenAction
	---------------------------------------------------------
	left join #TEMPOPENACTION OA on(OA.CASEID=CE.CASEID
				     and OA.ACTION<>T.ACTION
				     and OA.NEWCRITERIANO=CE.CREATEDBYCRITERIA)
	---------------------------------------------------------
	-- Due Date rule for Event that is associated with the 
	-- existing CaseEvent
	---------------------------------------------------------
	left join (select distinct CRITERIANO, EVENTNO
		   from DUEDATECALC
		   where OPERATOR is not null) DD1
				on (DD1.CRITERIANO=CE.CREATEDBYCRITERIA
				and DD1.EVENTNO=CE.EVENTNO)
	---------------------------------------------------------
	-- EventControl currently pointed to by CaseEvent
	-- existing CaseEvent
	---------------------------------------------------------
	left join EVENTCONTROL EC1
				on (EC1.CRITERIANO=CE.CRITERIANO	-- NOTE: This is deliberately using CE.CRITERIANO and not CE.CREATEDBYCRITERIA
				and EC1.EVENTNO=CE.EVENTNO)
	---------------------------------------------------------
	-- Due Date rule for Event against an OpenAction that is
	-- different to the OpenAction previously found. This is 
	-- to check for any other due date rules
	---------------------------------------------------------
	left join (select distinct OA2.CASEID, DD2.CRITERIANO, DD2.EVENTNO
		   from #TEMPOPENACTION OA2
		   join DUEDATECALC DD2 on (DD2.CRITERIANO=OA2.NEWCRITERIANO)
                   where OPERATOR is not null) DD2 on (DD2.CASEID=CE.CASEID
						   and DD2.CRITERIANO<>T.NEWCRITERIANO
						   and DD2.EVENTNO=CE.EVENTNO)
	---------------------------------------------------------------------------
	-- OpenAction criteria has changed or been calculated
	---------------------------------------------------------------------------
	where (T.CRITERIANO<>T.NEWCRITERIANO or T.CRITERIANO is null)
	---------------------------------------------------------------------------
	-- OpenAction criteria is different to what is on CaseEvent
	---------------------------------------------------------------------------
	and (CE.CREATEDBYCRITERIA<>T.NEWCRITERIANO or CE.CREATEDBYCRITERIA is null)
	---------------------------------------------------------------------------
	-- Due Date rule for OpenAction exists or there are no Due Date rules
	---------------------------------------------------------------------------
	and (DD.CRITERIANO is not null OR DD2.CRITERIANO is null)
	---------------------------------------------------------------------------
	-- Only do the update if there is no OPENACTION with due date calculations 
	-- for the Case pointing to the CriteriaNo currently against the CaseEvent
	-- and there are Due Date rules against another OpenAction or the CaseEvent
	-- has not occurred.
	---------------------------------------------------------------------------
	and (DD1.EVENTNO is null and (DD.EVENTNO is not null OR (CE.OCCURREDFLAG=0 and ISNULL(CE.DATEDUESAVED,0)=0)))"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceUpdateCaseEventCriteria',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*
		from	#TEMPCASEEVENT T
		where T.[STATE]<>'X'
		order by 4,1,2,3"

		Exec @ErrorCode = sp_executesql @sSQLString
	End
End

return @ErrorCode
go

grant execute on ip_PoliceUpdateCaseEventCriteria  to public
go
