-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ReportWriter
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ReportWriter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ReportWriter.'
	Drop procedure [dbo].[ipw_ReportWriter]
End
Print '**** Creating Stored Procedure dbo.ipw_ReportWriter...'
Print ''
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ReportWriter
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnQueryContextKey		int		= null,		-- The context of the search.  May only be null if @pnQueryKey is provided.
	@pnQueryKey			int		= null,		-- The key of a saved search to be run.
	@ptXMLSelectedColumns		nvarchar(max)	= null,		-- Any columns dynamically requested, expressed as XML.
									-- If neither @pnQueryContextKey nor @ptXMLSelectedColumns
									-- are provided, the default presentation for the context is used.
	@ptXmlFilterCriteria            nvarchar(max)   = null,
	@pnReportToolKey		int		= 9402,         -- Defaulted to Reporting Services
	@psPresentationType 		nvarchar(30)	= null,		-- The name of a secondary type of presentation. Used to distinguish multiple default presentations where necessary.
	@pbCalledFromCentura		bit		= 0,
	@pbUseDefaultPresentation 	bit		= 0,		-- When true, any presentation stored against the current search will be ignored in favour of the default presentation for the context.
	@pbIsExternalUser		bit		= null
)
as
-- PROCEDURE:	ipw_ReportWriter
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Stored procedure that performs a search on cases using existing 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 08 Mar 2010	LP	RFC8733	1	Procedure created
-- 23 Feb 2011  LP      RFC10252 2      Extend column sizes in temp tables to prevent truncation error
-- 17 Mar 2011  LP      RFC10252 3      Made some corrections on determining the XML filter criteria.
-- 19 Apr 2011  LP      RFC10502 4      Reset PrintSQL to 0.
-- 07 Aug 2012  DV      RFC12390 5      Pass DocItemKey in output xml
-- 24 Oct 2017	AK		R72645	 6		Make compatible with case sensitive server with case insensitive database.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON

declare	@nErrorCode     int	
declare @sProcedureName nvarchar(100)
declare @nRowCount      int
declare @tOutputRequest nvarchar(max)
Declare @idoc           int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument	
declare @nXmlFilterCriteria nvarchar(max)	

create table #tblOutputRequest
(
        ID                      nvarchar(max)   collate database_default not null,
        Qualifier               nvarchar(max)     collate database_default null,
        PublishName             nvarchar(max)   collate database_default null,
        SortOrder               int             null,
        SortDirection           nvarchar(max)     collate database_default null,
        GroupBySortOrder        int             null,
        GroupBySortDirection    nvarchar(max)     collate database_default null,
        IsFreezeColumnIndex     bit             null,
        DocItemKey              int             null,
        ProcedureName           nvarchar(max)   collate database_default null        
)

create table #tblXMLCriteria
(
        XmlCriteria             ntext           collate database_default null
)
create table #tblFormatting
(
        ID                      nvarchar(max)   collate database_default not null,
        Title                   nvarchar(max)   collate database_default not null,
        Format                  nvarchar(80)    collate database_default null,
        DecimalPlaces           int             null,
        CurrencySymbol          nvarchar(50)     collate database_default null       
)

create table #tblXmlQueryableCriteria
(
        Filter XML
)

-- Initialise variables
Set @nErrorCode = 0

If (DATALENGTH(@ptXMLSelectedColumns) = 0 
or DATALENGTH(@ptXMLSelectedColumns) is null)
Begin
        Set @ptXMLSelectedColumns = ''
End

-- Get Output Request
If @nErrorCode = 0
Begin
        insert into #tblOutputRequest
        exec @nErrorCode = dbo.ip_ListSearchRequirements @psProcedureName        = @sProcedureName OUTPUT,
                                                        @pnUserIdentityId	= @pnUserIdentityId,	
						        @psCulture		= @psCulture,	
						        @pnQueryContextKey      = @pnQueryContextKey,
						        @pnQueryKey             = @pnQueryKey,
						        @ptXMLSelectedColumns   = @ptXMLSelectedColumns,
						        @pnReportToolKey        = @pnReportToolKey,
						        @psPresentationType     = @psPresentationType,
					    	        @pbCalledFromCentura    = @pbCalledFromCentura,
					    	        @pbUseDefaultPresentation = @pbUseDefaultPresentation,
						        @pbIsExternalUser	= @pbIsExternalUser,
					    	        @psResultRequired       = 'OUTPUTREQUEST'    
					    	        
					    	               
End

-- Get Formatting
If @nErrorCode = 0
Begin
        insert into #tblFormatting
        exec @nErrorCode = dbo.ip_ListSearchRequirements @psProcedureName       = @sProcedureName OUTPUT,
                                                        @pnUserIdentityId	= @pnUserIdentityId,	
						        @psCulture		= @psCulture,	
						        @pnQueryContextKey      = @pnQueryContextKey,
						        @pnQueryKey             = @pnQueryKey,
						        @ptXMLSelectedColumns   = @ptXMLSelectedColumns,
						        @pnReportToolKey        = @pnReportToolKey,
						        @psPresentationType     = @psPresentationType,
					    	        @pbCalledFromCentura    = @pbCalledFromCentura,
					    	        @pbUseDefaultPresentation = @pbUseDefaultPresentation,
						        @pbIsExternalUser	= @pbIsExternalUser,
					    	        @psResultRequired       = 'FORMATTING' 
