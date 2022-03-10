-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateEventsAsToday
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateEventsAsToday]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateEventsAsToday.'
	Drop procedure [dbo].[csw_UpdateEventsAsToday]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateEventsAsToday...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_UpdateEventsAsToday
(	
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey				int,
	@psActionKey			nvarchar(2),
	@pnActionCycle			int,
	@pnCriteriaKey			int,
	@pnEntryNumber			int,
	@pbIsOverrideDueDates	bit = 0,
	@pnPolicingBatchNo		int = null
)
as
-- PROCEDURE:	csw_UpdateEventsAsToday
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update all events that has the "Default to System Date" attribute set (EVENTATTRIBUTE=4 or ISNULL)
--				to system date.
--				1. Update File Location, set When Moved to system date
--				2. For each events associated with current entry, add or update EVENTDATE to system date.
--				3. If @pbIsOverrideDueDate is not true, update status and renewal status
--				4. Add letters
--				5. Police each event according to settings.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Oct 2008	SF		RFC3392	1	Procedure created
-- 19 Aug 2011  DV              11069   2       Insert IDENTITYID value in ACTIVITYREQUEST table
-- 24 Oct 2011	ASH	R11460  3	Cast integer columns as nvarchar(11) data type.
-- 25 Sep 2013	KR		DR-985	4		Allow policing number to be null
-- 23 Apr 2014  SW              R32865  5       Fix Update As Today not generating Policing Request and insert OnHoldFlag based 
--                                              on whether @pnPolicingBatchNo is generated or not 
-- 14 Nov 2018  AV  75198/DR-45358	6   Date conversion errors when creating cases and opening names in Chinese DB

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 	nvarchar(4000)
Declare @dtToday		datetime
Declare @nPolicingSeq	int
Declare @dtTodayDateTime datetime

-- return some values from detail control
Declare @nRenewalStatusCode smallint
Declare @nCaseStatusCode smallint

-- Initialise variables
Set @nErrorCode 	= 0
Set @dtToday = CONVERT(nvarchar,getdate(),112)
Set @dtTodayDateTime = getdate()


If @nErrorCode = 0
Begin
	-- populate some values from detail control to be used below.
	Set @sSQLString = "
		Select	@nCaseStatusCode = STATUSCODE,
				@nRenewalStatusCode = RENEWALSTATUS
		from	DETAILCONTROL DC
		where	DC.CRITERIANO = @pnCriteriaKey 
		and		DC.ENTRYNUMBER = @pnEntryNumber"

	Exec @nErrorCode = sp_executesql @sSQLString,
					N'
					@nCaseStatusCode	smallint output,
					@nRenewalStatusCode smallint output,
					@pnCriteriaKey		int,
					@pnEntryNumber		int',
					@nCaseStatusCode	= @nCaseStatusCode output,
					@nRenewalStatusCode = @nRenewalStatusCode output,
					@pnCriteriaKey		= @pnCriteriaKey,
					@pnEntryNumber		= @pnEntryNumber
End

If @nErrorCode = 0
Begin
	-- insert a row into case location if
	-- the most recent case location for the case is not the same as the one
	-- specified in the detail control file location settings
	-- new case location does not have to be added if there wasn't a case location before
	Set @sSQLString = "
		insert into CASELOCATION (CASEID, WHENMOVED, FILELOCATION)
		select  @pnCaseKey, @dtTodayDateTime, DC1.FILELOCATION
		from	DETAILCONTROL DC1
		where	not exists (select	* 
						from		DETAILCONTROL DC
						left join (	select	CASEID, 
													MAX( convert(nvarchar(24),WHENMOVED, 21)+cast(CASEID as nvarchar(11)) ) as [DATE]
										from CASELOCATION CLMAX
										group by CASEID	
										) LASTMODIFIED	on (LASTMODIFIED.CASEID = @pnCaseKey)
						left join	CASELOCATION CL		on (CL.CASEID = @pnCaseKey
														and ( (convert(nvarchar(24),CL.WHENMOVED, 21)+cast(CL.CASEID as nvarchar(11))) = LASTMODIFIED.[DATE]
															or LASTMODIFIED.[DATE] is null ))
						where	(DC.FILELOCATION = CL.FILELOCATION 
								or (DC.FILELOCATION is null and CL.FILELOCATION is null)
								)
						and		DC.CRITERIANO = @pnCriteriaKey 
						and		DC.ENTRYNUMBER = @pnEntryNumber)
		and		DC1.CRITERIANO = @pnCriteriaKey 
		and		DC1.ENTRYNUMBER = @pnEntryNumber"
	
	Exec @nErrorCode = sp_executesql @sSQLString,
					N'
					@dtTodayDateTime	datetime,
					@pnCaseKey			int,
					@pnCriteriaKey		int,
					@pnEntryNumber		int',
					@dtTodayDateTime	= @dtTodayDateTime,
					@pnCaseKey 			= @pnCaseKey,
					@pnCriteriaKey		= @pnCriteriaKey,
					@pnEntryNumber		= @pnEntryNumber
