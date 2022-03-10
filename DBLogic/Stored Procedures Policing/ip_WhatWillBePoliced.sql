-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_WhatWillBePoliced
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_WhatWillBePoliced]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_WhatWillBePoliced.'
	drop procedure dbo.ip_WhatWillBePoliced
end
print '**** Creating procedure dbo.ip_WhatWillBePoliced...'
print ''
go

set ANSI_NULLS on
go

create procedure dbo.ip_WhatWillBePoliced
			@pnUserIdentityId		int = null,
			@pdtPolicingDateEntered		datetime,	-- Key to Policing row
			@pnPolicingSeqNo		int,		-- Key to Policing row
			@pbReturnCaseList		bit = 0,	-- Indicates that the actual Cases that will be policed should be returned
			@pbRaiseCasePolicingRequest	bit = 0,	-- Indicates that the procedure should generate a policing request for each Case.
			@pnNumberOfCases		int = 0	output	-- The output parameter that will return the case count.

as
-- PROCEDURE :	ip_WhatWillBePoliced
-- VERSION :	6
-- DESCRIPTION:	A procedure that determines the number of Cases that will be Policed for a given Policing Request.
--		Optionally, a list of the actual Cases to be policed may be returned.
--		Optionally, a Policing Request for individual Cases can be generated.
--		Note that this stored procedure calls the actual Policing stored procedures to determine the cases:
--			ip_PolceGetEvents
--			ip_PoliceGetOpenActions
--		which Policing uses to resolve the parameters provided in the POLICING request row to determine
--		what will actually be policed.
--======================================================================================================================
-- WARNING:	If the option to generate individual Policing requests per Case is used - @pbRaiseCasePolicingRequest=1
--		then the Policing requests generated may result in multiple entries per Case if the Events for that case
--		are being triggered to recalculate.  Similarly, separate recalculations of Actions can also generate
--		multiple rows per case as each Action will be recalculated.
--======================================================================================================================
--
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Jul 2016	MF	52844	1	Procedure created
-- 08 Sep 2016	MF	63849	2	Allow the generation of Case level policing for a saved Policing Request
-- 15 Mar 2017	MF	70049	3	Allow Renewal Status to be separately specified to be updated by an Event.
-- 14 Nov 2018  AV	DR-45358 4	Date conversion errors when creating cases and opening names in Chinese DB
-- 28 Oct 2019	MF	DR-53563 5	Change to handle Policing requests generated by Law Update even though these have SYSGENERATEDFLAG=1.	
-- 19 May 2020	DL	DR-58943 6	Ability to enter up to 3 characters for Number type code via client server	

-- User Defined Errors
-- ===================
-- 	-1	No entry in POLICING table

set nocount on

-- Create a temporary table to load the Status details of the Case.  This information may be updated
-- as the Case progresses.  The Status controls

	create table #TEMPCASES (
            CASEID               int		NOT NULL,
            STATUSCODE           int            NULL,
            RENEWALSTATUS        int            NULL,
	    REPORTTOTHIRDPARTY   decimal(1,0)	NULL,
            PREDECESSORID        int            NULL,
	    ACTION		 nvarchar(2)	collate database_default NULL,
	    EVENTNO		 int		NULL,
	    CYCLE		 smallint	NULL,
            CASETYPE             nchar(1)	collate database_default NULL,
            PROPERTYTYPE         nchar(1)	collate database_default NULL,
            COUNTRYCODE          nvarchar(3)	collate database_default NULL,
            CASECATEGORY         nvarchar(2)	collate database_default NULL,
            SUBTYPE              nvarchar(2)	collate database_default NULL,
            BASIS                nvarchar(2)	collate database_default NULL,
            REGISTEREDUSERS      nchar(1)	collate database_default NULL,
            LOCALCLIENTFLAG      decimal(1,0)	NULL,
            EXAMTYPE             int		NULL,
            RENEWALTYPE          int		NULL,
            INSTRUCTIONSLOADED   tinyint	NULL,
	    ERRORFOUND           bit            NULL,
	    RENEWALACTION	 nvarchar(2)	collate database_default NULL,
	    RENEWALEVENTNO	 int		NULL,
	    RENEWALCYCLE	 smallint	NULL,
	    RECALCULATEPTA	 bit		default(0),
	    IPODELAY 		 int		default(0),
	    APPLICANTDELAY 	 int		default(0),
            USERID               nvarchar(255)  collate database_default NULL,
	    IDENTITYID		 int		NULL,
	    CASESEQUENCENO	 int		identity(1,1),
	    OFFICEID		 int		NULL,
            OLDSTATUSCODE        int            NULL,	--SQA18736
            OLDRENEWALSTATUS     int            NULL,	--SQA18736
	    CASELOGSTAMP	 datetime	NULL,	--RFC10929
	    PROPERTYLOGSTAMP	 datetime	NULL	--RFC10929
	)

