-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListKeywordSynonyms
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListKeywordSynonyms]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListKeywordSynonyms.'
	Drop procedure [dbo].[ipw_ListKeywordSynonyms]
End
Print '**** Creating Stored Procedure dbo.ipw_ListKeywordSynonyms...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListKeywordSynonyms
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnKeywordKey		int			-- Mandatory
)
as
-- PROCEDURE:	ipw_ListKeywordSynonyms
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List Synonyms linked to a particular Keyword

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 MAR 2012	KR	R8562	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  S.KEYWORDNO as KeywordKey,
		S.KWSYNONYM as KeywordSynonymKey,
		K.KEYWORD    as	KeywordSynonym,
		K1.KEYWORD   as Keyword,
		S.LOGDATETIMESTAMP as LastModifiedDate
	from SYNONYMS S
	Join KEYWORDS K on (K.KEYWORDNO = S.KWSYNONYM)
	Join KEYWORDS K1 on (K1.KEYWORDNO = S.KEYWORDNO)
	Where S.KEYWORDNO = @pnKeywordKey
	order by 1"


	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnKeywordKey		int',
			@pnKeywordKey		= @pnKeywordKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListKeywordSynonyms to public
GO