End

If @nErrorCode = 0
Begin		
	-- for each events associated with the current criteria and entry number
	-- set event date to today, mark event as occurred 
	-- when adding new events set case event as current cycle of the action	

	Set @sSQLString = "
		Update	CASEEVENT
			Set	EVENTDATE = @dtToday,
				OCCURREDFLAG = 1
		from	CASEEVENT CE
		join	DETAILDATES DD on (DD.EVENTNO = CE.EVENTNO
								and DD.CRITERIANO = @pnCriteriaKey   		
								and	DD.ENTRYNUMBER = @pnEntryNumber)
		where	CE.CASEID = @pnCaseKey"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'
					@dtToday			datetime,
					@pnCaseKey			int,
					@pnCriteriaKey		int,
					@pnEntryNumber		int',
					@dtToday			= @dtToday,
					@pnCaseKey 			= @pnCaseKey,
					@pnCriteriaKey		= @pnCriteriaKey,
					@pnEntryNumber		= @pnEntryNumber

	Set @nRowCount = @@Rowcount
	
	If @nErrorCode = 0
	Begin
		-- add those not exists in the case 
		Set @sSQLString = "
			Insert CASEEVENT(CASEID, CYCLE, EVENTNO, EVENTDATE, OCCURREDFLAG)
			Select	@pnCaseKey,
					@pnActionCycle,
					DD.EVENTNO,
					@dtToday,
					1
			from	DETAILDATES DD
			where	DD.CRITERIANO = @pnCriteriaKey   		
			and		DD.ENTRYNUMBER = @pnEntryNumber   		
			and		DD.EVENTNO not in (
					Select	CE.EVENTNO
					from	CASEEVENT CE 
					where	CE.CASEID = @pnCaseKey)"
	
		exec @nErrorCode = sp_executesql @sSQLString,
				N'
					@dtToday			datetime,
					@pnCaseKey			int,
					@pnActionCycle		int,
					@pnCriteriaKey		int,
					@pnEntryNumber		int',
					@dtToday			= @dtToday,
					@pnCaseKey 			= @pnCaseKey,
					@pnActionCycle		= @pnActionCycle,
					@pnCriteriaKey		= @pnCriteriaKey,
					@pnEntryNumber		= @pnEntryNumber

		Set @nRowCount = @nRowCount + @@RowCount
	End

	If @nErrorCode = 0
	and @nRowCount > 0
	Begin

		-- Generate key
		Set @sSQLString = "
			Select 	@nPolicingSeq = isnull(max(POLICINGSEQNO) + 1, 0)
			from	POLICING
			where 	DATEENTERED = @dtTodayDateTime"

		exec @nErrorCode=sp_executesql @sSQLString,
							N'@nPolicingSeq		int		output,
							  @dtTodayDateTime      		datetime',
							  @nPolicingSeq		= @nPolicingSeq	output,
							  @dtTodayDateTime      = @dtTodayDateTime	
		
		-- police occurred events
		-- see ipw_InsertPolicing
		if @nErrorCode = 0
		Begin
			Set @sSQLString = "
				Insert Into [POLICING] (
					[DATEENTERED],
					[POLICINGSEQNO],
					[POLICINGNAME],	
					[SYSGENERATEDFLAG],
					[ONHOLDFLAG],
					[ACTION],
					[CASEID],
					[EVENTNO],
					[CYCLE],
					[CRITERIANO],
					[SQLUSER],
					[TYPEOFREQUEST],
					[BATCHNO],
					[IDENTITYID] )
				Select	DATEADD(millisecond,10 * ROW_NUMBER() OVER (ORDER BY CE.EVENTNO) , @dtTodayDateTime),
						@nPolicingSeq + DD.DISPLAYSEQUENCE,
						dbo.fn_DateToString(DATEADD(millisecond,10 * ROW_NUMBER() OVER (ORDER BY CE.EVENTNO) , @dtTodayDateTime),'CLEAN-DATETIME') + cast((@nPolicingSeq + DD.DISPLAYSEQUENCE) as varchar(10)),
						1,/* system generated */
						CASE WHEN(@pnPolicingBatchNo is not null) THEN 1 ELSE 0 END,	
						@psActionKey,
						@pnCaseKey,
						CE.EVENTNO,
						CE.CYCLE,
						@pnCriteriaKey,
						SYSTEM_USER,
						3, /* Police Occurred Events */	
						@pnPolicingBatchNo,
						@pnUserIdentityId
				from	DETAILDATES DD
				join	CASEEVENT CE on (CE.EVENTNO = DD.EVENTNO and CE.EVENTDATE = @dtToday and CE.CYCLE = @pnActionCycle)
				where	DD.CRITERIANO = @pnCriteriaKey and CE.CASEID = @pnCaseKey 		
				and	DD.ENTRYNUMBER = @pnEntryNumber"
		
			exec @nErrorCode=sp_executesql @sSQLString,
					N'
					@dtTodayDateTime	datetime,
					@dtToday			datetime,
					@nPolicingSeq		int,
					@pnUserIdentityId	int,
					@pnPolicingBatchNo	int,		
					@pnCaseKey			int,
					@psActionKey		nvarchar(2),
					@pnCriteriaKey		int,
					@pnEntryNumber		int,
					@pnActionCycle          int',
					@dtTodayDateTime	= @dtTodayDateTime,
					@dtToday			= @dtToday,
					@nPolicingSeq		= @nPolicingSeq,
					@pnUserIdentityId	= @pnUserIdentityId,
					@pnPolicingBatchNo	= @pnPolicingBatchNo,
					@pnCaseKey 			= @pnCaseKey,
					@psActionKey		= @psActionKey,
					@pnCriteriaKey		= @pnCriteriaKey,
					@pnEntryNumber		= @pnEntryNumber,
					@pnActionCycle          = @pnActionCycle
		End
	End