-- Create a temporary table to be loaded with Open Action details.
-- The temporary table will also contain the ncharacteristics of the Case used to determine the Criteria.  This 
-- CASE information is redundant to improve overall performance.

	create table #TEMPOPENACTION (
            CASEID               int		NOT NULL,
            ACTION               nvarchar(2)	collate database_default NOT NULL,
            CYCLE                smallint	NOT NULL,
            LASTEVENT            int		NULL,
            CRITERIANO           int		NULL,
            DATEFORACT           datetime	NULL,
            NEXTDUEDATE          datetime	NULL,
            POLICEEVENTS         decimal(1,0)	NULL,
            STATUSCODE           smallint	NULL,
            STATUSDESC           nvarchar(50)	collate database_default NULL,
            DATEENTERED          datetime	NULL,
            DATEUPDATED          datetime	NULL,
            CASETYPE             nchar(1)	collate database_default NULL,
            PROPERTYTYPE         nchar(1)	collate database_default NULL,
            COUNTRYCODE          nvarchar(3)	collate database_default NULL,
            CASECATEGORY         nvarchar(2)	collate database_default NULL,
            SUBTYPE              nvarchar(2)	collate database_default NULL,
            BASIS                nvarchar(2)	collate database_default NULL,
            REGISTEREDUSERS      nchar(1)	collate database_default NULL,
            LOCALCLIENTFLAG      decimal(1,0)	NULL,
            EXAMTYPE             int		NULL,
            RENEWALTYPE          int		NULL,
	    CASEOFFICEID	 int		NULL,
            NEWCRITERIANO        int		NULL,
            USERID               nvarchar(255)  collate database_default NULL,
            [STATE]              nvarchar(2)	collate database_default NULL,	/* C-Calculate, C1-Calculation Done, E-Error	*/
	    IDENTITYID		 int		NULL,
	    ACTIONSEQUENCENO	 int		identity(1,1)
	)
