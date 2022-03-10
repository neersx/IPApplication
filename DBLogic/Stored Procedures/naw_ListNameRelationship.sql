-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameRelationship
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].naw_ListNameRelationship') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure  dbo.naw_ListNameRelationship.'
	Drop procedure dbo.naw_ListNameRelationship
End
Print '**** Creating Stored Procedure dbo.naw_ListNameRelationship...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListNameRelationship
(
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= null, -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure.
	@pnPageStartRow			int		= null,	-- The row number of the first record requested. Null if no paging required.
	@pnPageEndRow			int		= null
)		
-- PROCEDURE :	naw_ListNameRelationship
-- VERSION :	7
-- DESCRIPTION:	Searches and return names and their relationships.
-- CALLED BY :	

-- MODIFICTIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 20 Feb 2009	LP	RFC5766	1	Procedure created.
-- 08 Apr 2009  LP	RFC5766 2	Fix ResponsibleFor, Relationship and Address filter logic.
-- 09 Apr 2009  LP	RFC5766 3	Fix Staff logic.
-- 15 Apr 2009  LP	RFC5766 4	Remove NameTypeClassification conditions from Staff logic.
-- 19 Apr 2011  DV	R100513 5	Add condition to restrict the Relationship which have ceased.
-- 11 Apr 2013	DV	R13270	6	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	7	Adjust formatted names logic (DR-15543).

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
Declare @tblOutputRequests table 
			 (	ROWNUMBER	int 		not null,
		    		ID		nvarchar(100)	collate database_default	not null,
		    		SORTORDER	tinyint		null,
		    		SORTDIRECTION	nvarchar(1)     collate database_default	null,
				PUBLISHNAME	nvarchar(100)   collate database_default	null,
				QUALIFIER	nvarchar(100)   collate database_default	null,				
				DOCITEMKEY	int		null
			  )

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
Declare @tbOrderBy table (
				Position	tinyint		not null,
				Direction	nvarchar(5)     collate database_default	not null,
				ColumnName	nvarchar(1000)  collate database_default	not null,
				PublishName	nvarchar(50)    collate database_default	null,
				ColumnNumber	tinyint		not null
			)

Declare @nOutRequestsRowCount		int
Declare @nColumnNo			tinyint
Declare @sColumn			nvarchar(100)
Declare @sPublishName			nvarchar(50)
Declare @sQualifier			nvarchar(50)
Declare @nOrderPosition			tinyint
Declare @sOrderDirection		nvarchar(5)
Declare @sTableColumn			nvarchar(1000)
Declare @sComma				nchar(2)	-- initialised when a column has been added to the Select.

Declare @idoc 				int 	-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
declare @nStartNameFilter 		int	-- the starting position of the name filter
declare @nEndNameFilter 		int	-- the ending position of the name filter

Declare @sSQLString			nvarchar(4000)
Declare @sLookupCulture			nvarchar(10)
Declare @nTopRowCount			int		-- Return this many rows from the top of the search results.
Declare @nCount				int		-- Current table row being processed.
Declare @sSelect			nvarchar(4000)
Declare @sFrom				nvarchar(4000)
Declare @sWhere				nvarchar(4000)
Declare @sOrder				nvarchar(4000)
Declare @sWhereFrom			nvarchar(4000)

Declare @bPrintSQL			bit -- for debugging sql (set below)

Declare @bIsExternalUser			bit
		
-- Declare some constants
Declare @String				nchar(1)
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Text				nchar(1)
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.

-- Filter Criteria
Declare @nStaffNameKey                  int
Declare @nStaffNameOperator             tinyint
Declare @sRelationshipKey               nvarchar(6)
Declare @nRelationshipOperator          tinyint
Declare @nNameRespKey                   int
Declare @nNameRespOperator              tinyint
Declare @sCity                          nvarchar(60)
Declare @nCityOperator                  tinyint
Declare @sState                         nvarchar(40)
Declare @nStateOperator                 tinyint
Declare @sCountryCode                   nvarchar(6)
Declare @nCountryCodeOperator               tinyint

Set	@String 		='S'
Set	@Date   		='DT'
Set	@Numeric		='N'
Set	@Text   		='T'
Set	@CommaString		='CS'

-- Initialise variables
Set 	@nErrorCode 		= 0
Set     @nCount			= 1
Set 	@bPrintSQL 		= 0

