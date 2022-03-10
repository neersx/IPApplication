-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_HasDueDatePresentation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_HasDueDatePresentation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_HasDueDatePresentation.'
	Drop procedure [dbo].[csw_HasDueDatePresentation]
End
Print '**** Creating Stored Procedure dbo.csw_HasDueDatePresentation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_HasDueDatePresentation
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnQueryContextKey		int		= null,		-- The context of the search.  May only be null if @pnQueryKey is provided.
	@pnQueryKey			int		= null,		-- The key of a saved search to be run.
	@ptXMLSelectedColumns		ntext		= null,		-- Any columns dynamically requested, expressed as XML.
	@psPresentationType 		nvarchar(30)	= null,		-- The name of a secondary type of presentation. Used to distinguish multiple default presentations where necessary.
	@pbUseDefaultPresentation 	bit		= 0,		-- When true, any presentation stored against the current search will be ignored in favour of the default presentation for the context.
	@pbIsExternalUser		bit		= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	csw_HasDueDatePresentation
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns True if the search request contains due date columns in the presentation. 
--		Otherwise returns false.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 Jul 2011	LP	RFC9541	1	Procedure created

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
			where S.PublishName is null
			)"
	
		exec @nErrorCode=sp_executesql @sSQLString
	End
End

If @nErrorCode = 0
Begin
	If Exists 
	(Select 1 FROM #tblSelectedColumns S
				join QUERYCONTEXTCOLUMN Q on (Q.COLUMNID = S.ColumnKey)
				where Q.GROUPID = CASE WHEN @pnQueryContextKey = 2 THEN -44 ELSE -45 END)
	Begin
		SELECT cast(1 as bit) as 'HasDueDateColumn'
	End
	Else 
	Begin
		SELECT cast(0 as bit) as 'HasDueDateColumn'
	End
End
	

Return @nErrorCode
GO

Grant execute on dbo.csw_HasDueDatePresentation to public
GO