-- Create a temporary table to be loaded with Case Event details.

	CREATE TABLE #TEMPCASEEVENT (
            CASEID               int		NOT NULL,
            DISPLAYSEQUENCE      smallint	NULL,
            EVENTNO              int		NOT NULL,
            CYCLE                smallint	NOT NULL,
            OLDEVENTDATE         datetime	NULL,
            OLDEVENTDUEDATE      datetime	NULL,
            DATEREMIND           datetime	NULL,
            DATEDUESAVED         decimal(1,0)	NULL,
            OCCURREDFLAG         decimal(1,0)	NULL,
            CREATEDBYACTION      nvarchar(2)	collate database_default NULL,
            CREATEDBYCRITERIA    int		NULL,
            ENTEREDDEADLINE      smallint	NULL,
            PERIODTYPE           nchar(1)	collate database_default NULL,
            DOCUMENTNO           smallint	NULL,
            DOCSREQUIRED         smallint	NULL,
            DOCSRECEIVED         smallint	NULL,
            USEMESSAGE2FLAG      decimal(1,0)	NULL,
	    SUPPRESSREMINDERS    decimal(1,0)   NULL,
	    OVERRIDELETTER       int            NULL,
            GOVERNINGEVENTNO     int		NULL,
            [STATE]              nvarchar(2) 	collate database_default NOT NULL,-- C=calculate; I=insert; D=delete
            ADJUSTMENT           nvarchar(4) 	collate database_default NULL,	 -- any adjustment to be made to the date
            IMPORTANCELEVEL      nvarchar(2)	collate database_default NULL,
            WHICHDUEDATE         nchar(1) 	collate database_default NULL,
            COMPAREBOOLEAN       decimal(1,0) 	NULL,
            CHECKCOUNTRYFLAG     int		NULL,
            SAVEDUEDATE          smallint	NULL,
            STATUSCODE           smallint	NULL,
	    RENEWALSTATUS	 smallint	NULL,
            SPECIALFUNCTION      nchar(1)	collate database_default NULL,
            INITIALFEE           int		NULL,
            PAYFEECODE           nchar(1)	collate database_default NULL,
            CREATEACTION         nvarchar(2)	collate database_default NULL,
            STATUSDESC           nvarchar(50) 	collate database_default NULL,
            CLOSEACTION          nvarchar(2)	collate database_default NULL,
            RELATIVECYCLE        smallint	NULL,
            INSTRUCTIONTYPE      nvarchar(3)	collate database_default NULL,
            FLAGNUMBER           smallint	NULL,
            SETTHIRDPARTYON      decimal(1,0)	NULL,
            COUNTRYCODE          nvarchar(3)	collate database_default NULL,	-- used to get Due Date rule
            NEWEVENTDATE         datetime 	NULL,
            NEWEVENTDUEDATE      datetime 	NULL,
            NEWDATEREMIND        datetime 	NULL,
            USEDINCALCULATION	 nchar(1)	collate database_default NULL,	-- if Y then removing the row will trigger recalculations	
            LOOPCOUNT		 smallint	NULL,
	    REMINDERTOSEND	 smallint	NULL,
            UPDATEFROMPARENT	 tinyint	NULL,
            PARENTEVENTDATE      datetime       NULL,
            USERID		 nvarchar(255)	collate database_default NULL,
            EVENTUPDATEDMANUALLY tinyint        NULL,	-- 15/08/2001 MF  Flag to indicate that the Event was updated outside of Policing
            CRITERIANO           int            NULL,	-- 20/09/2001 MF  Holds the CriteriaNo the Event is attached to
            ACTION               nvarchar(2)	collate database_default NULL,	-- 20/09/2001 MF  Holds the Action the Event is attached to
	    ESTIMATEFLAG         decimal(1,0)	NULL,	-- SQA7367
            EXTENDPERIOD         smallint	NULL,	-- SQA7532
            EXTENDPERIODTYPE     nchar(1)	collate database_default NULL,	-- SQA7532
            INITIALFEE2          int		NULL,	-- SQA7627
            PAYFEECODE2          nchar(1)	collate database_default NULL,	-- SQA7627
            ESTIMATEFLAG2        decimal(1,0)   NULL,
	    PTADELAY		 smallint	NULL,	-- SQA8260
	    IDENTITYID		 int		NULL,
	    SETTHIRDPARTYOFF	 bit		NULL,
            CHANGENAMETYPE	 nvarchar(3)	collate database_default NULL,
            COPYFROMNAMETYPE     nvarchar(3)	collate database_default NULL,
            COPYTONAMETYPE       nvarchar(3)	collate database_default NULL,
            DELCOPYFROMNAME      bit		NULL,
	    DIRECTPAYFLAG	 bit		NULL,
	    DIRECTPAYFLAG2	 bit		NULL,
	    FROMCASEID		 int		NULL,
	    LIVEFLAG		 bit		default(0),
	    RESPNAMENO		 int		NULL,
	    RESPNAMETYPE	 nvarchar(3)	collate database_default NULL,
	    LOADNUMBERTYPE	 nvarchar(3)	collate database_default NULL,	--SQA17773
	    PARENTNUMBER	 nvarchar(36)	collate database_default NULL,	--SQA17773
	    RECALCEVENTDATE	 bit		NULL,	-- SQA19252
	    SUPPRESSCALCULATION  bit		NULL,	-- SQA21404
	    DELETEDPREVIOUSLY	 tinyint	NULL,	-- RFC40815 Counter used to avoid continuously triggering an Event as deleted	
	    EVENTSEQUENCENO	 int		identity(1,1)
	)


