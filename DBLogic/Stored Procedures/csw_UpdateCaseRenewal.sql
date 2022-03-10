-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateCaseRenewal									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateCaseRenewal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateCaseRenewal.'
	Drop procedure [dbo].[csw_UpdateCaseRenewal]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateCaseRenewal...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[csw_UpdateCaseRenewal]
(
        @pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnRenewalStatusKey             int             = null,
	@pnRenewalTypeKey               int             = null,
	@pnExtendedRenewals             int             = null,
	@pbReportToThirdParty           bit             = null,
	@psRenewalNotes                 nvarchar(254)   = null,
	@pdtStartPayDate                datetime        = null,
	@pdtStopPayDate                 datetime        = null,
	@psStopPayReason                nchar(1)        = null,
	@pnPolicingBatchNo		int		= null,
	@pnOldRenewalStatusKey          int             = null,
	@pnOldRenewalTypeKey            int             = null,
	@pnOldExtendedRenewals          int             = null,
	@pbOldReportToThirdParty        bit             = null,
	@psOldRenewalNotes              nvarchar(254)   = null,
	@pdtOldStartPayDate             datetime        = null,
	@pdtOldStopPayDate              datetime        = null,
	@psOldStopPayReason             nchar(1)        = null
)
AS
-- PROCEDURE:	csw_UpdateCaseRenewal
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Case Renewal Details if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 08 Aug 2008	LP	RFC4087	1	Procedure created
-- 26 Aug 2011  DV      R11094  2       Only Renewal Status, Notes, Report to CPA flag  will be allowed to be modified
-- 29 Sep 2011	LP	R11354  3	Insert PROPERTY record if none exists for the Case
--					Allow Update of REPORTTOTHIRDPARTY flag if initially NULL
-- 03 Sep 2012  MS      R12673  4       Allow ExtendedYears,RenewalType,StartPayDate,StopPayDate and StopPayReason to modify       
-- 04 Oct 2012	LP	R12817	5	Fix error when updating StartPayDate and StopPayDate fields 
-- 10 Sep 2019	DV	D34750	6	Trigger policing on change of renewal type

SET CONCAT_NULL_YIELDS_NULL OFF 
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @bHasEventDate  bit
Declare @sAlertXML 	nvarchar(400)

Declare @nStartDateEventNo  int
Declare @nStopDateEventNo   int

-- Initialise variables
Set @nErrorCode = 0
Set @bHasEventDate = 0

If @nErrorCode = 0
Begin
        Set @sSQLString = "Select @nStartDateEventNo = S1.COLINTEGER,
                                @nStopDateEventNo = S2.COLINTEGER
                        from SITECONTROL S1 
                        left join SITECONTROL S2 on (S2.CONTROLID='CPA Date-Stop')
                        where S1.CONTROLID = 'CPA Date-Start'"
                        
        exec @nErrorCode = sp_executesql @sSQLString,
                           N'@nStartDateEventNo         int     OUTPUT,
                           @nStopDateEventNo            int     OUTPUT',
                           @nStartDateEventNo           = @nStartDateEventNo    OUTPUT,
                           @nStopDateEventNo            = @nStopDateEventNo     OUTPUT
End

