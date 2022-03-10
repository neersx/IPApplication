-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListSearchRequirements 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListSearchRequirements]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListSearchRequirements.'
	Drop procedure [dbo].[ip_ListSearchRequirements]
End
Print '**** Creating Stored Procedure dbo.ip_ListSearchRequirements...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ip_ListSearchRequirements
(
	@psProcedureName		nvarchar(50)	output,		-- The name of the procedure to run the search.
	@pnUserIdentityId		int,				-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnQueryContextKey		int		= null,		-- The context of the search.  May only be null if @pnQueryKey is provided.
	@pnQueryKey			int		= null,		-- The key of a saved search to be run.
	@ptXMLSelectedColumns		ntext		= null,		-- Any columns dynamically requested, expressed as XML.
									-- If neither @pnQueryContextKey nor @ptXMLSelectedColumns
									-- are provided, the default presentation for the context is used.
	@pnReportToolKey		int		= null,
	@psPresentationType 		nvarchar(30)	= null,		-- The name of a secondary type of presentation. Used to distinguish multiple default presentations where necessary.
	@pbCalledFromCentura		bit		= 0,
	@pbUseDefaultPresentation 	bit		= 0,		-- When true, any presentation stored against the current search will be ignored in favour of the default presentation for the context.
	@pbIsExternalUser		bit		= null,
	@psResultRequired               nvarchar(50)    = null
)
as
-- PROCEDURE:	ip_ListSearchRequirements
-- VERSION:	40
-- DESCRIPTION:	Returns the columns that need to be selected (requested and implied),
--		and information about how the result set needs to be presented.
--		For a saved query, also returns the filter criteria.
--		Populates the SearchRequirementsData dataset.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Nov 2003	JEK	RFC643	1	Procedure created
-- 06 Dec 2003	JEK	RFC406	2	Topic level security
-- 15 Dec 2003	JEK	RFC643	3	Check error code.
-- 15 Dec 2003	JEK	RFC643	4	FilterCriteria not being returned.
-- 18 Dec 2003	JEK	RFC643	5	Implied data should not be returned for sort only columns.
-- 20 Jan 2004	TM	RFC852	6	Eliminate duplicates in the OutputRequests result set by changing the final
--					Union All for the OutputRequests result set to a Union.
-- 19 Feb 2004	TM	RFC976	7	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 25 Feb 2004	TM	RFC955	8	Suppress the Link and Argument result sets if the QUERYIMPLIEDDATA.TYPE = 'Reference'.
-- 05 Mar 2004	JEK	RFC831	9	Improve logic to ensure that the Output Requests result set only request
--					a unique piece of data once.  Changed naming convention for PublishName to use qualifier
--					where possible, and only add ColumnKey when necessary.  Introduced new tblOutputRequests.
-- 09 Mar 2004	TM	RFC1056	10	Add a new DocItemKey int column to the existing #tblSelectedColumns. Adjust all the logic 
--					that inserts rows into this table to obtain the information from the database (saved query, 
--					selected columns passed as XML, default presentation).
-- 16 Mar 2004	JEK	RFC831	11	When a currency column uses a qualifier, the presentation result set maps to the wrong column.
-- 18 Apr 2004 	JEK	RFC919	12	Ensure the PublishName is consistent.  When run as a report, suppress the Link and 
--					Argument result sets and return ImageData rather than ImageKey.
-- 19 Apr 2004	TM	RFC919	13	Implement fn_GetCorrelationSuffix in the generation of the PublishName. 
-- 30 Apr 2004	TM	RFC919	14	Implement new Search datatable. 
-- 06 Jul 2004	JEK	RFC1230	15	Usage not implemented for implied data.
-- 08 Jul 2004	TM	RFC1230	16	Return the new ProcedureName in the Output requests. Add new optional 
--					@psPresentationType parameter.   
-- 14 Jul 2004	TM	RFC1230	17	Correct the logic returning the null presentation type.
-- 14 Jul 2004	JEK	RFC1230 18	Make sure column matching includes procedure name and implied item usage.
--					Ensure that there are no duplicate implied columns because of Usage.
-- 18 Aug 2004	AB	8035	19	Add collate database_default syntax to temp tables.
-- 15 Sep 2004	TM	RFC886	20	Implement translation.
-- 23 Sep 2004	JEK	RFC886	21	Do not tranlsate data format
-- 27 Oct 2004	JEK	RFC626	22	Implement ContextLink and ContextArgument result sets.
-- 07 Jul 2005	JEK	RFC2320	23	Implement subset and subject security when deciding what columns to return.
-- 20 Jul 2005	JEK	RFC2913 24	Check whether subject security exists before implementing security.
-- 23 Aug 2005	TM	RFC2593	25	Pass a new parameter @pbUseDefaultPresentation with a default value of 0. When   
--					true, any presentation stored against the current search will be ignored in 
--					favour of the default presentation for the context.
-- 25 Nov 2005	LP	RFC1017	26	For local currency formatting, retrieve the number of decimal places from the 
--					CURRENCY table, based on the CURRENCY Site Control
-- 03 Mar 2006	TM	RFC3446	27	Replace #tblSelectedColumns with local temporary table and implement sp_executresql. 
-- 17 Mar 2006	IB	RFC3325	28	Suppress alias columns with an Alias Type qualifier (Qualifier Type = 8)
--					that the current user does not have access to.  Applies to external users only.
-- 12 Jul 2006	SW	RFC3828	29	Pass getdate() to fn_Permission..
-- 26 Jul 2006	SW	RFC4218	30	Bug fix on param passed to fn_Permission..
-- 12 Dec 2006	JEK	RFC2984	31	Implement subset security for qualifier type Instruction Type.
-- 04 Dec 2006  PG         RFC3646 	32      Pass @pbIsExternalUser to fn_filterUserXxx.
-- 25 Jan 2007	SW	RFC4982	33	Allow comma separated value in QUALIFIER for QUALIFIERTYPE = 2
-- 11 Dec 2008	MF	17136	34	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 12 May 2009  LP      RFC7832 35      Match on PresentationType specified even if a default presentation exists for the user.
-- 04 Feb 2010	SF	RFC8483	36	Implement GroupBySortOrder, GroupBySortDirection, IsFreezeColumnIndex
-- 19 Feb 2010	SF	RFC8483	37	Saved query may be run with @ptXMLSelectedColumns
-- 09 Mar 2010  LP      RFC8388 38      Allow procedure to return specific result sets.
-- 22 Mar 2010	JCLG	RFC8851	39	Add test for @ptXMLSelectedColumns is null 
-- 22 Oct 2013	DV	RFC27712	40	Add additional check for Column label when checking for duplicate implied data column

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @nSelectedColumnsCount	int
declare @nTopicKey		int
declare @sSQLString 		nvarchar(4000)
create table #tblSelectedColumns 	
(
	 RowKey			int 			identity(1,1),
	 ColumnKey		int			null,
	 DisplaySequence	smallint		null,
	 SortOrder		tinyint			null,
	 SortDirection		nvarchar(1)		collate database_default null,
	 GroupBySortOrder		tinyint			null,
	 GroupBySortDirection		nvarchar(1)		collate database_default null,
	 IsFreezeColumnIndex	bit null,
	 ProcedureItemID	nvarchar(50)		collate database_default null, -- as passed to the search stored procedure
	 Qualifier		nvarchar(20)		collate database_default null,
	 PublishName		nvarchar(50)		collate database_default null,
	 ColumnLabel		nvarchar(50)		collate database_default null,
	 Format			nvarchar(80)		collate database_default null,
	 DecimalPlaces		tinyint			null,
	 FormatItemID		nvarchar(50)		collate database_default null,
	 DataItemKey		int,			
	 DocItemKey 		int			null,
	 ProcedureName		nvarchar(50)		collate database_default null 
)

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
declare @idoc 			int 
declare @sLookupCulture		nvarchar(10)

