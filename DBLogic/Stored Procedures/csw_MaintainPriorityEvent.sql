-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_MaintainPriorityEvent
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_MaintainPriorityEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_MaintainPriorityEvent.'
	Drop procedure [dbo].[csw_MaintainPriorityEvent]
End
Print '**** Creating Stored Procedure dbo.csw_MaintainPriorityEvent...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_MaintainPriorityEvent
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psRowKey		nvarchar(15)	= null,
	@pnCaseKey		int		= null,
	@pdtDate		datetime	= null,
	@psOfficialNumber	nvarchar(36)	= null,
	@psCountryKey		nvarchar(3)	= null,
	@pnEventKey		int		= null,
	@pbIsPriorityEvent	bit		= null,

	@pdtOldDate		datetime	= null,
	@psOldOfficialNumber	nvarchar(36)	= null,
	@psOldCountryKey	nvarchar(3)	= null,
	@pnOldEventKey		int		= null,

	@pnPolicingBatchNo	int		= null
)
as
-- PROCEDURE:	csw_MaintainPriorityEvent
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Used by Docketing Wizard in WorkBenches.  Logic derived from dlgCaseDateEdit in Client/Server

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 JAN 2008	SF	5708	1	Procedure created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Jul 2009	MF	16548	3	The FROMEVENTNO will now identify the Event from a related Case that will be pushed
--					into the child Case.
-- 09 Apr 2014  MS      R31303  4       Added LastModifiedDate in csw_UpdateCaseEvent call
-- 23 Nov 2016	DV	R62369	5	Remove concurrency check when updating case events
-- 03 Oct 2017  AK      R72485  6       used @pdtLastModifiedDate paramter in csw_DeleteRelatedCase call  
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)

declare @nRowCount int

declare @dtPriorityEventDate datetime
declare @sPriorityNumber nvarchar(36)
declare @sPriorityCountryKey nvarchar(3)
declare @nRelatedCaseKey	int
declare @sRelationship nvarchar(3)
declare @nRelationshipNo 	int
declare @nEventNo		int
declare @dtRelatedCaseLastModifiedDate  datetime

