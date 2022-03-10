-----------------------------------------------------------------------------------------------------------------------------
-- Creation of apps_SavedQueryCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[apps_SavedQueryCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.apps_SavedQueryCases.'
	Drop procedure [dbo].[apps_SavedQueryCases]
End
Print '**** Creating Stored Procedure dbo.apps_SavedQueryCases...'
Print ''
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.apps_SavedQueryCases
(
	@pnUserIdentityId		int,
	@pnQueryKey				int		-- The key of a saved search to be run.
)
as
-- PROCEDURE:	apps_SavedQueryCases
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Stored procedure that performs a search on cases using existing services
--              based on ipw_ReportWriter

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 09 Feb 2015	SF		RFC33597	1	Procedure created
-- 07 Aug 2017	SF		RFC33597	2	Fix casing


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON

declare	@nErrorCode				int	
declare @nRowCount				int
declare @tOutputRequest			nvarchar(max)
declare @nQueryContextKey		int
declare @nXmlFilterCriteria		nvarchar(max)	
declare @sXmlFilterCriteria		nvarchar(max)	-- Any columns dynamically requested, expressed as XML.

create table #tblXmlQueryableCriteria
(
        Filter XML
)

-- Initialise variables
Set @nErrorCode = 0
Set @nQueryContextKey = 2
Set @tOutputRequest = '<OutputRequests><Column ProcedureName="csw_ListCase" ID="CaseKey" PublishName="CaseKey" /></OutputRequests>'

If @nErrorCode = 0
Begin 
	Select @sXmlFilterCriteria = XMLFILTERCRITERIA
	from QUERYFILTER QF
	join QUERY Q on (QF.FILTERID = Q.FILTERID and Q.QUERYID = @pnQueryKey)

	-- Strip 'Filtering' out of XML Filter Criteria
	If @nErrorCode = 0
	and CHARINDEX('/Filtering',@sXmlFilterCriteria) > 0
	Begin
			Insert into #tblXmlQueryableCriteria(Filter)
			values(@sXmlFilterCriteria)
        
			Set @nErrorCode = @@ERROR

			If @nErrorCode = 0
			Begin
					Select @nXmlFilterCriteria = convert(nvarchar(max),Filter.query('(//Filtering)[1]')) from #tblXmlQueryableCriteria
					Set @nErrorCode = @@ERROR        
			End

			If @nErrorCode = 0
			Begin
					Set @nXmlFilterCriteria = REPLACE(REPLACE(@nXmlFilterCriteria,'<Filtering>',''),'</Filtering>','')
			End
	End
	Else
	Begin
			Set @nXmlFilterCriteria = @sXmlFilterCriteria
	End
End

-- Executes the search and return results
If @nErrorCode = 0
Begin

	If (@sXmlFilterCriteria is null)
	Begin
		Select null as 'RowKey', null as 'CaseKey'
		where 1=0
	End
	Else 
	Begin
        
		exec @nErrorCode = dbo.csw_ListCase 
				@pnRowCount				= @nRowCount			OUTPUT,
				@pnUserIdentityId		= @pnUserIdentityId,
				@pnQueryContextKey		= @nQueryContextKey,
				@ptXMLOutputRequests	= @tOutputRequest,
				@ptXMLFilterCriteria	= @nXmlFilterCriteria,
				@pnCallingLevel			= 0,
				@pbPrintSQL				= 0,
				@pnPageStartRow			= null,
				@pnPageEndRow			= null,
				@pbGenerateReportCriteria 	= 0,
				@pnCaseChargeCount		= null,
				@psEmailAddress			= null,
				@pbReturnResultSet		= 1,
				@pbGetTotalCaseCount	= 1
	
	End
End

Return @nErrorCode
GO

Grant execute on dbo.apps_SavedQueryCases to public
GO
