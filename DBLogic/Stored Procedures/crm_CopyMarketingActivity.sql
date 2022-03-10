-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_CopyMarketingActivity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_CopyMarketingActivity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_CopyMarketingActivity.'
	Drop procedure [dbo].[crm_CopyMarketingActivity]
End
Print '**** Creating Stored Procedure dbo.crm_CopyMarketingActivity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.crm_CopyMarketingActivity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnParentCaseKey	int,
	@pnStaffKey             int,
	@pnCRMCaseStatusKey	int,
	@psCaseCategoryKey	nvarchar(2)	= null,
	@psCaseReference	nvarchar(30)	= '<Generate Reference>',
	@psShortTitle   	nvarchar(508)	= null,
	@psStem			nvarchar(30)	= null,	
	@pdBudget		decimal		= null,
	@pdtStartDate		datetime	= null,
	@pdtActualDate		datetime	= null,
	@pnExpectedResponses	int		= null,
	@pnPolicingBatchNo	int		= null,
	@psNewCaseKey		nvarchar(11)	= null output				
)
as
-- PROCEDURE:	crm_CopyMarketingActivity
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Creates a Marketing Activity based on an existing Marketing Activity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 Aug 2014	LP	R35916	1	Procedure created
-- 08 Sep 2014	JD	R39205	2	Fix Date Of Entry not created for copied Marketing Activities
-- 10 Sep 2019	BS	DR-28789 3	Trimmed leading and trailing blank spaces in IRN when creating new case.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @nNewCaseKey	int
declare @nProfileKey	int
declare @sAction	nvarchar(10)
declare @sSQLString	nvarchar(max)
declare @bHasInsertRights bit
declare @sAlertXML	nvarchar(400)
declare @dtToday	datetime

Set @nErrorCode = 0
Set @dtToday = dbo.fn_DateOnly(GETDATE())

If @nErrorCode = 0
Begin
	Exec @nErrorCode = ip_GetLastInternalCode 
		@pnUserIdentityId,
		@psCulture,
		'CASES',
		@nNewCaseKey output
	Set @psNewCaseKey = CAST(@nNewCaseKey as nvarchar(11))
End

-- Insert Case
If @nErrorCode = 0
Begin
	insert into CASES(CASEID, IRN, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, TITLE, BUDGETAMOUNT, STEM)
	select @nNewCaseKey,
		LTRIM(RTRIM(@psCaseReference)), 
		C.CASETYPE, 
		C.PROPERTYTYPE, 
		C.COUNTRYCODE, 
		ISNULL(@psCaseCategoryKey, C.CASECATEGORY), 
		ISNULL(@psShortTitle, C.TITLE), 
		ISNULL(@pdBudget, C.BUDGETAMOUNT),
		ISNULL(@psStem, C.STEM)
	from CASES C
	where C.CASEID = @pnParentCaseKey

End

-- Insert Case Names
If @nErrorCode= 0 and @pnStaffKey is not null
Begin
         -- Add Staff
        Insert into CASENAME ([SEQUENCE], NAMETYPE, NAMENO, CASEID)
        values (0, 'EMP', @pnStaffKey, @nNewCaseKey)

	Set @nErrorCode = @@ERROR
	
	If @nErrorCode = 0
        Begin
                -- Add Instructor
                Insert into CASENAME ([SEQUENCE], NAMETYPE, NAMENO, CASEID)
                VALUES (0, 'I', @pnStaffKey, @nNewCaseKey)

                Set @nErrorCode = @@ERROR
        End

        If @nErrorCode= 0 
        Begin
                 -- Add Owner
                Insert into CASENAME ([SEQUENCE], NAMETYPE, NAMENO, CASEID)
                VALUES (0, 'O', @pnStaffKey, @nNewCaseKey)

                Set @nErrorCode = @@ERROR
        End
End

-- Copy Contacts
If @nErrorCode = 0
Begin
	Insert into CASENAME ([SEQUENCE], NAMETYPE, NAMENO, 
		        CASEID, ADDRESSCODE, ASSIGNMENTDATE, 
		        BILLPERCENTAGE, COMMENCEDATE, 
		        CORRESPONDNAME, 
		        DERIVEDCORRNAME, 
		        EXPIRYDATE, INHERITED, REFERENCENO)
        Select [SEQUENCE], NAMETYPE, NAMENO, 
	        @nNewCaseKey, ADDRESSCODE, ASSIGNMENTDATE, 
	        BILLPERCENTAGE, COMMENCEDATE, 
	        case 
		        when DERIVEDCORRNAME = 0 then CORRESPONDNAME
		        else dbo.fn_GetDerivedAttnNameNo(NAMENO, @pnParentCaseKey, NAMETYPE) 
	        end,
	        DERIVEDCORRNAME, 
	        EXPIRYDATE, INHERITED, REFERENCENO
	        from CASENAME
	        where CASEID = @pnParentCaseKey
	        and NAMETYPE IN ('~CN')
	
	Set @nErrorCode = @@ERROR
