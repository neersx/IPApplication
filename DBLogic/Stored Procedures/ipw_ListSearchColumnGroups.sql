-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListSearchColumnGroups
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListSearchColumnGroups]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListSearchColumnGroups.'
	Drop procedure [dbo].[ipw_ListSearchColumnGroups]
End
Print '**** Creating Stored Procedure dbo.ipw_ListSearchColumnGroups...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListSearchColumnGroups
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListSearchColumnGroups
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the list of functions.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Oct 2010	DV		RFC9437		1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
Declare @sLookupCulture		nvarchar(10)
Declare @sSQLString			nvarchar(4000)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "SELECT QCG.GROUPID as 'Key',
			" + dbo.fn_SqlTranslatedColumn('QUERYCOLUMNGROUP','GROUPNAME',null,'QCG',@sLookupCulture,@pbCalledFromCentura) + " as 'Description' ,
			QCG.CONTEXTID as QueryContext
			FROM QUERYCOLUMNGROUP QCG
			Order by 2"

	exec @nErrorCode = sp_executesql @sSQLString


End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListSearchColumnGroups to public
GO