declare @nOccurredFlag bit
-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select @sRelationship = SC.COLCHARACTER
		FROM SITECONTROL SC 
		WHERE SC.CONTROLID = 'Earliest Priority'"
		
	exec @nErrorCode = sp_executesql @sSQLString,
		N'@sRelationship 	nvarchar(3) output',
			@sRelationship 	= @sRelationship output
		
	If @nErrorCode = 0
	and @sRelationship is not null
	and (@pdtDate <> @pdtOldDate or @psCountryKey <> @psOldCountryKey or @psOfficialNumber <> @psOldOfficialNumber)
	Begin
		Set @sSQLString = "
		Select top 1 
			@dtPriorityEventDate = isnull(CE.EVENTDATE, RC.PRIORITYDATE),
			@sPriorityNumber = COALESCE(O.OFFICIALNUMBER, C.CURRENTOFFICIALNO, RC.OFFICIALNUMBER),
			@sPriorityCountryKey = isnull(C.COUNTRYCODE, RC.COUNTRYCODE),
			@nRelatedCaseKey = RC.RELATEDCASEID,
			@nRelationshipNo = RC.RELATIONSHIPNO,
			@nEventNo = CR.EVENTNO,
                        @dtRelatedCaseLastModifiedDate = RC.LOGDATETIMESTAMP 
		from RELATEDCASE RC
		JOIN SITECONTROL SC ON (SC.COLCHARACTER = RC.RELATIONSHIP AND SC.CONTROLID = 'Earliest Priority')
		JOIN CASERELATION CR ON (CR.RELATIONSHIP = RC.RELATIONSHIP)
		LEFT JOIN CASES C ON (C.CASEID = RC.RELATEDCASEID)
		LEFT JOIN OFFICIALNUMBERS O ON (O.CASEID = RC.RELATEDCASEID AND O.NUMBERTYPE = 'A' AND O.ISCURRENT = 1)
		LEFT JOIN CASEEVENT CE	ON (CE.CASEID = RC.RELATEDCASEID 
					AND CE.EVENTNO = CR.FROMEVENTNO
					AND CE.CYCLE = 1)
		where RC.CASEID = @pnCaseKey
		ORDER BY 1,2"
		
		exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnCaseKey   		int,
					@dtPriorityEventDate	datetime	output,
                                        @dtRelatedCaseLastModifiedDate datetime output,
					@sPriorityNumber	nvarchar(36)	output,
					@sPriorityCountryKey 	nvarchar(3)	output,
					@nEventNo		int		output,
					@nRelatedCaseKey	int		output,
					@nRelationshipNo	int		output',
					@pnCaseKey		= @pnCaseKey, 
					@dtPriorityEventDate 	= @dtPriorityEventDate	output,	
					@sPriorityNumber	= @sPriorityNumber	output,
					@sPriorityCountryKey	= @sPriorityCountryKey	output,
					@nEventNo		= @nEventNo		output,
					@nRelatedCaseKey	= @nRelatedCaseKey	output,
					@nRelationshipNo	= @nRelationshipNo	output,
                                        @dtRelatedCaseLastModifiedDate =@dtRelatedCaseLastModifiedDate output
		
		Set @nRowCount = @@rowcount
		
		If @nErrorCode = 0
		and @nRowCount = 1
		Begin
			If @nRelatedCaseKey is not null -- add / update / delete internal case
			Begin
				-- If date is not null,  add.
				If @pdtDate is not null				
				Begin
					exec @nErrorCode = csw_InsertRelatedCase
						@pnUserIdentityId			= @pnUserIdentityId,
						@psCulture				= @psCulture,
						@pnCaseKey				= @pnCaseKey,
						@pnPolicingBatchNumber			= @pnPolicingBatchNo,
						@psRelationshipCode			= @sRelationship,
						@psOfficialNumber			= @psOfficialNumber,
						@psCountryCode				= @psCountryKey,
						@pdtEventDate				= @pdtDate,	
						@pbIsRelationshipCodeInUse 		= 1,
						@pbIsOfficialNumberInUse		= 1,
						@pbIsCountryCodeInUse			= 1,	
						@pbIsEventDateInUse			= 1,
						@pbAddForwardRelationshipOnly		= 1
				End
				Else 
				Begin
					If @psOfficialNumber is not null -- add related case
					Begin
						declare @nRelatedCaseFound int
						
						Set @sSQLString = "
							Select top 1 @nRelatedCaseFound = C.CASEID		
							from OFFICIALNUMBERS O
							JOIN CASES C ON (C.CASEID = O.CASEID)							
							where O.COUNTRYCODE = @psCountryCode
							and O.OFFICIALNUMBER = @psOfficialNumber
							ORDER BY C.CASEID, O.OFFICIALNUMBER"
							
						exec @nErrorCode = sp_executesql @sSQLString,
							N'@nRelatedCaseFound		int			output,
								@psOfficialNumber	nvarchar(36),
								@psCountryCode 		nvachar(3)',
								@nRelatedCaseFound	= @nRelatedCaseFound	output, 
								@psOfficialNumber 	= @psOfficialNumber,	
								@psCountryCode		= @psCountryKey
						
						If @nRelatedCaseFound is not null
						Begin
							-- related case found
							exec @nErrorCode = csw_InsertRelatedCase
								@pnUserIdentityId		= @pnUserIdentityId,
								@psCulture			= @psCulture,
								@pnCaseKey			= @pnCaseKey,
								@pnPolicingBatchNumber		= @pnPolicingBatchNo,
								@psRelationshipCode		= @sRelationship,
								@pnRelatedCaseKey		= @nRelatedCaseFound,
								@psOfficialNumber		= @psOfficialNumber,
								@psCountryCode			= @psCountryKey,
								@pdtEventDate			= @pdtDate,	
								@pbIsRelationshipCodeInUse 	= 1,
								@pbIsRelatedCaseKeyInUse	= 1,
								@pbIsOfficialNumberInUse	= 1,
								@pbIsCountryCodeInUse		= 1,	
								@pbIsEventDateInUse		= 1,
								@pbAddForwardRelationshipOnly	= 1							
						End
						Else 
						Begin
							-- related case not found
							exec @nErrorCode = csw_InsertRelatedCase
								@pnUserIdentityId		= @pnUserIdentityId,
								@psCulture			= @psCulture,
								@pnCaseKey			= @pnCaseKey,
								@pnPolicingBatchNumber		= @pnPolicingBatchNo,
								@psRelationshipCode		= @sRelationship,
								@pbIsRelationshipCodeInUse 	= 1,
								@pbAddForwardRelationshipOnly 	= 1
						End
					End
					Else -- official number is null
					Begin
						exec @nErrorCode = csw_DeleteRelatedCase
								@pnUserIdentityId		= @pnUserIdentityId,
								@psCulture			= @psCulture,
								@pnCaseKey			= @pnCaseKey,
								@pnSequence			= @nRelationshipNo,
								@pnPolicingBatchNumber		= @pnPolicingBatchNo,
                                                                @pdtLastModifiedDate            = @dtRelatedCaseLastModifiedDate
					End
				End 
			End -- @nRelatedCaseKey is not null
			Else
			Begin
				-- ! Update Related Case Table
				If @nRelationshipNo is not null
				Begin
					If @pdtDate is null and @psOfficialNumber is null 
					Begin -- delete external case ref
						exec @nErrorCode = csw_DeleteRelatedCase
								@pnUserIdentityId		= @pnUserIdentityId,
								@psCulture			= @psCulture,
								@pnCaseKey			= @pnCaseKey,
								@pnSequence			= @nRelationshipNo,
								@pnPolicingBatchNumber		= @pnPolicingBatchNo,
                                                                @pdtLastModifiedDate            = @dtRelatedCaseLastModifiedDate
					End
					Else -- update external case ref
					Begin					        
					        Set @sSQLString = "Select @dtRelatedCaseLastModifiedDate = LOGDATETIMESTAMP
					        FROM RELATEDCASE 
					        where CASEID = @pnCaseKey
					        and RELATIONSHIPNO = @nRelationshipNo"
							
						exec @nErrorCode = sp_executesql @sSQLString,
							        N'@dtRelatedCaseLastModifiedDate        datetime        output,
							        @pnCaseKey		                int,
								@nRelationshipNo	                int',
								@dtRelatedCaseLastModifiedDate	        = @dtRelatedCaseLastModifiedDate	output, 
								@pnCaseKey 	                        = @pnCaseKey,	
								@nRelationshipNo		        = @nRelationshipNo
					
						exec @nErrorCode = csw_UpdateRelatedCase 
							@pnUserIdentityId	= @pnUserIdentityId,
							@psCulture		= @psCulture,
							@pnCaseKey		= @pnCaseKey,
							@pnSequence		= @nRelationshipNo,
							@pnPolicingBatchNumber	= @pnPolicingBatchNo,
							@psOfficialNumber	= @psOfficialNumber,
							@psCountryCode		= @psCountryKey,
							@pdtEventDate		= @pdtDate,
							@pdtLastModifiedDate    = @dtRelatedCaseLastModifiedDate
								
					End
				End
				Else -- the date is coming from CASEEVENT table, not from the RELATEDCASE table
				Begin
					exec @nErrorCode = csw_InsertRelatedCase
						@pnUserIdentityId		= @pnUserIdentityId,
						@psCulture			= @psCulture,
						@pnCaseKey			= @pnCaseKey,
						@pnPolicingBatchNumber		= @pnPolicingBatchNo,
						@psRelationshipCode		= @sRelationship,
						@psOfficialNumber		= @psOfficialNumber,
						@psCountryCode			= @psCountryKey,
						@pdtEventDate			= @pdtDate,	
						@pbIsRelationshipCodeInUse 	= 1,
						@pbIsOfficialNumberInUse	= 1,
						@pbIsCountryCodeInUse		= 1,	
						@pbIsEventDateInUse		= 1,
						@pbAddForwardRelationshipOnly	= 1		
				End
			End		-- nRelatedCaseKey is null
		End
		Else -- rowcount =0 
		Begin
			If @pdtDate is not null and @psOfficialNumber is not null 
			Begin
				exec @nErrorCode = csw_InsertRelatedCase
						@pnUserIdentityId		= @pnUserIdentityId,
						@psCulture			= @psCulture,
						@pnCaseKey			= @pnCaseKey,
						@pnPolicingBatchNumber		= @pnPolicingBatchNo,
						@psRelationshipCode		= @sRelationship,
						@psOfficialNumber		= @psOfficialNumber,
						@psCountryCode			= @psCountryKey,
						@pdtEventDate			= @pdtDate,	
						@pbIsRelationshipCodeInUse	= 1,
						@pbIsOfficialNumberInUse	= 1,
						@pbIsCountryCodeInUse		= 1,	
						@pbIsEventDateInUse		= 1,
						@pbAddForwardRelationshipOnly	= 1		
			End
		End
	End -- @sRelationship is not null
