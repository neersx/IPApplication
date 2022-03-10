-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListValidExportFormat									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListValidExportFormat]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListValidExportFormat.'
	Drop procedure [dbo].[ipw_ListValidExportFormat]
End
Print '**** Creating Stored Procedure dbo.ipw_ListValidExportFormat...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListValidExportFormat
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnDocumentRequestTypeKey	int		= null
)
as
-- PROCEDURE:	ipw_ListValidExportFormat
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List valid export format for document request types

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 19 Mar 2007	PG	RFC3646	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString ="
	Select  EF.FORMATID	as FormatKey,
        	dbo.fn_GetTranslation(TC.DESCRIPTION,null,TC.DESCRIPTION_TID,@sLookupCulture)
				as Description,
		EF.ISDEFAULT	as IsDefault
	From	VALIDEXPORTFORMAT EF join TABLECODES TC on (TC.TABLECODE=EF.FORMATID and TC.TABLETYPE=137)
	Where 	EF.DOCUMENTDEFID=@pnDocumentRequestTypeKey order by EF.ISDEFAULT DESC"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnDocumentRequestTypeKey	int,
					@sLookupCulture			nvarchar(10)',
					@pnDocumentRequestTypeKey	= @pnDocumentRequestTypeKey,
					@sLookupCulture			= @sLookupCulture
	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListValidExportFormat to public
GO