DECLARE		@ErrorCode		int,
		@nTransNo		int,
		@TranCountStart 	int,
		@nRowCount		int,
		@bHexNumber		varbinary(128)

-- The following variables are used to hold the contents of the POLICING
-- row whose key was passed as parameters
DECLARE		@sPolicingName		nvarchar(40),
		@nSysGeneratedFlag	decimal(1,0),
		@nOnHoldFlag		decimal(1,0),
		@sOfficeId		nvarchar(254),
		@sErrorMessage		nvarchar(4000),
		@sIRN			nvarchar(30),
		@sPropertyType		nchar(1),
		@sCountryCode		nvarchar(3),
		@dtDateOfAct		datetime,
		@sAction		nvarchar(2),
		@nEventNo		int,
		@sNameType		nvarchar(3),
		@nNameNo		int,
		@sCaseType		nchar(1),
		@sCaseCategory		nvarchar(2),
		@sSubtype		nvarchar(2),
		@dtFromDate		datetime,
		@dtUntilDate		datetime,
		@nNoOfDays		smallint,
		@dtLetterDate		datetime,
		@nCriticalOnlyFlag	decimal(1,0),
		@nUpdateFlag		decimal(1,0),
		@nReminderFlag		decimal(1,0),
		@nAdhocFlag		decimal(1,0),
		@nCriteriaFlag		decimal(1,0),
		@nDueDateFlag		decimal(1,0),
		@nCalcReminderFlag	decimal(1,0),
		@nExcludeProperty	decimal(1,0),
		@nExcludeCountry	decimal(1,0),
		@nExcludeAction		decimal(1,0),
		@sEmployeeNo		int,
		@nCaseid		int,
		@nCriteriano		int,
		@nCycle			smallint,
		@nTypeOfRequest		smallint,
		@nCountryFlags		int,
		@nFlagSetOn		decimal(1,0),
		@sSqlUser		nvarchar(30),
		@nDueDateOnlyflag	decimal(1,0),
		@nLetterFlag		decimal(1,0),
		@nDueDateRange		smallint,
		@nLetterAfterDays	smallint,
		@bRecalcEventDate	bit,
		@bDocumentsRequired	bit,
		@bErrorInserted		bit

-- Initialise the errorcode and then set it after each SQL Statement

Set 	@ErrorCode 	= 0
Set	@TranCountStart = 0

-- Read the POLICING table for the parameters passed and save the contents in variables.  These will be
-- used to determine what should be policed and what type of processing is required.

