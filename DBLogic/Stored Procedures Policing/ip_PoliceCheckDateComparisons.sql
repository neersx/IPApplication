-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceCheckDateComparisons
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceCheckDateComparisons]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceCheckDateComparisons.'
	drop procedure dbo.ip_PoliceCheckDateComparisons
end
print '**** Creating procedure dbo.ip_PoliceCheckDateComparisons...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure [dbo].[ip_PoliceCheckDateComparisons]
			@pnDebugFlag	tinyint
as
-- PROCEDURE :	ip_PoliceCheckDateComparisons
-- VERSION :	35
-- DESCRIPTION:	A procedure that looks at the calculated due dates and then determines if the required number of
--		date comparisons are true to allow the calculated due date to be kept.  Note that this is performed
--		after the date calculation because the calculated due date may be included in the date comparison.
-- CALLED BY :	ipu_PoliceCalculateDueDate


-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 13/07/2000	MF			Procedure created
-- 14/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 23/11/2001	MF	7227		SQLServer is sometime giving an internal error.  To resolve create an 
--					intermediate step to identify the TEMPCASEEVENT rows that fail the 
--					date comparison before updating TEMPCASEEVENT.
-- 09/04/2002	MF	7563		During a recalculation of a due date any manually entered due dates should 
--					be excluded from the date comparison phase.
-- 09/04/2003	MF	8550		If the date that is being compared is supposed to be a Due Date then check 
--					that it has not Occurred
-- 28 Jul 2003	MF		10	Standardise version number
-- 06 Oct 2004	MF	10563	11	Comparisons should always consider the currently calculated Events if a row
--					exists in the #TEMPCASEEVENT table in preference to the CASEEVENT row.
-- 27 Jan 2005	MF	10931	12	Allow date comparison tests to also consider Cases from a related Case.
-- 03 Jun 2005	MF	7128	13	Two new comparison operators have been provided for EX - Exists and NE - Not 
--					Exists.
-- 13 Jan 2006	MF	11896	14	An alternative to comparing against another Case Event date is to allow the
--					comparison against a manually entered date or the current system date.
-- 07 Jun 2006	MF	12417	15	Change order of columns returned in debug mode to make it easier to review
-- 11 Sep 2006	MF	13422	16	When considering Events in the comparison rules, make certain that any event
--					that is in the process of being calculated is NOT considered as we need to
--					wait until the calculation is complete before it can be considered.
-- 16 May 2007	MF	13422	17	Revisit. If the event being calculated matched the event in the comparison then
--					previously we allowed the comparison only if the Due date was used in the 
--					comparison. Change so if the rule is for Event/Due this will also be considered
--					even though in reality the date will only be a due date at this stage.
-- 24 May 2007	MF	14812	18	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	19	Reserve word [STATE]
-- 16 Apr 2008	MF	16249	20	Revisit 14812 to better handle Events under multiple Actions.
-- 17 Sep 2008	MF	16819	21	Allow calculated CaseEvent rows with a STATE of 'RX' to be considered in
--					the comparison.
-- 18 Feb 2009	MF	17345	22	Policing not calculating a due date when multiple 'not exists' present in 
--					Date comparsion tab of eventcontrol. This occurs when one of the Events that
--					is not allowed to exist is in fact in the process of being calculated.
-- 18 May 2009	MF	17696	23	If the date comparison uses the Highest Cycle then the cycle to use should consider 
--					the restrictions introduced by SQA13422.
-- 22 May 2009	MF	17703	24	If the date comparison rule is checking that an Event does not exist then a previously
--					calculated Event that is now flagged to be deleted should satisfy this condition. These
--					were previously being ignored.
-- 17 Jun 2009 MF	17801	25	Due Date is calculating when comparison rule should be failing. This is because comparison
--					is considering an Event still being calculated which later fails its own calculation.
-- 21 May 2010	MF	18765	26	Further revisit of SQA13422. If the comparison rule is NOT EXISTS and the event being checked
--					is in the process of being calculated then the comparison must be treated as if it failed 
--					because we do not know if the Event will successfully calculate or not.  If it does not calculate
--					then it will need to trigger the recalculation of the Event whose comparison just failed.
-- 17 Jun 2010 MF	18817	27	Event not calculating because it is incorrectly failing a Not Exists date comparison rule because
--					the NEWEVENTDUEDATE existed even thought the State of the row was marked to Delete.
-- 28 Oct 2010	MF	19124	28	Not Exists where the Event being considered was a Due Date was not working because the Event was now an
--					EventDate but the due date was still in the row.  If the Event Date exists then this is the same as the
--					due date not existing.
-- 01 Jul 2011	MF	10929	29	Keep track of when the CASES and PROPERTY rows were last updated so that we can check that no changes
--					have been applied to the database when Policing attempts to update these.
-- 18 Oct 2011	MF	18798	30	Use OPTION(MAXDOP 1) to manually set the Maximum Degrees of Parallelism to a single processor. This will allow
--					the database to be set to use parallelism but those complex problem queries with this option will then
--					revert to no parallelism in order to get enhanced performance.
-- 03 Feb 2012	MF	20338	30	When comparing #TEMPCASEEVENT rows consideration is already being given in case multiple rows exist for the Event and Cycle
--					because it is referenced by more than one Action.  This has to be extended to ensure that the same STATE value is used when
--					trying to get the row with the lowest UniqueId.
-- 05 Jun 2012	MF	S19025	31	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 06 Aug 2012	MF	R12597	31	When the NOT EXISTS is being used then an OCCURREDFLAG=9 is to be treated in the same ways as if the CASEEVENT was deleted.
-- 13 Aug 2012	MF	R12624	32	This change is are reversal to SQA20338.  The problem with 20338 was that the date comparison could return multiple rows
--					from the exact same CASEID, EVENTNO, CYCLE combination where the Event exists for multiple Actions and the rows have a different
--					State value. By returning multiple rows a comparison that may have failed on a different test could now cancel out that failure 
--					and return a false positive. The issue that SQA20338 was originally correcting, I believe is now corrected in another method because
--					when an Event occurs for a CaseEvent, all rows for that same CASEID, EVENTNO, CYCLE are being updated with the same values.
-- 15 Mar 2017	MF	70049	33	Allow Renewal Status to be separately specified to be updated by an Event.
-- 06 Jun 2017	MF	71680	34	An Event that belongs to more than Action can cause problems in the Date Comparison if the COMPAREBOOLEAN value is incorrectly set. Should
--					only consider the action that has created the CaseEvent (CREATEDBYACTION).
-- 14 Nov 2018  AV  75198/DR-45358	35   Date conversion errors when creating cases and opening names in Chinese DB
--		

