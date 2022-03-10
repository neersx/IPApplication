-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_GenerateQueryRules
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_GenerateQueryRules]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_GenerateQueryRules.'
	Drop procedure [dbo].[ip_GenerateQueryRules]
End
Print '**** Creating Stored Procedure dbo.ip_GenerateQueryRules...'
Print ''
GO


SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ip_GenerateQueryRules
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@ptXMLQueryRules	ntext
)
as
-- PROCEDURE:	ip_GenerateQueryRules
-- VERSION:	7
-- DESCRIPTION:	An internal stored procedure to generate scripting for Query* database
--		table rules from XML input.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02-Jul-2004	JEK		1	Procedure created
-- 11-Apr-2005	TM	RFC1896	2	Modify utility to generate insert statements to QueryDataItem containing 
--					the new IsAggregate column.
-- 22-Apr-2005	TM	RFC1896	3	Add FormatItemID column to the QueryDataItem insert statement.
-- 16-Jun-2005	TM	RFC2575	4	Correct the QueryColumn.Description datalength.
-- 06 Jul 2005	JEK	RFC2806 5	Only generate QUERYCONTENT if there is a DisplaySequence or SortOrder
-- 16-Jan-2007	MLE		6	Changed use of CHAR(10) to CHAR(13) + CHAR(10)
-- 01-Jun-2005	SW	RFC5405 7	Only create QUERYPRESENTATION and QUERYCONTENT iff the presentation is default and the ISPROTECT flag is false.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
Declare @sRFC 			nvarchar(10)
Declare @sComment		nvarchar(254)
Declare @nContextID		int
Declare @sStoredProcedure 	nvarchar(50)
Declare @nFirstColumnID 	int
Declare @idoc 			int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument		
Declare @nDefaultPresentationID	int
Declare @CRLF			char(2)		-- Declare standard string 

Declare @tblColumn table
	(Ident			int IDENTITY(0,1),
	 ProcedureName		nvarchar(50) collate database_default,
	 ProcedureItemID	nvarchar(50) collate database_default,
 	 Qualifier		nvarchar(20) collate database_default,
 	 ColumnLabel		nvarchar(50) collate database_default,	
	 Description		nvarchar(254) collate database_default
	)

-- Initialise variables
Set @nErrorCode = 0
Set @CRLF = char(13) + char(10)

If @nErrorCode = 0
Begin

	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLQueryRules
	
	Select 	@sRFC 			= ChangeReference,
		@sComment		= Comment,
		@nContextID		= ContextID,
		@sStoredProcedure	= StoredProcedure,
		@nFirstColumnID		= FirstColumnID
	from	OPENXML (@idoc, '/QueryRules',2)
		WITH (
		      ChangeReference		nvarchar(10)	'ChangeReference/text()',
		      Comment			nvarchar(254)	'Comment/text()',
		      ContextID			int		'ContextID/text()',
		      StoredProcedure		nvarchar(50)	'StoredProcedure/text()',
		      FirstColumnID		int		'FirstColumnID/text()'
		     )

	set @nErrorCode = @@ERROR

	--print 'RFC = '+@sRFC
	--print 'Comment = '+@sComment
	--print 'Context ID = '+cast(@nContextID as nvarchar)
	--print 'StoredProcedure = '+@sStoredProcedure
	--print 'First Column ID = '+cast(@nFirstColumnID as nvarchar)

End

