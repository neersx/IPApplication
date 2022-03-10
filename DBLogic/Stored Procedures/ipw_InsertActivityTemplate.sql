-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertActivityTemplate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertActivityTemplate.'
	Drop procedure [dbo].[ipw_InsertActivityTemplate]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertActivityTemplate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_InsertActivityTemplate
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psActivityTemplateCode	nvarchar(20),    -- Mandatory
	@pnContactKey		int		= null,	
	@pnRegardingKey		int		= null,
	@pnCaseKey		int		= null,
	@pnReferredToKey	int		= null,
	@pbIsIncomplete		bit		= 0,
	@psSummary		nvarchar(254)	= null,
	@pnCallStatusCode	smallint	= null,
	@pnActivityCategoryKey	int		= null,
	@psReferenceNo		nvarchar(20)	= null,
	@ptNotes		ntext		= null,
	@psClientReference	nvarchar(50)	= null,
	@pbCreateAdhocDate	bit		= 0
)
-- PROCEDURE:	ipw_InsertActivityTemplate
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Create a new Contact Activity Template.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 25 Sep 2014  DV	R26412	1	Procedure created. 
-- 01 Jun 2015  MS      R47576  2       Increase size of Summary from 100 to 254

AS

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON


Declare @nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sAlertXML		nvarchar(1000)
Declare @bIsExternalUser	bit
Declare @nAccessAccountId	int


-- Initialise variables
Set @nErrorCode 	= 0

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select	@bIsExternalUser=ISEXTERNALUSER,
	@nAccessAccountId=ACCOUNTID
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit		  OUTPUT,
				  @nAccessAccountId 	int		  OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser OUTPUT,
				  @nAccessAccountId	=@nAccessAccountId  OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

If @nErrorCode = 0 and exists (Select 1 from ACTIVITYTEMPLATE 
			   where ACTIVITYTEMPLATECODE = @psActivityTemplateCode
			   and ISEXTERNAL = @bIsExternalUser
			   and (@bIsExternalUser = 0 or ACCESSACCOUNTID = @nAccessAccountId))
Begin	
	Set @sAlertXML = dbo.fn_GetAlertXML('IP142', 'The Activity Template code already exists.',
							null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@Error
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	insert into ACTIVITYTEMPLATE (
		ACTIVITYTEMPLATECODE,
		NAMENO,
		RELATEDNAME,
		CASEID,
		REFERREDTO,
		INCOMPLETE,
		SUMMARY,
		CALLSTATUS,
		ACTIVITYCATEGORY,
		REFERENCENO,
		NOTES,
		CLIENTREFERENCE,
		CREATEADHOCDATE,
		ISEXTERNAL,
		ACCESSACCOUNTID)
	values (
		@psActivityTemplateCode,
		@pnContactKey,
		@pnRegardingKey,
		@pnCaseKey,
		@pnReferredToKey,
		CAST(@pbIsIncomplete as decimal(1,0)),
		@psSummary,
		@pnCallStatusCode,
		@pnActivityCategoryKey,
		@psReferenceNo,
		@ptNotes,		
		@psClientReference,
		@pbCreateAdhocDate,
		@bIsExternalUser,
		@nAccessAccountId)
		"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psActivityTemplateCode	nvarchar(20),
					  @pnContactKey			int,					  
					  @pnRegardingKey		int,
					  @pnCaseKey			int,
					  @pnReferredToKey		int,
					  @pbIsIncomplete		bit,
					  @psSummary			nvarchar(254),
					  @pnCallStatusCode		smallint,
					  @pnActivityCategoryKey	int,
					  @psReferenceNo		nvarchar(20),
					  @ptNotes			ntext,
					  @psClientReference		nvarchar(50),
					  @pbCreateAdhocDate		bit,
					  @bIsExternalUser		bit,
					  @nAccessAccountId		int',					  
					  @psActivityTemplateCode	= @psActivityTemplateCode,
					  @pnContactKey			= @pnContactKey,
					  @pnRegardingKey		= @pnRegardingKey,
					  @pnCaseKey			= @pnCaseKey,
					  @pnReferredToKey		= @pnReferredToKey,
					  @pbIsIncomplete		= @pbIsIncomplete,
					  @psSummary			= @psSummary,
					  @pnCallStatusCode 		= @pnCallStatusCode,
					  @pnActivityCategoryKey	= @pnActivityCategoryKey,
					  @psReferenceNo		= @psReferenceNo,
					  @ptNotes			= @ptNotes,
					  @psClientReference		= @psClientReference,
					  @pbCreateAdhocDate		= @pbCreateAdhocDate,
					  @bIsExternalUser		= @bIsExternalUser,
					  @nAccessAccountId		= @nAccessAccountId


End


Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertActivityTemplate to public
GO