set nocount on

-- Create a intermediate table to store the number of valid comparison tests

CREATE TABLE #TEMPCOMPARECOUNT (
		CASEID			int		NOT NULL,
		EVENTNO			int		NOT NULL,
		CYCLE			smallint	NOT NULL,
		CREATEDBYCRITERIA	int		NULL,
		COMPARECOUNT		smallint	NULL
		)	

CREATE CLUSTERED INDEX XPKTEMPCOMPARECOUNT ON #TEMPCOMPARECOUNT
 	(
        	CASEID,
		EVENTNO,
		CYCLE,
		COMPARECOUNT
 	)

-- Create a intermediate table of those rows that fail the date comparison.

CREATE TABLE #TEMPCOMPARE (
		CASEID		int		NOT NULL,
		EVENTNO		int		NOT NULL,
		CYCLE		smallint	NOT NULL
		)

CREATE CLUSTERED INDEX XPKTEMPCOMPARE ON #TEMPCOMPARE
 	(
        	CASEID,
		EVENTNO,
		CYCLE
 	)


DECLARE		@ErrorCode	int,
		@nRowCount	int,
		@sSQLString	nvarchar(4000),
		@sSQLString0	nvarchar(4000),
		@sSQLString1	nvarchar(4000),
		@sSQLString2	nvarchar(4000),
		@sSQLString3	nvarchar(4000),
		@sSQLString4	nvarchar(4000),
		@sSQLString5	nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0