End

-- Get XMLFilterCriteria
If @nErrorCode = 0
and @pnQueryKey is not null
and (DATALENGTH(@ptXmlFilterCriteria) = 0 
or DATALENGTH(@ptXmlFilterCriteria) is null)
Begin
        insert into #tblXMLCriteria
        exec @nErrorCode = dbo.ip_ListSearchRequirements @psProcedureName        = @sProcedureName OUTPUT,
                                                        @pnUserIdentityId	= @pnUserIdentityId,	
						        @psCulture		= @psCulture,	
						        @pnQueryContextKey      = @pnQueryContextKey,
						        @pnQueryKey             = @pnQueryKey,
						        @ptXMLSelectedColumns   = @ptXMLSelectedColumns,
						        @pnReportToolKey        = @pnReportToolKey,
						        @psPresentationType     = @psPresentationType,
					    	        @pbCalledFromCentura    = @pbCalledFromCentura,
					    	        @pbUseDefaultPresentation = @pbUseDefaultPresentation,
						        @pbIsExternalUser	= @pbIsExternalUser,
					    	        @psResultRequired       = 'FILTERCRITERIA'           
End

If (DATALENGTH(@ptXmlFilterCriteria) = 0 
or DATALENGTH(@ptXmlFilterCriteria) is null)
Begin
        Select @ptXmlFilterCriteria = XmlCriteria from #tblXMLCriteria
End

-- Construct the XML Filter Criteria
If @nErrorCode = 0
and CHARINDEX('/Filtering',@ptXmlFilterCriteria) > 0
Begin
        Insert into #tblXmlQueryableCriteria(Filter)
        values(@ptXmlFilterCriteria)
        
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
        Set @nXmlFilterCriteria = @ptXmlFilterCriteria
End



If @nErrorCode = 0
Begin
        Set @tOutputRequest = convert(nvarchar(max),(Select 
                                                         tOR.ID as '@ID',
                                                         Qualifier as '@Qualifier',
                                                         SortOrder as '@SortOrder',
                                                         SortDirection as '@SortDirection',
                                                         ISNULL(tF.ID,tOR.PublishName) as '@PublishName',
                                                         tOR.ProcedureName as '@ProcedureName',
                                                         tOR.DocItemKey as '@DocItemKey'
                                                         from #tblOutputRequest tOR
                                                         left join #tblFormatting tF on (tOR.PublishName = tF.ID)
                                                         for XML PATH('Column'))) 
End

Set @tOutputRequest = '<OutputRequests>' + @tOutputRequest + '</OutputRequests>'

-- Finally execute search and return results
If @nErrorCode = 0
Begin
        If @pnQueryContextKey = 2 
        or @pnQueryContextKey = 330
        Begin
                exec @nErrorCode = dbo.csw_ListCase 
	        @pnRowCount			= @nRowCount			OUTPUT,
	        @pnUserIdentityId		= @pnUserIdentityId,
	        @psCulture			= @psCulture,
	        @pnQueryContextKey		= @pnQueryContextKey,
	        @ptXMLOutputRequests		= @tOutputRequest,
	        @ptXMLFilterCriteria		= @nXmlFilterCriteria,
	        @pbCalledFromCentura		= @pbCalledFromCentura,
	        @pnCallingLevel			= 0,
	        @pbPrintSQL			= 1,
	        @pnPageStartRow			= null,
	        @pnPageEndRow			= null,
	        @pbGenerateReportCriteria 	= 0,
	        @pnCaseChargeCount		= null,
	        @psEmailAddress			= null,
	        @pbReturnResultSet		= 1,
	        @pbGetTotalCaseCount		= 1
	End
	Else If @pnQueryContextKey = 10
	Begin
	        
	        exec @nErrorCode = dbo.naw_ListName 
	        @pnRowCount			= @nRowCount			OUTPUT,
	        @pnUserIdentityId		= @pnUserIdentityId,
	        @psCulture			= @psCulture,
	        @pnQueryContextKey		= @pnQueryContextKey,
	        @ptXMLOutputRequests		= @tOutputRequest,
	        @ptXMLFilterCriteria		= @nXmlFilterCriteria,
	        @pbCalledFromCentura		= @pbCalledFromCentura,
	        @pnPageStartRow			= null,
	        @pnPageEndRow			= null,
	        @pnCallingLevel			= 0,
	        @pbPrintSQL			= 0,
	        @pbReturnResultSet		= 1,
	        @pbGetTotalNameCount		= 0
	End
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_ReportWriter to public
GO
