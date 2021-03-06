-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteAllEmptyTabControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteAllEmptyTabControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteAllEmptyTabControl.'
	Drop procedure [dbo].[ipw_DeleteAllEmptyTabControl]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteAllEmptyTabControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_DeleteAllEmptyTabControl]
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null
)
as
-- PROCEDURE:	ipw_DeleteAllEmptyTabControl
-- VERSION:	1
-- DESCRIPTION:	Delete all TabControls with no topic specified.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Jan 2010	KR		RFC6732	1		Procedure created


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode			int
declare @sSQLString 		nvarchar(4000)

set @nErrorCode = 0

--Delete the tab
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
		Delete from TABCONTROL where  not exists
		(select * from TOPICCONTROL T where T.TABCONTROLNO = TABCONTROL.TABCONTROLNO)"
		
	exec @nErrorCode=sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteAllEmptyTabControl to public
GO
