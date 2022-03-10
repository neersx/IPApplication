-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_GetSearchResultChildCount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_GetSearchResultChildCount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_GetSearchResultChildCount.'
	Drop procedure [dbo].[prw_GetSearchResultChildCount]
End
Print '**** Creating Stored Procedure dbo.prw_GetSearchResultChildCount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.prw_GetSearchResultChildCount
(
	@pnUserIdentityId	int,	-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int		= null
)
as
-- PROCEDURE:	prw_GetSearchResultChildCount
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Counts all records for child tables of SearchResults

-- MODIFICATIONS :
-- Date			Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 01 Mar 2011	JC	RFC6563	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @bIsSourceDocument bit

-- Initialise variables
Set @nErrorCode = 0
Set @bIsSourceDocument = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	@bIsSourceDocument = isnull(ISSOURCEDOCUMENT,0)
		from	SEARCHRESULTS
		where	PRIORARTID = @pnPriorArtKey"

	exec @nErrorCode=sp_executesql @sSQLString,
	      	N'
		@bIsSourceDocument	bit output,  		
		@pnPriorArtKey		int',
		@bIsSourceDocument	= @bIsSourceDocument OUTPUT,
		@pnPriorArtKey		= @pnPriorArtKey

End

If @nErrorCode = 0
Begin

	Set @sSQLString = "	
	Select 'ActivityAttachment' as TableName, count(PRIORARTID) as Count
	from ACTIVITY where PRIORARTID = @pnPriorArtKey
	union
	Select 'FamilySearchResult' as TableName, count(PRIORARTID) as Count
	from FAMILYSEARCHRESULT where PRIORARTID = @pnPriorArtKey
	union
	Select 'CaseListSearchResult' as TableName, count(PRIORARTID) as Count
	from CASELISTSEARCHRESULT where PRIORARTID = @pnPriorArtKey
	union
	Select 'NameSearchResult' as TableName, count(PRIORARTID) as Count
	from NAMESEARCHRESULT where PRIORARTID = @pnPriorArtKey
	union
	Select 'CaseSearchResult' as TableName, count(distinct CASEID) as Count
	from CASESEARCHRESULT where PRIORARTID = @pnPriorArtKey
	union"
	
	if @bIsSourceDocument = 0
	Begin
		Set @sSQLString = @sSQLString + "
		Select 'ReportCitation' as TableName, count(CITEDPRIORARTID) as Count
		from REPORTCITATIONS where CITEDPRIORARTID = @pnPriorArtKey"
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + "
		Select 'ReportCitation' as TableName, count(SEARCHREPORTID) as Count
		from REPORTCITATIONS where SEARCHREPORTID = @pnPriorArtKey"
	End
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pnPriorArtKey		int',
			@pnUserIdentityId	= @pnUserIdentityId,
			@pnPriorArtKey		= @pnPriorArtKey

End

Return @nErrorCode
GO

Grant execute on dbo.prw_GetSearchResultChildCount to public
GO
