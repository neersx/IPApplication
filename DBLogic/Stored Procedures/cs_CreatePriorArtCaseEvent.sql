-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_CreatePriorArtCaseEvent
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_CreatePriorArtCaseEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.cs_CreatePriorArtCaseEvent.'
	Drop procedure [dbo].[cs_CreatePriorArtCaseEvent]
end
Print '**** Creating Stored Procedure dbo.cs_CreatePriorArtCaseEvent...'
Print ''
GO

Set QUOTED_IDENTIFIER OFF
GO
Set ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_CreatePriorArtCaseEvent
(
	@pnUserIdentityId	int,			
	@psFamily		nvarchar(40)	= null,		-- optional parameters
	@pnPriorArtId		int		= null,		
	@pnCaseId		int		= null,	
	@psCulture		nvarchar(10) 	= null,
	@pbPolicingImmediate	bit		= 0
)
as
-- PROCEDURE:	cs_CreatePriorArtCaseEvent
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Create CASEEVENT rows when case is associated with prior art
--
-- MODIFICATIONS :
-- Date			Who		Change	 	Version	Description
-- -----------	----- 	-------- 	-------	----------------------------------------------- 
-- 18 Mar 2008	DL    	11964 		1		Procedure created.
-- 22 Aug 2017	MF	72214		2		Ensure POLICING rows are written with the IdentityId and start Policing with the same IdentityId.

Set NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF

-- A temporary table to store the Cases that are to have the CASEEVENT created
CREATE TABLE #TEMPCASE(
		CASEID		int		NOT NULL
		)

-- A temporary table to store the priorart that are to be associated to CASES
CREATE TABLE #TEMPPRIORART(
		PRIORARTID		int		NOT NULL
		)

-- A temporary table to store the EVENTS to be created for the above cases
CREATE TABLE #TEMPEVENT(
		EVENTNO		int			NOT NULL,
		EVENTDATE	DATETIME	NOT NULL
		)

-- A temporary table to store the CASE EVENTS to be created
CREATE TABLE #TEMPCASEEVENT(
		ROWID		int			IDENTITY(1, 1),
		CASEID		int			NOT NULL,
		EVENTNO		int			NOT NULL,
		EVENTDATE	DATETIME	NOT NULL,
		CYCLE		int			
		)



Declare @nErrorCode		int
Declare @nRowCount		int
Declare	@sSQLString		nvarchar(4000)
Declare @nCaseCount		int
Declare @nEventCount		int
Declare @nCaseEventCount	int
Declare @nRowId			int
Declare @nCaseId		int
Declare @nEventNo		int
Declare @dtEventDate		datetime
Declare @nCycle			int
Declare @nPolicingBatchNo	int
Declare @bOnHoldFlag		bit



Set @nErrorCode=0
Set @nCaseCount=0
Set @nEventCount=0
Set @nCaseEventCount = 0

-- Determine the affected CASES
If (@nErrorCode=0)
Begin
	If @pnCaseId is not null
	Begin
		Set @sSQLString="Insert into #TEMPCASE (CASEID) values (@pnCaseId)"
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int',
				  @pnCaseId	= @pnCaseId
		Set @nCaseCount=@@Rowcount
	End
	Else If @psFamily is not null
	Begin
		Set @sSQLString="
			Insert into #TEMPCASE (CASEID) 
			select C.CASEID
			from CASES C
			where C.FAMILY = @psFamily"
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@psFamily		nvarchar(40)',
				  @psFamily		= @psFamily
		Set @nCaseCount=@@Rowcount
	End
	Else If @pnPriorArtId is not null
	Begin
		-- User may have changed the priorart dates.  This triggers new case events for the new dates.
		Set @sSQLString="
			Insert into #TEMPCASE (CASEID) 
			select CSR.CASEID
			from CASESEARCHRESULT CSR
			where CSR.PRIORARTID = @pnPriorArtId"
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnPriorArtId		int',
				  @pnPriorArtId		= @pnPriorArtId
		Set @nCaseCount=@@Rowcount
	End
End

-- Determine the affected prior art
If (@nErrorCode=0)
Begin
	If @pnPriorArtId is not null
	Begin
		Set @sSQLString="Insert into #TEMPPRIORART (PRIORARTID) values (@pnPriorArtId)"
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnPriorArtId		int',
				  @pnPriorArtId	= @pnPriorArtId
	End
	-- When case is associated with a family we need to get all prior art that link to the family to link to the case
	Else If @psFamily is not null
	Begin
		Set @sSQLString="
			Insert into #TEMPPRIORART (PRIORARTID) 
			select distinct FSR.PRIORARTID
			from FAMILYSEARCHRESULT FSR
			where FSR.FAMILY = @psFamily"
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@psFamily		nvarchar(40)',
				  @psFamily		= @psFamily
	End
End