declare @bIsExists		bit
Declare @dtToday		datetime

-- Initialise variables
Set @nErrorCode = 0
Set @nSelectedColumnsCount = 0

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @dtToday = getdate()

If @nErrorCode = 0 and @pbIsExternalUser is null
Begin
	Set @sSQLString = "
	Select	@pbIsExternalUser = ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pbIsExternalUser		bit	OUTPUT,
				  @pnUserIdentityId		int',
				  @pbIsExternalUser=@pbIsExternalUser	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId

	If @pbIsExternalUser is null
		Set @pbIsExternalUser = 1
End

-- Extract the @pnQueryContextKey from the saved query if it has not been provided.
If @nErrorCode = 0
and @pnQueryContextKey is null
and @pnQueryKey is not null
Begin
	Set @sSQLString = "
	select @pnQueryContextKey = CONTEXTID
	from QUERY
	where QUERYID = @pnQueryKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnQueryContextKey	int output,
					  @pnQueryKey		int',
					  @pnQueryContextKey	= @pnQueryContextKey output,
					  @pnQueryKey		= @pnQueryKey
End

-- Extract the requested columns from the saved query.  Note there may be no presentation.
If @nErrorCode = 0
and @pnQueryKey is not null
and @pbUseDefaultPresentation <> 1
and (datalength(@ptXMLSelectedColumns) = 0
or datalength(@ptXMLSelectedColumns) is null)
Begin	
        -- extract presentation from saved query.
	Set @sSQLString = "
	insert into #tblSelectedColumns (ColumnKey, DisplaySequence, SortOrder, SortDirection, 
				GroupBySortOrder, GroupBySortDirection, IsFreezeColumnIndex, ProcedureItemID, Qualifier, 
			PublishName, ColumnLabel, Format, DecimalPlaces, FormatItemID, DataItemKey, DocItemKey, ProcedureName)
	select 	T.COLUMNID,
		T.DISPLAYSEQUENCE,
		T.SORTORDER,
		T.SORTDIRECTION,
		T.GROUPBYSEQUENCE,
		T.GROUPBYSORTDIR,
		case when T.COLUMNID = P.FREEZECOLUMNID then cast(1 as bit) end,
		DI.PROCEDUREITEMID,
		C.QUALIFIER,
		CC.USAGE,
		"+dbo.fn_SqlTranslatedColumn('QUERYCOLUMN','COLUMNLABEL',null,'C',@sLookupCulture,@pbCalledFromCentura)+",
		TC.DESCRIPTION,
		DI.DECIMALPLACES,
		DI.FORMATITEMID,
		DI.DATAITEMID,
		C.DOCITEMID,
		DI.PROCEDURENAME
	from QUERY Q
	join QUERYPRESENTATION P	on (P.PRESENTATIONID = Q.PRESENTATIONID)
	join QUERYCONTENT T		on (T.PRESENTATIONID = P.PRESENTATIONID)
	join QUERYCOLUMN C		on (C.COLUMNID = T.COLUMNID)
	join QUERYDATAITEM DI		on (DI.DATAITEMID = C.DATAITEMID)
	join QUERYCONTEXTCOLUMN CC 	on (CC.COLUMNID = C.COLUMNID
					and CC.CONTEXTID = P.CONTEXTID)
	left join TABLECODES TC		on (TC.TABLECODE=DI.DATAFORMATID)
	WHERE 	Q.QUERYID = @pnQueryKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnQueryKey		int',
			  @pnQueryKey		= @pnQueryKey

	Set @nSelectedColumnsCount = @@ROWCOUNT		