if @ErrorCode=0
Begin
	Select	@sPolicingName		= POLICINGNAME,
		@nSysGeneratedFlag	= isnull(SYSGENERATEDFLAG,0),
		@nOnHoldFlag		= isnull(ONHOLDFLAG,0),
		@sIRN			= IRN,
		@sOfficeId		= replace(CASEOFFICEID,';',','),	-- semicolons to be replaced by comma
		@sPropertyType		= PROPERTYTYPE,
		@sCountryCode		= COUNTRYCODE,
		@dtDateOfAct		= DATEOFACT,
		@sAction		= ACTION,
		@nEventNo		= EVENTNO,
		@sNameType		= NAMETYPE,
		@nNameNo		= NAMENO, 
		@sCaseType		= CASETYPE,
		@sCaseCategory		= CASECATEGORY, 
		@sSubtype		= SUBTYPE,
		@dtFromDate		= FROMDATE, 
		@dtUntilDate		= UNTILDATE,
		@nNoOfDays		= NOOFDAYS, 
		@dtLetterDate		= LETTERDATE,
		@nCriticalOnlyFlag	= isnull(CRITICALONLYFLAG,0),
		@nUpdateFlag		= isnull(UPDATEFLAG,0),
		@nReminderFlag		= isnull(REMINDERFLAG,0),
		@nAdhocFlag		= CASE WHEN(ADHOCNAMENO is not null)
						THEN 1
						ELSE isnull(ADHOCFLAG,0)
					  END,
		@nCriteriaFlag		= isnull(CRITERIAFLAG,0),
		@nDueDateFlag		= isnull(DUEDATEFLAG,0),
		@nCalcReminderFlag	= isnull(CALCREMINDERFLAG,0),
		@nExcludeProperty	= isnull(EXCLUDEPROPERTY,0),
		@nExcludeCountry	= isnull(EXCLUDECOUNTRY,0),
		@nExcludeAction		= isnull(EXCLUDEACTION,0),
		@sEmployeeNo		= EMPLOYEENO,
		@nCaseid		= CASEID,
		@nCriteriano		= CRITERIANO,
		@nCycle			= CYCLE,
		@nTypeOfRequest		= TYPEOFREQUEST,
		@nCountryFlags		= COUNTRYFLAGS,
		@nFlagSetOn		= FLAGSETON,
		@sSqlUser		= SQLUSER, 
		@nDueDateOnlyflag	= isnull(DUEDATEONLYFLAG,0),
		@nLetterFlag		= isnull(LETTERFLAG,0),
		@nDueDateRange		= SC1.COLINTEGER,
		@nLetterAfterDays	= SC2.COLINTEGER,
		@bRecalcEventDate	= CASE WHEN(RECALCEVENTDATE=1) THEN 1 ELSE coalesce(SC3.COLBOOLEAN,0) END -- RFC39157
	From 	POLICING
	left join
		SITECONTROL SC1	on (SC1.CONTROLID='Due Date Range')
	left join
		SITECONTROL SC2 on (SC2.CONTROLID='LETTERSAFTERDAYS')
	left join
		SITECONTROL SC3 on (SC3.CONTROLID='Policing Recalculates Event')
	Where	DATEENTERED	= @pdtPolicingDateEntered
	and	POLICINGSEQNO	= @pnPolicingSeqNo

	Select  @ErrorCode=@@Error,
		@nRowCount=@@Rowcount

	If  @nRowCount=0
	and @ErrorCode=0
	Begin
		set @ErrorCode=-1
	End
End

-- Calculate the FromDate, UntilDate and LetterDate if they have not been explicitly entered.

If  @dtFromDate is NULL
and @ErrorCode=0
Begin
	If @nNoOfDays is Null
	Or @nNoOfDays > -1
	Begin
		-- Set the FromDate to the current system date if the NoOfDays is either NULL or a positive number
		Set @dtFromDate = convert(nvarchar,getdate(),112)
	End
	Else Begin
		-- If the NoOfDays is negative then set the UntilDate to the current system date and subtract 
		-- the NoOfDays from it to get the FromDate
		Set @dtUntilDate = convert(nvarchar,getdate(),112)
		Set @dtFromDate  = dateadd(day, @nNoOfDays, @dtUntilDate)
	End
End

-- If the UntilDate has not been set then add the NoOfDays less 1 to the FromDate
If  @dtUntilDate is NULL
and @ErrorCode=0
Begin
	If  @nNoOfDays is not Null
	Begin
		Set @dtUntilDate = dateadd(day, isnull(@nNoOfDays-1, 0), @dtFromDate)
	End
	Else If @dtFromDate>getdate()
	Begin
		Set @dtUntilDate = @dtFromDate
	End
	Else Begin
		Set @dtUntilDate = convert(nvarchar,getdate(),112)
	End
	
