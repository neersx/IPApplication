-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceCalculateCriteria
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceCalculateCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceCalculateCriteria.'
	drop procedure dbo.ip_PoliceCalculateCriteria
end
print '**** Creating procedure dbo.ip_PoliceCalculateCriteria...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceCalculateCriteria
			 @pbCriteriaUpdated	bit	OUTPUT,
			 @pnDebugFlag		tinyint 
as
-- PROCEDURE :	ip_PoliceCalculateCriteria
-- VERSION :	34
-- DESCRIPTION:	A procedure to recalculate the Criteria of Open Action rows.
-- CALLED BY :	ipu_PoliceRecalc

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 13/07/2000	MF			Procedure created	
-- 03/09/2001	MF	7032		If no date of act then use todays date to get the latest Criteria. 
-- 19/10/2001	MF	7132		When the CriteriaNo for an OPENACTION row has been determined check to see
--					if any additional TEMPCASEEVENT rows need to be inserted for any Events just
--					updated that may now have a function to perform as a result of the new OpenAction.
-- 09/11/2001	MF	7190		Modify the looping procedure so that cursors are not used as these cause the 
--					stored procedure to recompile each execution.  Also use sp_executesql.
-- 01/03/2002	MF	7367 		Get ESTIMATEFLAG from the EventControl table for later charges raising.
-- 21/08/2002	MF	7532		Allow a new facility that causes the Due Date of an Event to be advanced by
--					a defined amount whenever the due date matches or exceeds the system date.
-- 21/08/2002	MF	7627		Allow a second Fee to be requested when an Event is updated.
-- 17/06/2003	MF	8916		Change of law was not causing CaseEvents to be recalculated when there was
--					a mixture of Cases that already had the correct law and Cases with an old
--					law being processed.
-- 24 Jul 2003	MF	8260	10	Get the PTADELAY from the EventControl table for Patent Term Adjustment calculation.
-- 28 Jul 2003	MF	8673	10	Use the OFFICE associated with the Case to determine the best CriteriaNo
--					for an Action.
-- 23 Feb 2004	MF	9738	11	Change the best fit hierarchy to move the UserDefinedRule flag to be lower
--					than the Date of Law
-- 26 Feb 2004	MF	RF709	12	Require IDENTITYID to identify workbench users.
-- 06 Aug 2004	AB	8035	13	Add collate database_default to temp table definitions
-- 03 Nov 2004	MF	10385	14	New EventControl column SETTHIRDPARTYOFF to turn off the ReportToThirdParty
--					flag against Cases when an Event occurs
-- 12 Nov 2004	MF	10385	15	Correction to coding error.
-- 07 Jul 2005	MF	11011	16	Increase CaseCategory column size to NVARCHAR(2)
-- 18 Aug 2005	MF	11762	17	Inconsistency in definition of the variable nValue.  Changed to INT from SMALLINT
--					to ensure data overflow does not occur.
-- 15 May 2006	MF	12315	18	New columns required to allow CASENAME updates when Event occurs.
-- 07 Jun 2006	MF	12417	19	Change order of columns returned in debug mode to make it easier to review
-- 21 Aug 2006	MF	13089	20	Get the DIRECTPAYFLAG from EventControl for later raising of charges.
-- 05 Oct 2006	MF	13295	21	When determining the CriteriaNo for a Case, consider if there is an ActualCaseType
--					associated with the CaseType of the Case being processed.
-- 24 May 2007	MF	14812	22	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	23	Reserve word [STATE]
-- 29 Oct 2007	MF	15518	24	Insert LIVEFLAG on #TEMPCASEEVENT
-- 07 Jan 2008	MF	15586	24	Allow a specific Name or NameType to be associated with a CaseEvent due date.
-- 25 Jan 2012	MF	11808	25	If there are no due date calculation rules for the new Criteria and no due date calculation rules
--					exist for any other Action for the Case then trigger Event to recalculate so that it will be deleted
--					and trigger other event recalculations.
-- 05 Jun 2012	MF	S19025	26	Dump out all columns in #TEMPCASEEVENT in debug mode.
-- 06 Jun 2013	MF	S21404	27	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 15 Sep 2015	MF	51907	28	Calculation of Criteria should allow for the CaseType to not be defined on the Criteria.
-- 01 Apr 2016	MF	59925	29	Newly opened Action with no defined Criteria is not being reported as an error
-- 11 Apr 2016	MF	R60302	30	If no CriteriaNo was able to be calculated for the OPENACTION then report the CRITERIANO and EVENTNO
--					that requested the action to open.
-- 07 Jul 2016	MF	63861	31	A null LOCALCLIENTFLAG should default to 0.
-- 26 Oct 2016	MF	69662	32	When constructing PoliceError message, ensure the Message can cope with null values in the concatenation.
-- 15 Mar 2017	MF	70049	33	Allow Renewal Status to be separately specified to be updated by an Event.
-- 14 Nov 2018  AV  75198/DR-45358	34   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on
-- set ansi_warnings off	

	Create table #TEMPCRITERIA (
		SEQUENCENO		int 		identity(1,1),
		CASEOFFICEID		int		null,
		ACTION			nvarchar(2)	collate database_default null, 
		COUNTRYCODE		nvarchar(3)	collate database_default null, 
		PROPERTYTYPE		nchar(1)	collate database_default null,
		DATEFORACT		datetime	null,
		CASETYPE		nchar(1)	collate database_default null,
		CASECATEGORY		nvarchar(2)	collate database_default null,
		SUBTYPE			nvarchar(2)	collate database_default null,
		BASIS			nvarchar(2)	collate database_default null,
		REGISTEREDUSERS 	nchar(1)	collate database_default null,
		LOCALCLIENTFLAG 	decimal(1,0)	null,
		EXAMTYPE		int		null,
		RENEWALTYPE		int		null,
		OLDCRITERIANO		int		null
	)