End
--  If the @ptXMLSelectedColumns have been supplied, the table variable is populated from the XML.
Else If datalength(@ptXMLSelectedColumns) > 0
     and @pbUseDefaultPresentation <> 1
Begin

	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLSelectedColumns

	Set @sSQLString = "
	Insert into #tblSelectedColumns (ColumnKey, DisplaySequence, 
		SortOrder, SortDirection, 
		GroupBySortOrder, GroupBySortDirection, 
		IsFreezeColumnIndex)
	Select  *   
	from	OPENXML(@idoc, '/SelectedColumns/Column',2)
		WITH (
		      ColumnKey		int		'ColumnKey/text()',
		      DisplaySequence	smallint	'DisplaySequence/text()',
		      SortOrder		tinyint		'SortOrder/text()',
		      SortDirection	nvarchar(1)	'SortDirection/text()',
		      GroupBySortOrder	tinyint		'GroupBySortOrder/text()',
		      GroupBySortDirection nvarchar(1) 'GroupBySortDirection/text()',
		      IsFreezeColumnIndex bit	'IsFreezeColumnIndex/text()'
		     )"	

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@idoc		int',
			  @idoc		= @idoc

	Set @nSelectedColumnsCount = @@ROWCOUNT

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc

	If @nErrorCode=0
	Begin
			-- Update the table with the additional information required

			Set @sSQLString = "
			update #tblSelectedColumns
			set 	ProcedureItemID = DI.PROCEDUREITEMID,
				Qualifier = C.QUALIFIER, 
				PublishName = CC.USAGE,
				ColumnLabel = "+dbo.fn_SqlTranslatedColumn('QUERYCOLUMN','COLUMNLABEL',null,'C',@sLookupCulture,@pbCalledFromCentura)+",
				Format = TC.DESCRIPTION,
				DecimalPlaces = DI.DECIMALPLACES, 
				FormatItemID = DI.FORMATITEMID, 
				DataItemKey = DI.DATAITEMID,
				DocItemKey = C.DOCITEMID,
				ProcedureName = DI.PROCEDURENAME
			from #tblSelectedColumns S
			join QUERYCOLUMN C		on (C.COLUMNID = S.ColumnKey)
			join QUERYDATAITEM DI		on (DI.DATAITEMID = C.DATAITEMID)
			join QUERYCONTEXTCOLUMN CC 	on (CC.COLUMNID = C.COLUMNID)
			left join TABLECODES TC		on (TC.TABLECODE=DI.DATAFORMATID)
			where CC.CONTEXTID = @pnQueryContextKey"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnQueryContextKey	int',
					  @pnQueryContextKey	= @pnQueryContextKey
	End
End