End

-- If the LetterDate has not been set then add the LetterAfterDays from SiteControl to the UntilDate
-- to get the date to use on any generated letters
If  @dtLetterDate is NULL
and @ErrorCode=0
Begin
	Set @dtLetterDate = dateadd(day, isnull(@nLetterAfterDays, 0), @dtUntilDate)
End

-- Getting the Cases and Events to be initialy Policed will depend upon the parameters of the 
-- Policing table.  There are 4 separate approaches :
--  1.	For Recalculations called from Policing Request
--	===============================================
--	Get the Cases that match the selection criteria followed by the Openactions for those Cases then
--	return the CaseEvents to be recalculated.
--
--  2.	For Non Recalculation Policing called from Policing Request
--	===========================================================
--	Get the CaseEvents to be policed within the selection criteria, then get the Cases and Openactions.
--
--

If @ErrorCode=0
Begin
	If  (@nCriteriaFlag    =1 OR @nDueDateFlag=1 OR @nCalcReminderFlag=1)
	and (@nSysGeneratedFlag=0 OR @nCaseid is null)				--DR-53563
	Begin
		--------------------------------------------------
--  		For Recalculations called from Policing Request
		--================================================
		-- Get the Cases that match the selection criteria followed by the OpenActions

		set transaction isolation level read uncommitted

		execute @ErrorCode = dbo.ip_PoliceGetOpenActions
							@nRowCount	OUTPUT,
							0,
							@sIRN,
							@sOfficeId,
							@sPropertyType,
							@sCountryCode,
							@dtDateOfAct,
							@sAction,
							@nEventNo,
							@sNameType,
							@nNameNo,
							@sCaseType,
							@sCaseCategory,
							@sSubtype,
							@nExcludeProperty,
							@nExcludeCountry,
							@nExcludeAction,
							@nCaseid,
							@nTypeOfRequest,
							@nCriteriaFlag,
							@nDueDateFlag,
							@nCalcReminderFlag,
							@bRecalcEventDate,
							NULL
	End
	Else If @nSysGeneratedFlag=0
	Begin
		--------------------------------------------------------------
--  		For Non Recalculation Policing called from Policing Request
		--============================================================
		-- Get the CaseEvents to be policed for the selection criteria, 
		-- then get the Cases and OpenActions.

		set transaction isolation level read uncommitted

		execute @ErrorCode = dbo.ip_PoliceGetEvents
							@nRowCount	OUTPUT,
							0,
							@sIRN,
							@sOfficeId,
							@sPropertyType,
							@sCountryCode,
							@dtDateOfAct,
							@sAction,
							@nEventNo,
							@sNameType,
							@nNameNo,
							@sCaseType,
							@sCaseCategory,
							@sSubtype,
							@nExcludeProperty,
							@nExcludeCountry,
							@nExcludeAction,
							@nCaseid,
							@nTypeOfRequest,
							@dtFromDate,
							@dtUntilDate,
							@nDueDateRange
	End
	
	If @ErrorCode=0
	Begin
		Select @pnNumberOfCases=COUNT(*)
		from #TEMPCASES
		
		set @ErrorCode=@@ERROR
	End
	
	If @ErrorCode=0
	and @pbReturnCaseList=1
	Begin
		Select C.IRN, C.CASEID
		from #TEMPCASES T
		join CASES C on (C.CASEID=T.CASEID)
		order by C.IRN
	
		Set @ErrorCode=@@ERROR
	End
		
End