set 	@sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set 	@nErrorCode				=0
Set     @nCount					= 1
Set 	@sFrom					='From NAME N'

-- Initialise the WHERE clause with a test that will always be true and will have no performance
-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
Set 	@sWhere 				= char(10)+"WHERE 1=1"
Set     @sWhereFrom				= char(10)+"From NAME XN"

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select	@bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit		  OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End
/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE SELECT LIST    ****/
/****                                       ****/
/***********************************************/
If @nErrorCode=0
Begin
        If @nTopRowCount is not null
        Begin
	        Set @sSelect = 'Select Top '+CAST(@nTopRowCount as varchar(10))+char(10)
        End
        Else Begin
	        Set @sSelect = 'Select '
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
	        -- Default @pnQueryContextKey to 190.
	        Set @pnQueryContextKey = isnull(@pnQueryContextKey, 190)

	        Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	        Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	        from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)

	        -- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	        -- while constructing the "Select" list   
	        Set @nOutRequestsRowCount	= @@ROWCOUNT
        End

        -- Loop through each column in order to construct the components of the SELECT
        While @nCount <= @nOutRequestsRowCount
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

		        If @sColumn = 'NameKey'
		        Begin
			        Set @sTableColumn='N.NAMENO'
		        End		
		        Else If @sColumn in ('DisplayName',
				             'NameCode')		
		        Begin
			        If @sColumn='DisplayName'
			        Begin
				        Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)' 
			        End

			        If @sColumn='NameCode'
			        Begin
				        Set @sTableColumn='N.NAMECODE'
			        End			
		        End
		        Else If @sColumn='StaffNameKey'
	                Begin
	                        Set @sTableColumn='AN.RELATEDNAME' 
		        End
		        Else If @sColumn in ('StaffNameKey',
		                             'StaffName',
		                             'StaffNameCode')
		        Begin
		                If charindex('left join ASSOCIATEDNAME AN ',@sFrom)=0
			        Begin
				        Set @sFrom=@sFrom + char(10) + "left join ASSOCIATEDNAME AN on (AN.NAMENO = N.NAMENO and (AN.CEASEDDATE is null 
					or AN.CEASEDDATE>getdate()))"
			        End
			        If charindex('left join NAME NS ',@sFrom)=0
			        Begin
				        Set @sFrom=@sFrom + char(10) + "left join NAME NS on (NS.NAMENO = AN.RELATEDNAME)"
			        End	
			        If @sColumn='StaffNameKey'
		                Begin
				        Set @sTableColumn='AN.RELATEDNAME' 
			        End 	
		                If @sColumn='StaffName'
		                Begin
				        Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NS.NAMENO, null)' 
			        End 
			        If @sColumn='StaffNameCode'
			        Begin
				        Set @sTableColumn='NS.NAMECODE'
			        End
		        End	
		        Else If @sColumn = 'Relationship'		
		        Begin
		                If charindex('left join ASSOCIATEDNAME AN ',@sFrom)=0
			        Begin
				        Set @sFrom=@sFrom + char(10) + "left join ASSOCIATEDNAME AN on (AN.NAMENO = N.NAMENO and (AN.CEASEDDATE is null 
					or AN.CEASEDDATE>getdate()))"
			        End
		                If charindex('left join NAMERELATION NR ',@sFrom)=0
			        Begin
				        Set @sFrom=@sFrom + char(10) + "left join NAMERELATION NR on (NR.RELATIONSHIP = AN.RELATIONSHIP)"
			        End
			        Set @sTableColumn='NR.RELATIONDESCR'
		        End
		        Else If @sColumn in ('OrganisationName',
				             'OrganisationCode',
				             'OrganisationKey')
		        Begin
		                If charindex('left join ASSOCIATEDNAME EMP',@sFrom)=0
			        Begin
			                Set @sFrom=@sFrom + char(10) + "left join ASSOCIATEDNAME EMP	on (EMP.RELATEDNAME = N.NAMENO and EMP.RELATIONSHIP = N'EMP'
			                                                and (EMP.CEASEDDATE is null or EMP.CEASEDDATE>getdate()))"
			        End
			        If @sColumn='OrganisationKey'
			        Begin
				        Set @sTableColumn='EMP.NAMENO'					
			        End			
			        Else If @sColumn='OrganisationCode'
			        Begin
				        Set @sTableColumn='ORG.NAMECODE'					
                                        If charindex('left join NAME ORG',@sFrom)=0
			                Begin
				                Set @sFrom=@sFrom + char(10) + "left join NAME ORG		on (ORG.NAMENO = EMP.NAMENO)"
				        End
        				
			        End		
			        Else If @sColumn='OrganisationName'
			        Begin
				        Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(ORG.NAMENO, null)'

				        If charindex('left join NAME ORG',@sFrom)=0
			                Begin
				                Set @sFrom=@sFrom + char(10) + "left join NAME ORG		on (ORG.NAMENO = EMP.NAMENO)"
				        End
			        End	
		        End
		        Else If @sColumn='DisplayMainPhone'
		        Begin
			        Set @sTableColumn='dbo.fn_FormatTelecom(PH.TELECOMTYPE, PH.ISD, PH.AREACODE, PH.TELECOMNUMBER, PH.EXTENSION)'

			        Set @sFrom=@sFrom + char(10) + 'Left Join TELECOMMUNICATION PH		on (PH.TELECODE=N.MAINPHONE)'
		        End
		        Else If @sColumn='DisplayMainEmail'
		        Begin
			        Set @sTableColumn='dbo.fn_FormatTelecom(ML.TELECOMTYPE, ML.ISD, ML.AREACODE, ML.TELECOMNUMBER, ML.EXTENSION)'

			        Set @sFrom=@sFrom + char(10) + 'Left Join TELECOMMUNICATION ML		on (ML.TELECODE=N.MAINEMAIL)'
		        End		
	        End

	        Set @sSelect = @sSelect + @sTableColumn
	        Set @sSelect = @sSelect + ' as [' + @sPublishName + ']'
	        if @nCount < @nOutRequestsRowCount
	        begin
		        Set @sSelect = @sSelect + ','
	        end
        	
	        -- If the column is to be sorted on then save the name of the table column along
	        -- with the sort details so that later the Order By can be constructed in the correct sequence

	        If @nOrderPosition>0
	        Begin
		        Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
		        values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, @sOrderDirection)

		        Set @nErrorCode = @@ERROR
	        End
        	
	        Set @sTableColumn = ''	
        	
	        -- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	        Set @nCount = @nCount + 1
        	
        End
