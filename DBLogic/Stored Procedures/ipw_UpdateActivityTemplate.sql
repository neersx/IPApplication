-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateActivityTemplate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateActivityTemplate.'
	Drop procedure [dbo].[ipw_UpdateActivityTemplate]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateActivityTemplate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[ipw_UpdateActivityTemplate]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psActivityTemplateCode	nvarchar(20),    -- Mandatory		
	@pnContactKey		int		= null,
	@pnRegardingKey		int		= null,
	@pnCaseKey		int		= null,
	@pnReferredToKey	int		= null,
	@pbIsIncomplete		bit		= null,
	@psSummary		nvarchar(254)	= null,
	@pnCallStatusCode	smallint	= null,
	@pnActivityCategoryKey	int		= null,
	@psReferenceNo		nvarchar(20)	= null,
	@ptNotes		ntext		= null,
	@psClientReference	nvarchar(50)	= null,
	@pbCreateAdhocDate	bit		= 0,
	@pdtLogDateTimeStamp	datetime	= null
)
-- PROCEDURE:	ipw_UpdateActivityTemplate
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update a Contact Activity Template if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 25 Sep 2014  DV	R26412	 1	Procedure created. 
-- 01 Jun 2015  MS  R47576   2  Increase size of Summary from 100 to 254
-- 23 Mar 2020	BS	DR-57435 3	DB public role missing execute permission on some stored procedures and functions

AS

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON


Declare @nErrorCode	int
Declare @sSQLString	nvarchar(4000)

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
				  @bIsExternalUser	=@bIsExternalUser  OUTPUT,
				  @nAccessAccountId 	=@nAccessAccountId OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

-- Update the Activity
If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	Update ACTIVITYTEMPLATE
	set	NAMENO			= @pnContactKey,
		RELATEDNAME		= @pnRegardingKey,
		CASEID			= @pnCaseKey,
		REFERREDTO		= @pnReferredToKey,
		INCOMPLETE		= CAST(@pbIsIncomplete as decimal(1,0)),
		SUMMARY			= @psSummary,
		CALLSTATUS		= @pnCallStatusCode,
		ACTIVITYCATEGORY	= @pnActivityCategoryKey,
		REFERENCENO		= @psReferenceNo,
		NOTES			= @ptNotes,
		CLIENTREFERENCE		= @psClientReference,
		CREATEADHOCDATE         = @pbCreateAdhocDate	
	where   ACTIVITYTEMPLATECODE	= @psActivityTemplateCode
	and	ISEXTERNAL		= @bIsExternalUser
	and	LOGDATETIMESTAMP	= @pdtLogDateTimeStamp"
	
	If @bIsExternalUser = 1 
	Begin
		Set @sSQLString = @sSQLString +CHAR(10)+"and ACCESSACCOUNTID =@nAccessAccountId" 
	End

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psActivityTemplateCode	nvarchar(20),
					  @pnContactKey		int,
					  @pnRegardingKey	int,
					  @pnCaseKey		int,
					  @pnReferredToKey	int,
					  @pbIsIncomplete	bit,
					  @psSummary		nvarchar(254),
					  @pnCallStatusCode	smallint,
					  @pnActivityCategoryKey int,
					  @psReferenceNo	nvarchar(20),
					  @ptNotes		ntext,
					  @psClientReference	nvarchar(50),
					  @pbCreateAdhocDate    bit,	
					  @bIsExternalUser	bit,
					  @nAccessAccountId	int,				  
					  @pdtLogDateTimeStamp	datetime',					  
					  @psActivityTemplateCode	= @psActivityTemplateCode,
					  @pnContactKey		= @pnContactKey,
					  @pnRegardingKey	= @pnRegardingKey,
					  @pnCaseKey		= @pnCaseKey,
					  @pnReferredToKey	= @pnReferredToKey,
					  @pbIsIncomplete	= @pbIsIncomplete,
					  @psSummary		= @psSummary,
					  @pnCallStatusCode 	= @pnCallStatusCode,
					  @pnActivityCategoryKey = @pnActivityCategoryKey,
					  @psReferenceNo	= @psReferenceNo,
					  @ptNotes		= @ptNotes,
					  @psClientReference	= @psClientReference,
					  @pbCreateAdhocDate    = @pbCreateAdhocDate,
					  @bIsExternalUser	= @bIsExternalUser,
					  @nAccessAccountId	= @nAccessAccountId,
					  @pdtLogDateTimeStamp	= @pdtLogDateTimeStamp
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateActivityTemplate to public
GO