Set @nRowCount = 0

-- If comparison rule makes reference to a related case then load the
-- related Case and associated CaseEvents into the temporary table
If @ErrorCode =0
Begin
	Set @sSQLString="
	insert #TEMPCASES (CASEID, STATUSCODE, RENEWALSTATUS, REPORTTOTHIRDPARTY, PREDECESSORID, ACTION,  
			   EVENTNO, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
			   BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE,RENEWALTYPE, INSTRUCTIONSLOADED,IPODELAY,
			   APPLICANTDELAY,USERID,IDENTITYID,OFFICEID,CASELOGSTAMP,PROPERTYLOGSTAMP)

	select	distinct C.CASEID, C.STATUSCODE, P.RENEWALSTATUS, C.REPORTTOTHIRDPARTY,C.PREDECESSORID, null, 
			 null, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE,
			 P.BASIS, P.REGISTEREDUSERS, C.LOCALCLIENTFLAG, P.EXAMTYPE, P.RENEWALTYPE, 0,isnull(C.IPODELAY,0),
			 isnull(C.APPLICANTDELAY,0),T.USERID,T.IDENTITYID,C.OFFICEID,C.LOGDATETIMESTAMP,P.LOGDATETIMESTAMP
	From #TEMPCASEEVENT T
	join DUEDATECALC DD	on (DD.CRITERIANO=T.CREATEDBYCRITERIA
				and DD.EVENTNO   =T.EVENTNO)
	join RELATEDCASE RC	on (RC.CASEID=T.CASEID
				and RC.RELATIONSHIP=DD.COMPARERELATIONSHIP)
	join CASES C		on (C.CASEID=RC.RELATEDCASEID)
	left join PROPERTY P	on (P.CASEID=C.CASEID)
	left join #TEMPCASES TC on (TC.CASEID=C.CASEID)
	where T.NEWEVENTDUEDATE is not null
	and T.[STATE] in ('R','RX')
	and isnull(T.DATEDUESAVED,0)=0
	and TC.CASEID is null"

	Execute @ErrorCode=sp_executesql @sSQLString

	Set @nRowCount=@@Rowcount
End

-- If new Cases were loaded then load the associated CaseEvents

If @ErrorCode=0
and @nRowCount>0
Begin
	Execute @ErrorCode=ip_PoliceGetEventsForTempTable @pnDebugFlag
End

-- Load a temporary table with the number of valid comparisons achieved
-- for each CASEID, EVENTNO and CYCLE combination.

