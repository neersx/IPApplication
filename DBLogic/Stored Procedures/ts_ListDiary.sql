-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_ListDiary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_ListDiary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_ListDiary.'
	Drop procedure [dbo].[ts_ListDiary]
End
Print '**** Creating Stored Procedure dbo.ts_ListDiary...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ts_ListDiary
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 240, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0,
	@pbPrintSQL			bit		= 0
)
as
-- PROCEDURE:	ts_ListDiary
-- VERSION:	15
-- DESCRIPTION:	Returns the requested Diary information that matches the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Jun 2005	TM	RFC2575	1	Procedure created
-- 20 Jun 2005	TM	RFC2575	2	Return the StartTime column as null if it contains 12:00AM.
-- 23 Jun 2005	TM	RFC2575	3	Correct ResponsibleName column logic.
-- 23 Jun 2005	TM	RFC2556	4	Restructure code and implement new EntryDateGroup filter criteria.
--					Ensure that filtering can handle a ts_ListDiary node wherever it occurs.
-- 29 Jun 2005	TM	RFC1100	5	When converting datetime values to minutes set the minutes value to null if 
--					the datetime value is null instead of setting it to 0.
-- 21 Oct 2005	TM	RFC3024	6	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 20 Jun 2006	TM	RFC3998	7	Implement IsPosted.
-- 15 Dec 2008	MF	17136	8	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 30 Nov 2009  NG	RFC8582 9	Implement logic to get the continuable task only.
-- 15 Feb 2010	LP	RFC3130	10	Implement new columns required for Time Summary.
-- 25 May 2011	SF	RFC10693 	12	Implement CaseShortTitle column
-- 07 Jul 2011	DL	RFC10830 	13	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 13 Sep 2011	ASH	R11175 14	Maintain Narrative Text in foreign languages.
-- 02 Nov 2015	vql	R53910	15	Adjust formatted names logic (DR-15543).

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added

--	ActivityDescription
--	ActivityKey
--	Activity
--	AccumulatedMinutes
--	CanCopy
--	CaseKey
--	CaseReference
--	IRN
--	CaseShortTitle
--	Discount
--	EntryNo
--	EntryDate
--	ForeignCurrencyCode
--	ForeignValue
-- 	IsPosted (RFC3998)
--	LocalCurrencyCode
--	LocalValue
--	NameKey
--	Name
--	NameCode
--	NarrativeKey
--	NarrativeCode
--	NarrativeTitle
--	NarrativeText
--	Notes
--	NULL
--	ProductKey
--	Product
--	ProductCode
--	ResponsibleNameKey
--	ResponsibleName
--	ResponsibleNameCode
--	StaffKey
--	StaffName
--	StaffCode
--	StartTime
--	StartDateTime
--	TotalUnits

--	

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables

--	C
--	CN
--	CSC
--	CSC1
--	D
--	N
--	N2
--	N3
--	NR
--	SCP
--	SLC - HOMECURRENCY Site Control
--	TC

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int

Declare @sSQLString				nvarchar(4000)
Declare	@sSql					nvarchar(4000)

Declare @sLookupCulture				nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
Declare @tblOutputRequests table 
			 (	ROWNUMBER	int 		not null,
		    		ID		nvarchar(100)	collate database_default not null,
		    		SORTORDER	tinyint		null,
		    		SORTDIRECTION	nvarchar(1)	collate database_default null,
				PUBLISHNAME	nvarchar(100)	collate database_default null,
				QUALIFIER	nvarchar(100)	collate database_default null,				
				DOCITEMKEY	int		null
			  )

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
Declare @tbOrderBy table (
				Position	tinyint		not null,
				Direction	nvarchar(5)	collate database_default not null,
				ColumnName	nvarchar(1000)	collate database_default not null,
				PublishName	nvarchar(50)	collate database_default null,
				ColumnNumber	tinyint		not null
			)

