-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_CompareTemplateColumns
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_CompareTemplateColumns]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_CompareTemplateColumns.'
	Drop procedure [dbo].[qr_CompareTemplateColumns]
End
Print '**** Creating Stored Procedure dbo.qr_CompareTemplateColumns...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.qr_CompareTemplateColumns
(
	@pnComparisonQueryKey	int	output,			-- The key of another query that uses the supplied report template.
	@pbAreColumnsConsistent	bit	output,			-- True if the comparison query passes the same columns to the report template.
	@pnUserIdentityId	int,				-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnQueryContextKey	int,				-- The context of the search.
	@pnReportToolKey	int,				-- The report tool that uses the template.
	@psReportTemplateName	nvarchar(254),			-- The name of the report template to be checked.
	@ptXMLSelectedColumns	ntext,				-- The columns requested, expressed as XML.
	@pnModifiedQueryKey	int		= null		-- The key of the saved query being modified (so that it can be excluded).
)
as
-- PROCEDURE:	qr_CompareTemplateColumns
-- VERSION:	3
-- DESCRIPTION:	Locates a comparison query that uses the report template supplied.
--		It then checks whether the columns passed to the template by the 
--		comparison query are the same as the selected columns provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13 May 2004	JEK	RFC909	1	Procedure created
-- 14 May 2004	JEK	RFC909	2	Choose a public query, or one of the user's own
--					queries for preference.
-- 13 Jul 2011	DL	RFC10830 3	Specify collation default in temp table.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode			int
declare @nSelectedColumnsCount		int
declare @nComparisonColumnsCount	int
declare @sSQLString 			nvarchar(4000)
declare @tblSelectedColumns 		TABLE
(
	 ColumnKey			int		null,
	 DisplaySequence		smallint	null,
    	 SortOrder			tinyint		null,
	 SortDirection			nvarchar(1)	collate database_default null 
)

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
declare @idoc 			int 

-- Initialise variables
Set @nErrorCode = 0
Set @nSelectedColumnsCount = null
Set @nComparisonColumnsCount = null
Set @pbAreColumnsConsistent = 0

-- Locate another query with that uses this report template
If @nErrorCode = 0
Begin
	-- For preference, choose a public query, or one of the user's own
	-- queries.
	-- Note this procedure may be called when editing an existing saved
	-- query, so that query must be excluded from the test.
	Set @sSQLString = " 
	Select 	@pnComparisonQueryKey =   
		SUBSTRING(
		MIN(	CASE WHEN Q.IDENTITYID IS NULL THEN '0' ELSE '1' END +
			CASE WHEN Q.IDENTITYID = @pnUserIdentityId THEN '0' ELSE '1' END +
			CAST (Q.QUERYID AS NVARCHAR)),
		3,8)
	from	QUERY Q
	join	QUERYPRESENTATION P on (P.PRESENTATIONID = Q.PRESENTATIONID)
	WHERE	Q.CONTEXTID = @pnQueryContextKey
	AND	P.REPORTTOOL = @pnReportToolKey
	AND	P.REPORTTEMPLATE = @psReportTemplateName
	AND	((@pnModifiedQueryKey is null) or (Q.QUERYID <> @pnModifiedQueryKey))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnComparisonQueryKey	int	output,
					  @pnQueryContextKey	int,
					  @pnReportToolKey	int,
					  @psReportTemplateName nvarchar(254),
					  @pnModifiedQueryKey	int,
					  @pnUserIdentityId	int',
					  @pnComparisonQueryKey	= @pnComparisonQueryKey	output,
					  @pnQueryContextKey	= @pnQueryContextKey,
					  @pnReportToolKey	= @pnReportToolKey,
					  @psReportTemplateName = @psReportTemplateName,
					  @pnModifiedQueryKey	= @pnModifiedQueryKey,
					  @pnUserIdentityId	= @pnUserIdentityId

End

-- Populate a table variable with the selected columns
If @nErrorCode = 0
and @pnComparisonQueryKey is not null
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLSelectedColumns

	Insert into @tblSelectedColumns (ColumnKey, DisplaySequence, SortOrder, SortDirection)
	Select  *   
	from	OPENXML(@idoc, '/SelectedColumns/Column',2)
		WITH (
		      ColumnKey		int		'ColumnKey/text()',
		      DisplaySequence	smallint	'DisplaySequence/text()',
		      SortOrder		tinyint		'SortOrder/text()',
		      SortDirection	nvarchar(1)	'SortDirection/text()'
		     )	

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc

End

-- Check the number of columns used by each
If @nErrorCode = 0
and @pnComparisonQueryKey is not null
Begin
	-- Only columns selected for display are passed to the report template
	Set @sSQLString = " 
	Select 	@nComparisonColumnsCount = count(*)
	from	QUERY Q
	join	QUERYCONTENT C		on (C.PRESENTATIONID = Q.PRESENTATIONID)
	WHERE	Q.QUERYID = @pnComparisonQueryKey
	and	C.DISPLAYSEQUENCE IS NOT NULL"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nComparisonColumnsCount	int	output,
					  @pnComparisonQueryKey	int',
					  @nComparisonColumnsCount = @nComparisonColumnsCount output,
					  @pnComparisonQueryKey	= @pnComparisonQueryKey

	If @nErrorCode = 0
	Begin
		Select @nSelectedColumnsCount = count(*) 
		from @tblSelectedColumns 
		where DisplaySequence is not null

		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
Begin
	If @pnComparisonQueryKey is null
	Begin
		Set @pbAreColumnsConsistent = 1
	End
	Else If @nComparisonColumnsCount = @nSelectedColumnsCount
	and @nComparisonColumnsCount <> 0
	Begin
	
		Set @pbAreColumnsConsistent = 1
	
		Select	@pbAreColumnsConsistent = 0
		from @tblSelectedColumns SC
		where SC.DisplaySequence is not null
		and not exists
			(select 1
			from	QUERY Q
			join	QUERYCONTENT C	on (C.PRESENTATIONID = Q.PRESENTATIONID)
			WHERE	Q.QUERYID = @pnComparisonQueryKey
			and	C.DISPLAYSEQUENCE IS NOT NULL
			and	C.COLUMNID = SC.ColumnKey)
	
		Set @nErrorCode = @@ERROR
	
	End
End


Return @nErrorCode
GO

Grant execute on dbo.qr_CompareTemplateColumns to public
GO
