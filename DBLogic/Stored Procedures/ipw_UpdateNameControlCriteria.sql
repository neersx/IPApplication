-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateNameControlCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateNameControlCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateNameControlCriteria.'
	Drop procedure [dbo].[ipw_UpdateNameControlCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateNameControlCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[ipw_UpdateNameControlCriteria]
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameCriteriaNo		int,		-- Mandatory
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
	@pbRuleInUse			bit		= 1,
	@pbIsCRMOnly			bit		= 0,
	@psDescription			nvarchar(254),  -- Mandatory
	@pnProfileKey			int		= null,
	@psOldPurposeCode		nchar(1)	= 'W',
	@psOldProgramId			nvarchar(8)	= null,
	@pbOldIsOrganisation		bit		= null,
	@pbOldIsStaff			bit		= null,
	@pbOldIsClient			bit		= null,
	@pbOldIsSupplier		bit		= null,	
	@pbOldDataUnknown		bit		= 0,
	@psOldCountryCode		nvarchar(3)	= null,
	@pbOldLocalClientFlag		bit		= null,
	@pnOldCategory			int		= null,
	@psOldNameType			nvarchar(3)	= null,
	@psOldRelationship		nvarchar(3)	= null,	
	@pbOldRuleInUse			bit		= 1,	
	@psOldDescription		nvarchar(254)	= null,
	@pnOldProfileKey		int		= null
)
as
-- PROCEDURE:	ipw_UpdateNameControlCriteria
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update a Name Criteria.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Jun 2009	MS	RFC7085	1	Procedure created
-- 10 Sep 2009	MS	RFC7085	2	Added Data Unknown check
-- 11 Sep 2009	LP	RFC8047	3	Added ProfileKey parameters
-- 18 Sep 2009	MS	RFC7085	4	Remove UserDefinedRule parameters
-- 24 Oct 2017	AK	R72645	5	Make compatible with case sensitive server with case insensitive database.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString	nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sAnd		nchar(5)
Declare @sAlertXML	nvarchar(400)
Declare @nUsedAsFlag	smallint
Declare @nOldUsedAsFlag	smallint

-- Initialise variables
Set @nErrorCode = 0
Set @sComma	= " "
Set @sAnd	= " and "
Set @sWhereString = CHAR(10)+" where "

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

	If @pbOldDataUnknown = 0
	Begin
		Set @nOldUsedAsFlag = coalesce(~@pbOldIsOrganisation, 0) * 1
				| isnull(@pbOldIsStaff, 0) * 2
				| isnull(@pbOldIsClient, 0) * 4
		Set @pbOldIsSupplier = CASE WHEN @pbOldIsSupplier = 0 THEN null ELSE @pbOldIsSupplier END
		Set @pbOldLocalClientFlag = CASE WHEN @pbOldLocalClientFlag = 0 THEN null ELSE @pbOldLocalClientFlag END	
	End
	Else
	Begin
		Set @nOldUsedAsFlag = null
		Set @pbOldIsSupplier = null
		Set @pbOldLocalClientFlag = null
	End

End

If @nErrorCode = 0
Begin
	If not(@psProgramId			= @psOldProgramId			 
	   	and @psCountryCode		= @psOldCountryCode			 
		and @psNameType			= @psOldNameType		 
		and @pnCategory			= @pnOldCategory		 
		and @nUsedAsFlag		= @nOldUsedAsFlag		 
		and @pbIsSupplier		= @pbOldIsSupplier		
		and @pbLocalClientFlag		= @pbOldLocalClientFlag	
		and @psRelationship		= @psOldRelationship	
		and @pbDataUnknown		= @pbOldDataUnknown
		and @pnProfileKey		= @pnOldProfileKey)		
	Begin	
		if exists(select 1 from NAMECRITERIA
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
				and (PROFILEID = @pnProfileKey))		
		Begin		
			Set @sAlertXML = dbo.fn_GetAlertXML('IP93', 'The criteria already exists.', null, null, null, null, null)
				RAISERROR(@sAlertXML, 12, 1)
				Set @nErrorCode = 1
		End
	
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
			Set @nErrorCode = 1
	End
