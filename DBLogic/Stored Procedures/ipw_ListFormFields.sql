-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListFormFields
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListFormFields]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListFormFields.'
	Drop procedure [dbo].[ipw_ListFormFields]
End
Print '**** Creating Stored Procedure dbo.ipw_ListFormFields...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListFormFields
(
	@pnUserIdentityId		int,	-- Mandatory
	@psCulture			nvarchar(10) = null,
	@pnDocumentKey			int,
	@pbCalledFromCentura	bit	= 0
)
as
-- PROCEDURE:	ipw_ListFormFields
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List all form fields for a PDF document

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	--------	-------	----------------------------------------------- 
-- 01 Aug 2011	JC	RFC10201	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
Declare @sSQLString		nvarchar(max)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode		= 0
set @sLookupCulture	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	-- Some code here
	Set @sSQLString = "
	Select 	F.FIELDNAME as FieldName,
		F.FIELDTYPE as FieldType,
		"+dbo.fn_SqlTranslatedColumn('FORMFIELD','FIELDDESCRIPTION',null,'F',@sLookupCulture,@pbCalledFromCentura)
			+ " as FieldDescription,
		I.ITEM_ID as ItemKey,
		I.ITEM_NAME as ItemName,
		"+dbo.fn_SqlTranslatedColumn('ITEM','ITEM_DESCRIPTION',null,'I',@sLookupCulture,@pbCalledFromCentura)
			+ " as ItemDescription,
		F.ITEMPARAMETER as Parameters,
		F.RESULTSEPARATOR as Separator,
		F.DOCUMENTNO as DocumentKey
	from FORMFIELDS F
	left join ITEM I on (I.ITEM_ID = F.ITEM_ID)
	where F.DOCUMENTNO = @pnDocumentKey
	order by 1"

	exec @nErrorCode = sp_executesql @sSQLString, 
		N'@pnDocumentKey int',
		  @pnDocumentKey = @pnDocumentKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListFormFields to public
GO