-- Use the default presentation if no other information has been provided
If @nErrorCode = 0
and @nSelectedColumnsCount = 0
Begin
	-- extract defaults from database
	Set @sSQLString = "
	insert into #tblSelectedColumns (ColumnKey, DisplaySequence, SortOrder, SortDirection, 
			GroupBySortOrder, GroupBySortDirection, IsFreezeColumnIndex, ProcedureItemID, Qualifier, 
			PublishName, ColumnLabel, Format, DecimalPlaces, FormatItemID, DataItemKey, DocItemKey, ProcedureName)
	select 	T.COLUMNID,
		T.DISPLAYSEQUENCE,
		T.SORTORDER,
		T.SORTDIRECTION,
		T.GROUPBYSEQUENCE,
		T.GROUPBYSORTDIR,
		case when T.COLUMNID = isnull(P1.FREEZECOLUMNID, P.FREEZECOLUMNID) then cast(1 as bit) end,
		DI.PROCEDUREITEMID,
		C.QUALIFIER,
		CC.USAGE,
		"+dbo.fn_SqlTranslatedColumn('QUERYCOLUMN','COLUMNLABEL',null,'C',@sLookupCulture,@pbCalledFromCentura)+",
		TC.DESCRIPTION,
		DI.DECIMALPLACES,
		DI.FORMATITEMID,
		DI.DATAITEMID,
		C.DOCITEMID,
		DI.PROCEDURENAME
	from QUERYPRESENTATION P
	-- The default may be overridden for a specific user identity
	left join QUERYPRESENTATION P1 	on (P1.CONTEXTID = P.CONTEXTID
					and P1.ISDEFAULT = P.ISDEFAULT
					and P1.IDENTITYID = @pnUserIdentityId
					and ((P1.PRESENTATIONTYPE IS NULL and @psPresentationType IS NULL) OR
		                             (P1.PRESENTATIONTYPE = @psPresentationType and @psPresentationType IS NOT NULL)))
	join QUERYCONTENT T		on (T.PRESENTATIONID = isnull(P1.PRESENTATIONID, P.PRESENTATIONID))
	join QUERYCOLUMN C		on (C.COLUMNID = T.COLUMNID)
	join QUERYDATAITEM DI		on (DI.DATAITEMID = C.DATAITEMID)
	join QUERYCONTEXTCOLUMN CC 	on (CC.COLUMNID = C.COLUMNID
					and CC.CONTEXTID = P.CONTEXTID)
	left join TABLECODES TC		on (TC.TABLECODE=DI.DATAFORMATID)
	WHERE 	P.CONTEXTID = @pnQueryContextKey
	AND 	P.ISDEFAULT = 1
	AND 	P.IDENTITYID IS NULL
	AND    ((P.PRESENTATIONTYPE IS NULL and @psPresentationType IS NULL) OR
		(P.PRESENTATIONTYPE = @psPresentationType and @psPresentationType IS NOT NULL))"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnQueryContextKey	int,
			  @pnUserIdentityId	int,
			  @psPresentationType 	nvarchar(30)',
			  @pnQueryContextKey	= @pnQueryContextKey,
			  @pnUserIdentityId	= @pnUserIdentityId,
			  @psPresentationType	= @psPresentationType
	
	Set @nSelectedColumnsCount = @@ROWCOUNT	
End

