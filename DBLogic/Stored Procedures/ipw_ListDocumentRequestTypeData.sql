-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListDocumentRequestTypeData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListDocumentRequestTypeData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListDocumentRequestTypeData.'
	Drop procedure [dbo].[ipw_ListDocumentRequestTypeData]
End
Print '**** Creating Stored Procedure dbo.ipw_ListDocumentRequestTypeData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListDocumentRequestTypeData
(
	@pnUserIdentityId				int,		-- Mandatory
	@psCulture						nvarchar(10) 	= null,
	@pnDocumentDefinitionKey		int		= null,	
	@pbCalledFromCentura			bit		= 0
)
as
-- PROCEDURE:	ipw_ListDocumentRequestTypeData
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates a DocumentRequestTypeData dataset for maintenance purposes.  Call by WorkBenches

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 APR 2007	SF	RFC4710	1	Procedure created
-- 03 Dec 2007	vql	RFC5909	2	Change RoleKey and DocumentDefId from smallint to int.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)


-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- populate the DocumentDefinition data table
If @nErrorCode = 0
Begin
	Set @sSQLString ="
	Select	Cast(ISNULL(D.DOCUMENTDEFID,0) as nvarchar(15)) as 'RowKey',
			D.DOCUMENTDEFID		as 'DocumentDefinitionKey',	
			D.LETTERNO			as 'LetterCode',
			dbo.fn_GetTranslation(L.LETTERNAME,null,L.LETTERNAME_TID,@sLookupCulture) 
								as 'LetterName',			
			dbo.fn_GetTranslation(D.NAME,null,D.NAME_TID,@sLookupCulture)
								as 'Name',
			dbo.fn_GetTranslation(D.DESCRIPTION,null,D.DESCRIPTION_TID,@sLookupCulture)
								as 'Description',			
			D.CANFILTERCASES	as 'CanFilterCases',
			D.CANFILTEREVENTS	as 'CanFilterEvents',
			D.SENDERREQUESTTYPE	as 'SenderRequestTypeCode',
			dbo.fn_GetTranslation(EDE.REQUESTTYPENAME,null,EDE.REQUESTTYPENAME_TID,@sLookupCulture) 
								as 'SenderRequestType'
	from	DOCUMENTDEFINITION D
	left join	LETTER L on (L.LETTERNO = D.LETTERNO)
	left join	EDEREQUESTTYPE EDE on (EDE.REQUESTTYPECODE = D.SENDERREQUESTTYPE)
	where	D.DOCUMENTDEFID = @pnDocumentDefinitionKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnDocumentDefinitionKey		int,
					@sLookupCulture					nvarchar(10)',
					@pnDocumentDefinitionKey		= @pnDocumentDefinitionKey,
					@sLookupCulture					= @sLookupCulture
End

-- populate the ActingAs data table
If @nErrorCode = 0
Begin
	Set @sSQLString ="
	Select	N.NAMETYPE					as 'RowKey',
			@pnDocumentDefinitionKey	as 'DocumentDefinitionKey',	
			N.NAMETYPE					as 'NameTypeKey',
			dbo.fn_GetTranslation(N.DESCRIPTION,null,N.DESCRIPTION_TID,@sLookupCulture)
										as 'NameType',
			Case when (D.NAMETYPE = N.NAMETYPE) then 1 else 0 end
										as 'IsSelected'
	from	 NAMETYPE N
	left join	DOCUMENTDEFINITIONACTINGAS D on (N.NAMETYPE = D.NAMETYPE
											and (D.DOCUMENTDEFID = @pnDocumentDefinitionKey or D.DOCUMENTDEFID is null))
	order by 'NameType'
	"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnDocumentDefinitionKey		int,
					@sLookupCulture					nvarchar(10)',
					@pnDocumentDefinitionKey		= @pnDocumentDefinitionKey,
					@sLookupCulture					= @sLookupCulture
End

-- populate the ExportFormat data table
If @nErrorCode = 0
Begin
	Set @sSQLString ="	
	Select	Cast(TC.TABLECODE as nvarchar(15))
										as 'RowKey',
			@pnDocumentDefinitionKey	as 'DocumentDefinitionKey',	
			TC.TABLECODE				as 'ExportFormatKey',
			dbo.fn_GetTranslation(TC.DESCRIPTION,null,TC.DESCRIPTION_TID,@sLookupCulture)					
										as 'ExportFormatDescription',
			ISNULL(V.ISDEFAULT,0)		as 'IsDefault',
			Case when TC.TABLECODE=V.FORMATID then 1 else 0 end
										as 'IsSelected'
	from	TABLECODES TC
	left	join VALIDEXPORTFORMAT V on (V.FORMATID = TC.TABLECODE and (V.DOCUMENTDEFID = @pnDocumentDefinitionKey or V.DOCUMENTDEFID is null))
	where	 TC.TABLETYPE=137
	order by 'ExportFormatDescription'
	"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnDocumentDefinitionKey		int,
					@sLookupCulture					nvarchar(10)',
					@pnDocumentDefinitionKey		= @pnDocumentDefinitionKey,
					@sLookupCulture					= @sLookupCulture
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListDocumentRequestTypeData to public
GO