Declare @nOutRequestsRowCount			int
Declare @nColumnNo				tinyint
Declare @sColumn				nvarchar(100)
Declare @sPublishName				nvarchar(50)
Declare @sQualifier				nvarchar(50)
Declare @nOrderPosition				tinyint
Declare @sOrderDirection			nvarchar(5)
Declare @sTableColumn				nvarchar(1000)
Declare @sComma					nchar(2)	-- initialised when a column has been added to the Select.

Declare @sDiaryWhere				nvarchar(4000)
Declare @sCurrentDiaryTable			nvarchar(60)
Declare	@bExternalUser				bit

Declare @nCount					int		-- Current table row being processed.
Declare @sSelect				nvarchar(4000)
Declare @sFrom					nvarchar(4000)
Declare @sWhere					nvarchar(4000)
Declare @sOrder					nvarchar(4000)

Declare @idoc 					int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
Declare @bGetContinuableTaskOnly	bit
		
-- Declare some constants
Declare @String					nchar(1)
Declare @Date					nchar(2)
Declare @Numeric				nchar(1)
Declare @Text					nchar(1)
Declare @CommaString				nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.
Declare @sOr					nchar(4)

Set	@String 				='S'
Set	@Date   				='DT'
Set	@Numeric				='N'
Set	@Text   				='T'
Set	@CommaString				='CS'

-- Initialise variables
Set		@nErrorCode = 0
Set     @nCount					= 1
set 	@sSelect				='SET ANSI_NULLS OFF' + char(10)+ 'Select '
set 	@sFrom					= char(10)+"From DIARY D"
set 	@sWhere 				= char(10)+"	WHERE 1=1"

-- Determine if only continuable time entry is to be returned
If datalength(@ptXMLFilterCriteria) > 0
and @nErrorCode = 0
Begin
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	
	Set @sSql="
	Select @bGetContinuableTaskOnly = GetContinuableTaskOnly
	from OPENXML(@idoc, '//ts_ListDiary/FilterCriteria',2)
	WITH ( GetContinuableTaskOnly	bit		'GetContinuableTaskOnly/text()')"

	exec @nErrorCode=sp_executesql @sSql,
				N'@bGetContinuableTaskOnly	bit		Output,
				  @idoc						int',
				  @bGetContinuableTaskOnly	= @bGetContinuableTaskOnly	Output,
				  @idoc		= @idoc
	
	exec sp_xml_removedocument @idoc
	Set @nErrorCode = @@Error
End

-- To get the latest continuable time entry
If @nErrorCode=0
and @bGetContinuableTaskOnly is not null
and @bGetContinuableTaskOnly = 1
Begin
	Set @sSelect = @sSelect + ' top 1 '
End

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString='
	Select	@bExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @bExternalUser=@bExternalUser	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId
End

--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
If datalength(@ptXMLOutputRequests) > 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End
-- If the @ptXMLOutputRequests was not supplied, the @pnQueryContextKey is used to obtain the default presentation from the database
Else
Begin
	-- Default @pnQueryContextKey to 240.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 240)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End

