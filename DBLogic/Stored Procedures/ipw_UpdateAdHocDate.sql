-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateAdHocDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateAdHocDate.'
	Drop procedure [dbo].[ipw_UpdateAdHocDate]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateAdHocDate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateAdHocDate
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnNameKey			int,		-- Mandatory
	@pdtDateCreated			datetime,	-- Mandatory
	@pnCaseKey			int		= null,
	@psAdHocMessage			nvarchar(1000),	-- Mandatory
	@psAdHocReference		nvarchar(20)	= null,
	@pnNameReferenceKey             int		= null,
	@pdtDueDate			datetime	= null, 	
	@pnEventKey			int		= null,
	@pdtDateOccurred		datetime	= null,
	@pnOccurredReasonKey		tinyint		= null,
	@pdtDeleteDate			datetime	= null,
	@pdtStopRemindersDate		datetime	= null,
	@pnDaysLead			smallint	= null,
	@pnRepeatIntervalDays		smallint	= null,
	@pnMonthsLead			smallint	= null,
	@pnRepeatIntervalMonths 	smallint	= null,
	@pnSequenceNo			int		= null,
	@pbIsElectronicReminder 	bit		= null,
	@psEmailSubject			nvarchar(100)	= null,
	@psImportanceLevel		nvarchar(2)	= null,
	@pnDisplayOrder			int		= null,
	@pbIsEmployee			bit		= 0,
	@pbIsSignatory			bit		= 0,
	@pbIsCriticalList		bit		= 0,
	@psNameType			nvarchar(3)	= null,
	@psRelationship			nvarchar(3)	= null,
	@pbChangeRecipient		bit		= null,
	@pnOldNameKey			int		= null,
	@pnOldCaseKey			int		= null,
	@psOldAdHocMessage		nvarchar(1000),	-- Mandatory
	@psOldAdHocReference		nvarchar(20)	= null,
	@pnOldNameReferenceKey          int             = null,
	@pdtOldDueDate			datetime	= null, 
	@pnOldEventKey			int		= null,	
	@pdtOldDateOccurred		datetime	= null,
	@pnOldOccurredReasonKey		tinyint		= null,
	@pdtOldDeleteDate		datetime	= null,
	@pdtOldStopRemindersDate 	datetime	= null,
	@pnOldDaysLead			smallint	= null,
	@pnOldRepeatIntervalDays 	smallint	= null,
	@pnOldMonthsLead		smallint	= null,
	@pnOldRepeatIntervalMonths 	smallint	= null,
	@pnOldSequenceNo		int		= null,
	@pbOldIsElectronicReminder 	bit		= null,
	@psOldEmailSubject		nvarchar(100)	= null,
	@psOldImportanceLevel		nvarchar(2)	= null,
	@pnOldDisplayOrder		int		= null,
	@pbOldIsEmployee		bit		= 0,
	@pbOldIsSignatory		bit		= 0,
	@pbOldIsCriticalList		bit		= 0,
	@psOldNameType			nvarchar(3)	= null,
	@psOldRelationship		nvarchar(3)	= null,
	@pnPolicingBatchNo		int		= null
)
-- PROCEDURE:	ipw_UpdateAdHocDate
-- VERSION:	16
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Updates an Alert.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 08 Oct 2004  TM	RFC1327	1	Procedure created. 
-- 11 Oct 2004	TM	RFC1327	2	Only write the @pnOccurredReasonKey to the database if it is provided.
-- 19 Oct 2004	TM	RFC1327	3	Set the SENDELECTRONICALLY column to @pbIsElectronicReminder instead of
--					the @pbOldIsElectronicReminder.
-- 23 Nov 2004	TM	RFC2025	4	Clear AlertDate. Ensure any time component is stripped from the following:
--					DueDate, DateOccurred, DeleteDate, StopRemindersDate.
-- 14 Jul 2005	TM	RFC2743	5	OccurredReasonKey concurrency checking should treat 0 and null as equal values.
-- 18 Jul 2005	JEK	RFC2743	6	Does not clear reason.
-- 18 Aug 2005	TM	RFC2938	7	Cater for new ImportanceLevel column on the Alert table. 
-- 18 Jan 2008	SF	RFC5708	8	Added new DisplayOrder field
-- 12 Feb 2009  LP      RFC6047 9       Added new NameReferenceKey field.
-- 01 May 2009	SF	RFC7924 10	Add a new entry if NameKey has changed
-- 06 May 2009	SF	RFC7924 11	Update does not work
-- 18 Jul 2011	LP	RFC10992 12	Increase @psAlertMessage parameter to 1000 characters.
-- 02 Dec 2011	DV	RFC996	13	Add logic to update additional fields in ALERT table. 
-- 27 Mar 2014	MS	R30706	14	Added parameter @pbChangeRecipient. If true recipient will be changed 
--					rather than creating copy of ad hoc date
-- 08 Apr 2014  MS      R31303  15      Set default values for parameters IsEmployee, IsSignaytory and IsCriticalList to 0 rather than null
-- 27 Sep 2018	MF	75149	16	If the recipient of the ALERT is being changed, check that this will not generate a duplicate ALERT row.

