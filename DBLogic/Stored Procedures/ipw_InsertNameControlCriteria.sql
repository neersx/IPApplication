-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertNameControlCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertNameControlCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertNameControlCriteria.'
	Drop procedure [dbo].[ipw_InsertNameControlCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertNameControlCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[ipw_InsertNameControlCriteria]
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCriteriaNo			int		= null		output,
	@psPurposeCode			nchar(1)	= 'W',	
	@psProgramId			nvarchar(8)	= null,	
	@pbIsOrganisation		bit		= null,
	@pbIsStaff			bit		= null,
	@pbIsClient			bit		= null,
	@pbIsSupplier			bit		= null,
	@pbDataUnknown			bit		= 0,
	@psCountryCode			nvarchar(3)	= null,
	@pbLocalClientFlag		bit		= null,
	@pnCategory			int		= null,
	@psNameType			nvarchar(3)	= null,
	@psRelationship			nvarchar(3)	= null,
	@pbUserDefinedRule		bit		= 0,
	@pbRuleInUse			bit		= 1,
	@pbIsCRMOnly			bit		= 0,
	@psDescription			nvarchar(254),	-- Mandatory
	@pnProfileKey			int		= null
)
as
-- PROCEDURE:	ipw_InsertNameControlCriteria
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Add a new NameCriteria.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Jul 2009	MS	RFC7085	1	Procedure created
-- 07 Aug 2009	MS	RFC7085	2	Added Data Unknown check
-- 11 Sep 2009	LP	RFC8047	3	Added ProfileKey parameters.
-- 21 Dec 2009	KR	RFC8704 4	Added USERDEFINEDRULE to the duplicate check list
-- 24 Oct 2017	AK	R72645	5	Make compatible with case sensitive server with case insensitive database.

SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT ON
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nUsedAsFlag 		smallint
Declare @sAlertXML		nvarchar(400)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0 
Begin	
	If @pbDataUnknown = 0
	Begin
		Set @nUsedAsFlag = coalesce(~@pbIsOrganisation, 0) * 1
				| isnull(@pbIsStaff, 0) * 2
				| isnull(@pbIsClient, 0) * 4	

		Set @pbIsSupplier = CASE WHEN @pbIsSupplier = 0 THEN null ELSE @pbIsSupplier END
		Set @pbLocalClientFlag = CASE WHEN @pbLocalClientFlag = 0 THEN null ELSE @pbLocalClientFlag END	
	End
	Else 
	Begin
		Set @nUsedAsFlag = null
		Set @pbIsSupplier = null
		Set @pbLocalClientFlag = null
	End
End

-- Check for Criteria existence
If @nErrorCode = 0
Begin
	if exists(Select 1 from NAMECRITERIA
			WHERE 
			(PURPOSECODE = @psPurposeCode)
			and (NAMETYPE = @psNameType)
			and (PROGRAMID = @psProgramId)
			and (CATEGORY = @pnCategory)
			and (COUNTRYCODE = @psCountryCode)
			and (USEDASFLAG = @nUsedAsFlag)	
			and (SUPPLIERFLAG = @pbIsSupplier)
			and (LOCALCLIENTFLAG = @pbLocalClientFlag)
			and (RELATIONSHIP = @psRelationship)
			and (DATAUNKNOWN = @pbDataUnknown)
			and (PROFILEID = @pnProfileKey)
			and (USERDEFINEDRULE = @pbUserDefinedRule))				
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('IP93', 'The criteria already exists.', null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR
	End
End

-- Check if NameType is CRM Name Type if CRM Only licenece is there
If @nErrorCode = 0 and @pbIsCRMOnly = 1 and @psNameType is not null
Begin
	if not exists(Select 1 from NAMETYPE 
			Where PICKLISTFLAGS & 32 = 32
			and NAMETYPE = @psNameType)								
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('IP94', 'CRM licensed users can only add or update rules containing CRM Only Name Types. Please check the Name Type.', null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR
	End
End

-- Get the LAST NAMECRITERIANO that need to be inserted
If @nErrorCode = 0 and @pbUserDefinedRule = 1
Begin
	Exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psTable		= N'NAMECRITERIA',
			@pnLastInternalCode	= @pnCriteriaNo OUTPUT	
End
Else if @nErrorCode = 0 and @pbUserDefinedRule = 0
Begin
	Exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@psTable			= N'NAMECRITERIA_MAXIM',
			@pbIsInternalCodeNegative	= 1,
			@pnLastInternalCode		= @pnCriteriaNo OUTPUT	
End 

If @nErrorCode = 0
Begin		
	
	Set @sSQLString = " 
	Insert into NAMECRITERIA
	  (	
		NAMECRITERIANO,
		PURPOSECODE, 
		PROGRAMID,
		USEDASFLAG,
		SUPPLIERFLAG,
		DATAUNKNOWN,
		COUNTRYCODE,
		LOCALCLIENTFLAG,
		CATEGORY,
		NAMETYPE,
		RELATIONSHIP,
		USERDEFINEDRULE,
		RULEINUSE,
		DESCRIPTION,
		PROFILEID
	  )
	Values	
	  (	
		@pnCriteriaNo,
		@psPurposeCode,
		@psProgramId,
		@nUsedAsFlag,
		@pbIsSupplier,
		@pbDataUnknown,
		@psCountryCode,
		@pbLocalClientFlag,
		@pnCategory,
		@psNameType,
		@psRelationship,
		@pbUserDefinedRule,
		@pbRuleInUse,
		@psDescription,
		@pnProfileKey)
	"

	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCriteriaNo			int,
				  @psPurposeCode		nchar(1),
				  @psProgramId			nvarchar(8),
				  @nUsedAsFlag			smallint,
				  @pbIsSupplier			bit,
				  @pbDataUnknown		bit,
				  @psCountryCode		nvarchar(3),
				  @pbLocalClientFlag		bit,
				  @pnCategory			int,
				  @psNameType			nvarchar(3),
				  @psRelationship		nvarchar(3),
				  @pbUserDefinedRule		bit,
				  @pbRuleInUse			bit,
				  @psDescription		nvarchar(254),
				  @pnProfileKey			int',	
				  @pnCriteriaNo			= @pnCriteriaNo, 
				  @psPurposeCode		= @psPurposeCode,
				  @psProgramId			= @psProgramId,
				  @nUsedAsFlag			= @nUsedAsFlag,
				  @pbIsSupplier			= @pbIsSupplier,
				  @pbDataUnknown		= @pbDataUnknown,
				  @psCountryCode		= @psCountryCode,
				  @pbLocalClientFlag		= @pbLocalClientFlag,
				  @pnCategory			= @pnCategory,
				  @psNameType			= @psNameType,
				  @psRelationship		= @psRelationship,
				  @pbUserDefinedRule		= @pbUserDefinedRule,
				  @pbRuleInUse			= @pbRuleInUse,
				  @psDescription		= @psDescription,
				  @pnProfileKey			= @pnProfileKey

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertNameControlCriteria to public
GO