End

If @nErrorCode = 0
Begin 
	Set @sSQLString = " 
	Update NAMECRITERIA
	Set		PURPOSECODE		= @psPurposeCode, 
			PROGRAMID		= @psProgramId,
			USEDASFLAG		= @nUsedAsFlag,
			SUPPLIERFLAG		= @pbIsSupplier,
			DATAUNKNOWN		= @pbDataUnknown,
			COUNTRYCODE		= @psCountryCode,
			LOCALCLIENTFLAG		= @pbLocalClientFlag,
			CATEGORY		= @pnCategory,
			NAMETYPE		= @psNameType,
			RELATIONSHIP		= @psRelationship,			
			RULEINUSE		= @pbRuleInUse,
			DESCRIPTION		= @psDescription,
			PROFILEID		= @pnProfileKey
	Where	NAMECRITERIANO	= @pnNameCriteriaNo
	And		PURPOSECODE		= @psOldPurposeCode 
	And		PROGRAMID		= @psOldProgramId
	And		USEDASFLAG		= @nOldUsedAsFlag
	And		SUPPLIERFLAG		= @pbOldIsSupplier
	And		DATAUNKNOWN		= @pbOldDataUnknown
	And		COUNTRYCODE		= @psOldCountryCode
	And		LOCALCLIENTFLAG		= @pbOldLocalClientFlag
	And		CATEGORY		= @pnOldCategory
	And		NAMETYPE		= @psOldNameType
	And		RELATIONSHIP		= @psOldRelationship	
	And		RULEINUSE		= @pbOldRuleInUse
	And		DESCRIPTION		= @psOldDescription
	And		PROFILEID		= @pnOldProfileKey"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameCriteriaNo		int,
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
				  @pbRuleInUse			bit,
				  @psDescription		nvarchar(254),
				  @pnProfileKey			int,
				  @psOldPurposeCode		nchar(1),
				  @psOldProgramId		nvarchar(8),
				  @nOldUsedAsFlag		smallint,
				  @pbOldIsSupplier		bit,
				  @pbOldDataUnknown		bit,
				  @psOldCountryCode		nvarchar(3),
				  @pbOldLocalClientFlag		bit,
				  @pnOldCategory		int,
				  @psOldNameType		nvarchar(3),
				  @psOldRelationship		nvarchar(3),				 
				  @pbOldRuleInUse		bit,
				  @psOldDescription		nvarchar(254),
				  @pnOldProfileKey		int',					 
				  @pnNameCriteriaNo		= @pnNameCriteriaNo,
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
				  @pbRuleInUse			= @pbRuleInUse,
				  @psDescription		= @psDescription,
				  @pnProfileKey			= @pnProfileKey,
				  @psOldPurposeCode		= @psOldPurposeCode,
				  @psOldProgramId		= @psOldProgramId,
				  @nOldUsedAsFlag		= @nOldUsedAsFlag,
				  @pbOldIsSupplier		= @pbOldIsSupplier,
				  @pbOldDataUnknown		= @pbOldDataUnknown,
				  @psOldCountryCode		= @psOldCountryCode,
				  @pbOldLocalClientFlag		= @pbOldLocalClientFlag,
				  @pnOldCategory		= @pnOldCategory,
				  @psOldNameType		= @psOldNameType,
				  @psOldRelationship		= @psOldRelationship,				 
				  @pbOldRuleInUse		= @pbOldRuleInUse,
				  @psOldDescription		= @psOldDescription,
				  @pnOldProfileKey		= @pnOldProfileKey

End
GO

Grant execute on dbo.ipw_UpdateNameControlCriteria to public
GO