-- Determine the affected events & dates
If (@nErrorCode=0)
Begin
	Set @sSQLString="
		Insert into #TEMPEVENT (EVENTNO, EVENTDATE) 
		select  EVENTNO, EVENTDATE
		from
			(Select distinct COLINTEGER AS EVENTNO, 
			case	when CONTROLID ='Prior Art Priority' then PRIORITYDATE 
				when CONTROLID ='Prior Art Published' then PUBLICATIONDATE
				when CONTROLID ='Prior Art Received' then RECEIVEDDATE 
				when CONTROLID ='Prior Art Report Issued' then ISSUEDDATE 
				when CONTROLID ='Prior Art Granted' then GRANTEDDATE 
			end as EVENTDATE
			from 
			(select COLINTEGER, CONTROLID
				from SITECONTROL
				where CONTROLID in ('Prior Art Priority', 'Prior Art Published', 'Prior Art Received', 'Prior Art Report Issued', 'Prior Art Granted')
				and COLINTEGER is not null) AS T1,
			(select SR.ISSUEDDATE, SR.RECEIVEDDATE, SR.PUBLICATIONDATE, SR.PRIORITYDATE, SR.GRANTEDDATE
				from SEARCHRESULTS SR
				join #TEMPPRIORART TPA on (TPA.PRIORARTID = SR.PRIORARTID) ) AS T2
			) as T3
			where EVENTDATE is not null and EVENTNO is not null
	"
	exec @nErrorCode=sp_executesql @sSQLString
	Set @nEventCount=@@Rowcount
End


-- Create CASEEVENT
If (@nErrorCode=0 and @nCaseCount>0 and @nEventCount>0)
Begin
	-- Get new case events to be inserted into CASEEVENT, exclude existing caseevent with matching eventdate
	Set @sSQLString="
		Insert into #TEMPCASEEVENT (CASEID, EVENTNO, EVENTDATE)
		Select T1.CASEID, T1.EVENTNO,  T1.EVENTDATE
		from 
		(	Select distinct TC.CASEID, TE.EVENTNO,  TE.EVENTDATE
				from #TEMPEVENT TE, #TEMPCASE TC ) T1 
		left join CASEEVENT CE on (CE.CASEID = T1.CASEID and CE.EVENTNO = T1.EVENTNO AND CE.EVENTDATE = T1.EVENTDATE)
		where CE.CASEID is null

		"
	exec @nErrorCode=sp_executesql @sSQLString
	Set @nCaseEventCount=@@Rowcount

	-- update the event cycle
	If @nErrorCode = 0 and @nCaseEventCount > 0
	Begin
		set @nCycle = 0
		Set @sSQLString="
			Update #TEMPCASEEVENT
			Set	@nCycle=	CASE WHEN(@nCaseId=CASEID AND @nEventNo=EVENTNO)
							THEN @nCycle+1
							ELSE 1
						END,
				CYCLE=@nCycle,
				@nCaseId=CASEID,
				@nEventNo=EVENTNO"
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nCycle		int,
							  @nCaseId		int,
							  @nEventNo		int',
							  @nCycle		= @nCycle,
							  @nCaseId		= @nCaseId,
							  @nEventNo		= @nEventNo
	End

	-- Now Create CASEEVENT
	If @nErrorCode = 0 and @nCaseEventCount > 0
	Begin
		Set @sSQLString="
			Insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)
			Select distinct TCE.CASEID, TCE.EVENTNO, 
				TCE.CYCLE + (select isnull(max(CYCLE),0) FROM CASEEVENT where EVENTNO = TCE.EVENTNO AND CASEID = TCE.CASEID ) AS CYCLE, 
				TCE.EVENTDATE, 1 OCCURREDFLAG
			from #TEMPCASEEVENT TCE
			"
			exec @nErrorCode=sp_executesql @sSQLString
	End
End


-- Create policing requests
If (@nErrorCode=0 and @nCaseEventCount>0)
Begin
	-- Get policing batch number if policing immediately
	Set @nPolicingBatchNo = null
	Set @bOnHoldFlag = 0
	If @pbPolicingImmediate = 1
	Begin
		Set @bOnHoldFlag = 1

		Set @sSQLString="
			Update LASTINTERNALCODE 
			set INTERNALSEQUENCE = INTERNALSEQUENCE+1,
				 @nPolicingBatchNo = INTERNALSEQUENCE+1
			where TABLENAME = 'POLICINGBATCH'"
		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nPolicingBatchNo int OUTPUT',
				  @nPolicingBatchNo = @nPolicingBatchNo OUTPUT
	End

	Set @sSQLString="
		Insert into POLICING(DATEENTERED, POLICINGSEQNO, POLICINGNAME, 
		SYSGENERATEDFLAG, ONHOLDFLAG, BATCHNO, EVENTNO, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
		select 	 getdate(), TCE.ROWID, convert(varchar, getdate(), 121)+' '+convert(varchar, TCE.ROWID), 
		1, @bOnHoldFlag, @nPolicingBatchNo, TCE.EVENTNO, TCE.CASEID, CE.CYCLE, 3, SYSTEM_USER, @pnUserIdentityId 
		from #TEMPCASEEVENT TCE
		join CASEEVENT CE on (CE.CASEID = TCE.CASEID and CE.EVENTNO=TCE.EVENTNO and CE.EVENTDATE=TCE.EVENTDATE) "

	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@bOnHoldFlag		bit,
				  @nPolicingBatchNo	int,
				  @pnUserIdentityId	int',
				  @bOnHoldFlag		= @bOnHoldFlag,
				  @nPolicingBatchNo	= @nPolicingBatchNo,
				  @pnUserIdentityId	= @pnUserIdentityId
	set @nRowCount = @@ROWCOUNT
End

-- run policing if @pbPolicingImmediate = 1
If (@pbPolicingImmediate = 1 and @nErrorCode = 0 and @nRowCount > 0)
Begin
	exec @nErrorCode=dbo.ipu_Policing
			@pdtPolicingDateEntered 	= null,
			@pnPolicingSeqNo 		= null,
			@pnDebugFlag			= 0,
			@pnBatchNo			= @nPolicingBatchNo,
			@psDelayLength			= null,
			@pnUserIdentityId		= @pnUserIdentityId,
			@psPolicingMessageTable		= null
End


If  @nErrorCode <>0
Begin
	RAISERROR('Cannot create CASEEVENT.', 14, 1)
	Set @nErrorCode = @@ERROR
End



Return @nErrorCode
GO

Grant execute on dbo.cs_CreatePriorArtCaseEvent to public
GO