--------------------------------------------------------
-- Generate individual POLICING requests for each Case
-- that would be picked up in the batch Policing Request
--------------------------------------------------------
If  @ErrorCode=0
and @pnNumberOfCases>0
and @pbRaiseCasePolicingRequest=1
Begin
	----------------------------------------------
	-- If User IdentityId has not been passed as
	-- a parameter then see if it has already been
	-- associated with the database connection.
	----------------------------------------------
	If @pnUserIdentityId is null
	Begin	
		select	@pnUserIdentityId=CASE WHEN(substring(context_info,1,4) <>0x0000000) THEN cast(substring(context_info,1,4)  as int) END
		from master.dbo.sysprocesses
		where spid=@@SPID
		and substring(context_info,1, 4)<>0x0000000
		
		Set @ErrorCode=@@Error
	End
		 
	-----------------------------------------------------------------------------
	-- A separate database transaction will be used to insert the TRANSACTIONINFO
	-- row to ensure the lock on the database is kept to a minimum as this table
	-- will be used extensively by other processes.
	-----------------------------------------------------------------------------
	If @ErrorCode=0
	Begin
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION

		-----------------------------------------------------------------------------
		-- Allocate a transaction id that can be accessed by the audit logs
		-- for inclusion.
		
		-- When inserting a row into TRANSACTIONINFO default the TRANSACTIONREASONNO
		-- TRANSACTIONMESSAGENO if a valid row exists in the associated table.
		-----------------------------------------------------------------------------
		Insert into TRANSACTIONINFO(TRANSACTIONDATE,TRANSACTIONREASONNO, TRANSACTIONMESSAGENO) 
		Select getdate(), R.TRANSACTIONREASONNO, M.TRANSACTIONMESSAGENO
		from (select 1 as COL1) A
		left join TRANSACTIONREASON  R on (R.TRANSACTIONREASONNO=-1)
		left join TRANSACTIONMESSAGE M on (M.TRANSACTIONMESSAGENO=2)
		
		Select  @nTransNo=SCOPE_IDENTITY(),
			@ErrorCode=@@Error

		--------------------------------------------------------------
		-- Load a common area accessible from the database server with
		-- the UserIdentityId and the TransactionNo just generated.
		-- This will be used by the audit logs.
		--------------------------------------------------------------

		Set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4)+ 
				substring(cast(isnull(@nTransNo,'') as varbinary),1,4)
		SET CONTEXT_INFO @bHexNumber

		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End
	
	If @ErrorCode=0
	Begin
		-- Determine  
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION
		
		If @nCriteriaFlag=1
		Begin
			--------------------------------------
			-- Open Actions are to be recalculated
			--------------------------------------
			insert into POLICING(DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG, ACTION, EVENTNO, CYCLE, CASEID, TYPEOFREQUEST, SQLUSER, IDENTITYID, RECALCEVENTDATE, PENDING, UPDATEFLAG)
			select	distinct
				GETDATE(), 
				OA.ACTIONSEQUENCENO, 
				substring(@sPolicingName,1,35-len(T.CASEID)-len(OA.ACTION)-len(OA.CYCLE))+' '+cast(T.CASEID as nvarchar)+'['+OA.ACTION+']' +'('+cast(OA.CYCLE as nvarchar)+')',
				1, 
				9, 
				OA.ACTION, 
				NULL,
				NULL, 
				T.CASEID, 
				4,								-- Type of Request to Recalculate an Action
				isnull(@sSqlUser,SYSTEM_USER),
				@pnUserIdentityId,
				@bRecalcEventDate, 
				0,
				@nUpdateFlag
			from #TEMPCASES T
							    
			join #TEMPOPENACTION OA		    on (OA.CASEID      =T.CASEID
							    and OA.POLICEEVENTS=1
							    and OA.ACTION      =ISNULL(@sAction,OA.ACTION))
							    
			left join POLICING P on (P.POLICINGNAME=substring(@sPolicingName,1,35-len(T.CASEID)-len(OA.ACTION)-len(OA.CYCLE))+' '+cast(T.CASEID as nvarchar)+'['+OA.ACTION+']' +'('+cast(OA.CYCLE as nvarchar)+')')

			where P.POLICINGNAME is null	-- Avoid creation of POLICING row that would give a duplicate key error.
		End
		
		Else Begin
			-------------------------------------
			-- Case Events are to be recalculated
			-------------------------------------
			with CTE_CaseEvent (CASEID, EVENTNO, CYCLE, OCCURREDFLAG, EVENTSEQUENCENO)
			as (	select CASEID, EVENTNO, CYCLE, OCCURREDFLAG, MIN(EVENTSEQUENCENO)
				from #TEMPCASEEVENT
				group by CASEID, EVENTNO, CYCLE, OCCURREDFLAG)
				
			insert into POLICING(DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG, ACTION, EVENTNO, CYCLE, CASEID, TYPEOFREQUEST, SQLUSER, IDENTITYID, RECALCEVENTDATE, PENDING, UPDATEFLAG)
			select	distinct
				GETDATE(), 
				isnull(CE.EVENTSEQUENCENO, OA.ACTIONSEQUENCENO), 
				substring(@sPolicingName,1,35-len(T.CASEID)-len(isnull(CE.EVENTNO,''))-len(isnull(CE.CYCLE,'')))+' '+cast(T.CASEID as nvarchar)+CASE WHEN(CE.CYCLE is not null) THEN '['+cast(CE.EVENTNO as nvarchar)+']' +'('+cast(CE.CYCLE as nvarchar)+')' ELSE '' END,
				1, 
				9, 
				NULL, 
				isnull(CE.EVENTNO,@nEventNo),
				 
				CASE WHEN(CE.EVENTNO is not null) THEN CE.CYCLE
				     WHEN(@nEventNo  is not null) THEN 1
								  ELSE NULL 
				END, 
				
				T.CASEID, 
				CASE WHEN(@nCriteriaFlag=1) THEN 4 ELSE 6 END,			 -- Type of Request determined by Recalculate Criteria flag
				isnull(@sSqlUser,SYSTEM_USER),
				@pnUserIdentityId,
				@bRecalcEventDate, 
				0,
				@nUpdateFlag
			from #TEMPCASES T
							    
			join #TEMPOPENACTION OA		    on (OA.CASEID      =T.CASEID
							    and OA.POLICEEVENTS=1
							    and OA.ACTION      =ISNULL(@sAction,OA.ACTION))
							    
			left join CTE_CaseEvent CE	    on (CE.CASEID =T.CASEID)
			
			join EVENTCONTROL EC		    on (EC.CRITERIANO=OA.CRITERIANO
							    and EC.EVENTNO=ISNULL(CE.EVENTNO,@nEventNo))
							    
			left join POLICING P on (P.POLICINGNAME=substring(@sPolicingName,1,35-len(T.CASEID)-len(isnull(CE.EVENTNO,''))-len(isnull(CE.CYCLE,'')))+' '+cast(T.CASEID as nvarchar)+CASE WHEN(CE.CYCLE is not null) THEN '['+cast(CE.EVENTNO as nvarchar)+']' +'('+cast(CE.CYCLE as nvarchar)+')' ELSE '' END)

			where P.POLICINGNAME is null						 -- Avoid creation of POLICING row that would give a duplicate key error.
			and( CE.OCCURREDFLAG=0							 -- Recalculate an existing Due Date
			 or (CE.CASEID is null and @nEventNo is not null)			 -- or calculate the due date for a specified Event where the Event does not exist for the case
			 or (CE.OCCURREDFLAG=1 and @bRecalcEventDate=1 and EC.RECALCEVENTDATE=1))-- or recalculate an 
		End

		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End
End

drop table #TEMPCASES
drop table #TEMPOPENACTION
drop table #TEMPCASEEVENT

return @ErrorCode
go

grant execute on dbo.ip_WhatWillBePoliced  to public
go