as

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON


Declare @nErrorCode	int
Declare @sSQLString	nvarchar(4000)

Declare @nTypeOfRequest	tinyint

-- Initialise variables
Set @nErrorCode 	= 0
Set @pbOldIsElectronicReminder = CAST(@pbOldIsElectronicReminder as decimal(1,0))
Set @pbIsElectronicReminder = CAST(@pbIsElectronicReminder as decimal(1,0))

If @nErrorCode = 0
Begin
	If @pnNameKey <> @pnOldNameKey and IsNull(@pbChangeRecipient,0) = 0
	Begin
		exec @nErrorCode = ipw_InsertAdHocDate 
				@pnUserIdentityId		= @pnUserIdentityId,
				@psCulture				= @psCulture,
				@pnNameKey				= @pnNameKey,
				@pnCaseKey				= @pnCaseKey,
				@psAdHocMessage			= @psAdHocMessage,
				@psAdHocReference		= @psAdHocReference,
				@pnNameReferenceKey		= @pnNameReferenceKey,
				@pdtDueDate				= @pdtDueDate,
				@pnEventKey				= @pnEventKey,
				@pdtDateOccurred		= @pdtDateOccurred,
				@pnOccurredReasonKey	= @pnOccurredReasonKey,
				@pdtDeleteDate			= @pdtDeleteDate,
				@pdtStopRemindersDate	= @pdtStopRemindersDate,
				@pnDaysLead				= @pnDaysLead,
				@pnRepeatIntervalDays	= @pnRepeatIntervalDays,
				@pnMonthsLead			= @pnMonthsLead,
				@pnRepeatIntervalMonths = @pnRepeatIntervalMonths,
				@pbIsElectronicReminder = @pbIsElectronicReminder,
				@psEmailSubject			= @psEmailSubject,
				@psImportanceLevel		= @psImportanceLevel,
				@pnDisplayOrder			= @pnDisplayOrder,
				@pbIsEmployee			= @pbIsEmployee,
				@pbIsSignatory			= @pbIsSignatory,
				@pbIsCriticalList		= @pbIsCriticalList,
				@psNameType				= @psNameType,
				@psRelationship			= @psRelationship,
				@pnPolicingBatchNo		= @pnPolicingBatchNo
	End
	Else
	Begin		
		Set @sSQLString = "	
		Update 	A
		Set	CASEID 			= @pnCaseKey,
			ALERTMESSAGE		= @psAdHocMessage,
			REFERENCE		= @psAdHocReference,
			NAMENO                  = @pnNameReferenceKey,
			DUEDATE			= convert(char(10),@pdtDueDate,121),
			TRIGGEREVENTNO				= @pnEventKey,
			DATEOCCURRED		= convert(char(10),@pdtDateOccurred,121),
			OCCURREDFLAG		= CASE WHEN @pnOccurredReasonKey <> @pnOldOccurredReasonKey
		    							THEN isnull(@pnOccurredReasonKey,0)
							   WHEN @pdtDateOccurred IS NOT NULL AND @pnOccurredReasonKey IS NULL 
				       					-- Event has occurred	
				       					THEN 3 
				       			   ELSE A.OCCURREDFLAG
				  		  END,
			DELETEDATE		= convert(char(10),@pdtDeleteDate,121),
			STOPREMINDERSDATE	= convert(char(10),@pdtStopRemindersDate,121),
			MONTHLYFREQUENCY 	= @pnRepeatIntervalMonths,
			MONTHSLEAD		= @pnMonthsLead,
			DAILYFREQUENCY		= @pnRepeatIntervalDays,
			DAYSLEAD		= @pnDaysLead,
			SEQUENCENO		= @pnSequenceNo,
			SENDELECTRONICALLY 	= @pbIsElectronicReminder,
			EMAILSUBJECT		= @psEmailSubject,
			ALERTDATE		= NULL,
			IMPORTANCELEVEL		= @psImportanceLevel,
			DISPLAYORDER		= CASE WHEN isnull(@pnDisplayOrder,9001) > 9000 THEN A.DISPLAYORDER ELSE @pnDisplayOrder END,
			EMPLOYEEFLAG		= @pbIsEmployee,
			SIGNATORYFLAG		= @pbIsSignatory,
			CRITICALFLAG		= @pbIsCriticalList,
			NAMETYPE		= @psNameType,
			RELATIONSHIP		= @psRelationship,
			EMPLOYEENO		= @pnNameKey
		From ALERT A
		left join (select * from ALERT) A1
						on (A1.EMPLOYEENO=@pnNameKey
						and A1.ALERTSEQ  =A.ALERTSEQ
						and @pnOldNameKey<>@pnNameKey)
		where   A.EMPLOYEENO 		= @pnOldNameKey
		and 	A.ALERTSEQ		= @pdtDateCreated
		and 	A.CASEID 		= @pnOldCaseKey
		and	A.ALERTMESSAGE		= @psOldAdHocMessage
		and 	A.REFERENCE		= @psOldAdHocReference
		and     A.NAMENO                = @pnOldNameReferenceKey
		and 	A.DUEDATE		= @pdtOldDueDate
		and 	A.TRIGGEREVENTNO	= @pnOldEventKey
		and 	A.DATEOCCURRED		= @pdtOldDateOccurred
		and 	ISNULL(A.OCCURREDFLAG,0)= ISNULL(@pnOldOccurredReasonKey,0)
		and	A.DELETEDATE		= @pdtOldDeleteDate
		and 	A.STOPREMINDERSDATE	= @pdtOldStopRemindersDate
		and	A.MONTHLYFREQUENCY 	= @pnOldRepeatIntervalMonths
		and	A.MONTHSLEAD		= @pnOldMonthsLead
		and	A.DAILYFREQUENCY	= @pnOldRepeatIntervalDays
		and	A.DAYSLEAD		= @pnOldDaysLead
		and 	A.SEQUENCENO		= @pnOldSequenceNo
		and	A.SENDELECTRONICALLY 	= @pbOldIsElectronicReminder
		and	A.EMAILSUBJECT		= @psOldEmailSubject
		and     A.IMPORTANCELEVEL	= @psOldImportanceLevel
		and	A.EMPLOYEEFLAG		= @pbOldIsEmployee
		and	A.SIGNATORYFLAG		= @pbOldIsSignatory
		and	A.CRITICALFLAG		= @pbOldIsCriticalList
		and	A.NAMETYPE		= @psOldNameType
		and	A.RELATIONSHIP		= @psOldRelationship  -- display order is non-essential in data concurrency check; may be passed in as 9999
		---------------------------------------------------------
		-- If the recipient NameKey of the Alert is being changed
		-- check that the change will not cause a duplicate row
		-- in the ALERT table
		---------------------------------------------------------
		and A1.EMPLOYEENO is null"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameKey			int,
						  @pdtDateCreated		datetime,
						  @pnCaseKey			int,
						  @psAdHocMessage		nvarchar(1000),
						  @psAdHocReference		nvarchar(20),
						  @pnNameReferenceKey           int,
						  @pdtDueDate			datetime,
						  @pnEventKey			int,
						  @pdtDateOccurred		datetime,
						  @pnOccurredReasonKey		tinyint,
						  @pdtDeleteDate		datetime,
						  @pdtStopRemindersDate		datetime,
						  @pnRepeatIntervalMonths 	smallint,
						  @pnMonthsLead			smallint,
						  @pnRepeatIntervalDays 	smallint,
						  @pnDaysLead			smallint,					
						  @pnSequenceNo			int,
						  @pbIsElectronicReminder 	bit,
						  @psEmailSubject		nvarchar(100),				
						  @psImportanceLevel		nvarchar(2),
						  @pnDisplayOrder		int,
						  @pbIsEmployee			bit,
						  @pbIsSignatory		bit,
					   	  @pbIsCriticalList		bit,
					   	  @psNameType			nvarchar(3),
						  @psRelationship		nvarchar(3),
						  @pnOldCaseKey			int,
						  @psOldAdHocMessage		nvarchar(1000),
						  @psOldAdHocReference		nvarchar(20),
						  @pnOldNameReferenceKey        int,
						  @pdtOldDueDate		datetime,
						  @pnOldEventKey		int,
						  @pdtOldDateOccurred		datetime,
						  @pnOldOccurredReasonKey 	tinyint,
						  @pdtOldDeleteDate		datetime,
						  @pdtOldStopRemindersDate 	datetime,
						  @pnOldRepeatIntervalMonths 	smallint,
						  @pnOldMonthsLead		smallint,
						  @pnOldRepeatIntervalDays 	smallint,
						  @pnOldDaysLead		smallint,					
						  @pnOldSequenceNo		int,
						  @pbOldIsElectronicReminder 	bit,
						  @psOldEmailSubject		nvarchar(100),
						  @psOldImportanceLevel		nvarchar(2),
						  @pnOldDisplayOrder		int,
						  @pbOldIsEmployee		bit,
						  @pbOldIsSignatory		bit,
						  @pbOldIsCriticalList		bit,
						  @psOldNameType		nvarchar(3),
						  @psOldRelationship		nvarchar(3),
						  @pnOldNameKey			int',					  
						  @pnNameKey			= @pnNameKey,
						  @pdtDateCreated		= @pdtDateCreated,
						  @pnCaseKey			= @pnCaseKey,
						  @psAdHocMessage		= @psAdHocMessage,
						  @psAdHocReference		= @psAdHocReference,
						  @pnNameReferenceKey           = @pnNameReferenceKey,
						  @pdtDueDate			= @pdtDueDate,
						  @pnEventKey			= @pnEventKey,
						  @pdtDateOccurred		= @pdtDateOccurred,
						  @pnOccurredReasonKey		= @pnOccurredReasonKey,
						  @pdtDeleteDate		= @pdtDeleteDate,
						  @pdtStopRemindersDate 	= @pdtStopRemindersDate,
						  @pnRepeatIntervalMonths 	= @pnRepeatIntervalMonths,
						  @pnMonthsLead			= @pnMonthsLead,
						  @pnRepeatIntervalDays		= @pnRepeatIntervalDays,
						  @pnDaysLead			= @pnDaysLead,	
						  @pnSequenceNo			= @pnSequenceNo,				
						  @pbIsElectronicReminder 	= @pbIsElectronicReminder,
						  @psEmailSubject		= @psEmailSubject,
						  @psImportanceLevel		= @psImportanceLevel,
						  @pnDisplayOrder		= @pnDisplayOrder,
						  @pbIsEmployee			= @pbIsEmployee,
						  @pbIsSignatory		= @pbIsSignatory,
						  @pbIsCriticalList		= @pbIsCriticalList,
						  @psNameType			= @psNameType,
						  @psRelationship		= @psRelationship,
						  @pnOldCaseKey			= @pnOldCaseKey,
						  @psOldAdHocMessage		= @psOldAdHocMessage,
						  @psOldAdHocReference		= @psOldAdHocReference,
						  @pnOldNameReferenceKey        = @pnOldNameReferenceKey,
						  @pdtOldDueDate		= @pdtOldDueDate,
						  @pnOldEventKey		= @pnOldEventKey,
						  @pdtOldDateOccurred		= @pdtOldDateOccurred,
						  @pnOldOccurredReasonKey	= @pnOldOccurredReasonKey,
						  @pdtOldDeleteDate		= @pdtOldDeleteDate,
						  @pdtOldStopRemindersDate 	= @pdtOldStopRemindersDate,
						  @pnOldRepeatIntervalMonths 	= @pnOldRepeatIntervalMonths,
						  @pnOldMonthsLead		= @pnOldMonthsLead,
						  @pnOldRepeatIntervalDays	= @pnOldRepeatIntervalDays,
						  @pnOldDaysLead		= @pnOldDaysLead,	
						  @pnOldSequenceNo		= @pnOldSequenceNo,				
						  @pbOldIsElectronicReminder 	= @pbOldIsElectronicReminder,
						  @psOldEmailSubject		= @psOldEmailSubject,
						  @psOldImportanceLevel		= @psOldImportanceLevel,
						  @pnOldDisplayOrder		= @pnOldDisplayOrder,
						  @pbOldIsEmployee		= @pbOldIsEmployee,
						  @pbOldIsSignatory		= @pbOldIsSignatory,
						  @pbOldIsCriticalList		= @pbOldIsCriticalList,
						  @psOldNameType		= @psOldNameType,
						  @psOldRelationship		= @psOldRelationship,
						  @pnOldNameKey			= @pnOldNameKey
	End
End

If @nErrorCode = 0
and @pnPolicingBatchNo is not null
Begin
	Set @nTypeOfRequest = CASE WHEN @pdtDateOccurred IS NOT NULL 
				   -- Ad Hoc Occurred
				   THEN 3
				   -- Ad Hoc Due
				   ELSE 2
			      END

	exec @nErrorCode = dbo.ipw_InsertPolicing
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnTypeOfRequest	= @nTypeOfRequest,
		@pnPolicingBatchNo	= @pnPolicingBatchNo,
		@pnAdHocNameNo		= @pnNameKey,
		@pdtAdHocDateCreated	= @pdtDateCreated
		
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateAdHocDate to public
GO

