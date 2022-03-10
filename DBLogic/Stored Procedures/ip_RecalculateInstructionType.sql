-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RecalculateInstructionType
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_RecalculateInstructionType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_RecalculateInstructionType.'
	Drop procedure [dbo].[ip_RecalculateInstructionType]
End
Print '**** Creating Stored Procedure dbo.ip_RecalculateInstructionType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_RecalculateInstructionType
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psInstructionType 	nvarchar(3)	= null, -- Optional if @psNameTypeCode is supplied otherwise it is mandatory
	@psAction		char(1)		= null,	-- Optional if @pnCaseKey supplied otherwise I=Insert, U=Update, D=Delete
	@pnPolicingBatchNo 	int		= null,
	@pnCaseKey 		int 		= null,
	@pnNameKey 		int 		= null,
	@pnInternalSequence	int		= null,
	@pbExistingEventsOnly	bit		= 0,
	@pbCountryNotChanged	bit		= 0,
	@pbPropertyNotChanged	bit		= 0,
	@pbNameNotChanged	bit		= 0,
	@pbRecalculateReminders	bit		= 0, 
	@psNameTypeCode		nvarchar(3)	= null	-- NameType changed against a Case which will trigger a recalulation of Events for that Case.
)
as
-- PROCEDURE:	ip_RecalculateInstructionType
-- VERSION:	20
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Generate Policing requests for the Case Events that should be recalculated as a result
--		of either the new, updated or removed standing instructions

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Feb 2006	TM	RFC3209	1	Procedure created
-- 15 Jul 2008	MF	16706	2	Increase the size of the #TEMPPOLICING.POLICINGSEQNO to cater for 
--					more than 32,000 Policing requests.
-- 20 May 2010	MF	18761	3	When a standing instruction against a Name is changed, non relevant Policing 
--					requests can be calculated.  This change will restrict the Cases to be recalculated.
-- 02 Jun 2010	MF	18761	4	Failed testing. New @psAction should not be mandatory.
-- 28 Jun 2010	MF	R929	5	Changes of standing instruction should trigger a recalculation of Case Instructions.
-- 01 Jul 2010	MF	18758	6	Increase the column size of Instruction Type to allow for expanded list.
-- 29 Nov 2010	MF	R10022	7	Insertion of POLICING row should check if an existing matching row already exists. This is
--					because multiple deletions of NAMEINSTRUCTIONS for the same Name may trigger the same  
--					Policing reclculations.
-- 29-Jul-2011	MF	R11039	8	When determining the Case Events to recalculate we need to consider
--					the possible Cycle(s) that may be calculated by looking at the calculation
--					rules and consider referenced events and their cycles.
-- 01-Aug-2011	MF	R11051	9	This change was performed in conjunction with RFC11039.
--					Allow the NameType that is being changed for a specific Case to be identified so that all
--					instruction types that reference that Name Type are considered when determining what Events
--					need to be recalcluated.
-- 03-Aug-2011	MF	R11062	10	A new parameter has been added to indicate that Policing requests should be raised for Events
--					that have reminders that can be delivered to the NameType just inserted.
-- 23-Aug-2011	MF	R11205	11	Changes of Standing Instruction at Name can be slow and generate a time out. Move this processing
--					into another stored procedure that can be started asynchronously.
-- 22-Feb-2012	LP	R11974	12	Do not create Policing Requests for Case Events where DATEDUESAVED=1.
-- 02-May-2013	MF	R13450	13	Retrofit changes to 3.5.1
-- 28 May 2013	DL	10030	14	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 18-Jul-2013	MF	R13663	15	Recalculate Events that require the existence of a Document Case for a given Name Type. The
--					change of Name against the Case for the given Name Type could now mean an Event can occur.
-- 14 Oct 2014	DL	R39102	16	Use service broker instead of OLE Automation to run the command asynchronoulsly
-- 09 Jan 2014	MF	R41513	17	Events triggered to recalculate the due date (Type of Request = 6) should also consider Events that are flagged with RECALCEVENTDATE=1
--					if the Site Control 'Policing Recalculates Event' is set to TRUE.
-- 14 Nov 2018  AV	DR-45358 18	Date conversion errors when creating cases and opening names in Chinese DB
-- 21 Jun 2019	MF	DR-49099 19	Give consideration to the CASE STATUS to determine if Policing is active before generating Policing requests.
-- 19 Feb 2020	vql	DR-57005 20	Policing and standing instructions on client server vs web behavior is different (retrofit of DR-57005).


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Create a temporary table to hold the generated POLICING request rows

