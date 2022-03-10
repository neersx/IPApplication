-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListSearchPresentationColumns
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListSearchPresentationColumns]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListSearchPresentationColumns.'
	Drop procedure [dbo].[ipw_ListSearchPresentationColumns]
End
Print '**** Creating Stored Procedure dbo.ipw_ListSearchPresentationColumns...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListSearchPresentationColumns
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbIsBillCaseColumn     bit             = null,
	@pnQueryContext		int
	
)
as
-- PROCEDURE:	ipw_ListSearchPresentationColumns
-- VERSION:	4
-- DESCRIPTION:	Return available bill map profiles.

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Oct 2010	DV		RFC9437		1	Procedure created.
-- 28 mar 2011  DV           	RFC10041        2       Pass extra parameter @pbIsBillCaseColumn and modify the output to display Bill Case columns
-- 04 May 2012	DV		RFC11793	3	Return IsUsedBySystem to indicate if the column is a part of query presentation
-- 18 Feb 2013	vql		RFC11971	4	Not all columns available in Display/Sort columns are maintainable in Maintain Columns

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int
Declare @sSQLString				nvarchar(4000)
Declare @sLookupCulture				nvarchar(10)
Create table #SEARCHCOLUMNS (
	ColumnID int,
	DisplayName nvarchar(1000),
	ColumnNameKey int,
	ColumnNameDescription nvarchar(100),
	Parameter nvarchar(40),
	DocItemID int,
	IsUsedBySystem bit,
	ItemName nvarchar(40),
	Description nvarchar(1000),
	IsMandatory bit,
	IsVisible bit,
	DataFormat nvarchar(1000),
	ColumnGroupKey int,
	ColumnGroupDescription nvarchar(1000),
	LogDateTimeStamp datetime);

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @nErrorCode = 0

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "
		INSERT INTO #SEARCHCOLUMNS (ColumnID,DisplayName,ColumnNameKey,ColumnNameDescription,Parameter,DocItemID,IsUsedBySystem,ItemName,
		Description,IsMandatory,IsVisible,DataFormat,ColumnGroupKey,ColumnGroupDescription,LogDateTimeStamp)
		SELECT 	QC.COLUMNID as 'ColumnID',"+char(10)+
		dbo.fn_SqlTranslatedColumn('QUERYCOLUMN','COLUMNLABEL',null,'QC',@sLookupCulture,@pbCalledFromCentura)+char(10)+" as DisplayName,
		QD.DATAITEMID as ColumnNameKey,
		QD.PROCEDUREITEMID as ColumnNameDescription,
		QC.QUALIFIER as Parameter,
		QC.DOCITEMID as DocItemID,
		CASE WHEN QCC.COLUMNID is null THEN 0 ELSE 1 END as IsUsedBySystem,
		I.ITEM_NAME as ItemName,"+char(10)+  	
		dbo.fn_SqlTranslatedColumn('QUERYCOLUMN','DESCRIPTION',null,'QC',@sLookupCulture,@pbCalledFromCentura)+char(10)+" as Description,
		isnull(QCC.ISMANDATORY,0) as IsMandatory,   
		CASE WHEN QCC.CONTEXTID is null THEN 0 ELSE 1 END as IsVisible, "+char(10)+
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+char(10)+" as DataFormat,
		QCG.GROUPID as ColumnGroupKey,"+char(10)+  	
		dbo.fn_SqlTranslatedColumn('QUERYCOLUMNGROUP','GROUPNAME',null,'QCG',@sLookupCulture,@pbCalledFromCentura)+char(10)+" as ColumnGroupDescription,		
		QC.LOGDATETIMESTAMP as LogDateTimeStamp
		FROM QUERYCOLUMN  QC 
		join QUERYDATAITEM QD on (QD.DATAITEMID = QC.DATAITEMID)
		join QUERYCONTEXTCOLUMN QCC on (QCC.COLUMNID = QC.COLUMNID)
		left join QUERYCOLUMNGROUP QCG on (QCG.GROUPID = QCC.GROUPID and QCG.CONTEXTID = QCC.CONTEXTID)
		join TABLECODES TC on (QD.DATAFORMATID = TC.TABLECODE)   
		left join ITEM I on (QC.DOCITEMID = I.ITEM_ID)
		WHERE QCC.CONTEXTID = @pnQueryContext"
	If (@pbIsBillCaseColumn = 1)
	Begin
	        Set @sSQLString = @sSQLString + " and QD.PROCEDUREITEMID = 'UserColumnString' and QD.PROCEDURENAME = 'xml_GetDebitNoteMappedCodes'"
	End
		
	Set @sSQLString = @sSQLString + " ORDER BY QC.COLUMNLABEL, QC.QUALIFIER"

	exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnQueryContext	int',		
						@pnQueryContext	= @pnQueryContext
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "SELECT * FROM #SEARCHCOLUMNS"
	
	exec @nErrorCode = sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	-- find places where the column is used in multiple context
	Set @sSQLString = 
			"select QC.COLUMNID as ColumnID,
				Q.CONTEXTNAME as ContextName, 
				QD.PROCEDURENAME as ProcedureName,"+char(10)+
				dbo.fn_SqlTranslatedColumn('QUERYCOLUMN','COLUMNLABEL',null,'QC',@sLookupCulture,@pbCalledFromCentura)+char(10)+" as DisplayName
			from QUERYCONTEXTCOLUMN QCC
			join #SEARCHCOLUMNS SC on (SC.ColumnID = QCC.COLUMNID)
			join QUERYCOLUMN QC on (QC.COLUMNID = QCC.COLUMNID)
			join QUERYCONTEXT Q on (Q.CONTEXTID = QCC.CONTEXTID)
			join QUERYDATAITEM QD on (QD.DATAITEMID = QC.DATAITEMID)
			order by Q.CONTEXTNAME asc"

	exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListSearchPresentationColumns to public
GO