-- Loop through each column in order to construct the components of the SELECT
While @nCount < @nOutRequestsRowCount + 1
and   @nErrorCode=0
Begin
	-- Get the ColumnID, Name of the column to be published (@sPublishName), the position of the Column 
	-- in the Order By clause (@nOrderPosition), the direction of the sort (@sOrderDirection),
	-- Qualifier to be used to get the column (@sQualifier)   
	Select	@nColumnNo 		= ROWNUMBER,
		@sColumn   		= ID,
		@sPublishName 		= PUBLISHNAME,
		@nOrderPosition		= SORTORDER,
		@sOrderDirection	= CASE WHEN SORTORDER > 0 THEN SORTDIRECTION
					       ELSE NULL
					  END,
		@sQualifier		= QUALIFIER
	from	@tblOutputRequests
	where	ROWNUMBER = @nCount

	Set @nErrorCode = @@ERROR

	If @nErrorCode=0
	Begin
		If @sColumn='NULL'
		Begin
			Set @sTableColumn='NULL'
		End
		Else
		If @sColumn='CanCopy'
		Begin
			Set @sTableColumn='cast(1 as bit)'
		End
		Else
		If @sColumn='StaffKey'
		Begin
			Set @sTableColumn='D.EMPLOYEENO'
		End
		Else 
		If @sColumn='StaffName'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)'

			If charindex('left join NAME N',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join NAME N	on (N.NAMENO = D.EMPLOYEENO)' 
			End
		End
		Else 
		If @sColumn = 'StaffCode'
		Begin
			Set @sTableColumn='N.NAMECODE'

			If charindex('left join NAME N',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join NAME N	on (N.NAMENO = D.EMPLOYEENO)' 
			End
		End
		Else 
		If @sColumn = 'EntryNo'
		Begin
			Set @sTableColumn='D.ENTRYNO'
		End
		Else 
		If @sColumn = 'EntryDate'
		Begin
			Set @sTableColumn='convert(datetime, convert(char(10),convert(datetime,D.STARTTIME,120),120), 120)'
		End
		Else 
		If @sColumn = 'StartTime'
		Begin
			Set @sTableColumn='CASE WHEN DATEPART(hh, convert(datetime, D.STARTTIME, 120))=0 and DATEPART(mi, D.STARTTIME )=0 THEN NULL ELSE convert(datetime,convert(varchar(23), D.STARTTIME,108), 108) END'
		End
		Else
		If @sColumn = 'StartDateTime'
		Begin
			Set @sTableColumn='D.STARTTIME'
		End
		Else
		If @sColumn = 'NameKey'
		Begin
			Set @sTableColumn='D.NAMENO'
		End
		Else 
		If @sColumn='Name'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N2.NAMENO, null)'

			If charindex('left join NAME N2',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join NAME N2	on (N2.NAMENO = D.NAMENO)' 
			End
		End
		Else
		If @sColumn='NameCode'
		Begin
			Set @sTableColumn='N2.NAMECODE'

			If charindex('left join NAME N2',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join NAME N2	on (N2.NAMENO = D.NAMENO)' 
			End
		End
		Else
		If @sColumn in ('ResponsibleNameKey',
				'ResponsibleName',
				'ResponsibleNameCode')
		Begin
			If charindex('left join CASES C',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join CASES C		on (C.CASEID = D.CASEID)' 
			End

			If charindex('left join NAME N3',@sFrom)=0
			Begin
				Set @sFrom = 	  CHAR(10) + @sFrom 
						+ CHAR(10) + "left join CASENAME CN	on (CN.CASEID = C.CASEID"
						+ CHAR(10) + "				and CN.NAMETYPE = 'I'"
						+ CHAR(10) + "				and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"							
							-- For time recorded against a case, the name of the instructor for the case (CaseKey) 
							-- is shown. Information is obtained from CaseName and Name.
							-- For time recorded directory against a name (instead of a case), the NameKey is obtained 
							-- from Diary.NameNo and the associated information from Name.
							-- Note: Look at the Diary.CaseId first even if the Diary.Name exists as well as the Diary.CaseId
						+ CHAR(10) + "	left join NAME N3 	on (N3.NAMENO = ISNULL(CN.NAMENO, D.NAMENO))" 
			End			

			If @sColumn='ResponsibleNameKey'
			Begin
				Set @sTableColumn='N3.NAMENO'
			End
			Else
			If @sColumn='ResponsibleNameCode'
			Begin
				Set @sTableColumn='N3.NAMECODE'
			End
			Else
			If @sColumn='ResponsibleName'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N3.NAMENO, null)'
			End
		End
		Else
		If @sColumn='CaseKey'
		Begin
			Set @sTableColumn='C.CASEID'

			If charindex('left join CASES C',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join CASES C		on (C.CASEID = D.CASEID)' 
			End
		End		
		Else
		If @sColumn in ('CaseReference', 'IRN')
		Begin
			Set @sTableColumn='C.IRN'

			If charindex('left join CASES C',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join CASES C		on (C.CASEID = D.CASEID)' 
			End
		End	
		Else
		If @sColumn='CaseShortTitle'
		Begin
			Set @sTableColumn='C.TITLE'

			If charindex('left join CASES C',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join CASES C		on (C.CASEID = D.CASEID)' 
			End
		End	
		Else
		If @sColumn='ActivityKey'
		Begin
			Set @sTableColumn='D.ACTIVITY'			
		End	
		Else
		If @sColumn in ('Activity', 'ActivityDescription')
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'W',@sLookupCulture,@pbCalledFromCentura)

			If charindex('left join WIPTEMPLATE W',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join WIPTEMPLATE W 	on (W.WIPCODE = D.ACTIVITY)' 
			End
		End	
		Else
		If @sColumn in ('ProductKey',
				'Product',	
				'ProductCode')
		Begin
			If charindex('left join TABLECODES TC',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom 
					   + CHAR(10) + "left join TABLECODES TC	on (TC.TABLECODE = D.PRODUCTCODE)"
					   + CHAR(10) + "left join SITECONTROL SCP	on (SCP.CONTROLID = 'Product Recorded on WIP')" 
			End

			If @sColumn='ProductKey'
			Begin
				Set @sTableColumn='CASE	WHEN SCP.COLBOOLEAN = 1 THEN D.PRODUCTCODE ELSE NULL END'
			End
			Else
			If @sColumn='Product'
			Begin
				Set @sTableColumn="CASE	WHEN SCP.COLBOOLEAN = 1 THEN "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+" ELSE NULL END"
			End
			Else
			If @sColumn='ProductCode'
			Begin
				Set @sTableColumn='CASE	WHEN SCP.COLBOOLEAN = 1 THEN TC.USERCODE ELSE NULL END'
			End
		End		
		Else
		If @sColumn='NarrativeKey'
		Begin
			Set @sTableColumn='D.NARRATIVENO'			
		End	
		Else
		If @sColumn='NarrativeText'
		Begin
			Set @sTableColumn='isnull('+
						dbo.fn_SqlTranslatedColumn('DIARY','LONGNARRATIVE',null,'D',@sLookupCulture,@pbCalledFromCentura)+', '+
						dbo.fn_SqlTranslatedColumn('DIARY','SHORTNARRATIVE',null,'D',@sLookupCulture,@pbCalledFromCentura)+
						')'
					
		End		
		Else
		If @sColumn in ('NarrativeCode',
				'NarrativeTitle')
		Begin
			If charindex('left join NARRATIVE NR',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom 
					   + CHAR(10) + "left join NARRATIVE NR		on (NR.NARRATIVENO = D.NARRATIVENO)"					
			End

			If @sColumn='NarrativeCode'
			Begin
				Set @sTableColumn='NR.NARRATIVECODE'
			End
			Else
			If @sColumn='NarrativeTitle'
			Begin
				Set @sTableColumn='NR.NARRATIVETITLE'
			End			
		End				
		Else
		If @sColumn='AccumulatedMinutes'
		Begin
			Set @sTableColumn='CASE WHEN (D.TOTALTIME is null and D.TIMECARRIEDFORWARD is null) 
						THEN NULL 
						ELSE (isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
					   		+
					   	      isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0))
					   END' 
		End	
		Else
		If @sColumn='Notes'
		Begin
			Set @sTableColumn='D.NOTES'			
		End	
		Else
		If @sColumn='IsPosted'
		Begin
			Set @sTableColumn='CASE WHEN (D.TRANSNO is not null) 
						THEN cast(1 as bit)
						ELSE cast(0 as bit)
					   END'
		End
		Else
		If @sColumn='TotalUnits'
		Begin
			Set @sTableColumn='D.TOTALUNITS'
		End
		Else
		If @sColumn='LocalValue'
		Begin
			Set @sTableColumn='D.TIMEVALUE'
		End
		Else
		If @sColumn='LocalCurrencyCode'
		Begin
			If charindex('left join SITECONTROL SLC',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom 
					   + CHAR(10) + "left join SITECONTROL SLC		on (SLC.CONTROLID = 'CURRENCY')"					
			End
			Set @sTableColumn='SLC.COLCHARACTER'
		End
		Else
		If @sColumn='ForeignValue'
		Begin
			Set @sTableColumn='D.FOREIGNVALUE'
		End
		Else
		If @sColumn='ForeignCurrencyCode'
		Begin
			Set @sTableColumn='D.FOREIGNCURRENCY'
		End
		Else
		If @sColumn='Discount'
		Begin
			Set @sTableColumn='D.DISCOUNTVALUE'
		End
						
		-- If the column is being published then concatenate it to the Select list

		If datalength(@sPublishName)>0
		Begin
			Set @sSelect=@sSelect+@sComma+@sTableColumn+' as ['+@sPublishName+']'
			Set @sComma=', '
		End
		Else Begin
			Set @sPublishName=NULL
		End

		-- If the column is to be sorted on then save the name of the table column along
		-- with the sort details so that later the Order By can be constructed in the correct sequence

		If @nOrderPosition>0
		Begin
			Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
			values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, @sOrderDirection)

			Set @nErrorCode = @@ERROR
		End
	End

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
	
End

-- Now construct the Order By clause

-- To get the latest continuable time entry
If @nErrorCode=0 
and @bGetContinuableTaskOnly is not null
and @bGetContinuableTaskOnly = 1
Begin
	Set @sOrder = ' Order by D.STARTTIME DESC '
End
Else
Begin		
	-- Assemble the "Order By" clause.

	-- If there is more than one row in the @tbOrderBy then the data from the next row gets concatenated 
	-- to the previous row.
	Select @sOrder= ISNULL(NULLIF(@sOrder+',', ','),'')			
			 +CASE WHEN(PublishName is null) 
			       THEN ColumnName
			       ELSE '['+PublishName+']'
			  END
			+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
			from @tbOrderBy
			order by Position			

	If @sOrder is not null
	Begin
		Set @sOrder = ' Order by ' + @sOrder
	End

	Set @nErrorCode=@@Error
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE  clause  ****/
/****                                       ****/
/***********************************************/

If   @nErrorCode=0
and (datalength(@ptXMLFilterCriteria) <> 0
or   datalength(@ptXMLFilterCriteria) is not null)
Begin
	exec @nErrorCode=dbo.ts_FilterDiary
				@psReturnClause		= @sDiaryWhere	  	OUTPUT, 
				@psCurrentDiaryTable	= @sCurrentDiaryTable	OUTPUT,
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,		
				@pbIsExternalUser	= @bExternalUser,	
				@ptXMLFilterCriteria	= @ptXMLFilterCriteria,	
				@pbCalledFromCentura	= @pbCalledFromCentura	
End

If @nErrorCode=0
Begin 	
	Set @sDiaryWhere		= + char(10) 	+ 'WHERE exists (Select 1' 
				 	  + char(10) 	+ @sDiaryWhere
				  	  + char(10)	+ 'and XD.EMPLOYEENO=D.EMPLOYEENO'
				  	  + char(10) 	+ 'and XD.ENTRYNO=D.ENTRYNO)'
				  	  
	If @pbPrintSQL = 1
	Begin
		Print @sSelect + @sFrom + @sDiaryWhere + @sOrder
	End

	-- Now execute the constructed SQL to return the result set
	Exec (@sSelect + @sFrom + @sDiaryWhere + @sOrder)
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End

-- Now drop the temporary table holding the Entries results:
If exists(select * from tempdb.dbo.sysobjects where name = @sCurrentDiaryTable)
and @nErrorCode=0
Begin
	Set @sSql = "drop table "+@sCurrentDiaryTable
		
	exec @nErrorCode=sp_executesql @sSql
End

Return @nErrorCode
GO

Grant execute on dbo.ts_ListDiary to public
GO