Create Table #TEMPPOLICING (
		DATEENTERED          datetime 		NOT NULL,
		POLICINGSEQNO        int		identity,
		SYSGENERATEDFLAG     decimal(1,0)	NULL,
		ONHOLDFLAG           decimal(1,0)	NULL,
		ACTION               nvarchar(2)	collate database_default NULL,
		EVENTNO              int		NULL,
		CASEID               int		NULL,
		CRITERIANO           int		NULL,
		CYCLE                smallint		NULL,
		TYPEOFREQUEST        smallint		NULL,
		SQLUSER              nvarchar(60)	collate database_default NULL
		)

Declare @nErrorCode 	int
Declare @nRowCount 	int
Declare @sSQLString	nvarchar(3000)
Declare	@sSQLWhere	nvarchar(1000)

Declare	@sCountryCode	nvarchar(3)
Declare	@sPropertyType	nchar(1)
Declare	@sNameType	nvarchar(3)
Declare	@nNameNo	int
Declare	@bRecalcEvent	bit

-- Variables for background processing
declare	@nObject	int
declare	@nObjectExist	tinyint
declare	@sCommand	varchar(255)

-- Initialise variables
Set @nErrorCode = 0
Set @pnRowCount = 0
Set @nRowCount  = 0

If @nErrorCode=0
Begin
	Select @bRecalcEvent=COLBOOLEAN
	from SITECONTROL
	where CONTROLID='Policing Recalculates Event'
	
	Set @nErrorCode=@@ERROR
End

-- Generate Policing requests for the Case Events that should be recalculated as a result
-- of either the new, updated or removed standing instructions

