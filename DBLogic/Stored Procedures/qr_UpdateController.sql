-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_UpdateController
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_UpdateController]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_UpdateController.'
	Drop procedure [dbo].[qr_UpdateController]
End
Print '**** Creating Stored Procedure dbo.qr_UpdateController...'
Print ''
GO

SET QUOTED_IDENTIfIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.qr_UpdateController
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnQueryId		int,		-- Mandatory
	@pnContextKey		int,		-- Mandatory
	@psQueryName		nvarchar(50)	= null,
	@psQueryDescription	nvarchar(254)	= null,
	@pbIsPublic		bit		= null,
	@ptXMLFilterCriteria	ntext		= null,
	@ptXMLPresentation	ntext		= null,
	@pnReportToolKey 	int		= null,
	@pbIsReadOnly		bit		= 0
)
as
-- PROCEDURE:	qr_UpdateController
-- VERSION:	3
-- SCOPE:	Inprotech
-- DESCRIPTION:	Controls update of the query

-- MODIfICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	--------	-------	----------------------------------------------- 
-- 20 Jan 2004	MB	SQA8809		1	Procedure created
-- 01 Jul 2004	IB	SQA10125	2	Implemented @pbIsReadOnly parameter, defaulted it to 0.
-- 27 Aug 2004	MB	SQA9658		3	Added TITLE column in the QUERYCONTENT table

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	 int
Declare @idoc 		 int 	
Declare @nColumnIndex 	 int 	
Declare @nColumnCount 	 int 	
Declare @sSql 		 nvarchar(4000)
Declare @nFilterId 	 int
Declare @nGroupId 	 int
Declare @nPresenationId  int
Declare @sReportTitle 	 nvarchar (80)
Declare @sReportTemplate nvarchar (254)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0 
Begin
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLPresentation

	-- select @nPresenationId and @nFilterId
	Set @sSql = '
		select @nFilterId = FILTERID, @nPresenationId = PRESENTATIONID 
		from QUERY A 
		where QUERYID = @pnQueryId'


	exec @nErrorCode=sp_executesql @sSql,
			N'@nFilterId		int	output,
			  @nPresenationId	int	output,
			  @pnQueryId		int',
			  @nFilterId		= @nFilterId output,
			  @nPresenationId	= @nPresenationId output,
			  @pnQueryId		= @pnQueryId

	If @nPresenationId is not null  
	and @nErrorCode = 0
	Begin
		Set @sSql = '
			Delete 
			from  QUERYCONTENT 
			where PRESENTATIONID = @nPresenationId'

		exec @nErrorCode=sp_executesql @sSql, 
				N'@nPresenationId int', 
				  @nPresenationId = @nPresenationId

	End
	Else If @nErrorCode = 0
	Begin
		exec @nErrorCode = qr_MaintainPresentation
			@pnPresentationKey 		= @nPresenationId		 output,	-- Required for update
			@pnUserIdentityId 		= @pnUserIdentityId,				-- Mandatory
			@psCulture 			= @psCulture,
			@pnContextKey 			= @pnContextKey,					-- Mandatory
			@pnAdoptFromQueryKey		= null,	-- Indicates that the presentation on the identIfied query should be used
			@pbUsesDefaultPresentation 	= 0, -- Must be 0 to insert new presenatation
			@pbIsPublic 			= @pbIsPublic,
			@pbIsContextDefault 		= 0,
			@pbOldUsesDefaultPresentation 	= null, -- Must be 0 to insert new presenatation
			@pbOldIsPublic 			= 0,
			@pbOldIsContextDefault		= 0,
			@pnReportToolKey 		= @pnReportToolKey  		

		If @nErrorCode = 0
		Begin
			Set @sSql = '
				Update QUERY 
				set PRESENTATIONID = @nPresenationId 
				where QUERYID = @pnQueryId'

			exec @nErrorCode=sp_executesql @sSql, 
					N'@nPresenationId 	int,
					  @pnQueryId 		int', 
					  @nPresenationId 	= @nPresenationId,
					  @pnQueryId 		= @pnQueryId
		End
	End	
	If @nErrorCode = 0
	Begin
		set @sSql = "Select"  +
			char (10) + " @sReportTitle = ReportTitle, " +
			char (10) + " @sReportTemplate = ReportTemplate, " + 
			char (10) + " @nGroupId = QueryGroup " +
			"		from	OPENXML(@idoc, '/OutputRequests',1)
			WITH (
			ReportTitle	nvarchar(80) 	'ReportTitle/text()',
			ReportTemplate  nvarchar(254) 	'ReportTemplate/text()',
			QueryGroup 	int 		'QueryGroup/text()'  )	" 
	
		exec @nErrorCode = sp_executesql @sSql,
				N'@idoc		   int,
				  @sReportTitle    nvarchar(80)	 output,
				  @sReportTemplate nvarchar(254) output,
				  @nGroupId 	   int				output',
				  @idoc		   = @idoc,
				  @sReportTitle    = @sReportTitle	output,
				  @sReportTemplate = @sReportTemplate 	output,
				  @nGroupId 	   = @nGroupId 		output

		If @nErrorCode = 0
		Begin
			Set @sSql = '
			Update QUERYPRESENTATION 
			set  
				REPORTTITLE 	= @sReportTitle,
				REPORTTEMPLATE 	= @sReportTemplate,
				IDENTITYID	= CASE WHEN @pbIsPublic = 1 THEN Null
							  ELSE @pnUserIdentityId
						  END,
				REPORTTOOL 	= @pnReportToolKey 
			where 	PRESENTATIONID  = @nPresenationId'

			exec @nErrorCode = sp_executesql @sSql,
				N'@sReportTitle		nvarchar(80),
				  @sReportTemplate 	nvarchar(254),
				  @pbIsPublic		bit,
				  @pnUserIdentityId 	int,
				  @pnReportToolKey	int,
				  @nPresenationId 	int',
				  @sReportTitle		= @sReportTitle,
				  @sReportTemplate  	= @sReportTemplate,
				  @pbIsPublic		= @pbIsPublic,
				  @pnUserIdentityId 	= @pnUserIdentityId,
				  @pnReportToolKey	= @pnReportToolKey,
				  @nPresenationId 	= @nPresenationId
		End

		If @nErrorCode = 0
		Begin
			Set @sSql = "
			Insert into QUERYCONTENT ( 
				PRESENTATIONID, 	COLUMNID, 
				DISPLAYSEQUENCE,	SORTORDER, 
				SORTDIRECTION,		CONTEXTID,
				TITLE  )
			Select  @nPresenationId,	ColumnId, 
				DisplaySequence, 	SortOrder, 
				SortDirection, 		@pnContextKey,
				ColumnTitle 
				from	OPENXML(@idoc, '/OutputRequests/Column',1)
				WITH (
				ColumnId		int 		'@ColumnId/text()',
				DisplaySequence 	int 		'@DisplaySequence/text()',
				SortOrder		tinyint		'@SortOrder/text()',
				SortDirection		nvarchar(1)	'@SortDirection/text()' ,
				ColumnHiddenFlag 	int 		'@ColumnHiddenFlag/text()',
				ColumnTitle		nvarchar(254)	'@ColumnTitle/text()'   )	
			where ColumnHiddenFlag is null"

			exec @nErrorCode = sp_executesql @sSql,
				N'@nPresenationId int,
				  @pnContextKey int,
				  @idoc 	  int',
				  @nPresenationId = @nPresenationId,
				  @pnContextKey   = @pnContextKey,
				  @idoc 	  = @idoc
		End

	
		-- deallocate the xml document handle when finished.
		exec sp_xml_removedocument @idoc
	End
		--- Maintain Filter
	If datalength(@ptXMLFilterCriteria) > 0 and @nErrorCode = 0
	Begin
		If @nFilterId is null 
		Begin
			exec @nErrorCode = qr_MaintainFilter
			@pnFilterKey 		= @nFilterId	  output,	-- Required for update
			@pnUserIdentityId 	= @pnUserIdentityId,
			@psCulture 		= @psCulture,
			@pnContextKey 		= @pnContextKey,	-- Mandatory
			@pnAdoptFromQueryKey	= null,			-- Indicates that the filter on the identIfied query should be used
			@ptXMLFilterCriteria	= @ptXMLFilterCriteria ,
			@ptOldXMLFilterCriteria = null

			If @nErrorCode =0
			Begin		 
				Set @sSql ='
				Update QUERY 
				set FILTERID = @nFilterId 
				where QUERYID = @pnQueryId'

 				exec @nErrorCode=sp_executesql @sSql, 
						N'@nFilterId int,
						  @pnQueryId int', 
						  @nFilterId = @nFilterId,
						  @pnQueryId = @pnQueryId
			End
		End
		Else
		Begin
			Set @sSql ='
			Update QUERYFILTER 
			set XMLFILTERCRITERIA = @ptXMLFilterCriteria
			where FILTERID = @nFilterId'

 			exec @nErrorCode=sp_executesql @sSql, 
					N'@ptXMLFilterCriteria  ntext,
					  @nFilterId 		int', 
					  @ptXMLFilterCriteria  = @ptXMLFilterCriteria,
					  @nFilterId 		= @nFilterId
		End
	End
	Else
	Begin
		If @nFilterId is not null and @nErrorCode = 0
		Begin
			Set @sSql ='
			Update QUERY 
			set FILTERID = null 
			where QUERYID = @pnQueryId'
 			exec @nErrorCode=sp_executesql @sSql, 
					N'@pnQueryId int', 
					@pnQueryId = @pnQueryId

			If @nErrorCode =0
			Begin
				exec @nErrorCode = qr_DeleteFilter 
						@pnUserIdentityId 	= @pnUserIdentityId,	
						@psCulture		= @psCulture,
						@pnFilterKey 		= @nFilterId
			End
		End	
	End

