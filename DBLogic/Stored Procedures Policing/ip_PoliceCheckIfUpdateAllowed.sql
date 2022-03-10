-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceCheckIfUpdateAllowed
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceCheckIfUpdateAllowed]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceCheckIfUpdateAllowed.'
	drop procedure dbo.ip_PoliceCheckIfUpdateAllowed
end
print '**** Creating procedure dbo.ip_PoliceCheckIfUpdateAllowed...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceCheckIfUpdateAllowed
			@pnUpdateCandidates	int	OUTPUT,
			@pnDebugFlag		tinyint
as
-- PROCEDURE :	ip_PoliceCheckIfUpdateAllowed
-- VERSION :	9
-- DESCRIPTION:	Check rules to determine if CaseEvent is to be blocked from
--		automatically updating as occurred.

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 09 Jan 2007	MF	12548	1	Procedure created
-- 27 Mar 2007	MF	14625	2	Revisit of 12548.  The SUBSTITUTENAMETYPE and APPLICABLENAMETYPE
--					were reversed when the user interface maintenance was created.
--					Easier to modify the Policing procedure than change the interface.
-- 21 Apr 2007	MF	14737	3	If no valid Events exist against the Document Cases then this was
--					incorrectly being treated as passing the test. Code corrected by
--					adding CROSS JOIN of CASES in the derived table to ensure the 
--					CASEID is returned even if no valid CASEEVENT.
-- 31 May 2007	MF	14812	4	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	5	Reserve word [STATE]
-- 05 Jun 2012	MF	S19025	6	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 17 Jul 2013	MF	R13664	7	When a Case has more than one of a given NameType and has a Must Exist rule for that NameType, then the existence
--					of any document for any of the actual names for that NameType will satisfy the requirement of the document existing.
-- 15 Mar 2017	MF	70049	8	Allow Renewal Status to be separately specified to be updated by an Event.
-- 14 Nov 2018  AV  75198/DR-45358	9   Date conversion errors when creating cases and opening names in Chinese DB
--		

set nocount on

Create table #TEMPDOCUMENTCASE(
		CASEID			int	NOT NULL,
		EVENTNO			int	NOT NULL,
		CRITERIANO		int	NOT NULL,
		DOCUMENTCASEID		int	NOT NULL,
		BESTFIT			char(7)	collate database_default NOT NULL
		)

Declare	@ErrorCode	int,
	@nRowCount	int,
	@sSQLString	nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0
Set @nRowCount = 0
------------------------------------------------------
-- Search for possible document Cases that match the
-- characteristics of the candidate Case to be updated
------------------------------------------------------

