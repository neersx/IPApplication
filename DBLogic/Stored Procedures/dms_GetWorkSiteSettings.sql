-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dms_GetSettings
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dms_GetWorkSiteSettings]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dms_GetWorkSiteSettings.'
	Drop procedure [dbo].dms_GetWorkSiteSettings
End
Print '**** Creating Stored Procedure dbo.dms_GetWorkSiteSettings...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.dms_GetWorkSiteSettings
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null
)
as
-- PROCEDURE:	dms_GetWorkSiteSettings
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This stored procedure retrieves login and password of the useridentity
--				to connect to WorkSite

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 DEC 2009	JCLG	RFC8535	1		Procedure created
-- 14 MAY 2015	SF	R47579	2		PASSWORD is not required for some Login Types

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	SELECT 
		L.COLCHARACTER AS LoginID,
		P.COLCHARACTER AS Password
	FROM USERIDENTITY U
	JOIN SETTINGVALUES L ON (L.IDENTITYID = U.IDENTITYID AND L.SETTINGID = 9) -- 'WORKSITE LOGIN'
	LEFT JOIN SETTINGVALUES P ON (P.IDENTITYID = U.IDENTITYID AND P.SETTINGID = 10) -- 'WORKSITE PASSWORD'
	where U.IDENTITYID = @pnUserIdentityId

End


Return @nErrorCode
GO

Grant execute on dbo.dms_GetWorkSiteSettings to public
GO
