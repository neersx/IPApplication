-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchKeyword
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchKeyword]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchKeyword.'
	Drop procedure [dbo].[csw_FetchKeyword]
End
Print '**** Creating Stored Procedure dbo.csw_FetchKeyword...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_FetchKeyword
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		-- Mandatory
)
as
-- PROCEDURE:	csw_FetchKeyword
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists all modifiable columns from the OfficialNumbers table

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Apr 2012	KR	R10134	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "  
	Select  CAST(W.CASEID as nvarchar(11)) +'^'+
		CAST(W.KEYWORDNO as varchar(11))	as RowKey,
		W.CASEID			as CaseKey,
		W.KEYWORDNO			as KeyWordKey,
		"+dbo.fn_SqlTranslatedColumn('KEYWORDS','KEYWORD',null,'K',@sLookupCulture,@pbCalledFromCentura)+"	
				  		as KeyWordDescription,
		W.LOGDATETIMESTAMP		as LastModifiedDate
	from CASEWORDS W
	join KEYWORDS K	on (K.KEYWORDNO = W.KEYWORDNO)
	where W.CASEID = @pnCaseKey
	order by CaseKey, K.KEYWORD DESC"
	
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey		int',
				  @pnCaseKey		= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchKeyword to public
GO