If @ErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TEMPDOCUMENTCASE(CASEID,EVENTNO,CRITERIANO,DOCUMENTCASEID,BESTFIT)
	SELECT 	DISTINCT T.CASEID, T.EVENTNO, T.CRITERIANO, C.CASEID,
		CASE WHEN (C.OFFICEID     IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (R.CASEID       IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.PROPERTYTYPE ='~')		THEN '0' ELSE '1' END +    			
		CASE WHEN (C.COUNTRYCODE  ='ZZZ')	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.SUBTYPE      IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (P.BASIS        IS NULL)	THEN '0' ELSE '1' END
	FROM #TEMPUPDATECANDIDATE T
	join EVENTCONTROL EC	on (EC.CRITERIANO=T.CRITERIANO
				and EC.EVENTNO=T.EVENTNO)
	join CASES C		on (C.CASETYPE=EC.CASETYPE)
	left join PROPERTY P	on (P.CASEID=C.CASEID)
	join #TEMPCASES TC	on (TC.CASEID=T.CASEID)

	-- document Case is to match on names
	join EVENTCONTROLNAMEMAP NM
				on (NM.CRITERIANO=T.CRITERIANO
				and NM.EVENTNO=T.EVENTNO)
	join CASENAME CN1	on (CN1.CASEID=T.CASEID
				and CN1.NAMETYPE=isnull(NM.SUBSTITUTENAMETYPE,NM.APPLICABLENAMETYPE)
				and(CN1.EXPIRYDATE is null or CN1.EXPIRYDATE>getdate()))
	left join CASENAME CN2	on (CN2.CASEID=C.CASEID
				and CN2.NAMETYPE=NM.APPLICABLENAMETYPE
				and(CN2.EXPIRYDATE is null or CN2.EXPIRYDATE>getdate())
				and CN2.NAMENO=CN1.NAMENO)

	-- check to see if the Document Case has been specifically
	-- linked to the candidate Case.
	left join RELATEDCASE R	on (R.CASEID=C.CASEID
				and R.RELATEDCASEID=T.CASEID)

	-- check all required Events exist against
	-- the candidate Case.
	left join (	select	RE.CRITERIANO, RE.EVENTNO, C.CASEID, 
				count(*) as REQUIREDEVENTCOUNT,
				sum(CASE WHEN(CE.EVENTNO is null) THEN 0 ELSE 1 END) as OCCURREDEVENTCOUNT 
			from EVENTCONTROLREQEVENT RE
			cross join CASES C	
			left join CASEEVENT CE	on (CE.CASEID=C.CASEID
						and CE.EVENTNO=RE.REQEVENTNO
						and CE.CYCLE=1
						and CE.OCCURREDFLAG=1)
			group by RE.CRITERIANO, RE.EVENTNO, C.CASEID) REQ	
						on (REQ.CASEID=C.CASEID
						and REQ.CRITERIANO=EC.CRITERIANO
						and REQ.EVENTNO=EC.EVENTNO)

	WHERE(C.OFFICEID     = CASE WHEN(EC.OFFICEIDISTHISCASE=1)    THEN TC.OFFICEID     ELSE EC.OFFICEID     END OR C.OFFICEID     IS NULL)
	AND  (C.PROPERTYTYPE = CASE WHEN(EC.PROPERTYTYPEISTHISCASE=1)THEN TC.PROPERTYTYPE ELSE EC.PROPERTYTYPE END OR C.PROPERTYTYPE ='~')
	AND  (C.COUNTRYCODE  = CASE WHEN(EC.COUNTRYCODEISTHISCASE=1) THEN TC.COUNTRYCODE  ELSE EC.COUNTRYCODE  END OR C.COUNTRYCODE  ='ZZZ')
	AND  (C.CASECATEGORY = CASE WHEN(EC.CATEGORYISTHISCASE=1)    THEN TC.CASECATEGORY ELSE EC.CASECATEGORY END OR C.CASECATEGORY IS NULL)
	AND  (C.SUBTYPE      = CASE WHEN(EC.SUBTYPEISTHISCASE=1)     THEN TC.SUBTYPE      ELSE EC.SUBTYPE      END OR C.SUBTYPE      IS NULL)
	AND  (P.BASIS        = CASE WHEN(EC.BASISISTHISCASE=1)       THEN TC.BASIS        ELSE EC.BASIS        END OR P.BASIS        IS NULL)
	--    Number of required events must have 
	--    occurred on the document case
	AND   isnull(REQ.OCCURREDEVENTCOUNT,0)>=isnull(REQ.REQUIREDEVENTCOUNT,0)
	--    Document case names are to match with
	--    names against the candidate cases
	AND  (CN2.NAMENO=CN1.NAMENO
	 OR  (isnull(NM.MUSTEXIST,0)=0 
	  and not exists (Select 1 from CASENAME CN3
			  where CN3.CASEID=C.CASEID
			  and CN3.NAMETYPE=isnull(NM.SUBSTITUTENAMETYPE,NM.APPLICABLENAMETYPE)
			  and(CN3.EXPIRYDATE is null or CN3.EXPIRYDATE>getdate())
			  and CN3.NAMENO<>CN1.NAMENO) ))
	--   The document Case must either be linked directly to
	--   the candidate Case or not be linked to any other Case.
	AND  (R.CASEID is not null
	 OR   not exists (Select 1 from RELATEDCASE R1
			  where R1.CASEID=C.CASEID
			  and R1.RELATEDCASEID is not null) )"

	exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@@Rowcount
End

-------------------------------------------------
-- Remove any Document Cases that do not have the
-- required set of matching names.
-------------------------------------------------
If @nRowCount>0
and @ErrorCode=0
Begin
	Set @sSQLString="
	Delete #TEMPDOCUMENTCASE
	from #TEMPDOCUMENTCASE T
	join EVENTCONTROLNAMEMAP NM	
				on (NM.CRITERIANO=T.CRITERIANO
				and NM.EVENTNO=T.EVENTNO)
	left join CASENAME CN2	on (CN2.CASEID=T.DOCUMENTCASEID
				and CN2.NAMETYPE=NM.APPLICABLENAMETYPE
				and(CN2.EXPIRYDATE is null or CN2.EXPIRYDATE>getdate())
				and CN2.NAMENO in (SELECT CN1.NAMENO
						   from CASENAME CN1
						   where CN1.CASEID=T.CASEID
						   and   CN1.NAMETYPE=isnull(NM.SUBSTITUTENAMETYPE,NM.APPLICABLENAMETYPE)
						   and  (CN1.EXPIRYDATE is null or CN1.EXPIRYDATE>GETDATE())))
	--     Delete if a MustExist name is missing
	Where (NM.MUSTEXIST=1 and CN2.CASEID is null)
	--     Delete if an optional Name is missing but
	--     a non matching name exists for the name type
	OR    (isnull(NM.MUSTEXIST,0)=0 
	  and  CN2.CASEID is null
	  and  exists(  select * from CASENAME CN3
			where CN3.CASEID=T.DOCUMENTCASEID
			and CN3.NAMETYPE=NM.APPLICABLENAMETYPE
			and(CN3.EXPIRYDATE is null OR CN2.EXPIRYDATE>getdate())))"

	Exec @ErrorCode=sp_executesql @sSQLString

	Set @nRowCount=@nRowCount-@@rowcount
End

-------------------------------------------------
-- Now update the candidate Cases with the best
-- Document Case that will allow the update to 
-- occur.
-------------------------------------------------
If @nRowCount>0
and @ErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPUPDATECANDIDATE
	Set FROMCASEID=convert(int,substring(D.BESTFIT, 8,20))
	from #TEMPUPDATECANDIDATE T
	join (	select	max(BESTFIT+convert(varchar,DOCUMENTCASEID)) as BESTFIT,
			CASEID, CRITERIANO, EVENTNO
		from #TEMPDOCUMENTCASE
		group by CASEID, CRITERIANO, EVENTNO) D	on (D.CASEID=T.CASEID
							and D.CRITERIANO=T.CRITERIANO
							and D.EVENTNO=T.EVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-------------------------------------------------
-- Finally remove any update candidates that 
-- require a document Case but none exists
-------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	Delete #TEMPUPDATECANDIDATE
	from #TEMPUPDATECANDIDATE T
	where T.FROMCASEID is null
	and exists
	(select 1 from EVENTCONTROLREQEVENT EC
	 where EC.CRITERIANO=T.CRITERIANO
	 and EC.EVENTNO=T.EVENTNO)"

	exec @ErrorCode=sp_executesql @sSQLString

	Set @pnUpdateCandidates=@pnUpdateCandidates-@@rowcount
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceCheckIfUpdateAllowed',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*,@pnUpdateCandidates as 'RowCount' 
		from	#TEMPCASEEVENT T
		where	T.[STATE]<>'X'
		order by 4,1,2,3"

		exec @ErrorCode= sp_executesql @sSQLString,
						N'@pnUpdateCandidates	int',
						  @pnUpdateCandidates
	End
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceCheckIfUpdateAllowed  to public
go
