-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_ListWipTemplate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_ListWipTemplate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_ListWipTemplate.'
	Drop procedure [dbo].[wp_ListWipTemplate]
End
Print '**** Creating Stored Procedure dbo.wp_ListWipTemplate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.wp_ListWipTemplate
(
	@pnRowCount			int		= null output,	
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 230, -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null	-- The filtering to be performed on the result set.			
)
as
-- PROCEDURE:	wp_ListWipTemplate
-- VERSION:		26
-- DESCRIPTION:	Returns the requested WIP Template information, for activities or expenses that match the filter criteria provided.

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	-----------	-------	----------------------------------------------- 
-- 14 Jun 2005	TM		RFC2575		1		Procedure created
-- 16 Jun 2005	TM		RFC2575		2		Set the best fit score to null if CaseKey has not been supplied.
-- 30 Jun 2005	TM		RFC2766		3		Choose action in a similar manner to client/server.
-- 01 Jul 2005	TM		RFC2778		4		Correct the best fit logic.
-- 01 Jul 2005	TM		RFC2778		5		Add POLICEEVENTS=1 to the Action selection.
-- 04 Jul 2005	TM		RFC2777		6		Extract the highest best fit score for the narrative similar to the 
--											extraction of the default WIP template. 
-- 05 Jul 2005 	TM		RFC2777		7		Correct the Narrative defaulting logic.
-- 21 Oct 2005	TM		RFC3024		8		Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 06 Jul 2006	SW		RFC4024		9		Remove BestFit filtering as it is now done by wp_ConstructWipTemplateWhere
-- 15 Dec 2008	MF		17136		10		Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 18 Mar 2008	MS		RFC6478		11		Add WIPCategory Column in the output and remove the check 
--											for the	 Staff Key and Case key for Narratives.
-- 11 Mar 2010	MS		RFC7279		12		Add Debtor in the best fit logic for selecting Narrative Rule.
-- 24 Mar 2010	MS		RFC8302		13		Add BillInAdvance column in the select list.
-- 26 Apr 2010	AT		RFC8292		14		Add WipTypeKey and WipCategorySort data items.
-- 28 Jul 2010	MS		R100332		15		Add RenewalFlag data item.
-- 21 Sep 2010  MS		R5885 		16		Swap DebtorKey with NameKey in Best Fit rule for Narrative for debtor value
-- 09 Jun 2011	SF		R10543		17		Add CountryCode, LocalCountryFlag, ForeignCountryFlag in the Best Fit
-- 15 Jun 2011	SF		R10543 		18		Correction made for RFC10543
-- 27 Jun 2011	SF		R10543		19		Correction to RFC10543
-- 07 Jul 2011	DL		R10830		20		Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 08 Feb 2012	LP		R11855 		21		Add HasValidTaxCode and WIPTaxCode data items.
-- 31 Aug 2012  MS		R11911		22		Improve best fit logic for narrative by picking the narrative when there is only one best fit narrative rule
-- 21 Sep 2012	DL		R12763		23		Fix collation error by adding 'collate database_default' to character based columns in temp table definition.
-- 13 Nov 2012	MF		R12922		24		Repeated WIPTemplate rows are being returned since TAXRATESCOUNTRY table was introduced by RFC11855.
-- 17 Jul 2013	AT		SDR9995		25		Return translated NarrativeTitle if applicable.
-- 31 Oct 2018	DL	DR-45102		26		Replace control character (word hyphen) with normal sql editor hyphen


-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	WIPTemplateKey
--	Description
--	WIPType
--	BestFitScore
--	NarrativeKey
--	NarrativeCode
--	NarrativeTitle
--	NarrativeText
--	HasValidTaxCode
--	WIPTaxCode

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	N
--	NRL
--	NTR
--	WIP
--	T

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int

Declare @sSQLString		nvarchar(MAX)

Declare @sLookupCulture		nvarchar(10)

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

Create table #tempBestFitNarrative (
                                WIPCODE nvarchar(6) collate database_default, 
                                BestFit nvarchar(20) collate database_default, 
                                BestFitCount int
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

-- Information about the context in which the information is being used.
Declare @nStaffKey				int		-- The key of the staff member being recorded on the WIP.
Declare @nNameKey				int		-- The key of the name the WIP is being recorded against. Either NameKey or CaseKey should be provided - not both.
Declare @nCaseKey				int		-- The key of the case the WIP is being recorded against. Either NameKey or CaseKey should be provided - not both.
Declare @nLanguageKey				int		-- The language in which a bill is to be prepared.
Declare @bIsTranslateNarrative			bit		-- If the Narrative Translate site control is on, the text is obtained in the language in which the bill will be raised. 
Declare @nDebtorKey				int		-- The key of the name which is debtor of the case the WIP is being recorded against.