-- Update Property
If @nErrorCode = 0
Begin
	-- if row does not exist for the case, insert a new record	
	If not exists (SELECT 1 from PROPERTY where CASEID = @pnCaseKey)
	Begin
		set @sSQLString = "INSERT INTO PROPERTY(CASEID, RENEWALSTATUS, RENEWALNOTES, RENEWALTYPE)
                values	(@pnCaseKey, @pnRenewalStatusKey, @psRenewalNotes, @pnRenewalTypeKey)"
       
		exec @nErrorCode = sp_executesql @sSQLString,
                                        N'@pnCaseKey            int,
                                        @pnRenewalStatusKey     int,
                                        @pnRenewalTypeKey       int,
                                        @psRenewalNotes         nvarchar(254)',
                                        @pnCaseKey              = @pnCaseKey,
                                        @pnRenewalStatusKey     = @pnRenewalStatusKey,
                                        @pnRenewalTypeKey       = @pnRenewalTypeKey,
                                        @psRenewalNotes         = @psRenewalNotes
	End
	Else
	Begin
       
		if(not exists (Select 1 from PROPERTY where CASEID = @pnCaseKey
			and RENEWALSTATUS = @pnOldRenewalStatusKey
			and RENEWALNOTES = @psOldRenewalNotes
			and RENEWALTYPE = @pnOldRenewalTypeKey))
		Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('SF29', 'Concurrency violation: The Update command affected 0 records.',
				null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR 
		End
		Else
		Begin

		set @sSQLString = "UPDATE PROPERTY
			set RENEWALSTATUS = @pnRenewalStatusKey,
			RENEWALNOTES =  @psRenewalNotes,
			RENEWALTYPE = @pnRenewalTypeKey           
			where CASEID = @pnCaseKey
			and RENEWALSTATUS = @pnOldRenewalStatusKey
			and RENEWALNOTES = @psOldRenewalNotes
			and RENEWALTYPE = @pnOldRenewalTypeKey"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey            int,
					@pnRenewalStatusKey     int,
					@psRenewalNotes         nvarchar(254), 
					@pnRenewalTypeKey       int,                                     
					@pnOldRenewalStatusKey  int,
					@psOldRenewalNotes      nvarchar(254),
					@pnOldRenewalTypeKey    int',
					@pnCaseKey              = @pnCaseKey,
					@pnRenewalStatusKey     = @pnRenewalStatusKey,
					@psRenewalNotes         = @psRenewalNotes,
					@pnRenewalTypeKey       = @pnRenewalTypeKey,
					@pnOldRenewalStatusKey  = @pnOldRenewalStatusKey,
					@psOldRenewalNotes      = @psOldRenewalNotes,
					@pnOldRenewalTypeKey    = @pnOldRenewalTypeKey
		End
        END
		If @nErrorCode = 0 and @pnOldRenewalTypeKey <> @pnRenewalTypeKey
		Begin
			declare @openAction nvarchar(10)
			declare validActionCursor CURSOR LOCAL for
						SELECT O.ACTION
						FROM OPENACTION O  join CASES C		on (C.CASEID=O.CASEID)  
						join ACTIONS A		on (A.ACTION=O.ACTION)  
						join VALIDACTION VA	on (VA.ACTION=O.ACTION  			
						and VA.CASETYPE=C.CASETYPE  			
						and VA.PROPERTYTYPE=C.PROPERTYTYPE  			
						and VA.COUNTRYCODE=(select min(VA1.COUNTRYCODE)  						
												from VALIDACTION VA1  						
												where VA1.CASETYPE=VA.CASETYPE  						
												and VA1.PROPERTYTYPE=VA.PROPERTYTYPE  	
												and VA1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))  
						WHERE O.CASEID = @pnCaseKey

			open validActionCursor

			fetch next from validActionCursor into @openAction

			while @@FETCH_STATUS = 0 BEGIN

				--execute your sproc on each row
				exec @nErrorCode = ip_InsertPolicing
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture 		= @psCulture,
					@psCaseKey 		= @pnCaseKey,
					@psEventKey		= null,
					@pnCycle		= 1,
					@psAction		= @openAction,
					@pnCriteriaNo		= null,
					@pnTypeOfRequest	= 4,
					@pnPolicingBatchNo	= @pnPolicingBatchNo

				fetch next from validActionCursor into @openAction
			END
			close validActionCursor
			deallocate validActionCursor
		End
End

-- Update Case
If @nErrorCode = 0
Begin
	if(not exists (Select 1 from CASES where CASEID = @pnCaseKey
		and (REPORTTOTHIRDPARTY = @pbOldReportToThirdParty OR REPORTTOTHIRDPARTY IS NULL)
		and (EXTENDEDRENEWALS = @pnOldExtendedRenewals)
		and (STOPPAYREASON = @psOldStopPayReason)))
	Begin
	       Set @sAlertXML = dbo.fn_GetAlertXML('SF29', 'Concurrency violation: The Update command affected 0 records.',
				null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR 
	End
	Else
	Begin
	Set @sSQLString = "	
	UPDATE CASES
	SET REPORTTOTHIRDPARTY = @pbReportToThirdParty,
	EXTENDEDRENEWALS = @pnExtendedRenewals,
	STOPPAYREASON = @psStopPayReason
	where CASEID = @pnCaseKey
	and (REPORTTOTHIRDPARTY = @pbOldReportToThirdParty or REPORTTOTHIRDPARTY IS NULL)
	and EXTENDEDRENEWALS = @pnOldExtendedRenewals
	and STOPPAYREASON = @psOldStopPayReason"
        
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey			int,
					@pbReportToThirdParty           bit,
					@pnExtendedRenewals             int,
					@psStopPayReason                nchar(1),
					@pnOldExtendedRenewals	        int,                             
					@pbOldReportToThirdParty        bit,
					@psOldStopPayReason             nchar(1)',
					@pnCaseKey                      = @pnCaseKey,
					@pbReportToThirdParty           = @pbReportToThirdParty,
					@pnExtendedRenewals             = @pnExtendedRenewals,
					@psStopPayReason                = @psStopPayReason,
					@pnOldExtendedRenewals          = @pnOldExtendedRenewals,
					@pbOldReportToThirdParty        = @pbOldReportToThirdParty,
					@psOldStopPayReason             = @psOldStopPayReason
	End
End

-- Update Case Start Pay Date
If @nErrorCode = 0 and @pdtStartPayDate <> @pdtOldStartPayDate and @nStartDateEventNo is not null
Begin
        if(not exists (Select 1 from CASEEVENT CE where CASEID = @pnCaseKey and EVENTNO = @nStartDateEventNo))
	Begin
	       Set @sSQLString = "INSERT INTO CASEEVENT (CASEID, CYCLE, EVENTNO, DATEDUESAVED, EVENTDATE,  OCCURREDFLAG)
	                        VALUES (@pnCaseKey,1,@nStartDateEventNo, 0, @pdtStartPayDate, 1)"
	                        
	       exec @nErrorCode=sp_executesql @sSQLString,
	                        N'@pnCaseKey			int,
	                        @nStartDateEventNo            int,
	                        @pdtStartPayDate                datetime',
	                        @pnCaseKey			= @pnCaseKey,
	                        @nStartDateEventNo              = @nStartDateEventNo,
	                        @pdtStartPayDate                = @pdtStartPayDate
	End
	Else
	Begin
	Set @sSQLString = "UPDATE CASEEVENT
	                  SET   EVENTDATE = @pdtStartPayDate,
	                        OCCURREDFLAG = CASE WHEN @pdtStartPayDate is null THEN 0 ELSE 1 END,
	                        DATEDUESAVED = 0,
	                        EVENTDUEDATE = null	
	                where CASEID = @pnCaseKey
	                and EVENTDATE = @pdtOldStartPayDate
	                and EVENTNO = @nStartDateEventNo
	                and CYCLE = 1"
        
	exec @nErrorCode=sp_executesql @sSQLString,
	                        N'@pnCaseKey                    int,
	                        @nStartDateEventNo              int,
	                        @pdtStartPayDate                datetime,
	                        @pdtOldStartPayDate             datetime',
	                        @pnCaseKey                      = @pnCaseKey,
	                        @nStartDateEventNo              = @nStartDateEventNo,
	                        @pdtStartPayDate                = @pdtStartPayDate,
	                        @pdtOldStartPayDate             = @pdtOldStartPayDate
	End
	
	-- Police event change
	exec @nErrorCode = ip_InsertPolicing
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture 		= @psCulture,
		@psCaseKey 		= @pnCaseKey,
		@psEventKey		= @nStartDateEventNo,
		@pnCycle		= 1,
		@psAction		= null,
		@pnCriteriaNo		= null,
		@pnTypeOfRequest	= 3,
		@pnPolicingBatchNo	= @pnPolicingBatchNo
End

-- Update Case Stop Pay Date
If @nErrorCode = 0 and @pdtStopPayDate <> @pdtOldStopPayDate and @nStopDateEventNo is not null
Begin
        if(exists (Select 1 from CASEEVENT CE where CASEID = @pnCaseKey and EVENTNO = @nStopDateEventNo))
	Begin
	       Set @sSQLString = "UPDATE CASEEVENT
	                  SET   EVENTDATE = @pdtStopPayDate,
	                        OCCURREDFLAG = CASE WHEN @pdtStopPayDate is null THEN 0 ELSE 1 END,
	                        DATEDUESAVED = 0,
	                        EVENTDUEDATE = null	
	                where CASEID = @pnCaseKey
	                and EVENTDATE = @pdtOldStopPayDate
	                and EVENTNO = @nStopDateEventNo
	                and CYCLE = 1"
        
	        exec @nErrorCode=sp_executesql @sSQLString,
	                        N'@pnCaseKey                    int,
	                        @nStopDateEventNo              int,
	                        @pdtStopPayDate                datetime,
	                        @pdtOldStopPayDate             datetime',
	                        @pnCaseKey                      = @pnCaseKey,
	                        @nStopDateEventNo              = @nStopDateEventNo,
	                        @pdtStopPayDate                = @pdtStopPayDate,
	                        @pdtOldStopPayDate             = @pdtOldStopPayDate	       
	End
	Else
	Begin
	        Set @sSQLString = "INSERT INTO CASEEVENT (CASEID, CYCLE, EVENTNO, DATEDUESAVED, EVENTDATE,  OCCURREDFLAG)
	                        VALUES (@pnCaseKey,1,@nStopDateEventNo, 0, @pdtStopPayDate, 1)"
	                        
	        exec @nErrorCode=sp_executesql @sSQLString,
	                        N'@pnCaseKey			int,
	                        @nStopDateEventNo            int,
	                        @pdtStopPayDate                datetime',
	                        @pnCaseKey			= @pnCaseKey,
	                        @nStopDateEventNo              = @nStopDateEventNo,
	                        @pdtStopPayDate                = @pdtStopPayDate
	End
	
	-- Police event change
	exec @nErrorCode = ip_InsertPolicing
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture 		= @psCulture,
		@psCaseKey 		= @pnCaseKey,
		@psEventKey		= @nStopDateEventNo,
		@pnCycle		= 1,
		@psAction		= null,
		@pnCriteriaNo		= null,
		@pnTypeOfRequest	= 3,
		@pnPolicingBatchNo	= @pnPolicingBatchNo
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateCaseRenewal to public
GO