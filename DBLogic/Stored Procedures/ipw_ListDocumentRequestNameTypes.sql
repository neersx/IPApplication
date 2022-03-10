-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListDocumentRequestNameTypes									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListDocumentRequestNameTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListDocumentRequestNameTypes.'
	Drop procedure [dbo].[ipw_ListDocumentRequestNameTypes]
End
Print '**** Creating Stored Procedure dbo.ipw_ListDocumentRequestNameTypes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListDocumentRequestNameTypes
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnDocumentRequestTypeKey	int		=null,
	@psNameTypeKeys			nvarchar(4000)	=null, -- Supports multiple name type keys delimited by '~sep~'
	@psPickListSearch		nvarchar(50)	=null
)
as
-- PROCEDURE:	ipw_ListDocumentRequestNameTypes
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List name type for supplied document request type. Also supports search multiple name types

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 19 Mar 2007	PG	RFC3646	1	Procedure created
-- 08 Apr 2016  MS      R52206  2       Addded fn_WrapQuotes for @psNameTypeKeys to avoid sql injection

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
	Select DA.NAMETYPE	as NameType,
	"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)
					+ " 			as Description
	From   DOCUMENTDEFINITIONACTINGAS DA join NAMETYPE NT on (NT.NAMETYPE=DA.NAMETYPE)

	Where  DA.DOCUMENTDEFID=@pnDocumentRequestTypeKey"
	
	If @psNameTypeKeys is not null 
	Begin
		If @psNameTypeKeys not like '%~sep~%'
		Begin
			Print 'not like '+ @psNameTypeKeys
			Set @sSQLString = @sSQLString+ " and DA.NAMETYPE  ="+ dbo.fn_WrapQuotes(@psNameTypeKeys,0,0)
		End
		Else
		Begin
			Print 'like ' +@psNameTypeKeys
			Set @sSQLString = @sSQLString+ " and DA.NAMETYPE  in (Select Parameter From dbo.fn_Tokenise(" + dbo.fn_WrapQuotes(@psNameTypeKeys,0,0) + ",'~sep~'))"
		End
	End
	Else If @psPickListSearch is not null
	Begin
		Set @sSQLString = @sSQLString+ " and UPPER(NT.DESCRIPTION) like "+ dbo.fn_WrapQuotes(UPPER(@psPickListSearch)+'%',0,0)
	End

	Set @sSQLString = @sSQLString+ " order by NT.DESCRIPTION"
       
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnDocumentRequestTypeKey	int',
			@pnDocumentRequestTypeKey	= @pnDocumentRequestTypeKey
	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListDocumentRequestNameTypes to public
GO