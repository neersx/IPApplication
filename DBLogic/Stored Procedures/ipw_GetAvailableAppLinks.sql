-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetAvailableAppLinks
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetAvailableAppLinks]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetAvailableAppLinks.'
	Drop procedure [dbo].[ipw_GetAvailableAppLinks]
End
Print '**** Creating Stored Procedure dbo.ipw_GetAvailableAppLinks...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetAvailableAppLinks
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psAccessPoint		nvarchar(254)
)
as
-- PROCEDURE:	ipw_GetAvailableAppLinks
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Given an accesspoint, retrieve all Apps Link that the user has access to.
--				CHEC				

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 FEB 2013	SF		R13112	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

DECLARE	@nErrorCode			int
DECLARE @bIsExternalUser	bit
DECLARE	@dtToday			datetime
DECLARE @sLookupCulture		nvarchar(10)
DECLARE @tblAppsLink  		table (LinkId int	not null)

-- Initialise variables
SET @nErrorCode = 0
SET @dtToday = GETDATE()
SET @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)

If @nErrorCode = 0
Begin
	SELECT	@bIsExternalUser = ISEXTERNALUSER
    FROM	USERIDENTITY
    WHERE	IDENTITYID = @pnUserIdentityId
    
    SET @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	-- links that are available based on whether the user is internal or external
	
	INSERT	@tblAppsLink (LinkId)
	SELECT	AL.ID
	FROM	APPSLINK AL
	JOIN	ACCESSPOINT AP on (AL.ID = AP.APPSLINKID and AP.NAME = @psAccessPoint)
	WHERE	(AL.ISEXTERNAL = 1 and @bIsExternalUser = 1) or
			(AL.ISINTERNAL = 1 and @bIsExternalUser = 0)
			
	SET @nErrorCode = @@ERROR		
End

If @nErrorCode = 0
Begin
	-- remove links that do not meet task security checking requirements

	DELETE 
	FROM @tblAppsLink 
	WHERE LinkId not in (
		SELECT	AL.ID
		FROM	APPSLINK AL
		JOIN	ACCESSPOINT AP on (AL.ID = AP.APPSLINKID and AP.NAME = @psAccessPoint)
		JOIN	dbo.fn_PermissionsGranted(@pnUserIdentityId, 'TASK', null, null, @dtToday) P
				on (P.ObjectIntegerKey = AL.TASKID
					and ((P.CanInsert = 1 and AL.CHECKINSERT = 1) or AL.CHECKINSERT = 0)
					and ((P.CanUpdate = 1 and AL.CHECKUPDATE = 1) or AL.CHECKUPDATE = 0)
					and ((P.CanDelete = 1 and AL.CHECKDELETE = 1) or AL.CHECKDELETE = 0)
					and ((P.CanExecute = 1 and AL.CHECKEXECUTE = 1) or AL.CHECKEXECUTE = 0))
		UNION	
		SELECT	AL.ID
		FROM	APPSLINK AL
		WHERE	AL.TASKID is null)
	
	SET @nErrorCode = @@ERROR		
End

If @nErrorCode = 0
Begin
	SELECT	dbo.fn_GetTranslation(AL.TITLE, null, AL.TITLE_TID, @sLookupCulture) as 'Name', 
			dbo.fn_GetTranslation(AL.DESCRIPTION, null, AL.DESCRIPTION_TID, @sLookupCulture) as 'Description', 
			AL.URL as 'Url',
			AL.CHECKUPDATECASEACCESS as 'CheckUpdateCaseAccess',
			AL.CHECKUPDATENAMEACCESS as 'CheckUpdateNameAccess',
			AL.ISMULTIARG as 'IsMultiArg'
	FROM APPSLINK AL
	JOIN @tblAppsLink t on (t.LinkId = AL.ID)
	
	SET @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetAvailableAppLinks to public
GO
