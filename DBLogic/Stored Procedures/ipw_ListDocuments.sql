-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListDocuments
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListDocuments]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListDocuments.'
	Drop procedure [dbo].[ipw_ListDocuments]
End
Print '**** Creating Stored Procedure dbo.ipw_ListDocuments...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListDocuments
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) = null,
	@pnDocumentType		int,
	@pnUsedBy		int,
	@pnNotUsedBy		int		= null,
	@pnCaseKey		int		= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListDocuments
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List all documents filtered by document type and used by

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 May 2010	JC	RFC6229	1	Procedure created
-- 10 Aug 2011	JC	R11082	2	Add File Destination
-- 16 Nov 2011	vql	R11473	3	Allow filtering on Property Type and Country
-- 02 Mar 2012	SF	R11961	4	Add Not Used By to retrict result 
-- 19 Sep 2014	MF	R39599	5	Rework of RFC11473 and none of the expected filtering was implemented.

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

	Set @sSQLString = "
	Select 	L.LETTERNO as DocumentKey,
		"+dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'L',@sLookupCulture,@pbCalledFromCentura)
				+ " as DocumentDescription,
		L.DOCUMENTCODE as DocumentCode,
		L.MACRO as Template,
		L.DOCUMENTTYPE as DocumentType,
		CONVERT(Bit, ISNULL(L.ADDATTACHMENTFLAG,0)) as AddAttachment,
		L.ACTIVITYTYPE as ActivityTypeKey,
		L.ACTIVITYCATEGORY as ActivityCategoryKey,
		DL.FILEDESTINATION as DefaultFilePath,
		DL.DESTINATIONSP as FileDestinationSP
	from LETTER L 
	left join DELIVERYMETHOD DL on (DL.DELIVERYID = L.DELIVERYID)
	left join CASES C on (C.CASEID = @pnCaseKey)
	where L.DOCUMENTTYPE = @pnDocumentType
	  and L.USEDBY & @pnUsedBy > 0
	  and(L.COUNTRYCODE =C.COUNTRYCODE  or L.COUNTRYCODE  is null or C.COUNTRYCODE  is null)
	  and(L.PROPERTYTYPE=C.PROPERTYTYPE or L.PROPERTYTYPE is null or C.PROPERTYTYPE is null)
	" + 
	
	CASE WHEN @pnNotUsedBy is not null THEN 
		" and L.USEDBY & @pnNotUsedBy = 0 
		"
	END +
	"order by 2"	

	exec @nErrorCode = sp_executesql @sSQLString, 
		N'@pnDocumentType	int,
		  @pnUsedBy		int,
		  @pnCaseKey		int,
		  @pnNotUsedBy		int',
		  @pnDocumentType	= @pnDocumentType,
		  @pnUsedBy		= @pnUsedBy,
		  @pnNotUsedBy		= @pnNotUsedBy,
		  @pnCaseKey		= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListDocuments to public
GO