If @nErrorCode=0
Begin
	------------------------------------------------------------------
	-- If the standing instruction has been modified at the Name level 
	-- then recalculate the CaseEvent rows for Cases linked to that 
	-- name via the relevant NameType
	-- This will be performed in a separated procedure that will be
	-- started asynchronously so as to avoid delaying processing.
	------------------------------------------------------------------
	If  @pnNameKey is not null
	and @pnCaseKey is null 
	Begin
		------------------------------------------------
		-- Build command line to run cs_GlobalNameChange 
		-- using osql/sqlcmd utility
		------------------------------------------------
		-- NOTE: 
		-- I have not used named parameters as this 
		-- would cause the @sCommand to exceed its 
		-- 255 character limit
		------------------------------------------------
		
		-- rfc39102 Modified command to be run asynchronously via service broker.
		Select @sCommand =	'dbo.ip_RecalculateInstructionTypeForName'
					+' '+CASE WHEN(@pnUserIdentityId     is null) THEN 'null' ELSE cast(@pnUserIdentityId as varchar)     END
					+','+CASE WHEN(@psInstructionType    is null) THEN 'null' ELSE ''''+@psInstructionType+''''           END
					+','+CASE WHEN(@psAction             is null) THEN 'null' ELSE ''''+@psAction+''''                    END
					+','+CASE WHEN(@pnNameKey            is null) THEN 'null' ELSE cast(@pnNameKey            as varchar) END
					+','+CASE WHEN(@pnInternalSequence   is null) THEN 'null' ELSE cast(@pnInternalSequence   as varchar) END
					+','+CASE WHEN(@pbExistingEventsOnly is null) THEN 'null' ELSE cast(@pbExistingEventsOnly as varchar) END
					+','+CASE WHEN(@pbCountryNotChanged  is null) THEN 'null' ELSE cast(@pbCountryNotChanged  as varchar) END
					+','+CASE WHEN(@pbPropertyNotChanged is null) THEN 'null' ELSE cast(@pbPropertyNotChanged as varchar) END
					+','+CASE WHEN(@pbNameNotChanged     is null) THEN 'null' ELSE cast(@pbNameNotChanged     as varchar) END

		---------------------------------------------------------------
		-- rfc39102 Run the command asynchronously using Service Broker
		--------------------------------------------------------------- 
		exec @nErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				
	End	
	-- Load a temporary table which will generate the sequence number required in the POLICING table.

	-- If the standing instruction has been modified against the Case then only recalculate Events for
	-- that specific Case.

	Else If @pnCaseKey is not null
	and @psNameTypeCode is not null
		Begin
		-----------------------------------------------
		-- RFC11051
		-- Where the CaseName row has been changed then 
		-- we need to find all of the Instruction Types
		-- that reference the modified NameType.
		-----------------------------------------------
		Set @sSQLString="
		insert into #TEMPPOLICING (DATEENTERED, SYSGENERATEDFLAG, ONHOLDFLAG, ACTION, EVENTNO, CASEID, CRITERIANO, CYCLE, TYPEOFREQUEST, SQLUSER)
		Select distinct getdate(), 1, CASE WHEN @pnPolicingBatchNo IS NOT NULL THEN 1 ELSE 0 END, OA.ACTION, EC.EVENTNO, OA.CASEID, OA.CRITERIANO, 
			isnull(	CASE WHEN(A.NUMCYCLESALLOWED>1) 
					THEN OA.CYCLE 
					ELSE Case DD.RELATIVECYCLE
						WHEN (0) Then CE1.CYCLE
						WHEN (1) Then CE1.CYCLE+1
						WHEN (2) Then CE1.CYCLE-1
							 Else isnull(DD.CYCLENUMBER,1)
					     End
				END,1),
			6, SYSTEM_USER
		From INSTRUCTIONTYPE IT
		join OPENACTION OA	on (OA.CASEID=@pnCaseKey)
		join CASES C		on (C.CASEID =OA.CASEID)
		join ACTIONS A		on (A.ACTION=OA.ACTION)
		join EVENTCONTROL EC	on (EC.CRITERIANO     =OA.CRITERIANO
					and EC.INSTRUCTIONTYPE=IT.INSTRUCTIONTYPE)
		left join DUEDATECALC DD
					on (DD.CRITERIANO=EC.CRITERIANO
					and DD.EVENTNO   =EC.EVENTNO)
		left join CASEEVENT CE1	on (CE1.CASEID =OA.CASEID
					and CE1.EVENTNO=DD.FROMEVENT)
		left join CASEEVENT CE2	on (CE2.CASEID =OA.CASEID
					and CE2.EVENTNO=EC.EVENTNO
					and CE2.CYCLE  =CASE WHEN(A.NUMCYCLESALLOWED>1) 
								THEN OA.CYCLE 
								ELSE Case DD.RELATIVECYCLE
									WHEN (0) Then CE1.CYCLE
									WHEN (1) Then CE1.CYCLE+1
									WHEN (2) Then CE1.CYCLE-1
										 Else isnull(DD.CYCLENUMBER,1)
								     End
							END)
		left join PROPERTY P	on (P.CASEID=C.CASEID)
		left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
		left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
		where (IT.NAMETYPE=@psNameTypeCode OR IT.RESTRICTEDBYTYPE=@psNameTypeCode)
		and OA.POLICEEVENTS=1
		and    ((A.ACTIONTYPEFLAG  =0 and (S.POLICEOTHERACTIONS=1 or S.STATUSCODE  is null))
		 or     (A.ACTIONTYPEFLAG  =2 and (S.POLICEEXAM        =1 or S.STATUSCODE  is null))
		 or     (A.ACTIONTYPEFLAG  =1 and (S.POLICERENEWALS    =1 or S.STATUSCODE  is null) 
					      and (S1.POLICERENEWALS   =1 or S1.STATUSCODE is null)))
		and((isnull(CE2.OCCURREDFLAG,0)=0 and isnull(CE2.DATEDUESAVED,0)=0)
		 or (@bRecalcEvent=1 and EC.RECALCEVENTDATE=1 and EC.SAVEDUEDATE between 2 and 5))
		------------------------------------------------
		-- RFC13663
		-- Recalculate Events that require the existence
		-- of a Document Case for a given Name Type
		------------------------------------------------
		UNION
		Select distinct getdate(), 1, CASE WHEN @pnPolicingBatchNo IS NOT NULL THEN 1 ELSE 0 END, OA.ACTION, EC.EVENTNO, OA.CASEID, OA.CRITERIANO, 
			CE2.CYCLE, 6, SYSTEM_USER
		From OPENACTION OA
		join ACTIONS A		on (A.ACTION=OA.ACTION)
		join EVENTCONTROLNAMEMAP EC
					on (EC.CRITERIANO=OA.CRITERIANO
					and @psNameTypeCode=isnull(EC.SUBSTITUTENAMETYPE,EC.APPLICABLENAMETYPE))
		join CASEEVENT CE2	on (CE2.CASEID =OA.CASEID
					and CE2.EVENTNO=EC.EVENTNO
					and CE2.CYCLE  =CASE WHEN(A.NUMCYCLESALLOWED>1) 
								THEN OA.CYCLE 
								ELSE CE2.CYCLE
							END)
		where OA.CASEID=@pnCaseKey
		and OA.POLICEEVENTS=1
		and isnull(CE2.OCCURREDFLAG,0)=0"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					  @psNameTypeCode	nvarchar(3),
					  @pnPolicingBatchNo	int,
					  @bRecalcEvent		bit',
					  @pnCaseKey		= @pnCaseKey,
					  @psNameTypeCode	= @psNameTypeCode,
					  @pnPolicingBatchNo	= @pnPolicingBatchNo,
					  @bRecalcEvent		= @bRecalcEvent

		Set @nRowCount=@@RowCount

		If  @pbRecalculateReminders=1
		and @nErrorCode=0
		Begin
			----------------------------------------------------------------
			-- RFC11062
			-- If CASENAME row has been added against the Case then we need
			-- to recalculate any Events that already exist as there may now
			-- be reminders that can be sent out.
			----------------------------------------------------------------
			Set @sSQLString="
			insert into #TEMPPOLICING (DATEENTERED, SYSGENERATEDFLAG, ONHOLDFLAG, ACTION, EVENTNO, CASEID, CRITERIANO, CYCLE, TYPEOFREQUEST, SQLUSER)
			Select distinct getdate(), 1, CASE WHEN @pnPolicingBatchNo IS NOT NULL THEN 1 ELSE 0 END, OA.ACTION, EC.EVENTNO, OA.CASEID, OA.CRITERIANO, CE.CYCLE, 6, SYSTEM_USER
			From OPENACTION OA
			join CASES C		on (C.CASEID=OA.CASEID)
			join ACTIONS A		on (A.ACTION=OA.ACTION)
			join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO)
			join CASEEVENT CE	on (CE.CASEID=OA.CASEID
						and CE.EVENTNO=EC.EVENTNO
						and CE.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) THEN OA.CYCLE ELSE CE.CYCLE END
						and CE.OCCURREDFLAG=0
						and ISNULL(CE.DATEDUESAVED,0)=0)
			left join PROPERTY P	on (P.CASEID=C.CASEID)
			left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
			left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
			Where OA.CASEID=@pnCaseKey
			and OA.POLICEEVENTS=1
			and    ((A.ACTIONTYPEFLAG  =0 and (S.POLICEOTHERACTIONS=1 or S.STATUSCODE  is null))
			 or     (A.ACTIONTYPEFLAG  =2 and (S.POLICEEXAM        =1 or S.STATUSCODE  is null))
			 or     (A.ACTIONTYPEFLAG  =1 and (S.POLICERENEWALS    =1 or S.STATUSCODE  is null) 
						      and (S1.POLICERENEWALS   =1 or S1.STATUSCODE is null)))
			and exists (	select 1 from REMINDERS R
					Where R.CRITERIANO=EC.CRITERIANO
					and ((R.EMPLOYEEFLAG =1 and @psNameTypeCode='EMP')
					 or  (R.SIGNATORYFLAG=1 and @psNameTypeCode='SIG')
					 or  (R.NAMETYPE     =  @psNameTypeCode)))
			and not exists(	select 1 from #TEMPPOLICING T
					where T.CASEID =CE.CASEID
					and   T.ACTION =OA.ACTION
					and   T.EVENTNO=CE.EVENTNO
					and   T.CYCLE  =CE.CYCLE)"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnCaseKey		int,
						  @psNameTypeCode	nvarchar(3),
						  @pnPolicingBatchNo	int',
						  @pnCaseKey		= @pnCaseKey,
						  @psNameTypeCode	= @psNameTypeCode,
						  @pnPolicingBatchNo	= @pnPolicingBatchNo

			Set @nRowCount=@nRowCount+@@RowCount
		End

	End	
	Else If @pnCaseKey is not null
	Begin
		If @pbExistingEventsOnly=1
		Begin
			-- If only characteristic(s) of the instruction have changed then
			-- only CaseEvent rows that exist and have a due date need to be 
			-- recalculated by Policing
			Set @sSQLString="
			insert into #TEMPPOLICING (DATEENTERED, SYSGENERATEDFLAG, ONHOLDFLAG, ACTION, EVENTNO, CASEID, CRITERIANO, CYCLE, TYPEOFREQUEST, SQLUSER)
			Select getdate(), 1, CASE WHEN @pnPolicingBatchNo IS NOT NULL THEN 1 ELSE 0 END, OA.ACTION, EC.EVENTNO, OA.CASEID, OA.CRITERIANO, CE.CYCLE, 6, SYSTEM_USER
			From  OPENACTION OA
			join CASES C		on (C.CASEID=OA.CASEID)
			join ACTIONS A		on (A.ACTION=OA.ACTION)
			join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO)
			join CASEEVENT CE	on (CE.CASEID=OA.CASEID
						and CE.EVENTNO=EC.EVENTNO
						and CE.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) THEN OA.CYCLE ELSE CE.CYCLE END)
			left join PROPERTY P	on (P.CASEID=C.CASEID)
			left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
			left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
			Where OA.CASEID=@pnCaseKey
			and OA.POLICEEVENTS=1
			and    ((A.ACTIONTYPEFLAG  =0 and (S.POLICEOTHERACTIONS=1 or S.STATUSCODE  is null))
			 or     (A.ACTIONTYPEFLAG  =2 and (S.POLICEEXAM        =1 or S.STATUSCODE  is null))
			 or     (A.ACTIONTYPEFLAG  =1 and (S.POLICERENEWALS    =1 or S.STATUSCODE  is null) 
						      and (S1.POLICERENEWALS   =1 or S1.STATUSCODE is null)))
			and EC.INSTRUCTIONTYPE = @psInstructionType
			and((isnull(CE.OCCURREDFLAG,0)=0 and isnull(CE.DATEDUESAVED,0)=0)
			 or (@bRecalcEvent=1 and EC.RECALCEVENTDATE=1 and EC.SAVEDUEDATE between 2 and 5))"
		End
		Else Begin
			Set @sSQLString="
			insert into #TEMPPOLICING (DATEENTERED, SYSGENERATEDFLAG, ONHOLDFLAG, ACTION, EVENTNO, CASEID, CRITERIANO, CYCLE, TYPEOFREQUEST, SQLUSER)
			Select distinct getdate(), 1, CASE WHEN @pnPolicingBatchNo IS NOT NULL THEN 1 ELSE 0 END, OA.ACTION, EC.EVENTNO, OA.CASEID, OA.CRITERIANO, 
				isnull(	CASE WHEN(A.NUMCYCLESALLOWED>1) 
						THEN OA.CYCLE 
						ELSE Case DD.RELATIVECYCLE
							WHEN (0) Then CE1.CYCLE
							WHEN (1) Then CE1.CYCLE+1
							WHEN (2) Then CE1.CYCLE-1
								 Else isnull(DD.CYCLENUMBER,1)
						     End
					END,1),
				6, SYSTEM_USER
			From  OPENACTION OA
			join CASES C		on (C.CASEID=OA.CASEID)
			join ACTIONS A		on (A.ACTION=OA.ACTION)
			join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO)
			left join DUEDATECALC DD
						on (DD.CRITERIANO=EC.CRITERIANO
						and DD.EVENTNO   =EC.EVENTNO)
			left join CASEEVENT CE1	on (CE1.CASEID =OA.CASEID
						and CE1.EVENTNO=DD.FROMEVENT)
			left join CASEEVENT CE2	on (CE2.CASEID =OA.CASEID
						and CE2.EVENTNO=EC.EVENTNO
						and CE2.CYCLE  =CASE WHEN(A.NUMCYCLESALLOWED>1) 
									THEN OA.CYCLE 
									ELSE Case DD.RELATIVECYCLE
										WHEN (0) Then CE1.CYCLE
										WHEN (1) Then CE1.CYCLE+1
										WHEN (2) Then CE1.CYCLE-1
											 Else isnull(DD.CYCLENUMBER,1)
									     End
								END)
			left join PROPERTY P	on (P.CASEID=C.CASEID)
			left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
			left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
			where OA.CASEID=@pnCaseKey
			and OA.POLICEEVENTS=1
			and    ((A.ACTIONTYPEFLAG  =0 and (S.POLICEOTHERACTIONS=1 or S.STATUSCODE  is null))
			 or     (A.ACTIONTYPEFLAG  =2 and (S.POLICEEXAM        =1 or S.STATUSCODE  is null))
			 or     (A.ACTIONTYPEFLAG  =1 and (S.POLICERENEWALS    =1 or S.STATUSCODE  is null) 
						      and (S1.POLICERENEWALS   =1 or S1.STATUSCODE is null)))
			and EC.INSTRUCTIONTYPE = @psInstructionType
			and((isnull(CE2.OCCURREDFLAG,0)=0 and isnull(CE2.DATEDUESAVED,0)=0)
			 or (@bRecalcEvent=1 and EC.RECALCEVENTDATE=1 and EC.SAVEDUEDATE between 2 and 5))
			union
			Select distinct getdate(), 1, CASE WHEN @pnPolicingBatchNo IS NOT NULL THEN 1 ELSE 0 END, ACTION, null, CASEID, null, CYCLE, 4, SYSTEM_USER
			FROM OPENACTION WHERE CASEID = @pnCaseKey AND POLICEEVENTS = 1
			ORDER BY ACTION"
		End
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					  @psInstructionType	nvarchar(3),
					  @pnPolicingBatchNo	int,
					  @bRecalcEvent		bit',
					  @pnCaseKey		= @pnCaseKey,
					  @psInstructionType	= @psInstructionType,
					  @pnPolicingBatchNo	= @pnPolicingBatchNo,
					  @bRecalcEvent		= @bRecalcEvent

		Set @nRowCount=@@RowCount
	End	

	-- Now load the generated POLICING rows into the live table
	If @nErrorCode=0
	and @nRowCount>0
	Begin
		Set @sSQLString="
		insert into POLICING (	DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG, ACTION,
					EVENTNO, CASEID, CRITERIANO, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID, BATCHNO)
		select T.DATEENTERED, T.POLICINGSEQNO, convert(varchar,T.DATEENTERED,126)+convert(varchar,T.POLICINGSEQNO), T.SYSGENERATEDFLAG, T.ONHOLDFLAG, T.ACTION,
			T.EVENTNO, T.CASEID, T.CRITERIANO, T.CYCLE, T.TYPEOFREQUEST, T.SQLUSER, @pnUserIdentityId, @pnPolicingBatchNo
		from #TEMPPOLICING T
		left join POLICING P	on (P.CASEID =T.CASEID
					and P.EVENTNO=T.EVENTNO
					and P.CYCLE  =T.CYCLE
					and P.SYSGENERATEDFLAG=1
					and P.TYPEOFREQUEST   =6)
		where P.CASEID is null"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					@pnPolicingBatchNo	int',
					@pnUserIdentityId 	= @pnUserIdentityId,
					@pnPolicingBatchNo	= @pnPolicingBatchNo

		Set @pnRowCount = @@RowCount
	End