If @ErrorCode=0
Begin
	Exec("
	insert #TEMPCOMPARECOUNT(CASEID,EVENTNO, CYCLE, CREATEDBYCRITERIA, COMPARECOUNT)
	select T.CASEID, T.EVENTNO, T.CYCLE, T.CREATEDBYCRITERIA, count(*)
	from #TEMPCASEEVENT T
	join DUEDATECALC DD		on (DD.CRITERIANO=T.CREATEDBYCRITERIA
					and DD.EVENTNO   =T.EVENTNO)
	left join #TEMPCASEEVENT T1	on (T1.CASEID = T.CASEID 
					and T1.EVENTNO= DD.FROMEVENT
					-- SQA13422 Ignore CaseEvents that are still being 
					-- calculated unless :
					-- 1) it is the event we are trying to actually calculate
					-- 2) the calculated due date will not be saved and comparison is not NOT EXISTS and the comparison DueDate previously existed
					-- 3) the calculate due date will only be save if it is not in the future and the comparison DueDate previously existed
			 		and((T1.[STATE] not in ('C','C1','R') OR DD.COMPARISON='NE')  
					 OR (isnull(T.SAVEDUEDATE,0)=0 and DD.COMPARISON<>'NE' and T1.OLDEVENTDUEDATE is not null)
					 OR (T.SAVEDUEDATE=4 and convert(nvarchar,T.NEWEVENTDUEDATE,102)>convert(nvarchar,getdate(),102) and T1.OLDEVENTDUEDATE is not null)
					 OR (T1.CASEID=T.CASEID and T1.EVENTNO=T.EVENTNO and DD.EVENTDATEFLAG in (2,3)))
					and T1.CYCLE  = CASE DD.RELATIVECYCLE	WHEN(0) THEN T.CYCLE
										WHEN(1) THEN T.CYCLE-1
									    	WHEN(2) THEN T.CYCLE+1
									    	WHEN(3) THEN 1
									   		ELSE (select max(CYCLE)
											      from #TEMPCASEEVENT T3 
											      where T3.CASEID =T1.CASEID 
											      and   T3.EVENTNO=T1.EVENTNO
											      and   T3.[STATE] not in ('D','D1')
											      and  (T3.[STATE] not in ('C','C1','R') OR DD.COMPARISON='NE')
											      and ((DD.EVENTDATEFLAG=1 and  T3.NEWEVENTDATE is not null)
											       or  (DD.EVENTDATEFLAG=2 and  T3.NEWEVENTDUEDATE is not null)
											       or  (DD.EVENTDATEFLAG=3 and (T3.NEWEVENTDUEDATE is not null or T3.NEWEVENTDATE is not null))))
						       END
									-- This restriction is to allow for 
									-- multiple #TEMPCASEEVENT rows when an
									-- Event belongs to more than one action
					and T1.UNIQUEID=(select min(UNIQUEID)
							 from #TEMPCASEEVENT U
							 where U.CASEID =T1.CASEID
							 and   U.EVENTNO=T1.EVENTNO
							 and   U.CYCLE  =T1.CYCLE))
	left join RELATEDCASE RC	on (RC.CASEID = T.CASEID
					and RC.RELATIONSHIP=DD.COMPARERELATIONSHIP)
	left join #TEMPCASEEVENT T2 	on (T2.CASEID = isnull(RC.RELATEDCASEID,T.CASEID)
					and T2.EVENTNO= DD.COMPAREEVENT
					-- SQA13422 Ignore CaseEvents that are still being 
					-- calculated unless :
					-- 1) it is the event we are trying to actually calculate
					-- 2) the calculated due date will not be saved and comparison is not NOT EXISTS and the comparison DueDate previously existed
					-- 3) the calculate due date will only be save if it is not in the future and the comparison DueDate previously existed
			 		and( T2.[STATE] not in ('C','C1','R','RX')
					 OR (isnull(T.SAVEDUEDATE,0)=0 and DD.COMPARISON<>'NE' and T2.OLDEVENTDUEDATE is not null)
					 OR (T.SAVEDUEDATE=4 and convert(nvarchar,T.NEWEVENTDUEDATE,102)>convert(nvarchar,getdate(),102) and T2.OLDEVENTDUEDATE is not null)
					 OR (T2.CASEID=T.CASEID and T2.EVENTNO=T.EVENTNO and DD.COMPAREEVENTFLAG in (2,3)))

					and T2.CYCLE  = CASE DD.COMPARECYCLE	WHEN(0) THEN T.CYCLE
									    	WHEN(1) THEN T.CYCLE-1
									    	WHEN(2) THEN T.CYCLE+1
									    	WHEN(3) THEN 1
										WHEN(8) THEN isnull(RC.CYCLE,1)
									   		ELSE (select max(CYCLE)
											      from #TEMPCASEEVENT T3 
											      where T3.CASEID =T2.CASEID 
											      and   T3.EVENTNO=T2.EVENTNO
											      and   T3.[STATE] not in ('D','D1','C','C1','R','RX')
											      and ((DD.COMPAREEVENTFLAG=1 and  T3.NEWEVENTDATE is not null)
											       or  (DD.COMPAREEVENTFLAG=2 and  T3.NEWEVENTDUEDATE is not null)
											       or  (DD.COMPAREEVENTFLAG=3 and (T3.NEWEVENTDUEDATE is not null or T3.NEWEVENTDATE is not null))))
						       END
									-- This restriction is to allow for 
									-- multiple #TEMPCASEEVENT rows when an
									-- Event belongs to more than one action
					and T2.UNIQUEID=(select min(UNIQUEID)
							 from #TEMPCASEEVENT U
							 where U.CASEID =T2.CASEID
							 and   U.EVENTNO=T2.EVENTNO
							 and   U.CYCLE  =T2.CYCLE))
	WHERE	T.NEWEVENTDUEDATE is not null
	and	T.[STATE] in ('R','RX')
	and	T.ACTION=T.CREATEDBYACTION
	and    (isnull(T1.[STATE],'X') not in ('D','D1') OR DD.COMPARISON='NE')
	and 	isnull(T2.[STATE],'X') not in ('D','D1')
	and	isnull(T.DATEDUESAVED,0)=0

		-- If the date that is being compared is supposed to be a Due Date then check that it has not Occurred
	and ( DD.EVENTDATEFLAG<>2              OR isnull(T1.OCCURREDFLAG,0)=0 OR DD.COMPARISON='NE')
	and ( isnull(DD.COMPAREEVENTFLAG,1)<>2 OR isnull(T2.OCCURREDFLAG,0)=0 OR DD.COMPARISON='NE')
	and (
		-- The following complex WHERE clause is required to combine all of the different	
		-- combinations of EVENTDATEFLAG, COMPAREEVENTFLAG and COMPARISON in order to test the	
		-- correct column comparison.  I could not devise any other method of formulating this	
		-- query.
		   (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='='  and T1.NEWEVENTDATE =  T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='>'  and T1.NEWEVENTDATE >  T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='<'  and T1.NEWEVENTDATE <  T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='<=' and T1.NEWEVENTDATE <= T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='>=' and T1.NEWEVENTDATE >= T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='<>' and T1.NEWEVENTDATE <> T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=1                           and DD.COMPARISON='EX' and T1.NEWEVENTDATE IS NOT NULL)
		OR (DD.EVENTDATEFLAG=1                           and DD.COMPARISON='NE' and T1.NEWEVENTDATE IS NULL)
	
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='='  and T1.NEWEVENTDATE =  T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='>'  and T1.NEWEVENTDATE >  T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='<'  and T1.NEWEVENTDATE <  T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='<=' and T1.NEWEVENTDATE <= T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='>=' and T1.NEWEVENTDATE >= T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='<>' and T1.NEWEVENTDATE <> T2.NEWEVENTDUEDATE)
	
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='='  and T1.NEWEVENTDATE =  isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='>'  and T1.NEWEVENTDATE >  isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='<'  and T1.NEWEVENTDATE <  isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='<=' and T1.NEWEVENTDATE <= isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='>=' and T1.NEWEVENTDATE >= isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=1 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='<>' and T1.NEWEVENTDATE <> isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))	

		OR (DD.EVENTDATEFLAG=1 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='='  and T1.NEWEVENTDATE =  convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=1 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='>'  and T1.NEWEVENTDATE >  convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=1 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='<'  and T1.NEWEVENTDATE <  convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=1 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='<=' and T1.NEWEVENTDATE <= convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=1 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='>=' and T1.NEWEVENTDATE >= convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=1 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='<>' and T1.NEWEVENTDATE <> convert(varchar, getdate(),112))

		OR (DD.EVENTDATEFLAG=1                            and DD.COMPARISON='='  and T1.NEWEVENTDATE =  DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=1                            and DD.COMPARISON='>'  and T1.NEWEVENTDATE >  DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=1                            and DD.COMPARISON='<'  and T1.NEWEVENTDATE <  DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=1                            and DD.COMPARISON='<=' and T1.NEWEVENTDATE <= DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=1                            and DD.COMPARISON='>=' and T1.NEWEVENTDATE >= DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=1                            and DD.COMPARISON='<>' and T1.NEWEVENTDATE <> DD.COMPAREDATE)
	
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='='  and T1.NEWEVENTDUEDATE =  T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='>'  and T1.NEWEVENTDUEDATE >  T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='<'  and T1.NEWEVENTDUEDATE <  T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='<=' and T1.NEWEVENTDUEDATE <= T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='>=' and T1.NEWEVENTDUEDATE >= T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='<>' and T1.NEWEVENTDUEDATE <> T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=2                           and DD.COMPARISON='EX' and T1.NEWEVENTDUEDATE IS NOT NULL and T1.NEWEVENTDATE is null)  --SQA19124
		OR (DD.EVENTDATEFLAG=2                           and DD.COMPARISON='NE' and(T1.NEWEVENTDUEDATE IS NULL     or  T1.NEWEVENTDATE is not null OR T1.OCCURREDFLAG<>0 OR T1.[STATE] in ('D','D1')))  --SQA19124
	
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='='  and T1.NEWEVENTDUEDATE =  T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='>'  and T1.NEWEVENTDUEDATE >  T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='<'  and T1.NEWEVENTDUEDATE <  T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='<=' and T1.NEWEVENTDUEDATE <= T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='>=' and T1.NEWEVENTDUEDATE >= T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='<>' and T1.NEWEVENTDUEDATE <> T2.NEWEVENTDUEDATE)
	
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='='  and T1.NEWEVENTDUEDATE =  isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='>'  and T1.NEWEVENTDUEDATE >  isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='<'  and T1.NEWEVENTDUEDATE <  isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='<=' and T1.NEWEVENTDUEDATE <= isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='>=' and T1.NEWEVENTDUEDATE >= isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=2 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='<>' and T1.NEWEVENTDUEDATE <> isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
	
		OR (DD.EVENTDATEFLAG=2 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='='  and T1.NEWEVENTDUEDATE =  convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=2 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='>'  and T1.NEWEVENTDUEDATE >  convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=2 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='<'  and T1.NEWEVENTDUEDATE <  convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=2 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='<=' and T1.NEWEVENTDUEDATE <= convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=2 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='>=' and T1.NEWEVENTDUEDATE >= convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=2 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='<>' and T1.NEWEVENTDUEDATE <> convert(varchar, getdate(),112))
	
		OR (DD.EVENTDATEFLAG=2                            and DD.COMPARISON='='  and T1.NEWEVENTDUEDATE =  DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=2                            and DD.COMPARISON='>'  and T1.NEWEVENTDUEDATE >  DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=2                            and DD.COMPARISON='<'  and T1.NEWEVENTDUEDATE <  DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=2                            and DD.COMPARISON='<=' and T1.NEWEVENTDUEDATE <= DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=2                            and DD.COMPARISON='>=' and T1.NEWEVENTDUEDATE >= DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=2                            and DD.COMPARISON='<>' and T1.NEWEVENTDUEDATE <> DD.COMPAREDATE)
	
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='='  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) =  T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='>'  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) >  T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='<'  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <  T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='<=' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <= T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='>=' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) >= T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=1 and DD.COMPARISON='<>' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <> T2.NEWEVENTDATE)
		OR (DD.EVENTDATEFLAG=3                           and DD.COMPARISON='EX' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) IS NOT NULL)
		OR (DD.EVENTDATEFLAG=3                           and DD.COMPARISON='NE' and(isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) IS NULL OR T1.OCCURREDFLAG=9 OR T1.[STATE] in ('D','D1')))
	
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='='  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) =  T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='>'  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) >  T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='<'  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <  T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='<=' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <= T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='>=' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) >= T2.NEWEVENTDUEDATE)
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=2 and DD.COMPARISON='<>' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <> T2.NEWEVENTDUEDATE)
	
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='='  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) =  isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='>'  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) >  isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='<'  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <  isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='<=' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <= isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='>=' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) >= isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
		OR (DD.EVENTDATEFLAG=3 and DD.COMPAREEVENTFLAG=3 and DD.COMPARISON='<>' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <> isnull(T2.NEWEVENTDATE,T2.NEWEVENTDUEDATE))
	
		OR (DD.EVENTDATEFLAG=3 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='='  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) =  convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=3 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='>'  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) >  convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=3 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='<'  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <  convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=3 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='<=' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <= convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=3 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='>=' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) >= convert(varchar, getdate(),112))
		OR (DD.EVENTDATEFLAG=3 and DD.COMPARESYSTEMDATE=1 and DD.COMPARISON='<>' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <> convert(varchar, getdate(),112))
	
		OR (DD.EVENTDATEFLAG=3                            and DD.COMPARISON='='  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) =  DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=3                            and DD.COMPARISON='>'  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) >  DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=3                            and DD.COMPARISON='<'  and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <  DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=3                            and DD.COMPARISON='<=' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <= DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=3                            and DD.COMPARISON='>=' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) >= DD.COMPAREDATE)
		OR (DD.EVENTDATEFLAG=3                            and DD.COMPARISON='<>' and isnull(T1.NEWEVENTDATE,T1.NEWEVENTDUEDATE) <> DD.COMPAREDATE)
			)
	group by T.CASEID, T.EVENTNO, T.CYCLE, T.CREATEDBYCRITERIA
	OPTION (MAXDOP 1)")

	Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin

--	If COMPAREBOOLEAN=1 then ALL date comparisons defined must be true for the due date
--	calculated to be kept.  Determine this by counting the number of date comparison
--	rules and compare against the number of rules that are true.
	set @sSQLString="
	Insert into #TEMPCOMPARE (CASEID, EVENTNO, CYCLE)
	Select T.CASEID, T.EVENTNO, T.CYCLE
	From (	select T1.CASEID, T1.EVENTNO, T1.CYCLE, T1.COMPAREBOOLEAN, count(*) as RuleCount
		from #TEMPCASEEVENT T1
		join DUEDATECALC DD1	on (DD1.CRITERIANO=T1.CREATEDBYCRITERIA
					and DD1.EVENTNO   =T1.EVENTNO)
		left join RELATEDCASE R	on (R.CASEID=T1.CASEID
					and R.RELATIONSHIP=DD1.COMPARERELATIONSHIP)
		where DD1.COMPARISON is not null
		and T1.ACTION=T1.CREATEDBYACTION
		and T1.NEWEVENTDUEDATE is not null
		and T1.[STATE] in ('R','RX')
		and isnull(T1.DATEDUESAVED,0)=0
		group by T1.CASEID, T1.EVENTNO, T1.CYCLE, T1.COMPAREBOOLEAN) T 
	left join #TEMPCOMPARECOUNT TC		 on (TC.CASEID =T.CASEID
						and  TC.EVENTNO=T.EVENTNO
						and  TC.CYCLE  =T.CYCLE)
	Where	T.RuleCount>0
		-- Compare the number of Rules against the number of comparisons that were ok

		-- If COMPAREBOOLEAN=1 then the test fails if all rules did not match
	and    ((T.COMPAREBOOLEAN=1 AND T.RuleCount>isnull(TC.COMPARECOUNT,0))
		-- If COMPAREBOOLEAN<>1 then the test fails if no rules matched at all
	  OR    ((T.COMPAREBOOLEAN=0 or T.COMPAREBOOLEAN is null) AND TC.CASEID is null))"

	Exec @ErrorCode=sp_executesql @sSQLString
