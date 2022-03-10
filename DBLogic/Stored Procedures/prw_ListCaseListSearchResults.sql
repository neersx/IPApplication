-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_ListCaseListSearchResults
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_ListCaseListSearchResults]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_ListCaseListSearchResults.'
	Drop procedure [dbo].[prw_ListCaseListSearchResults]
End
Print '**** Creating Stored Procedure dbo.prw_ListCaseListSearchResults...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.prw_ListCaseListSearchResults
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnPriorArtKey		int				= null,
	@pbCalledFromCentura	bit			= 0
)
as
-- PROCEDURE:	prw_ListCaseListSearchResults
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List All Case List Prior Art Search Result for a particular Prior Art Key

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 28 Feb 2011	JC		RFC6563	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin

	Set @sSQLString = "Select
	CS.PRIORARTID					as PriorArtKey,
	CS.CASELISTNO					as CaseListKey,
	"+dbo.fn_SqlTranslatedColumn('CASELIST','CASELISTNAME',null,'CL',@sLookupCulture,@pbCalledFromCentura)	
			 +" as CaseListCode,			
	"+dbo.fn_SqlTranslatedColumn('CASELIST','DESCRIPTION',null,'CL',@sLookupCulture,@pbCalledFromCentura)	
			 +" as CaseListDescription,			
	CS.LOGDATETIMESTAMP				as LastModifiedDate
	from CASELISTSEARCHRESULT CS
	join CASELIST CL			on (CL.CASELISTNO = CS.CASELISTNO)
	where CS.PRIORARTID = @pnPriorArtKey
	order by CaseListCode"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pbCalledFromCentura bit,
			@pnPriorArtKey		int',
			@pnUserIdentityId   = @pnUserIdentityId,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnPriorArtKey		= @pnPriorArtKey

End

Return @nErrorCode
GO

Grant execute on dbo.prw_ListCaseListSearchResults to public
GO