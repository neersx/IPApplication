-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdatePriorityEvents
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdatePriorityEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_UpdatePriorityEvents.'
	Drop procedure [dbo].[cs_UpdatePriorityEvents]
	Print '**** Creating Stored Procedure dbo.cs_UpdatePriorityEvents...'
	Print ''
End
go

SET QUOTED_IDENTIFIER off
go

CREATE PROCEDURE dbo.cs_UpdatePriorityEvents
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,		-- Mandatory
	@pnPolicingBatchNo	int = null,	-- Optional policing batchno.
	@pbDebug		bit = 0
)
-- PROCEDURE :	cs_UpdatePriorityEvents
-- VERSION :	16
-- DESCRIPTION:	Examines the RelatedCases for the supplied CaseId 
--		and establishes whether any of the relationships affect the priority events for the supplied case.
--		If so, the relevant priority event(s) for the supplied Case are created or updated and policed.
-- SCOPE:	CPA.net, InPro.net
-- CALLED BY :	DataAccess directly

-- MODIFICATIONS :
-- Date		Who	Version	Change	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 AUG 2002	SF	1		Procedure created
-- 12 AUG 2002	SF	2		Made changes re:JK's feedback.
--					1. removed a redundant select when looking for existing case event.
--					2. policing is still kept separately in a different loop.
-- 28 OCT 2002	SF	3		Changed Parameter @pnCaseId to @pnCaseKey (for standard conformance)
-- 17 MAR 2003	SF	6	R084	1. Add @pnPolicingBatchNo
--					2. Change to work with new ip_InsertPolicing
--					3. Policing will be performed from the calling code.
-- 15 APR 2005	TM	7	R2514	Only process events that are not marked as read only.
-- 22 Dec 2005	TM	8	R3200	If the Earliest Date Flag is OFF. 
-- 24 Jul 2009	MF	9	16548	The FROMEVENTNO will now identify the Event from a related Case that will be pushed
--					into the child Case.
-- 09 Sep 2010	SF	10	R9751	If Earliest Date Flag is on, take the date entered in the related case.
-- 17 Dec 2010	DV	11	R10107	Changed logic so that the correct EVENT will not be determined from FROMEVENTNO. 
--					Only the date will be determined from FROMEVENTNO in  case the related case exists in the database.
-- 13 Oct 2011	MF	12	R11416	Where multiple Events associated with more than one Relationship were to be determined, it was possible
--					that only one EventNo would be considered if the date that should have updated the second or subsequent
--					events was an earlier date. Also taking the opportunity to improve the logic to make it more efficient
--					by removing the looping through each row.
-- 19 Aug 2014	LP	13	R33074	Do not update Priority Date if there is no FROMEVENTNO configured against the Relationship
-- 04-Sep-2014	LP	14	R38642	Extend to also recalculate where the EVENTDATE is NULL.
-- 18-Nov-2014	LP	15	R41354	Set OCCURREDFLAG to 1 when updating the Priority Date.
-- 21-Oct-2019	DL	16 DR-52908 Error after adding related cases when creating a new case

as

declare @nErrorCode		int
declare @nRowCount		int

declare @tbEvents table ( 
		EVENTNO		int		not null,
		EVENTDATE	datetime	not null, 
		EARLIESTDATE	tinyint		not null)	-- has to be tinyint and not bit so can use with MAX function

declare @tbEarliestEvents table ( 
		EVENTNO		int		not null,
		EVENTDATE	datetime	not null,
		CYCLE		smallint	null,		-- Cycle of existing CASEEVENT row to be updated
		SEQUENCENO	tinyint		identity(1,1))	-- This will be used in the generated Policing rows

set @nErrorCode = 0
set @nRowCount = 0

if @nErrorCode = 0
begin
	if @pbDebug = 1
		print 'Getting earliest dates for events'

	------------------------------------
	-- Get the earliest date for those
	-- relationships that have indicated
	-- an Event to be updated with the 
	-- earliest available related date.
	------------------------------------
	insert @tbEvents (EVENTNO, EVENTDATE, EARLIESTDATE)
	select 	C.EVENTNO, min(coalesce(CE.EVENTDATE, R.PRIORITYDATE) ), 1
	from RELATEDCASE R
	join CASERELATION C	on (C.RELATIONSHIP=R.RELATIONSHIP)
	left join CASEEVENT CE	on (CE.CASEID  = R.RELATEDCASEID
				and CE.EVENTNO = C.FROMEVENTNO
				and CE.EVENTDATE is not null)
	where R.CASEID = @pnCaseKey
	and C.EARLIESTDATEFLAG=1
	and C.FROMEVENTNO IS NOT NULL
	and isnull(CE.EVENTDATE, R.PRIORITYDATE) is not null -- At least one date must exist
	group by C.EVENTNO
	order by C.EVENTNO

	select @nRowCount  = @@rowcount, 
	       @nErrorCode = @@error
end