DECLARE		@ErrorCode		int,
		@nRowCount		int,
		@nCurrentRowCount	int,
		@nCriteriano		int,
		@nOldCriteriano		int,
		@nValue			int,
		@nTotalCriteria		int,
		@bErrorFlag		bit,
		@sSQLString		nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode=0
Set @nRowCount=0
-------------------------------------------------------------------------------------
-- Extract a unique set of characteristics into a temporary table which will be processed.  
-- NOTE :	This method is being used as an alternative to using a CURSOR as the use of CURSORS causes
--		additional recompilation of the stored procedure

If @ErrorCode = 0
Begin
	set @sSQLString="
	insert into #TEMPCRITERIA 
		       (CASEOFFICEID, ACTION, COUNTRYCODE, PROPERTYTYPE, DATEFORACT, CASETYPE, CASECATEGORY, SUBTYPE, 
			BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE, RENEWALTYPE, OLDCRITERIANO)
	select distinct CASEOFFICEID, ACTION, COUNTRYCODE, PROPERTYTYPE, DATEFORACT, CASETYPE, CASECATEGORY, SUBTYPE,
			BASIS, REGISTEREDUSERS, isnull(LOCALCLIENTFLAG,0), EXAMTYPE, RENEWALTYPE, NEWCRITERIANO
	from #TEMPOPENACTION T
	where T.[STATE]='C'"

	exec @ErrorCode=sp_executesql @sSQLString

	Set @nTotalCriteria=@@Rowcount

	Set @nValue = 1
End

-- Loop through each row returned and get the best fit CRITERIANO and then update all #TEMPOPENACTION rows
-- that have the same characteristics.

WHILE @nValue <= @nTotalCriteria
 and  @ErrorCode=0