End
/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE CLAUSE   ****/
/****                                       ****/
/***********************************************/
If (datalength(@ptXMLFilterCriteria) > 0)
	and @nErrorCode = 0
Begin
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	
	Set @sSQLString = 
	"Select @nStaffNameKey        = StaffNameKey,"+CHAR(10)+
	"@nStaffNameOperator                     = StaffNameOperator,"+CHAR(10)+
	"@sRelationshipKey                       = RelationshipKey,"+CHAR(10)+
	"       @nRelationshipOperator                  = RelationshipOperator,"+CHAR(10)+
	"       @nNameRespKey                           = NameRespKey,"+CHAR(10)+
	"       @nNameRespOperator                      = NameRespOperator,"+CHAR(10)+
	"       @sCity                                  = upper(City),"+CHAR(10)+
	"       @nCityOperator                          = CityOperator,"+CHAR(10)+
	"       @sState                                 = upper(State),"+CHAR(10)+
	"       @nStateOperator                         = StateOperator,"+CHAR(10)+
	"       @sCountryCode                           = CountryCode,"+CHAR(10)+
	"       @nCountryCodeOperator                   = CountryCodeOperator"+CHAR(10)+            
        "from	OPENXML (@idoc, '/naw_ListNameRelationship/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	StaffNameKey	        int	'Staff/NameKey/text()',"+CHAR(10)+
	"	StaffNameOperator	int	'Staff/@Operator/text()',"+CHAR(10)+
        "	RelationshipKey	        nvarchar(6)	'RelationshipKey/text()',"+CHAR(10)+
        "	RelationshipOperator	int	'RelationshipKey/@Operator/text()',"+CHAR(10)+
        "	NameRespKey	        int	'NameResponsible/text()',"+CHAR(10)+
        "	NameRespOperator	int	'NameResponsible/@Operator/text()',"+CHAR(10)+
        "	City	                nvarchar(60)	'City/text()',"+CHAR(10)+
        "	CityOperator	        int	'City/@Operator/text()',"+CHAR(10)+
        "	State	                nvarchar(40)	'State/text()',"+CHAR(10)+
        "	StateOperator	        int	'State/@Operator/text()',"+CHAR(10)+
        "	CountryCode	        nvarchar(6)	'CountryCode/text()',"+CHAR(10)+
        "	CountryCodeOperator	int	'CountryCode/@Operator/text()'"+CHAR(10)+
        ")"
        exec @nErrorCode = sp_executesql @sSQLString,
		N'@idoc				int,
		@nStaffNameKey		        int	output,
		@nStaffNameOperator	        tinyint	output,
		@sRelationshipKey	        nvarchar(6)	output,
		@nRelationshipOperator          tinyint	output,
		@nNameRespKey  	                int	output,
		@nNameRespOperator		tinyint	output,
		@sCity		                nvarchar(60)	output,
		@nCityOperator		        tinyint	output,
	        @sState		                nvarchar(40) output,
		@nStateOperator		        tinyint	output,
		@sCountryCode		        nvarchar(6)	output,
		@nCountryCodeOperator	        tinyint	output',
		@idoc				= @idoc,
		@nStaffNameKey		        = @nStaffNameKey	output,
		@nStaffNameOperator		= @nStaffNameOperator	output,
		@sRelationshipKey		= @sRelationshipKey	output,
		@nRelationshipOperator		= @nRelationshipOperator	output,
		@nNameRespKey		        = @nNameRespKey	output,
		@nNameRespOperator		= @nNameRespOperator	output,
		@sCity		                = @sCity	output,
		@nCityOperator		        = @nCityOperator	output,
		@sState		                = @sState	output,
		@nStateOperator		        = @nStateOperator	output,
		@sCountryCode		        = @sCountryCode	output,
		@nCountryCodeOperator		= @nCountryCodeOperator	output

		exec sp_xml_removedocument @idoc
	
	If @nStaffNameKey is not NULL
	Begin
	        Set @sWhere = @sWhere+char(10)+
		" and exists (select 1 from ASSOCIATEDNAME AN 
		where AN.NAMENO=N.NAMENO and (AN.CEASEDDATE is null or AN.CEASEDDATE>getdate()))"+
		" and AN.RELATEDNAME"+dbo.fn_ConstructOperator(@nStaffNameOperator,@Numeric,@nStaffNameKey, null,0)
	End
	Else 
	Begin
		Set @sWhere = @sWhere+char(10)+
		" and exists (select 1 from ASSOCIATEDNAME AN where AN.NAMENO=N.NAMENO and (AN.CEASEDDATE is null 
					or AN.CEASEDDATE>getdate()))"		
	End
	Set @sWhere = @sWhere +char(10)+" and exists (select 1 from EMPLOYEE where EMPLOYEENO = AN.RELATEDNAME)"
	Set @sWhere = @sWhere +char(10)+" and (NS.DATECEASED is null OR NS.DATECEASED>getdate())
	                                  and NS.USEDASFLAG&2=2"
	
	If @nNameRespKey is not NULL
	or @nNameRespOperator between 5 and 6
	Begin 
	        If @nNameRespOperator = 1
	        Begin
	                Set @sWhere = @sWhere+char(10)+
		        " and not exists (select 1 from ASSOCIATEDNAME AR 
		          where AR.RELATEDNAME=NS.NAMENO"+
		        " and AR.RELATIONSHIP = 'RES' and AR.NAMENO="+convert(nvarchar(11),@nNameRespKey)+"
		         and (AR.CEASEDDATE is null 
					or AR.CEASEDDATE > getdate())"		                
		End
		Else If @nNameRespOperator = 6
		Begin
		        Set @sWhere = @sWhere+char(10)+
		        " and not exists (select 1 from ASSOCIATEDNAME AR 
		          where AR.RELATEDNAME=NS.NAMENO and AR.RELATIONSHIP = 'RES' and (AR.CEASEDDATE is null 
					or AR.CEASEDDATE > getdate())"
		End
		Else
		Begin
	                Set @sWhere = @sWhere+char(10)+
	                " and exists (select 1 from ASSOCIATEDNAME AR 
	                  where AR.RELATEDNAME=NS.NAMENO"+
	                " and AR.RELATIONSHIP = 'RES' and AR.NAMENO"+dbo.fn_ConstructOperator(@nNameRespOperator,@Numeric,@nNameRespKey, null,0)+"
	                 and (AR.CEASEDDATE is null 
					or AR.CEASEDDATE > getdate())"	          
		End
		Set @sWhere = @sWhere+char(10)+ ")"
	End	
	If @sRelationshipKey is not NULL
	Begin
	        Set @sWhere = @sWhere+char(10)+
		" and AN.RELATIONSHIP"+dbo.fn_ConstructOperator(@nRelationshipOperator,@String,@sRelationshipKey, null,0)
	End
	If @sCountryCode is not null
	or @sState   is not null
	or @nStateOperator between 2 and 6
	or @sCity       is not null
	or @nCityOperator between 5 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+
                        " and (exists (select 1 from NAMEADDRESS XNA"+ 
                                " join ADDRESS XA on ( XA.ADDRESSCODE = XNA.ADDRESSCODE )"+
                                " where XNA.NAMENO=N.NAMENO and (XNA.DATECEASED is null or XNA.DATECEASED > getdate())"
                                        
		If @sCountryCode is not null
		Begin
			Set @sWhere =@sWhere+char(10)+"	and XA.COUNTRYCODE"+dbo.fn_ConstructOperator(@nCountryCodeOperator,@String,@sCountryCode, null,0)
                End
                
		If @sState is not null
		or @nStateOperator between 2 and 6
		Begin
			Set @sWhere =@sWhere+char(10)+"	and XA.STATE"+dbo.fn_ConstructOperator(@nStateOperator,@String,@sState, null,0)
                End
                
		If @sCity is not null
		or @nCityOperator between 5 and 6
	        Begin
			Set @sWhere =@sWhere+char(10)+"	and upper(XA.CITY)"+dbo.fn_ConstructOperator(@nCityOperator,@String,@sCity, null,0)
	        End
	        Set @sWhere = @sWhere+")"
	        -- Cater for names with no addresses
	        If @nStateOperator = 6
	        or @nCityOperator = 6
	        Begin
	                Set @sWhere = @sWhere+char(10)+
	                "or not exists (select 1 from NAMEADDRESS XNA 
                        where XNA.NAMENO=N.NAMENO and (XNA.DATECEASED is null or XNA.DATECEASED > getdate()))"
	        End
	        Set @sWhere = @sWhere+")"
	End		