if @nErrorCode = 0
begin
	if @pbDebug = 1
		print 'Getting last entered date for events'

	---------------------------------------
	-- Get the last entered date for those
	-- relationships that have indicated
	-- an Event to be updated but where the
	-- earliest date flag is off.
	---------------------------------------
	insert @tbEvents (EVENTNO, EVENTDATE, EARLIESTDATE)
	select 	C.EVENTNO, min(coalesce(CE.EVENTDATE, R.PRIORITYDATE)), 0
	from RELATEDCASE R
	join CASERELATION C	on (C.RELATIONSHIP=R.RELATIONSHIP)
	left join CASEEVENT CE	on (CE.CASEID  = R.RELATEDCASEID
				and CE.EVENTNO = C.FROMEVENTNO
				and CE.EVENTDATE is not null)
	where R.CASEID = @pnCaseKey
	and isnull(C.EARLIESTDATEFLAG,0)=0
	and C.FROMEVENTNO IS NOT NULL
	and isnull(CE.EVENTDATE, R.PRIORITYDATE) is not null -- At least one date must exist
	and R.LOGDATETIMESTAMP=(select max(R1.LOGDATETIMESTAMP)
				from CASERELATION C1
				join RELATEDCASE R1	on (R1.CASEID=R.CASEID
							and R1.RELATIONSHIP=C1.RELATIONSHIP)
				where C1.EVENTNO=C.EVENTNO)
	group by C.EVENTNO
	order by C.EVENTNO

	select @nRowCount  = @nRowCount + @@rowcount, 
	       @nErrorCode = @@error
end

If  @nRowCount >0
and @nErrorCode=0
Begin
	if @pbDebug = 1
		print 'Consolidating Events to be updated'
	----------------------------------------------
	-- If more than one row has been inserted
	-- into @tbEvents for the same EventNo
	-- then this is because at least one
	-- Relationship has specified to use the
	-- Earliest Date and another Relationship has
	-- not specified to use the earliest date.
	-- We need to consolidate down to just one
	-- EventNo and date by taking the earliest.
	----------------------------------------------
	insert @tbEarliestEvents (EVENTNO, EVENTDATE, CYCLE)
	select T.EVENTNO, T.EVENTDATE, CE.CYCLE
	from (	select 	EVENTNO, min(EVENTDATE) as EVENTDATE
		from @tbEvents
		group by EVENTNO) T
	-----------------------------------
	-- Determine if a CaseEvent row
	-- needs to be inserted or updated.
	-----------------------------------
	left join CASEEVENT CE	on (CE.CASEID =@pnCaseKey
				and CE.EVENTNO=T.EVENTNO
				and CE.CYCLE  =(select min(CE1.CYCLE)
						from CASEEVENT CE1
						where CE1.CASEID=CE.CASEID
						and CE1.EVENTNO =CE.EVENTNO))
	where CE.CASEID is null		-- CASEEVENT does not exist and will be inserted
	or CE.EVENTDATE IS NULL		-- CASEEVENT exists but is cleared
	or CE.EVENTDATE<>T.EVENTDATE	-- CASEEVENT exists but is to be updated with a different date

	---------------------------------------------
	-- Set the RowCount to track if there are
	-- CASEEVENT rows to insert/update and Police
	---------------------------------------------
	select @nRowCount  = @@rowcount, 
	       @nErrorCode = @@error
End

If  @nRowCount >0
and @nErrorCode=0
Begin
	-------------------------------------
	-- Update the existing CASEEVENT rows
	-------------------------------------
	update 	CE
	set	EVENTDATE = T.EVENTDATE,
		OCCURREDFLAG = 1
	from	@tbEarliestEvents T
	join	CASEEVENT CE	on (CE.CASEID  = @pnCaseKey
				and CE.EVENTNO = T.EVENTNO
				and CE.CYCLE   = T.CYCLE)

	Set @nErrorCode = @@error
	
	If @nErrorCode=0
	Begin
		-----------------------------
		-- Insert a new CASEEVENT row
		-----------------------------
		insert 	CASEEVENT (
				CASEID,
				EVENTNO,
				CYCLE,
				EVENTDATE,
				OCCURREDFLAG )
		Select	@pnCaseKey,
			EVENTNO,
			1,
			EVENTDATE,
			1
		From @tbEarliestEvents
		where CYCLE is null
		
		Set @nErrorCode = @@error
	End
	
	-- DR-52908 Error after adding related cases when creating a new case (TODO)
	-- Generate policing key					
	If @nErrorCode = 0
	Begin										
		declare @dtCurrentDate		datetime
		declare @nPolicingSeq		int
				
		set @dtCurrentDate=GETDATE()

		Select 	@nPolicingSeq = isnull(max(POLICINGSEQNO) + 1, 1)
		from	POLICING
		where 	DATEENTERED = @dtCurrentDate
				
		If @nPolicingSeq is null
			Set @nPolicingSeq = 1

		Set @nErrorCode = @@error
	End	

	If @nErrorCode=0
	Begin
		-------------------------------------
		-- Insert a POLICING row for each
		-- CASEEVENT just updated or inserted
		-------------------------------------
		Insert Into POLICING
			(	DATEENTERED,
				POLICINGSEQNO,
				POLICINGNAME,	
				SYSGENERATEDFLAG,
				ONHOLDFLAG,
				CASEID,
				EVENTNO,
				CYCLE,
				SQLUSER,
				TYPEOFREQUEST,
				BATCHNO,
				IDENTITYID
			)
		Select	@dtCurrentDate,
				SEQUENCENO+@nPolicingSeq,
				dbo.fn_DateToString(@dtCurrentDate,'CLEAN-DATETIME') + cast(SEQUENCENO+@nPolicingSeq as nvarchar(3))+'Rel Case',	
				1,
				case when @pnPolicingBatchNo is null then 0 else 1 end,
				@pnCaseKey,
				EVENTNO,
				isnull(CYCLE,1),
				SYSTEM_USER,
				3,
				@pnPolicingBatchNo,
				@pnUserIdentityId
		From @tbEarliestEvents
		
		set @nErrorCode = @@error
	End
End

return @nErrorCode
GO

Grant execute on dbo.cs_UpdatePriorityEvents to public
go
