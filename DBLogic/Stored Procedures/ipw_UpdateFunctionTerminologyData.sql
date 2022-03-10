-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateFunctionTerminologyData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateFunctionTerminologyData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateFunctionTerminologyData.'
	Drop procedure [dbo].[ipw_UpdateFunctionTerminologyData]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateFunctionTerminologyData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateFunctionTerminologyData
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pnFunctionTypeKey		int,
	@psFunctionTypeDescription	nvarchar(254),
	@psOldFunctionTypeDescription	nvarchar(254),	
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_UpdateFunctionTerminologyData
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Modify an existing attribute against a user profile.

-- MODIFICATIONS :
-- Date			Who	 Change	 Version	Description
-- -----------	---- ------- ---------	----------------------------------------------- 
-- 15 Mar 2010	PA	 RFC8378	1		Procedure created
-- 30 Mar 2010  PA       RFC8378        2               Added "Function Terminology Description exists" check 
-- 27 Apr 2010  PA       RFC100229      3               Incorrect Alert message on Function Terminology Maintenance window
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sAlertXML	nvarchar(400)
declare @sSQLString	nvarchar(max)
-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
and @psFunctionTypeDescription <> @psOldFunctionTypeDescription
Begin	
	if (@psFunctionTypeDescription is not null and
		exists(select 1 from BUSINESSFUNCTION where DESCRIPTION = @psFunctionTypeDescription))
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('IP107', 'Function Terminology Description already exists.', null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	UPDATE BUSINESSFUNCTION
	SET DESCRIPTION = @psFunctionTypeDescription
	WHERE FUNCTIONTYPE = @pnFunctionTypeKey
	AND DESCRIPTION = @psOldFunctionTypeDescription		
	"
	
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnFunctionTypeKey		int,
		  @psFunctionTypeDescription	nvarchar(254),
		  @psOldFunctionTypeDescription	nvarchar(254)',
		  @pnFunctionTypeKey		= @pnFunctionTypeKey,
		  @psFunctionTypeDescription	= @psFunctionTypeDescription,
		  @psOldFunctionTypeDescription	= @psOldFunctionTypeDescription
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateFunctionTerminologyData to public
GO
