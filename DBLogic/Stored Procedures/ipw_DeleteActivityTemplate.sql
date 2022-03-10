-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteActivityTemplate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteActivityTemplate.'
	Drop procedure [dbo].[ipw_DeleteActivityTemplate]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteActivityTemplate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[ipw_DeleteActivityTemplate]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnActivityTemplateCode		nvarchar(20),		-- Mandatory		
	@pdtLogDateTimeStamp	datetime	-- Mandatory
)
-- PROCEDURE:	ipw_DeleteActivityTemplate
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete a Contact Activity Template if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 25 Sep 2014  DV	R26412	 1	Procedure created.
-- 23 Mar 2020	BS	DR-57435 2	DB public role missing execute permission on some stored procedures and functions
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

-- Delete the Activity template
If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	Delete
	from    ACTIVITYTEMPLATE 
	where   ACTIVITYTEMPLATECODE	= @pnActivityTemplateCode
	and	ISEXTERNAL		= @bIsExternalUser
	and	LOGDATETIMESTAMP	= @pdtLogDateTimeStamp"
	
	If @bIsExternalUser = 1 
	Begin
		Set @sSQLString = @sSQLString + " and ACCESSACCOUNTID =@nAccessAccountId"
	End

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnActivityTemplateCode	nvarchar(20),
					  @bIsExternalUser		bit,
					  @nAccessAccountId		int,
					  @pdtLogDateTimeStamp	datetime',					  
					  @pnActivityTemplateCode	= @pnActivityTemplateCode,
					  @bIsExternalUser		= @bIsExternalUser,
					  @nAccessAccountId		= @nAccessAccountId,
					  @pdtLogDateTimeStamp		= @pdtLogDateTimeStamp
					 
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteActivityTemplate to public
GO