Declare @bHasCountryAttributes			bit		-- Indicate where country attributes exist
Declare @bTreatAsLocal				bit		-- Indicate LocalCountryFlag is considered
Declare @bTreatAsForeign			bit		-- Indicate ForeignCountryFlag is considered

Declare @nCount					int		-- Current table row being processed.
Declare @sSelect				nvarchar(4000)
Declare @sFrom					nvarchar(MAX)
Declare @sWhere					nvarchar(4000)
Declare @sWipTemplateWhere			nvarchar(4000)
Declare @sOrder					nvarchar(4000)

Declare @idoc 					int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String					nchar(1)
Declare @Date					nchar(2)
Declare @Numeric				nchar(1)
Declare @Text					nchar(1)
Declare @CommaString				nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.

Set	@String 				='S'
Set	@Date   				='DT'
Set	@Numeric				='N'
Set	@Text   				='T'
Set	@CommaString				='CS'

-- Initialise variables
Set 	@nErrorCode = 0
Set     @nCount					= 1
set 	@sSelect				='SET ANSI_NULLS OFF' + char(10)+ 'Select '
set 	@sFrom					= char(10)+"From WIPTEMPLATE WIP"
set 	@sLookupCulture 			= dbo.fn_GetLookupCulture(@psCulture, null, 0)
set	@nLanguageKey				= null

-- If filter criteria was passed, extract details from the XML
If PATINDEX ('%<ContextCriteria>%', @ptXMLFilterCriteria)>0
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the filter criteria using element-centric mapping (implement 
	--    Case Insensitive searching were required)   

	Set @sSQLString = 	
	"Select @nStaffKey		= StaffKey,"+CHAR(10)+
	"	@nNameKey		= NameKey,"+CHAR(10)+				
	"	@nCaseKey		= CaseKey"+CHAR(10)+
	"from	OPENXML (@idoc, '//wp_ListWipTemplate/ContextCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      StaffKey			int		'StaffKey/text()',"+CHAR(10)+
 	"	      NameKey			int		'NameKey/text()',"+CHAR(10)+	
	"	      CaseKey			int		'CaseKey/text()'"+CHAR(10)+	
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nStaffKey			int			output,
				  @nNameKey			int			output,
				  @nCaseKey			int			output',
				  @idoc				= @idoc,	
				  @nStaffKey			= @nStaffKey		output,
				  @nNameKey			= @nNameKey		output,
				  @nCaseKey			= @nCaseKey		output				  
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error
End	

-- Deriving DebtorKey. The main debtor for the CaseKey is used. This is the 
-- CaseName for the Name Type = 'D' with the minimum sequence number.
If @nErrorCode =0 and @nCaseKey is not null
Begin
	Set @sSQLString = 
	"Select @nDebtorKey = CN.NAMENO
	 from CASENAME CN
	 where CN.CASEID = @nCaseKey
	 and   CN.NAMETYPE = 'D'
	 and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
	 and   CN.SEQUENCE = (select min(SEQUENCE) from CASENAME CN
                              where CN.CASEID = @nCaseKey
                              and CN.NAMETYPE = 'D'
                              and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nDebtorKey			int			output,
				  @nCaseKey			int',
				  @idoc				= @idoc,	
				  @nDebtorKey			= @nDebtorKey		output,
				  @nCaseKey			= @nCaseKey
				 		
End

If @nErrorCode =0 and @nCaseKey is not null
Begin
	If Exists (Select * 
		from	TABLEATTRIBUTES TA	
		where	TA.PARENTTABLE = 'COUNTRY' 
		AND	TA.TABLECODE = 5002 
		AND	TA.TABLETYPE = 50)
	Begin
		Set @bHasCountryAttributes = 1
	End


	Set @sSQLString = 
	"Select @bTreatAsLocal =	CASE	WHEN @bHasCountryAttributes = 0 THEN NULL
						WHEN @bHasCountryAttributes = 1 and TA.GENERICKEY IS NOT NULL THEN 1 ELSE 0 END,
		@bTreatAsForeign =	CASE	WHEN @bHasCountryAttributes = 0 THEN NULL
						WHEN @bHasCountryAttributes = 1 and TA.GENERICKEY IS NULL THEN 1 ELSE 0 END
	from CASES C
 	left join TABLEATTRIBUTES TA	on (TA.PARENTTABLE = 'COUNTRY' 
					and TA.TABLECODE = 5002 
					and TA.TABLETYPE = 50
					and TA.GENERICKEY = C.COUNTRYCODE)
	 where C.CASEID = @nCaseKey"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@bTreatAsLocal		bit			output,
				  @bTreatAsForeign		bit			output,
				  @bHasCountryAttributes	bit,
				  @nCaseKey			int',
				  @bTreatAsLocal		= @bTreatAsLocal	output,	
				  @bTreatAsForeign		= @bTreatAsForeign	output,
				  @bHasCountryAttributes	= @bHasCountryAttributes,
				  @nCaseKey			= @nCaseKey
				 		
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
	exec @nErrorCode=dbo.wp_ConstructWipTemplateWhere
				@psWipTemplateWhere	= @sWipTemplateWhere	OUTPUT, 
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,		
				@ptXMLFilterCriteria	= @ptXMLFilterCriteria	
End

If @nErrorCode=0
Begin
	Set @sWhere = char(10)+"where exists(Select 1"
		     +char(10)+@sWipTemplateWhere
		     +char(10)+"and XWIP.WIPCODE = WIP.WIPCODE)"
End

--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
If datalength(@ptXMLOutputRequests) > 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,0,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End
-- If the @ptXMLOutputRequests was not supplied, the @pnQueryContextKey is used to obtain the default presentation from the database
Else
Begin
	-- Default @pnQueryContextKey to 230.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 230)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,0,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End