-- If the selected columns were not provided directly,
-- apply subset and subject security to remove columns
If datalength(@ptXMLSelectedColumns) = 0
or datalength(@ptXMLSelectedColumns) is null
Begin
	Set @bIsExists = 0
	
	Set @sSQLString = "
	Select @bIsExists = 1 
	from #tblSelectedColumns 
	where Qualifier is not null"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@bIsExists	bit		OUTPUT',
			@bIsExists	= @bIsExists	OUTPUT
	
	-- If qualifiers are present, subset security needs to be applied to ensure
	-- that the user has access to the qualifier
	If  @bIsExists = 1
	and @nErrorCode = 0
	Begin
		-- Note: syntax used because of problems with correlation names matching
		-- with table variables that has been implemented before the temporary table.
		Set @sSQLString = "
		Delete 	#tblSelectedColumns
		where RowKey in (
			select S.RowKey
			from #tblSelectedColumns S
			join	QUERYDATAITEM DI	on (DI.DATAITEMID = S.DataItemKey)
			-- For QUALIFIERTYPE = 1 the fn_FilterUserTextTypes needs to be applied
			left join dbo.fn_FilterUserTextTypes(@pnUserIdentityId,null,@pbIsExternalUser,@pbCalledFromCentura) FT
							on (FT.TEXTTYPE = S.Qualifier
							and DI.QUALIFIERTYPE = 1)
			-- For QUALIFIERTYPE = 2 the fn_FilterUserNameTypes needs to be applied 
			left join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,null,@pbIsExternalUser,@pbCalledFromCentura) FN
							on (Charindex(FN.NAMETYPE +',', S.Qualifier + ',') > 0
							and DI.QUALIFIERTYPE = 2)
			-- For QUALIFIERTYPE = 5 the fn_FilterUserNumberTypes needs to be applied
			left join dbo.fn_FilterUserNumberTypes(@pnUserIdentityId,null,@pbIsExternalUser,@pbCalledFromCentura) FNM
							on (FNM.NUMBERTYPE = S.Qualifier
							and DI.QUALIFIERTYPE = 5)
			-- For QUALIFIERTYPE = 8 the fn_FilterUserAliasTypes needs to be applied
	    		left join dbo.fn_FilterUserAliasTypes(@pnUserIdentityId,null,@pbIsExternalUser,@pbCalledFromCentura) FUAT
			   				on (FUAT.ALIASTYPE = S.Qualifier
							and DI.QUALIFIERTYPE = 8)
			where	S.Qualifier is not null
			and	DI.QUALIFIERTYPE IN (1,2,5,8)
			and 	CASE	WHEN DI.QUALIFIERTYPE = 1 THEN FT.TEXTTYPE					 
			          	WHEN DI.QUALIFIERTYPE = 2 THEN FN.NAMETYPE
					WHEN DI.QUALIFIERTYPE = 5 THEN FNM.NUMBERTYPE 
					WHEN DI.QUALIFIERTYPE = 8 THEN FUAT.ALIASTYPE 
				END IS NULL)"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @pbIsExternalUser	bit,
				  @pbCalledFromCentura	bit',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @pbIsExternalUser	= @pbIsExternalUser,
				  @pbCalledFromCentura	= @pbCalledFromCentura

		-- For External users, also check the events and instruction types
		If @nErrorCode = 0
		and @pbIsExternalUser = 1
		Begin
			Set @sSQLString = "
			Delete 	#tblSelectedColumns
			where RowKey in (
				select S.RowKey
				from #tblSelectedColumns S
				join	QUERYDATAITEM DI	on (DI.DATAITEMID = S.DataItemKey)
				-- For QUALIFIERTYPE = 4 the fn_FilterUserEvents needs to be applied
		    		left join dbo.fn_FilterUserEvents(@pnUserIdentityId,null,1,@pbCalledFromCentura) FE
				   				on (cast(FE.EVENTNO as nvarchar(12)) = S.Qualifier
								and DI.QUALIFIERTYPE = 4)   
				-- For QUALIFIERTYPE = 14 the fn_FilterUserInstructionTypes needs to be applied
		    		left join dbo.fn_FilterUserInstructionTypes(@pnUserIdentityId,null,1,@pbCalledFromCentura) FI
				   				on (FI.INSTRUCTIONTYPE = S.Qualifier
								and DI.QUALIFIERTYPE = 14)   
				where	S.Qualifier is not null
				and	DI.QUALIFIERTYPE IN (4,14)
				and 	CASE	WHEN DI.QUALIFIERTYPE = 4 THEN cast(FE.EVENTNO as nvarchar(12))
						WHEN DI.QUALIFIERTYPE = 14 THEN FI.INSTRUCTIONTYPE				 
					END IS NULL
				)"

			exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @pbCalledFromCentura	bit',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @pbCalledFromCentura	= @pbCalledFromCentura
		End
	End

	If @nErrorCode = 0
	Begin
		Set @bIsExists = 0

		Set @sSQLString = "
		Select @bIsExists = 1
		from #tblSelectedColumns S
		join	QUERYDATAITEM DI	on (DI.DATAITEMID = S.DataItemKey)
		join	TOPICDATAITEMS TDI	on (TDI.DATAITEMID = DI.DATAITEMID)"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExists	bit		OUTPUT',
				  @bIsExists	= @bIsExists	OUTPUT	
	End

	-- Remove any columns the user does not have subject security for
	If @nErrorCode = 0
	and @bIsExists = 1
	Begin
		Set @sSQLString = "
		Delete 	#tblSelectedColumns
		where RowKey in (
			select S.RowKey
			from #tblSelectedColumns S
			join	QUERYDATAITEM DI	on (DI.DATAITEMID = S.DataItemKey)
			join	TOPICDATAITEMS TDI	on (TDI.DATAITEMID = DI.DATAITEMID)
		 	left join dbo.fn_PermissionsGranted(@pnUserIdentityId, 'DATATOPIC', NULL, NULL, @dtToday) PG
			       				on (PG.ObjectIntegerKey = TDI.TOPICID
			       				and PG.CanSelect = 1)
			left join dbo.fn_ValidObjects(null, 'DATATOPICREQUIRES', @dtToday) VO
							on (VO.ObjectIntegerKey = TDI.TOPICID)
			where 	PG.ObjectIntegerKey is null
			or	VO.ObjectIntegerKey is null
			)"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @dtToday		datetime',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @dtToday		= @dtToday
	End
End

-- Add any Formatting columns (e.g. currency code), not already present
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	insert into #tblSelectedColumns (ProcedureItemID, Qualifier, ProcedureName)
	select 	distinct
		S.FormatItemID,
		S.Qualifier,
		S.ProcedureName
	from #tblSelectedColumns S
	where S.FormatItemID is not null
	and   S.DisplaySequence is not null
	-- Ensure that the data is not already there.
	and not exists(
		select 1
		from #tblSelectedColumns S2
		where	S2.ProcedureItemID = S.FormatItemID
		and	S2.ProcedureName=S.ProcedureName
		and 	(S2.Qualifier = S.Qualifier or
			(S2.Qualifier is null and S.Qualifier is null)))"

	exec @nErrorCode=sp_executesql @sSQLString
End