End

If @nErrorCode = 0
and @pbIsOverrideDueDates = 0
Begin
	-- update case status if the
	-- status set in details control is not null and not the same as the current case status 
	-- add activity history row if status is updated.
	exec @nErrorCode = cs_UpdateStatuses
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture				= @psCulture,
		@psProgramID			= N'WorkBnch',
		@pnCaseKey				= @pnCaseKey,
		@pnCaseStatus			= @nCaseStatusCode,
		@pnRenewalStatus		= @nRenewalStatusCode,
		@psActionKey			= @psActionKey,
		@pnCycle				= @pnActionCycle

	If @nErrorCode = 0	
	Begin
		-- update the action status
		Set @sSQLString = "
			update OPENACTION 
				set STATUSCODE = @nCaseStatusCode,
					STATUSDESC = EXTERNALDESC
			from	OPENACTION OA
			left join STATUS S on (S.STATUSCODE = @nCaseStatusCode)
			where	OA.CASEID = @pnCaseKey
			and		OA.ACTION = @psActionKey
			and		OA.CYCLE = @pnActionCycle
			and		OA.STATUSCODE is not null
			and		@nCaseStatusCode is not null
			and		OA.STATUSCODE <> @nCaseStatusCode"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'
					@nCaseStatusCode	smallint,
					@pnCaseKey			int,
					@psActionKey		nvarchar(2),
					@pnActionCycle		int',
					@nCaseStatusCode	= @nCaseStatusCode,
					@pnCaseKey 			= @pnCaseKey,
					@psActionKey		= @psActionKey,
					@pnActionCycle		= @pnActionCycle
					
	End
End

If @nErrorCode = 0
Begin
	-- add letters
	Set @sSQLString ="
		Insert into ACTIVITYREQUEST (
				WHENREQUESTED,LETTERNO,COVERINGLETTERNO,
				DELIVERYID,LETTERDATE,PROGRAMID,
				[ACTION],HOLDFLAG,ACTIVITYTYPE,
				ACTIVITYCODE,PROCESSED,
				CASEID,
				SQLUSER,
				IDENTITYID
			)
		Select	
				@dtTodayDateTime,
				DL.LETTERNO,
				L.COVERINGLETTER,
				L.DELIVERYID,
				@dtTodayDateTime,
				'WorkBnch',
				@psActionKey,
				L.HOLDFLAG,
				32, 
				3204,
				0,
				@pnCaseKey,
				SYSTEM_USER,
				@pnUserIdentityId
		from	DETAILLETTERS DL
		join	LETTER L on (DL.LETTERNO = L.LETTERNO)
		where	DL.CRITERIANO = @pnCriteriaKey   		
		and		DL.ENTRYNUMBER = @pnEntryNumber   		
	"	
	
	exec @nErrorCode = sp_executesql @sSQLString,
		N'
			@dtTodayDateTime	datetime,
			@pnCaseKey			int,
			@psActionKey		nvarchar(2),
			@pnActionCycle		int,
			@pnCriteriaKey		int,
			@pnEntryNumber		int,
			@pnUserIdentityId       int',
			@dtTodayDateTime	= @dtTodayDateTime,
			@pnCaseKey 			= @pnCaseKey,
			@pnActionCycle		= @pnActionCycle,
			@psActionKey		= @psActionKey,
			@pnCriteriaKey		= @pnCriteriaKey,
			@pnEntryNumber		= @pnEntryNumber,
			@pnUserIdentityId       = @pnUserIdentityId

End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateEventsAsToday to public
GO