If @nErrorCode = 0
Begin
        -- Insert the BestFit value and BestFitCount of Narrative rules against the WIP Codes
        Set @sSQLString = "Insert into #tempBestFitNarrative(WIPCODE, BestFit, BestFitCount)
                        Select  NRL.WIPCODE	 as WipCode,"+char(10)+
			        "CASE WHEN (NRL.DEBTORNO IS NULL)	THEN '0' ELSE '1' END +"+char(10)+  
			        "CASE WHEN (NRL.EMPLOYEENO IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    
			        "CASE WHEN (NRL.CASETYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
			        "CASE WHEN (NRL.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
			        "CASE WHEN (NRL.LOCALCOUNTRYFLAG IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
			        "CASE WHEN (NRL.FOREIGNCOUNTRYFLAG IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
			        "CASE WHEN (NRL.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
			        "CASE WHEN (NRL.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
			        "CASE WHEN (NRL.SUBTYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
			        "CASE WHEN (NRL.TYPEOFMARK is NULL)	THEN '0' ELSE '1' END, "+char(10)+
			        "COUNT(*)"+char(10)+
			"from NARRATIVERULE NRL"+char(10)+
			"left join CASES C on " + char(10)+ 
			CASE WHEN @nCaseKey is null THEN "(C.CASEID is null)" ELSE "(C.CASEID = "+CAST(@nCaseKey as varchar(11))+")" END +char(10)+
			"where"+char(10)+ 	
			CASE WHEN @nNameKey is null and @nDebtorKey is null then " NRL.DEBTORNO IS NULL "
				ELSE " ( NRL.DEBTORNO = "+ISNULL(CAST(@nDebtorKey as varchar(11)), CAST(@nNameKey as varchar(11)))+ " OR NRL.DEBTORNO IS NULL )" END +char(10)+													
			CASE WHEN @nStaffKey is null then "AND NRL.EMPLOYEENO IS NULL"
				ELSE "AND ( NRL.EMPLOYEENO = "+CAST(@nStaffKey as varchar(11))+" OR NRL.EMPLOYEENO IS NULL )" END +char(10)+							
			"AND (	NRL.CASETYPE		= C.CASETYPE		OR NRL.CASETYPE		is NULL )"+char(10)+
			"AND (	NRL.COUNTRYCODE		= C.COUNTRYCODE		OR NRL.COUNTRYCODE	is NULL )"+char(10)+
		        CASE WHEN @bTreatAsLocal is not null THEN 
			"AND (	NRL.LOCALCOUNTRYFLAG	= " + CAST(@bTreatAsLocal AS varchar(1)) + "	OR NRL.LOCALCOUNTRYFLAG	is NULL )"+char(10)
			END +
			CASE WHEN @bTreatAsForeign is not null THEN 
			"AND (	NRL.FOREIGNCOUNTRYFLAG	= " + CAST(@bTreatAsForeign AS varchar(1)) + "	OR NRL.FOREIGNCOUNTRYFLAG is NULL )"+char(10)
			END +
			"AND (	NRL.PROPERTYTYPE 	= C.PROPERTYTYPE 	OR NRL.PROPERTYTYPE 	IS NULL )"+char(10)+
			"AND (	NRL.CASECATEGORY 	= C.CASECATEGORY 	OR NRL.CASECATEGORY 	IS NULL )"+char(10)+
			"AND (	NRL.SUBTYPE 		= C.SUBTYPE 		OR NRL.SUBTYPE	 	IS NULL )"+char(10)+
			"AND (	NRL.TYPEOFMARK		= C.TYPEOFMARK		OR NRL.TYPEOFMARK	IS NULL )"+char(10)+
			"and  exists(Select 1"+char(10)+
			@sWipTemplateWhere+char(10)+
			"and XWIP.WIPCODE = NRL.WIPCODE)"+char(10)+
			"group by NRL.WIPCODE,"+char(10)+
                                "CASE WHEN (NRL.DEBTORNO IS NULL)	THEN '0' ELSE '1' END +"+char(10)+  
			        "CASE WHEN (NRL.EMPLOYEENO IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    
			        "CASE WHEN (NRL.CASETYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
			        "CASE WHEN (NRL.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
			        "CASE WHEN (NRL.LOCALCOUNTRYFLAG IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
			        "CASE WHEN (NRL.FOREIGNCOUNTRYFLAG IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
			        "CASE WHEN (NRL.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
			        "CASE WHEN (NRL.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
			        "CASE WHEN (NRL.SUBTYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
			        "CASE WHEN (NRL.TYPEOFMARK is NULL)	THEN '0' ELSE '1' END "+char(10)+
			"order by 2 desc"
			
	        exec (@sSQLString)
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
		If @sColumn='WIPTemplateKey'
		Begin
			Set @sTableColumn='WIP.WIPCODE'
		End
		Else
		If @sColumn='Description'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WIP',@sLookupCulture,0) 
		End
		Else
		If @sColumn='WIPType'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('WIPTYPE','DESCRIPTION',null,'WT',@sLookupCulture,0) 
				
			If charindex('left join WIPTYPE WT',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join WIPTYPE WT		on (WT.WIPTYPEID = WIP.WIPTYPEID)'
			End		
		End
		Else
		If @sColumn='WIPCategory'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('WIPTYPE','CATEGORYCODE',null,'WT',@sLookupCulture,0) 
				
			If charindex('left join WIPTYPE WT',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join WIPTYPE WT		on (WT.WIPTYPEID = WIP.WIPTYPEID)'
			End		
		End
		Else
		If @sColumn = 'BestFitScore'
		Begin
			If @nCaseKey is null
			Begin
				Set @sTableColumn='NULL'
			End
			Else
			Begin
				Set @sTableColumn=           "CONVERT(int,"
						+ char(10) + "CASE WHEN (WIP.CASETYPE 	IS NULL)	THEN '0' ELSE '1' END +"  
						+ char(10) + "CASE WHEN (WIP.COUNTRYCODE 	IS NULL)	THEN '0' ELSE '1' END +"
						+ char(10) + "CASE WHEN (WIP.PROPERTYTYPE 	IS NULL)	THEN '0' ELSE '1' END +"    
						+ char(10) + "CASE WHEN (WIP.ACTION  		IS NULL)	THEN '0' ELSE '1' END)"							
			End
		End	
		Else
		If @sColumn in ('NarrativeKey',
				'NarrativeCode',	
				'NarrativeTitle',
				'NarrativeText') 				
		Begin
			If charindex('left join (    Select WIPCODE, BestFit, BestFitCount',@sFrom)=0
				Begin
					Set @sFrom = @sFrom + char(10) + 
					"left join (    Select WIPCODE, BestFit, BestFitCount"+char(10)+
                                                        "FROM (SELECT WIPCODE, BestFit, BestFitCount,"+char(10)+ 
                                                                "RANK() OVER (PARTITION BY WIPCODE ORDER BY BestFit DESC) N"+char(10)+
                                                                "FROM #tempBestFitNarrative"+char(10)+
                                                        ")M WHERE N = 1"+char(10)+
                                                    ") as BestFitNar on (BestFitNar.WIPCODE = WIP.WIPCODE)"+char(10)+
					"left join (	Select  NRL.WIPCODE	 as WipCode,"+char(10)+
								"convert(smallint,"+char(10)+
								"substring("+char(10)+
								"max ("+char(10)+
								"CASE WHEN (NRL.DEBTORNO IS NULL)	THEN '0' ELSE '1' END +"+char(10)+  
								"CASE WHEN (NRL.EMPLOYEENO IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    
								"CASE WHEN (NRL.CASETYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
								"CASE WHEN (NRL.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
								"CASE WHEN (NRL.LOCALCOUNTRYFLAG IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
								"CASE WHEN (NRL.FOREIGNCOUNTRYFLAG IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
								"CASE WHEN (NRL.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
								"CASE WHEN (NRL.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
								"CASE WHEN (NRL.SUBTYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
								"CASE WHEN (NRL.TYPEOFMARK is NULL)	THEN '0' ELSE '1' END +"+char(10)+
								"cast(NRL.NARRATIVENO as varchar(5)) ),11,5)) as NarrativeNo"+char(10)+
							"from NARRATIVERULE NRL"+char(10)+
							"left join CASES C on " + char(10)+ 
								CASE WHEN @nCaseKey is null THEN "(C.CASEID is null)" ELSE "(C.CASEID = "+CAST(@nCaseKey as varchar(11))+")" END +char(10)+
							"where"+char(10)+ 	
							CASE WHEN @nNameKey is null and @nDebtorKey is null then " NRL.DEBTORNO IS NULL "
								ELSE " ( NRL.DEBTORNO = "+ISNULL(CAST(@nDebtorKey as varchar(11)), CAST(@nNameKey as varchar(11)))+ " OR NRL.DEBTORNO IS NULL )" END +char(10)+													
							CASE WHEN @nStaffKey is null then "AND NRL.EMPLOYEENO IS NULL"
								ELSE "AND ( NRL.EMPLOYEENO = "+CAST(@nStaffKey as varchar(11))+" OR NRL.EMPLOYEENO IS NULL )" END +char(10)+							
							"AND (	NRL.CASETYPE		= C.CASETYPE		OR NRL.CASETYPE		is NULL )"+char(10)+
							"AND (	NRL.COUNTRYCODE		= C.COUNTRYCODE		OR NRL.COUNTRYCODE	is NULL )"+char(10)+
							CASE WHEN @bTreatAsLocal is not null THEN 
							"AND (	NRL.LOCALCOUNTRYFLAG	= " + CAST(@bTreatAsLocal AS varchar(1)) + "	OR NRL.LOCALCOUNTRYFLAG	is NULL )"+char(10)
							END +
							CASE WHEN @bTreatAsForeign is not null THEN 
							"AND (	NRL.FOREIGNCOUNTRYFLAG	= " + CAST(@bTreatAsForeign AS varchar(1)) + "	OR NRL.FOREIGNCOUNTRYFLAG is NULL )"+char(10)
							END +
							"AND (	NRL.PROPERTYTYPE 	= C.PROPERTYTYPE 	OR NRL.PROPERTYTYPE 	IS NULL )"+char(10)+
							"AND (	NRL.CASECATEGORY 	= C.CASECATEGORY 	OR NRL.CASECATEGORY 	IS NULL )"+char(10)+
							"AND (	NRL.SUBTYPE 		= C.SUBTYPE 		OR NRL.SUBTYPE	 	IS NULL )"+char(10)+
							"AND (	NRL.TYPEOFMARK		= C.TYPEOFMARK		OR NRL.TYPEOFMARK	IS NULL )"+char(10)+
							-- Improve performance by using the where clause in the derived table:
							"and  exists(Select 1"+char(10)+
						         @sWipTemplateWhere+char(10)+
						        "and XWIP.WIPCODE = NRL.WIPCODE)"+char(10)+
							"group by NRL.WIPCODE) BestNar	on (BestNar.WipCode = BestFitNar.WIPCODE and BestFitNar.BestFitCount = 1)"	
				End														
	
				If @sColumn='NarrativeKey'
				Begin
					Set @sTableColumn='BestNar.NarrativeNo'
				End
				Else 		
				If @sColumn='NarrativeCode'
				Begin
					Set @sTableColumn='N.NARRATIVECODE'
	
					If charindex('left join NARRATIVE N',@sFrom)=0
					Begin
						Set @sFrom = @sFrom + char(10) + 'left join NARRATIVE N		on (N.NARRATIVENO = BestNar.NarrativeNo)'
					End	
				End
				Else 
				If @sColumn = 'NarrativeTitle'
				Begin
					Set @sTableColumn = dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETITLE',NULL,'N',@sLookupCulture,NULL)
	
					If charindex('left join NARRATIVE N',@sFrom)=0
					Begin
						Set @sFrom = @sFrom + char(10) + 'left join NARRATIVE N		on (N.NARRATIVENO = BestNar.NarrativeNo)'
					End	
				End
				Else 
				If @sColumn = 'NarrativeText'
				Begin
					If charindex('left join NARRATIVE N',@sFrom)=0
					Begin
						Set @sFrom = @sFrom + char(10) + 'left join NARRATIVE N		on (N.NARRATIVENO = BestNar.NarrativeNo)'
					End	
					
					Set @sSQLString = "
					Select @bIsTranslateNarrative = COLBOOLEAN
					from SITECONTROL where CONTROLID = 'Narrative Translate'"
		
					exec @nErrorCode=sp_executesql @sSQLString,
						N'@bIsTranslateNarrative	bit			 OUTPUT',
						  @bIsTranslateNarrative	= @bIsTranslateNarrative OUTPUT
		
					If   @bIsTranslateNarrative = 1
					and (@nNameKey is not null
					 or  @nCaseKey is not null)
					Begin
						exec @nErrorCode=dbo.bi_GetBillingLanguage
							@pnLanguageKey		= @nLanguageKey output,	
							@pnUserIdentityId	= @pnUserIdentityId,
							@pnDebtorKey		= @nNameKey,	
							@pnCaseKey		= @nCaseKey, 
							@pbDeriveAction		= 1					
					End			
		
					If @nLanguageKey is null
					Begin
						Set @sTableColumn='N.NARRATIVETEXT'
					End
					Else Begin
		
						Set @sTableColumn='ISNULL(NTR.TRANSLATEDTEXT, N.NARRATIVETEXT)'
						
						If charindex('left join NARRATIVETRANSLATE NTR',@sFrom)=0
						Begin
							Set @sFrom = @sFrom + char(10) + 'left join NARRATIVETRANSLATE NTR	on (NTR.NARRATIVENO = N.NARRATIVENO' 
									    + char(10) + '					and NTR.LANGUAGE = ' + CAST(@nLanguageKey as varchar(10)) + ')'
						End				
					End
			End
			Else 		
			Begin
				Set @sTableColumn='NULL'
			End	
		End	
		ELSE
		If @sColumn='BillInAdvance'
		Begin
			Set @sTableColumn='Cast(WIP.ENTERCREDITWIP as bit)'
		End		
		Else
		If @sColumn='WIPTypeKey'
		Begin
			Set @sTableColumn='WIP.WIPTYPEID'
		End
		Else
		If @sColumn='WIPCategorySort'
		Begin
			Set @sTableColumn='WC.CATEGORYSORT'

			If charindex('left join WIPTYPE WT',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join WIPTYPE WT		on (WT.WIPTYPEID = WIP.WIPTYPEID)'
			End
			If charindex('left join WIPCATEGORY WC',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join WIPCATEGORY WC on (WC.CATEGORYCODE = WT.CATEGORYCODE)'
			End
		End
		If @sColumn='RenewalFlag'
		Begin
			Set @sTableColumn='WIP.RENEWALFLAG'
		End
		If @sColumn='HasValidTaxCode'
		Begin
			Set @sTableColumn = 'CASE WHEN T.TAXCODE IS NULL THEN Cast(0 as bit) ELSE Cast(1 as bit) END'
			If charindex('left join (select distinct TAXCODE from TAXRATESCOUNTRY) T',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + "left join (select distinct TAXCODE from TAXRATESCOUNTRY) T on (WIP.TAXCODE = T.TAXCODE)"	-- R12922 Note joining on COUNTRYCODE from WIPTEMPLATE is incorrect as the TAXRATESCOUNTRY row would be determined from the country of the CASES row or ZZZ
			End
		End
		If @sColumn='WIPTaxCode'
		Begin
			Set @sTableColumn = 'WIP.TAXCODE'			
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

If @nErrorCode=0
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

If @nErrorCode=0
Begin 	
	-- Now execute the constructed SQL to return the result set
	Exec (@sSelect + @sFrom + @sWhere + @sOrder)
	
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End

Return @nErrorCode
GO

Grant execute on dbo.wp_ListWipTemplate to public
GO