-- Simple Query Update
	If @nErrorCode = 0 
	Begin
		Set @sSql ='
		Update 	QUERY 
		set 	
			QUERYNAME 	= @psQueryName, 
			DESCRIPTION 	= @psQueryDescription,
			GROUPID 	= @nGroupId,
			IDENTITYID 	= CASE WHEN @pbIsPublic = 1 THEN Null
					  ELSE @pnUserIdentityId
				     	  END,
			ISREADONLY 	= @pbIsReadOnly
		where 
			QUERYID 	= @pnQueryId'

		exec @nErrorCode=sp_executesql @sSql, 
				N'@psQueryName 		nvarchar(50),
				  @psQueryDescription 	nvarchar(254),
				  @nGroupId 		int,
				  @pbIsPublic 		bit,
				  @pnUserIdentityId 	int,
				  @pnQueryId 		int,
				  @pbIsReadOnly	bit', 
				  @psQueryName 		= @psQueryName,
				  @psQueryDescription 	= @psQueryDescription,
				  @nGroupId 		= @nGroupId,
				  @pbIsPublic 		= @pbIsPublic,
				  @pnUserIdentityId 	= @pnUserIdentityId,
				  @pnQueryId 		= @pnQueryId,
				  @pbIsReadOnly	= @pbIsReadOnly							
	End
End


Return @nErrorCode
GO

Grant execute on qr_UpdateController to public
GO