End

-- Assemble the "Order By" clause.
If @nErrorCode=0
Begin		
	-- If there is more than one row in the @tbOrderBy then the data from the next row gets concatenated 
	-- to the previous row.
	Select @sOrder= 	ISNULL(NULLIF(@sOrder+',', ','),'')			
			  	+CASE WHEN(PublishName is null) 
			       	      THEN ColumnName
			       	      ELSE '['+PublishName+']'
			  	END
				+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
				from @tbOrderBy
				order by Position

	If @sOrder is not null
	Begin
		Set @sOrder = 'Order by ' + @sOrder
	End

	Set @nErrorCode=@@Error
End

If (@bPrintSQL=1)
Begin
	print char(10)+char(10)+ @sSelect + @sFrom + @sWhere + @sOrder
End


-- Return the results
-- No paging required
If (@pnPageStartRow is null or @pnPageEndRow is null)
Begin

	Set @sSQLString = @sSelect + char(10) + @sFrom + char(10) + @sWhere + char(10) + @sOrder	

	exec @nErrorCode = sp_executesql @sSQLString
	Set @pnRowCount = @@RowCount
End
-- Paging required
Else Begin

	Set @sSelect = replace(@sSelect,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')

	-- Execute the SQL
	Set @sSQLString = @sSelect + char(10) + @sFrom + char(10) + @sWhere + char(10) + @sOrder
        exec @nErrorCode = sp_executesql @sSQLString
	Set @pnRowCount = @@RowCount

	If @pnRowCount<@pnPageEndRow
	and @nErrorCode=0
	Begin
		-- results fit on 1 page
		set @sSQLString='select @pnRowCount as SearchSetTotalRows'  

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnRowCount	int',
					  @pnRowCount=@pnRowCount
	End
	Else If @nErrorCode = 0
	Begin
		Set @sSelect = ' Select count(*) as SearchSetTotalRows '

		Set @sSQLString = @sSelect + char(10) + @sFrom + char(10) + @sWhere

		exec @nErrorCode = sp_executesql @sSQLString

		Set @nErrorCode =@@ERROR
	End
End

RETURN @nErrorCode
GO

Grant execute on dbo.naw_ListNameRelationship  to public
GO