BEGIN
	-- If no Criteriano is found the @nCriteriano will be set to NULL
	-- The following method of getting the best CriteriaNo uses a Best Fit weighting
	-- The value of the best fit is returned as a string of zeros and ones.  The Date Of Act is
	-- returned in the format YYYYMMDD and is concatenated as a string.  Using the MAX function then
	-- returns the best row and it is just a matter of using a SUBSTRING to extract the CriteriaNo that
	-- was concatenated to the end of the Best Fit and Date of Act.
	set @sSQLString="
	SELECT 
	@nOldCriterianoOUT=isnull(max(isnull(T.OLDCRITERIANO,-999999999)),-999999999),
	@nCriterianoOUT   =
	convert(int,
	substring(
	max (
	CASE WHEN (C.CASEOFFICEID IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (C.CASETYPE IS NULL)		THEN '0' 
		ELSE CASE WHEN(C.CASETYPE=CT.CASETYPE) 	 THEN '2' ELSE '1' END 
	END +  
	CASE WHEN (C.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
	CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (C.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
	CASE WHEN (C.BASIS IS NULL)		THEN '0' ELSE '1' END +
	CASE WHEN (C.TABLECODE is NULL)		THEN '0' ELSE '1' END +
	CASE WHEN (C.LOCALCLIENTFLAG IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (C.DATEOFACT IS NULL)		THEN '0' ELSE '1' END +
	isnull(convert(varchar, DATEOFACT, 112),'00000000') +
	CASE WHEN (C.USERDEFINEDRULE is NULL
		OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +	-- SQA9738 moved from after LOCALCLIENTFLAG
	convert(varchar,C.CRITERIANO)), 20,20))
	FROM CRITERIA C 
	join #TEMPCRITERIA T	on (T.SEQUENCENO=@nValue)
	join CASETYPE CT	on (CT.CASETYPE=T.CASETYPE)
	WHERE	C.RULEINUSE		= 1  	
	AND	C.PURPOSECODE		= 'E'
	AND 	C.ACTION		= T.ACTION
	AND (	C.CASEOFFICEID 		= T.CASEOFFICEID 	OR C.CASEOFFICEID 	IS NULL )
	AND (	C.CASETYPE	      in (CT.CASETYPE,CT.ACTUALCASETYPE) OR C.CASETYPE  IS NULL )
	AND (	C.PROPERTYTYPE 		= T.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
	AND (	C.COUNTRYCODE 		= T.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
	AND (	C.CASECATEGORY 		= T.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
	AND (	C.SUBTYPE 		= T.SUBTYPE 		OR C.SUBTYPE 		IS NULL ) 
	AND (	C.BASIS 		= T.BASIS 		OR C.BASIS 		IS NULL ) 	
	AND (	C.REGISTEREDUSERS 	= T.REGISTEREDUSERS	OR C.REGISTEREDUSERS	IS NULL )
	AND (	C.LOCALCLIENTFLAG 	= T.LOCALCLIENTFLAG 	OR C.LOCALCLIENTFLAG	IS NULL ) 
	AND (	C.DATEOFACT 	       <= isnull(T.DATEFORACT,getdate()) OR C.DATEOFACT IS NULL )
	AND (	C.TABLECODE 		= T.EXAMTYPE 		OR C.TABLECODE = T.RENEWALTYPE OR C.TABLECODE IS NULL )"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@nValue		int,
				  @nCriterianoOUT	int	OUTPUT,
				  @nOldCriterianoOUT	int	OUTPUT',
				  @nValue,
				  @nCriterianoOUT=@nCriteriano		OUTPUT,
				  @nOldCriterianoOUT=@nOldCriteriano	OUTPUT

--	Set the STATE to "E" if no CriteriaNo is found to indicate that an ERROR has occurred.

	If @ErrorCode=0
	Begin
		set @sSQLString="
		UPDATE #TEMPOPENACTION
		set	NEWCRITERIANO	=@nCriteriano,
			[STATE]		=CASE WHEN (@nCriteriano is null) THEN 'E' ELSE 'C' END
		from	#TEMPOPENACTION OA
		join	#TEMPCRITERIA T	on (T.SEQUENCENO=@nValue)
		where  (@nOldCriteriano<>@nCriteriano OR @nCriteriano is null)
		and     isnull(OA.NEWCRITERIANO,-999999999)=@nOldCriteriano
		and	OA.ACTION		=T.ACTION
		and (	OA.CASEOFFICEID		=T.CASEOFFICEID		OR (OA.CASEOFFICEID	is null and T.CASEOFFICEID	is null))
		and (	OA.CASETYPE		=T.CASETYPE		OR (OA.CASETYPE		is null and T.CASETYPE		is null))
		and (	OA.COUNTRYCODE		=T.COUNTRYCODE		OR (OA.COUNTRYCODE	is null and T.COUNTRYCODE 	is null))
		and (	OA.PROPERTYTYPE		=T.PROPERTYTYPE		OR (OA.PROPERTYTYPE	is null and T.PROPERTYTYPE	is null))
		and (	OA.CASECATEGORY		=T.CASECATEGORY 	OR (OA.CASECATEGORY 	is null and T.CASECATEGORY 	is null))
		and (	OA.SUBTYPE		=T.SUBTYPE 		OR (OA.SUBTYPE 		is null and T.SUBTYPE 		is null))
		and (	OA.BASIS		=T.BASIS 		OR (OA.BASIS 		is null and T.BASIS 		is null))
		and (	OA.REGISTEREDUSERS	=T.REGISTEREDUSERS	OR (OA.REGISTEREDUSERS	is null and T.REGISTEREDUSERS	is null))
		and (	isnull(OA.LOCALCLIENTFLAG,0)=T.LOCALCLIENTFLAG	OR (OA.LOCALCLIENTFLAG 	is null and T.LOCALCLIENTFLAG	is null))
		and (	OA.EXAMTYPE		=T.EXAMTYPE 		OR (OA.EXAMTYPE 	is null and T.EXAMTYPE 		is null))
		and (	OA.RENEWALTYPE		=T.RENEWALTYPE 		OR (OA.RENEWALTYPE 	is null and T.RENEWALTYPE 	is null))
		and (	OA.DATEFORACT		=T.DATEFORACT 		OR (OA.DATEFORACT 	is null and T.DATEFORACT 	is null))"

		exec @ErrorCode=sp_executesql @sSQLString, 
				N'@nCriteriano		int,
				  @nOldCriteriano	int,
				  @nValue		int',
				  @nCriteriano,
				  @nOldCriteriano,
				  @nValue

		Set @nCurrentRowCount=@@Rowcount

		If @nCriteriano is null
		Begin
			Set @bErrorFlag=1
		End

		-- If the Criteriano has changed then any associated Case Event rows are to be marked for 
		-- recalculation

		If  @ErrorCode=0
		and @nCurrentRowCount> 0
		and @nOldCriteriano <> @nCriteriano
		and @nCriteriano    is not null
		Begin
			set @pbCriteriaUpdated = 1

			set @sSQLString="
			UPDATE #TEMPCASEEVENT
			set	[STATE]=CASE 	WHEN T.POLICEEVENTS=1 AND CE.[STATE] in ('R','R1','D','DX','D1','X') 
						THEN 'C' 
						ELSE CE.[STATE] 
					END,
				CREATEDBYCRITERIA=@nCriteriano,
				IMPORTANCELEVEL=EC.IMPORTANCELEVEL,
				WHICHDUEDATE=EC.WHICHDUEDATE,
				COMPAREBOOLEAN=EC.COMPAREBOOLEAN,
				CHECKCOUNTRYFLAG=EC.CHECKCOUNTRYFLAG, 
				SAVEDUEDATE=EC.SAVEDUEDATE,
				STATUSCODE=EC.STATUSCODE,
				RENEWALSTATUS=EC.RENEWALSTATUS,
				SPECIALFUNCTION=EC.SPECIALFUNCTION,
				INITIALFEE=EC.INITIALFEE,
				PAYFEECODE=EC.PAYFEECODE,
				CREATEACTION=EC.CREATEACTION,
				STATUSDESC=EC.STATUSDESC, 
				CLOSEACTION=EC.CLOSEACTION,
				RELATIVECYCLE=EC.RELATIVECYCLE,
				INSTRUCTIONTYPE=EC.INSTRUCTIONTYPE,
				FLAGNUMBER=EC.FLAGNUMBER,
				SETTHIRDPARTYON=EC.SETTHIRDPARTYON,
				ESTIMATEFLAG=EC.ESTIMATEFLAG,
				EXTENDPERIOD=EC.EXTENDPERIOD,
				EXTENDPERIODTYPE=EC.EXTENDPERIODTYPE,
				INITIALFEE2=EC.INITIALFEE2,
				PAYFEECODE2=EC.PAYFEECODE2,
				ESTIMATEFLAG2=EC.ESTIMATEFLAG2,
				PTADELAY=EC.PTADELAY,
				SETTHIRDPARTYOFF=EC.SETTHIRDPARTYOFF,
				CHANGENAMETYPE=EC.CHANGENAMETYPE, 
				COPYFROMNAMETYPE=EC.COPYFROMNAMETYPE, 
				COPYTONAMETYPE=EC.COPYTONAMETYPE, 
				DELCOPYFROMNAME=EC.DELCOPYFROMNAME,
				DIRECTPAYFLAG=EC.DIRECTPAYFLAG,
				DIRECTPAYFLAG2=EC.DIRECTPAYFLAG2,
				SUPPRESSCALCULATION=EC.SUPPRESSCALCULATION
			from	#TEMPCASEEVENT CE
			join	#TEMPCRITERIA TC  on (TC.SEQUENCENO=@nValue)
			join	#TEMPOPENACTION T on (T.CASEID=CE.CASEID
						  and T.ACTION=CE.CREATEDBYACTION
						  and T.ACTION=TC.ACTION)
			join	ACTIONS		A on (A.ACTION=T.ACTION)
			join	EVENTCONTROL   EC on (EC.CRITERIANO=@nCriteriano
						  and EC.EVENTNO   =CE.EVENTNO)	
			where	(A.NUMCYCLESALLOWED=1 OR
				(A.NUMCYCLESALLOWED>1 AND CE.CYCLE=T.CYCLE))
			and	CE.NEWEVENTDATE is null
			and (	CE.DATEDUESAVED = 0			OR CE.DATEDUESAVED	is null)
			and (	CE.CREATEDBYCRITERIA<>@nCriteriano	OR CE.CREATEDBYCRITERIA is null)
			and (	 T.CASEOFFICEID	=TC.CASEOFFICEID	OR (T.CASEOFFICEID	is null and TC.CASEOFFICEID	is null))
			and (	 T.CASETYPE	=TC.CASETYPE		OR (T.CASETYPE		is null and TC.CASETYPE		is null))
			and (	 T.COUNTRYCODE	=TC.COUNTRYCODE		OR (T.COUNTRYCODE	is null and TC.COUNTRYCODE	is null))
			and (	 T.PROPERTYTYPE	=TC.PROPERTYTYPE	OR (T.PROPERTYTYPE	is null and TC.PROPERTYTYPE	is null))
			and (	 T.CASECATEGORY	=TC.CASECATEGORY 	OR (T.CASECATEGORY 	is null and TC.CASECATEGORY 	is null))
			and (	 T.SUBTYPE	=TC.SUBTYPE 		OR (T.SUBTYPE 		is null and TC.SUBTYPE 		is null))
			and (	 T.BASIS	=TC.BASIS 		OR (T.BASIS 		is null and TC.BASIS 		is null))
			and ( 	 T.REGISTEREDUSERS=TC.REGISTEREDUSERS	OR (T.REGISTEREDUSERS	is null and TC.REGISTEREDUSERS	is null))
			and (	 isnull(T.LOCALCLIENTFLAG,0)=TC.LOCALCLIENTFLAG	
									OR (T.LOCALCLIENTFLAG 	is null and TC.LOCALCLIENTFLAG	is null))
			and (	 T.EXAMTYPE	=TC.EXAMTYPE 		OR (T.EXAMTYPE 		is null and TC.EXAMTYPE 	is null))
			and (	 T.RENEWALTYPE	=TC.RENEWALTYPE 	OR (T.RENEWALTYPE 	is null and TC.RENEWALTYPE 	is null))
			and (	 T.DATEFORACT	=TC.DATEFORACT		OR (T.DATEFORACT 	is null and TC.DATEFORACT 	is null))"

			exec @ErrorCode=sp_executesql @sSQLString, 
					N'@nCriteriano		int,
					  @nValue		int',
					  @nCriteriano,
					  @nValue

			Select @nRowCount=@nRowCount+@@Rowcount
		End

		Select @ErrorCode=@@Error
	End

	-- Get the next SEQUENCENO of the Temporary Table

	Set @nValue = @nValue + 1

END


--	Report as an error any Actions that could not find a Criteria

If  @ErrorCode=0
and @bErrorFlag=1
Begin
	set @sSQLString="
	insert into #TEMPPOLICINGERRORS (CASEID, MESSAGE, CRITERIANO, EVENTNO,  CYCLENO)
	select T.CASEID,  
	      'Cannot find a criteria to open the action: ' + T.ACTION +'. '
	      +CASE WHEN(T.OPENINGCRITERIANO is not null and T.OPENINGEVENTNO is not null and T.OPENINGCYCLE is not null)
			THEN 'Action opened by CaseEvent with CriteriaNo('+cast(T.OPENINGCRITERIANO as varchar)+'), EventNo('+cast(T.OPENINGEVENTNO as varchar)+') and Cycle('+cast(T.OPENINGCYCLE as varchar)+').'
		     WHEN(T.OPENINGCRITERIANO is not null and T.OPENINGEVENTNO is not null)
			THEN 'Action opened by CaseEvent with CriteriaNo('+cast(T.OPENINGCRITERIANO as varchar)+'), and EventNo('+cast(T.OPENINGEVENTNO as varchar)+').'
		     WHEN(T.OPENINGCRITERIANO is not null)
			THEN 'Action opened by CriteriaNo('+cast(T.OPENINGCRITERIANO as varchar)+').'
			ELSE ''
		END,
	      T.OPENINGCRITERIANO, T.OPENINGEVENTNO,   T.OPENINGCYCLE
	from #TEMPOPENACTION T
	where T.[STATE] = 'E'"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- SQA 7132
-- For any TEMPOPENACTION that have just had their CRITERIANO updated check to see if a new TEMPCASEEVENT row
-- is to be inserted.  This handles the situation where an Event can belong to more than one Action.

If  @ErrorCode=0
and @nRowCount>0 -- Only if changed CriteriaNo has been found
Begin
	set @sSQLString="
	insert into #TEMPCASEEVENT 
			(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, OLDEVENTDATE, OLDEVENTDUEDATE, DATEDUESAVED, 
				OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA, ENTEREDDEADLINE, PERIODTYPE, DOCUMENTNO, 
				DOCSREQUIRED, DOCSRECEIVED, USEMESSAGE2FLAG, GOVERNINGEVENTNO, [STATE], ADJUSTMENT,
				IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
				SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
				INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, NEWEVENTDATE, NEWEVENTDUEDATE,
				USEDINCALCULATION, DATEREMIND, USERID, CRITERIANO, ACTION, EVENTUPDATEDMANUALLY, ESTIMATEFLAG,
				EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,IDENTITYID,SETTHIRDPARTYOFF,
				CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME, DIRECTPAYFLAG, DIRECTPAYFLAG2,LIVEFLAG,RESPNAMENO,RESPNAMETYPE,
				SUPPRESSCALCULATION)
	SELECT	distinct T.CASEID,  E.DISPLAYSEQUENCE, T.EVENTNO, isnull(T.CYCLE,1), 
		0, T.OLDEVENTDATE, T.OLDEVENTDUEDATE, T.DATEDUESAVED, T.OCCURREDFLAG, T.CREATEDBYACTION, 
		E.CRITERIANO, T.ENTEREDDEADLINE, T.PERIODTYPE, T.DOCUMENTNO, T.DOCSREQUIRED,
		T.DOCSRECEIVED, T.USEMESSAGE2FLAG, T.GOVERNINGEVENTNO, T.[STATE],
		NULL, E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, 
		E.SAVEDUEDATE, E.STATUSCODE, E.RENEWALSTATUS, E.SPECIALFUNCTION, E.INITIALFEE, E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC, 
		E.CLOSEACTION, E.RELATIVECYCLE, E.INSTRUCTIONTYPE, E.FLAGNUMBER, E.SETTHIRDPARTYON, T.COUNTRYCODE, 
		T.NEWEVENTDATE, T.NEWEVENTDUEDATE, T.USEDINCALCULATION,
		T.DATEREMIND, T.USERID, E.CRITERIANO, CR.ACTION, T.EVENTUPDATEDMANUALLY, E.ESTIMATEFLAG,
		E.EXTENDPERIOD, E.EXTENDPERIODTYPE, E.INITIALFEE2, E.PAYFEECODE2, E.ESTIMATEFLAG2,E.PTADELAY,T.IDENTITYID,E.SETTHIRDPARTYOFF,
		E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME, E.DIRECTPAYFLAG, E.DIRECTPAYFLAG2,T.LIVEFLAG,
		E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE,E.SUPPRESSCALCULATION
	from #TEMPCASEEVENT T
	join EVENTCONTROL E	on (E.EVENTNO    =T.EVENTNO
				and exists (	select NEWCRITERIANO
						from #TEMPOPENACTION OA
						where OA.[STATE]='C'
						and  (OA.CRITERIANO<>OA.NEWCRITERIANO or (OA.CRITERIANO is null and OA.NEWCRITERIANO is not null))
						and   OA.CASEID=T.CASEID
						and   OA.POLICEEVENTS=1
						and   OA.NEWCRITERIANO=E.CRITERIANO))
	join CRITERIA CR	on (CR.CRITERIANO=E.CRITERIANO)
	left join #TEMPCASEEVENT T1	on (T1.CASEID=T.CASEID
					and T1.EVENTNO=T.EVENTNO
					and T1.CYCLE  =isnull(T.CYCLE,1)
					and T1.CREATEDBYCRITERIA=E.CRITERIANO)
	where T.[STATE]='I'
	and  T1.CASEID is null"

	exec @ErrorCode=sp_executesql @sSQLString

End

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
	     -- the Event then mark the row to be calculated.  This will ultimately cause the row
	     -- to be deleted and trigger any other events that rely upon it to also recalculate.
	     ------------------------------------------------------------------------------------
	     [STATE]='C',
	DISPLAYSEQUENCE=E.DISPLAYSEQUENCE,
	IMPORTANCELEVEL=E.IMPORTANCELEVEL,
	WHICHDUEDATE=E.WHICHDUEDATE,
	COMPAREBOOLEAN=E.COMPAREBOOLEAN,
	CHECKCOUNTRYFLAG=E.CHECKCOUNTRYFLAG,
	SAVEDUEDATE=E.SAVEDUEDATE,
	STATUSCODE=E.STATUSCODE,
	RENEWALSTATUS=E.RENEWALSTATUS,
	SPECIALFUNCTION=E.SPECIALFUNCTION,
	INITIALFEE=E.INITIALFEE,
	PAYFEECODE=E.PAYFEECODE,
	CREATEACTION=E.CREATEACTION,
	STATUSDESC=E.STATUSDESC,
	CLOSEACTION=E.CLOSEACTION,
	RELATIVECYCLE=E.RELATIVECYCLE,
	INSTRUCTIONTYPE=E.INSTRUCTIONTYPE,
	FLAGNUMBER=E.FLAGNUMBER,
	SETTHIRDPARTYON=E.SETTHIRDPARTYON,
	ESTIMATEFLAG=E.ESTIMATEFLAG,
	EXTENDPERIOD=E.EXTENDPERIOD,
	EXTENDPERIODTYPE=E.EXTENDPERIODTYPE,
	INITIALFEE2=E.INITIALFEE2,
	PAYFEECODE2=E.PAYFEECODE2,
	ESTIMATEFLAG2=E.ESTIMATEFLAG2,
	PTADELAY=E.PTADELAY,
	SETTHIRDPARTYOFF=E.SETTHIRDPARTYOFF,
	CHANGENAMETYPE=E.CHANGENAMETYPE,
	COPYFROMNAMETYPE=E.COPYFROMNAMETYPE,
	COPYTONAMETYPE=E.COPYTONAMETYPE,
	DELCOPYFROMNAME=E.DELCOPYFROMNAME,
	DIRECTPAYFLAG=E.DIRECTPAYFLAG,
	DIRECTPAYFLAG2=E.DIRECTPAYFLAG2,
	LIVEFLAG=1,
	SUPPRESSCALCULATION=E.SUPPRESSCALCULATION
	from #TEMPCASEEVENT CE
	join #TEMPOPENACTION T on (T.CASEID=CE.CASEID)
	join EVENTCONTROL E    on (E.CRITERIANO=T.NEWCRITERIANO
			       and E.EVENTNO   =CE.EVENTNO)
	left join (select distinct CRITERIANO, EVENTNO
		   from DUEDATECALC
		   where OPERATOR is not null) DD
				on (DD.CRITERIANO=T.NEWCRITERIANO
				and DD.EVENTNO=CE.EVENTNO)
	left join #TEMPOPENACTION OA on(OA.CASEID=CE.CASEID
				     and OA.ACTION<>T.ACTION
				     and OA.NEWCRITERIANO=CE.CREATEDBYCRITERIA)
	left join (select distinct CRITERIANO, EVENTNO
		   from DUEDATECALC
		   where OPERATOR is not null) DD1
				on (DD1.CRITERIANO=OA.NEWCRITERIANO
				and DD1.EVENTNO=CE.EVENTNO)
	left join (select distinct DD2.CRITERIANO, DD2.EVENTNO
		   from #TEMPOPENACTION OA2
		   join DUEDATECALC DD2 on (DD2.CRITERIANO=OA2.NEWCRITERIANO)
                   where OPERATOR is not null) DD2 on (DD2.CRITERIANO<>T.NEWCRITERIANO
						   and DD2.EVENTNO=CE.EVENTNO)
	where (T.CRITERIANO<>T.NEWCRITERIANO or T.CRITERIANO is null)
	and  CE.[STATE]<>'C'
	and  CE.NEWEVENTDATE is null
	and (CE.DATEDUESAVED = 0                   OR  CE.DATEDUESAVED      is null)
	and (CE.CREATEDBYCRITERIA<>T.NEWCRITERIANO OR  CE.CREATEDBYCRITERIA is null)
	and (DD.CRITERIANO is not null             OR DD2.CRITERIANO        is null)
	-- only do the update if there is no OPENACTION with due date calculations 
	-- for the Case pointing to the CriteriaNo currently against the CaseEvent.
	and DD1.EVENTNO is null"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceCalculateCriteria',0,1,@sTimeStamp ) with NOWAIT


	If @pnDebugFlag>2
	begin
		set @sSQLString="
		Select	T.[STATE], * from #TEMPOPENACTION T
		order by T.[STATE], CASEID, ACTION"
		
		exec @ErrorCode=sp_executesql @sSQLString
		
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*
			from	#TEMPCASEEVENT T
			where	T.[STATE]<>'X'
			order by 4,1,2,3"

			exec @ErrorCode=sp_executesql @sSQLString
		End
	end

End

drop table #TEMPCRITERIA

return @ErrorCode
go

grant execute on dbo.ip_PoliceCalculateCriteria  to public
go

