-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListDocumentRequestType									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListDocumentRequestType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListDocumentRequestType.'
	Drop procedure [dbo].[ipw_ListDocumentRequestType]
End
Print '**** Creating Stored Procedure dbo.ipw_ListDocumentRequestType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListDocumentRequestType
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@psPickListSearch		nvarchar(254)	= null
)
as
-- PROCEDURE:	ipw_ListDocumentRequestType
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List avaiable document request types

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 19 Mar 2007	PG	RFC3646	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString ="
	Select  DD.DOCUMENTDEFID	as DocumentRequestTypeKey,
		"+dbo.fn_SqlTranslatedColumn('DOCUMENTDEFINTION','NAME',null,'DD',@sLookupCulture,@pbCalledFromCentura)
					+ " 			as Name,
		"+dbo.fn_SqlTranslatedColumn('DOCUMENTDEFINTION','DESCRIPTION',null,'DD',@sLookupCulture,@pbCalledFromCentura)
					+ " 			as Description,
		DD.CANFILTERCASES	as CanFilterCases,
		DD.CANFILTEREVENTS	as CanFilterEvents
	from 	DOCUMENTDEFINITION DD"

	If @psPickListSearch is not null
	Begin
		Set @sSQLString = @sSQLString + " Where UPPER(DD.NAME) LIKE "+ dbo.fn_WrapQuotes(UPPER(@psPickListSearch)+'%',0,0)
		
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@psPickListSearch		nvarchar(254)',
			@psPickListSearch	 	= @psPickListSearch
	End
	Else
	Begin
		exec @nErrorCode=sp_executesql @sSQLString
		
	End
	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListDocumentRequestType to public
GO