-- Add any Implied columns (e.g. links), not already present.
-- Note: this is only required for display, not reporting.
If @nErrorCode = 0
and @pnReportToolKey is null
Begin
	-- Implied Data per column
	Set @sSQLString = "
	Insert into #tblSelectedColumns (ProcedureItemID, Qualifier, PublishName, ProcedureName)
	select 	distinct
		II.PROCEDUREITEMID,
		-- The implied data may use the same qualifier as the explicitly selected data
		case when II.USESQUALIFIER = 1 then S.Qualifier else null end,
		II.USAGE,
		II.PROCEDURENAME
	From #tblSelectedColumns S
	join QUERYCOLUMN C		on (C.COLUMNID = S.ColumnKey)
	-- Implied data may be held at the Context or Context/DataItem levels
	join QUERYIMPLIEDDATA I		on (I.DATAITEMID = C.DATAITEMID
					and I.CONTEXTID = @pnQueryContextKey)
	join QUERYIMPLIEDITEM II	on (II.IMPLIEDDATAID = I.IMPLIEDDATAID)
	where S.DisplaySequence is not null
	-- Ensure that the data is not already there.
	and not exists(
		select 1
		from #tblSelectedColumns S2
		where	S2.ProcedureItemID = II.PROCEDUREITEMID
		and	S2.ProcedureName = II.PROCEDURENAME
		and 	((S2.Qualifier = S.Qualifier) or
			 (S2.Qualifier is null and S.Qualifier is null))
		and	((S2.PublishName = II.USAGE) or
			 (II.USAGE is null))
		)"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnQueryContextKey	int',
				  @pnQueryContextKey	= @pnQueryContextKey

	-- Add any implied data at the Context level
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Insert into #tblSelectedColumns (ProcedureItemID, Qualifier, PublishName, ProcedureName)
		select 	distinct
			II.PROCEDUREITEMID,
			null,
			II.USAGE,
			II.PROCEDURENAME
		From 	QUERYIMPLIEDDATA I
		join 	QUERYIMPLIEDITEM II	on (II.IMPLIEDDATAID = I.IMPLIEDDATAID)
		where 	I.CONTEXTID = @pnQueryContextKey
		and	I.DATAITEMID IS NULL
		-- Ensure that the data is not already there.
		and not exists(
			select 1
			from #tblSelectedColumns S2
			where	S2.ProcedureItemID = II.PROCEDUREITEMID
			and	S2.ProcedureName = II.PROCEDURENAME
			and	((S2.PublishName = II.USAGE) or
				 (II.USAGE is null))
			)"
	
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnQueryContextKey	int',
				  @pnQueryContextKey	= @pnQueryContextKey
	End

	-- Remove any duplicate implied columns
	-- The same implied column may appear twice - one with a usage (PublishName) and one without
	If @nErrorCode = 0
	Begin
		-- Note: syntax used because of problems with correlation names matching
		-- with table variables.
		Set @sSQLString = "
		Delete from #tblSelectedColumns
		where RowKey in (
			select S.RowKey
			from #tblSelectedColumns S
			join #tblSelectedColumns S2 on (S2.ProcedureItemID = S.ProcedureItemID
						and	S2.ProcedureName = S.ProcedureName
						and 	((S2.Qualifier = S.Qualifier) or
							 (S2.Qualifier is null and S.Qualifier is null))
						and	S2.PublishName is not null)
			where S.PublishName is null and S.ColumnLabel is null
			)"
	
		exec @nErrorCode=sp_executesql @sSQLString
	End
End

-- Generate PublishName
-- The internal column names are used by the report layout to identify the fields.
-- It must be consistent (the same value for every query), and as meaningful as possible.
-- The .net framework also requires that it contains a valid set of characters.
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	update	#tblSelectedColumns
	set	PublishName = ProcedureItemID+
			case when Qualifier IS NULL
				then NULL
				else dbo.fn_GetCorrelationSuffix(Qualifier)
			end+
			case when ColumnKey IS NULL
				then NULL
				else dbo.fn_GetCorrelationSuffix(ColumnKey)
			end
	where 	PublishName is null"

	exec @nErrorCode=sp_executesql @sSQLString
End

-- Subject security
-- Parse the selected columns.  If the user does not have topic rights to the data item,
-- ask the stored procedure to return the 'NULL' column; i.e. the search stored procedure 
-- must support a ProcedureItemID = 'NULL'
If @nErrorCode = 0
Begin
	-- Get the first security topic for the data items
	Set @sSQLString = "
	Select	@nTopicKey=min(TD.TOPICID)
	From	#tblSelectedColumns S
	join	TOPICDATAITEMS TD	on (TD.DATAITEMID = S.DataItemKey)
	-- Exclude columns for internal use
	where	DisplaySequence is not null"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nTopicKey	int		OUTPUT',
				  @nTopicKey	= @nTopicKey	OUTPUT

	While @nTopicKey is not NULL
	and   @nErrorCode=0
	Begin
		-- Replace all the selected data items for the topic with NULL
		Set @sSQLString = "
		update 	#tblSelectedColumns
		set 	ProcedureItemID = 'NULL',	-- ask the procedure for a null column
			FormatItemID = null,
			DataItemKey = null
		from	TOPICDATAITEMS TD
		where	TD.TOPICID = @nTopicKey
		and	TD.DATAITEMID = DataItemKey
		and	not exists
			-- Does the current user have access to the requested data item?
			(select	*
			 from dbo.fn_GetTopicSecurity(@pnUserIdentityId, @nTopicKey, default, @dtToday))"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nTopicKey		int,
				  @pnUserIdentityId	int,
				  @dtToday		datetime',
				  @nTopicKey		= @nTopicKey,
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @dtToday		= @dtToday

		-- Get the next topic
		If @nErrorCode=0
		Begin
			Set @sSQLString = "
			Select	@nTopicKey=min(TD.TOPICID)
			From	#tblSelectedColumns S
			join	TOPICDATAITEMS TD	on (TD.DATAITEMID = S.DataItemKey)
			Where	TD.TOPICID>@nTopicKey
			-- Exclude columns for internal use
			and	DisplaySequence is not null"
		
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTopicKey	int		OUTPUT',
					  @nTopicKey	= @nTopicKey	OUTPUT
		End
	End