--	QueryProcedureUsed

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/ProcedureUsed[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"++@CRLF++
"    	/*** "+@sRFC+" "+@sComment+" - Query Procedure Used						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

	select
"	If NOT exists (SELECT * FROM QUERYPROCEDUREUSED WHERE PROCEDURENAME ='"+isnull(ProcedureName, @sStoredProcedure)+"' AND USESPROCEDURENAME= '"+UsesProcedureName+"')"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data QUERYPROCEDUREUSED.PROCEDURENAME = "+isnull(ProcedureName, @sStoredProcedure)+" AND USESPROCEDURENAME= "+UsesProcedureName+"'"+@CRLF+
"		 INSERT INTO QUERYPROCEDUREUSED (PROCEDURENAME, USESPROCEDURENAME, EXCLUDEFILTERNODE)"+@CRLF+
"		 VALUES ('"+isnull(ProcedureName, @sStoredProcedure)+"', '"+UsesProcedureName+"', "+
			case when ExcludeFilterNode is null then 'NULL' else dbo.fn_WrapQuotes(ExcludeFilterNode,0,0) end+")"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYPROCEDUREUSED table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" QUERYPROCEDUREUSED.PROCEDURENAME = "+isnull(ProcedureName, @sStoredProcedure)+" AND USESPROCEDURENAME= "+UsesProcedureName+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF

--	Select 	ProcedureName, UsesProcedureName, ExcludeFilterNode
	from	OPENXML (@idoc, '/QueryRules/ProcedureUsed',2)
		WITH (
		      ProcedureName	nvarchar(50)	'ProcedureName/text()',
		      UsesProcedureName	nvarchar(50)	'UsesProcedureName/text()',
		      ExcludeFilterNode	nvarchar(50)	'ExcludeFilterNode/text()'
		     )

	set @nErrorCode = @@ERROR
End

--	QueryContext

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/Context[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Query Context							***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

	Select
"	If NOT exists(SELECT * FROM QUERYCONTEXT WHERE CONTEXTID = "+isnull(ContextID, @nContextID)+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data QUERYCONTEXT.CONTEXTID = "+isnull(ContextID, @nContextID)+"'"+@CRLF+
"		 INSERT INTO QUERYCONTEXT (CONTEXTID, CONTEXTNAME, PROCEDURENAME, NOTES)"+@CRLF+
"		 VALUES ("+isnull(ContextID, @nContextID)+", "+dbo.fn_WrapQuotes(Name,0,0)+", '"+isnull(StoredProcedure, @sStoredProcedure)+"', "+dbo.fn_WrapQuotes(Notes,0,0)+")"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYCONTEXT table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" QUERYCONTEXT.CONTEXTID = "+isnull(ContextID, @nContextID)+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF
--	Select 	ContextID, Name, Notes, StoredProcedure
	from	OPENXML (@idoc, '/QueryRules/Context',2)
		WITH (
		      ContextID		nvarchar(10)	'ContextID/text()',
		      Name		nvarchar(50)	'Name/text()',
		      Notes		nvarchar(254)	'Notes/text()',
		      StoredProcedure	nvarchar(50)	'StoredProcedure/text()'
		     )

	set @nErrorCode = @@ERROR
End

--	QueryColumnGroup

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/ColumnGroup[descendant::text()]',2))
Begin
	select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Query Column Groups						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF+ 
"	SET IDENTITY_INSERT QUERYCOLUMNGROUP ON"+@CRLF+
"	go"+@CRLF

	select
"	If NOT exists(SELECT * FROM QUERYCOLUMNGROUP WHERE GROUPNAME = "+dbo.fn_WrapQuotes(GroupName,0,0)+" AND CONTEXTID = "+isnull(ContextID, @nContextID)+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data QUERYCOLUMNGROUP.GROUPNAME = "+replace(GroupName,'''','''''')+"'"+@CRLF+
"		 INSERT INTO QUERYCOLUMNGROUP (GROUPID, GROUPNAME, DISPLAYSEQUENCE, CONTEXTID)"+@CRLF+
"		 VALUES ("+GroupID+", "+dbo.fn_WrapQuotes(GroupName,0,0)+", "+DisplaySequence+", "+isnull(ContextID, @nContextID)+" )"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYCOLUMNGROUP table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" QUERYCOLUMNGROUP.GROUPNAME = "+replace(GroupName,'''','''''')+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF
--	Select 	GroupID, ContextID, GroupName, DisplaySequence
	from	OPENXML (@idoc, '/QueryRules/ColumnGroup',2)
		WITH (
		      GroupID		nvarchar(10)	'GroupID/text()',
		      ContextID		nvarchar(10)	'ContextID/text()',
		      GroupName		nvarchar(50)	'GroupName/text()',
		      DisplaySequence	nvarchar(10)	'DisplaySequence/text()'
		     )

	select
"	SET IDENTITY_INSERT QUERYCOLUMNGROUP OFF"+@CRLF+
"	go"+@CRLF

	set @nErrorCode = @@ERROR
End

--	QueryPresentation

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/Presentation[descendant::text()]',2))
Begin
	select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Query Presentation						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF+ 
"	SET IDENTITY_INSERT QUERYPRESENTATION ON"+@CRLF+
"	go"+@CRLF

	select
"	If NOT exists(SELECT * FROM QUERYPRESENTATION WHERE PRESENTATIONID = "+PresentationID+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data QUERYPRESENTATION.PRESENTATIONID = "+PresentationID+"'"+@CRLF+
"		 INSERT INTO QUERYPRESENTATION (PRESENTATIONID, CONTEXTID, IDENTITYID, ISDEFAULT, 
			REPORTTITLE, REPORTTEMPLATE, REPORTTOOL, EXPORTFORMAT, PRESENTATIONTYPE)"+@CRLF+
"		 SELECT DISTINCT "+PresentationID+", "+isnull(ContextID, @nContextID)+", NULL, 1, "+
			case when ReportTitle is null then 'NULL' else dbo.fn_WrapQuotes(ReportTitle,0,0) end+", "+
			case when ReportTemplate is null then 'NULL' else dbo.fn_WrapQuotes(ReportTemplate,0,0) end+", "+
			case when ReportTool is null then 'NULL' else dbo.fn_WrapQuotes(ReportTool,0,0) end+", "+
			case when ExportFormat is null then 'NULL' else dbo.fn_WrapQuotes(ExportFormat,0,0) end+", "+
			case when PresentationType is null then 'NULL' else dbo.fn_WrapQuotes(PresentationType,0,0) end+@CRLF+
"		 FROM (select 1 as txt) TMP"+@CRLF+
"		 left join QUERYPRESENTATION P on (P.CONTEXTID = "+isnull(ContextID, @nContextID)+")"+@CRLF+
"		 where ISNULL(P.ISDEFAULT, 0) = 0"+@CRLF+
"		 or ISNULL(P.ISPROTECT, 0) = 0"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYPRESENTATION table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" QUERYPRESENTATION.PRESENTATIONID = "+PresentationID+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF

--	Select 	PresentationID, ContextID, IsDefault, ReportTitle, ReportTemplate, ReportTool, ExportFormat
	from	OPENXML (@idoc, '/QueryRules/Presentation',2)
		WITH (
		      PresentationID	nvarchar(10)	'PresentationID/text()',
		      ContextID		nvarchar(10)	'ContextID/text()',
		      ReportTitle	nvarchar(80)	'ReportTitle/text()',
		      ReportTemplate	nvarchar(254)	'ReportTemplate/text()',
		      ReportTool	nvarchar(10)	'ReportTool/text()',
		      ExportFormat	nvarchar(10)	'ExportFormat/text()',
		      PresentationType	nvarchar(50)	'PresentationType/text()'
		     )

	select
"	SET IDENTITY_INSERT QUERYPRESENTATION OFF"+@CRLF+
"	go"+@CRLF

	set @nErrorCode = @@ERROR
End

--	DefaultPresentationID

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/Presentation[descendant::text()]',2))
Begin

	Select 	@nDefaultPresentationID = PresentationID
	from	OPENXML (@idoc, '/QueryRules/Presentation',2)
		WITH (
		      PresentationID	nvarchar(10)	'PresentationID/text()'
		     )

	--print @nDefaultPresentationID

	set @nErrorCode = @@ERROR
End

--	QueryDataItem

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateDataItem[descendant::text()]',2))
Begin

	select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Query Data Item							***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF


	select
"	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = "+dbo.fn_WrapQuotes(ProcedureItemID,0,0)+" AND PROCEDURENAME = "+dbo.fn_WrapQuotes(isnull(ProcedureName,@sStoredProcedure),0,0)+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data QUERYDATAITEM.PROCEDUREITEMID = "+ProcedureItemID+"'"+@CRLF+
"		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, "+@CRLF+
"					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)"+@CRLF+
"		 select "+dbo.fn_WrapQuotes(ProcedureItemID,0,0)+", "+
			case when QualifierType is null then 'NULL' else dbo.fn_WrapQuotes(QualifierType,0,0) end+", "+
			case when SortDirection is null then 'NULL' else dbo.fn_WrapQuotes(SortDirection,0,0) end+", "+
			isnull(IsMultiResult,'0')+", "+
			isnull(IsAggregate,'0')+", "+
			case when DataItemDescription is null then 'NULL' else dbo.fn_WrapQuotes(DataItemDescription,0,0) end+", "+
			"isnull(max(DATAITEMID),0)+1, "+
			isnull(DataFormatID, '9100')+", "+
			case when FormatItemID is null then 'NULL' else dbo.fn_WrapQuotes(FormatItemID,0,0) end+", "+
			dbo.fn_WrapQuotes(isnull(ProcedureName, @sStoredProcedure),0,0)+", "+
			case when DecimalPlaces is null then 'NULL' else dbo.fn_WrapQuotes(DecimalPlaces,0,0) end+", "+
			case when FilterNodeName is null then 'NULL' else dbo.fn_WrapQuotes(FilterNodeName,0,0) end+@CRLF+
"		 from QUERYDATAITEM "+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYDATAITEM table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" QUERYDATAITEM.PROCEDUREITEMID = "+ProcedureItemID+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF

--	Select 	ProcedureName, ProcedureItemID, QualifierType, SortDirection, DataItemDescription,
--		IsMultiResult, IsAggregate, DataFormatID, FormatItemID, DecimalPlaces, FilterNodeName
	from	OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateDataItem',2)
		WITH (
		      ProcedureName	nvarchar(50)	'../ProcedureName/text()',
		      ProcedureItemID	nvarchar(50)	'../ProcedureItemID/text()',
		      QualifierType	nvarchar(10)	'QualifierType/text()',
		      SortDirection	nvarchar(1)	'SortDirection/text()',
		      DataItemDescription nvarchar(254)	'DataItemDescription/text()',
		      IsMultiResult	nvarchar(1)	'IsMultiResult/text()',
		      IsAggregate	nvarchar(1)	'IsAggregate/text()',
		      DataFormatID	nvarchar(10)	'DataFormatID/text()',
		      FormatItemID	nvarchar(50)	'FormatItemID/text()',
		      DecimalPlaces	nvarchar(10)	'DecimalPlaces/text()',
		      FilterNodeName	nvarchar(50)	'FilterNodeName/text()'
		     )

	set @nErrorCode = @@ERROR
end

--	QueryColumn

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateColumn[descendant::text()]',2))
Begin

	select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Query Column							***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF+
@CRLF+
"	SET IDENTITY_INSERT QUERYCOLUMN ON"+@CRLF+
"	go"+@CRLF

	-- Insert into a table variable to generate a sequence number in Ident
	Insert into @tblColumn (ProcedureName, ProcedureItemID, Qualifier, ColumnLabel, Description)
	Select 	isnull(ProcedureName, @sStoredProcedure), ProcedureItemID, Qualifier, ColumnLabel, Description
	from	OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateColumn',2)
		WITH (
		      ProcedureName	nvarchar(50)	'../ProcedureName/text()',
		      ProcedureItemID	nvarchar(50)	'../ProcedureItemID/text()',
		      Qualifier		nvarchar(20)	'Qualifier/text()',
		      ColumnLabel	nvarchar(50)	'ColumnLabel/text()',
		      Description	nvarchar(254)	'Description/text()'
		     )

--	select * from @tblColumn

	-- ColumnIDs are calculated by adding Ident to the FirstColumnID
	select
"	If NOT exists(	SELECT * FROM QUERYCOLUMN WHERE COLUMNID = "+cast(@nFirstColumnID-Ident as nvarchar)+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data QUERYCOLUMN for COLUMNID = "+cast(@nFirstColumnID-Ident as nvarchar)+"'"+@CRLF+
"		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)"+@CRLF+
"		 SELECT "+cast(@nFirstColumnID-Ident as nvarchar)+", "+
			dbo.fn_WrapQuotes(ColumnLabel,0,0)+", "+
			case when Description is null then 'DI.DESCRIPTION' else dbo.fn_WrapQuotes(Description,0,0) end+", "+
			case when Qualifier is null then 'NULL' else dbo.fn_WrapQuotes(Qualifier,0,0) end+", "+
			"DI.DATAITEMID"+@CRLF+
"		 FROM QUERYDATAITEM DI"+@CRLF+
"		 WHERE DI.PROCEDUREITEMID = "+dbo.fn_WrapQuotes(ProcedureItemID,0,0)+@CRLF+
"		 AND DI.PROCEDURENAME = "+dbo.fn_WrapQuotes(ProcedureName,0,0)+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYCOLUMN table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" QUERYCOLUMN for COLUMNID = "+cast(@nFirstColumnID-Ident as nvarchar)+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF
	From @tblColumn

	select
"	SET IDENTITY_INSERT QUERYCOLUMN OFF"+@CRLF+
"	go"+@CRLF

	set @nErrorCode = @@ERROR
end

--	QueryContextColumn header for either newly created QueryColumns, or existing QueryColumns

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateColumn/CreateContextColumn|/QueryRules/AddColumnToContext[descendant::text()]',2))
Begin

	select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Query Context Column						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

End

--	QueryContextColumn for newly created QueryColumns

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateColumn/CreateContextColumn',2))
Begin
	-- Some information comes from XML, and some from table variable
	select
"	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = "+cast(@nFirstColumnID-C.Ident as nvarchar)+" and CONTEXTID = "+isnull(ContextID, @nContextID)+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data QUERYCONTEXTCOLUMN for COLUMNID = "+cast(@nFirstColumnID-C.Ident as nvarchar)+" and CONTEXTID = "+isnull(ContextID, @nContextID)+"'"+@CRLF+
"		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)"+@CRLF+
"		 VALUES ("+isnull(X.ContextID, @nContextID)+", "+
			cast(@nFirstColumnID-C.Ident as nvarchar)+", "+
			case when X.Usage is null then 'NULL' else dbo.fn_WrapQuotes(X.Usage,0,0) end+", "+
			case when X.GroupID is null then 'NULL' else X.GroupID end+", "+
			case when X.IsMandatory is null then '0' else X.IsMandatory end+", "+
			case when X.IsSortOnly is null then '0' else IsSortOnly end+")"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYCONTEXTCOLUMN table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" QUERYCONTEXTCOLUMN for COLUMNID = "+cast(@nFirstColumnID-C.Ident as nvarchar)+" and CONTEXTID = "+isnull(ContextID, @nContextID)+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF
--	Select 	X.ProcedureName, X.ProcedureItemID, X.Qualifier, X.ColumnLabel, X.ContextID, X.GroupID, X.IsMandatory, X.IsSortOnly, X.Usage, C.Ident
	from	OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateColumn/CreateContextColumn',2)
		WITH (
		      ProcedureName	nvarchar(50)	'../../ProcedureName/text()',
		      ProcedureItemID	nvarchar(50)	'../../ProcedureItemID/text()',
		      Qualifier		nvarchar(20)	'../Qualifier/text()',
		      ColumnLabel	nvarchar(50)	'../ColumnLabel/text()',
		      ContextID		nvarchar(10)	'ContextID/text()',
		      GroupID		nvarchar(10)	'GroupID/text()',
		      IsMandatory	nvarchar(1)	'IsMandatory/text()',
		      IsSortOnly	nvarchar(1)	'IsSortOnly/text()',
		      Usage		nvarchar(50)	'Usage/text()'
		     ) X
	-- Join to the table variable to be able to calculate the correct ColumnID
	join @tblColumn C	on (C.ProcedureName=isnull(X.ProcedureName,@sStoredProcedure)
				and C.ProcedureItemID=X.ProcedureItemID
				and ((C.Qualifier=X.Qualifier) OR (C.Qualifier is null and X.Qualifier is null))
				and C.ColumnLabel=X.ColumnLabel)

	set @nErrorCode = @@ERROR
end

--	QueryContextColumn for columns that exist already

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/AddColumnToContext[descendant::text()]',2))
Begin

	select
"	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = "+ColumnID+" and CONTEXTID = "+isnull(ContextID, @nContextID)+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data QUERYCONTEXTCOLUMN for COLUMNID = "+ColumnID+" and CONTEXTID = "+isnull(ContextID, @nContextID)+"'"+@CRLF+
"		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)"+@CRLF+
"		 VALUES ("+isnull(ContextID, @nContextID)+", "+
			ColumnID+", "+
			case when Usage is null then 'NULL' else dbo.fn_WrapQuotes(Usage,0,0) end+", "+
			case when GroupID is null then 'NULL' else GroupID end+", "+
			case when IsMandatory is null then '0' else IsMandatory end+", "+
			case when IsSortOnly is null then '0' else IsSortOnly end+")"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYCONTEXTCOLUMN table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" QUERYCONTEXTCOLUMN for COLUMNID = "+ColumnID+" and CONTEXTID = "+isnull(ContextID, @nContextID)+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF
--	Select 	ColumnID, ContextID, GroupID, IsMandatory, IsSortOnly, Usage
	from	OPENXML (@idoc, '/QueryRules/AddColumnToContext',2)
		WITH (
		      ColumnID		nvarchar(10)	'ColumnID/text()',
		      ContextID		nvarchar(10)	'ContextID/text()',
		      GroupID		nvarchar(10)	'GroupID/text()',
		      IsMandatory	nvarchar(1)	'IsMandatory/text()',
		      IsSortOnly	nvarchar(1)	'IsSortOnly/text()',
		      Usage		nvarchar(50)	'Usage/text()'
		     )

	set @nErrorCode = @@ERROR
end

--	QueryContent header for either newly created QueryColumns, or existing QueryColumns

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateColumn/CreatePresentationContent[descendant::text()]|/QueryRules/AddColumnToPresentation[descendant::text()]',2))
Begin

	select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Query Content						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

End

--	QueryContent for newly created QueryColumns

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateColumn/CreatePresentationContent[descendant::text()]',2))
Begin
	-- Some information comes from XML, and some from table variable
	select
"	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = "+cast(@nFirstColumnID-C.Ident as nvarchar)+" AND PRESENTATIONID = "+isnull(PresentationID,@nDefaultPresentationID)+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data QUERYCONTENT for COLUMNID = "+cast(@nFirstColumnID-C.Ident as nvarchar)+" AND PRESENTATIONID = "+isnull(PresentationID,@nDefaultPresentationID)+"'"+@CRLF+
"		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)"+@CRLF+
"		 SELECT DISTINCT "+isnull(PresentationID,@nDefaultPresentationID)+", "+
			cast(@nFirstColumnID-C.Ident as nvarchar)+", "+
			case when DisplaySequence is null then 'NULL' else DisplaySequence end+", "+
			case when SortOrder is null then 'NULL' else SortOrder end+", "+
			case when SortDirection is null then 'NULL' else dbo.fn_WrapQuotes(SortDirection,0,0) end+", "+
			isnull(ContextID, @nContextID)+@CRLF+
"		 FROM (select 1 as txt) TMP"+@CRLF+
"		 left join QUERYPRESENTATION P on (P.CONTEXTID = "+isnull(ContextID, @nContextID)+")"+@CRLF+
"		 where ISNULL(P.ISDEFAULT, 0) = 0"+@CRLF+
"		 or ISNULL(P.ISPROTECT, 0) = 0"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYCONTENT table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" QUERYCONTENT for COLUMNID = "+cast(@nFirstColumnID-C.Ident as nvarchar)+" AND PRESENTATIONID "+isnull(PresentationID,@nDefaultPresentationID)+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF

--	Select 	X.ProcedureName, X.ProcedureItemID, X.Qualifier, X.ColumnLabel, 
--		PresentationID, DisplaySequence, SortOrder, SortDirection, ContextID, C.Ident
	from	OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateColumn/CreatePresentationContent',2)
		WITH (
		      ProcedureName		nvarchar(50)	'../../ProcedureName/text()',
		      ProcedureItemID		nvarchar(50)	'../../ProcedureItemID/text()',
		      Qualifier			nvarchar(20)	'../Qualifier/text()',
		      ColumnLabel		nvarchar(50)	'../ColumnLabel/text()',
		      PresentationID		nvarchar(10)	'PresentationID/text()',
		      DisplaySequence		nvarchar(10)	'DisplaySequence/text()',
		      SortOrder			nvarchar(10)	'SortOrder/text()',
		      SortDirection		nvarchar(1)	'SortDirection/text()',
		      ContextID			nvarchar(10)	'ContextID/text()'
		     ) X
	-- Join to the table variable to be able to calculate the correct ColumnID
	join @tblColumn C	on (C.ProcedureName=isnull(X.ProcedureName,@sStoredProcedure)
				and C.ProcedureItemID=X.ProcedureItemID
				and ((C.Qualifier=X.Qualifier) OR (C.Qualifier is null and X.Qualifier is null))
				and C.ColumnLabel=X.ColumnLabel)
	where DisplaySequence is not null or SortOrder is not null

	set @nErrorCode = @@ERROR
end

--	QueryContent for columns that exist already

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/AddColumnToPresentation[descendant::text()]',2))
Begin

	select
"	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = "+ColumnID+" AND PRESENTATIONID = "+isnull(PresentationID,@nDefaultPresentationID)+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data QUERYCONTENT for COLUMNID = "+ColumnID+" AND PRESENTATIONID = "+isnull(PresentationID,@nDefaultPresentationID)+"'"+@CRLF+
"		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)"+@CRLF+
"		 SELECT DISTINCT "+isnull(PresentationID,@nDefaultPresentationID)+", "+
			ColumnID+", "+
			case when DisplaySequence is null then 'NULL' else DisplaySequence end+", "+
			case when SortOrder is null then 'NULL' else SortOrder end+", "+
			case when SortDirection is null then 'NULL' else dbo.fn_WrapQuotes(SortDirection,0,0) end+", "+
			isnull(ContextID, @nContextID)+@CRLF+
"		 FROM (select 1 as txt) TMP"+@CRLF+
"		 left join QUERYPRESENTATION P on (P.CONTEXTID = "+isnull(ContextID, @nContextID)+")"+@CRLF+
"		 where ISNULL(P.ISDEFAULT, 0) = 0"+@CRLF+
"		 or ISNULL(P.ISPROTECT, 0) = 0"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYCONTENT table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" QUERYCONTENT for COLUMNID = "+ColumnID+" AND PRESENTATIONID "+isnull(PresentationID,@nDefaultPresentationID)+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF
--	Select 	PresentationID, DisplaySequence, SortOrder, SortDirection, ContextID
	from	OPENXML (@idoc, '/QueryRules/AddColumnToPresentation',2)
		WITH (
		      ColumnID		nvarchar(10)	'ColumnID/text()',
		      PresentationID		nvarchar(10)	'PresentationID/text()',
		      DisplaySequence		nvarchar(10)	'DisplaySequence/text()',
		      SortOrder			nvarchar(10)	'SortOrder/text()',
		      SortDirection		nvarchar(1)	'SortDirection/text()',
		      ContextID			nvarchar(10)	'ContextID/text()'
		     )
	where DisplaySequence is not null or SortOrder is not null

	set @nErrorCode = @@ERROR
end

--	QueryImpliedData header for either data item or context level data

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateImpliedData[descendant::text()]|/QueryRules/AddImpliedDataToContext[descendant::text()]',2))
Begin
	select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Query Implied Data						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF
End

--	QueryImpliedData

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateImpliedData[descendant::text()]',2))
Begin

	select
"	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = "+ImpliedDataID+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data IMPLIEDDATAID = "+ImpliedDataID+"'"+@CRLF+
"		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)"+@CRLF+
"		 SELECT "+ImpliedDataID+", DATAITEMID, "+
			dbo.fn_WrapQuotes(Type,0,0)+", "+
			case when Notes is null then 'NULL' else dbo.fn_WrapQuotes(Notes,0,0) end+", "+
			isnull(ContextID, @nContextID)+@CRLF+
"		 FROM QUERYDATAITEM"+@CRLF+
"		 WHERE PROCEDUREITEMID = "+dbo.fn_WrapQuotes(ProcedureItemID,0,0)+@CRLF+
"		 AND PROCEDURENAME = "+dbo.fn_WrapQuotes(isnull(ProcedureName,@sStoredProcedure),0,0)+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYIMPLIEDDATA table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" IMPLIEDDATAID = "+ImpliedDataID+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF

--	Select 	ProcedureName, ProcedureItemID, ImpliedDataID, ContextID, Type, Notes
	from	OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateImpliedData',2)
		WITH (
		      ProcedureName	nvarchar(50)	'../ProcedureName/text()',
		      ProcedureItemID	nvarchar(50)	'../ProcedureItemID/text()',
		      ImpliedDataID	nvarchar(10)	'ImpliedDataID/text()',
		      ContextID		nvarchar(10)	'ContextID/text()',
		      Type		nvarchar(50)	'Type/text()',
		      Notes		nvarchar(254)	'Notes/text()'
		     )

	set @nErrorCode = @@ERROR
end

--	QueryImpliedData at Context level

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/AddImpliedDataToContext[descendant::text()]',2))
Begin

	select
"	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = "+ImpliedDataID+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data IMPLIEDDATAID = "+ImpliedDataID+"'"+@CRLF+
"		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)"+@CRLF+
"		 VALUES ("+ImpliedDataID+", NULL, "+
			dbo.fn_WrapQuotes(Type,0,0)+", "+
			case when Notes is null then 'NULL' else dbo.fn_WrapQuotes(Notes,0,0) end+", "+
			isnull(ContextID, @nContextID)+")"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYIMPLIEDDATA table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" IMPLIEDDATAID = "+ImpliedDataID+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF

--	Select 	ProcedureName, ProcedureItemID, ImpliedDataID, ContextID, Type, Notes
	from	OPENXML (@idoc, '/QueryRules/AddImpliedDataToContext',2)
		WITH (
		      ImpliedDataID	nvarchar(10)	'ImpliedDataID/text()',
		      ContextID		nvarchar(10)	'ContextID/text()',
		      Type		nvarchar(50)	'Type/text()',
		      Notes		nvarchar(254)	'Notes/text()'
		     )

	set @nErrorCode = @@ERROR
end

--	QueryImpliedItem header for either data item or context level data

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateImpliedData/ImpliedItem[descendant::text()]|/QueryRules/AddImpliedDataToContext/ImpliedItem[descendant::text()]',2))
Begin
	select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Query Implied Item						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF
End

--	QueryImpliedItem

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateImpliedData/ImpliedItem[descendant::text()]',2))
Begin

	select
"	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = "+ImpliedDataID+" AND SEQUENCENO = "+isnull(SequenceNo,1)+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = "+ImpliedDataID+" AND SEQUENCENO = "+isnull(SequenceNo,1)+"'"+@CRLF+
"		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)"+@CRLF+
"		 VALUES ("+ImpliedDataID+", "+
			isnull(SequenceNo,1)+", "+
			dbo.fn_WrapQuotes(ProcedureItemID,0,0)+", "+
			isnull(UsesQualifier,0)+", "+
			case when Usage is null then 'NULL' else dbo.fn_WrapQuotes(Usage,0,0) end+", "+
			dbo.fn_WrapQuotes(isnull(ProcedureName, @sStoredProcedure),0,0)+")"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYIMPLIEDITEM table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" QUERYIMPLIEDITEM IMPLIEDDATAID = "+ImpliedDataID+" AND SEQUENCENO = "+isnull(SequenceNo,1)+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF
--	Select 	ImpliedDataID, SequenceNo, ProcedureName, ProcedureItemID, UsesQualifier, Usage
	from	OPENXML (@idoc, '/QueryRules/DataItemColumn/CreateImpliedData/ImpliedItem',2)
		WITH (
		      ImpliedDataID	nvarchar(10)	'../ImpliedDataID/text()',
		      SequenceNo	nvarchar(10)	'SequenceNo/text()',
		      ProcedureName	nvarchar(50)	'ProcedureName/text()',
		      ProcedureItemID	nvarchar(50)	'ProcedureItemID/text()',
		      UsesQualifier	nvarchar(1)	'UsesQualifier/text()',
		      Usage		nvarchar(50)	'Usage/text()'
		     )

	set @nErrorCode = @@ERROR
end

--	QueryImpliedItem at Context level

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/QueryRules/AddImpliedDataToContext/ImpliedItem[descendant::text()]',2))
Begin

	select
"	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = "+ImpliedDataID+" AND SEQUENCENO = "+isnull(SequenceNo,1)+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = "+ImpliedDataID+" AND SEQUENCENO = "+isnull(SequenceNo,1)+"'"+@CRLF+
"		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)"+@CRLF+
"		 VALUES ("+ImpliedDataID+", "+
			isnull(SequenceNo,1)+", "+
			dbo.fn_WrapQuotes(ProcedureItemID,0,0)+", "+
			isnull(UsesQualifier,0)+", "+
			case when Usage is null then 'NULL' else dbo.fn_WrapQuotes(Usage,0,0) end+", "+
			dbo.fn_WrapQuotes(isnull(ProcedureName, @sStoredProcedure),0,0)+")"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to QUERYIMPLIEDITEM table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" QUERYIMPLIEDITEM IMPLIEDDATAID = "+ImpliedDataID+" AND SEQUENCENO = "+isnull(SequenceNo,1)+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF
--	Select 	ImpliedDataID, SequenceNo, ProcedureName, ProcedureItemID, UsesQualifier, Usage
	from	OPENXML (@idoc, '/QueryRules/AddImpliedDataToContext/ImpliedItem',2)
		WITH (
		      ImpliedDataID	nvarchar(10)	'../ImpliedDataID/text()',
		      SequenceNo	nvarchar(10)	'SequenceNo/text()',
		      ProcedureName	nvarchar(50)	'ProcedureName/text()',
		      ProcedureItemID	nvarchar(50)	'ProcedureItemID/text()',
		      UsesQualifier	nvarchar(1)	'UsesQualifier/text()',
		      Usage		nvarchar(50)	'Usage/text()'
		     )

	set @nErrorCode = @@ERROR
end

Return @nErrorCode
GO

Grant execute on dbo.ip_GenerateQueryRules to public
GO