End

If @nErrorCode = 0
and (@pdtDate <> @pdtOldDate)
and @nEventNo is not null
Begin
	Set @nOccurredFlag = case when @pdtDate is null then 0 else 1 end
	
	-- update / add
	If exists (Select 1 from CASEEVENT CE where CE.CASEID = @pnCaseKey and CE.EVENTNO = @nEventNo and CE.CYCLE = 1)
	Begin   
	        exec @nErrorCode = dbo.csw_UpdateCaseEvent
						@pnUserIdentityId	= @pnUserIdentityId,
						@psCulture		= @psCulture,
						@pnCaseKey		= @pnCaseKey,
						@pnPolicingBatchNo	= @pnPolicingBatchNo,
						@pnEventKey		= @nEventNo,
						@pnEventCycle		= 1,
						@pdtEventDate		= @pdtDate,
						@pbIsEventKeyInUse	= 1,
						@pbIsEventCycleInUse	= 1,
						@pbIsEventDateInUse	= 1	
	End
	Else
	Begin
		exec @nErrorCode = dbo.csw_InsertCaseEvent
						@pnUserIdentityId	= @pnUserIdentityId,
						@psCulture		= @psCulture,
						@pnCaseKey		= @pnCaseKey,
						@pnPolicingBatchNo	= @pnPolicingBatchNo,
						@pnEventKey		= @nEventNo,
						@pnCycle		= 1,
						@pdtEventDate		= @pdtDate
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_MaintainPriorityEvent to public
GO