End

-- Reporting requires images as data not a key
If @nErrorCode = 0
and @pnReportToolKey is not null
Begin
	Set @sSQLString = "
	update	#tblSelectedColumns
	set	ProcedureItemID = 'ImageData',
		Format = 'Image Data'
	where	ProcedureItemID = 'ImageKey'"

	exec @nErrorCode=sp_executesql @sSQLString
End

-- Formatting result set
If @nErrorCode = 0
and (@psResultRequired is null or UPPER(@psResultRequired) = 'FORMATTING')
Begin
	Set @sSQLString = "
	select	S.PublishName	as ID,
		S.ColumnLabel	as Title,
		S.Format	as Format,
		case S.Format	when 'Currency'	then 2
				when 'Local Currency' then case when CUR.COLBOOLEAN = 1 then 0 else ISNULL(CY.DECIMALPLACES, 2) end
				else S.DecimalPlaces
				end
				as DecimalPlaces,
		case when S.Format in ('Currency', 'Local Currency') 
				-- The name of the published column that will contain the currency symbol
				then S2.PublishName
				else null end
				as CurrencySymbol
	from #tblSelectedColumns S
	-- Locate the column containing the formatting.
	left join #tblSelectedColumns S2	on (S2.RowKey =
							-- There may be multiple rows with the same
							-- ProcedureItemId/Qualifier combination
							(select min(RowKey)
							from #tblSelectedColumns S3
							where S3.ProcedureItemID = S.FormatItemID
							and S3.ProcedureName = S.ProcedureName
							and ((S3.Qualifier = S.Qualifier) or
							     (S3.Qualifier is null and S.Qualifier is null))
							)
						    )
	left join SITECONTROL CUR on (CUR.CONTROLID='Currency Whole Units')
	-- Match the currency information based on default currency
	left join SITECONTROL SC on (SC.CONTROLID='CURRENCY')
	left join CURRENCY CY	on (CY.CURRENCY = SC.COLCHARACTER
				-- Decimal places implemented in Centura
				and isnull(@pbCalledFromCentura,0) = 0 )
	where S.DisplaySequence is not null
	order by S.DisplaySequence"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pbCalledFromCentura	bit',
				  @pbCalledFromCentura	= @pbCalledFromCentura
End

-- Link result set
-- Relates the column names in the search result set to the links required
If @nErrorCode = 0
and (@psResultRequired is null or UPPER(@psResultRequired) like 'LINK%')
Begin
	Set @sSQLString = "
	select	S.PublishName	as ID,
		I.TYPE		as Type
	from 	#tblSelectedColumns S
	join 	QUERYIMPLIEDDATA I	on (I.DATAITEMID = S.DataItemKey)
	where 	I.CONTEXTID = @pnQueryContextKey
	and	DisplaySequence is not null
	and     I.TYPE <> 'Reference'
	-- Result set is not required for reports
	and 	@pnReportToolKey is null
	order by S.PublishName"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnQueryContextKey	int,
				  @pnReportToolKey	int',
				  @pnQueryContextKey	= @pnQueryContextKey,
				  @pnReportToolKey	= @pnReportToolKey
End

-- Argument result set
-- Relates the column names in the search result set to the link arguments required
If @nErrorCode = 0
and (@psResultRequired is null or UPPER(@psResultRequired) like 'LINKARGUMENT%')
Begin
	Set @sSQLString = "
	select	S.PublishName	as ID,
		-- The name the column will have in the result set
		isnull(II.USAGE, S2.PublishName)
				as Source
	from #tblSelectedColumns S
	join QUERYIMPLIEDDATA I		on (I.DATAITEMID = S.DataItemKey)
	join QUERYIMPLIEDITEM II	on (II.IMPLIEDDATAID = I.IMPLIEDDATAID)
	-- Locate the column containing the argument.
	left join #tblSelectedColumns S2	on (S2.RowKey =
							-- There may be multiple rows with the same
							-- ProcedureItemId/Qualifier combination
							(select min(RowKey)
							from #tblSelectedColumns S3
							where S3.ProcedureItemID = II.PROCEDUREITEMID
							and   S3.ProcedureName = II.PROCEDURENAME
							and ((S3.Qualifier = S.Qualifier) or
							     (S3.Qualifier is null and S.Qualifier is null))
							and ((S3.PublishName = II.USAGE) or
							     (II.USAGE IS NULL))
							)
						    )
	where I.CONTEXTID = @pnQueryContextKey
	and   S.DisplaySequence is not null
	and   I.TYPE <> 'Reference'
	-- Result set is not required for reports
	and @pnReportToolKey is null
	order by S.PublishName, II.SEQUENCENO"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnQueryContextKey	int,
				  @pnReportToolKey	int',
				  @pnQueryContextKey	= @pnQueryContextKey,
				  @pnReportToolKey	= @pnReportToolKey
End