End

---------------------------------------------------
-- Changes of a Standing Instruction against either
-- a Name or a Case is to trigger the recalculation
-- of the Standing Instructions against Cases.
---------------------------------------------------
If @nErrorCode=0
and @pnCaseKey is not null
Begin
	-- Case Level
	Set @sSQLString="
	Insert into CASEINSTRUCTIONSRECALC(CASEID, ONHOLDFLAG)
	select	C.CASEID, 0
	from CASES C
	left join CASEINSTRUCTIONSRECALC CI	on (CI.CASEID=C.CASEID
						and CI.ONHOLDFLAG=0)
	where C.CASEID=@pnCaseKey
	and CI.CASEID is null"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey	int',
				  @pnCaseKey=@pnCaseKey
End

If  @nErrorCode=0
and @pnNameKey is not null
Begin
	-- Name Level
	Set @sSQLString="
	Insert into CASEINSTRUCTIONSRECALC(NAMENO, ONHOLDFLAG)
	select	N.NAMENO, 0
	from NAME N
	left join CASEINSTRUCTIONSRECALC CI	on (CI.NAMENO=N.NAMENO
						and CI.ONHOLDFLAG=0)
	where N.NAMENO=@pnNameKey
	AND  CI.NAMENO is null"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey	int',
				  @pnNameKey=@pnNameKey
End

Return @nErrorCode
GO

Grant execute on dbo.ip_RecalculateInstructionType to public
GO