End



-- Now update the TEMPCASEEVENT table for those rows that have failed the comparison test

If @ErrorCode=0
Begin
	Set @sSQLString="
	update	#TEMPCASEEVENT
	set 	NEWEVENTDUEDATE=null
	From #TEMPCASEEVENT CE
	join #TEMPCOMPARE C	on (C.CASEID =CE.CASEID
				and C.EVENTNO=CE.EVENTNO
				and C.CYCLE  =CE.CYCLE)
	-- check if the Case Event that just failed the date comparison
	-- was used in another date comparison rule that was calculated
	-- at the same time.  If so then we will need to trigger the
	-- recalculation of that event.
	left join (
		select T1.CASEID, T1.EVENTNO, T1.CYCLE
		from #TEMPCOMPARECOUNT T
		join DUEDATECALC DD		on (DD.CRITERIANO=T.CREATEDBYCRITERIA
						and DD.EVENTNO   =T.EVENTNO)
		join #TEMPCASEEVENT T1		on (T1.CASEID = T.CASEID 
						and T1.EVENTNO= DD.FROMEVENT
						and T1.CYCLE  = CASE DD.RELATIVECYCLE	
									WHEN(0) THEN T.CYCLE
									WHEN(1) THEN T.CYCLE-1
								    	WHEN(2) THEN T.CYCLE+1
								    	WHEN(3) THEN 1
								   		ELSE (select max(CYCLE)
										      from #TEMPCASEEVENT T3 
										      where T3.CASEID =T1.CASEID 
										      and   T3.EVENTNO=T1.EVENTNO
										      and   T3.[STATE] not in ('D','D1')
										      and ((DD.EVENTDATEFLAG=1 and  T3.NEWEVENTDATE is not null)
										       or  (DD.EVENTDATEFLAG=2 and  T3.NEWEVENTDUEDATE is not null)
										       or  (DD.EVENTDATEFLAG=3 and (T3.NEWEVENTDUEDATE is not null or T3.NEWEVENTDATE is not null))))
							       END)
		UNION
		select T2.CASEID, T2.EVENTNO, T2.CYCLE
		from #TEMPCOMPARECOUNT T
		join DUEDATECALC DD		on (DD.CRITERIANO=T.CREATEDBYCRITERIA
						and DD.EVENTNO   =T.EVENTNO)
		left join RELATEDCASE RC	on (RC.CASEID = T.CASEID
						and RC.RELATIONSHIP=DD.COMPARERELATIONSHIP)
		join #TEMPCASEEVENT T2		on (T2.CASEID = isnull(RC.RELATEDCASEID,T.CASEID)
						and T2.EVENTNO= DD.COMPAREEVENT
						and T2.CYCLE  = CASE DD.COMPARECYCLE	
									WHEN(0) THEN T.CYCLE
								    	WHEN(1) THEN T.CYCLE-1
								    	WHEN(2) THEN T.CYCLE+1
								    	WHEN(3) THEN 1
									WHEN(8) THEN isnull(RC.CYCLE,1)
								   		ELSE (select max(CYCLE)
										      from #TEMPCASEEVENT T3 
										      where T3.CASEID =T2.CASEID 
										      and   T3.EVENTNO=T2.EVENTNO
										      and   T3.[STATE] not in ('D','D1')
										      and ((DD.COMPAREEVENTFLAG=1 and  T3.NEWEVENTDATE is not null)
										       or  (DD.COMPAREEVENTFLAG=2 and  T3.NEWEVENTDUEDATE is not null)
										       or  (DD.COMPAREEVENTFLAG=3 and (T3.NEWEVENTDUEDATE is not null or T3.NEWEVENTDATE is not null))))
							       END)) TC
				on (TC.CASEID =CE.CASEID
				and TC.EVENTNO=CE.EVENTNO
				and TC.CYCLE  =CE.CYCLE)"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If  @pnDebugFlag>0
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceCheckDateComparisons',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*
		from	#TEMPCASEEVENT T
		where	T.[STATE]<>'X'
		order by 4,1,2,3"

		exec @ErrorCode=sp_executesql @sSQLString
	End
End

drop table #TEMPCOMPARE

return @ErrorCode
go

grant execute on dbo.ip_PoliceCheckDateComparisons  to public
go