End

-- Inherit new names
If @nErrorCode = 0
Begin
        exec @nErrorCode = cs_GenerateCaseName
	        @pnUserIdentityId = @pnUserIdentityId,
	        @psCulture = @psCulture,
	        @pnCaseKey = @nNewCaseKey
End

-- Insert Marketing
If @nErrorCode = 0
Begin
	Insert into MARKETING(CASEID, EXPECTEDRESPONSES)
	Select @nNewCaseKey, isnull(@pnExpectedResponses, M.EXPECTEDRESPONSES)
	from MARKETING M
	where M.CASEID = @pnParentCaseKey
End

-- Insert Dates
if @pdtStartDate is not null 
and @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.csw_InsertCaseEvent
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnCaseKey 		= @nNewCaseKey,
		@pnEventKey 		= -12210,
		@pnCycle		= 1,
		@pdtEventDate		= @pdtStartDate,
		@pbIsPolicedEvent 	= 0
End


if @pdtActualDate is not null 
and @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.csw_InsertCaseEvent
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnCaseKey 		= @nNewCaseKey,
		@pnEventKey 		= -12211,
		@pnCycle		= 1,
		@pdtEventDate		= @pdtActualDate,
		@pdtEventDueDate	= @pdtActualDate,
		@pbIsPolicedEvent 	= 0
End

if @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.csw_InsertCaseEvent
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnCaseKey 		= @nNewCaseKey,
		@pnEventKey 		= -13,
		@pnCycle		= 1,
		@pdtEventDate		= @dtToday,
		@pbIsPolicedEvent 	= 0
End

-- Update CRM Status
If @nErrorCode = 0
Begin
        exec @nErrorCode = dbo.crm_InsertCRMCaseStatusHistory   @pnUserIdentityId 	= @pnUserIdentityId,
							        @pnCaseKey		= @nNewCaseKey,
	                                                        @pnCRMCaseStatusKey	= @pnCRMCaseStatusKey
End

-- Use Generated Reference
If @nErrorCode = 0
and @psCaseReference = '<Generate Reference>' 
Begin
		Exec @nErrorCode = cs_ApplyGeneratedReference
			@psCaseReference	= @psCaseReference	OUTPUT, 
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture 		= @psCulture,
			@pnCaseKey		= @nNewCaseKey,
			@pnParentCaseKey	= @pnParentCaseKey
End

-- Get ProfileKey of the current user
If @nErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId
        
        Set @nErrorCode = @@ERROR
End

-- Request policing to open Action
If @nErrorCode = 0
Begin
	-- Get the Default Action from Screen Control
	Set @sSQLString = "	
	Select @sAction = CREATEACTION 
	from SCREENCONTROL S
	where S.SCREENID = 0
	and   S.SCREENNAME = N'frmCaseHistory'
	and   S.CRITERIANO = (Select dbo.fn_GetCriteriaNo(convert(int,@psNewCaseKey),
							  'S', -- (screen control)
							  SC.COLCHARACTER,
							  getdate(),
							  @nProfileKey)
			      from SITECONTROL SC
			      where SC.CONTROLID = 'CRM Screen Control Program')"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@sAction	nvarchar(2)	OUTPUT,
				  @psNewCaseKey	nvarchar(11),
				  @nProfileKey  int',
				  @sAction = @sAction	OUTPUT,
				  @psNewCaseKey	= @nNewCaseKey,
				  @nProfileKey = @nProfileKey
	
	-- Now insert the Policing request to open the action
	If @nErrorCode = 0
	and @sAction is not null
	Begin
		-- Add OpenAction Policing request
		If @nErrorCode = 0 and @sAction is not null
		Begin
			Exec @nErrorCode = ip_InsertPolicing
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture 		= @psCulture,
				@psCaseKey 		= @nNewCaseKey,
				@psSysGeneratedFlag	= 1, 
				@psAction		= @sAction,
				@pnTypeOfRequest	= 1,
				@pnPolicingBatchNo	= @pnPolicingBatchNo
		End
	End
	
End

-- Row level security

If @nErrorCode = 0
Begin
	Exec @nErrorCode = cs_GetSecurityForCase
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture = @psCulture,
		@pnCaseKey = @nNewCaseKey,
		@pbCanInsert = @bHasInsertRights output

	If @nErrorCode = 0 and @bHasInsertRights = 0
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS2', 'User has insufficient privileges to create this case. Please contact your system administrator.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode <> 0
Begin
	set @psNewCaseKey = null
End

Return @nErrorCode
GO

Grant execute on dbo.crm_CopyMarketingActivity to public
GO