-- OutputRequests result set
-- The columns required in the search result set
If @nErrorCode = 0
and (@psResultRequired is null or UPPER(@psResultRequired) like 'OUTPUTREQUEST%')
Begin
	Set @sSQLString = "
	select 	ProcedureItemID		as 'ID', 
		Qualifier		as 'Qualifier', 
		PublishName		as 'PublishName', 
		SortOrder		as 'SortOrder', 
		SortDirection		as 'SortDirection',
		GroupBySortOrder	as 'GroupBySortOrder',
		GroupBySortDirection as 'GroupBySortDirection',
		IsFreezeColumnIndex as 'IsFreezeColumnIndex',
		DocItemKey		as 'DocItemKey',
		ProcedureName		as 'ProcedureName'
	from #tblSelectedColumns
	order by PublishName"

	exec @nErrorCode=sp_executesql @sSQLString
End

-- FilterCriteria result set
If @nErrorCode = 0
and (@psResultRequired is null or UPPER(@psResultRequired) = 'FILTERCRITERIA')
Begin
        
	Set @sSQLString = "
	select F.XMLFILTERCRITERIA as XMLCriteria
	from QUERY Q
	join QUERYFILTER F	on (F.FILTERID = Q.FILTERID)
	where QUERYID = @pnQueryKey"
        
        exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnQueryKey	int',
				  @pnQueryKey	= @pnQueryKey
End

-- Populating Search dataset

If @nErrorCode = 0
and (@psResultRequired is null or UPPER(@psResultRequired) = 'SEARCH')
Begin
	Set @sSQLString = "
	Select  Q.QUERYID		as 'QueryKey',
		"+dbo.fn_SqlTranslatedColumn('QUERY','QUERYNAME',null,'Q',@sLookupCulture,@pbCalledFromCentura)+
				      " as 'QueryName',
		"+dbo.fn_SqlTranslatedColumn('QUERYPRESENTATION','REPORTTITLE',null,'QP',@sLookupCulture,@pbCalledFromCentura)+
				      " as 'ReportTitle',
		QP.REPORTTEMPLATE	as 'ReportTemplateName',		
		QP.REPORTTOOL		as 'ReportToolKey',	
		QP.EXPORTFORMAT		as 'ExportFormatKey'
	from	QUERY Q
	left join QUERYPRESENTATION QP	on (QP.PRESENTATIONID = Q.PRESENTATIONID)
	where	Q.QUERYID = @pnQueryKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnQueryKey	int',					  
					  @pnQueryKey	= @pnQueryKey		
End

-- ContextLink result set
-- The links required per result row
If @nErrorCode = 0
and (@psResultRequired is null or UPPER(@psResultRequired) = 'CONTEXTLINK')
Begin
	Set @sSQLString = "
	select	I.TYPE		as Type
	from 	QUERYIMPLIEDDATA I
	where 	I.CONTEXTID = @pnQueryContextKey
	and	I.DATAITEMID IS NULL
	and     I.TYPE <> 'Reference'
	-- Result set is not required for reports
	and 	@pnReportToolKey is null
	order by I.TYPE"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnQueryContextKey	int,
				  @pnReportToolKey	int',
				  @pnQueryContextKey	= @pnQueryContextKey,
				  @pnReportToolKey	= @pnReportToolKey
End

-- Argument result set
-- The link arguments required per result row
If @nErrorCode = 0
and (@psResultRequired is null or UPPER(@psResultRequired) = 'CONTEXTLINKARGUMENT')
Begin
	Set @sSQLString = "
	select	I.TYPE		as Type,
		-- The name the column will have in the result set
		isnull(II.USAGE, S.PublishName)
				as Source
	from QUERYIMPLIEDDATA I
	join QUERYIMPLIEDITEM II	on (II.IMPLIEDDATAID = I.IMPLIEDDATAID)
	-- Locate the column containing the argument.
	left join #tblSelectedColumns S	on (S.RowKey =
						-- There may be multiple rows with the same
						-- ProcedureItemId/Qualifier combination
						(select min(RowKey)
						from #tblSelectedColumns S2
						where S2.ProcedureItemID = II.PROCEDUREITEMID
						and   S2.ProcedureName = II.PROCEDURENAME
						and ((S2.PublishName = II.USAGE) or
						     (II.USAGE IS NULL))
						)
					    )
	where 	I.CONTEXTID = @pnQueryContextKey
	and	I.DATAITEMID IS NULL
	and   	I.TYPE <> 'Reference'
	-- Result set is not required for reports
	and 	@pnReportToolKey is null
	order by I.TYPE, II.SEQUENCENO"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnQueryContextKey	int,
				  @pnReportToolKey	int',
				  @pnQueryContextKey	= @pnQueryContextKey,
				  @pnReportToolKey	= @pnReportToolKey
End

-- Extract the name of the stored procedure to run the search
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select @psProcedureName = PROCEDURENAME
	from QUERYCONTEXT
	where CONTEXTID = @pnQueryContextKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psProcedureName	nvarchar(50) output,
					  @pnQueryContextKey	int',
					  @psProcedureName	= @psProcedureName output,
					  @pnQueryContextKey	= @pnQueryContextKey
End

Return @nErrorCode
GO

Grant execute on dbo.ip_ListSearchRequirements to public
GO
